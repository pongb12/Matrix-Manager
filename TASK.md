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

Status: [ ]

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

⸻

MM-002 — Initial architecture

Status: [ ]

Create a clean separation between:

UI
Core
Filesystem
Packages
Cleanup
Applications
Platform/Linux

Do not create empty abstraction layers without a purpose.

⸻

MM-003 — Application shell

Status: [ ]

Implement the main application window.

Requirements:

* minimum sensible window size
* resizable
* desktop-friendly layout
* navigation
* page container
* application title
* icon placeholder if final icon is not ready

Pages initially:

* Overview
* Storage
* Applications
* Cleanup
* Large Files
* Duplicates
* Settings

Pages can initially contain proper empty states.

⸻

PHASE 1 — Design system

MM-010 — Matrix Manager design system

Status: [ ]

Create the central QML design-token system.

Define:

* colors
* typography
* spacing
* radius
* borders
* shadows/elevation
* animations
* focus state
* semantic colors

Support:

* light theme
* dark theme

The design must follow Hallmark’s anti-slop principles while being adapted to a Linux desktop utility.

Reference:

https://github.com/Nutlope/hallmark

Do NOT clone Hallmark.

⸻

MM-011 — Typography

Status: [ ]

Choose a suitable desktop-oriented font system.

Priorities:

1. readability
2. Linux availability
3. clear hierarchy
4. restrained personality

Avoid excessive font pairing.

Do not use italic display headings.

⸻

MM-012 — Core components

Status: [ ]

Create reusable components for:

* Button
* IconButton
* DestructiveButton
* SecondaryButton
* Card/Surface where justified
* ListItem
* ProgressBar
* EmptyState
* ErrorState
* LoadingState
* ConfirmationDialog
* SearchField
* SegmentedControl
* Badge
* Toast/notification
* PageHeader

Each interactive component must handle:

* default
* hover
* focus
* pressed
* disabled
* loading
* error
* success where applicable

⸻

PHASE 2 — Disk information

MM-020 — Disk information

Status: [ ]

Display:

* total capacity
* used space
* free space
* usage percentage
* filesystem where available
* mount point

Support multiple mounted storage volumes where appropriate.

Do not claim a volume is “safe to clean”.

⸻

MM-021 — Storage overview

Status: [ ]

Create the Storage page.

Display meaningful categories based on actual filesystem data.

Potential categories:

* Home
* Applications
* Downloads
* Documents
* Pictures
* Videos
* Cache
* Other

Do not fabricate category values.

If classification is incomplete, label it honestly.

⸻

MM-022 — Storage tree

Status: [ ]

Implement directory traversal.

Requirements:

* lazy loading
* asynchronous traversal
* cancellation
* permission-error handling
* symlink safety
* progress reporting
* sorting by size
* sorting by name

Do not scan the entire root filesystem on startup.

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

Status: [ ]

Create Large Files page.

Default threshold:

500 MB

Allow:

* 100 MB
* 500 MB
* 1 GB
* 5 GB

Display:

* filename
* path
* size
* modified time
* file type

Actions:

* Open
* Show in folder
* Delete

Deletion must require appropriate confirmation.

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

Status: [ ]

Implement package enumeration using the Debian package ecosystem.

Retrieve where possible:

* package name
* display name
* version
* architecture
* installed size
* description
* package state

Handle package query errors gracefully.

⸻

MM-041 — Application list

Status: [ ]

Create Applications page.

Features:

* search
* sorting
* size
* name
* version
* details view

Avoid displaying technical package names as the only identity when a human-readable name is available.

⸻

MM-042 — Application details

Status: [ ]

Show:

* application name
* package name
* version
* architecture
* installed size
* description
* installation source where available

Actions:

* Uninstall

⸻

MM-043 — Uninstall

Status: [ ]

Implement safe .deb package removal.

Requirements:

* use dpkg/APT mechanisms
* do not manually delete /usr files
* show what package will be removed
* confirmation
* privilege escalation only when necessary
* display operation progress
* display errors

Never run the entire GUI as root.

⸻

PHASE 5 — Cleanup

MM-050 — Cleanup framework

Status: [ ]

Create explicit cleanup rules.

Each rule must define:

* identifier
* human-readable name
* description
* target paths
* estimated size
* risk level
* cleanup action
* whether privilege is required

Example:

Trash
APT cache
Known temporary files

⸻

MM-051 — Trash cleanup

Status: [ ]

Detect user trash.

Display:

* number of items
* total size

Actions:

* review
* empty trash

Do not delete trash without explicit user action.

⸻

MM-052 — APT cache cleanup

Status: [ ]

Detect removable APT package cache.

Display:

APT cache
1.2 GB

Explain what it is before deletion.

Use appropriate APT mechanisms rather than arbitrary deletion when possible.

⸻

MM-053 — Temporary file cleanup

Status: [ ]

Only target clearly defined temporary locations.

Do not treat all hidden files as temporary.

Do not recursively delete arbitrary directories.

⸻

MM-054 — Cleanup review

Status: [ ]

Create a review screen before destructive cleanup.

Display:

Selected:
✓ Trash
✓ APT cache
? Temporary files
Total:
4.2 GB
[ Cancel ]
[ Clean selected ]

User must understand exactly what will happen.

⸻

PHASE 6 — Overview

MM-060 — Overview page

Status: [ ]

Create a useful dashboard.

Show:

* storage usage
* largest storage category
* installed application count
* largest applications
* available cleanup candidates
* largest files

No fake statistics.

No decorative metrics.

⸻

MM-061 — Recent activity

Status: [ ]

Display only actions performed by the current Matrix Manager session.

Examples:

Deleted 1.4 GB
Uninstalled Firefox
Scanned Downloads

Do not implement telemetry.

⸻

PHASE 7 — Settings

MM-070 — Settings

Status: [ ]

Settings:

* Theme: System / Light / Dark
* Default large-file threshold
* Confirm destructive operations
* Follow symlinks: OFF by default
* Filesystem scan boundaries
* About

Avoid unnecessary settings.

⸻

MM-071 — About

Status: [ ]

Display:

* Matrix Manager
* version
* Qt version
* supported platforms
* license
* project information

No fake company information.

⸻

PHASE 8 — Reliability

MM-080 — Permission handling

Status: [ ]

Test:

* readable directory
* unreadable directory
* protected file
* root-owned file
* broken symlink
* mounted volume

The app must continue operating when individual entries cannot be accessed.

⸻

MM-081 — Cancellation

Status: [ ]

Long-running scans must support cancellation where practical.

Cancellation must leave the filesystem unchanged unless the user was explicitly performing a destructive operation.

⸻

MM-082 — Process execution safety

Status: [ ]

Audit every QProcess invocation.

Requirements:

* no unsafe shell interpolation
* separate program and arguments
* validate package names
* capture stdout/stderr
* timeout where appropriate
* clear error handling

⸻

PHASE 9 — UX / Hallmark audit

MM-090 — Hallmark-style design audit

Status: [ ]

Review the entire UI against the Hallmark philosophy.

Check for:

* generic card-grid layouts
* excessive rounded containers
* excessive gradients
* meaningless decoration
* weak hierarchy
* generic AI aesthetic
* unnecessary icons
* invented metrics
* inconsistent spacing
* inconsistent typography
* poor empty states
* poor loading states
* poor error states

The result should feel like a deliberate Linux utility, not generated SaaS UI.

Reference:

https://github.com/Nutlope/hallmark

⸻

MM-091 — Accessibility

Status: [ ]

Verify:

* keyboard navigation
* focus visibility
* sensible text contrast
* readable font sizes
* destructive actions are distinguishable
* status is not communicated by color alone

⸻

PHASE 10 — Performance

MM-100 — Startup performance

Status: [ ]

Application startup must NOT perform a full disk scan.

Only load:

* UI
* minimal system information
* lightweight initial state

⸻

MM-101 — Scan performance

Status: [ ]

Verify:

* worker-thread filesystem operations
* incremental results
* cancellation
* no unnecessary hashing
* no blocking GUI thread

⸻

PHASE 11 — Testing

MM-110 — Unit tests

Status: [ ]

Test:

* size formatting
* path handling
* cleanup rule evaluation
* package parsing
* filesystem classification
* duplicate grouping

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
