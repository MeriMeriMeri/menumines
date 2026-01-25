# Sweep Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                    App Shell                         │
│    (SweepApp, MenuBarExtra, Info.plist config)      │
├─────────────────────────────────────────────────────┤
│                    UI Layer                          │
│   (GameBoardView, CellView, MenuContentView)        │
├─────────────────────────────────────────────────────┤
│                 Game Logic Layer                     │
│        (Board, Cell, GameState, Timer)              │
├─────────────────────────────────────────────────────┤
│               Daily Board Service                    │
│      (SeededGenerator, DailyBoardService)           │
└─────────────────────────────────────────────────────┘
```

---

## Module Definitions

### Module A: Game Logic (No Dependencies)

Pure Swift types with no UI framework imports.

#### Cell.swift
```swift
enum CellState: Equatable {
    case hidden
    case revealed(adjacentMines: Int)
    case flagged
    case mine
    case exploded
}

struct Cell {
    var state: CellState
    var hasMine: Bool
}
```

#### Board.swift
```swift
struct Board {
    let rows: Int = 8
    let cols: Int = 8
    let mineCount: Int = 10
    private(set) var cells: [[Cell]]

    init(seed: Int64)
    mutating func reveal(row: Int, col: Int) -> RevealResult
    mutating func toggleFlag(row: Int, col: Int)
    func adjacentMineCount(row: Int, col: Int) -> Int
}

enum RevealResult {
    case safe(cellsRevealed: Int)
    case mine
    case alreadyRevealed
}
```

#### GameState.swift
```swift
@Observable
final class GameState {
    private(set) var board: Board
    private(set) var status: GameStatus
    private(set) var elapsedTime: TimeInterval
    private(set) var flagCount: Int

    func reveal(row: Int, col: Int)
    func toggleFlag(row: Int, col: Int)
    func reset()
}

enum GameStatus {
    case playing
    case won
    case lost
}
```

**Win Condition:** All cells where `hasMine == false` are in `revealed` state.

**Reveal Cascading:** When revealing a cell with 0 adjacent mines, automatically reveal all adjacent cells (recursive flood fill).

---

### Module B: Daily Board Service (No Dependencies)

#### SeededGenerator.swift
```swift
import GameplayKit

final class SeededGenerator {
    private let source: GKLinearCongruentialRandomSource

    init(seed: Int64) {
        source = GKLinearCongruentialRandomSource(seed: UInt64(bitPattern: seed))
    }

    func nextInt(upperBound: Int) -> Int {
        return source.nextInt(upperBound: upperBound)
    }
}
```

#### DailyBoardService.swift
```swift
protocol DailyBoardServiceProtocol {
    func boardForToday() -> Board
    func boardForDate(_ date: Date) -> Board
}

final class DailyBoardService: DailyBoardServiceProtocol {
    func boardForToday() -> Board {
        return boardForDate(Date())
    }

    func boardForDate(_ date: Date) -> Board {
        let seed = seedFromDate(date)
        return Board(seed: seed)
    }

    private func seedFromDate(_ date: Date) -> Int64 {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return Int64(year * 10000 + month * 100 + day)
    }
}
```

---

### Module C: UI Components (Depends on A's Interfaces)

#### CellView.swift
```swift
struct CellView: View {
    let cell: Cell
    let isSelected: Bool
    let onReveal: () -> Void
    let onFlag: () -> Void

    var body: some View { ... }
}
```

Rendering rules:
- `hidden` → gray square
- `revealed(0)` → empty square
- `revealed(n)` → number with color (1=blue, 2=green, 3=red, etc.)
- `flagged` → flag icon
- `mine` → mine icon (shown on game over)
- `exploded` → red background with mine

#### GameBoardView.swift
```swift
struct GameBoardView: View {
    @Bindable var gameState: GameState
    @State private var selectedRow: Int = 0
    @State private var selectedCol: Int = 0

    var body: some View { ... }
}
```

Responsibilities:
- Render 8x8 grid of CellViews
- Track keyboard selection
- Forward reveal/flag actions to GameState

#### MenuContentView.swift
```swift
struct MenuContentView: View {
    @Bindable var gameState: GameState

    var body: some View {
        VStack {
            HeaderView(status: gameState.status, time: gameState.elapsedTime)
            GameBoardView(gameState: gameState)
            FooterView(onReset: gameState.reset, onQuit: { NSApp.terminate(nil) })
        }
    }
}
```

---

### Module D: App Shell (Depends on All)

#### SweepApp.swift
```swift
@main
struct SweepApp: App {
    @State private var gameState: GameState

    init() {
        let service = DailyBoardService()
        _gameState = State(initialValue: GameState(board: service.boardForToday()))
    }

    var body: some Scene {
        MenuBarExtra("Sweep", systemImage: "circle.grid.3x3.fill") {
            MenuContentView(gameState: gameState)
        }
        .menuBarExtraStyle(.window)
    }
}
```

#### Info.plist Configuration
```xml
<key>LSUIElement</key>
<true/>
```

#### Keyboard Event Handling
```swift
NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
    switch event.keyCode {
    case 123: // Left arrow
    case 124: // Right arrow
    case 125: // Down arrow
    case 126: // Up arrow
    case 49:  // Space
    case 3:   // F key
    }
    return event
}
```

---

## Parallel Work Streams

| Stream | Module | Dependencies | Can Start |
|--------|--------|--------------|-----------|
| 1 | Game Logic (Cell, Board, GameState) | None | Immediately |
| 2 | Daily Board Service | None | Immediately |
| 3 | UI Components | Game Logic interfaces | After interfaces defined |
| 4 | App Shell | All modules | After modules stubbed |

### Interface Contracts

Streams 1 and 2 define these protocols that Stream 3 codes against:

```swift
// From Game Logic
protocol GameStateProtocol {
    var board: Board { get }
    var status: GameStatus { get }
    var elapsedTime: TimeInterval { get }
    var flagCount: Int { get }
    func reveal(row: Int, col: Int)
    func toggleFlag(row: Int, col: Int)
    func reset()
}

// From Daily Board Service
protocol DailyBoardServiceProtocol {
    func boardForToday() -> Board
    func boardForDate(_ date: Date) -> Board
}
```

---

## Implementation Phases

### Phase 1: Foundation (Parallel)

**Stream 1 - Game Logic:**
- [ ] `Cell` struct and `CellState` enum
- [ ] `Board` struct with initializer (no mines yet)
- [ ] `GameState` class with `@Observable`
- [ ] Unit tests for basic types

**Stream 2 - Daily Service:**
- [ ] `SeededGenerator` wrapping GameplayKit
- [ ] `DailyBoardService` with seed calculation
- [ ] Unit tests verifying deterministic output

**Verification:**
- Both streams have passing unit tests
- Same seed produces identical boards

### Phase 2: Core Features (Parallel)

**Stream 1 - Game Logic:**
- [ ] Mine placement using SeededGenerator
- [ ] `reveal()` with cascade for zero-adjacent cells
- [ ] Win/lose detection
- [ ] First-click safety (relocate mine)
- [ ] Timer integration

**Stream 2 - Daily Service:**
- [ ] Board caching (optional optimization)

**Stream 3 - UI Components:**
- [ ] `CellView` with all state renderings
- [ ] `GameBoardView` grid layout
- [ ] `MenuContentView` with header/footer
- [ ] Mouse click handling

**Verification:**
- Can play a complete game in UI
- Win/lose states display correctly

### Phase 3: Integration

- [ ] `SweepApp` with MenuBarExtra
- [ ] Connect all modules
- [ ] Keyboard event monitor
- [ ] LSUIElement configuration
- [ ] Quit button functionality

**Verification:**
- App appears in menu bar only (no Dock)
- Full game playable via mouse and keyboard
- Daily board matches across app restarts

### Phase 4: Polish

- [ ] Timer display formatting (MM:SS)
- [ ] Mine counter display
- [ ] Visual feedback (selection highlight, hover states)
- [ ] App icon design
- [ ] Sound effects (optional)
- [ ] Smooth reveal animations (optional)

**Verification:**
- App feels polished and responsive
- All controls documented in README work

---

## Testing Strategy

### Unit Tests (Required)

| Test File | Coverage |
|-----------|----------|
| `CellTests.swift` | State transitions |
| `BoardTests.swift` | Mine placement, reveal logic, cascade |
| `GameStateTests.swift` | Win/lose, timer, flag counting |
| `SeededGeneratorTests.swift` | Deterministic output |
| `DailyBoardServiceTests.swift` | Seed calculation, date handling |

### Key Test Cases

```swift
// Deterministic boards
func testSameSeedProducesSameBoard() {
    let board1 = Board(seed: 20240315)
    let board2 = Board(seed: 20240315)
    XCTAssertEqual(board1.cells, board2.cells)
}

// Cascade reveal
func testRevealZeroCascades() {
    var board = Board(seed: testSeed)
    let result = board.reveal(row: safeCorner.row, col: safeCorner.col)
    // Should reveal multiple cells
}

// Win condition
func testWinWhenAllNonMinesRevealed() {
    // Reveal all 54 non-mine cells
    XCTAssertEqual(gameState.status, .won)
}
```

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Board size | 8x8, 10 mines | Classic beginner size, games under 60s |
| Game mode | Daily only | Aligns with "no decisions" philosophy |
| First click | Always safe | Standard Minesweeper UX |
| State management | @Observable | Modern Swift, simpler than Combine |
| RNG | GKLinearCongruentialRandomSource | Built-in, seedable, deterministic |
| Window style | .window (not .menu) | Allows rich custom UI |
