# Shelf Page Heading Design

## Overview

Refine the shelf books header so the shelf identity reads as a page heading rather than a compressed toolbar. The Books controls remain structurally unchanged below it.

## Problem

The current header places the back button, shelf icon, title, long description, and edit action in one horizontal row. On a wide viewport, the description stretches across the page and the edit icon becomes visually detached. The resulting row has weak hierarchy compared with the search field and chips below it.

## Goals

- Present the shelf name as the page title.
- Keep the shelf icon, configured color, description, and edit action visible.
- Constrain the description to a readable width and at most two lines.
- Align the title, description, search field, chips, and book grid consistently.
- Preserve the existing responsive Books-page controls and shelf-specific behavior.

## Non-goals

- Redesigning the search bar, filter chips, book grid, or Add to shelf action.
- Adding decorative cards, tinted header backgrounds, shadows, or a hero treatment.
- Changing shelf data, editing behavior, navigation, or filtering.

## Proposed Design

### Desktop

- Use a dedicated heading block above the search-and-action row.
- Place the back button first, followed by the colored shelf icon and a content column.
- In the content column, place the shelf title and a compact Edit text action on the same line.
- Place the description beneath the title line. Align it with the title, constrain its width, allow at most two lines, and use the existing secondary text color.
- Keep the remainder of the heading row empty; do not push Edit to the far-right viewport edge.
- Preserve the search field and Add to shelf button on the following row, with the filter chips directly below.

### Mobile

- Keep the back button, colored shelf icon, title, and compact edit icon on the first line.
- Place the description beneath that line, aligned with the title rather than the back button.
- Allow at most two description lines with ellipsis overflow.
- Keep the full-width search field below the heading and retain the Add to shelf floating action button.

### Visual Treatment

- Increase the shelf title from toolbar-like typography to the existing page-heading scale.
- Render the shelf icon directly in its configured color, without a tinted container or decorative background.
- Use existing spacing, typography, color, and touch-target tokens.
- Keep the header compact: spacing should establish hierarchy without creating a large hero section.

## Accessibility

- Preserve tooltips and semantic labels for Back and Edit controls.
- Keep interactive targets at the application’s standard accessible size.
- Do not rely on shelf color alone; the shelf icon and title continue to identify the shelf.
- Ensure truncation remains usable with text scaling by retaining two description lines.

## Verification

- Confirm title, description, search, chips, and grid share a coherent left alignment on desktop.
- Confirm long descriptions wrap to two lines without pushing Edit away from the title.
- Confirm mobile layout does not overflow at narrow widths or increased text scale.
- Confirm missing descriptions still display the existing Add a description prompt.
- Confirm Back, Edit, search, filters, view controls, and Add to shelf retain their current behavior.
- Run targeted `flutter analyze` for the modified page.

## Assumptions

- The shelf identity remains visible outside book-selection mode and hidden during selection, matching current behavior.
- Only the reusable shelf variant of `LibraryPage` changes; the main Books header remains unchanged.
