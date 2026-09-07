# Controlled Migration Plan

## Phase 1: Stabilize and Prove CH01_S01

This is the recommended next implementation phase. It intentionally does not start the other 17 segments.

1. Install or locate Godot 4.5 without changing `project.godot`; run a headless editor/import/parser pass.
2. Repair the missing light-shape baked-resource dependencies or deliberately replace that editor output, then reopen `lev_1.tscn` and its prop scenes.
3. Establish a public `Stats` damage method and update the platformer player bridge to use it. Verify platformer contact damage and top-down damage independently.
4. Add a small, shared completion/objective boundary only where CH01_S01 needs it. Do not introduce a full framework in advance.
5. Route only CH01_S01 to the existing `lev_1.tscn` after its objective, exit, enemy contact damage, and narrative return flow work end to end.
6. Restore the disabled CH02_S01 and CH04_S01 entries only when their individual scenes exist; do not use a generic prototype to fill coverage gaps.
7. Update the level matrix and QA checklist with evidence from the actual Godot run.

## Subsequent Milestones

1. CH01_S02: finalize the authored chase scene and make it the second live route.
2. CH02: introduce one reusable timed survival/burst component, then boss and wave controllers only after their enemies exist.
3. CH03 and CH04: extract Felix follow and auto-scroll only after their target scenes are distinct.
4. CH05 through CH08: create enemy and hazard archetypes one at a time from confirmed PDF needs.
5. Data/folder migration: move a small verified cluster at a time, with Godot reference checks after every move.

## Migration Guardrails

- Do not delete duplicate assets during gameplay stabilization.
- Do not rename scenes solely for cosmetic consistency.
- Do not switch player-controller stack inside a level without an explicit migration and playtest.
- Keep Level 1 and Level 2 scene changes isolated from unrelated cleanup.
- Require a passing Godot parser/import check before each new segment becomes reachable from the webtoon flow.

## Phase 1 Classification

| Classification | Files and folders | Phase 1 decision |
| --- | --- | --- |
| Keep in current location | `project.godot`, enabled addons, all autoloads, UI scenes/scripts, player scenes/scripts, `lev_1`, `lev_2`, shared Stats/HitBox/HurtBox | Preserve in place. |
| Safe to migrate | Documentation and empty production destination folders | Created in place; no runtime relocation needed. |
| Needs dependency migration | Props, `lev_1`, `lev_2`, tilesets, skeleton, moving platform, scene manager | Leave in place until Godot import/reference validation is available. |
| Prototype/legacy | `Scenes/App/main.tscn`, `Scenes/Scene_Manager/game_root.tscn`, `Scenes/Environments/Small_Scenes`, generic prototype level, duplicate numbered level layouts | Retain untouched until live references and intended ownership are confirmed. |
| Reference asset | `Assets/Video game/Refrence`, webtoon source panels, source art packs | Retain untouched. No deletion or relocation. |
| Unknown | Unreferenced art, duplicate-looking assets, `output/`, `tmp/`, empty `Collecteditems.gd` | Leave untouched pending a Godot import pass and reference review. |

## Phase 1 Migrations

No existing project file was moved or renamed. The required destination hierarchy was created with `.gitkeep` placeholders so it is available for controlled future migrations.
