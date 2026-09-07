# Full QA Report

## Scope And Method

Audit date: 2026-09-07.

The repository contains 84 `.tscn` scenes. All direct quoted `ext_resource` paths in `.tscn` and `.tres` files resolve in the workspace; no missing script references were found. `project.godot` targets Godot 4.5 Mobile, uses a 720x1280 portrait viewport, and declares the six required autoloads: `Global`, `CollectedItems`, `TransitionManager`, `GameData`, `SceneManager`, and `AchievementManager`.

There is no `godot` or `godot4` executable available on this host. Therefore parser/import results, runtime UI layout, input, physics, audio, animation playback, and actual device performance are not verified. “Static” below means source, configured paths, signal contracts, and scene text were inspected; it does not mean playtested.

The request refers to 19 gameplay segments, but the supplied Chapter 1-8 specification and chapter config resources define 18 segments. No nineteenth segment specification or PDF was present in the workspace, so none was inferred.

## Fixes Applied

- Level 1 and Level 2 now emit `level_completed(false)` on reader-launched death/capture, preventing a stuck gameplay overlay.
- `TransitionManager` now processes while paused and unpauses before restoring `WebtoonReader`; this fixes the Chapter 2 `pause_on_finish` transition deadlock.
- Chapter Select now reads unlock costs from `ChapterData` instead of its stale all-zero local values.
- The enabled light-shape addon now generates an in-memory procedural texture at runtime when baked textures are absent. This preserves existing Level 1 lighting without creating replacement assets.
- The simple-shadow addon icon reference now resolves to `res://icon.svg`.
- CH04_S02 was removed from launchable progression because its placeholder scene never emits success or failure. It remains documented and gated rather than trapping the player.

## Project And Asset Results

| Check | Result | Notes |
|---|---|---|
| Project configuration | Static pass | Godot 4.5 Mobile retained; portrait viewport and mobile renderer configured. |
| Input map | Partial | Keyboard actions cover movement, jump, attack, dash, block, and projectile. No gameplay touch controls are configured. |
| Autoloads | Static pass | All configured scripts exist. |
| Enabled addons | Partial | All addon directories and plugin scripts exist. Light/runtime and icon defects fixed. |
| Direct scene/resource dependencies | Static pass | 0 missing direct `ext_resource` paths. |
| Baked light save paths | Accepted risk | 14 stale `save_path` strings refer to absent editor artifacts; runtime fallback now produces textures. |
| UID validation | Manual | 51 newer scripts have no adjacent `.uid`; Godot must import/regenerate them and report any collision. |
| Import/parser check | Blocked | Godot executable unavailable. |
| Audio | Manual | No comprehensive audio routing or asset playback validation was possible. |

## Segment Matrix

“Implemented” is based only on static evidence. “Tested” is `No` throughout because Godot could not run.

| Segment | Requirement | Implemented | Tested | Bug | Status |
|---|---|---:|---:|---|---|
| CH01_S01 | 20-coin hedge-maze exit, skulls, CT | Partial | No | Missing baked-light artifacts now have runtime fallback; gameplay still manual | Manual QA |
| CH01_S02 | Timed platformer chest chase | Partial | No | Death/capture return fixed | Manual QA |
| CH02_S01 | 40 coins, collect 30, telegraphed timed avatars/bursts | Yes, static | No | No runtime verification of overlap timing | Manual QA |
| CH02_S02 | Invulnerable Big Boss, telegraphs, sword wave, slam, 90s | Yes, static | No | No runtime verification of damage/camera | Manual QA |
| CH02_S03 | Three escalating Skull waves, breach failure | Yes, static | No | No runtime verification of enemy defeat accounting | Manual QA |
| CH03_S01 | Cliff pursuit, knockback/fall, 60s survival | Partial | No | Scene lacks authored platforms, Skull support, HUD, and restart UI | Incomplete |
| CH03_S02 | Forest, Felix follow/comments, 50 coins/collect 35 | Partial | No | Runtime-spawned coins/companion exist; no authored forest or non-blocking comment UI | Incomplete |
| CH04_S01 | Auto-scroll forest escape with hazards | Partial | No | Auto-scroll/companion exist; trees, logs, projectiles, Horn staging absent | Incomplete |
| CH04_S02 | Enemy weakness combat tutorial | No | No | Placeholder cannot finish; launch is gated | Blocked |
| CH05_S01 | Bull Stampede | No | No | No playable scene configured | Blocked |
| CH05_S02 | Duel Warmup | No | No | No playable scene configured | Blocked |
| CH06_S01 | Alex Boomerang Duel | No | No | Alex assets exist, but no playable segment scene configured | Blocked |
| CH06_S02 | Crowd Scramble | No | No | No playable scene configured | Blocked |
| CH07_S01 | Victory Rush | No | No | No playable scene configured | Blocked |
| CH07_S02 | Ship Disaster | No | No | Systems exist but no playable scene configured | Blocked |
| CH08_S01 | Sand Land Intro | No | No | Systems exist but no playable scene configured | Blocked |
| CH08_S02 | Contract Panic | No | No | Systems exist but no playable scene configured | Blocked |
| CH08_S03 | Wormfish Chase | No | No | No playable scene configured | Blocked |

## Scene, Gameplay, And Performance Findings

### Critical

- None remaining after the fixes in this pass.

### High Priority

- CH04_S02 is not implemented and could not complete; it is now gated. It needs its required enemy-category objective and result path before re-enabling.
- CH05 through CH08 have no configured playable scenes, so the current game cannot deliver a full Chapter 1-8 progression.
- Gameplay is keyboard-only. Existing button UI is touch-capable, but platformer/top-down controls have no virtual touch layer or mobile input mapping.
- The project cannot receive a complete runtime sign-off until it is imported and run with Godot 4.5.

### Medium Priority

- CH03/CH04 configured scenes are thin prototypes. Their controllers provide some reusable mechanics, but they do not meet their authored level requirements and have no proven HUD/restart flow.
- `td_player.tscn` has `max_health = 1000`, while authored hazards deal roughly 16-28 damage. This may make death behavior impractical; balance must be checked in playtesting before changing values.
- 14 missing light bake outputs remain as stale `save_path` metadata. The runtime fallback prevents blank procedural light textures, but editor re-baking is needed to restore serialized light assets.
- `WebtoonReader.gd` (809 lines), `td_player.gd` (587 lines), `skeleton_orange.gd` (544 lines), and `ChapterData.gd` (525 lines) are maintenance risks. No broad refactor was performed.

### Low Priority

- Debug output remains in `WebtoonReader.gd`, `player.gd`, companion comments, and legacy fade scripts.
- Legacy `ChapterData` fallback definitions retain obsolete `PROTO_LEVEL` TODOs, although active chapter resources now supply progression data.
- The project title/description remain “Prototype.”
- Chapter Select contains legacy chapter titles separate from the story config.

## Manual Tests Required

1. Import in Godot 4.5 and resolve all parser, import, UID, and addon warnings.
2. Run Title -> Chapter Select -> Chapter 1 -> S01 -> S02 -> Chapter Complete; verify one-time rewards and Chapter 2 unlock.
3. In Level 1 and Level 2, verify movement, coins, attacks, damage, death, restart, and quit-to-reader behavior.
4. Run every configured Chapter 2-4 segment. Verify objective success/failure, enemy damage/death, hazards, waves, camera framing, portrait/landscape restoration, and duplicate-node absence after restart.
5. Test mobile portrait UI, landscape gameplay HUD, safe areas, readability, touch controls, and performance on target devices.
6. Re-bake/open Level 1 lights in the editor and confirm lighting quality after the procedural fallback.
7. Validate all animation tracks, audio assets, collision layers/masks, and scene signal connections in the Godot editor.

## Final Health Assessment

**Prototype / not release-ready.** The project now has safer failure and transition behavior, clean direct resource references, and guarded progression paths. Chapter 1 and static Chapter 2 foundations are the strongest areas. The full game flow remains incomplete because most later chapter gameplay is absent or only partially scaffolded, and no runtime verification was possible in this environment.
