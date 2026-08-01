# Advanced Filter Sheet Sizing Design

## Overview

Align the Advanced filters bottom sheet with Papyrus’s established bottom-sheet width and content spacing.

## Problem

The sheet applies a custom 760px desktop maximum width, making it visibly wider than standard sheets such as the book context menu. Its scrollable content and footer also use tighter horizontal insets than form sheets such as Add Shelf.

## Goals

- Match the standard Material bottom-sheet width used by the book context menu.
- Align the header, filter content, and footer actions to 24px horizontal insets using `Spacing.lg`.
- Preserve the current filter structure and interaction behavior.

## Non-goals

- Redesigning filter controls, typography, borders, sections, or colors.
- Changing draggable sizes, snapping, scrolling, preview counts, or filter semantics.
- Adding another custom desktop width.

## Design

- Remove the explicit 760px `showModalBottomSheet` constraint and allow the shared Material bottom-sheet defaults to determine width and bottom-center placement.
- Keep the transparent modal background and existing decorated sheet surface.
- Use `Spacing.lg` for the left and right padding of:
  - the sheet header;
  - the scrollable filter content;
  - the sticky footer action bar.
- Preserve the header’s current vertical padding and give the close button enough internal room without reducing the right content inset.
- Preserve all current mobile behavior; the standard sheet width continues to use the available mobile width.

## Verification

- Compare desktop width against the book context menu bottom sheet.
- Confirm header title, section content, and footer actions share the same horizontal edges.
- Confirm no filter controls overflow at the narrower desktop width.
- Confirm mobile width, scrolling, snapping, close/cancel/reset/apply, and sticky footer behavior remain unchanged.
- Run targeted Flutter analysis and a debug web build.

## Assumptions

- The application’s Material bottom-sheet theme remains the source of truth for standard desktop width.
- Existing internal padding inside individual filter controls remains unchanged.
