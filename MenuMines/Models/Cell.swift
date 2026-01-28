import Foundation

/// The visibility state of a cell on the board.
enum CellState: Equatable, Codable {
    case hidden
    case revealed(adjacentMines: Int)
    case flagged

    private enum CodingKeys: String, CodingKey {
        case type
        case adjacentMines
    }

    private enum StateType: String, Codable {
        case hidden
        case revealed
        case flagged
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StateType.self, forKey: .type)
        switch type {
        case .hidden:
            self = .hidden
        case .revealed:
            let adjacentMines = try container.decode(Int.self, forKey: .adjacentMines)
            self = .revealed(adjacentMines: adjacentMines)
        case .flagged:
            self = .flagged
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .hidden:
            try container.encode(StateType.hidden, forKey: .type)
        case .revealed(let adjacentMines):
            try container.encode(StateType.revealed, forKey: .type)
            try container.encode(adjacentMines, forKey: .adjacentMines)
        case .flagged:
            try container.encode(StateType.flagged, forKey: .type)
        }
    }
}

/// A single cell on the Minesweeper board.
struct Cell: Equatable, Codable {
    var state: CellState
    let hasMine: Bool
    var isExploded: Bool = false
}
