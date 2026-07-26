# Reader Integration Design

The Papyrus client will host the sibling `papyrus_reader` package without
exposing PowerSync, repositories, or application services to the package.

The existing “Start reading” action will support EPUB and PDF files. It will
prepare the local media cache and navigate to a full-screen reader route.
Unsupported digital formats will produce a clear message and will not attempt
to open the reader.

`ReaderPage` will resolve the book and cached bytes from client-owned services,
construct a `ReaderDocument`, restore a versioned `ReaderLocator` from
`Book.customMetadata`, and render `PapyrusReader`. Locator changes will be
debounced before updating the book in `DataStore`. The stored locator will
remain intact while summary fields such as current position, current page,
current CFI, reading status, and last-read time are updated for the rest of the
client.

The client’s existing reading defaults will be mapped to `ReaderPreferences`.
Reader-owned preference changes remain local to the reader session for this
initial integration; global preference synchronization is outside this slice.

Tests will cover format gating, locator restoration and persistence, preference
mapping, the stable reader route, and the Start reading action’s unsupported
format behavior.
