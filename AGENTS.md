# MenuMines - Development Guide

## Project Overview

MenuMines is a menu bar Minesweeper game for macOS. It features a 9x9 board with 15 mines, generating the same daily puzzle for all players using deterministic seeding.

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
MenuMines/
├── MenuMinesApp.swift              # App entry point, MenuBarExtra setup
├── Constants.swift             # App-wide constants and UserDefaults keys
├── Models/
│   ├── Board.swift             # 9x9 grid, mine placement, reveal logic
│   ├── Cell.swift              # Cell state enum
│   ├── DailyBoard.swift        # Date-based board generation
│   ├── GameResult.swift        # Win/loss result with timing
│   ├── GameState.swift         # @Observable game state
│   ├── MenuBarIconState.swift  # Menu bar icon state machine
│   └── StatsStore.swift        # Persistent stats storage
├── Views/
│   ├── AboutWindow.swift       # About window
│   ├── CellView.swift          # Individual cell rendering
│   ├── ConfettiView.swift      # Win celebration animation
│   ├── FooterView.swift        # Menu and quit button
│   ├── GameBoardView.swift     # 9x9 grid of cells
│   ├── HeaderView.swift        # Timer, flag count, reset
│   ├── MenuContentView.swift   # Main popover content
│   ├── SettingsView.swift      # App settings
│   └── StatsWindow.swift       # Statistics display
├── Resources/
│   ├── Assets.xcassets         # App icon
│   └── en.lproj/Localizable.strings
MenuMinesTests/
├── BoardTests.swift
├── DailyBoardTests.swift
├── DailyCompletionTests.swift
├── GameStateTests.swift
├── MenuBarIconStateTests.swift
├── SettingsTests.swift
└── StatsStoreTests.swift
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
xcodebuild -scheme MenuMines -configuration Release

# Run tests (code signing must be disabled to avoid Team ID mismatch errors)
xcodebuild test -scheme MenuMines CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""

# Clean build
xcodebuild clean -scheme MenuMines
```

## Testing Requirements

**Tests must always be run:**
- After any substantive code change, even if not explicitly asked
- Before every commit

This is non-negotiable. CI does not run on PRs, so local test runs are the only safeguard.

## Accessibility

MenuMines must be fully playable with VoiceOver. Accessibility is a core requirement, not an afterthought.

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

- Board size: 9x9 (81 cells)
- Mine count: 12
- First click is always safe (relocate mine if needed)
- If the first click hits a mine, relocation uses system randomness (boards can diverge after that first click)

## Workflow

### Linear
User stories are tracked in Linear under the MenuMines project.

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
- Project: MenuMines (`sweep-f5976e94df09`)
- Issue prefix: `MER` (e.g., `MER-23`)
- Workflow: Todo → In Progress → Done

## State Management Rules

The app maintains consistent behavior across resume, pause, completion, and recovery scenarios.

### Completion
- **Completion = win or loss**: A daily puzzle is complete when the game status becomes `.won` or `.lost`
- Both outcomes mark `dailyCompletionSeed` in UserDefaults
- Both outcomes record stats (once per day, deduped by seed)

### Timer Behavior
- **Starts**: On first `reveal()` call (not on flag)
- **Pauses**: When menu bar popover closes (`onDisappear`)
- **Resumes**: When popover reopens (`onAppear`) if status is `.playing`
- **Stops**: On win, loss, or reset

### Reset Lock
- Once today's puzzle is complete (win or loss), reset is disabled for the rest of the day
- `canReset` checks `isDailyPuzzleComplete()` using UTC date
- Enforced in: HeaderView emoji, FooterView menu, keyboard shortcut (⌘R)

### Persistence
- **GameSnapshot**: Saves/restores full game state (board, status, time, flags, selection)
- **dailyCompletionSeed**: Tracks if today's puzzle was completed
- **dailyStatsRecordedSeed**: Prevents duplicate stats recording
- **dailyStats_<seed>**: Stores DailyStats struct for each completed day

### Error Recovery
When app launches:
1. Try to load snapshot → restore full state if valid and today's seed
2. If snapshot missing/corrupted but daily complete → restore from stats (won/lost, time, flags)
3. Otherwise → fresh game with today's board

### Share Availability
- Share button visible when `status == .won || status == .lost`
- Persists after relaunch because snapshot preserves status

### Daily Seed
```swift
// All date-based logic uses UTC timezone
let seed = Int64(year * 10000 + month * 100 + day)
// Example: 2026-01-25 → 20260125
```

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

**Emojis are locale-independent** and don't need localization: 🚩, 💣, 🙂, 😎, 😵, 🎉

### Localizable.strings

All user-facing text is in `MenuMines/Resources/en.lproj/Localizable.strings`. This includes strings for buttons, menu items, accessibility labels, share text, and stats display.

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
