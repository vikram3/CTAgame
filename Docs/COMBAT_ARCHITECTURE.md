# Combat Architecture

## Phase 3 Foundation

Combat remains scene-composed. Existing `Stats`, HitBox, HurtBox, player state nodes, trap areas, and the fireball projectile stay active; this phase adds a typed contract around them instead of replacing working collision and animation timing.

```text
Attack or Projectile
`- HitBox -> DamageInfo -> HurtBox -> Stats -> health/death signals
```

## Contracts

- `DamageInfo` carries an integer amount, damage type, source, knockback direction/strength, and an invulnerability bypass flag.
- `HitBox.do_damage()` remains the legacy integer API. `get_damage_info()` adds the new typed API without changing existing collision handlers.
- `HurtBox.apply_damage()` remains the legacy API. `apply_hit(DamageInfo)` applies the same damage and emits `hit_received` for future reactions. `auto_receive_hits` is opt-in, keeping state-machine-owned player damage handling intact.
- `Stats` remains the health component. It retains `health_updated` and `health_depleated`, and now also emits typed `health_changed` and one-shot `died` signals. `take_damage_info()` delegates to its existing calculation.

Damage calculation is unchanged: defense and the existing `min_damage` value are applied by `Stats`.

## Existing Integrations

- Player melee, air attacks, counter, and fireball retain their current HitBox scenes and animation-driven collision windows. The platformer player's accidental `script = null` override was removed and its HitBox now references the existing player `Stats` node.
- The Orange Skull opts into HurtBox collision reception, so existing player HitBoxes now damage its existing Stats/death path.
- Player hurt state and top-down player damage retain their existing knockback/invulnerability implementations.
- Traps and level damage areas retain their integer `do_damage()` behavior.
- Future attacks should create `DamageInfo` and use `apply_hit`; legacy content may continue using integer methods until deliberately migrated.

## Future Scope

`DamageInfo` supports damage type and knockback metadata now. Weakness resolution, damage modifiers, projectile ownership filtering, and a shared invulnerability component should be implemented only with their first concrete enemy requirement.
