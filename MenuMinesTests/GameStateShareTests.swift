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

        // Should have: header, result, 9 grid rows, marked count = 12 lines
        #expect(lines.count == 12, "Share text should have 12 lines (header, result, 9 grid rows, marked)")

        // Grid rows should be lines 2-10 (0-indexed)
        for i in 2..<11 {
            let line = String(lines[i])
            // Each grid line should only contain the three emoji types
            let validEmojis = Set(["🟩", "🚩", "⬛️"])
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

        // The grid should not contain any mine-specific emoji
        // Mines should appear as either 🟩 (if revealed, but that means loss) or 🚩 (flagged) or ⬛️ (hidden)
        // The grid should NOT have a special "mine" emoji that reveals locations
        #expect(!shareText.contains("💣"), "Share text should not contain mine emoji")
        #expect(!shareText.contains("💥"), "Share text should not contain explosion emoji")
    }

    @Test("Share text includes marked count")
    func testShareTextIncludesMarkedCount() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Find and flag some mines
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

        // Flag one mine cell (must flag a mine, not a non-mine, to allow winning)
        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine cell found")
            return
        }
        gameState.toggleFlag(row: mine.row, col: mine.col)

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        // Check that we have the expected emoji types
        #expect(shareText.contains("🟩"), "Share text should contain green square for revealed cells")
        #expect(shareText.contains("🚩"), "Share text should contain flag for flagged cells")
        // Hidden cells (⬛️) will exist for unflagged mines after winning
    }
}
