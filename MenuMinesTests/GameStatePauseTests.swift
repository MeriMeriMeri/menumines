import Foundation
import Testing
@testable import MenuMines

@Suite("GameState Pause Tests")
struct GameStatePauseTests {

    @Test("isPaused is initially false")
    func testIsPausedInitiallyFalse() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.isPaused == false)
    }

    @Test("isPaused is true after pauseTimer while playing")
    @MainActor
    func testIsPausedTrueAfterPauseWhilePlaying() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.reveal(row: 0, col: 0)
        #expect(gameState.status == .playing)

        gameState.pauseTimer()

        #expect(gameState.isPaused == true)
    }

    @Test("isPaused is false after resumeTimer")
    @MainActor
    func testIsPausedFalseAfterResume() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.reveal(row: 0, col: 0)
        gameState.pauseTimer()
        #expect(gameState.isPaused == true)

        gameState.resumeTimer()

        #expect(gameState.isPaused == false)
    }

    @Test("isPaused remains false when pausing before game starts")
    func testIsPausedFalseWhenPausingBeforeGameStarts() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.status == .notStarted)
        gameState.pauseTimer()

        #expect(gameState.isPaused == false)
    }

    @Test("isPaused is false after game is won")
    @MainActor
    func testIsPausedFalseAfterWin() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        #expect(gameState.status == .won)
        #expect(gameState.isPaused == false)
    }

    @Test("isPaused is false after game is lost")
    @MainActor
    func testIsPausedFalseAfterLoss() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine cell found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)

        #expect(gameState.status == .lost)
        #expect(gameState.isPaused == false)
    }
}
