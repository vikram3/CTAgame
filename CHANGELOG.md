# Changelog

## Phase 1 - Asset Optimization

- Resized `Assets/Coin/Coin-1.png.png` through `Assets/Coin/Coin-7.png.png` from 800x800 to 96x96 PNGs while preserving RGBA transparency. Why: Phase 0 showed these coin frames were displayed much smaller than their source size in gameplay and UI, so the new source size keeps a 20% safety margin over the largest 80px UI display.
- Updated the coin sprite scales in `Scenes/Collectables/Coin/coin.tscn`, `Scenes/UI/TitleScreen.tscn`, `Scenes/UI/chapter_select.tscn`, and `Scenes/Characters/Player/Projectile/fire_ball.tscn` to preserve the previous on-screen sizes after source resizing. Why: resizing the source images without compensating scale changes would shrink the visible collectible/UI/projectile coin sprites.
- Left the missing projectile frame references in `Scenes/Characters/Player/Projectile/fire_ball.tscn` unchanged. Why: Phase 0 reported the referenced `Assets/Player_Projectile/...` PNGs as missing, and no source copies were found under `Assets`; replacing them would require a design/art decision outside this asset optimization batch.
