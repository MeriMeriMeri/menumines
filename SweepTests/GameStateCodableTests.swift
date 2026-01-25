import Foundation
import Testing
@testable import Sweep

@Suite("GameState Codable Tests")
struct GameStateCodableTests {

    @Test("CellState hidden round-trips through Codable")
    func testCellStateHiddenCodable() throws {
        let original = CellState.hidden
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CellState.self, from: data)
        #expect(decoded == original)
    }

    @Test("CellState revealed round-trips through Codable")
    func testCellStateRevealedCodable() throws {
        let original = CellState.revealed(adjacentMines: 3)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CellState.self, from: data)
        #expect(decoded == original)
    }

    @Test("CellState flagged round-trips through Codable")
    func testCellStateFlaggedCodable() throws {
        let original = CellState.flagged
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CellState.self, from: data)
        #expect(decoded == original)
    }

    @Test("Cell round-trips through Codable")
    func testCellCodable() throws {
        let original = Cell(state: .revealed(adjacentMines: 2), hasMine: false, isExploded: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded == original)
    }

    @Test("Cell with mine round-trips through Codable")
    func testCellWithMineCodable() throws {
        let original = Cell(state: .hidden, hasMine: true, isExploded: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded == original)
    }

    @Test("Cell with exploded mine round-trips through Codable")
    func testCellExplodedCodable() throws {
        let original = Cell(state: .revealed(adjacentMines: 0), hasMine: true, isExploded: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded == original)
    }

    @Test("Board round-trips through Codable")
    func testBoardCodable() throws {
        let original = Board(seed: 12345)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Board.self, from: data)
        #expect(decoded == original)
    }

    @Test("Board with modified cells round-trips through Codable")
    func testBoardModifiedCodable() throws {
        var original = Board(seed: 12345)
        _ = original.reveal(row: 0, col: 0)
        original.toggleFlag(row: 1, col: 1)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Board.self, from: data)
        #expect(decoded == original)
    }

    @Test("GameStatus round-trips through Codable")
    func testGameStatusCodable() throws {
        for status in [GameStatus.notStarted, .playing, .won, .lost] {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(GameStatus.self, from: data)
            #expect(decoded == status)
        }
    }

    @Test("GameSnapshot round-trips through Codable")
    func testGameSnapshotCodable() throws {
        let board = Board(seed: 12345)
        let snapshot = GameSnapshot(
            board: board,
            status: .playing,
            elapsedTime: 42.0,
            flagCount: 3,
            selectedRow: 2,
            selectedCol: 5,
            dailySeed: 20260125
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: data)

        #expect(decoded.board == snapshot.board)
        #expect(decoded.status == snapshot.status)
        #expect(decoded.elapsedTime == snapshot.elapsedTime)
        #expect(decoded.flagCount == snapshot.flagCount)
        #expect(decoded.selectedRow == snapshot.selectedRow)
        #expect(decoded.selectedCol == snapshot.selectedCol)
        #expect(decoded.dailySeed == snapshot.dailySeed)
    }

    @Test("Board init with cells preserves all cell states")
    func testBoardInitWithCells() {
        let originalBoard = Board(seed: 12345)
        var modifiedBoard = originalBoard
        _ = modifiedBoard.reveal(row: 0, col: 0)
        modifiedBoard.toggleFlag(row: 1, col: 1)

        let reconstructed = Board(cells: modifiedBoard.cells)

        #expect(reconstructed == modifiedBoard)
        #expect(reconstructed.cells[1][1].state == .flagged)
    }
}
