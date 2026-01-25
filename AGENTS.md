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
│   ├── Board.swift             # 8x8 grid, mine placement, reveal logic
│   └── GameState.swift         # @Observable game state
├── Services/
│   ├── DailyBoardService.swift # Date-based board generation
│   └── SeededGenerator.swift   # Wraps GKLinearCongruentialRandomSource
├── Views/
│   ├── GameBoardView.swift     # 8x8 grid of cells
│   ├── CellView.swift          # Individual cell rendering
│   └── MenuContentView.swift   # Main popover content
├── Resources/
│   └── Assets.xcassets         # App icon, cell images
└── Tests/
    ├── BoardTests.swift
    ├── GameStateTests.swift
    └── DailyBoardServiceTests.swift
```

## Key Patterns

### Game Logic is Pure Swift
All game logic (`Board`, `Cell`, `GameState`) has no UI dependencies. This enables comprehensive unit testing without SwiftUI test harnesses.

### Views are Stateless
Views read from `@Observable GameState` and call methods on it. No view-local game state.

### Daily Seed Formula
```swift
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

## Testing Strategy

- Unit test all game logic (Board, GameState, DailyBoardService)
- Test win/lose conditions
- Test reveal cascading behavior
- Test deterministic seeding produces identical boards
- UI testing optional, focus on logic correctness
