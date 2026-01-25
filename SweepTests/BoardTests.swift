import XCTest
@testable import Sweep

final class BoardTests: XCTestCase {

    // MARK: - Story 3A: Seeded Mine Placement

    func testSameSeedProducesSameBoard() {
        let board1 = Board(seed: 20240315)
        let board2 = Board(seed: 20240315)

        XCTAssertEqual(board1.cells, board2.cells)
    }

    func testDifferentSeedsProduceDifferentBoards() {
        let board1 = Board(seed: 20240315)
        let board2 = Board(seed: 20240316)

        XCTAssertNotEqual(board1.cells, board2.cells)
    }

    func testBoardHasExactlyTenMines() {
        let board = Board(seed: 12345)

        var mineCount = 0
        for row in board.cells {
            for cell in row where cell.hasMine {
                mineCount += 1
            }
        }

        XCTAssertEqual(mineCount, 10)
    }

    func testAllCellsStartHidden() {
        let board = Board(seed: 12345)

        for row in board.cells {
            for cell in row {
                XCTAssertEqual(cell.state, .hidden)
            }
        }
    }

    func testBoardHasCorrectDimensions() {
        let board = Board(seed: 12345)

        XCTAssertEqual(board.cells.count, 8)
        for row in board.cells {
            XCTAssertEqual(row.count, 8)
        }
    }

    func testDeterministicMinePositions() {
        // Create two boards with the same seed and verify mine positions match
        let board1 = Board(seed: 99999)
        let board2 = Board(seed: 99999)

        for row in 0..<8 {
            for col in 0..<8 {
                XCTAssertEqual(
                    board1.cells[row][col].hasMine,
                    board2.cells[row][col].hasMine,
                    "Mine mismatch at (\(row), \(col))"
                )
            }
        }
    }

    func testMultipleSeedsAllHaveTenMines() {
        let seeds: [Int64] = [1, 100, 20240101, 20241231, 99999999]

        for seed in seeds {
            let board = Board(seed: seed)
            var mineCount = 0
            for row in board.cells {
                for cell in row where cell.hasMine {
                    mineCount += 1
                }
            }
            XCTAssertEqual(mineCount, 10, "Board with seed \(seed) should have exactly 10 mines")
        }
    }

    func testNoCellsStartExploded() {
        let board = Board(seed: 12345)

        for row in board.cells {
            for cell in row {
                XCTAssertFalse(cell.isExploded)
            }
        }
    }
}
