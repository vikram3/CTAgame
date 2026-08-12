# Coin Troll Adventure - Project Board

This is a Trello-style working board for finishing the project without getting lost. It is based on `PROJECT_AUDIT.md`, the HTML prototype's 19 gameplay segments, and the current Godot 4.5 project state.

## How Big Is The Project?

- Current state: working prototype with scattered systems, oversized/missing assets, duplicated scene logic, and partial level coverage.
- Practical workload: about 50 meaningful cards.
- Must-do before a stable demo: about 18 cards.
- Full professional cleanup: about 45-55 cards.
- Biggest risk areas: assets and references, long scripts, repeated level scenes, unclear 19-segment alignment, and lack of editor/runtime verification.

## Board Rules

- Do not redesign gameplay.
- Do not skip phases when the next phase depends on the previous one.
- Commit one concern at a time.
- Prefer fixing broken references and architecture before balance tweaks.
- Use the PDF for design intent and the HTML prototype for concrete level data when the PDF is silent.

## Column: Done

### Card: Phase 0 project audit
- Priority: Done
- Output: `PROJECT_AUDIT.md`
- Notes: Static audit produced structure, dependencies, scripts, resources, assets, duplicates, missing references, and priorities.

### Card: Coin frame optimization
- Priority: Done
- Output: 7 coin PNGs resized from 800x800 to 96x96; scene scales adjusted to preserve visible size.
- Notes: Invisible in-game by design; reduces source asset size.

### Card: Restore missing projectile and platform textures
- Priority: Done
- Output: Restored fireball frame folders and `box.jpeg` from sibling backup project.
- Notes: Fixes major broken image references without replacing art.

## Column: Doing Now

### Card: Phase 1 reference validation
- Priority: High
- Goal: Get image references to zero missing runtime assets, except addon-only fallbacks that are harmless.
- Checklist:
  - Rerun missing `res://` image scan.
  - Confirm restored projectile frames match `fire_ball.tscn`.
  - Confirm moving platform `box.jpeg` exists.
  - Note any addon-only missing references separately.

### Card: Phase 1 safe asset wins
- Priority: High
- Goal: Optimize only asset groups whose displayed sizes are understood.
- Candidate batches:
  - Coin frames: done.
  - Projectile frames: inspect dimensions and displayed scale before resizing.
  - `bgAssetsNight.png`: high waste, but used as an atlas in several scenes, so only resize after mapping all regions.
  - `props 2.png` and `props 1.png`: high value, but TileSet/region dependent, so require careful atlas audit.

## Column: Next

### Card: Install or locate Godot CLI/editor
- Priority: High
- Why: Static checks are not enough. The project needs editor import/dependency validation.
- Done when:
  - `godot --version` works, or the exact Godot executable path is documented.
  - Project opens with import cache regenerated.
  - Missing dependency warnings are captured.

### Card: Finish Phase 1 asset optimization
- Priority: High
- Why: Assets are the largest source of repo bloat and broken references.
- Done when:
  - Referenced oversized images are resized only when safe.
  - Unused assets are removed only after confirmed zero references.
  - `CHANGELOG.md` explains every non-trivial asset decision.
  - All scenes open with no broken texture references.

### Card: Phase 2 folder organization plan
- Priority: High
- Why: The repo currently mixes runtime assets, reference packs, scenes, scripts, and addons.
- Done when:
  - Final target folder map is approved.
  - Move list is generated.
  - Risky path moves are grouped into small commits.

### Card: Move runtime assets into clean folders
- Priority: High
- Depends on: folder organization plan.
- Done when:
  - Runtime art is under `assets/`.
  - Reference/source packs are separated or clearly marked.
  - Scene/resource/script paths are updated.
  - Godot opens without missing dependency errors.

### Card: Move scenes into gameplay folders
- Priority: High
- Depends on: runtime asset move.
- Done when:
  - Levels, player, enemies, UI, traps, collectables, camera, and managers have clear homes.
  - No scene node hierarchy changes yet.

## Column: Backlog - Architecture

### Card: Normalize top-level level scene structure
- Priority: Medium
- Phase: 3
- Done when: each gameplay scene uses a predictable grouping such as Player, EnemySpawner, TileMap, Objects, Camera, UI, Navigation, Audio, Triggers.

### Card: Remove dead and empty nodes
- Priority: Medium
- Phase: 3
- Done when: empty containers and redundant nesting are removed without changing behavior.

### Card: Split `Scripts/WebtoonReader.gd`
- Priority: High
- Phase: 4
- Why: 805 lines, too many responsibilities.
- Suggested split: loading, navigation, zoom/scroll UI, input/touch handling, overlay state.

### Card: Split `Scenes/Levels/td_player.gd`
- Priority: High
- Phase: 4
- Why: 587 lines, mixes movement, animation, combat, hiding, damage, and top-down/platformer modes.
- Suggested split: movement, animation, combat/damage, hiding interaction, mode controller.

### Card: Split `skeleton_orange.gd`
- Priority: High
- Phase: 4
- Why: 565 lines, mixes platformer AI, top-down AI, combat, search, return, health, and effects.
- Suggested split: stats, sensing, movement, combat, state behavior.

### Card: Convert magic numbers to resources/constants
- Priority: Medium
- Phase: 4
- Done when: enemy stats, player movement values, level timers, rewards, and damage values are named or data-driven.

### Card: Replace fragile node paths
- Priority: Medium
- Phase: 4
- Done when: relative lookups are replaced with exported `NodePath`s, signals, groups, or autoload references.

## Column: Backlog - Levels

### Card: Map existing Godot levels to 19 prototype segments
- Priority: High
- Phase: 7
- Done when: every PDF/HTML segment has a Godot scene status: implemented, partial, missing, or mismatch.

### Card: Create reusable level archetypes
- Priority: High
- Phase: 7
- Candidate archetypes:
  - Tutorial coin collection.
  - Timed chase.
  - Survival arena.
  - Combat wave.
  - Boss arena.
  - Exploration plus coins.
  - Auto-scroll escape.

### Card: Verify Chapter 1 segments
- Priority: High
- Phase: 7
- Segments: Bush Maze Sneak, Treasure Chase.

### Card: Verify Chapter 2 segments
- Priority: High
- Phase: 7
- Segments: Shadow Flood, Boss Dodge, Reinforcement Wave.

### Card: Verify Chapters 3-8 segments
- Priority: Medium
- Phase: 7
- Done when: all remaining segment mechanics, timers, enemy counts, coin targets, hazards, and win conditions are checked against PDF/HTML.

## Column: Backlog - Data And Save

### Card: Audit current save data
- Priority: Medium
- Phase: 8
- Done when: current tracked data is listed and mapped to player, coins, story flags, inventory, level completion, and settings.

### Card: Restructure save data
- Priority: Medium
- Phase: 8
- Done when: data is grouped into resources or JSON consistently, with no lost tracked values.

### Card: Add migration/default handling
- Priority: Medium
- Phase: 8
- Done when: old or missing save keys do not crash the game.

## Column: Backlog - QA

### Card: Static reference scan
- Priority: High
- Phase: 9
- Done when: no missing runtime `res://` paths remain.

### Card: Editor warning pass
- Priority: High
- Phase: 9
- Depends on: Godot CLI/editor path.
- Done when: warnings/errors are captured and technical bugs are fixed.

### Card: Playtest chapter flow
- Priority: High
- Phase: 9
- Done when: title -> chapter select -> webtoon -> playable segment -> completion path works for each implemented segment.

### Card: Verify input map
- Priority: Medium
- Phase: 9
- Done when: `move_down` null input is fixed if Godot reports it, and action naming is normalized later if needed.

## Column: Later / Nice To Have

### Card: README rewrite
- Priority: Low
- Phase: 10
- Done when: README explains folder structure, how to run the project, where levels/enemies/data live, and known limitations.

### Card: Notes for review
- Priority: Low
- Phase: 10
- Done when: all uncertain choices and human-review items are collected in `NOTES_FOR_REVIEW.md`.

### Card: Final changelog cleanup
- Priority: Low
- Phase: 10
- Done when: each phase has grouped entries with a one-line why.

## Suggested Milestones

### Milestone 1: Stabilize The Prototype
- Cards: finish Phase 1 validation, restore/fix missing references, locate Godot CLI/editor, run editor dependency check.
- Outcome: project opens cleanly enough to work safely.

### Milestone 2: Make The Repo Navigable
- Cards: Phase 2 folder organization, path updates, README draft.
- Outcome: assets/scenes/scripts are findable.

### Milestone 3: Make The Code Maintainable
- Cards: scene cleanup, split large scripts, replace fragile paths.
- Outcome: future gameplay work stops feeling scary.

### Milestone 4: Align The Actual Game
- Cards: map all 19 segments, create reusable level archetypes, verify win conditions.
- Outcome: the Godot project matches the intended Coin Troll Adventure design.

### Milestone 5: QA And Ship-Ready Docs
- Cards: save-system cleanup, technical bug fixes, playtest matrix, final docs.
- Outcome: stable demo-ready project.

## The First 10 Cards To Do

1. Finish missing image reference validation.
2. Locate Godot executable and run an editor/import check.
3. Finish safe Phase 1 asset cleanup.
4. Commit Phase 1 asset/reference fixes.
5. Create exact Phase 2 move map.
6. Move runtime assets in small batches.
7. Move scenes/scripts/resources in small batches.
8. Normalize level scene structure.
9. Split `td_player.gd`.
10. Map implemented scenes against the 19 intended gameplay segments.
