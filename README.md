# Matrix Manager

A lightweight, local-first Qt 6 Linux utility that lets you visually
understand your storage, manage .deb applications and safely clean clearly
identifiable disposable data — without AI, telemetry or background services.

![Platform](https://img.shields.io/badge/platform-Linux%20Mint%20%2F%20Ubuntu%20%2F%20Debian-blue)
![Qt](https://img.shields.io/badge/Qt-6.2%2B-green)
![License](https://img.shields.io/badge/license-MIT-informational)

## What it does

| Page | Purpose |
|------|---------|
| **Overview** | Real disk usage, cleanup candidate sizes, installed package totals and session activity. Only cheap data is read automatically; everything expensive is loaded on demand. |
| **Storage** | Mounted volumes (capacity, used, free, filesystem, mount point) and an on-demand directory usage explorer with incremental results, cancellation and honest error reporting. Includes a Home folder breakdown with an explicit "Other" remainder. |
| **Applications** | Installed .deb packages via `dpkg-query`: search, sort by size/name/version, details view, and safe uninstall through the system package manager. |
| **Cleanup** | Three explicit, rule-based candidates: user trash, APT package cache and thumbnail cache. Each rule explains what it is, what it costs and what will happen. Nothing runs without a review step. |
| **Large Files** | Find files above a threshold (100 MB / 500 MB / 1 GB / 5 GB). Open, show in folder, or move to trash after explicit confirmation. |
| **Duplicates** | Honest placeholder — planned as task MM-032. |
| **Settings** | Theme (System/Light/Dark), default large-file threshold, destructive-confirmation preference, scan boundary options, About. |

## Product principles

Matrix Manager follows a strict set of rules (see `AGENT.md` and `DOC.md`):

- **Local only.** No account, no network access, no telemetry, no analytics.
  All data stays on the machine; even the activity log lives only in memory.
- **No AI.** Every recommendation is a deterministic, auditable rule.
- **No background services.** The app works only while it is open. Closing it
  stops all application-owned work. No daemon, no autostart, no watchers.
- **Never guess that user data is disposable.** "Large", "old" or "hidden"
  never means "junk". Cleanup candidates come from fixed rules only.
- **Destructive operations are explicit.** Every dangerous action shows its
  target, size and consequence before running, and destructive package
  operations always require confirmation.
- **Minimum privileges.** The GUI never runs as root. Privilege is requested
  through `pkexec` only at the operation boundary that needs it.
- **Safe process execution.** Program and arguments are always separate —
  no shell strings are ever constructed from user-controlled values, and
  package names are strictly validated.
- **No startup scans.** Launching the app reads no filesystem trees and runs
  no package queries until you ask for them.

## Building

### Requirements

- Linux Mint 21+, Ubuntu 22.04+ or Debian 12+
- Qt 6.2 or newer (Core, Gui, Qml, Quick, QuickControls2)
- CMake 3.16+
- A C++20 compiler (GCC 10+, Clang 12+)

### Install dependencies (Debian family)

The project is a Qt Quick (QML) application, so it needs the Qt declarative
development package in addition to the base Qt package. It also needs the
runtime QML modules at launch time — these are separate packages from the
`-dev` ones and are not installed automatically by `qt6-declarative-dev`.

```bash
sudo apt install build-essential cmake \
    qt6-base-dev qt6-declarative-dev qt6-base-dev-tools \
    libgl1-mesa-dev libxkbcommon-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    qml6-module-qtqml-workerscript
```

What each Qt package is for:

| Package | Why it is needed |
|---|---|
| `qt6-base-dev` | Qt Core / Gui development files (build) |
| `qt6-declarative-dev` | Qt Qml / Quick / QuickControls2 development files (build) |
| `libxkbcommon-dev` | Keyboard input support for Qt Gui (build) |
| `qml6-module-qtquick*` | Runtime QML modules: QtQuick, Controls (Basic style), Layouts (run) |
| `qml6-module-qtqml-workerscript` | Runtime helper module required by QtQuick (run) |

If a build already failed because of a missing Qt component, delete the
stale build directory before reconfiguring:

```bash
rm -rf build
```

### Build and run

```bash
cmake -S . -B build
cmake --build build
./build/matrix-manager
```

Both Debug and Release configurations are supported:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
```

### Run the unit tests

```bash
cmake --build build --target tst_sizeutils tst_packageparser tst_cleanuprules
ctest --test-dir build
```

### Install system-wide

```bash
sudo cmake --install build
```

This installs the binary to `/usr/bin`, a desktop entry to
`/usr/share/applications` and the application icon to the hicolor theme.

## Architecture

```
src/
├── core/               Size formatting, settings, activity log, system info
├── filesystem/         FileWalker, StorageService, DirectoryScanner,
│                       LargeFileService (+ model)
├── packages/           PackageService (dpkg-query / apt-get via pkexec),
│                       PackageModel
├── cleanup/            CleanupService (rules, estimates, safe execution)
├── platform/linux/     ProcessRunner (safe QProcess wrapper)
└── main.cpp            Entry point, QML type registration

qml/
├── Main.qml            Application shell: sidebar navigation + pages
├── theme/Theme.qml     Design token singleton (both themes)
├── components/         20 reusable styled controls
└── pages/              Overview, Storage, Applications, Cleanup,
                        Large Files, Duplicates, Settings

tests/                  QtTest unit tests (ctest integration)
packaging/              .desktop entry
resources/              Application icon
```

Key design decisions:

- **Worker threads.** All filesystem traversal runs off the GUI thread with
  incremental partial results and cancellation.
- **Symlink safety.** Symbolic links are never followed recursively by
  default; enabling the setting adds cycle detection via `(dev, inode)`.
- **Mount boundaries.** Scans stay on one filesystem unless explicitly
  allowed in Settings; crossing a boundary is reported, not hidden.
- **pkexec at the boundary.** `apt-get remove` and `apt-get clean` run
  through `pkexec env DEBIAN_FRONTEND=noninteractive ...`, so the GUI stays
  unprivileged and no environment leaks through polkit's sanitisation.
- **Verified builds.** The application builds and runs against Qt 6.8, and
  the complete C++ core compiles against Qt 6.2.4 headers (the oldest
  supported distribution base).

## Roadmap

Everything not yet implemented is tracked in `TASK.md` with honest status
markers. Highlights:

- Storage treemap visualisation (MM-023)
- Filesystem search (MM-031)
- Duplicate file detection (MM-032)
- Integration tests with temporary directories (MM-111)
- Full release test matrix on Mint / Ubuntu / Debian (MM-112)

## License

MIT — see [LICENSE](LICENSE).
