# QA Checklist

## Baseline Environment

- [ ] Godot 4.5 executable is available.
- [ ] Project opens without parser errors.
- [ ] Project import completes without missing-resource errors.
- [ ] Input Map warning for `move_down` is reviewed.
- [ ] Enabled addons load without editor errors.

## Reference Integrity

- [ ] Recheck the 30 missing baked-light scene references after the chosen light-shape resolution.
- [ ] Recheck all quoted `res://` paths after every move or rename.
- [ ] Confirm all referenced scene UIDs resolve in the Godot editor.
- [ ] Keep a clean diff from user worktree changes before modifying `lev_2.tscn`.

## Gameplay Shell

- [ ] Title screen starts a new game.
- [ ] Chapter select respects unlock state.
- [ ] Webtoon page images load for Chapters 1 through 8.
- [ ] A segment starts in landscape and returns to the webtoon in portrait.
- [ ] Successful segment completion records progress and coins exactly once.
- [ ] Failed/back-out segment returns without completing the segment.
- [ ] Chapter completion and achievements agree with the live segment count.

## CH01_S01 Acceptance

- [ ] CT is playable in the hedge maze.
- [ ] There are 25 to 35 collectible coins.
- [ ] Three to four slow skull patrols are present.
- [ ] Contact damage works and respects invulnerability.
- [ ] Small vertical jumps are traversable.
- [ ] Reaching 20 coins opens the exit.
- [ ] Reaching the exit before 20 coins is handled as specified.
- [ ] Successful completion returns to the correct webtoon trigger.

## Before Every Milestone

- [ ] Static resource-path scan passes or has documented, accepted exceptions.
- [ ] Godot parser/import check passes.
- [ ] Affected scenes open in the editor.
- [ ] No unexpected scene/script/resource moves occurred.
- [ ] Mobile portrait/landscape transitions are exercised.
- [ ] Docs are updated with the verified result and remaining risks.
