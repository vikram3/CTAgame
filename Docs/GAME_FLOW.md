# Game Flow

## Ownership

`SceneManager` is the public navigation entry point. It changes between title, chapter select, settings, and `WebtoonReader`, and it is the only story-UI API that launches a gameplay segment.

`TransitionManager` remains the existing transition presentation and gameplay-lifetime helper. It owns the portrait-to-landscape fade, instantiates the requested gameplay root beside the reader, waits for `level_completed(success)`, and restores portrait before returning to story. It is not a second scene router.

`GameData` remains the persistent progression source. It records launches, first completion, repeat completion counts, coin awards, chapter completion, unlocked chapters, and reader scroll positions in `user://save_data.json`.

## Runtime Sequence

```text
TitleScreen
  -> SceneManager.go_to_chapter_select()
Chapter Select
  -> SceneManager.go_to_chapter(chapter_number)
WebtoonReader
  -> SceneManager.start_gameplay_segment(scene_path, reader)
TransitionManager
  -> gameplay root emits level_completed(success)
WebtoonReader
  -> GameData records result and advances to next story panel
  -> chapter completion unlocks the next chapter
```

Gameplay roots must expose `signal level_completed(success: bool)`. `true` records a segment completion and awards its configured coins only on the first success. `false` returns to the same reader position without completing the segment. This is also the retry path: press the existing playable trigger again after failure.

## Chapter Resources

`Resources/Levels/chapter_01_config.tres` through `chapter_08_config.tres` now define chapter page count, unlock cost, and the ordered segment metadata: story insertion page, transition text, stable game index, coin reward, and gameplay scene path.

`ChapterData` is retained as a compatibility adapter for `WebtoonReader`. It reads the resources and produces its established `PanelEntry` objects; story UI has no gameplay-specific controller knowledge.

Chapter 1 uses the verified existing Level 1 and Level 2 scenes. Chapters 2 and 3, plus CH04_S01, use their authored, completable scene paths. CH04_S02 and Chapters 5 through Chapter 8 retain their story placements and progression metadata, but their scene paths are intentionally blank because no corresponding completable gameplay scene is present in this repository. `SceneManager` rejects that condition before the reader records a launch, rather than launching `proto_level.tscn` or altering progress.

## Progression Guarantees

- Existing completions persist; repeated successes do not award coins twice.
- A completed chapter remains complete and its successor remains unlocked.
- Restart behavior stays owned by the individual gameplay scene. Its quit action emits failure when it is reader-launched, returning to story without bypassing the transition flow.
- Returning to chapter select stays available through the existing reader UI and `SceneManager.go_to_chapter_select()`.
- Invalid scene paths and gameplay roots without `level_completed(success)` are rejected before the reader is hidden.

## Validation Checklist

- Title -> Chapter Select -> Chapter 1 Reader.
- Complete `lev_1.tscn`; verify next-story positioning, one-time reward, and replay state.
- Complete `lev_2.tscn`; verify Chapter 1 completion and Chapter 2 unlock.
- Fail either Chapter 1 segment; verify it returns to the same playable trigger without completion.
- Launch one each of Chapters 2, 3, and 4; verify landscape entry, completion/failure return, and no duplicate gameplay root.
- Attempt a Chapter 5-8 trigger; verify the reader remains available and no progress is recorded until its scene is authored and configured.
