# Known Limitations

## Content

- The available chapter specification defines 18 gameplay segments, not 19. No source requirement for a nineteenth segment was found.
- Eight segments are launchable through chapter progression. CH04_S02 is gated because its placeholder has no completion path.
- CH05_S01 through CH08_S03 have story metadata but no configured gameplay scene.
- CH03 and CH04 launchable scenes are prototype-grade and do not yet satisfy all authored encounter, environment, HUD, or restart requirements.

## Assets

- `Assets/Audio` contains no shipped audio files; music, SFX, and mix validation are outstanding.
- Later chapter enemy, boss, environment, and UI art is incomplete or unverified.
- Level 1 retains 14 missing editor-baked light save paths. Runtime procedural fallback prevents blank light textures, but the assets should be re-baked in Godot.
- No animation completeness audit can be certified without opening all scenes in Godot.

## Technical

- No Godot executable is available in this workspace, so parser, import, UID, runtime, Android export, and device-performance validation have not run.
- Fifty-one newer scripts do not yet have adjacent `.uid` files. Godot should generate and validate them at import.
- Gameplay input is keyboard-based; UI controls are touch-capable but no virtual gameplay-control scheme has been verified.
- Large legacy scripts and duplicate prototype scene families remain until a source-of-truth content migration is completed.
