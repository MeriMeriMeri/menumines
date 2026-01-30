import XCTest
@testable import MenuMines

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

        XCTAssertEqual(board.cells.count, 9)
        for row in board.cells {
            XCTAssertEqual(row.count, 9)
        }
    }

    func testMultipleSeedsAllHaveFifteenMines() {
        let seeds: [Int64] = [1, 100, 20240101, 20241231, 99999999]

        for seed in seeds {
            let board = Board(seed: seed)
            var mineCount = 0
            for row in board.cells {
                for cell in row where cell.hasMine {
                    mineCount += 1
                }
            }
            XCTAssertEqual(mineCount, 15, "Board with seed \(seed) should have exactly 15 mines")
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
            XCTAssertEqual(mineCount, 15, "Seed \(seed) should produce exactly 15 mines")
        }
    }

    // MARK: - Story 4A: Reveal Logic with Cascade

    func testRevealCellWithMineReturnsMine() {
        var board = Board(seed: 12345)

        // Find a cell with a mine
        var mineRow = 0, mineCol = 0
        outer: for r in 0..<9 {
            for c in 0..<9 {
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
        outer: for r in 0..<9 {
            for c in 0..<9 {
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
        outer: for r in 0..<9 {
            for c in 0..<9 {
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
        outer: for r in 0..<9 {
            for c in 0..<9 {
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
        outer: for r in 0..<9 {
            for c in 0..<9 {
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
        XCTAssertEqual(board.reveal(row: 9, col: 0), .safe(cellsRevealed: 0))
        XCTAssertEqual(board.reveal(row: 0, col: 9), .safe(cellsRevealed: 0))
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
        for r in 0..<9 {
            for c in 0..<9 {
                if !board.cells[r][c].hasMine {
                    _ = board.reveal(row: r, col: c)
                }
            }
        }

        // Verify no mine cells were revealed by cascade
        for r in 0..<9 {
            for c in 0..<9 {
                if board.cells[r][c].hasMine {
                    XCTAssertEqual(board.cells[r][c].state, .hidden, "Mine at (\(r),\(c)) should remain hidden")
                }
            }
        }
    }

    // MARK: - Story 5A: Win/Lose Detection and First-Click Safety

    func testRelocateMineRemovesMineFromOriginalCell() {
        var board = Board(seed: 12345)

        // Find a cell with a mine
        var mineRow = -1, mineCol = -1
        outer: for r in 0..<9 {
            for c in 0..<9 {
                if board.cells[r][c].hasMine {
                    mineRow = r
                    mineCol = c
                    break outer
                }
            }
        }

        guard mineRow >= 0 else {
            XCTFail("No mine found")
            return
        }

        XCTAssertTrue(board.cells[mineRow][mineCol].hasMine)

        board.relocateMine(from: mineRow, col: mineCol)

        XCTAssertFalse(board.cells[mineRow][mineCol].hasMine, "Mine should be removed from original cell")
    }

    func testRelocateMinePreservesTotalMineCount() {
        var board = Board(seed: 12345)

        // Find a cell with a mine
        var mineRow = -1, mineCol = -1
        outer: for r in 0..<9 {
            for c in 0..<9 {
                if board.cells[r][c].hasMine {
                    mineRow = r
                    mineCol = c
                    break outer
                }
            }
        }

        guard mineRow >= 0 else {
            XCTFail("No mine found")
            return
        }

        let mineCountBefore = board.cells.flatMap { $0 }.filter(\.hasMine).count
        XCTAssertEqual(mineCountBefore, 15)

        board.relocateMine(from: mineRow, col: mineCol)

        let mineCountAfter = board.cells.flatMap { $0 }.filter(\.hasMine).count
        XCTAssertEqual(mineCountAfter, 15, "Mine count should stay at 15 after relocation")
    }

    func testRelocateMineMovesToDifferentCell() {
        var board = Board(seed: 12345)

        // Find a cell with a mine
        var mineRow = -1, mineCol = -1
        outer: for r in 0..<9 {
            for c in 0..<9 {
                if board.cells[r][c].hasMine {
                    mineRow = r
                    mineCol = c
                    break outer
                }
            }
        }

        guard mineRow >= 0 else {
            XCTFail("No mine found")
            return
        }

        // Get positions of mines before relocation
        var minePositionsBefore = Set<Int>()
        for r in 0..<9 {
            for c in 0..<9 {
                if board.cells[r][c].hasMine {
                    minePositionsBefore.insert(r * 9 + c)
                }
            }
        }

        board.relocateMine(from: mineRow, col: mineCol)

        // Get positions of mines after relocation
        var minePositionsAfter = Set<Int>()
        for r in 0..<9 {
            for c in 0..<9 {
                if board.cells[r][c].hasMine {
                    minePositionsAfter.insert(r * 9 + c)
                }
            }
        }

        // The original position should no longer have a mine
        XCTAssertFalse(minePositionsAfter.contains(mineRow * 8 + mineCol))

        // A new position should have a mine
        let newMines = minePositionsAfter.subtracting(minePositionsBefore)
        XCTAssertEqual(newMines.count, 1, "Exactly one new mine position should exist")
    }

    func testRelocateMineDoesNothingIfCellHasNoMine() {
        var board = Board(seed: 12345)

        // Find a cell without a mine
        var emptyRow = -1, emptyCol = -1
        outer: for r in 0..<9 {
            for c in 0..<9 {
                if !board.cells[r][c].hasMine {
                    emptyRow = r
                    emptyCol = c
                    break outer
                }
            }
        }

        guard emptyRow >= 0 else {
            XCTFail("No empty cell found")
            return
        }

        let mineCountBefore = board.cells.flatMap { $0 }.filter(\.hasMine).count
        board.relocateMine(from: emptyRow, col: emptyCol)
        let mineCountAfter = board.cells.flatMap { $0 }.filter(\.hasMine).count

        XCTAssertEqual(mineCountBefore, mineCountAfter, "Mine count should not change when relocating from non-mine cell")
    }

    func testMarkExplodedSetsIsExplodedTrue() {
        var board = Board(seed: 12345)

        // Find a cell with a mine
        var mineRow = -1, mineCol = -1
        outer: for r in 0..<9 {
            for c in 0..<9 {
                if board.cells[r][c].hasMine {
                    mineRow = r
                    mineCol = c
                    break outer
                }
            }
        }

        guard mineRow >= 0 else {
            XCTFail("No mine found")
            return
        }

        XCTAssertFalse(board.cells[mineRow][mineCol].isExploded)

        board.markExploded(row: mineRow, col: mineCol)

        XCTAssertTrue(board.cells[mineRow][mineCol].isExploded, "Cell should be marked as exploded")
    }

    func testMarkExplodedOutOfBoundsDoesNothing() {
        var board = Board(seed: 12345)

        // These should not crash
        board.markExploded(row: -1, col: 0)
        board.markExploded(row: 0, col: -1)
        board.markExploded(row: 9, col: 0)
        board.markExploded(row: 0, col: 9)

        // Verify no cells are exploded
        for r in 0..<9 {
            for c in 0..<9 {
                XCTAssertFalse(board.cells[r][c].isExploded)
            }
        }
    }

    // MARK: - Story 27: Chord Reveal

    func testAdjacentFlagCountWithNoFlags() {
        let board = Board(seed: 12345)

        // No flags placed, count should be 0
        let count = board.adjacentFlagCount(row: 4, col: 4)
        XCTAssertEqual(count, 0)
    }

    func testAdjacentFlagCountWithOneFlag() {
        var board = Board(seed: 12345)

        board.toggleFlag(row: 3, col: 3)
        let count = board.adjacentFlagCount(row: 4, col: 4)

        XCTAssertEqual(count, 1)
    }

    func testAdjacentFlagCountWithMultipleFlags() {
        var board = Board(seed: 12345)

        board.toggleFlag(row: 3, col: 3)
        board.toggleFlag(row: 3, col: 4)
        board.toggleFlag(row: 4, col: 3)
        let count = board.adjacentFlagCount(row: 4, col: 4)

        XCTAssertEqual(count, 3)
    }

    func testAdjacentFlagCountIgnoresNonAdjacentFlags() {
        var board = Board(seed: 12345)

        board.toggleFlag(row: 0, col: 0)
        let count = board.adjacentFlagCount(row: 4, col: 4)

        XCTAssertEqual(count, 0)
    }

    func testAdjacentFlagCountAtCorner() {
        var board = Board(seed: 12345)

        board.toggleFlag(row: 0, col: 1)
        board.toggleFlag(row: 1, col: 0)
        board.toggleFlag(row: 1, col: 1)
        let count = board.adjacentFlagCount(row: 0, col: 0)

        XCTAssertEqual(count, 3)
    }

    func testChordRevealOnHiddenCellReturnsZero() {
        var board = Board(seed: 12345)

        let result = board.chordReveal(row: 0, col: 0)
        XCTAssertEqual(result, .safe(cellsRevealed: 0))
    }

    func testChordRevealOnRevealedZeroCellReturnsZero() {
        var board = Board(seed: 12345)

        // Find a cell with 0 adjacent mines and reveal it
        var targetRow = -1, targetCol = -1
        outer: for r in 0..<9 {
            for c in 0..<9 {
                if !board.cells[r][c].hasMine && board.adjacentMineCount(row: r, col: c) == 0 {
                    targetRow = r
                    targetCol = c
                    break outer
                }
            }
        }

        guard targetRow >= 0 else {
            XCTFail("No zero-adjacent cell found")
            return
        }

        _ = board.reveal(row: targetRow, col: targetCol)

        let result = board.chordReveal(row: targetRow, col: targetCol)
        XCTAssertEqual(result, .safe(cellsRevealed: 0))
    }

    func testChordRevealWhenFlagsDoNotMatchReturnsZero() {
        var board = Board(seed: 12345)

        // Find a cell with adjacent mines > 0
        var targetRow = -1, targetCol = -1
        outer: for r in 0..<9 {
            for c in 0..<9 {
                if !board.cells[r][c].hasMine {
                    let adj = board.adjacentMineCount(row: r, col: c)
                    if adj > 0 {
                        targetRow = r
                        targetCol = c
                        break outer
                    }
                }
            }
        }

        guard targetRow >= 0 else {
            XCTFail("No cell with adjacent mines found")
            return
        }

        _ = board.reveal(row: targetRow, col: targetCol)
        // Don't place any flags - flags (0) won't match adjMines (>0)

        let result = board.chordReveal(row: targetRow, col: targetCol)
        XCTAssertEqual(result, .safe(cellsRevealed: 0), "Chord reveal should do nothing when flag count doesn't match")
    }

    func testChordRevealRevealsUnflaggedAdjacentCells() {
        var board = Board(seed: 12345)

        // Find a revealed cell with exactly 1 adjacent mine
        var targetRow = -1, targetCol = -1
        var mineRow = -1, mineCol = -1
        outer: for r in 0..<9 {
            for c in 0..<9 {
                if !board.cells[r][c].hasMine {
                    let adj = board.adjacentMineCount(row: r, col: c)
                    if adj == 1 {
                        // Find the adjacent mine
                        for dr in -1...1 {
                            for dc in -1...1 {
                                if dr == 0 && dc == 0 { continue }
                                let mr = r + dr
                                let mc = c + dc
                                if mr >= 0, mr < 9, mc >= 0, mc < 9 {
                                    if board.cells[mr][mc].hasMine {
                                        targetRow = r
                                        targetCol = c
                                        mineRow = mr
                                        mineCol = mc
                                        break outer
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        guard targetRow >= 0 else {
            XCTFail("No suitable cell found")
            return
        }

        _ = board.reveal(row: targetRow, col: targetCol)
        board.toggleFlag(row: mineRow, col: mineCol)

        let result = board.chordReveal(row: targetRow, col: targetCol)

        if case .safe(let count) = result {
            XCTAssertGreaterThan(count, 0, "Chord reveal should reveal at least one cell")
        } else {
            XCTFail("Expected safe result")
        }
    }

    func testChordRevealReturnsMineIfIncorrectFlag() {
        var board = Board(seed: 12345)

        // Find a revealed cell with exactly 1 adjacent mine
        var targetRow = -1, targetCol = -1
        var wrongFlagRow = -1, wrongFlagCol = -1
        outer: for r in 0..<9 {
            for c in 0..<9 {
                if !board.cells[r][c].hasMine {
                    let adj = board.adjacentMineCount(row: r, col: c)
                    if adj == 1 {
                        // Find a non-mine adjacent cell to place wrong flag
                        for dr in -1...1 {
                            for dc in -1...1 {
                                if dr == 0 && dc == 0 { continue }
                                let nr = r + dr
                                let nc = c + dc
                                if nr >= 0, nr < 9, nc >= 0, nc < 9 {
                                    if !board.cells[nr][nc].hasMine {
                                        targetRow = r
                                        targetCol = c
                                        wrongFlagRow = nr
                                        wrongFlagCol = nc
                                        break outer
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        guard targetRow >= 0, wrongFlagRow >= 0 else {
            XCTFail("No suitable cell found")
            return
        }

        _ = board.reveal(row: targetRow, col: targetCol)
        board.toggleFlag(row: wrongFlagRow, col: wrongFlagCol)

        let result = board.chordReveal(row: targetRow, col: targetCol)

        XCTAssertEqual(result, .mine, "Chord reveal should return .mine when flag is incorrectly placed")
    }

    func testChordRevealOutOfBoundsReturnsZero() {
        var board = Board(seed: 12345)

        XCTAssertEqual(board.chordReveal(row: -1, col: 0), .safe(cellsRevealed: 0))
        XCTAssertEqual(board.chordReveal(row: 0, col: -1), .safe(cellsRevealed: 0))
        XCTAssertEqual(board.chordReveal(row: 9, col: 0), .safe(cellsRevealed: 0))
        XCTAssertEqual(board.chordReveal(row: 0, col: 9), .safe(cellsRevealed: 0))
    }

    func testChordRevealCanTriggerCascade() {
        var board = Board(seed: 12345)

        // Find a revealed cell with 1 adjacent mine where an adjacent cell has 0 mines
        var targetRow = -1, targetCol = -1
        var mineRow = -1, mineCol = -1
        var hasZeroNeighbor = false

        outer: for r in 0..<9 {
            for c in 0..<9 {
                if !board.cells[r][c].hasMine {
                    let adj = board.adjacentMineCount(row: r, col: c)
                    if adj == 1 {
                        // Find the mine
                        for dr in -1...1 {
                            for dc in -1...1 {
                                if dr == 0 && dc == 0 { continue }
                                let mr = r + dr
                                let mc = c + dc
                                if mr >= 0, mr < 9, mc >= 0, mc < 9 {
                                    if board.cells[mr][mc].hasMine {
                                        mineRow = mr
                                        mineCol = mc
                                    }
                                }
                            }
                        }

                        // Check if any non-mine neighbor has 0 adjacent mines
                        for dr in -1...1 {
                            for dc in -1...1 {
                                if dr == 0 && dc == 0 { continue }
                                let nr = r + dr
                                let nc = c + dc
                                if nr >= 0, nr < 9, nc >= 0, nc < 9 {
                                    if !board.cells[nr][nc].hasMine {
                                        if board.adjacentMineCount(row: nr, col: nc) == 0 {
                                            hasZeroNeighbor = true
                                            targetRow = r
                                            targetCol = c
                                            break outer
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        guard targetRow >= 0, mineRow >= 0, hasZeroNeighbor else {
            // This test depends on board layout - skip if no suitable configuration
            return
        }

        _ = board.reveal(row: targetRow, col: targetCol)
        board.toggleFlag(row: mineRow, col: mineCol)

        let result = board.chordReveal(row: targetRow, col: targetCol)

        if case .safe(let count) = result {
            // If we have a zero-neighbor, cascade should reveal more than just immediate neighbors
            XCTAssertGreaterThan(count, 1, "Chord reveal with zero-adjacent neighbor should cascade")
        } else {
            XCTFail("Expected safe result")
        }
    }
}
