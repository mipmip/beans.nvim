## MODIFIED Requirements

### Requirement: Floating wizard window
The wizard SHALL render as a floating window near the cursor showing a title line with
step progress, the current step's options, and a footer of active key hints. As each step
activates, the plugin SHALL move the cursor to that field's frontmatter line (or its
insertion point) and highlight it. The window SHALL mark the currently highlighted option
with a distinct selection indicator (a caret glyph in a left gutter) that is visually
separate from the marker used for the value already set on the bean.

#### Scenario: Float shows progress and footer
- **WHEN** the wizard is on the second of five steps
- **THEN** a floating window exists whose title shows progress `2/5 · type` and whose
  footer lists the active keys

#### Scenario: Cursor tracks the active field
- **WHEN** a step activates
- **THEN** the cursor is moved to that field's frontmatter line (or its insertion point)
  and the line is highlighted

#### Scenario: The selected option is clearly indicated
- **WHEN** a card is displayed with a highlighted option
- **THEN** that option shows a caret selection indicator distinct from the marker for the
  value already set on the bean

### Requirement: Highlight groups with default links
The wizard SHALL define its highlight groups (`BeansWizardTitle`, `BeansWizardKey`,
`BeansWizardCurrent`, `BeansWizardActive`, `BeansWizardHint`, `BeansFieldLine`,
`BeansFlash`) each linking to a standard group by default so any colorscheme works.
`BeansWizardCurrent` SHALL link to a selection-style group (`PmenuSel`) by default so the
highlighted option is clearly visible.

#### Scenario: Groups link to standard groups by default
- **WHEN** the plugin is set up without custom highlights
- **THEN** each `Beans*` wizard highlight group is defined as a link to a standard group

#### Scenario: Selection highlight is a selection-style group
- **WHEN** the plugin is set up without custom highlights
- **THEN** `BeansWizardCurrent` links to `PmenuSel` by default
