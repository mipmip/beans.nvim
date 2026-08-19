# cli-schema Specification

## Purpose
TBD - created by archiving change build-data-layer. Update Purpose after archive.
## Requirements
### Requirement: Asynchronous CLI wrapper

The system SHALL invoke the `beans` CLI through `vim.system` with a callback-based API
and MUST NOT call `:wait()` on the main event loop. Every invocation SHALL run with the
current working directory set to the project root and SHALL honour a configurable
`--beans-path`. JSON output SHALL be decoded before being handed to callers.

#### Scenario: Read completes without blocking
- **WHEN** a caller requests `beans list --json`
- **THEN** the call returns immediately and the decoded result is delivered later via
  callback, without the editor blocking

#### Scenario: Invocation runs at the project root
- **WHEN** the CLI wrapper runs any command
- **THEN** the command executes with `cwd` set to the project root and the resolved
  `--beans-path`

### Requirement: Vocabulary discovery from help text

The system SHALL discover the `status`, `type`, and `priority` vocabularies at runtime
by parsing `beans update --help`. For each field it SHALL locate the line matching
`--<field>` at a word boundary, capture the first parenthesised group, split it on
commas, trim each item, and discard any item containing whitespace. When parsing yields
nothing or the binary is unavailable, the system SHALL fall back to the configured static
vocabulary.

#### Scenario: Priority parses and drops the clear tail
- **WHEN** the help line reads `--priority string   New priority (critical, high, normal, low, deferred, or empty to clear)`
- **THEN** the discovered priority vocabulary is exactly
  `critical, high, normal, low, deferred` (the `or empty to clear` item is discarded)

#### Scenario: Fallback when parsing fails
- **WHEN** `beans update --help` cannot be parsed or the binary is missing
- **THEN** the system uses the configured fallback vocabulary for that field

### Requirement: Dynamic mnemonic assignment

The system SHALL compute a unique mnemonic key for each value of a discovered vocabulary
by trying the first letter, then the next unused letter in the word, then falling back to
digits `1..9`. Mnemonics MUST NOT be hardcoded to specific vocabulary values.

#### Scenario: Collision falls through to a later letter or digit
- **WHEN** a vocabulary contains values whose first letters collide and whose remaining
  letters are also exhausted
- **THEN** the colliding values receive distinct mnemonics from later letters or digits
  `1..9`, and every value has a unique key

### Requirement: Prefetch and caching of reads

On bean detection the system SHALL prefetch `beans update --help` and `beans list --json`
asynchronously. The vocabulary result SHALL be cached per project root for the session.
The list result SHALL be cached per project root with a short TTL (~30s) and invalidated
on `BufWritePost` of any bean. When a consumer needs data that has not yet arrived, the
system SHALL surface a loading state rather than blocking.

#### Scenario: Vocabulary cached for the session
- **WHEN** vocabulary is requested twice for the same project root within one session
- **THEN** the second request is served from cache without a new subprocess

#### Scenario: List cache invalidated on save
- **WHEN** any bean in the project is saved (`BufWritePost`)
- **THEN** the cached `beans list --json` result for that root is invalidated

#### Scenario: Data not yet available
- **WHEN** a consumer requests list-derived data before the prefetch has returned
- **THEN** the system reports a loading state instead of blocking the event loop

