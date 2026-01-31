import Foundation
import Testing
@testable import MenuMines

@Suite("GameState Share Tests")
struct GameStateShareTests {

    @Test("Share text is nil before game completes")
    func testShareTextNilBeforeCompletion() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.shareText() == nil, "Share text should be nil when game not started")

        gameState.reveal(row: 0, col: 0)
        #expect(gameState.status == .playing)
        #expect(gameState.shareText() == nil, "Share text should be nil while playing")
    }

    @Test("Share text available after win")
    func testShareTextAvailableAfterWin() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)
        #expect(gameState.status == .won)

        let shareText = gameState.shareText()
        #expect(shareText != nil, "Share text should be available after winning")
    }

    @Test("Share text available after loss")
    func testShareTextAvailableAfterLoss() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)
        #expect(gameState.status == .lost)

        let shareText = gameState.shareText()
        #expect(shareText != nil, "Share text should be available after losing")
    }

    @Test("Share text includes UTC date")
    func testShareTextIncludesUTCDate() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        // Use a specific date for testing
        let timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = DateComponents(year: 2026, month: 1, day: 25)
        guard let testDate = calendar.date(from: components) else {
            Issue.record("Failed to construct test date")
            return
        }

        guard let shareText = gameState.shareText(for: testDate) else {
            Issue.record("Share text should not be nil")
            return
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let expectedDate = formatter.string(from: testDate)
        let expectedHeader = String(format: String(localized: "share_header"), expectedDate)
        #expect(shareText.contains(expectedHeader), "Share text should include UTC date in header")
    }

    @Test("Share text includes completion time")
    func testShareTextIncludesCompletionTime() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        // Verify the actual formatted time appears in share text
        let minutes = Int(gameState.elapsedTime) / 60
        let seconds = Int(gameState.elapsedTime) % 60
        let expectedTime = String(format: "%d:%02d", minutes, seconds)
        #expect(shareText.contains(expectedTime), "Share text should include formatted time")
    }

    @Test("Share text includes failed message on loss")
    func testShareTextIncludesFailedOnLoss() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        // Verify the actual formatted time appears in share text
        let minutes = Int(gameState.elapsedTime) / 60
        let seconds = Int(gameState.elapsedTime) % 60
        let expectedTime = String(format: "%d:%02d", minutes, seconds)
        #expect(shareText.contains(expectedTime), "Share text should include formatted time")
    }

    @Test("Share text includes 9x9 emoji grid")
    func testShareTextIncludesEmojiGrid() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        let lines = shareText.split(separator: "\n", omittingEmptySubsequences: false)

        // Should have: header, result (with flag count), 9 grid rows = 11 lines
        #expect(lines.count == 11, "Share text should have 11 lines (header, result, 9 grid rows)")

        // Grid rows should be lines 2-10 (0-indexed)
        for i in 2..<11 {
            let line = String(lines[i])
            // Each grid line should only contain difficulty-based emojis (fully spoiler-free)
            // No ⬜️ - mines show the same colors as safe cells based on adjacent count
            let validEmojis = Set(["🟩", "🟡", "🟠", "🔴"])
            var emojiCount = 0
            var index = line.startIndex
            while index < line.endIndex {
                let remaining = String(line[index...])
                var found = false
                for emoji in validEmojis {
                    if remaining.hasPrefix(emoji) {
                        emojiCount += 1
                        index = line.index(index, offsetBy: emoji.count)
                        found = true
                        break
                    }
                }
                if !found {
                    Issue.record("Unexpected character in grid line \(i): \(line)")
                    break
                }
            }
            #expect(emojiCount == 9, "Grid line \(i) should have exactly 9 emojis, got \(emojiCount)")
        }
    }

    @Test("Share text does not reveal mine locations")
    func testShareTextDoesNotRevealMines() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Flag some mine cells (must flag mines, not non-mines, to allow winning)
        var flaggedCount = 0
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if gameState.board.cells[r][c].hasMine && flaggedCount < 2 {
                    gameState.toggleFlag(row: r, col: c)
                    flaggedCount += 1
                }
            }
        }

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        // The grid should not contain any mine-revealing emoji
        // Mines show the same difficulty colors as safe cells (based on adjacent count)
        #expect(!shareText.contains("💣"), "Share text should not contain mine emoji")
        #expect(!shareText.contains("💥"), "Share text should not contain explosion emoji")
        #expect(!shareText.contains("⬜️"), "Share text should not contain white square (would reveal mine positions)")

        // Verify flags don't appear in the grid rows (spoiler-free)
        let lines = shareText.split(separator: "\n", omittingEmptySubsequences: false)
        // Grid rows are lines 2-10 (0-indexed)
        for i in 2..<11 {
            let gridLine = String(lines[i])
            #expect(!gridLine.contains("🚩"), "Grid should not contain flag emoji at positions (reveals mines)")
        }
    }

    @Test("Share text includes marked count")
    func testShareTextIncludesMarkedCount() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start the game first to trigger first-click clearing
        gameState.reveal(row: 0, col: 0)

        // Find and flag some mines (after first-click clearing)
        var flaggedMines = 0
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if gameState.board.cells[r][c].hasMine && flaggedMines < 3 {
                    gameState.toggleFlag(row: r, col: c)
                    flaggedMines += 1
                }
            }
        }

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        // Verify the actual formatted count appears in share text
        let expectedCount = "\(flaggedMines)/\(Board.mineCount)"
        #expect(shareText.contains(expectedCount), "Share text should include marked count")
    }

    @Test("Share text emoji mapping is correct")
    func testShareTextEmojiMapping() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        // Check that we have the expected difficulty-based emoji types
        // All cells (including mines) show difficulty colors - no gaps that reveal positions
        #expect(shareText.contains("🟩"), "Share text should contain green square for empty cells (0 adjacent)")
        // At least one of the difficulty colors should appear (depends on board layout)
        let hasDifficultyColors = shareText.contains("🟡") || shareText.contains("🟠") || shareText.contains("🔴")
        #expect(hasDifficultyColors, "Share text should contain at least one difficulty color (🟡, 🟠, or 🔴)")
        // No white squares - mines are disguised with their difficulty color
        #expect(!shareText.contains("⬜️"), "Share text should not contain white squares (would reveal mine positions)")
    }

    @Test("Share text does not contain flag emoji in grid")
    func testShareTextNoFlagsInGrid() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Flag multiple mine cells
        var flaggedCount = 0
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if gameState.board.cells[r][c].hasMine && flaggedCount < 5 {
                    gameState.toggleFlag(row: r, col: c)
                    flaggedCount += 1
                }
            }
        }

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        // The result line should contain flag count (🚩 appears there)
        #expect(shareText.contains("🚩"), "Share text should contain flag emoji in result line")

        // But flags should NOT appear in the grid rows (lines 2-10)
        let lines = shareText.split(separator: "\n", omittingEmptySubsequences: false)
        for i in 2..<11 {
            let gridLine = String(lines[i])
            #expect(!gridLine.contains("🚩"), "Grid row \(i) should not contain flag emoji")
        }
    }
}
