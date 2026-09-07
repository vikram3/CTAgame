# Build Instructions

## Prerequisites

- Godot 4.5 with Android export templates installed.
- Android SDK, JDK, and a signing keystore configured in the Godot editor for release builds.

## Editor Validation

1. Open `project.godot` in Godot 4.5.
2. Let the import scan finish and resolve every parser, UID, missing-resource, and addon warning before running the project.
3. Open `Scenes/UI/TitleScreen.tscn`, then each configured scene named in `Resources/Levels/chapter_XX_config.tres`.
4. Run the game and complete the manual test list in `Docs/FINAL_QA_REPORT.md`.
5. Re-bake Level 1 lights if the editor reports missing baked light resources.

## Android Export

1. In Project > Export, select the existing Android preset in `export_presets.cfg`.
2. Set a release version name, release signing credentials, and an output path suitable for the build environment.
3. Export a debug APK first and install it on a supported Android device.
4. Complete portrait UI, landscape gameplay, touch, restart, transition, and performance testing.
5. Export a signed release APK only after the debug build and all critical manual tests pass.

## Current Export Status

The repository contains an Android export preset, but export is **not certified**. This host cannot run Godot or the Android toolchain, and the game remains content-incomplete beyond the currently configured scenes.
