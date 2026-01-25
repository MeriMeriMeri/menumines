import SwiftUI

struct CellView: View {
    let cell: Cell
    let gameStatus: GameStatus
    let isSelected: Bool
    let onReveal: () -> Void
    let onFlag: () -> Void

    private let cellSize: CGFloat = 32

    var body: some View {
        ZStack {
            background
            content
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(selectionBorder)
        .onTapGesture {
            onReveal()
        }
        .onTapGesture(count: 1) {
            // Primary click handled above
        }
        .contextMenu {
            Button("Toggle Flag") {
                onFlag()
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        switch cell.state {
        case .hidden, .flagged:
            if cell.isExploded {
                Color.red
            } else if gameStatus == .lost && cell.hasMine {
                Color.gray.opacity(0.3)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    )
            }
        case .revealed:
            if cell.isExploded {
                Color.red
            } else {
                Color.gray.opacity(0.15)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if cell.isExploded {
            mineIcon
        } else if gameStatus == .lost && cell.hasMine {
            mineIcon
        } else {
            switch cell.state {
            case .hidden:
                EmptyView()
            case .flagged:
                Text("🚩")
                    .font(.system(size: 18))
            case .revealed(let adjacentMines):
                if adjacentMines > 0 {
                    Text("\(adjacentMines)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(colorForNumber(adjacentMines))
                }
            }
        }
    }

    private var mineIcon: some View {
        Text("💣")
            .font(.system(size: 18))
    }

    @ViewBuilder
    private var selectionBorder: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.accentColor, lineWidth: 2)
        }
    }

    private func colorForNumber(_ n: Int) -> Color {
        switch n {
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        case 4: return Color(red: 0, green: 0, blue: 0.5)
        case 5: return .brown
        case 6: return .cyan
        case 7: return .black
        case 8: return .gray
        default: return .primary
        }
    }
}

#Preview("Hidden Cell") {
    CellView(
        cell: Cell(state: .hidden, hasMine: false),
        gameStatus: .playing,
        isSelected: false,
        onReveal: {},
        onFlag: {}
    )
    .padding()
}

#Preview("Selected Cell") {
    CellView(
        cell: Cell(state: .hidden, hasMine: false),
        gameStatus: .playing,
        isSelected: true,
        onReveal: {},
        onFlag: {}
    )
    .padding()
}

#Preview("Revealed Numbers") {
    HStack {
        ForEach(1..<9, id: \.self) { n in
            CellView(
                cell: Cell(state: .revealed(adjacentMines: n), hasMine: false),
                gameStatus: .playing,
                isSelected: false,
                onReveal: {},
                onFlag: {}
            )
        }
    }
    .padding()
}

#Preview("Flagged Cell") {
    CellView(
        cell: Cell(state: .flagged, hasMine: true),
        gameStatus: .playing,
        isSelected: false,
        onReveal: {},
        onFlag: {}
    )
    .padding()
}

#Preview("Exploded Mine") {
    CellView(
        cell: Cell(state: .revealed(adjacentMines: 0), hasMine: true, isExploded: true),
        gameStatus: .lost,
        isSelected: false,
        onReveal: {},
        onFlag: {}
    )
    .padding()
}

#Preview("Game Over - Revealed Mines") {
    HStack {
        CellView(
            cell: Cell(state: .hidden, hasMine: true),
            gameStatus: .lost,
            isSelected: false,
            onReveal: {},
            onFlag: {}
        )
        CellView(
            cell: Cell(state: .flagged, hasMine: true),
            gameStatus: .lost,
            isSelected: false,
            onReveal: {},
            onFlag: {}
        )
    }
    .padding()
}
