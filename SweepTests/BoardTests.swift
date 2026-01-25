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

    // MARK: - Story 4A: Reveal Logic with Cascade

    func testRevealCellWithMineReturnsMine() {
        var board = Board(seed: 12345)

        // Find a cell with a mine
        var mineRow = 0, mineCol = 0
        outer: for r in 0..<8 {
            for c in 0..<8 {
                if board.cells[r][c].hasMine {
                    mineRow = r
                    mineCol = c
                    break outer
                }
            }
        }

        let result = board.reveal(row: mineRow, col: mineCol)
        XCTAssertEqual(result, .mine)
    }

    func testRevealCellWithAdjacentMinesRevealsOneCell() {
        var board = Board(seed: 12345)

        // Find a cell next to a mine (has adjacent mines > 0) but isn't a mine
        var targetRow = -1, targetCol = -1
        outer: for r in 0..<8 {
            for c in 0..<8 {
                if !board.cells[r][c].hasMine {
                    let adjacent = board.adjacentMineCount(row: r, col: c)
                    if adjacent > 0 {
                        targetRow = r
                        targetCol = c
                        break outer
                    }
                }
            }
        }

        guard targetRow >= 0 else {
            XCTFail("Could not find a cell with adjacent mines")
            return
        }

        let result = board.reveal(row: targetRow, col: targetCol)

        if case .safe(let count) = result {
            XCTAssertEqual(count, 1, "Revealing cell with adjacent mines should reveal exactly 1 cell")
        } else {
            XCTFail("Expected .safe result")
        }

        if case .revealed(let adj) = board.cells[targetRow][targetCol].state {
            XCTAssertGreaterThan(adj, 0)
        } else {
            XCTFail("Cell should be revealed")
        }
    }

    func testRevealCellWithZeroAdjacentMinesCascades() {
        var board = Board(seed: 12345)

        // Find a cell with 0 adjacent mines
        var targetRow = -1, targetCol = -1
        outer: for r in 0..<8 {
            for c in 0..<8 {
                if !board.cells[r][c].hasMine {
                    let adjacent = board.adjacentMineCount(row: r, col: c)
                    if adjacent == 0 {
                        targetRow = r
                        targetCol = c
                        break outer
                    }
                }
            }
        }

        guard targetRow >= 0 else {
            XCTFail("Could not find a cell with zero adjacent mines")
            return
        }

        let result = board.reveal(row: targetRow, col: targetCol)

        if case .safe(let count) = result {
            XCTAssertGreaterThan(count, 1, "Revealing cell with 0 adjacent mines should cascade")
        } else {
            XCTFail("Expected .safe result")
        }
    }

    func testRevealAlreadyRevealedCellReturnsZero() {
        var board = Board(seed: 12345)

        // Find a non-mine cell
        var targetRow = 0, targetCol = 0
        outer: for r in 0..<8 {
            for c in 0..<8 {
                if !board.cells[r][c].hasMine {
                    targetRow = r
                    targetCol = c
                    break outer
                }
            }
        }

        _ = board.reveal(row: targetRow, col: targetCol)
        let secondResult = board.reveal(row: targetRow, col: targetCol)

        XCTAssertEqual(secondResult, .safe(cellsRevealed: 0))
    }

    func testRevealFlaggedCellReturnsZero() {
        var board = Board(seed: 12345)

        // Find a non-mine cell
        var targetRow = 0, targetCol = 0
        outer: for r in 0..<8 {
            for c in 0..<8 {
                if !board.cells[r][c].hasMine {
                    targetRow = r
                    targetCol = c
                    break outer
                }
            }
        }

        board.toggleFlag(row: targetRow, col: targetCol)
        let result = board.reveal(row: targetRow, col: targetCol)

        XCTAssertEqual(result, .safe(cellsRevealed: 0))
    }

    func testRevealOutOfBoundsReturnsZero() {
        var board = Board(seed: 12345)

        XCTAssertEqual(board.reveal(row: -1, col: 0), .safe(cellsRevealed: 0))
        XCTAssertEqual(board.reveal(row: 0, col: -1), .safe(cellsRevealed: 0))
        XCTAssertEqual(board.reveal(row: 8, col: 0), .safe(cellsRevealed: 0))
        XCTAssertEqual(board.reveal(row: 0, col: 8), .safe(cellsRevealed: 0))
    }

    func testAdjacentMineCountAtCorner() {
        let board = Board(seed: 12345)

        // Corner cells have at most 3 neighbors
        let count = board.adjacentMineCount(row: 0, col: 0)
        XCTAssertLessThanOrEqual(count, 3)
    }

    func testAdjacentMineCountAtEdge() {
        let board = Board(seed: 12345)

        // Edge cells have at most 5 neighbors
        let count = board.adjacentMineCount(row: 0, col: 4)
        XCTAssertLessThanOrEqual(count, 5)
    }

    func testAdjacentMineCountAtCenter() {
        let board = Board(seed: 12345)

        // Center cells have at most 8 neighbors
        let count = board.adjacentMineCount(row: 4, col: 4)
        XCTAssertLessThanOrEqual(count, 8)
    }

    func testCascadeDoesNotRevealMines() {
        var board = Board(seed: 12345)

        // Reveal all non-mine cells with cascade
        for r in 0..<8 {
            for c in 0..<8 {
                if !board.cells[r][c].hasMine {
                    _ = board.reveal(row: r, col: c)
                }
            }
        }

        // Verify no mine cells were revealed by cascade
        for r in 0..<8 {
            for c in 0..<8 {
                if board.cells[r][c].hasMine {
                    XCTAssertEqual(board.cells[r][c].state, .hidden, "Mine at (\(r),\(c)) should remain hidden")
                }
            }
        }
    }
}
