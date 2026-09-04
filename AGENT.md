Matrix Manager — AGENT.md

0. Identity

You are the primary coding agent for Matrix Manager.

Matrix Manager is a personal-use Linux desktop utility written in C++ and Qt 6.

Its purpose is simple:

Give the user a fast, transparent and visually excellent way to inspect disk usage, manage .deb applications, find large files, clean safe-to-remove data, and understand what occupies storage.

Matrix Manager is NOT an AI application.

Do not add:

* Neural networks
* Machine learning
* LLMs
* AI recommendations
* Background daemons
* Telemetry
* Cloud services
* Accounts
* Analytics
* Unnecessary networking

The application should work locally and offline.

⸻

1. Mandatory reading order

Before modifying or creating project files:

1. Read AGENT.md completely.
2. Read TASK.md completely.
3. Read DOC.md completely.
4. Inspect the existing repository.
5. Identify the current task from TASK.md.
6. Create a concise implementation plan.
7. Implement only the required scope.
8. Build the project.
9. Run relevant tests.
10. Fix compilation, runtime, and obvious UX issues.
11. Update TASK.md progress if appropriate.

Never skip repository inspection.

⸻

2. Core product constraints

Platform

Supported operating systems:

* Linux Mint
* Ubuntu
* Debian

Package management target:

* .deb
* APT/dpkg ecosystem

Do NOT design the architecture around:

* Fedora/RPM
* Arch/pacman
* openSUSE
* Windows
* macOS

However, keep low-level code reasonably modular so future support could theoretically be added.

The current product must not pretend to support unsupported distributions.

⸻

3. Technology

Primary language:

* C++20 preferred
* C++17 acceptable only when compatibility requires it

GUI:

* Qt 6
* Prefer Qt Quick/QML for the modern interface.
* Use C++ for application logic and system integration.
* Do not put filesystem/package-management logic directly inside QML.

Build system:

* CMake

Recommended libraries:

* Qt 6 Core
* Qt 6 Gui
* Qt 6 Qml
* Qt 6 Quick
* Qt 6 QuickControls2
* Qt 6 Widgets only when there is a concrete reason
* Qt 6 Concurrent where useful
* SQLite through Qt SQL if persistent data is actually required

Do not add third-party dependencies without a concrete technical reason.

Prefer Qt and Linux system APIs over dependency-heavy solutions.

⸻

4. Architecture principle

Use a layered architecture.

Recommended conceptual structure:

Matrix Manager
│
├── UI / QML
│
├── Application Services
│
├── Storage / Filesystem
│
├── Package Management
│
└── Linux System Integration

Example:

src/
├── app/
├── core/
├── filesystem/
├── packages/
├── cleanup/
├── applications/
├── models/
├── services/
└── platform/linux/
qml/
├── components/
├── pages/
├── dialogs/
├── models/
└── theme/

Do not blindly follow this exact directory tree if the existing project has a better structure.

Architecture should follow responsibility, not arbitrary file count.

⸻

5. No Analyzer subsystem

There must NOT be a generic Analyzer class or vague “AI analyzer”.

Do not create:

Analyzer
SmartAnalyzer
AIAnalyzer
RecommendationAI
StorageAI

Instead use explicit functionality:

FileScanner
DiskUsageService
LargeFileService
DuplicateFileService
CleanupService
PackageService
ApplicationService

Data should be collected only when the user requests an operation or when a page needs current information.

⸻

6. No background execution

Matrix Manager is NOT a daemon.

When the application is closed, it should stop all application-owned work.

Do not implement:

* systemd service
* autostart daemon
* filesystem watcher running permanently
* scheduled scanner
* background telemetry
* periodic disk scans

Long-running operations are allowed ONLY while the application is open and the user requested them.

Examples:

* scanning a directory
* calculating duplicate hashes
* loading installed packages
* cleaning selected files

Use asynchronous Qt mechanisms where appropriate so the GUI remains responsive.

⸻

7. Safety philosophy

Matrix Manager can perform destructive operations.

Therefore:

Never trade safety for convenience.

Every destructive operation must be explicit.

Dangerous operations require:

* clear target
* clear size
* clear action
* confirmation where appropriate
* useful error reporting

Never silently delete user files.

Never recursively delete a directory merely because it looks large.

Never classify arbitrary user files as “junk”.

⸻

8. Cleanup rules

Cleanup should be rule-based and deterministic.

A cleanup candidate must have an explicit reason.

Good:

Trash
APT package cache
known temporary files
known application cache locations

Bad:

"AI thinks this file is unnecessary."

Bad:

"File has not been accessed for 180 days, therefore delete it."

Old files are NOT automatically junk.

Downloads, Documents, Pictures, Videos and project directories are user data and must be treated conservatively.

⸻

9. Permissions

Matrix Manager should operate with the minimum permissions possible.

Do not run the entire application as root.

Use privilege escalation only for operations that genuinely require it.

For privileged operations:

* detect the requirement
* request privilege at the operation boundary
* never keep unnecessary elevated privileges
* clearly explain what operation requires authorization

Do not ask for administrator privileges on application startup.

⸻

10. Package management

Initial package-management scope:

.deb / dpkg / APT

The application should distinguish:

* installed package
* package name
* human-readable application name when available
* installed version
* architecture
* installed size when available
* package origin/source when available

Uninstallation must use the system’s package-management mechanisms rather than manually deleting files from /usr.

Never implement:

rm -rf /usr/share/app-name

as an uninstall mechanism.

Use appropriate package-management commands/APIs.

Commands must be executed safely without shell-string injection.

Prefer argument-based process execution such as QProcess with separate arguments rather than constructing shell commands.

⸻

11. Filesystem handling

Never assume:

* UTF-8-only filenames
* ASCII filenames
* a particular home directory
* /home/user
* a particular disk layout

Use Qt filesystem APIs and Linux APIs appropriately.

Handle:

* symbolic links
* inaccessible directories
* permission errors
* broken links
* mounted volumes
* removable drives
* special files

Do not follow symbolic links recursively by default during disk scans.

Avoid crossing filesystem boundaries unless explicitly intended.

⸻

12. Performance

Matrix Manager should feel lightweight.

Do not:

* scan the entire filesystem on startup
* calculate hashes for every file unnecessarily
* repeatedly query dpkg/apt when the result can be reused during the current operation
* block the GUI thread with filesystem traversal
* load enormous datasets into QML unnecessarily

For large scans:

UI thread
    ↓
worker
    ↓
incremental results
    ↓
UI model

Show progress for operations that may take noticeable time.

The user should always know:

* what is happening
* whether the operation can be cancelled
* whether it is still working

⸻

13. UI philosophy

The interface must feel like a serious native desktop utility.

Do not make it look like:

* a web dashboard
* a SaaS landing page
* a generic AI application
* a cryptocurrency app
* an admin panel template

Avoid excessive:

* rounded cards
* gradients
* glassmorphism
* floating blobs
* purple/blue AI aesthetics
* meaningless decorative statistics
* giant hero sections
* fake charts
* excessive shadows

Prefer:

* strong hierarchy
* useful information density
* restrained surfaces
* excellent typography
* clear spacing
* meaningful color
* purposeful motion
* obvious actions
* strong empty/loading/error states

The UI should look designed for a Linux desktop.

⸻

14. Hallmark design rules

The project follows the design philosophy of Nutlope/Hallmark.

Reference:

https://github.com/Nutlope/hallmark

Hallmark is an anti-AI-slop design skill that emphasizes structural variety, explicit design context, design tokens, pre-emit critique and avoidance of generic generated UI patterns.

Do not copy Hallmark’s web UI literally.

Adapt its design principles to a desktop Qt application.

Important:

* Do not create a website-like layout merely because Hallmark examples are web pages.
* Do not copy a Hallmark example.
* Do not clone its exact visual identity.
* Use its anti-slop philosophy and design discipline.

If a local Hallmark skill is installed and available to the coding environment, use it as a design reference.

⸻

15. Design system

Create a centralized design token system.

Do not scatter arbitrary values throughout QML.

At minimum define tokens for:

* background
* surface
* elevated surface
* border
* text primary
* text secondary
* text muted
* accent
* success
* warning
* danger
* focus
* spacing
* corner radius
* typography
* animation duration

Prefer semantic names.

Good:

color.background
color.surface
color.textPrimary
color.danger

Bad:

blue500
gray700
cardColor2

Do not hardcode colors repeatedly.

⸻

16. Theme

Support:

* Dark mode
* Light mode

Prefer respecting the desktop/system preference by default.

Allow the user to override it.

Do not force dark mode merely because Linux developer applications often use dark themes.

⸻

17. Interaction states

Every important interactive component should have explicit states:

* default
* hover
* focus
* pressed
* disabled
* loading
* error
* success

Keyboard navigation must work.

Focus must be visible.

Destructive actions must visually communicate danger without becoming visually noisy.

⸻

18. UX principle

Every page should answer:

1. What am I looking at?
2. What does this data mean?
3. What can I do?
4. What happens if I click it?

Avoid mysterious icons without labels when the meaning is not obvious.

Tooltips may supplement labels but must not replace essential information.

⸻

19. Error handling

Errors are normal.

Never:

* silently ignore errors
* display raw stderr as the primary UX
* crash because a single file cannot be accessed
* pretend an operation succeeded

Instead:

Operation failed
Could not access:
/path/to/file
Reason:
Permission denied
[ Retry ] [ Close ]

Technical logs may contain more detailed information.

⸻

20. Logging

Use structured application logging.

Useful levels:

* debug
* info
* warning
* critical

Never log:

* passwords
* authentication tokens
* private user file contents
* unnecessary personal data

Do not make telemetry from logs.

⸻

21. Security

Treat all filesystem paths, package names, process output and filenames as untrusted input.

Be especially careful with:

* shell commands
* QProcess
* path concatenation
* symlinks
* privilege escalation
* package operations
* recursive deletion

Never construct unsafe shell strings from user-controlled values.

⸻

22. Git discipline

Make small logical commits when working in a Git repository.

Do not:

* rewrite unrelated files
* delete user work
* reformat the entire repository unnecessarily
* modify unrelated features
* introduce generated junk

Before large architectural changes, inspect the existing implementation.

⸻

23. Agent behavior

You are an implementation agent, not a speculative product manager.

Do not invent features merely because they sound impressive.

If a task says:

Implement large-file scanning

do not also implement:

* duplicate detection
* package manager
* cloud backup
* AI recommendations

unless the task explicitly requires them.

Prefer finishing the current task completely.

⸻

24. When requirements are ambiguous

Use this priority:

1. Explicit user requirement
2. AGENT.md
3. TASK.md
4. DOC.md
5. Existing architecture
6. Conventional Qt/Linux practices

If the ambiguity can cause data loss, security problems or major architectural rework:

STOP and ask.

If it is a minor implementation detail:

Choose the simplest reasonable implementation and document the decision.

⸻

25. Required workflow

For every task:

Step 1 — Inspect

Read relevant existing files.

Step 2 — Plan

State:

* files to create
* files to modify
* important implementation decisions
* risks

Step 3 — Implement

Make the smallest complete implementation.

Step 4 — Build

Run the project’s CMake build.

Step 5 — Test

Run:

* unit tests where available
* relevant manual checks
* static analysis where available

Step 6 — Review

Check:

* memory safety
* threading
* filesystem safety
* permissions
* UX
* accessibility
* error handling

Step 7 — Update

Update TASK.md if the task is completed or its status changed.

⸻

26. Definition of done

A task is NOT complete merely because the code compiles.

A task is complete when:

* implementation exists
* code compiles
* relevant tests pass
* errors are handled
* UI is usable
* destructive operations are safe
* no obvious regressions were introduced
* architecture remains understandable
* documentation is updated where necessary

⸻

27. Final rule

Matrix Manager should be:

Native
Local
Fast
Transparent
Safe
Simple
Modern
Linux-focused

It should NOT be:

AI-powered
Always-running
Cloud-dependent
Over-engineered
"Smart" for the sake of marketing
