# Sweep - Development Guide

## Project Overview

Sweep is a menu bar Minesweeper game for macOS. It features an 8x8 board with 10 mines, generating the same daily puzzle for all players using deterministic seeding.

## Technology Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Target:** macOS 13+ (Ventura)
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

## Code Style

- SwiftLint with default rules
- No force unwraps (`!`) - use `guard let` or `if let`
- Prefer `struct` over `class` where possible
- Use `@Observable` (Swift 5.9) over `@ObservableObject`

## Game Constants

- Board size: 8x8 (64 cells)
- Mine count: 10
- First click is always safe (relocate mine if needed)

## Workflow

### Fizzy Board
User stories are tracked on the Sweep Fizzy board: https://app.fizzy.do/6145991/boards/03fgsne3i8553pc9z1b7w2y3u

**Before starting work:**
1. Move the card for the story to the "In-progress" column
2. Read the full card description to understand acceptance criteria
3. Check dependencies are complete

**While working:**
- Commit incrementally as you complete parts of the story
- Update AGENTS.md with new learnings or instructions

**When done:**
- Ensure all acceptance criteria are met
- Close the card (mark as done)

### Account Details
- Account slug: `/6145991`
- Board ID: `03fgsne3i8553pc9z1b7w2y3u`
- In-progress column ID: `03fgstkhdcurmwz1hsg3oxup6`

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

**Optional:**
- UI testing (focus on logic correctness first)
