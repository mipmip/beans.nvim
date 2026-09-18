## Context

See proposal.md for motivation. Three properties of the existing code shape the
approach and are easy to get wrong on a first reading.

**Cursor initialisation already exists.** `enum.lua` builds its option list, then
scans it for the option marked `active` and puts the cursor there, falling back to
index 1. A configured default is a second fallback in that same scan, not a new
mechanism.

**The fallback vocabulary races the discovered one.** `enum.lua` resolves its option
list as `vocab[field]` first and the configured `fallback` table second. `wizard.start`
fires the vocabulary read and then enters step 1 without waiting for it:

```
M.start
  |- schema.get_vocab(...)  async ------------+
  |- M.goto_step(state, 1)                    |
  |    \- enum.enter   state.data.vocab = nil |
  |                    values = FALLBACK  <---+-- first render
  |                                           |
  ...vocab lands <-----------------------------+
  state.data.vocab = vocab
  M.refresh(state)
    \- enum.enter      values = REAL VOCAB  <----- second render
```

`get_vocab` caches per root, so only the first wizard of a session in a given root
renders twice. That is exactly the window in which a naive vocabulary check would
fire a warning that the second render then contradicts.

**Steps re-enter freely.** `enum.enter` runs on `goto_step`, on the back key, and on
every `refresh`. Any warning raised inside it repeats unless something records that
it already fired.

## Goals / Non-Goals

**Goals:**

- One configured value per enum field, honoured as cursor placement only.
- A wrong value tells the user once, in the project where it is wrong, and degrades
  to current behaviour.
- No new mutation path. The set of circumstances under which the wizard writes to the
  buffer is unchanged.

**Non-Goals:**

- Reconciling the meaning of the next key across steps. Its meaning differs between
  the enum steps (advance without writing) and the tags and parent steps (confirm and
  write). This change works within that asymmetry rather than fixing it, which is why
  tags and parent are out of scope.
- Reading `default_status` and `default_type` from `.beans.yml`. See Decisions.
- Any form of remembered or computed default, such as reusing the last value picked
  in the session.

## Decisions

### Cursor placement rather than a seeded value

The alternative was to write the default into the buffer when the step is entered, or
for all fields when the wizard starts, so that tabbing straight through produces a
fully populated bean.

Rejected because it makes opening the wizard a mutating act, which has three knock-on
effects: the flash animation fires on a value the user did not choose; `state.changed`
accumulates fields the user never touched and is handed to the `on_finish` hook; and
with `write.touch_updated_at` enabled, merely opening the wizard would bump
`updated_at`. It also contradicts the manual acceptance check in the briefing, which
requires that pressing the finish key immediately leaves the bean at its defaults.

The cost is one keystroke: accepting the default requires the select key rather than
the next key. That is the correct price for the wizard never writing something the
user did not ask for.

### Gate on the field being unset, not on "no option is active"

The obvious implementation extends the existing scan: if no option came back `active`,
use the default. That is wrong for a bean carrying a value the vocabulary does not
know, such as a hand-written `priority: urgent`. The field is set, but no option
matches, so nothing is `active`, and the default would quietly take over the cursor
and hide the discrepancy.

The condition is therefore the result of the current-value lookup being nil, which is
a distinct signal from the absence of an active option.

### Check the default against the discovered vocabulary only

The warning fires only when the field's vocabulary resolved from the CLI. While the
`fallback` table is standing in, the step stays silent. This is what keeps the race
described in Context from producing a retracted warning.

The guard needs an explicit marker rather than a nil test. `get_vocab` fills every
missing field from the `fallback` table before caching the result, so once resolution
finishes all three entries are non-nil whether Beans reported them or not, and a nil
test cannot tell a discovered vocabulary from a fallback-filled one. The cached vocab
therefore carries a `discovered` sub-table recording which fields Beans actually
reported, and the warning is gated on that.

The marker also covers the no-project-root case for free: `wizard.start` assigns a
vocab table there with no `discovered` entry at all, so the gate is false.

The trade-off is that a missing beans binary makes a bad default degrade silently,
because every field then falls back. That is acceptable: the health check already
reports a missing binary, and a second warning about a downstream symptom of the same
cause is noise.

### Warn once per project root and field

The configuration is global to the session, but vocabularies are per project root, so
the same configured value can be correct in one project and wrong in another. Keying
the record by root and field reports both truthfully, where keying by field alone
would swallow the second project's warning.

The existing per-root caches in `schema.lua` are the natural place for this record to
sit, so that the wizard does not grow its own root-keyed state.

### Do not read defaults from `.beans.yml`

`.beans.yml` carries `default_status` and `default_type`, and the briefing lists them
as present but not needed. Reading them would buy nothing on the happy path, because
the CLI has already applied them by the time the file reaches the editor, so the
fields are set and the default is not consulted. It would also introduce a silent
third source of truth for a value the user can already set explicitly. Recorded here
so the question is not reopened.

### Two validation moments

Type validation belongs at setup, where the existing warn-once-and-fall-back
machinery lives. Value validation cannot happen there, because vocabularies are
discovered per project after setup has returned. Splitting them is not a compromise:
they answer different questions and can only be answered at different times.

The notification level gate at setup is currently written inline. The wizard now needs
the same gate, so it moves to a shared helper rather than being duplicated.

## Risks / Trade-offs

**A user configures a default and expects the next key to accept it.** The next key
advances without writing, so tabbing through leaves the field unset, which may read as
the setting being ignored. Mitigation: name the behaviour in the configuration
documentation for the key, and say plainly that the value is confirmed rather than
applied.

**A silent degradation when the beans binary is missing.** A bad default produces no
warning at all in that case. Mitigation: accepted deliberately, on the grounds that
the health check covers the root cause.

**The warn-once record outlives a configuration reload.** Calling setup again with a
corrected value in the same session does not clear the record, but nothing needs
clearing, because a corrected value no longer warns. The stale case is the reverse:
correcting a value and then breaking it again in one session would be reported only
once. Mitigation: none. The cost of tracking configuration identity is not worth this
case.

**Fixture beans in the test suite may already set priority.** Tests for the unset path
need a fixture with no priority key, which is what the CLI actually produces. Any
existing shared fixture that sets all fields cannot be reused for these cases.

## Migration Plan

None required. Every new key is absent by default and the behaviour with no key
configured is byte-identical to today, so there is nothing to migrate and rollback is
the removal of the feature.
