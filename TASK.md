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

Verified: builds, launches and passes all tests against Qt 6.8.2 AND
Qt 6.2.4 (offscreen), bracketing Mint 22's Qt 6.4.2. Distro Qt 6.2-6.4
needed an explicit static QML plugin link and a C++ number formatter
(both fixed in 1.0.2).

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

Status: [x]

Implemented (MMTreemap component, Storage page third tab): binary-split
proportional blocks over the current directory scan, largest first.
Labels appear only when there is room, hovering shows path + size,
clicking a directory navigates into it. The directory table remains the
accessible alternative and the UI says so.

Do not use the treemap as decoration. — respected: it is a data view of
real scan results only.

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

Status: [x]

Implemented (FileSearcher + Storage page second tab): filename substring
(case-insensitive), extension (case-insensitive), minimum and maximum
size, filters combined with AND. Results arrive incrementally, are
capped at 5000 with an honest "limited" note in the summary, and the
scan is cancellable. Searching starts only on explicit user action.

Do not perform a full filesystem search without explicit user action. —
respected.

⸻

MM-032 — Duplicate files

Status: [x]

Implemented (DuplicateScanner + Duplicates page):
1. files grouped by size, unique sizes dropped
2. partial hash (first 4 KiB) splits the remaining groups
3. full hash only where partial hashes collide

Display: duplicate groups with every member, per-group reclaimable size,
total reclaimable, oldest-first "keep" hint. Never automatically delete
duplicates — respected: files go to the trash only after the user
selects them and confirms a review dialog; the move uses the existing
safe trash path.

Do not hash every file blindly. — respected.

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

Note (1.0.2): automated offscreen UI checks now capture screenshots of
every page (build with -DMM_QA_SUPPORT=ON, run with MM_QA_PAGES /
MM_QA_OUT; see src/main.cpp). On Qt 6.2-6.4 the Layouts engine can log
"recursive rearrange" warnings when the Storage search tab is first
arranged; this is log-only noise, the layout settles and the UI is
correct (verified by screenshots on 6.2.4 and 6.8.2).

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

Five suites passing (ctest): size formatting, dpkg-query parsing,
cleanup rule registry and path-guard evaluation, duplicate detection,
filesystem search. Still missing: path handling edge cases and
filesystem classification tests.

Run: ctest --test-dir build

⸻

MM-111 — Integration tests

Status: [-]

Implemented: duplicate detection and filesystem search integration tests
run entirely inside QTemporaryDir (never the real home directory),
covering grouping, hashing pipeline, filters, error handling and empty
inputs. Still pending: package enumeration/removal and cleanup workflow
integration tests, which need a harness that can stub pkexec.

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

## Patch release notes (1.0.3-1)

Fixed in this release:

- AsyncProcess delivered only the unread remainder of process output to the
  finished handler (readyRead had already drained the pipe), so on real
  systems `dpkg-query` produced an empty package list. Output is now
  accumulated and decoded once; regression test added (tst_asyncprocess).
- Settings page language selector had an empty model left over from a
  Qt 6.2-6.4 layout bisect; the Tiếng Việt / English buttons are back.
- The deprecated `QCryptographicHash::addData(const char*, qsizetype)`
  call was replaced with the `QByteArray` overload (warning-free on
  Qt 6.2-6.8, see 1.0.3 notes).

New in this release (user requests):

- Browse buttons (folder picker) on Storage, Storage search, Large Files
  and Duplicates path fields; the manual path entry is kept. The picker is
  the QtQuick.Dialogs FolderDialog on Qt 6.3+ and a Qt.labs.platform
  fallback on Qt 6.2 (MFolderDialog adapts at runtime).
- Large Files: custom size threshold (value + MB/GB) next to the presets.
- Treemap: category colour-coding with legend, gutters, rounded corners,
  hover outline, staggered entrance animation, overflow chip.
- Consistent Lucide-derived icon set (recolored light/dark/on-accent,
  bundled in resources — no runtime network use).
- Guided tour: Settings → Guide opens an animated spotlight walkthrough
  (intro card first, per-section steps, closing card), replayable anytime.
- Short enter transition on section switch, sliding sidebar indicator and
  button micro-interactions using the existing motion tokens.

Known limitations kept honest:

- MM-090: on Qt 6.2-6.4 a few recursive-rearrange warnings can still be
  logged when the search card is arranged; they are log-only.
- The folder picker on Qt 6.2 uses the native dialog helper; on minimal
  desktops without one the Browse button may do nothing on that floor
  version (6.3+ is unaffected).

## Patch release notes (1.0.3-2)

- .deb installs showed no icons: the SVG image-format plugin (dlopened by
  the icon decoder, invisible to shlibdeps) was missing from the runtime
  Depends. Qt6::Svg is now referenced from the binary, libqt6svg6 is an
  explicit dependency and a startup warning names the package to install.
- Guided tour fixes: the sidebar step card could fly off-window; the
  spotlight only located its target once (mid page-enter animation) and
  is now re-located while the tour is open; a failing prepare() no longer
  aborts the step; out-of-view targets (Settings → Guide) are scrolled
  into view first.
- Applications are grouped by detected package category: filter chips
  with counts, section headers with aggregate count/size, search also
  matches the section name (tst_packagemodel added).

## Patch release notes (1.0.3-3)

- Sidebar navigation rows sagged: the Basic style's 12px vertical padding
  squeezed the custom content layout, pushing icon + label below the row
  centre so they appeared to overlap the next section (worse with tall
  Vietnamese diacritics). Rows now own the full height, are 40px tall
  with 3px spacing, and the sliding indicator stays aligned. MButton /
  MSecondaryButton received the same padding fix, 15px icons and explicit
  vertical centring, so button ink no longer spills past the border.
- Large Files custom threshold SpinBox clipped its value to one digit
  between the stepper buttons ("500" rendered as "0"); widened so all
  five digits fit.
- Storage mount cards truncated both legends on narrow cards; the total
  (already shown in the card header) is no longer repeated in the legend.
- Guided tour intro/outro cards are now floating: no fill, light ink on
  the dimmed backdrop, dark mode outlined white with a green inner
  hairline, light mode outlined green; the card sits slightly above
  centre and is clamped on screen. Target-step cards use auto ink so the
  header icon is visible in both themes (was white-on-white in light
  mode).
