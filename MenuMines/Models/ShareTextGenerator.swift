import Foundation

/// What the player actually did, as opposed to what the board looked like.
struct PlaySummary: Equatable {
    var clickCount: Int = 0
    var chordCount: Int = 0
    var largestOpening: Int = 0
}

/// Generates Wordle-style share text for completed games.
/// The grid encodes difficulty heat map without exposing mine locations.
struct ShareTextGenerator {
    /// Generates share text for a completed game.
    /// - Parameters:
    ///   - status: The game status (must be .won or .lost).
    ///   - board: The game board.
    ///   - elapsedTime: Total time played.
    ///   - markedMinesCount: Number of correctly marked mines at win (before auto-flagging).
    ///   - date: The date to use for the header (defaults to current date formatted in UTC).
    /// - Returns: The formatted share text, or nil if the game is not complete.
    static func generate(
        status: GameStatus,
        board: Board,
        elapsedTime: TimeInterval,
        markedMinesCount: Int,
        play: PlaySummary = PlaySummary(),
        date: Date = Date()
    ) -> String? {
        guard status == .won || status == .lost else { return nil }

        var lines: [String] = []

        // Header with UTC date
        lines.append(formatHeader(date: date))

        // Result line with formatted time and flag count
        lines.append(formatResultLine(status: status, elapsedTime: elapsedTime, markedMinesCount: markedMinesCount))

        // The grid is the day's fingerprint and is identical for everyone, so the line
        // above it is the only part that says anything about this player.
        if let playLine = formatPlayLine(play) {
            lines.append(playLine)
        }

        // Emoji grid - difficulty heat map (fully spoiler-free)
        lines.append(contentsOf: generateDifficultyGrid(board: board))

        return lines.joined(separator: "\n")
    }

    /// Describes how the player got there, without saying anything about where the mines
    /// are. Anything positional would hand a head start to someone who has not played yet.
    private static func formatPlayLine(_ play: PlaySummary) -> String? {
        guard play.clickCount > 0 else { return nil }
        return String(
            format: String(localized: "share_play_line"),
            play.clickCount,
            play.chordCount,
            play.largestOpening
        )
    }

    /// Formats the header with UTC date.
    private static func formatHeader(date: Date) -> String {
        let timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dateString = formatter.string(from: date)
        return String(format: String(localized: "share_header"), dateString)
    }

    /// Formats the result line showing time and flag count.
    private static func formatResultLine(status: GameStatus, elapsedTime: TimeInterval, markedMinesCount: Int) -> String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let timeString = String(format: "%d:%02d", minutes, seconds)

        if status == .won {
            return String(format: String(localized: "share_solved"), timeString, markedMinesCount, Board.mineCount)
        } else {
            return String(format: String(localized: "share_failed"), timeString, markedMinesCount, Board.mineCount)
        }
    }

    /// Generates the difficulty heat map grid.
    /// Every cell shows its difficulty based on adjacent mine count.
    /// Mines are indistinguishable from safe cells - no gaps in the pattern.
    private static func generateDifficultyGrid(board: Board) -> [String] {
        var gridLines: [String] = []

        for row in 0..<Board.rows {
            var rowEmojis = ""
            for col in 0..<Board.cols {
                let adjacentMines = board.adjacentMineCount(row: row, col: col)
                rowEmojis += difficultyEmoji(for: adjacentMines)
            }
            gridLines.append(rowEmojis)
        }

        return gridLines
    }

    /// Returns the appropriate emoji for the given adjacent mine count.
    /// - 0 adjacent mines: safe zone (green)
    /// - 1-2 adjacent mines: easy (yellow)
    /// - 3-4 adjacent mines: medium (orange)
    /// - 5+ adjacent mines: danger zone (red)
    private static func difficultyEmoji(for adjacentMines: Int) -> String {
        switch adjacentMines {
        case 0:
            return "🟩"
        case 1...2:
            return "🟡"
        case 3...4:
            return "🟠"
        default:
            return "🔴"
        }
    }
}
