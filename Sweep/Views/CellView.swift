import AppKit
import SwiftUI

struct CellView: View {
    let cell: Cell
    let row: Int
    let col: Int
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
        .overlay(
            ClickHandlerView(onLeftClick: onReveal, onRightClick: onFlag)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let position = "Row \(row + 1), Column \(col + 1)"

        if cell.isExploded {
            return "\(position), exploded mine"
        }

        if gameStatus == .lost && cell.hasMine {
            return "\(position), mine"
        }

        switch cell.state {
        case .hidden:
            return "\(position), covered"
        case .flagged:
            return "\(position), flagged"
        case .revealed(let adjacentMines):
            if adjacentMines == 0 {
                return "\(position), empty"
            } else if adjacentMines == 1 {
                return "\(position), 1 adjacent mine"
            } else {
                return "\(position), \(adjacentMines) adjacent mines"
            }
        }
    }

    private var accessibilityHint: String {
        guard gameStatus == .notStarted || gameStatus == .playing else {
            return ""
        }

        switch cell.state {
        case .hidden:
            return "Double-tap to reveal, or press F to flag"
        case .flagged:
            return "Press F to remove flag"
        case .revealed:
            return ""
        }
    }

    private var accessibilityTraits: AccessibilityTraits {
        switch cell.state {
        case .hidden, .flagged:
            return .isButton
        case .revealed:
            return .isStaticText
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
        if cell.isExploded || (gameStatus == .lost && cell.hasMine) {
            mineIcon
        } else {
            switch cell.state {
            case .hidden:
                EmptyView()
            case .flagged:
                Text("🚩")
                    .font(.system(size: 14))
            case .revealed(let adjacentMines):
                if adjacentMines > 0 {
                    Text("\(adjacentMines)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(color(for: adjacentMines))
                }
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

// MARK: - Click Handler

private struct ClickHandlerView: NSViewRepresentable {
    let onLeftClick: () -> Void
    let onRightClick: () -> Void

    func makeNSView(context: Context) -> ClickableNSView {
        let view = ClickableNSView()
        view.onLeftClick = onLeftClick
        view.onRightClick = onRightClick
        return view
    }

    func updateNSView(_ nsView: ClickableNSView, context: Context) {
        nsView.onLeftClick = onLeftClick
        nsView.onRightClick = onRightClick
    }
}

private class ClickableNSView: NSView {
    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onLeftClick?()
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
    }
}

// MARK: - Raised Cell Background

private struct RaisedCellBackground: View {
    private let bevelWidth: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width
            let inset = bevelWidth

            ZStack {
                Color(nsColor: .controlColor)

                // Top and left highlight
                Path { path in
                    path.move(to: CGPoint(x: 0, y: size))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: size, y: 0))
                    path.addLine(to: CGPoint(x: size - inset, y: inset))
                    path.addLine(to: CGPoint(x: inset, y: inset))
                    path.addLine(to: CGPoint(x: inset, y: size - inset))
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.5))

                // Bottom and right shadow
                Path { path in
                    path.move(to: CGPoint(x: size, y: 0))
                    path.addLine(to: CGPoint(x: size, y: size))
                    path.addLine(to: CGPoint(x: 0, y: size))
                    path.addLine(to: CGPoint(x: inset, y: size - inset))
                    path.addLine(to: CGPoint(x: size - inset, y: size - inset))
                    path.addLine(to: CGPoint(x: size - inset, y: inset))
                    path.closeSubpath()
                }
                .fill(Color.black.opacity(0.3))
            }
        }
    }
}

// MARK: - Previews

#Preview("Hidden Cell") {
    CellView(
        cell: Cell(state: .hidden, hasMine: false),
        row: 0,
        col: 0,
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
        row: 0,
        col: 0,
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
        row: 0,
        col: 0,
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
                row: 0,
                col: count - 1,
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
        row: 0,
        col: 0,
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
        row: 0,
        col: 0,
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
        row: 0,
        col: 0,
        gameStatus: .lost,
        isSelected: false,
        onReveal: {},
        onFlag: {}
    )
    .padding()
}
