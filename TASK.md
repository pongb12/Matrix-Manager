Matrix Manager — TASK.md

Project goal

Build Matrix Manager, a personal Linux desktop utility for managing disk space and installed .deb applications.

Target:

* Linux Mint
* Ubuntu
* Debian

Technology:

* C++20
* Qt 6
* QML
* CMake

No AI.
No neural network.
No background daemon.
No telemetry.

⸻

Task status legend

* [ ] Not started
* [-] In progress
* [x] Complete
* [!] Blocked
* [?] Needs decision

⸻

PHASE 0 — Repository foundation

MM-001 — Project bootstrap

Status: [x]

Create the initial CMake project.

Requirements:

* CMake
* C++20
* Qt 6
* QML
* application entry point
* basic resource system
* Debug/Release configurations

Expected result:

cmake -S . -B build
cmake --build build

must succeed.

Verified: builds and runs against Qt 6.8.2; all C++ core compiles against
Qt 6.2.4 headers (minimum supported version, Ubuntu 22.04 / Mint 21).

⸻

MM-002 — Initial architecture

Status: [x]

Create a clean separation between:

UI
Core
Filesystem
Packages
Cleanup
Applications
Platform/Linux

Do not create empty abstraction layers without a purpose.

Implemented: src/core (formatting, settings, activity), src/filesystem
(walker, volumes, scanners), src/packages, src/cleanup,
src/platform/linux (safe process execution), qml/ (theme, components,
pages). Each layer exists because it has a concrete responsibility.

⸻

MM-003 — Application shell

Status: [x]

Implemented: fixed sidebar navigation with keyboard support, page
container (StackLayout), resizable window (1180x760, min 960x600),
application title, SVG icon placeholder, toast notifications. All seven
pages exist; Duplicates carries an honest empty state pointing at
MM-032.

⸻

PHASE 1 — Design system

MM-010 — Matrix Manager design system

Status: [x]

Implemented as a QML singleton (qml/theme/Theme.qml): semantic colour
tokens for both themes, spacing/radius/typography/motion scales, focus
colour. Single restrained green accent on a near-monochrome scale; no
gradients or AI-purple.

⸻

MM-011 — Typography

Status: [x]

Implemented: platform default font family plus the system fixed-width
font for paths, package names and sizes (QFontDatabase systemFont).
Hierarchy through size/weight only. No italics, no decorative pairing.

⸻

MM-012 — Core components

Status: [x]

Implemented in qml/components/: MButton, MSecondaryButton,
MDestructiveButton, MIconButton, MCard, MListItem, MProgressBar,
MEmptyState, MErrorState, MLoadingState, MConfirmationDialog,
MSearchField, MSegmented, MBadge, MToast, MPageHeader, MUsageBar,
MValueRow, MCheckBox, MSwitch. All interactive components implement
default/hover/pressed/focus/disabled states.

⸻

PHASE 2 — Disk information

MM-020 — Disk information

Status: [x]

Implemented via QStorageInfo (StorageService): capacity, used, free,
percentage, filesystem type, mount point, multiple volumes, pseudo
filesystems filtered. No "safe to clean" claims anywhere.

⸻

MM-021 — Storage overview

Status: [x]

Implemented: Home folder breakdown after an explicit home scan groups
well-known top-level directories (Documents, Downloads, Pictures,
Videos, .cache, ...) with an honest "Other" remainder. Classification
is derived from real scan data only.

⸻

MM-022 — Storage tree

Status: [x]

Implemented (DirectoryScanner): lazy per-directory scanning on user
request, worker-thread traversal, partial results, cancellation,
per-entry permission error recording, symlink safety (never followed by
default, cycle guard when enabled), mount-boundary reporting, sorting by
size and name.

⸻

MM-023 — Treemap

Status: [ ]

Create a visual treemap for directory/file sizes.

Requirements:

* meaningful proportional sizing
* labels only when there is enough room
* hover information
* click to navigate
* accessible alternative list/table

Do not use the treemap as decoration.

⸻

PHASE 3 — File management

MM-030 — Large files

Status: [x]

Implemented (LargeFileService + page): thresholds 100 MB / 500 MB /
1 GB / 5 GB (default 500 MB, persisted), filename, path, size, modified
time, type. Actions: Open, Show in folder, Move to trash (with explicit
confirmation; recoverable). Deletion is never automatic.

⸻

MM-031 — Search

Status: [ ]

Implement filesystem search.

Support:

* filename
* extension
* minimum size
* maximum size

Do not perform a full filesystem search without explicit user action.

⸻

MM-032 — Duplicate files

Status: [ ]

Implement duplicate detection.

Algorithm:

1. compare file size
2. group same-size candidates
3. partial hash
4. full hash only when required

Do not hash every file blindly.

Display:

* duplicate groups
* files in each group
* total reclaimable size

Never automatically delete duplicates.

⸻

PHASE 4 — Applications

MM-040 — Installed .deb applications

Status: [x]

Implemented via dpkg-query (read-only): package name, one-line summary
as human-readable identity, version, architecture, installed size,
section, status filtering (installed only). Query errors surface as an
actionable error state with retry.

⸻

MM-041 — Application list

Status: [x]

Implemented: searchable (name or description), sortable (size, name,
version, asc/desc), totals line, details panel.

⸻

MM-042 — Application details

Status: [x]

Implemented: display name, package name, version, architecture,
installed size, section, summary. Uninstall action present.

⸻

MM-043 — Uninstall

Status: [x]

Implemented: apt-get remove through pkexec at the operation boundary
(GUI stays unprivileged), strict package-name validation, explicit
confirmation showing package/version/size/consequence, live output tail,
success and error reporting, automatic list refresh. No manual /usr
deletion anywhere in the codebase.

⸻

PHASE 5 — Cleanup

MM-050 — Cleanup framework

Status: [x]

Implemented (CleanupService): three explicit rules with id, name,
description, targets, deterministic size estimation, risk level
(LOW/MEDIUM), privilege requirement flag and documented consequence.
Rule ids are validated before execution; arbitrary paths are never
accepted.

⸻

MM-051 — Trash cleanup

Status: [x]

Implemented: XDG home trash detection with strict canonical-path
guards, item count and size display, review before emptying, explicit
user action required.

⸻

MM-052 — APT cache cleanup

Status: [x]

Implemented: /var/cache/apt/archives/*.deb size estimation, plain
explanation in rule description and consequence, `apt-get clean` through
pkexec rather than manual deletion.

⸻

MM-053 — Temporary file cleanup

Status: [x]

Implemented scope: thumbnail cache (~/.cache/thumbnails) as the clearly
defined temporary location. /tmp is deliberately NOT targeted: it
contains live sessions of other programs and deleting from it while
applications run is unsafe. Hidden files are never treated as junk by
themselves.

⸻

MM-054 — Cleanup review

Status: [x]

Implemented: review dialog lists each selected rule with its estimated
size, the per-rule consequence and the total, with Cancel and Clean
buttons. User must understand exactly what will happen before anything
runs.

⸻

PHASE 6 — Overview

MM-060 — Overview page

Status: [x]

Implemented: real volume usage bars, cleanup candidate sizes (estimated
on demand, cheap directory listings only), installed package count and
total size (dpkg-query on demand), session activity. No fake statistics,
no decorative metrics; expensive scans are explicitly delegated to the
Storage and Large Files pages.

⸻

MM-061 — Recent activity

Status: [x]

Implemented (ActivityLog): in-memory, session-only record of actions
performed by the application (cleanups, package removals, trash moves).
Nothing is persisted; nothing leaves the process.

⸻

PHASE 7 — Settings

MM-070 — Settings

Status: [x]

Implemented: theme (System / Light / Dark, persisted), default
large-file threshold, confirmation preference, follow symlinks (off by
default, with warning), cross-filesystem scan boundaries (off by
default). No unnecessary settings.

⸻

MM-071 — About

Status: [x]

Implemented in Settings: application name and version, Qt version,
detected operating system, architecture, supported platforms, MIT
license, local-first privacy statement. No fabricated company
information.

⸻

PHASE 8 — Reliability

MM-080 — Permission handling

Status: [-]

Designed for: the walker records inaccessible entries and continues;
scans never abort on a single failure; unreadable roots produce a clear
error. Needs verification on a real desktop against unreadable
directories, root-owned files, broken symlinks and mounted volumes.

⸻

MM-081 — Cancellation

Status: [x]

Implemented: directory scans and large-file scans are cancellable at any
point; cancellation never touches the filesystem (only reads). Destructive
operations are deliberately not cancellable mid-run.

⸻

MM-082 — Process execution safety

Status: [x]

Audited: every process invocation uses QProcess with separate program
and arguments; no shell strings exist in the codebase; package names are
regex-validated and length-limited; output is captured and reported;
synchronous calls are time-limited. pkexec is invoked only at
privileged operation boundaries.

⸻

PHASE 9 — UX / Hallmark audit

MM-090 — Hallmark-style design audit

Status: [-]

Design built to the principles from the start: no generic card grids, no
gradients or glassmorphism, no invented metrics, semantic tokens only,
explicit empty/loading/error states. A full visual audit on a real
desktop (both themes, various window sizes) is still pending.

⸻

MM-091 — Accessibility

Status: [-]

Implemented so far: keyboard navigation in the sidebar, visible focus
rings on all interactive components, status communicated by text plus
colour (badges carry labels), readable sizes. Full contrast review and
end-to-end keyboard pass pending on a real desktop.

⸻

PHASE 10 — Performance

MM-100 — Startup performance

Status: [x]

By design: startup loads only the UI and constants. No filesystem scan,
no package query, no disk enumeration happens before the user asks for
it. Cleanup estimates on the Overview page are cheap directory listings
and are the only automatic data reads.

⸻

MM-101 — Scan performance

Status: [x]

Implemented: all traversals run on worker threads with incremental
partial results, progress reporting, cancellation, no hashing, no
token-bucket surprises. The GUI thread never touches the filesystem
beyond cheap metadata reads.

⸻

PHASE 11 — Testing

MM-110 — Unit tests

Status: [-]

Implemented and passing (ctest): size formatting, dpkg-query parsing,
cleanup rule registry and path-guard evaluation. Still missing: path
handling edge cases and filesystem classification tests.

Run: ctest --test-dir build

⸻

MM-111 — Integration tests

Status: [ ]

Test:

* package enumeration
* package removal workflow
* cleanup workflow
* filesystem scanning
* error handling

Never run destructive tests against the developer’s real home directory.

Use temporary test directories.

⸻

MM-112 — Final release test

Status: [ ]

Verify on:

* Linux Mint
* Ubuntu
* Debian

Test:

* installation
* startup
* scanning
* application listing
* uninstall
* cleanup
* deletion
* error handling
* light theme
* dark theme
* keyboard navigation

⸻

Definition of MVP

MVP is complete when:

[x] application builds
[x] main window works
[x] design system exists
[x] Overview exists
[x] Storage scanning works
[x] Large Files works
[x] .deb application listing works
[x] uninstall works safely
[x] basic Cleanup works
[x] confirmation dialogs work
[x] errors are handled
[x] no background daemon exists
[x] no AI/ML exists
[x] no telemetry exists

Everything else can follow after MVP.

⸻

Agent execution rule

Work sequentially.

Do not jump to later tasks because they look more interesting.

For each task:

inspect
plan
implement
build
test
review
mark complete

If a task reveals an architectural issue, fix the architecture before adding more dependent functionality.
