## ADDED Requirements

### Requirement: Wizard auto-start on freshly created beans
The wizard SHALL auto-start when, and only when, all of the following hold: the buffer is
a recognised bean, the bean's `created_at` is within `autostart.max_age_seconds` of the
current time, and the body is empty or whitespace-only. Auto-start MUST be disableable
with a single configuration flag.

#### Scenario: Fresh empty bean auto-starts the wizard
- **WHEN** a recognised bean whose `created_at` is within `max_age_seconds` and whose body
  is empty is opened
- **THEN** the wizard float opens automatically at step 1

#### Scenario: Old bean does not auto-start
- **WHEN** a recognised bean whose `created_at` is older than `max_age_seconds` is opened
- **THEN** no wizard float opens

#### Scenario: Bean with a non-empty body does not auto-start
- **WHEN** a recognised bean with `require_empty_body` enabled and a non-empty body is opened
- **THEN** no wizard float opens

#### Scenario: Auto-start disabled
- **WHEN** `autostart.enabled` is `false` and a fresh empty bean is opened
- **THEN** no wizard float opens, and `:BeanWizard` still starts it manually

### Requirement: Floating wizard window
The wizard SHALL render as a floating window near the cursor showing a title line with
step progress, the current step's options, and a footer of active key hints. As each step
activates, the plugin SHALL move the cursor to that field's frontmatter line (or its
insertion point) and highlight it.

#### Scenario: Float shows progress and footer
- **WHEN** the wizard is on the second of five steps
- **THEN** a floating window exists whose title shows progress `2/5 · type` and whose
  footer lists the active keys

#### Scenario: Cursor tracks the active field
- **WHEN** a step activates
- **THEN** the cursor is moved to that field's frontmatter line (or its insertion point)
  and the line is highlighted

### Requirement: Buffer-edit mutations with one undo step per field
The wizard SHALL apply every field change as a direct buffer edit via the frontmatter
editor and MUST NOT invoke `beans update` while the bean is open. Each applied field
change MUST be exactly one undo step.

#### Scenario: Five picks undo to the original in five steps
- **WHEN** the user applies five field values and then presses `u` five times
- **THEN** the buffer is byte-identical to its as-opened state

#### Scenario: No CLI mutation during the wizard
- **WHEN** any field value is applied in the wizard
- **THEN** no `beans update` subprocess is spawned; the change exists only in the buffer

### Requirement: Universal keys and step navigation
The wizard SHALL provide universal keys available in every step: accept-and-advance,
back-one-step, select-highlighted, and finish. Advancing past the last step SHALL finish
the wizard.

#### Scenario: Back-navigation restores the prior pick
- **WHEN** the user advances past a step and then presses `<S-Tab>`
- **THEN** the previous step re-opens with the previously chosen value highlighted, so a
  subsequent accept is a no-op

#### Scenario: Accepting an unchanged field does not dirty the buffer
- **WHEN** the user presses accept-and-advance on a field without changing its value
- **THEN** the wizard advances and the buffer is left byte-identical

### Requirement: Escape finishes the wizard from any step
`<Esc>` (and the configured equivalents) SHALL finish the wizard entirely from any step
rather than stepping back, and SHALL always be an instant exit.

#### Scenario: Escape exits from every step
- **WHEN** the user presses `<Esc>` on any step
- **THEN** the wizard closes immediately and no float window remains

### Requirement: Finish drops into the body in insert mode
On finishing, the wizard SHALL close the float, position the cursor per the configured
finish behaviour (default the first line of the body, never the closing `---`), and enter
insert mode when configured to do so.

#### Scenario: Finish lands in insert mode on the body
- **WHEN** the wizard finishes on a bean with an empty body and default finish settings
- **THEN** the mode is insert, the cursor is on the first body line, and no float remains

### Requirement: No blocking prompts in the wizard path
The wizard path MUST NOT use `vim.fn.input`, `vim.fn.confirm`, `vim.fn.getchar`,
`vim.ui.select`, or `vim.ui.input`. All input MUST flow through buffer-local keymaps on the
wizard buffer so the flow is drivable by `nvim_feedkeys`.

#### Scenario: Grep-as-test finds no blocking prompt
- **WHEN** the wizard source under `lua/beans/wizard/` is grepped for the forbidden calls
- **THEN** no matches are found

### Requirement: Highlight groups with default links
The wizard SHALL define its highlight groups (`BeansWizardTitle`, `BeansWizardKey`,
`BeansWizardCurrent`, `BeansWizardActive`, `BeansWizardHint`, `BeansFieldLine`,
`BeansFlash`) each linking to a standard group by default so any colorscheme works.

#### Scenario: Groups link to standard groups by default
- **WHEN** the plugin is set up without custom highlights
- **THEN** each `Beans*` wizard highlight group is defined as a link to a standard group
