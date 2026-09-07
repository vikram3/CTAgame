# Enemy Architecture

## Phase 3 Foundation

`EnemyBase` is intentionally small. It owns the shared `Stats` reference, optional `EnemyData`, death flag, `defeated` signal, and `take_hit(DamageInfo)` entry point. It does not prescribe movement, detection, attack animation, or AI states.

```text
EnemyBase
|- Stats / health and death
|- EnemyData
`- Concrete controller
   |- Movement
   |- Detection
   |- Attack
   `- AI/state behavior
```

`EnemyData` can configure identity, health stats, movement/chase speed, attack type/damage/range, projectile scene, knockback strength, weaknesses, invulnerability duration, and death behavior. It is data, not a forced behavior tree or inheritance chain.

## Orange Skull Migration

`skeleton_orange.gd` now extends `EnemyBase` and uses `Resources/Enemies/skull_orange_data.tres`. Its existing platformer and top-down movement, patrol, detection, attack timing, collision setup, animations, and Level 1/Level 2 instance overrides remain in its concrete script and scenes.

The resource reproduces its prior baseline Stats values and contact-damage value. Per-level movement overrides are deliberately not read from the resource, so the Level 1 and Level 2 tuning remains authoritative. On zero health, the existing Skeleton now stops and plays its authored `dead` animation; it is not automatically removed from the scene.

## Future Enemy Families

Skull, Elite Skull, Horn, Big Boss, Barreldugo, Bull, Big Bird/Sacavuelo, Sand Worm/Wormfish, and Shadow Avatar should each use `EnemyData` plus a purpose-built controller only where their movement or attack behavior differs. Add shared components after at least two real enemies need the same behavior.
