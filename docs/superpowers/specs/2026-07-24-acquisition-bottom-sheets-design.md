# Acquisition Bottom Sheets Design

## Goal

Replace every dialog-style overlay in the acquisition experience with a bottom sheet so acquisition follows the interaction pattern used elsewhere in Papyrus.

## Scope

The change covers all overlays launched from the Acquisition page:

- Add and edit integration
- Arr command selection
- Arr ID entry
- Remove-integration confirmation

The Arr command selector is already a bottom sheet. It will retain that behavior and receive the same spacing and header treatment as the converted overlays.

This change does not alter acquisition APIs, authentication, endpoint persistence, credential behavior, search, submission, or background-worker configuration.

## Interaction Design

### Integration Editor

The integration editor opens as a modal bottom sheet at every window width. The existing tablet and desktop dialog path is removed.

The sheet is:

- sized to its content instead of being forced to fill the viewport;
- scroll controlled and safe-area aware;
- padded for the software keyboard;
- constrained to a maximum of 92 percent of the available height;
- width constrained by the app's Material bottom-sheet behavior on larger windows;
- bottom anchored with top-only rounded corners and a visible drag handle;
- dismissible by drag, backdrop tap, Back, or Cancel while idle;
- dynamically protected from barrier, drag, and back dismissal while a connection test or save is pending.

The existing Integration and Connection groups, field validation, credential visibility controls, connection-test status, and footer actions remain unchanged.

The editor reports its busy state to a focused route wrapper. The wrapper rebuilds the modal bottom-sheet route when that state changes so `isDismissible`, `enableDrag`, and the drag handle reflect the live operation state. This keeps standard sheet behavior while idle without allowing a pending mutation to disappear and skip the page reload.

### Arr Command Selection

The existing command sheet keeps its list-based interaction. It gains the shared Papyrus bottom-sheet handle and a clear header, while command rows retain their labels and supporting command names.

### Arr ID Entry

The ID dialog becomes a keyboard-aware form sheet. It contains:

- the selected Arr command as the title;
- the existing comma-separated ID guidance;
- one ID text field;
- Cancel and Run actions.

Run returns the same parsed integer list as today. Invalid entries continue to be ignored.

### Remove Confirmation

The remove dialog becomes a compact destructive-action sheet. It contains:

- a shared sheet handle and title;
- the existing credential-removal warning;
- Cancel and Remove actions;
- destructive emphasis on Remove.

The endpoint is deleted only after explicit confirmation.

## Shared Presentation

Sheets reuse the existing Papyrus `BottomSheetHandle` and `BottomSheetHeader` patterns where their action model fits. Layout uses the existing spacing, radius, color, and typography tokens. Every sheet is bottom anchored with top-only corners and content-driven height. Form sheets use keyboard insets and bounded scrolling so their actions remain reachable on small screens.

No new dependency or app-wide overlay abstraction is introduced. Acquisition-specific helpers may be extracted when they remove duplication without changing other features.

## State and Error Handling

All existing callbacks and result values are preserved:

- a saved editor returns `true` and reloads endpoints;
- cancelled sheets return `null` or `false` as appropriate;
- connection-test and save errors stay local to the editor;
- deletion errors continue to use the page snackbar;
- pending editor operations keep controls disabled and cannot be dismissed.

## Accessibility

Every sheet has a readable title. Icon-only actions retain tooltips or semantic labels. Destructive actions use explicit text. Keyboard focus, safe areas, text scaling, and scroll reachability are covered by the existing widget structure and regression tests.

## Testing

Widget tests will prove:

- the integration editor uses a bottom sheet on both narrow and wide windows;
- short editor forms hug their content instead of occupying 92 percent of the viewport;
- larger forms and keyboard-open forms stop at the height cap and scroll;
- idle editor sheets expose drag, backdrop, and Back dismissal;
- pending editor operations dynamically disable those dismissal paths and restore them afterward;
- no acquisition editor dialog remains;
- Arr ID entry and remove confirmation use bottom sheets instead of dialogs;
- keyboard insets and constrained scrolling remain present for forms;
- Cancel, Run, Remove, Test connection, and Save preserve their results;
- busy integration operations still block dismissal;
- the focused acquisition suite, analyzer, formatter, and full Flutter suite pass.

## Non-Goals

- Refactoring dialogs elsewhere in Papyrus
- Changing acquisition endpoint types or capabilities
- Adding OPDS or other acquisition sources
- Enabling the background worker
