import SwiftUI

struct CellView: View {
    let cell: Cell
    let gameStatus: GameStatus
    let isSelected: Bool
    let onReveal: () -> Void
    let onFlag: () -> Void

    private static let cellSize: CGFloat = 32

    var body: some View {
        ZStack {
            background
            content
        }
        .frame(width: Self.cellSize, height: Self.cellSize)
        .overlay(selectionBorder)
        .onTapGesture(perform: onReveal)
        .onTapGesture(count: 1) {
            // Handled by contextMenu for right-click
        }
        .contextMenu {
            Button("Flag") { onFlag() }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        if cell.isExploded {
            Color.red
        } else if case .revealed = cell.state {
            Color(nsColor: .controlBackgroundColor)
        } else {
            RaisedCellBackground()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch cell.state {
        case .hidden:
            if gameStatus == .lost && cell.hasMine {
                mineIcon
            } else {
                EmptyView()
            }

        case .revealed(let adjacentMines):
            if cell.hasMine {
                mineIcon
            } else if adjacentMines > 0 {
                Text("\(adjacentMines)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(color(for: adjacentMines))
            }

        case .flagged:
            if gameStatus == .lost && cell.hasMine {
                mineIcon
            } else {
                Text("🚩")
                    .font(.system(size: 14))
            }
        }
    }

    private var mineIcon: some View {
        Text("💣")
            .font(.system(size: 14))
    }

    // MARK: - Selection Border

    @ViewBuilder
    private var selectionBorder: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.accentColor, lineWidth: 2)
        }
    }

    // MARK: - Number Colors

    private func color(for adjacentMines: Int) -> Color {
        switch adjacentMines {
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        case 4: return Color(nsColor: NSColor(red: 0.0, green: 0.0, blue: 0.55, alpha: 1.0))
        case 5: return .brown
        case 6: return .cyan
        case 7: return .black
        case 8: return .gray
        default: return .primary
        }
    }
}

// MARK: - Raised Cell Background

private struct RaisedCellBackground: View {
    var body: some View {
        ZStack {
            Color(nsColor: .controlColor)

            // Top and left highlight
            Path { path in
                path.move(to: CGPoint(x: 0, y: 32))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 32, y: 0))
                path.addLine(to: CGPoint(x: 29, y: 3))
                path.addLine(to: CGPoint(x: 3, y: 3))
                path.addLine(to: CGPoint(x: 3, y: 29))
                path.closeSubpath()
            }
            .fill(Color.white.opacity(0.5))

            // Bottom and right shadow
            Path { path in
                path.move(to: CGPoint(x: 32, y: 0))
                path.addLine(to: CGPoint(x: 32, y: 32))
                path.addLine(to: CGPoint(x: 0, y: 32))
                path.addLine(to: CGPoint(x: 3, y: 29))
                path.addLine(to: CGPoint(x: 29, y: 29))
                path.addLine(to: CGPoint(x: 29, y: 3))
                path.closeSubpath()
            }
            .fill(Color.black.opacity(0.3))
        }
    }
}

// MARK: - Previews

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

#Preview("Hidden Cell (Selected)") {
    CellView(
        cell: Cell(state: .hidden, hasMine: false),
        gameStatus: .playing,
        isSelected: true,
        onReveal: {},
        onFlag: {}
    )
    .padding()
}

#Preview("Revealed - Zero") {
    CellView(
        cell: Cell(state: .revealed(adjacentMines: 0), hasMine: false),
        gameStatus: .playing,
        isSelected: false,
        onReveal: {},
        onFlag: {}
    )
    .padding()
}

#Preview("Revealed - Numbers") {
    HStack(spacing: 2) {
        ForEach(1...8, id: \.self) { count in
            CellView(
                cell: Cell(state: .revealed(adjacentMines: count), hasMine: false),
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

#Preview("Mine (Game Over)") {
    CellView(
        cell: Cell(state: .hidden, hasMine: true),
        gameStatus: .lost,
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
