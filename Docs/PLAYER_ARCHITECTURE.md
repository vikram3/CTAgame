# Player Architecture

## Phase 2 Baseline

The project retains two active player stacks because they serve different verified content paths:

| Stack | Scene | Current role |
| --- | --- | --- |
| Top-down controller | `Scenes/Levels/td_player.tscn` | Level 1 and Level 2, including top-down movement, platformer mode, hiding, and level-local damage handling. |
| Character controller | `Scenes/Characters/Player/player.tscn` | State-chart-driven side-scrolling player used by platformer/prototype content. |

They intentionally are not merged in Phase 2. `td_player.gd` continues to own Level 1 and Level 2 behavior, while `CharacterController` is the reusable foundation for CT and future playable characters.

## Character Controller

`Scenes/Characters/Player/player.gd` now declares `CharacterController` and remains the controller for `player.tscn`. The scene still owns its current node topology:

```text
CharacterController (CharacterBody2D)
|- Body
|  |- AnimationPlayer
|  |- Hit_Box
|  |- HurtBox
|  `- projectile_point
|- State_Transition_Manager
|- StateChart
|- Player_Stats
|- CanvasLayer/HealthBar
`- Camera and level-facing integrations
```

Movement, state transitions, collision shapes, animation tracks, input actions, and all state scripts remain where they were. This preserves idle, run, jump, double jump, falling, ground and air attacks, dashes, block, counter, parry, hurt, death, and projectile behavior.

## Character Data

`Scripts/Characters/CharacterData.gd` is a reusable data object for character-specific values. It contains the character identifier, display name, `stats_resource`, and projectile scene. CT is configured by `Resources/Characters/ct_character_data.tres`; its values are copied from the previous embedded `player.tscn` data.

At startup, `CharacterController` applies the assigned data object to its existing `Stats` child and projectile reference before it initializes the health UI. The existing scene properties remain as fallbacks, so a scene without a data object continues to function with its local configuration.

This makes a future Alex implementation a new `CharacterData` resource plus character presentation/animation assets on the same controller foundation. It does not create a second copied controller.

## Shared Combat Contract

`Stats` owns health, energy, outgoing damage, and incoming damage. `get_damage()` and `take_damage()` are its public boundary methods. The shared HitBox and both HurtBox variants now use those methods instead of reaching into private underscore-prefixed methods. Damage calculation and health/energy signals are unchanged.

## Known Follow-up Checks

- `player.tscn` exposes `check_hit`, but this exported `CollisionShape2D` is not assigned in the saved scene. Block/parry code references it. Do not assign a candidate shape without an editor inspection and gameplay test.
- A Godot runtime is required to verify state-chart execution, collision timing, block/counter/parry, camera behavior, and Level 1/Level 2 playthroughs.
