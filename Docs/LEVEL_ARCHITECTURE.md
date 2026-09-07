# Level And Objective Architecture

## Phase 4 Foundation

New gameplay segments compose a `LevelController`, `ObjectiveController`, objectives, and only the gameplay systems they need. Existing Level 1 and Level 2 controllers remain unchanged during this phase.

```text
LevelController
|- LevelConfig
|- player setup
|- ObjectiveController
|  |- CoinObjective
|  |- ReachGoalObjective
|  `- other required objectives
|- GoalController / CheckpointController
`- optional systems: EnemySpawner, WaveController, AutoScrollController, HazardController
```

`LevelController` preserves the established `level_completed(success)` signal used by `TransitionManager`. It connects completion/failure handlers before it starts its `ObjectiveController`, so immediately satisfied objectives cannot lose a completion event.

## Objectives

- `CoinObjective`: completes after the required `CollectedItems.coins_amount`.
- `SurvivalObjective`: completes after a duration.
- `TimerObjective`: either fails or completes at timeout.
- `ReachGoalObjective`: completes when `GoalController` reports a player arrival.
- `WaveObjective`: completes when `WaveController` clears all configured waves.
- `ExplorationObjective`: accepts reported explored-map percentage.
- `CompositeObjective`: combines objectives with all/any completion behavior.

## Gameplay Systems

- `EnemySpawner` instantiates an enemy scene at configured markers.
- `WaveController` composes a spawner and enemy `defeated` signals.
- `AutoScrollController` publishes a scroll edge and a behind-player failure signal.
- `HazardController` aggregates opt-in hazard signals; it does not replace existing hazard damage scripts.
- `CheckpointController` records a marker and can restore a player position.
- `GoalController` turns an editor-authored `Area2D` into a player goal signal.

## Example: CH01_S01

```text
LevelController
|- CoinObjective(required_coins = 20)
|- ReachGoalObjective
|- GoalController(exit Area2D)
|- EnemySpawner(Orange Skull)
`- maze authored in the scene
```

The goal objective is intentionally separate from the coin objective. A `CompositeObjective` can require both before the level completes.
