# Coin Adventure Game

Godot 4 project organized by gameplay area.

## Project Layout

- `Scenes/App/` - top-level app flow and main entry scenes.
- `Scenes/Characters/` - playable character, enemies, projectiles, and character state machines.
- `Scenes/Levels/` - playable levels, level scripts, tile sets, level props, and level-specific helpers.
- `Scenes/UI/` - menus, HUD, health bars, chapter select, and webtoon reader UI.
- `Scenes/Scene_Manager/` - scene loading, transitions, spawn points, and stage data.
- `Scenes/Collectables/` - collectable gameplay scenes.
- `Scenes/Traps/` - trap scenes and scripts.
- `Scenes/Camera/` - camera rigs and camera effects.
- `Scenes/HitBox_and_HurtBox/` - shared combat collision scenes.
- `Scenes/Stats/` - reusable stats scenes and scripts.
- `Assets/` - imported art, sprites, textures, webtoon panels, and source asset packs.
- `Resources/` - reusable Godot resources such as sprite frames.
- `Scripts/` - global scripts, autoloads, menu scripts, data classes, and shared managers.
- `addons/` - third-party Godot plugins. Keep plugin code isolated here.

## Organization Rules

1. Put new playable scenes under the closest existing `Scenes/` category.
2. Keep scripts beside their scene when they are only used by that scene.
3. Put shared singleton scripts in `Scripts/Autoload/`.
4. Put reusable data resources in `Resources/`.
5. Do not put game files at the project root except Godot config, docs, and repo files.
6. Do not edit or move files inside `addons/` unless updating a plugin.

## Current Main Paths

- Main scene: `Scenes/App/main.tscn`
- Player scene: `Scenes/Characters/Player/player.tscn`
- Enemy scenes: `Scenes/Characters/Enemies/`
- Title screen: `Scenes/UI/TitleScreen.tscn`
- Webtoon reader: `Scenes/UI/WebtoonReader.tscn`
