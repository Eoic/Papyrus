# Contributing to Papyrus

Thank you for contributing to Papyrus. This guide defines how work is organized, named, reviewed, and merged.
Before participating, please read the [Code of Conduct](CODE_OF_CONDUCT.md).

## Contents

1. [Before you start](#before-you-start)
2. [Branching strategy](#branching-strategy)
3. [Branch naming](#branch-naming)
4. [Commit messages](#commit-messages)
5. [Keeping a branch up to date](#keeping-a-branch-up-to-date)
6. [Quality checks](#quality-checks)
7. [Testing](#testing)
8. [Pull requests](#pull-requests)
9. [Review and merge policy](#review-and-merge-policy)
10. [Release process](#release-process)
11. [Hotfix process](#hotfix-process)

## Before you start

Every change must be associated with a Trello task identified by a Papyrus ticket key such as `PPR-42`.

Before writing code:

1. Check whether a relevant Trello task already exists.
2. Discuss substantial features, architectural changes, or breaking changes with the maintainers.
3. Create or obtain the task's `PPR-<number>` key.
4. Create a branch from the appropriate base branch.

Keep one branch and one pull request focused on one Trello task. A task may contain multiple commits, but every commit must reference the same task unless the pull request explains why multiple tasks are inseparable. External contributors without access to the Trello board should open a GitHub issue or discussion so a maintainer can assign a ticket.

## Branching strategy

Papyrus uses a GitFlow-style workflow for versioned releases:

- `main` contains released, production-ready code.
- `development` contains integrated changes intended for the next release.

Feature and fix branches start from `development` and target `development`. Merge them only when the work is complete, tested, and accepted for the next release. Work that must not ship in the next release must remain on its task branch or be disabled behind a feature flag.

Release branches start from `development` after the planned release scope has been integrated. After the branch is created, only stabilization fixes, version changes, and release notes are added to it.

Hotfix branches start from `main` and are used for urgent fixes to released versions.

Use **Rebase and merge** for feature and fix branches. Use **Create a merge commit** for release, hotfix, and synchronization pull requests.

Create an ordinary task branch:

```bash
git switch development
git pull --ff-only origin development
git switch -c feature/PPR-42-add-reading-goals
```

Create a hotfix branch:

```bash
git switch main
git pull --ff-only origin main
git switch -c hotfix/PPR-87-fix-startup-crash
```

## Branch naming

Branch names must use this format:

```text
<intention>/PPR-<ticket-number>-<short-kebab-case-description>
```

Examples:

```text
feature/PPR-42-add-reading-goals
fix/PPR-57-correct-progress-percentage
hotfix/PPR-87-fix-startup-crash
release/PPR-120-prepare-v1-2-0
```

| Prefix | Purpose | Base | Target |
| --- | --- | --- | --- |
| `feature/` | New functionality and other planned changes | `development` | `development` |
| `fix/` | Non-urgent bug fixes | `development` | `development` |
| `hotfix/` | Urgent fixes for released code | `main` | `main` |
| `release/` | Stabilization and preparation of the next release | `development` | `main` |

Use `feature/` for refactoring, documentation, tests, dependencies, CI, and build changes that are not bug fixes.

Branch naming rules:

- Begin with one of the documented prefixes.
- Include exactly one primary `PPR-<number>` ticket key.
- Use lowercase kebab-case after the ticket key.
- Keep the description concise and specific.
- Avoid personal names, dates, and generic descriptions such as `changes`, `update`, or `work`.
- Delete the branch after it is merged.

## Commit messages

Every commit must use the same structure:

```text
PPR-<ticket-number>: <imperative summary>

[optional body]
```

Examples:

```text
PPR-42: Add bulk metadata editing
PPR-42: Validate selected books before updating metadata
PPR-57: Preserve reading progress after reopening a book
PPR-63: Separate queue persistence from synchronization transport
PPR-74: Cover invalid EPUB metadata
```

Commit rules:

- Begin every commit subject with a valid `PPR-<number>` key.
- Use the same ticket key as the branch.
- Write the summary in the imperative mood, such as `Add`, `Fix`, `Remove`, or `Update`.
- Keep the subject concise, preferably no longer than 100 characters.
- Make each commit a coherent and reviewable change.
- Do not leave messages such as `WIP`, `Fix stuff`, `Address review`, or `Misc changes` in the final history.

A commit body is optional. Use one when the reason for the change, an important trade-off, or a migration requirement is not obvious from the subject.

```text
PPR-96: Resume interrupted file uploads

Persist the completed chunk offset so an upload can continue after the app
restarts instead of beginning again from zero.
```

After rebasing a previously pushed personal branch, update it with:

```bash
git push --force-with-lease
```

## Keeping a branch up to date

Rebase a short-lived branch onto its target branch before requesting final review.

For branches targeting `development`:

```bash
git fetch origin
git rebase origin/development
```

For branches targeting `main`:

```bash
git fetch origin
git rebase origin/main
```

Resolve conflicts, rerun the relevant checks, and update the remote branch:

```bash
git push --force-with-lease
```

## Quality checks

Run the relevant checks before requesting review:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test --coverage
```

Apply formatting with:

```bash
dart format .
```

A pull request is not ready to merge while any required check is failing.

## Testing

Add or update tests whenever behavior changes.

- Place unit and widget tests under `app/test/`.
- Place end-to-end integration tests under `app/integration_test/`.
- Add a regression test for a bug fix when practical.
- Cover both success and failure paths for parsing, storage, synchronization, and import logic.
- Avoid tests that depend on execution order, local machine state, real credentials, or uncontrolled external services.
- Keep test data minimal and free of copyrighted content that cannot be redistributed.

Run a specific test with:

```bash
flutter test test/path/to/example_test.dart
```

Contributors are not expected to test every supported platform locally. The pull request must state which platforms were tested and identify any known platform-specific risks.

## Pull requests

### Pull request title

Create a PR using the following title format:

```text
PPR-<ticket-number>: <imperative summary>
```

Example:

```text
PPR-42: Add bulk metadata editing
```

Use the following PR template:

```markdown
## Ticket

<Trello card link>

## Summary

Describe the problem, what changed, and why this approach was chosen.

## Testing

Describe the testing steps so that other users can follow them step-by-step and test the introduced changes.

## UI evidence

Add screenshots or recordings, or write `-` if not applicable.

## Compatibility and migration

Describe breaking changes and migrations, or write `-` if not applicable.

## Notes

Add reviewer guidance, risks, or follow-up tasks.

## Checklist

- [ ] The branch, commits, and pull request title follow the repository conventions.
- [ ] The change is complete and limited to the ticket's scope.
- [ ] Relevant tests have been added or updated.
- [ ] Formatting, analysis, and tests pass.
- [ ] Documentation, UI evidence, and migration notes are included where relevant.
- [ ] No credentials, personal data, copyrighted fixtures, or unrelated generated files are included.
- [ ] The branch is up to date with its target branch.
```

Draft pull requests are welcome for early feedback. Mark a pull request ready only when the change is complete enough for final review.

## Review and merge policy

A pull request may be merged when:

- Required CI checks pass.
- At least one maintainer approves it.
- Review conversations are resolved.
- The branch is up to date with its target branch, when required by branch protection.
- Every commit follows the required message format.
- The change is documented and tested appropriately.

Use **Rebase and merge** for `feature/` and `fix/` pull requests into `development`.

Use **Create a merge commit** for:

- `release/` pull requests into `main`.
- `hotfix/` pull requests into `main`.
- Synchronization pull requests from `main` into `development` or an active release branch.

After merging:

1. Delete the source branch.
2. Move the Trello task to the appropriate completed state.
3. Create separate Trello tasks for deferred follow-up work.

### Recommended branch protection

Protect both `main` and `development` by requiring:

- Pull requests before merging.
- At least one approving review.
- Resolved review conversations.
- Passing CI checks.
- Restricted direct pushes.
- Blocked force pushes and branch deletion.

Enable **Rebase and merge** and **Create a merge commit**. Disable squash merging.

## Release process

A release contains the state of `development` at the point when the release branch is created.

Before creating the branch:

1. Confirm the set of tickets planned for the release.
2. Ensure each included ticket is complete, reviewed, and tested in `development`.
3. Keep deferred work on its task branch or disable it behind a feature flag.
4. Ensure the required CI checks pass on `development`.

Create the release branch from `development`:

```bash
git switch development
git pull --ff-only origin development
git switch -c release/PPR-120-prepare-v1-2-0
```

After creating the branch:

1. Update the application version and release notes.
2. Apply only stabilization fixes required for the release.
3. Run the full quality and platform checks.
4. Open a pull request from the release branch into `main`.
5. Merge it using **Create a merge commit**.
6. Create and push an annotated release tag from `main`:

```bash
git switch main
git pull --ff-only origin main
git tag -a v1.2.0 -m "Papyrus v1.2.0"
git push origin v1.2.0
```

7. Open a synchronization pull request from `main` into `development` and merge it using **Create a merge commit**.
8. Delete the release branch after both pull requests are complete.

## Hotfix process

Create a hotfix branch from `main`, implement the fix, and open a pull request into `main`.

After the pull request passes review and CI:

1. Merge it using **Create a merge commit**.
2. Tag the patch release on `main`.
3. Open synchronization pull requests from `main` into `development` and any active release branch.
4. Merge the synchronization pull requests using **Create a merge commit**.
5. Delete the hotfix branch.
