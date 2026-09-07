# Production Project Structure

## Established Destination Hierarchy

```text
Assets/
  Characters/ Environments/ Collectables/ VFX/ UI/ Audio/ Reference/
Scenes/
  App/ Characters/{Player,Enemies,NPCs}/ Levels/{Common,Chapter01..Chapter08}/
  UI/ Camera/ Collectables/ Traps/ HitBox_and_HurtBox/ Scene_Manager/ Stats/
Scripts/
  Core/ Characters/ Enemies/ Levels/ Gameplay/{Objectives,Timers,Spawners,Checkpoints,Hazards}/
  UI/ Autoload/ Data/
Resources/
  Characters/ Enemies/ Levels/ Items/ Shared/
Docs/
  ChapterBreakdown/ LevelSpecs/ QA/
```

## Current Placement Policy

Existing runtime content stays at its current path in Phase 1. The destination hierarchy is reserved for new, verified production content and for future migrations that have passed Godot reference validation.

| Current path | Classification | Reason |
| --- | --- | --- |
| `Scenes/Levels/lev_1.tscn`, `Scenes/Levels/lev_2.tscn` | Keep in current location | Working Level 1/2 prototypes with scene/resource dependencies. |
| `Scenes/Characters/Player` | Keep in current location | Live player stack and state-machine dependencies. |
| `Scenes/UI`, `Scripts/Autoload`, `Scripts/TransitionManager.gd` | Keep in current location | Active title, webtoon, save, and transition flow. |
| `Scenes/Scene_Manager` | Needs dependency migration | Legacy loader scenes coexist with active autoload flow. |
| `Scenes/Levels/level_7.tscn` through `level_18.tscn` | Prototype/legacy | Duplicated layouts are not live segment implementations. |
| `Assets/Video game/Refrence` | Reference asset | Large source/reference pack; preserve until ownership and usage are verified. |
| `Assets/TopDown`, `Assets/PlatformAssets`, `Assets/Player`, `Assets/skeleton` | Needs dependency migration | Runtime references span scenes, resources, and import metadata. |
| `output/`, `tmp/`, `Scripts/Collecteditems.gd` | Unknown | Leave untouched; they are not safe cleanup targets yet. |

## Phase 1 Changes

- Created the reserved production directory hierarchy with `.gitkeep` files.
- Added the public `Stats.take_damage()` compatibility method.
- Removed the null placeholder from the `move_down` Input Map event list.
- Performed no existing-file move, rename, or deletion.
