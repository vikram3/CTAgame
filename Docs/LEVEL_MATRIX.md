# PDF to Project Coverage Matrix

Status key: `Candidate` means an authored scene or script resembles the segment but is not routed by `ChapterData`. `Prototype` means the live route points to the generic prototype. `Missing` means no segment-specific implementation was found.

| Segment | PDF archetype | Current project evidence | Status |
| --- | --- | --- | --- |
| CH01_S01 Bush Maze Sneak | Top-down stealth/coin maze | `lev_1.tscn`, `lev_1.gd`, top-down player, skulls, coin objective | Candidate; live route is Prototype |
| CH01_S02 Treasure Chase | Timed platformer chase/combat | `lev_2.tscn`, 60-second controller, chest | Candidate; live route is Prototype |
| CH02_S01 Shadow Flood | Coin arena with shadow bursts | Generic prototype has coin/burst objective; definition commented out | Prototype only; missing live segment |
| CH02_S02 Boss Dodge | 90-second boss survival | Segment definition uses prototype | Missing boss and attacks |
| CH02_S03 Reinforcement Wave | Three-wave defense | `level_5.tscn` / `level_5.gd` candidate | Candidate; live route is Prototype |
| CH03_S01 Cliff Panic | Horn survival/fall | `level_6.tscn` / `level_6.gd`, Horn behavior | Candidate; live route is Prototype |
| CH03_S02 Forest Exploration | Felix follower and 35 coins | `level_7.tscn` / `level_7.gd`, Felix script | Candidate; live route is Prototype |
| CH04_S01 Forest Escape | Auto-scroll chase | `level_8.tscn` / `level_8.gd`; definition commented out | Candidate; missing live segment |
| CH04_S02 Combat Tutorial | Type-weakness combat | `level_9.tscn` and header-only derived script | Missing mechanics; live route is Prototype |
| CH05_S01 Bull Stampede | Charges plus minor bulls | `level_10.tscn` and header-only derived script | Missing actors/mechanics |
| CH05_S02 Duel Warmup | Coin collection and flying waves | `level_11.tscn` and header-only derived script | Missing actors/mechanics |
| CH06_S01 Boomerang Duel | Alex, Big Bird, shield, close hits | `level_12.tscn` and header-only derived script | Missing actors/mechanics |
| CH06_S02 Crowd Scramble | Timed hazards and coins | `level_13.tscn` and header-only derived script | Missing actors/mechanics |
| CH07_S01 Victory Rush | Ship-deck falling coins | `level_14.tscn` and header-only derived script | Missing environment/mechanics |
| CH07_S02 Ship Disaster | Slanted ship, crates, poles | `level_15.tscn` and header-only derived script | Missing environment/mechanics |
| CH08_S01 Sand Land Intro | Sand exploration and ruins | `level_16.tscn` and header-only derived script | Missing environment/mechanics |
| CH08_S02 Contract Panic | Quicksand and coin bag | `level_17.tscn` and header-only derived script | Missing environment/mechanics |
| CH08_S03 Wormfish Chase | Auto-scroll, rocks, no combat | `level_18.tscn` and header-only derived script | Missing actor/mechanics |
| Final Big Boss | Reserve only | No confirmed implementation | TODO; do not design yet |

The source materials contain a future final-boss listing, but the chapter breakdown in the current design authority specifies 18 chapter segments. Treat the final boss as reserved architecture only until its specification is confirmed.
