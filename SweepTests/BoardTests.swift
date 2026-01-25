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

    func testEdgeCaseSeeds() {
        let extremeSeeds: [Int64] = [Int64.min, -1, 0, Int64.max]

        for seed in extremeSeeds {
            let board = Board(seed: seed)
            let mineCount = board.cells.flatMap { $0 }.filter(\.hasMine).count
            XCTAssertEqual(mineCount, 10, "Seed \(seed) should produce exactly 10 mines")
        }
    }
}
