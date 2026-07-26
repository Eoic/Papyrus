# Reader Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Open cached EPUB and PDF books in the Papyrus reader from the book details page and persist reading position.

**Architecture:** The client owns media access and persisted book state. A pure adapter translates client books and preferences to reader domain types, while a full-screen `ReaderPage` coordinates loading and debounced persistence.

**Tech Stack:** Flutter, Provider, go_router, papyrus_reader, flutter_test

---

### Task 1: Reader adapter

**Files:**
- Create: `app/lib/reader/reader_book_adapter.dart`
- Test: `app/test/reader/reader_book_adapter_test.dart`

- [ ] Write failing tests for EPUB/PDF format mapping, unsupported formats,
      safe locator restoration, locator persistence, and preference mapping.
- [ ] Run `flutter test test/reader/reader_book_adapter_test.dart` and verify
      that it fails because the adapter does not exist.
- [ ] Implement pure conversion and update functions.
- [ ] Re-run the test and verify it passes.

### Task 2: Reader page

**Files:**
- Create: `app/lib/pages/reader_page.dart`
- Create: `app/lib/reader/reader_session.dart`
- Test: `app/test/reader/reader_session_test.dart`

- [ ] Write failing tests proving locator updates are debounced and the final
      pending locator can be flushed.
- [ ] Run `flutter test test/reader/reader_session_test.dart` and verify the
      expected failure.
- [ ] Implement the session coordinator and full-screen page using
      `ReaderDocument`, cached client bytes, and `PapyrusReader`.
- [ ] Re-run the reader tests and verify they pass.

### Task 3: Routing and Start reading

**Files:**
- Modify: `app/lib/config/app_router.dart`
- Modify: `app/lib/pages/book_details_page.dart`
- Modify: `app/pubspec.yaml`
- Modify: `app/pubspec.lock`
- Modify: `app/test/config/app_router_test.dart`

- [ ] Add a failing route test for `/library/read/:bookId`.
- [ ] Run the route test and verify the missing route failure.
- [ ] Add the sibling package dependency, full-screen route, EPUB/PDF gate, and
      navigation from the existing callback.
- [ ] Run focused reader, router, and book-details tests.

### Task 4: Verification

- [ ] Run `dart format` on changed Dart files.
- [ ] Run all focused reader and route tests.
- [ ] Run `flutter analyze`.
- [ ] Run the full Flutter test suite.
- [ ] Inspect `git diff --check` and the final working tree.
