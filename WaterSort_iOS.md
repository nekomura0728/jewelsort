## Water Sort (iOS) — Product & Tech Spec (Draft)

### Overview
A minimalist Water Sort puzzle for iOS. Sort colored liquids in tubes so each tube contains a single color. Fast, smooth animations, infinite levels via generator, no account.

- Business: Free + one-time purchase (~¥300) to unlock advanced features and remove soft limits. No ads.
- Platform: iOS, SwiftUI + SpriteKit (2D). Offline, on-device only.

### Core Gameplay
- State: N tubes, capacity = 4 (default). C colors, each appears exactly 4 times. Extra empty tubes = 2 (default).
- Move: Pour from source to destination if:
  - Source not empty.
  - Destination not full.
  - Destination empty OR destination top color == source top color.
  - Pours only the top contiguous segment of same color from source.
- Goal: All non-empty tubes are uniform (single color) and full; remaining tubes empty.
- Quality-of-life: Prevent no-op moves; optional rule to disallow pouring from already uniform-full tube.

### Free (MVP) Scope
- Infinite Levels: Procedural generator ensures solvable states (seeded) for Normal difficulty.
- Game Loop: Level start → play → undo (up to 3) → restart → next level.
- Controls: Tap source → tap destination (or drag). Invalid move → haptic.
- Animations: Smooth pour of contiguous segment, fill height interpolation, basic splash.
- Hints: 1-step suggestion (1 per level).
- Progress: Local save for current level, best moves/time, streak count.
- Visuals: 1 theme (auto light/dark).
- Accessibility: Colorblind-friendly palette switch (free).

Free soft limits (suggested)
- Undo: 3 per level
- Hint: 1 per level
- Difficulty: Normal only (capacity 4, extraEmpty 2)

### One-Time Purchase Unlock (~¥300)
- Unlimited Undo & Hints.
- Difficulties: Hard (extraEmpty 1), Expert (capacity 5 / extraEmpty 1, etc.).
- Themes: extra palettes/backgrounds/tube skins.
- Speed: animation speed control (fast/normal/slow).
- Level Sets: Daily seed browser, past levels replay, Favorites.

### Level Generation
- Parameters: colors=C, tubes=T=C+extraEmpty, capacity=4.
- Process:
  1) Create multiset with each color repeated `capacity` times.
  2) Shuffle and deal into first C tubes; append `extraEmpty` empty tubes.
  3) Reject trivially solved setups; enforce at least K mixed tubes.
  4) Solvability check via solver (IDDFS/A*). If not solvable within depth/time budget, reshuffle.
- Determinism: Seeded RNG for reproducible levels; daily seed = `yyyymmdd`.
- Difficulty knobs: extraEmpty, colors count, capacity, bias to reduce easy merges.

### Solver (validation & hints)
- Encoding: stacks of small Ints; 64-bit hash for visited set.
- Moves: For each source, consider top segment and legal destinations.
- Search: IDDFS or A* (heuristic = unmatched segments + empty slack).
- Hint: shallow search (~10–30ms budget) to suggest next move; fallback to any legal move on timeout.

### Data Model
- LevelConfig: seed, colors, tubes, capacity, extraEmpty, difficulty.
- Tube: [Int] length ≤ capacity (0 = empty slot not stored).
- GameState: tubes [[Int]], moves [Move], undoStack [Move], startTime, best.
- Move: srcIndex, dstIndex, amount.
- ProgressStore: best-by-seed, streak, settings, purchased flag.

### Architecture
- UI: SwiftUI shells (Home, Game, Settings, Themes); GameView hosts SpriteKit scene.
- Scene: GameScene renders tubes/liquids, handles tap/drag, asks GameCore for legality/state updates.
- Core: GameCore (pure logic) — apply/undo, win check, generator, solver.
- Services: Haptics, StoreKit 2, Persistence (UserDefaults/Codable or SQLite v2).

### Screens / Flows
- Home: Play (Normal/Hard/Expert), Daily, Settings, Themes (locked badges).
- Game: Header (moves/time/undo/hint), Board (tubes), Footer (restart/next).
- Settings: Default difficulty, Colorblind mode, Animation speed, Sound, Restore Purchase.
- Themes: Preview and select (purchase unlock).

### Visual & Animation
- Tubes: Rounded rect with 4 slots. Liquids layered; pour anim = move segment along bezier to dest, then merge/settle.
- Durations: 0.25–0.35s per segment (scaled by speed).
- Haptics: success, warning (invalid move), win.

### StoreKit
- Product ID: `pro.unlock` (Non‑Consumable).
- Gate: Unlimited undo/hints, Hard/Expert, Themes, Speed control, Level sets.
- Restore: in Settings.

### Tech Stack
- Swift 5.9+, SwiftUI, SpriteKit, StoreKit 2, Combine (light).
- Persistence: UserDefaults + Codable file store (v1) → SQLite/GRDB (v2).
- Testing: XCTest for GameCore, Generator, Solver.

### MVP Acceptance
- Generator produces diverse, solvable boards; immediate play.
- Smooth pour animations; invalid move feedback.
- Undo 3 / Hint 1 works; win detection stable; next level flow ok.

### Risks & Mitigations
- Generator bias: tune reject rules; seed diversity; collect simple telemetry later (optional).
- Solver cost: time-boxed search; heuristic pruning; fallback hints.
- Color perception: free colorblind mode with symbols/patterns.

### Development Plan (6–8 days)
1) Scaffold (SwiftUI+SpriteKit), GameCore skeleton, tube rendering.
2) Rules (legality/apply/win) + unit tests.
3) Level generator (Normal) + solver (validate/hints).
4) Animations (pour/merge) + input (tap/drag).
5) Progress (undo/hint/restart/next) + persistence.
6) UI polish (Home/Settings/Themes) + purchase gate.
7) StoreKit (buy/restore) + premium features.
8) QA/balancing (speed/difficulty/reject tuning).

---
Status: Draft v0.1. Confirm features/pricing to proceed with scaffolding.
