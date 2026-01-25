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
│           (Board, Cell, GameState)                  │
├─────────────────────────────────────────────────────┤
│                 Daily Board                          │
│         (free functions for seed/date)              │
└─────────────────────────────────────────────────────┘
```

---

## Module Definitions

### Module A: Game Logic (No UI Dependencies)

Pure Swift types with no UI framework imports. Board uses GameplayKit directly for deterministic RNG.

#### Cell.swift
```swift
enum CellState: Equatable {
    case hidden
    case revealed(adjacentMines: Int)
    case flagged
}

struct Cell: Equatable {
    var state: CellState
    let hasMine: Bool
    var isExploded: Bool = false  // true only for the mine the player clicked
}
```

Note: Mine visibility is computed at render time based on game status and `hasMine`, not stored in `CellState`. This prevents state duplication between `hasMine` and cell state.

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
    mutating func markExploded(row: Int, col: Int)
    mutating func relocateMine(from row: Int, col: Int)  // for first-click safety
    func adjacentMineCount(row: Int, col: Int) -> Int
}

enum RevealResult {
    case safe(cellsRevealed: Int)
    case mine
}
// Note: GameState guards against revealing already-revealed cells, so Board doesn't need to handle it
```

#### GameState.swift
```swift
@Observable
final class GameState {
    private(set) var board: Board
    private(set) var status: GameStatus
    private(set) var elapsedTime: TimeInterval
    private(set) var flagCount: Int
    private(set) var selectedRow: Int = 0
    private(set) var selectedCol: Int = 0
    private var timer: Timer?

    func reveal(row: Int, col: Int)
    func toggleFlag(row: Int, col: Int)
    func reset()
    func pauseTimer()
    func resumeTimer()

    // Keyboard navigation
    func moveSelection(_ direction: Direction)
    func revealSelected()
    func toggleFlagSelected()
}

enum Direction {
    case up, down, left, right
}
```

**Win/Lose Detection Flow:**
```swift
func reveal(row: Int, col: Int) {
    guard status == .notStarted || status == .playing else { return }
    guard case .hidden = board.cells[row][col].state else { return }  // already revealed/flagged

    let isFirstClick = (status == .notStarted)
    if isFirstClick {
        // First-click safety: relocate mine if present
        if board.cells[row][col].hasMine {
            board.relocateMine(from: row, col: col)
        }
        startTimer()
        status = .playing
    }

    let result = board.reveal(row: row, col: col)

    switch result {
    case .mine:
        status = .lost
        stopTimer()
        board.markExploded(row: row, col: col)
    case .safe:
        if checkWinCondition() {
            status = .won
            stopTimer()
        }
    }
}

private func checkWinCondition() -> Bool {
    // Win when all 54 non-mine cells are revealed
    for row in board.cells {
        for cell in row where !cell.hasMine {
            guard case .revealed = cell.state else {
                return false  // found unrevealed non-mine cell
            }
        }
    }
    return true
}

enum GameStatus {
    case notStarted  // before first click
    case playing
    case won
    case lost
}
```

**Timer Behavior:**
- Starts on first click (first `reveal()` call), not on app launch
- Pauses when popover closes (`pauseTimer()`), resumes when reopened (`resumeTimer()`)
- Stops permanently on win/lose
- Implementation: `Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)`

**Reveal Cascading:** When revealing a cell with 0 adjacent mines, automatically reveal all adjacent cells (recursive flood fill). Board only handles mechanics—it doesn't check win/lose.

#### DailyBoard.swift
```swift
import GameplayKit

/// Free functions for daily board generation. No class needed—these are pure functions.
func dailyBoard() -> Board {
    return boardForDate(Date())
}

func boardForDate(_ date: Date) -> Board {
    let seed = seedFromDate(date)
    return Board(seed: seed)
}

private func seedFromDate(_ date: Date) -> Int64 {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let year = calendar.component(.year, from: date)
    let month = calendar.component(.month, from: date)
    let day = calendar.component(.day, from: date)
    return Int64(year * 10000 + month * 100 + day)
}
```

#### Board RNG Usage
```swift
// Board.init uses GameplayKit directly—no wrapper class needed
struct Board {
    init(seed: Int64) {
        let rng = GKLinearCongruentialRandomSource(seed: UInt64(bitPattern: seed))
        // Use rng.nextInt(upperBound:) directly for mine placement
    }
}
```

---

### Module C: UI Components (Depends on A)

#### CellView.swift
```swift
struct CellView: View {
    let cell: Cell
    let gameStatus: GameStatus  // needed to show mines on game over
    let isSelected: Bool
    let onReveal: () -> Void
    let onFlag: () -> Void

    var body: some View { ... }
}
```

Rendering rules:
- `hidden` → gray square (or mine icon if game lost and `hasMine`)
- `revealed(0)` → empty square
- `revealed(n)` → number with color (1=blue, 2=green, 3=red, etc.)
- `flagged` → flag icon (or mine icon if game lost and `hasMine`)
- `isExploded` → red background with mine (the clicked mine)

#### GameBoardView.swift
```swift
struct GameBoardView: View {
    @Bindable var gameState: GameState

    var body: some View { ... }
}
```

Responsibilities:
- Render 8x8 grid of CellViews
- Highlight cell at `gameState.selectedRow/Col`
- Forward mouse clicks to GameState

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
        _gameState = State(initialValue: GameState(board: dailyBoard()))
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
// Store the monitor token to allow removal if needed
private var keyboardMonitor: Any?

// In SweepApp.init()
keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak gameState] event in
    guard let gameState else { return event }
    switch event.keyCode {
    case 123: gameState.moveSelection(.left)
    case 124: gameState.moveSelection(.right)
    case 125: gameState.moveSelection(.down)
    case 126: gameState.moveSelection(.up)
    case 49:  gameState.revealSelected()   // Space
    case 3:   gameState.toggleFlagSelected() // F key
    default: break
    }
    return event
}
```

---

## Implementation Phases

### Phase 1: Foundation

**Game Logic:**
- [ ] `Cell` struct and `CellState` enum
- [ ] `Board` struct with seeded RNG (uses GameplayKit directly)
- [ ] `GameState` class with `@Observable`
- [ ] `dailyBoard()` and `boardForDate()` free functions
- [ ] Unit tests for basic types and deterministic output

**Verification:**
- All unit tests passing
- Same seed produces identical boards

### Phase 2: Core Features

**Game Logic:**
- [ ] Mine placement using seeded RNG
- [ ] `reveal()` with cascade for zero-adjacent cells
- [ ] Win/lose detection
- [ ] First-click safety (relocate mine to random empty cell)
- [ ] Timer integration (start/pause/resume/stop)
- [ ] Selection movement with bounds checking

**UI Components:**
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

**Verification:**
- App feels polished and responsive
- All controls documented in README work

**Future ideas (not in scope):**
- Sound effects
- Reveal animations

---

## Testing Strategy

Since we use concrete types without protocols, thorough unit testing of core game logic is essential. Test the actual classes directly—no mocks needed.

### Unit Tests (Required)

| Test File | Coverage |
|-----------|----------|
| `CellTests.swift` | State transitions |
| `BoardTests.swift` | Mine placement, reveal logic, cascade, first-click safety, deterministic seeding |
| `GameStateTests.swift` | Win/lose detection after cascade, timer start/pause/resume, flag counting, selection movement |
| `DailyBoardTests.swift` | Seed calculation, UTC date handling |

### Key Test Cases

```swift
// Deterministic boards
func testSameSeedProducesSameBoard() {
    let board1 = Board(seed: 20240315)
    let board2 = Board(seed: 20240315)
    XCTAssertEqual(board1.cells, board2.cells)
}

// UTC timezone consistency
func testLateNightUTCUsesCorrectDate() {
    // 2024-03-15 23:00 UTC = 2024-03-16 01:00 in UTC+2
    // If we incorrectly used local time in UTC+2, we'd get March 16's board
    let lateNightUTC = Date(timeIntervalSince1970: 1710543600)
    let board = boardForDate(lateNightUTC)

    // Compare against known March 15 seed (20240315)
    let march15Board = Board(seed: 20240315)
    XCTAssertEqual(board.cells, march15Board.cells)

    // Verify it's NOT March 16's board
    let march16Board = Board(seed: 20240316)
    XCTAssertNotEqual(board.cells, march16Board.cells)
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

// Selection bounds
func testSelectionStaysWithinBoardBounds() {
    let gameState = GameState(board: Board(seed: 12345))
    gameState.moveSelection(.up) // Already at row 0
    XCTAssertEqual(gameState.selectedRow, 0) // Should not go negative

    for _ in 0..<10 { gameState.moveSelection(.down) }
    XCTAssertEqual(gameState.selectedRow, 7) // Should not exceed 7
}

// Timer behavior
func testTimerStartsOnFirstReveal() {
    let gameState = GameState(board: Board(seed: 12345))
    XCTAssertEqual(gameState.status, .notStarted)
    XCTAssertEqual(gameState.elapsedTime, 0)

    gameState.reveal(row: 0, col: 0)
    XCTAssertEqual(gameState.status, .playing)
    // Timer now running
}

// Win detection after cascade
func testWinDetectedAfterCascadeRevealsLastCells() {
    // Set up board where one reveal cascades to win
    // Verify status becomes .won after cascade completes
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
| RNG | GKLinearCongruentialRandomSource (used directly in Board) | Built-in, seedable, deterministic; no wrapper class needed |
| Daily board | Free functions, not a class | No state = no class; simpler for beginners |
| Window style | .window (not .menu) | Allows rich custom UI |
| Daily seed timezone | UTC | Same puzzle globally at same moment |
| Daily board identity | Pre-click (initial mine layout) | First-click safety may relocate a mine, so post-click boards can vary by starting cell. Standard Minesweeper behavior. |
| Mine state | Computed at render, not stored | `hasMine` is source of truth; no `.mine`/`.exploded` in CellState to prevent sync bugs |
| Timer start | On first click | Standard Minesweeper; no penalty for reading the board |
| Timer on popover close | Pause | Casual-friendly; no penalty for distractions |
| Timer implementation | `Timer.scheduledTimer` | Simple, beginner-friendly, no Combine needed |
| Selection state | In GameState, not View | Allows App-level keyboard monitor to access it |
| Protocols | None (concrete types) | Simpler for small project; test GameState directly |
