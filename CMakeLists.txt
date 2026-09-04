cmake_minimum_required(VERSION 3.16)

project(MatrixManager VERSION 1.0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type (Debug/Release/RelWithDebInfo)" FORCE)
endif()

# ---------------------------------------------------------------------------
# Qt 6 dependencies
# Qt 6.2 is the minimum supported version (Ubuntu 22.04 LTS / Linux Mint 21.x).
# ---------------------------------------------------------------------------
# Resolve OpenGL first so the OpenGL::* imported targets exist in every
# scope (Qt's WrapOpenGL references them). Harmless on systems with a
# complete OpenGL installation.
find_package(OpenGL REQUIRED)

find_package(Qt6 6.2 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

qt_add_executable(matrix-manager
    src/main.cpp
    src/core/SizeUtils.cpp
    src/core/SystemInfo.cpp
    src/core/SettingsService.cpp
    src/core/ActivityLog.cpp
    src/platform/linux/ProcessRunner.cpp
    src/filesystem/FileWalker.cpp
    src/filesystem/StorageService.cpp
    src/filesystem/DirectoryScanner.cpp
    src/filesystem/LargeFileService.cpp
    src/packages/PackageModel.cpp
    src/packages/PackageService.cpp
    src/cleanup/CleanupService.cpp
)

# Static library holding the application core. Unit tests link against it so
# that pure logic (size formatting, package parsing, cleanup rules) can be
# tested without the QML front end.
add_library(matrix_core STATIC
    src/core/SizeUtils.cpp
    src/core/SystemInfo.cpp
    src/core/SettingsService.cpp
    src/core/ActivityLog.cpp
    src/platform/linux/ProcessRunner.cpp
    src/filesystem/FileWalker.cpp
    src/filesystem/StorageService.cpp
    src/filesystem/DirectoryScanner.cpp
    src/filesystem/LargeFileService.cpp
    src/packages/PackageModel.cpp
    src/packages/PackageService.cpp
    src/cleanup/CleanupService.cpp
)
target_include_directories(matrix_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_compile_features(matrix_core PUBLIC cxx_std_20)
target_compile_definitions(matrix_core PUBLIC MM_APP_VERSION="${PROJECT_VERSION}")
target_link_libraries(matrix_core PUBLIC Qt6::Core Qt6::Gui)
# The static library must not collide with the executable's copy when linking.
set_target_properties(matrix_core PROPERTIES POSITION_INDEPENDENT_CODE ON)

target_include_directories(matrix-manager PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_compile_features(matrix-manager PRIVATE cxx_std_20)
target_link_libraries(matrix-manager PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    matrix_core
)

target_compile_definitions(matrix-manager PRIVATE
    QT_MESSAGELOGCONTEXT
)

# Optional QA instrumentation for automated UI checks (screenshots, model
# probes). Off by default; enable with -DMM_QA_SUPPORT=ON.
option(MM_QA_SUPPORT "Compile QA hooks (file logger for UI checks)" OFF)
if(MM_QA_SUPPORT)
    target_compile_definitions(matrix-manager PRIVATE MM_QA_SUPPORT)
endif()

# ---------------------------------------------------------------------------
# QML modules
# All modules share RESOURCE_PREFIX /qml; the engine adds "qrc:/qml" as an
# import path at startup. URI maps to the resource directory, e.g.
#   MatrixManager.Theme      -> qrc:/qml/MatrixManager/Theme/qmldir
#
# Each module gets its own static target (qt_add_qml_module allows one
# module per target). The executable links them so their registration code
# is pulled in.
# ---------------------------------------------------------------------------
set_source_files_properties(qml/theme/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

# Give every QML module its own output directory below build/qml.
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)

qt_add_library(mm_theme STATIC)
qt_add_qml_module(mm_theme
    URI MatrixManager.Theme
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        qml/theme/Theme.qml
)

qt_add_library(mm_components STATIC)
qt_add_qml_module(mm_components
    URI MatrixManager.Components
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        qml/components/MBadge.qml
        qml/components/MButton.qml
        qml/components/MCard.qml
        qml/components/MCheckBox.qml
        qml/components/MConfirmationDialog.qml
        qml/components/MDestructiveButton.qml
        qml/components/MEmptyState.qml
        qml/components/MErrorState.qml
        qml/components/MIconButton.qml
        qml/components/MListItem.qml
        qml/components/MLoadingState.qml
        qml/components/MPageHeader.qml
        qml/components/MProgressBar.qml
        qml/components/MSearchField.qml
        qml/components/MSecondaryButton.qml
        qml/components/MSegmented.qml
        qml/components/MSwitch.qml
        qml/components/MToast.qml
        qml/components/MUsageBar.qml
        qml/components/MValueRow.qml
)

qt_add_library(mm_pages STATIC)
qt_add_qml_module(mm_pages
    URI MatrixManager.Pages
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        qml/pages/OverviewPage.qml
        qml/pages/StoragePage.qml
        qml/pages/ApplicationsPage.qml
        qml/pages/CleanupPage.qml
        qml/pages/LargeFilesPage.qml
        qml/pages/DuplicatesPage.qml
        qml/pages/SettingsPage.qml
)

# Place Main.qml at the module root so the load URL is clean:
#   qrc:/qml/MatrixManager/Main.qml
set_source_files_properties(qml/Main.qml PROPERTIES QT_RESOURCE_ALIAS "Main.qml")

qt_add_qml_module(matrix-manager
    URI MatrixManager
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        qml/Main.qml
)

target_link_libraries(matrix-manager PRIVATE mm_theme mm_components mm_pages)

# ---------------------------------------------------------------------------
# Static QML module plugin import
#
# Qt 6.5+ links the plugins of the project's static QML modules into the
# executable automatically during target finalization. On Qt 6.2 - 6.4 with
# a shared (distro) Qt build the finalizer returns early for shared Qt, so
# the plugins are never linked and the app fails at startup with:
#   module "MatrixManager.Theme" plugin "mm_themeplugin" not found
#
# Link the generated plugin targets directly. This is the supported manual
# pattern for Qt 6.2 - 6.4; on Qt 6.5+ it is redundant but harmless because
# CMake de-duplicates the repeated link entries against the finalizer's own.
# ---------------------------------------------------------------------------
foreach(_mm_qml_plugin mm_themeplugin mm_componentsplugin mm_pagesplugin)
    if(TARGET ${_mm_qml_plugin})
        target_link_libraries(matrix-manager PRIVATE ${_mm_qml_plugin})
    endif()
endforeach()

qt_add_resources(matrix-manager "appicon"
    PREFIX "/"
    FILES
        resources/matrix-manager.svg
)

# ---------------------------------------------------------------------------
# Install rules
# ---------------------------------------------------------------------------
include(GNUInstallDirs)
install(TARGETS matrix-manager RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES packaging/matrix-manager.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
install(FILES resources/matrix-manager.svg
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
        RENAME matrix-manager.svg)

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
option(MM_BUILD_TESTS "Build unit tests" ON)
if(MM_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
