import Foundation
import Testing
@testable import Sweep

// MARK: - Shared Test Helpers

/// Helper to run the main RunLoop for a duration, allowing Timer to fire
func runLoopFor(seconds: TimeInterval) {
    let deadline = Date(timeIntervalSinceNow: seconds)
    while Date() < deadline {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
    }
}

/// Helper to find the first safe (non-mine) cell in a board
func findSafeCell(in board: Board) -> (row: Int, col: Int)? {
    for r in 0..<Board.rows {
        for c in 0..<Board.cols {
            if !board.cells[r][c].hasMine {
                return (r, c)
            }
        }
    }
    return nil
}

/// Helper to find the first mine cell in a board
func findMineCell(in board: Board) -> (row: Int, col: Int)? {
    for r in 0..<Board.rows {
        for c in 0..<Board.cols {
            if board.cells[r][c].hasMine {
                return (r, c)
            }
        }
    }
    return nil
}

/// Helper to win the game by revealing all non-mine cells
func winGame(_ gameState: GameState) {
    for r in 0..<Board.rows {
        for c in 0..<Board.cols {
            if !gameState.board.cells[r][c].hasMine {
                gameState.reveal(row: r, col: c)
            }
        }
    }
}

/// Helper to verify all cells are hidden
func expectAllCellsHidden(in gameState: GameState) {
    for r in 0..<Board.rows {
        for c in 0..<Board.cols {
            #expect(gameState.board.cells[r][c].state == .hidden)
        }
    }
}

/// Helper to find the first hidden cell in a game state
func findHiddenCell(in gameState: GameState) -> (row: Int, col: Int)? {
    for r in 0..<Board.rows {
        for c in 0..<Board.cols {
            if case .hidden = gameState.board.cells[r][c].state {
                return (r, c)
            }
        }
    }
    return nil
}
