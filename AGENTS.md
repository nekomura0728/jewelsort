# Repository Guidelines

## Project Structure & Modules
- Source: `WaterSort/Watersort/Watersort/`
  - Views: `Views/` (`GameView.swift`, `SettingsView.swift`, etc.)
  - Core: `GameCore/` (`GameCore.swift`, `AdvancedHintSystem.swift`)
  - Models: `Models/` (`GameModels.swift`, etc.)
  - Assets: `Assets.xcassets/`, `Preview Content/`
- Tests: `WaterSort/Watersort/WatersortTests/` (unit) and `WaterSort/Watersort/WatersortUITests/` (UI)
- Xcode Projects: `WaterSort/WaterSort.xcodeproj` and `WaterSort/Watersort/Watersort.xcodeproj`
- Spec: `docs/WaterSort_iOS.md` (architecture and product scope)

## Build, Test, and Development
- Open in Xcode: `open WaterSort/Watersort/Watersort.xcodeproj`
- Build (Simulator): `xcodebuild -project WaterSort/Watersort/Watersort.xcodeproj -scheme Watersort -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Run tests: `xcodebuild -project WaterSort/Watersort/Watersort.xcodeproj -scheme Watersort -destination 'platform=iOS Simulator,name=iPhone 15' test`
- Recommended: run from Xcode (Product → Test) for UI tests and debugging.

## Coding Style & Naming
- Swift 5.9+, 2‑space indentation, trim trailing whitespace.
- Types/protocols: UpperCamelCase; funcs/vars: lowerCamelCase; enum cases: lowerCamelCase.
- SwiftUI views end with `View` (e.g., `LevelEditorView`). One primary type per file.
- Prefer `let` and immutability; keep `GameCore` pure/deterministic.
- Optional tools: SwiftFormat/SwiftLint (if installed); match existing file layout and spacing.

## Testing Guidelines
- Framework: XCTest. Place unit tests under `WatersortTests` (focus: `GameCore`, generator, solver);
  UI flows under `WatersortUITests`.
- Naming: `test_<Behavior>_<Condition>()` (e.g., `test_Pour_MergesSameColor`).
- Use deterministic seeds for generator/solver tests; avoid sleeps in unit tests.
- Aim for strong coverage on `GameCore` and move legality; smoke tests for views.
birudo 
## Commit & Pull Requests
- Commits: concise imperative subject (max ~72 chars) with context in body.
  Example: `Fix(GameCore): prevent no‑op pour from uniform tube`.
- PRs: clear description, linked issues, screenshots or short screen recording for UI,
  list tested device/simulator + iOS version, and notes on performance/animations if relevant.
- Keep PRs focused; include update to `docs/WaterSort_iOS.md` if behavior/config changes.

## Security & Configuration
- Do not commit signing profiles or provisioning data.
- StoreKit: keep product IDs consistent (e.g., `pro.unlock`).
- App is offline by design; avoid adding network dependencies without discussion.
