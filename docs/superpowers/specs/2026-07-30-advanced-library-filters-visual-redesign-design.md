# Advanced Library Filters Visual Redesign

## Goal

Redesign the advanced library filter sheet without changing its filtering behavior. The sheet should feel like one coherent form instead of a stack of outlined cards, and desktop hover feedback should remain cleanly contained.

## Visual Direction

Use the web prototype as the structural reference while retaining Papyrus theme tokens.

- Keep the existing narrow, bottom-centered sheet and fixed header and action bar.
- Preserve the existing header divider and action-bar top border.
- Remove subsection icons and generic card backgrounds.
- Distinguish Metadata, Organization, Reading, and Dates with uppercase labels, compact spacing, and a single divider between major sections.
- Hide option-based facets that have no available values.
- Use outlines to communicate expandable facets, inactive chips, and date controls.
- Reserve filled surfaces for search inputs and selected chips.
- Do not copy prototype shadows or color tints; derive colors from the active Papyrus theme.

## Sheet Structure

The sheet remains a single scrollable column between a fixed header and fixed action bar.

- The header contains the drag handle, title, and close action.
- The scrolling body uses consistent horizontal padding and compact gaps between sections.
- The original header divider and action-bar top border remain unchanged.
- Reset, Cancel, and Show N books retain their current behavior.

## Section Presentation

Each section starts with a compact uppercase text label. Section labels have no icons or background block. Section labels, field labels, inputs, options, and chip boundaries follow one consistent left-alignment grid. A section contains only fields that have meaningful controls; unavailable option facets such as an empty Publishers or Series list are omitted.

Sections retain their current order:

1. Metadata
2. Organization
3. Reading
4. Dates

## Searchable Facets

Authors, Languages, Publishers, Series, Shelves, and Topics use a custom expandable facet instead of `Card` and `ExpansionTile`.

- The expandable facet uses one rounded outline for its collapsed and expanded states.
- It shows the field label, either `Any` or the selected count, and a chevron.
- The entire row is clickable and keyboard accessible.
- Hover, focus, and pressed feedback is rendered by `Material` and `InkWell` using the same border radius, preventing rectangular or clipped state layers.
- A separator divides the expanded header from its content.
- Search inputs are compact, pill-shaped, surface-filled, and borderless at rest with a primary focus border.
- Matching options use transparent selectable rows with trailing checkboxes and separators contained within the facet outline.
- The options area shrink-wraps short lists and becomes scrollable only after a maximum height.
- A search with no matches shows a compact text state rather than an oversized empty panel.

## Compact Controls

Formats, reading statuses, ratings, and favorite state use compact choice chips. Selected values use the theme's selected-container colors; inactive chips are transparent with an `outlineVariant` border.

Progress and date filters use plain labels without wrapper cards:

- Progress keeps its enable switch, summary, and range slider in one compact left-aligned row.
- Date ranges keep their inclusive range behavior and clear action inside outlined rows.
- Labeled groups do not receive full-width wrapper backgrounds.

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
- Verify only purposeful outlines and separators remain: facets, date rows, inactive chips, option rows, and major section boundaries.
- Verify hover, focus, and pressed states follow rounded boundaries.
- Verify short option lists do not reserve excessive height.
- Verify empty option facets are hidden.
- Verify all filter interactions and draft/apply/reset behavior still work.
