# Changelog

## Phase 1 - Asset Optimization

- Resized `Assets/Coin/Coin-1.png.png` through `Assets/Coin/Coin-7.png.png` from 800x800 to 96x96 PNGs while preserving RGBA transparency. Why: Phase 0 showed these coin frames were displayed much smaller than their source size in gameplay and UI, so the new source size keeps a 20% safety margin over the largest 80px UI display.
- Updated the coin sprite scales in `Scenes/Collectables/Coin/coin.tscn`, `Scenes/UI/TitleScreen.tscn`, `Scenes/UI/chapter_select.tscn`, and `Scenes/Characters/Player/Projectile/fire_ball.tscn` to preserve the previous on-screen sizes after source resizing. Why: resizing the source images without compensating scale changes would shrink the visible collectible/UI/projectile coin sprites.
- Restored the missing `Assets/Player_Projectile/fireballs/fire_ball_side_medium/` and `Assets/Player_Projectile/fireballs_explosion/fire_ball_side_medium/` frame folders from the sibling backup project. Why: `Scenes/Characters/Player/Projectile/fire_ball.tscn` already referenced these exact paths, so restoring the original assets fixes broken projectile animations without changing scene behavior.
- Restored `Assets/Environment/Test_Block/box.jpeg` from the sibling backup project. Why: `Scenes/Environments/Proto_Levels/Moving_Platforms/moving_platform.tscn` uses this texture in its platform TileSet, and the referenced file was missing.
