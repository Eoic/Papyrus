# Advanced Library Filters Visual Redesign

## Goal

Redesign the advanced library filter sheet without changing its filtering behavior. The sheet should feel like one coherent form instead of a stack of outlined cards, and desktop hover feedback should remain cleanly contained.

## Visual Direction

Use a borderless, tonal grouped form.

- Keep the existing narrow, bottom-centered sheet and fixed header and action bar.
- Remove subsection icons, card outlines, `ExpansionTile` dividers, and full-width separator rules.
- Distinguish Metadata, Organization, Reading, and Dates with typography, spacing, and a subtle tonal section label.
- Hide option-based facets that have no available values.
- Use spacing and surface color—not strokes—to establish hierarchy.

## Sheet Structure

The sheet remains a single scrollable column between a fixed header and fixed action bar.

- The header contains the drag handle, title, and close action.
- The scrolling body uses consistent horizontal padding and larger gaps between sections than between fields.
- The action bar uses a slightly different surface color and spacing to remain distinct without a top border.
- Reset, Cancel, and Show N books retain their current behavior.

## Section Presentation

Each section starts with a compact text label on a subtle tonal background. Section labels have no icons. A section contains only fields that have meaningful controls; unavailable option facets such as an empty Publishers or Series list are omitted.

Sections retain their current order:

1. Metadata
2. Organization
3. Reading
4. Dates

## Searchable Facets

Authors, Languages, Publishers, Series, Shelves, and Topics use a custom expandable facet instead of `Card` and `ExpansionTile`.

- The collapsed row is a rounded, borderless tonal surface.
- It shows the field label, either `Any` or the selected count, and a chevron.
- The entire row is clickable and keyboard accessible.
- Hover, focus, and pressed feedback is rendered by `Material` and `InkWell` using the same border radius, preventing rectangular or clipped state layers.
- The expanded content remains within the same surface without divider lines.
- Search inputs are compact, filled, and borderless.
- Matching options use rounded selectable rows with checkboxes and contained hover feedback.
- The options area shrink-wraps short lists and becomes scrollable only after a maximum height.
- A search with no matches shows a compact text state rather than an oversized empty panel.

## Compact Controls

Formats, reading statuses, ratings, and favorite state use borderless tonal choice chips. Selected values use the theme's selected-container colors; inactive values use a quieter surface-container color.

Progress and date filters use plain labeled blocks rather than cards:

- Progress keeps its enable switch, summary, and range slider.
- Date ranges keep their inclusive range behavior and clear action.
- Controls are grouped by spacing and background tone, without outlines or horizontal separators.

## Interaction and State

The redesign does not alter the draft filter model, matching logic, result preview, chip synchronization, or dismissal behavior.

- Multiple searchable facets can remain expanded simultaneously.
- Reset clears the local draft.
- Close, Cancel, and backdrop dismissal discard the draft.
- Show N books applies the draft.
- Zero-result filters remain valid.

## Accessibility

- Preserve semantic labels for the sheet, filter fields, checkboxes, and actions.
- Keep at least 44 logical pixels for interactive rows and buttons.
- Expose expanded/collapsed state through the custom facet control.
- Use theme colors for sufficient contrast in light, dark, and e-ink modes.
- Do not rely on color alone to indicate selected options.

## Scope

Only the presentation and internal widget composition of the new advanced filter sheet are changed. Provider behavior, filter models, the search-bar badge, library chips, and shelf-content search remain functionally unchanged.

## Verification

No new automated tests are required.

- Run targeted `flutter analyze` on the advanced filter feature files.
- Build and launch the Linux app.
- Inspect the sheet in dark mode at desktop width.
- Verify outlines and separator lines are gone.
- Verify hover, focus, and pressed states follow rounded boundaries.
- Verify short option lists do not reserve excessive height.
- Verify empty option facets are hidden.
- Verify all filter interactions and draft/apply/reset behavior still work.
