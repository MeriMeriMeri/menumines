# Sweep - Development Guide

## Project Overview

Sweep is a menu bar Minesweeper game for macOS. It features an 8x8 board with 10 mines, generating the same daily puzzle for all players using deterministic seeding.

## Technology Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Target:** macOS 14+ (Sonoma) - required for @Observable macro
- **Key APIs:**
  - `MenuBarExtra` with `.window` style for rich popover UI
  - `GameplayKit` `GKLinearCongruentialRandomSource` for seeded RNG
  - `NSEvent.addLocalMonitorForEvents` for keyboard input

## Directory Structure

```
Sweep/
├── SweepApp.swift              # App entry point, MenuBarExtra setup
├── Models/
│   ├── Cell.swift              # Cell state enum
│   ├── Board.swift             # 8x8 grid, mine placement, reveal logic (uses GameplayKit directly)
│   ├── GameState.swift         # @Observable game state
│   └── DailyBoard.swift        # Free functions for date-based board generation
├── Views/
│   ├── GameBoardView.swift     # 8x8 grid of cells
│   ├── CellView.swift          # Individual cell rendering
│   └── MenuContentView.swift   # Main popover content
├── Resources/
│   └── Assets.xcassets         # App icon, cell images
└── Tests/
    ├── CellTests.swift
    ├── BoardTests.swift
    ├── GameStateTests.swift
    └── DailyBoardTests.swift
```

## Key Patterns

### Game Logic is Pure Swift
All game logic (`Board`, `Cell`, `GameState`) has no UI dependencies. This enables comprehensive unit testing without SwiftUI test harnesses.

### Views are Stateless
Views read from `@Observable GameState` and call methods on it. No view-local game state.

### Daily Seed Formula
```swift
// IMPORTANT: Use UTC timezone so all players get same puzzle globally
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "UTC")!
let seed = Int64(year * 10000 + month * 100 + day)
// Example: 2024-03-15 → 20240315
```

### Agent App Configuration
Set `LSUIElement = YES` in Info.plist to hide from Dock. The UI must provide a Quit button since there's no Dock icon to right-click.

## Build Commands

```bash
# Build release
xcodebuild -scheme Sweep -configuration Release

# Run tests
xcodebuild test -scheme Sweep

# Clean build
xcodebuild clean -scheme Sweep
```

## Accessibility

Sweep must be fully playable with VoiceOver. Accessibility is a core requirement, not an afterthought.

### Required Accessibility Features

1. **Cell Labels** - Every cell needs a descriptive accessibility label:
   - Hidden cells: "Row X, Column Y, covered" or "Row X, Column Y, flagged"
   - Revealed cells: "Row X, Column Y, [number] adjacent mines" or "Row X, Column Y, empty"
   - Mines: "Row X, Column Y, mine"

2. **State Announcements** - Use `AccessibilityNotification.Announcement` to announce:
   - Game win: "Congratulations! You won in X seconds"
   - Game loss: "Game over. You hit a mine"
   - Timer updates (on demand, not continuously)

3. **Keyboard Navigation** - Already implemented via arrow keys + Space/F (see Controls)

4. **Control Labels** - All buttons need accessibility labels:
   - Reset button: "Reset game"
   - Timer display: "Elapsed time: X seconds"
   - Mine counter: "X mines remaining"

### Implementation Notes

```swift
// Cell accessibility label example
.accessibilityLabel(cellAccessibilityLabel(row: row, col: col, cell: cell))
.accessibilityHint("Double-tap to reveal, or use F to flag")

// State announcement example
AccessibilityNotification.Announcement("Game over").post()
```

### Testing Accessibility

Use these tools to verify accessibility:
- **Accessibility Inspector** (Xcode → Open Developer Tool): Check labels and traits
- **VoiceOver** (Cmd+F5): Play through the entire game with VoiceOver enabled
- Test all game states: initial, in-progress, won, lost

## Code Style

- SwiftLint with default rules
- No force unwraps (`!`) - use `guard let` or `if let`
- Prefer `struct` over `class` where possible
- Use `@Observable` (Swift 5.9) over `@ObservableObject`

## Game Constants

- Board size: 8x8 (64 cells)
- Mine count: 10
- First click is always safe (relocate mine if needed)
- If the first click hits a mine, relocation uses system randomness (boards can diverge after that first click)

## Workflow

### Linear
User stories are tracked in Linear under the Sweep project.

**Before starting work:**
1. Move the issue to "In Progress" status
2. Read the full issue description to understand acceptance criteria
3. Check blocking issues are resolved

**While working:**
- Commit incrementally as you complete parts of the story
- Update AGENTS.md with new learnings or instructions

**When done:**
- Ensure all acceptance criteria are met
- Leave the issue in "In Progress" status (do NOT move to "Done" - another process handles that)

### Linear Details
- Organization: `merimerimeri`
- Project: Sweep (`sweep-f5976e94df09`)
- Issue prefix: `MER` (e.g., `MER-23`)
- Workflow: Todo → In Progress → Done

## Testing Strategy

Core game logic must be thoroughly tested since we use concrete types without protocols. Test the actual classes directly—no mocks needed.

**Required coverage:**
- Unit test all game logic (Board, GameState, DailyBoard functions)
- Test win/lose conditions
- Test reveal cascading behavior
- Test first-click safety (mine relocation)
- Test timer start/pause/resume behavior
- Test deterministic seeding produces identical boards
- Test UTC timezone consistency (same Date produces same seed regardless of local timezone)
- Test keyboard selection movement and bounds

**Accessibility testing (required before release):**
- Verify all cells have correct accessibility labels
- Test full game flow with VoiceOver enabled (Cmd+F5)
- Confirm win/loss announcements are spoken
- Verify keyboard navigation works with VoiceOver focus

**Optional:**
- UI testing (focus on logic correctness first)

## Localization

The app is structured to support future localization. Follow these guidelines to keep it localization-ready.

### String Handling

**Never hard-code user-facing strings.** All text shown to users must go through the localization system:

```swift
// ❌ Bad - hard-coded string
Text("Reset")
Button("Quit") { ... }

// ✅ Good - uses String Catalog / Localizable.strings
Text("reset_button", tableName: "Localizable")
Button(String(localized: "quit_button")) { ... }
```

**Current user-facing strings to localize:**
- Button labels: "Reset", "Quit"
- Accessibility labels: "About Sweep"
- App name in menu bar (if displayed as text)

**Emojis are locale-independent** and don't need localization: 🚩, 💣, 🙂, 😎, 😵, 🎉

### Localizable.strings

The `Localizable.strings` file lives in `Sweep/Resources/en.lproj/` and contains all user-facing text:

```
// Sweep/Resources/en.lproj/Localizable.strings
"reset_button" = "Reset";
"quit_button" = "Quit";
"about_help" = "About Sweep";
"menubar_title" = "Sweep";
```

When adding new user-facing strings:
1. Add the key-value pair to `Localizable.strings`
2. Use `String(localized:)` or `Text(_:tableName:)` in code
3. Use descriptive keys that indicate purpose, not content

### Date and Number Formatting

**Use locale-aware formatters** for user-facing dates and numbers:

```swift
// ❌ Bad - assumes specific locale format
let dateString = "\(month)/\(day)/\(year)"
let priceString = "$\(amount)"

// ✅ Good - respects user's locale
let dateString = date.formatted(date: .abbreviated, time: .omitted)
let priceString = amount.formatted(.currency(code: "USD"))
```

**Exception:** The game timer (`%02d:%02d`) is intentionally locale-independent since `MM:SS` is a universal stopwatch format, not a localized time display.

**Exception:** The daily seed calculation must always use UTC timezone to ensure all players worldwide get the same puzzle - this is not a localization concern but a game design requirement.

### Testing Localization

When adding localized strings:
- Test with different system languages to catch layout issues
- Verify strings don't get truncated in UI
- Check that emojis render correctly across locales
