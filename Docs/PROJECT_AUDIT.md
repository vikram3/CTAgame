# Repository Audit

Audit date: 2026-09-07

## Scope and Validation

This is a read-only audit of the `topdownl1` worktree. No gameplay, asset, scene, resource, addon, or project-setting files were changed. The audit reviewed the four-page design PDF at `output/pdf/coin_troll_project_lists.pdf`, `project.godot`, all project scenes and scripts, resource paths, asset folders, and the existing root-level `PROJECT_AUDIT.md` from 2026-08-06.

Godot 4.5 is required by `project.godot`, but no Godot executable is available on PATH or in the checked standard locations. Static reference checks ran successfully; parser, import, and runtime validation remain pending an installed Godot 4.5 executable.

The existing worktree is not clean: `Scenes/Levels/lev_2.tscn` is modified, while `output/` and `tmp/` are untracked. They were not altered.

## Repository Map

| Area | Current contents | Assessment |
| --- | --- | --- |
| `Scenes/App` | `main.tscn` | Legacy composition scene; not the configured entry scene. |
| `Scenes/Characters/Player` | Platformer player, state machine, projectile | Reusable but platformer-specific. |
| `Scenes/Characters/Enemies` | Orange skeleton and Horn behavior | Only authored enemy scene. |
| `Scenes/Levels` | `lev_1`, `lev_2`, `Lev3`, `level_5` through `level_18`, props and top-down player | Mixed prototypes and duplicated numbered scenes. |
| `Scenes/Environments` | Prototype arena, moving platform, small streaming scenes | Generic prototype support. |
| `Scenes/UI` | Title, chapter select, webtoon reader, settings, health and achievement UI | Most complete product-flow area. |
| `Scenes/Scene_Manager` | Legacy loader, fades, transition trigger, spawn points | Separate from active autoload transition flow. |
| `Scenes/Collectables` | Coin scene | Working shared pickup. |
| `Scenes/Traps` | Falling trap, spike, ball | Present but not mapped to segment requirements. |
| `Scenes/HitBox_and_HurtBox` and `Scenes/Stats` | HitBox, HurtBox, Stats | Shared combat primitives with an API mismatch. |
| `Scripts` | UI, chapter data, autoloads, save and transition state | Active narrative and persistence flow. |
| `Resources` | SpriteFrames and level tilesets | Small resource footprint; no data-driven level definitions yet. |
| `Assets` | 3,000+ files, mostly webtoon panels and reference packs | Runtime and source/reference assets are intermixed. |
| `addons` | AS2P, state charts, light shape, simple shadow | Enabled third-party editor/runtime dependencies; leave unchanged. |

Inventory: 73 `.tscn` files including addon scenes, 127 `.gd` files including addon scripts, 3 `.tres` files, and 2 `.res` files. The earlier root `PROJECT_AUDIT.md` contains a fuller historical file-level inventory and is retained unchanged.

## Existing Gameplay Map

1. The configured main scene is `Scenes/UI/TitleScreen.tscn`, not `Scenes/App/main.tscn`.
2. Title screen -> chapter select -> webtoon reader works as the intended application shell through `SceneManager` and `TransitionManager` autoloads.
3. `WebtoonReader` creates story panels from `ChapterData` and starts a playable scene through `TransitionManager`.
4. All currently active chapter definitions point to `Scenes/Environments/Proto_Levels/proto_level.tscn`; no authored numbered level scene is in the live chapter route.
5. The prototype level provides coin collection, collision-burst tracking, HUD, win/lose panels, and a `level_completed(bool)` signal.
6. `lev_1.tscn` is the strongest authored Level 1 candidate: top-down movement, 37 placed coin instances, skeleton instances, hide spots, exit gate, lighting, and a 20-coin exit objective.
7. `lev_2.tscn` is an authored treasure-chase candidate with a 60-second timer and chest target, but it is not routed from ChapterData.
8. `level_5`, `level_6`, `level_7`, and `level_8` have separate controller work. `level_9` through `level_18` are scene-layout copies of `level_8` with only their root name and attached script changed.

## Character and Enemy Map

| Design role | Existing implementation | Status |
| --- | --- | --- |
| CT | `td_player.tscn` / `td_player.gd` top-down player; `player.tscn` / `player.gd` platformer player | Two incompatible controller stacks; no shared character base. |
| Skull | `skeleton_orange.tscn` / `skeleton_orange.gd` | Has platformer and top-down branches, patrol, chase, contact damage, health, and defeat signal. |
| Horn | `Horn.gd` attached behavior only | No dedicated authored Horn scene. |
| Felix | `Scenes/Levels/felix.gd` | Follow behavior exists; no reusable NPC scene. |
| Alex, Pink Girl/Sigih, Lala, Queen, Big Boss, Big Bird/Sacavuelo, Bulls, Barreldugo, Shadow Avatar, Wormfish | No authored character scenes found | Missing. |

## System Map

| System | Existing state | Notes |
| --- | --- | --- |
| Save/progress | `GameData` autoload | JSON save with chapters, segment records, coins, settings, and achievements. |
| Narrative transition | `TransitionManager` + `WebtoonReader` | Loads additive level instance and listens for `level_completed`. Contains debug prints. |
| Navigation | `SceneManager` autoload | Title, chapter select, webtoon, and settings routes. |
| Objectives | Per-level controller scripts | No shared ObjectiveController, TimerObjective, or CoinObjective. |
| Coins | `CollectedItems` autoload + coin scene | Shared session count; player projectile consumes coins in platformer stack. |
| Combat | Stats, HitBox, HurtBox, player state machine | Two HurtBox implementations and no uniform public damage API. |
| Camera | Player camera plus `cam_root` | Top-down and platformer approaches coexist. |
| Hazards | Three trap scenes plus top-down contact/damage areas | No common hazard controller or spawner. |
| Scene loading | Autoload transition flow and legacy `Scenes/Scene_Manager` loader | Two overlapping architectures; only the autoload flow is used by narrative segments. |

## Static Broken-Reference Report

Static quoted-resource validation found 32 missing paths. Thirty are scene dependencies:

- `lev_1.tscn` references 15 absent `addons/light_shape_2d/baked_lights/*.res` resources.
- The shared prop scenes reference `light_13716011801156.res`, which is also absent.
- `addons/light_shape_2d/point_light_shape_2d.gd` references its optional baked-light directory, which is absent.
- `addons/simple_shadow_2d/plugin.gd` references `res://brand/icon.svg`; this is an addon/editor icon issue, not a game scene dependency.

No other quoted `res://` path was missing. UID resolution, scene parsing, imports, and runtime checks are pending Godot 4.5.

## High-Priority Findings

1. The platformer player damage bridge is broken. `player.gd` checks for `Stats.apply_damage()` or `Stats.take_damage()`, while `Stats.gd` exposes only `_damage_deduction()`. Enemy contact can knock the player back without reducing health.
2. `ChapterData` exposes 16 playable entries, while the design requires 18 chapter segments. CH02_S01 and CH04_S01 are commented out. All 16 active entries load the generic prototype scene.
3. `AchievementManager` expects 18 segments, but the active ChapterData list has only 16. Chapter 2 and Chapter 4 completion/achievement states cannot align with the current live list.
4. `lev_1.tscn` and all shared prop scenes have missing baked-light resource dependencies. Do not move or rename those scenes before repairing or intentionally replacing that authoring output.
5. `level_7` and `level_8` are almost identical, and `level_9` through `level_18` are exact layout copies of `level_8`. Their filenames imply coverage that their contents do not provide.
6. There is no installed Godot executable for parser, import, or runtime validation.

## Code Quality and Migration Risks

- Oversized scripts: `WebtoonReader.gd` (633 lines), `td_player.gd` (485), `skeleton_orange.gd` (474+), and `ChapterData.gd` (456). Split only when extracting a cohesive responsibility.
- `lev_1.tscn` has 261 nodes and is hand-authored with repeated props/lights. Treat it as a protected working scene during initial migration.
- The project uses both a state-machine platformer CT and a top-down CT. Choose one per segment before extracting shared health, damage, coin, and completion contracts.
- Naming is inconsistent: `Collected_items.gd` and empty `Collecteditems.gd`, `Hurt_Box.tscn` and `hurt_box.gd`, `Lev3.tscn`, and mixed `lev_`/`level_` names.
- `move_down` contains a null input event. Validate in the Godot Input Map before gameplay work.
- No audio assets are present. The design has no audio specification, so audio remains TODO rather than invented work.

See `ARCHITECTURE.md`, `LEVEL_MATRIX.md`, `MIGRATION_PLAN.md`, and `QA_CHECKLIST.md` for the current development baseline.
