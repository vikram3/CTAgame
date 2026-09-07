# Architecture Baseline

## Current Runtime Flow

`TitleScreen` -> `SceneManager` -> `ChapterSelect` or `WebtoonReader` -> `TransitionManager` -> active segment scene -> `level_completed(success)` -> `WebtoonReader` -> `GameData` and `AchievementManager`.

This is the application flow to preserve. `Scenes/App/main.tscn` and `Scenes/Scene_Manager/game_root.tscn` are legacy/parallel paths and must not be adopted or removed without reference and playtest checks.

## Current Gameplay Stacks

| Stack | Core scene | Movement | Combat | Primary use |
| --- | --- | --- | --- | --- |
| Top-down | `td_player.tscn` | Eight-directional with top-down and platformer options | Local hurt box and Stats | `lev_1`, `lev_2` |
| Platformer | `player.tscn` | State-machine driven side-scrolling | HitBox/HurtBox, projectile, Stats | proto and numbered levels |

Do not merge these controllers in one migration. Phase 1 should establish only shared contracts at their boundaries: `level_completed`, health/damage, coin collection, objectives, and player grouping.

## Existing Reusable Pieces

- Coin pickup: `Scenes/Collectables/Coin/coin.tscn`.
- Shared stats and hit/hurt box scenes.
- Orange skeleton enemy with patrol/chase branches.
- Felix follow script.
- Moving platform scene.
- Top-down patrol and damage areas.
- Scene-transition and save/progress autoloads.
- Existing title, chapter-select, webtoon, settings, HUD, and achievement UI.

## Target Incremental Direction

1. Preserve both player scenes while defining a narrow level-facing player contract.
2. Add shared objective components under `Scripts/Gameplay/Objectives` only after the first use case is proven in a migrated segment.
3. Keep level scene controllers thin: compose objective, hazards, spawners, and actor scenes.
4. Move files only after static references and a Godot import pass are clean.
5. Keep editor-authored environments and TileMaps in their existing locations until the relevant segment is verified.

## Do Not Move Yet

- `lev_1.tscn`, props, and any scene using light_shape baked resources.
- Both player stacks and their state-machine scripts.
- Enabled addons.
- `Assets/Video game/Refrence/`; it contains source/reference material intermingled with possible runtime art.
- Existing `output/` and `tmp/` worktree content.

## Phase 1 Cleanup Record

- Production destination folders now exist as empty tracked placeholders.
- No gameplay, UI, autoload, scene-manager, player, level, resource, or asset file was moved in this phase.
- `Stats.take_damage(damage)` is the public damage entry point for the existing platformer player bridge. It delegates to the established deduction implementation, preserving all current HurtBox callers.
- The invalid null event in the `move_down` Input Map entry was removed. The existing S-key binding is unchanged.
