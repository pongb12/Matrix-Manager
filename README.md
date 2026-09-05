# Matrix Manager

A lightweight, local-first Qt 6 Linux utility that lets you visually
understand your storage, manage .deb applications and safely clean clearly
identifiable disposable data — without AI, telemetry or background services.
Interface language: **Vietnamese by default**, English included.

![Platform](https://img.shields.io/badge/platform-Linux%20Mint%20%2F%20Ubuntu%20%2F%20Debian-blue)
![Qt](https://img.shields.io/badge/Qt-6.2%2B-green)
![License](https://img.shields.io/badge/license-MIT-informational)

## What it does

| Page | Purpose |
|------|---------|
| **Overview** | Real disk usage, cleanup candidate sizes, installed package totals and session activity. Only cheap data is read automatically; everything expensive is loaded on demand. |
| **Storage** | Mounted volumes (capacity, used, free, filesystem, mount point) and an on-demand directory usage explorer with incremental results, cancellation and honest error reporting. Includes a Home folder breakdown with an explicit "Other" remainder, a **filesystem search** (name / extension / size range, MM-031) and a **treemap** view (MM-023) colour-coded by file category with a legend; the table remains the accessible alternative. |
| **Applications** | Installed .deb packages via `dpkg-query`, grouped into categories derived from package sections (chips + section headers): search, sort by size/name/version, details view, and safe uninstall through the system package manager. |
| **Cleanup** | Three explicit, rule-based candidates: user trash, APT package cache and thumbnail cache. Each rule explains what it is, what it costs and what will happen. Nothing runs without a review step. |
| **Large Files** | Find files above a threshold — presets (100 MB / 500 MB / 1 GB / 5 GB) **or any custom size** you type. Open, show in folder, or move to trash after explicit confirmation. |
| **Duplicates** | Content-based duplicate detection (MM-032): files are compared by size first and hashed only when needed. Duplicate groups are shown with every member; you pick what goes to the trash and review the list before anything happens. |
| **Settings** | **Language (Tiếng Việt / English, applied live)**, theme (System/Light/Dark), default large-file threshold, destructive-confirmation preference, scan boundary options, **guided tour**, About. |

## Interface tour and icons

- **Guided tour.** Settings → **Guide** opens a short animated tour: a brief
  introduction first, then a spotlight that walks through every section with
  explanations (scanning, treemap, search, large files, duplicates,
  applications, cleanup). Back/Next navigation, replayable anytime.
- **Browse buttons.** Every path field (Storage, Storage search, Large Files,
  Duplicates) has a **Browse** button that opens the system folder picker;
  the manual path entry stays available.
- **Icons.** The interface uses a consistent icon set derived from
  [Lucide](https://lucide.dev) (ISC license, see
  `resources/icons/LICENSE-NOTES.md`), recolored for the light and dark
  themes. The icons ship **inside the application** — nothing is fetched
  from the network at runtime.
- **Animations.** Section switches, the sidebar selection indicator,
  buttons and the treemap have short, restrained transitions built from the
  theme's motion tokens.

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
sudo apt update
sudo apt install build-essential cmake \
    qt6-base-dev qt6-declarative-dev qt6-svg-dev qt6-base-dev-tools \
    libgl1-mesa-dev libxkbcommon-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-templates \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    qml6-module-qtquick-dialogs \
    qml6-module-qt-labs-platform \
    qml6-module-qtqml-workerscript
```

What each Qt package is for:

| Package | Why it is needed |
|---|---|
| `qt6-base-dev` | Qt Core / Gui development files (build) |
| `qt6-declarative-dev` | Qt Qml / Quick / QuickControls2 development files (build) |
| `qt6-svg-dev` | Qt SVG development files — the app links Qt6::Svg so the SVG icon set can be decoded (build) |
| `libxkbcommon-dev` | Keyboard input support for Qt Gui (build) |
| `qml6-module-qtquick*` | Runtime QML modules: QtQuick, Controls (Basic style), Templates, Layouts (run) |
| `qml6-module-qtquick-dialogs` | Runtime QML module for the folder picker used by the Browse buttons (run, Qt 6.3+) |
| `qml6-module-qt-labs-platform` | Native folder-picker fallback used on Qt 6.2 (run) |
| `qml6-module-qtqml-workerscript` | Runtime helper module required by QtQuick (run) |
| `libqt6svg6` | SVG image-format plugin that decodes the bundled UI icons (run) |

> **Icons invisible after installing?** The UI icon set consists of SVG
> files decoded by Qt's SVG image-format plugin. That plugin lives in the
> `libqt6svg6` runtime package and is dlopened (not linked), so it is easy
> to miss when running from source. The generated .deb depends on it
> automatically; when launching a manually built binary, install
> `libqt6svg6` yourself. Since 1.0.3-2 the application also prints a
> one-line warning at startup if the plugin is missing.

If a build already failed because of a missing Qt component, delete the
stale build directory before reconfiguring:

```bash
rm -rf build
```

### Build and run (developer mode)

```bash
cmake -S . -B build
cmake --build build
./build/matrix-manager
```

Both Debug and Release configurations are supported:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
```

### Run the tests

```bash
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

Five suites run: size formatting, dpkg-query parsing, the package list
model (category classification/filtering), cleanup rules,
duplicate detection, filesystem search and process-output capture. The
filesystem suites create their data inside `QTemporaryDir` and never touch
your real home directory.

### Build and install the .deb package (recommended for daily use)

The project packages itself with CPack. The .deb declares **every Qt
runtime library and QML module it needs**, so the package manager resolves
all dependencies from your distribution's repositories automatically.

**Step 1 — build dependencies.** Install the same package set as above
(the "Install dependencies" section). These are only needed to compile.

**Step 2 — build and package:**

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
cpack --config build/CPackConfig.cmake -G DEB
```

The result is `matrix-manager_<version>_amd64.deb` in the project root
(the version comes from `project(... VERSION ...)` in `CMakeLists.txt`,
with `CPACK_DEBIAN_PACKAGE_RELEASE` adding a Debian-style revision, e.g.
`matrix-manager_1.0.3-1_amd64.deb`).

**Step 3 — install the package:**

```bash
sudo apt install ./matrix-manager_1.0.3-1_amd64.deb
```

> **Why `apt install ./file.deb` and not `dpkg -i file.deb`?**
> `apt` reads the package's `Depends:` field and installs every missing Qt
> runtime library and QML module from the repository in the same
> transaction. `dpkg -i` performs no dependency resolution — the package
> ends up "installed" but broken until you run `sudo apt -f install`.
> If you prefer `dpkg -i`, follow it with `sudo apt -f install` and it
> will end up in the same state.

**Step 4 — run:**

- From the application menu: **Matrix Manager** (icon installed to the
  hicolor theme), or
- from a terminal: `matrix-manager`

**Step 5 — uninstall:**

```bash
sudo apt remove matrix-manager
```

Notes:

- **Build the .deb on the distro release you target.** A package built on
  Mint 22 / Ubuntu 24.04 links against that system's Qt 6.4 libraries; a
  package built on Mint 21 / Ubuntu 22.04 works on Qt 6.2 systems. The
  dependency list uses the `libqt6core6t64 | libqt6core6` alternative
  syntax so it validates on both jammy and noble.
- The .deb installs `/usr/bin/matrix-manager`, a desktop entry and the
  application icon. No configuration is stored outside
  `~/.config/MatrixManager/`.
- Prefer no packaging at all? `sudo cmake --install build` performs a
  plain install of the same three files without dependency declaration.

### Translations

The interface is translated with Qt Linguist tooling. The compiled
Vietnamese catalog (`translations/matrix-manager_vi.qm`) is committed and
embedded into the binary — building the app requires **no** Linguist tools.

If you edit UI strings or the translation:

1. Regenerate the `.ts` catalog and compile it:

   ```bash
   lupdate -recursive qml -ts translations/matrix-manager_vi.ts
   lrelease translations/matrix-manager_vi.ts
   ```

2. Rebuild the app. `lrelease`/`lupdate` come from the Qt installation
   (`qt6-l10n-tools` on Debian-family distributions).

The default language is Vietnamese; users can switch to English in
**Settings → Language**, and the choice is applied immediately without a
restart.

## Architecture

```
src/
├── core/               Size formatting, settings, translations, activity
│                       log, system info
├── filesystem/         FileWalker, StorageService, DirectoryScanner,
│                       DuplicateScanner, FileSearcher,
│                       LargeFileService (+ model)
├── packages/           PackageService (dpkg-query / apt-get via pkexec),
│                       PackageModel
├── cleanup/            CleanupService (rules, estimates, safe execution)
├── platform/linux/     ProcessRunner (safe QProcess wrapper)
└── main.cpp            Entry point, QML type registration

qml/
├── Main.qml            Application shell: sidebar navigation + pages
├── theme/Theme.qml     Design token singleton (both themes)
├── components/         23 reusable styled controls (incl. MMTreemap,
│                        MIcon, MGuideOverlay)
└── pages/              Overview, Storage, Applications, Cleanup,
                        Large Files, Duplicates, Settings

tests/                  QtTest suites (ctest integration)
translations/           Vietnamese catalog (.ts + compiled .qm)
packaging/              .desktop entry
resources/              Application icon + themed UI icons (Lucide-derived)
```

Key design decisions:

- **Worker threads.** All filesystem traversal runs off the GUI thread with
  incremental partial results and cancellation.
- **Symlink safety.** Symbolic links are never followed recursively by
  default; enabling the setting adds cycle detection via `(dev, inode)`.
- **Mount boundaries.** Scans stay on one filesystem unless explicitly
  allowed in Settings; crossing a boundary is reported, not hidden.
- **Duplicate detection without blind hashing.** Files are grouped by size,
  split by a partial 4 KiB hash and fully hashed only when needed (MM-032).
- **pkexec at the boundary.** `apt-get remove` and `apt-get clean` run
  through `pkexec env DEBIAN_FRONTEND=noninteractive ...`, so the GUI stays
  unprivileged and no environment leaks through polkit's sanitisation.
- **Verified builds.** The application builds and runs against Qt 6.8 and
  Qt 6.2.4 (bracketing Mint 22's Qt 6.4), with screenshots captured from
  automated offscreen UI runs; all six test suites pass on both.

## Roadmap

Everything not yet implemented is tracked in `TASK.md` with honest status
markers. Highlights:

- Accessibility and design audit passes on a real desktop (MM-090, MM-091)
- Permission edge-case verification on real hardware (MM-080)
- Full release test matrix on Mint / Ubuntu / Debian (MM-112)

## License

MIT — see [LICENSE](LICENSE).
