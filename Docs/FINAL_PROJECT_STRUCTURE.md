# Final Project Structure

## Production Runtime Surface

```text
Scenes/
|- App/                         Bootstrap scene
|- UI/                          Title, chapter select, reader, settings, HUD
|- Characters/                  CT, Alex, enemies, projectile scenes
|- Collectables/                Coin scene
|- Chapters/
|  |- Chapter2/                 CH02_S01 through CH02_S03
|  |- Chapter3/                 CH03_S01 through CH03_S02
|  `- Chapter4/                 CH04_S01 and gated CH04_S02
`- Levels/                      Legacy CH01 Level 1 and Level 2 scenes

Scripts/
|- Autoload/                    Persistent game, scene, and achievement state
|- Progression/                 ChapterConfig and SegmentConfig resources
|- Combat/ and Enemies/         Shared combat contracts and base enemy logic
|- Gameplay/                    Objectives, systems, hazards, actors, ship/sand foundations
|- Chapter2/                    Reusable Chapter 2 encounter behavior
|- Chapter34/                   Prototype scenario controller
`- UI/                          UI support scripts

Resources/
|- Characters/                  CT and Alex character data
|- Enemies/                     Enemy data
`- Levels/                      chapter_01_config through chapter_08_config
```

`Resources/Levels/chapter_XX_config.tres` is the production gameplay discovery source. It currently exposes eight launchable scene paths: CH01_S01, CH01_S02, CH02_S01, CH02_S02, CH02_S03, CH03_S01, CH03_S02, and CH04_S01. CH04_S02 and all Chapter 5-8 slots are deliberately unconfigured because their required completable scenes are absent.

## Retained Legacy And Reference Material

- `Scenes/Environments/Proto_Levels`, `Scenes/Environments/Small_Scenes`, and numbered `Scenes/Levels/level_*.tscn` files are retained legacy/prototype material. They are not referenced by the chapter-configured production path.
- `Assets/Reference` and `Assets/Video game/Refrence` are reference-only libraries. The latter retains its existing spelling because it has legacy scene references.
- The original platform-player scene references assets beneath `Assets/Video game/Refrence`; it is a legacy player implementation and is not used by configured gameplay scenes.
- No assets or scenes were moved or deleted in final cleanup. Their full dependency graph cannot be authoritatively rebuilt without a Godot import pass.

## Naming Status

New runtime chapter scenes use `CH##_S##_PascalCase.tscn`; level config resources use `chapter_##_config.tres`. Existing `lev_*`, `level_*`, `prop*`, and `Ground*` names are legacy identifiers retained to avoid breaking tile-set and scene references.
