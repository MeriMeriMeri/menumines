import Foundation

/// The current status of the game.
enum GameStatus: Equatable {
    case notStarted
    case playing
    case won
    case lost
}

/// Direction for keyboard navigation.
enum Direction {
    case up, down, left, right
}

/// Observable game state that owns the board and manages game logic.
@Observable
final class GameState {
    private(set) var board: Board
    private(set) var status: GameStatus = .notStarted
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var flagCount: Int = 0
    private(set) var selectedRow: Int = 0
    private(set) var selectedCol: Int = 0

    private var timer: Timer?

    init(board: Board) {
        self.board = board
    }

    /// Generates a Wordle-style share text for the completed game.
    /// The grid encodes only the revealed/marked/hidden outcome without exposing mine locations.
    /// - Parameter date: The date to use for the header (defaults to current date in UTC).
    /// - Returns: The formatted share text, or nil if the game is not complete.
    func shareText(for date: Date = Date()) -> String? {
        guard status == .won || status == .lost else { return nil }

        var lines: [String] = []

        // Header with UTC date
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let dateString = String(format: "%04d-%02d-%02d", year, month, day)
        lines.append("Sweep — \(dateString)")

        // Result line with formatted time
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let timeString = String(format: "%d:%02d", minutes, seconds)
        if status == .won {
            lines.append(String(format: String(localized: "share_solved"), timeString))
        } else {
            lines.append(String(format: String(localized: "share_failed"), timeString))
        }

        // Emoji grid - encode only visual outcome, not mine locations
        // 🟩 = revealed safe cell
        // 🚩 = flagged cell
        // ⬛️ = unrevealed/hidden cell
        for row in 0..<Board.rows {
            var rowEmojis = ""
            for col in 0..<Board.cols {
                let cell = board.cells[row][col]
                switch cell.state {
                case .revealed:
                    rowEmojis += "🟩"
                case .flagged:
                    rowEmojis += "🚩"
                case .hidden:
                    rowEmojis += "⬛️"
                }
            }
            lines.append(rowEmojis)
        }

        // Marked count
        let markedCorrect = countCorrectlyMarkedMines()
        lines.append(String(format: String(localized: "share_marked"), markedCorrect, Board.mineCount))

        return lines.joined(separator: "\n")
    }

    /// Counts the number of flags placed on actual mines.
    private func countCorrectlyMarkedMines() -> Int {
        var count = 0
        for row in board.cells {
            for cell in row {
                if case .flagged = cell.state, cell.hasMine {
                    count += 1
                }
            }
        }
        return count
    }

    /// Reveals the cell at the given position.
    /// If the cell is already revealed with a number, performs a chord reveal instead.
    func reveal(row: Int, col: Int) {
        guard status == .notStarted || status == .playing else { return }
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else { return }

        if case .revealed(let adjacentMines) = board.cells[row][col].state, adjacentMines > 0 {
            chordReveal(row: row, col: col)
            return
        }

        guard case .hidden = board.cells[row][col].state else { return }

        let isFirstClick = (status == .notStarted)
        if isFirstClick {
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
        case .safe:
            if checkWinCondition() {
                status = .won
                stopTimer()
            }
        }
    }

    /// Toggles the flag on the cell at the given position.
    func toggleFlag(row: Int, col: Int) {
        guard status == .notStarted || status == .playing else { return }
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else { return }

        let previousState = board.cells[row][col].state
        board.toggleFlag(row: row, col: col)
        let newState = board.cells[row][col].state

        // Update flag count
        if case .flagged = newState {
            flagCount += 1
        } else if case .flagged = previousState {
            flagCount -= 1
        }
    }

    /// Resets the game to a fresh state with today's daily board.
    func reset() {
        stopTimer()
        board = dailyBoard()
        status = .notStarted
        elapsedTime = 0
        flagCount = 0
        selectedRow = 0
        selectedCol = 0
    }

    /// Pauses the timer (e.g., when popover closes).
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Resumes the timer (e.g., when popover reopens).
    func resumeTimer() {
        guard status == .playing else { return }
        startTimer()
    }

    /// Moves the keyboard selection in the given direction.
    func moveSelection(_ direction: Direction) {
        switch direction {
        case .up:
            selectedRow = max(0, selectedRow - 1)
        case .down:
            selectedRow = min(Board.rows - 1, selectedRow + 1)
        case .left:
            selectedCol = max(0, selectedCol - 1)
        case .right:
            selectedCol = min(Board.cols - 1, selectedCol + 1)
        }
    }

    /// Reveals the currently selected cell.
    func revealSelected() {
        reveal(row: selectedRow, col: selectedCol)
    }

    /// Toggles the flag on the currently selected cell.
    func toggleFlagSelected() {
        toggleFlag(row: selectedRow, col: selectedCol)
    }

    /// Performs a chord reveal on the cell at the given position.
    func chordReveal(row: Int, col: Int) {
        guard status == .playing else { return }
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else { return }

        switch board.chordReveal(row: row, col: col) {
        case .mine:
            status = .lost
            stopTimer()
        case .safe:
            if checkWinCondition() {
                status = .won
                stopTimer()
            }
        }
    }

    /// Performs a chord reveal on the currently selected cell.
    func chordRevealSelected() {
        chordReveal(row: selectedRow, col: selectedCol)
    }

    // MARK: - Private

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func checkWinCondition() -> Bool {
        for row in board.cells {
            for cell in row where !cell.hasMine {
                guard case .revealed = cell.state else {
                    return false
                }
            }
        }
        return true
    }
}
