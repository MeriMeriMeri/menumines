import Foundation
import Testing
@testable import MenuMines

@Suite("GameState Win/Lose Tests")
struct GameStateWinLoseTests {

    @Test("Lose when clicking a mine")
    func testLoseWhenClickingMine() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)
        #expect(gameState.status == .playing)

        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)

        #expect(gameState.status == .lost)
        #expect(gameState.board.cells[mine.row][mine.col].isExploded)
    }

    @Test("Win when all non-mine cells are revealed")
    func testWinWhenAllNonMinesRevealed() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        #expect(gameState.status == .won)
    }

    @Test("First click never hits a mine")
    func testFirstClickNeverHitsMine() {
        // Use a seed where we know position (0,0) has a mine
        // Try multiple seeds to find one where (0,0) has a mine
        var testSeed: Int64 = 1
        var foundSeed = false

        for seed in 1...1000 {
            let testBoard = Board(seed: Int64(seed))
            if testBoard.cells[0][0].hasMine {
                testSeed = Int64(seed)
                foundSeed = true
                break
            }
        }

        guard foundSeed else {
            Issue.record("Could not find a seed where (0,0) has a mine")
            return
        }

        // Now test that first click on (0,0) doesn't lose
        let board = Board(seed: testSeed)
        let gameState = GameState(board: board)

        // Verify the board originally has a mine at (0,0)
        #expect(board.cells[0][0].hasMine)

        // First click should not result in loss
        gameState.reveal(row: 0, col: 0)

        #expect(gameState.status == .playing, "First click should never lose, mine should be relocated")
        #expect(!gameState.board.cells[0][0].hasMine, "Mine should have been relocated from first click position")
    }

    @Test("First click relocates mine and preserves mine count")
    func testFirstClickRelocatesMinePreservesMineCount() {
        // Find a seed where (0,0) has a mine
        var testSeed: Int64 = 1
        for seed in 1...1000 {
            let testBoard = Board(seed: Int64(seed))
            if testBoard.cells[0][0].hasMine {
                testSeed = Int64(seed)
                break
            }
        }

        let board = Board(seed: testSeed)
        let gameState = GameState(board: board)

        // First click on (0,0) which has a mine
        gameState.reveal(row: 0, col: 0)

        // Count mines after first click
        var mineCount = 0
        for r in 0..<8 {
            for c in 0..<8 {
                if gameState.board.cells[r][c].hasMine {
                    mineCount += 1
                }
            }
        }

        #expect(mineCount == 10, "Mine count should remain 10 after first-click relocation")
    }

    @Test("Cannot reveal after game is lost")
    func testCannotRevealAfterGameLost() {
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

        guard let hidden = findHiddenCell(in: gameState) else {
            Issue.record("No hidden cell found")
            return
        }

        gameState.reveal(row: hidden.row, col: hidden.col)
        #expect(gameState.board.cells[hidden.row][hidden.col].state == .hidden, "Should not be able to reveal after losing")
    }

    @Test("Cannot reveal after game is won")
    func testCannotRevealAfterGameWon() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)
        #expect(gameState.status == .won)

        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }

        gameState.reveal(row: mine.row, col: mine.col)
        #expect(gameState.status == .won, "Status should still be won")
    }
}
