Matrix Manager — DOC.md

1. Product definition

Matrix Manager is a personal-use Linux desktop application for managing storage and installed .deb applications.

Primary goals:

1. Understand storage usage.
2. Find large files.
3. Manage installed applications.
4. Remove applications safely.
5. Clean clearly identifiable temporary/cache data.
6. Provide a modern, focused and trustworthy Linux UI.

The product intentionally avoids AI and background services.

⸻

2. Supported platforms

Official target:

Linux Mint
Ubuntu
Debian

Package ecosystem:

Debian / dpkg / APT
.deb

The application is not currently intended to support:

Arch
Fedora
openSUSE
Windows
macOS

Do not add cross-platform abstractions unless they provide real architectural value.

⸻

3. Product philosophy

Matrix Manager follows five principles:

Transparency

The user should know:

* what is being scanned
* what was found
* what will be deleted
* why an item is considered cleanable
* what permissions are required

Safety

Never guess that user data is disposable.

Performance

Do work only when necessary.

Local-first

No account.
No cloud.
No telemetry.
No mandatory network access.

Simplicity

Every feature must justify its existence.

⸻

4. What Matrix Manager is NOT

Matrix Manager is not:

* an antivirus
* a system optimizer
* a RAM booster
* a registry cleaner
* an AI assistant
* a background monitoring service
* a cloud backup tool
* a generic package manager for every Linux distribution

Avoid feature creep.

⸻

5. Core pages

Overview

Purpose:

Give the user a quick understanding of current storage state.

Possible content:

Disk usage
Free space
Largest categories
Largest applications
Largest files
Available cleanup candidates

Do not create fake KPI cards.

⸻

Storage

Purpose:

Explore filesystem usage.

Capabilities:

* storage volumes
* directory tree
* directory sizes
* file sizes
* sorting
* navigation
* treemap

The Storage page is exploratory, not an AI analysis page.

⸻

Applications

Purpose:

Manage installed .deb applications.

Capabilities:

* application list
* search
* sorting
* details
* uninstall

Package management should use the Debian package ecosystem.

⸻

Cleanup

Purpose:

Remove explicitly recognized disposable data.

Possible rules:

Trash
APT cache
selected temporary files
selected application caches

Each cleanup rule must be explicit.

⸻

Large Files

Purpose:

Find unusually large files.

The user chooses a threshold.

Default:

500 MB

The page must never automatically delete files.

⸻

Duplicates

Purpose:

Find identical files and show reclaimable storage.

The application must identify duplicates using deterministic hashing.

Never automatically choose which duplicate the user should keep.

⸻

Settings

Purpose:

Only expose settings that materially improve usability or safety.

⸻

6. Storage model

Conceptually:

Volume
  ↓
Directory
  ↓
File

A filesystem item may contain:

path
name
size
type
modifiedTime
permissions
isDirectory
isSymlink
isAccessible

Do not unnecessarily persist every filesystem entry.

⸻

7. Size formatting

Use human-readable binary units.

Example:

512 B
1.0 KiB
42.7 MiB
1.8 GiB
512.4 GiB

Use consistent formatting throughout the application.

Do not alternate randomly between:

MB
MiB
GB
GiB

Pick one convention and use it consistently.

⸻

8. Filesystem rules

Symbolic links

Do not recursively follow symbolic links by default.

Reason:

A symlink can point outside the intended scan tree or create cycles.

⸻

Permissions

An inaccessible file should not terminate an entire scan.

Represent it as:

inaccessible

and continue.

⸻

Special files

Avoid treating device nodes, sockets, FIFOs and other special filesystem objects as ordinary user files.

⸻

Mount boundaries

Be explicit about whether a scan crosses mounted filesystem boundaries.

Default behavior should be conservative.

⸻

9. Cleanup classification

Every cleanup rule has a risk level.

Suggested:

LOW
MEDIUM
HIGH

Examples:

LOW

Trash
APT package cache

MEDIUM

browser cache
application cache

HIGH

user-selected files

High-risk operations require explicit confirmation.

⸻

10. Important cleanup rule

“Large” does NOT mean “unnecessary”.

“Old” does NOT mean “unnecessary”.

“Hidden” does NOT mean “unnecessary”.

“Unused-looking” does NOT mean “unnecessary”.

Never create automatic deletion rules from those assumptions.

⸻

11. Application management

The initial application manager targets .deb packages.

Information hierarchy:

Human-readable name
    ↓
package name
    ↓
version
    ↓
architecture
    ↓
installed size

Where possible, use package metadata rather than guessing application identity from filenames.

⸻

12. Uninstallation

Uninstall flow:

User selects application
      ↓
Details screen
      ↓
User chooses Uninstall
      ↓
Confirmation
      ↓
Privilege request if required
      ↓
Package manager operation
      ↓
Progress/output
      ↓
Success or error
      ↓
Refresh application list

Never manually delete package-managed files.

⸻

13. Process execution

Prefer:

QProcess

with:

program
arguments

rather than:

shell command string

Bad:

sh -c "apt remove " + userInput

Better:

QProcess
    program = "apt"
    arguments = ["remove", packageName]

Validate package names and never assume user input is safe.

⸻

14. Privileged operations

Examples:

* uninstalling system packages
* deleting protected system cache

The GUI must remain unprivileged.

Use an appropriate desktop privilege mechanism when required.

Do not ask the user to launch Matrix Manager as root.

⸻

15. No background service

Matrix Manager only operates while the GUI is running.

No:

daemon
systemd service
autostart
cron
timer
permanent filesystem watcher

A scan begins because the user requested it or opened a feature requiring current data.

⸻

16. No AI/ML

There is deliberately no:

neural network
machine learning
LLM
AI inference
behavior learning

Recommendations are deterministic.

Example:

APT cache exists
    ↓
known cleanup rule
    ↓
show cleanup candidate

Not:

model predicts user wants to delete it

This makes the application:

* predictable
* offline
* lightweight
* auditable
* easier to maintain

⸻

17. Design system

The visual design is inspired by the design discipline of Hallmark.

Official reference:

https://github.com/Nutlope/hallmark

Hallmark’s current skill describes itself as an anti-AI-slop design system for AI coding assistants. Its principles include structural variety, design-context discovery, locked design tokens, self-critique and explicit avoidance of generic generated UI patterns.

Matrix Manager adopts the philosophy, not a literal visual clone.

Important Hallmark-derived principles:

Avoid generic layouts

Do not default to:

Sidebar
   ↓
giant hero
   ↓
3 cards
   ↓
3 more cards
   ↓
CTA

That pattern belongs to marketing websites, not necessarily desktop utilities.

⸻

18. Matrix Manager visual direction

The UI should feel:

Technical
Utilitarian
Precise
Calm
Native
Modern
Slightly distinctive

Avoid:

AI-purple gradients
glassmorphism
excessive rounded cards
floating blobs
meaningless decorative charts
fake statistics
marketing copy
oversized headings

The application should prioritize information density without becoming visually cluttered.

⸻

19. Layout philosophy

Desktop-first.

The application is not a responsive website.

Do not blindly import mobile web design rules into Qt.

However, the UI must still behave correctly when:

* window is narrow
* window is resized
* text is translated
* system font is larger

Important information must remain accessible.

⸻

20. Typography

Typography should establish hierarchy through:

* size
* weight
* spacing
* contrast

Avoid decorative typography.

Do not use italic display headings.

Use semantic font tokens.

⸻

21. Color

Use semantic colors.

Examples:

background
surface
surfaceElevated
border
textPrimary
textSecondary
textMuted
accent
success
warning
danger
focus

Never scatter raw hex/OKLCH values throughout QML.

⸻

22. Motion

Motion should explain state changes.

Good:

page transition
scan progress
item removal
dialog appearance
list update

Bad:

constant floating animations
decorative particles
excessive bouncing
animations that slow down routine operations

Animations must never block the user.

⸻

23. Empty states

Every feature needs a meaningful empty state.

Example:

No large files found
Try lowering the size threshold
or scan another location.

Avoid:

"Nothing here :)"

⸻

24. Loading states

Loading UI must explain what is happening.

Example:

Scanning Downloads…
14,283 files checked
[ Cancel ]

Do not display a spinner without context for long operations.

⸻

25. Error states

Errors should be actionable.

Example:

Unable to scan this directory
/home/user/example
Permission denied.
[ Retry ]

Technical details may be available through an expandable section.

⸻

26. Confirmation dialogs

A destructive confirmation should include:

Action
Target
Size
Consequence

Example:

Delete 24 files?
Total size: 3.8 GiB
These files will be moved/deleted according
to the selected operation.
[ Cancel ] [ Delete ]

Do not use vague:

"Are you sure?"

⸻

27. Data freshness

Because Matrix Manager does not run in the background, data can become stale while the app is open.

Therefore provide:

Refresh

where appropriate.

After an operation such as uninstall or cleanup:

refresh affected models

Do not pretend cached information is live.

⸻

28. Threading

GUI:

main Qt thread

Filesystem-heavy work:

worker thread / Qt concurrent mechanism

Package queries:

asynchronous process execution

UI models should receive incremental updates where useful.

Never freeze the main GUI thread during large scans.

⸻

29. Persistence

Persistence should be minimal.

Only persist information that provides real user value.

Potential persisted settings:

theme
large-file threshold
confirmation preferences

Do not persist:

* full filesystem maps unnecessarily
* file contents
* unnecessary user behavior
* telemetry

If history is implemented, store only the minimal aggregate information required.

⸻

30. Privacy

All data remains local.

Matrix Manager should not require:

* account
* internet connection
* cloud API
* telemetry endpoint

Do not add analytics SDKs.

⸻

31. Testing strategy

Filesystem tests must use temporary directories.

Never let automated tests delete:

/home
/
/usr
/etc
real user directories

Package-manager integration tests must be isolated from the developer’s real package state whenever possible.

⸻

32. Build

Expected basic workflow:

cmake -S . -B build
cmake --build build

Testing:

ctest --test-dir build

Exact commands may differ if the project evolves.

⸻

33. Release philosophy

A release is acceptable when it is:

* reliable
* understandable
* safe
* fast enough
* visually coherent

A larger feature count does not make a better release.

⸻

34. Future ideas

These are NOT MVP requirements.

Possible future features:

* storage history
* better duplicate management
* removable-drive support
* custom cleanup rules
* .desktop metadata integration
* Flatpak support
* AppImage discovery
* exportable storage reports

Do not implement future ideas until their corresponding task exists in TASK.md.

⸻

35. Design reference

Hallmark:

https://github.com/Nutlope/hallmark

Hallmark README:

https://github.com/Nutlope/hallmark

Hallmark skill:

https://github.com/Nutlope/hallmark/blob/main/skills/hallmark/SKILL.md

The current Hallmark project describes its skill as an anti-AI-slop design system and includes design-flow, token, self-critique, responsive and interaction guidance. Matrix Manager should adapt the relevant principles to Qt desktop UI rather than copying web-specific behavior.

⸻

36. Final product sentence

If the agent needs a single sentence to understand the product:

Matrix Manager is a lightweight, local-first Qt 6 Linux utility that lets users visually understand their storage, manage .deb applications and safely clean clearly identifiable disposable data without AI, telemetry or background services.
