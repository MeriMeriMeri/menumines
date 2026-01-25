# Sweep

A minimalist Minesweeper for your menu bar.

## What is Sweep?

Sweep is a menu bar Minesweeper game for macOS that brings the classic puzzle to your fingertips:

- **Always accessible** - Lives in your menu bar, one click away
- **Daily puzzle** - Same board for everyone, every day
- **No decisions** - Just open and play, no setup required
- **Distraction-free** - No dock icon, no clutter

## Installation

### Download

Download the latest release from the Releases page.

1. Download `Sweep.dmg`
2. Open the DMG and drag Sweep to Applications
3. Launch Sweep from Applications
4. Click the mine icon in your menu bar to play

### Build from Source

Requires Xcode 15+ and macOS 14+ (Sonoma).

```bash
git clone <repository-url>
cd sweep
xcodebuild -scheme Sweep -configuration Release
```

The built app will be in `build/Release/Sweep.app`.

## How to Play

Clear the 8x8 board without hitting any of the 10 hidden mines.

### Controls

| Action | Mouse | Keyboard |
|--------|-------|----------|
| Reveal cell | Left-click | Space |
| Toggle flag | Right-click or Control+Click | F |
| Move selection | - | Arrow keys |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘R | Reset game |
| ⌘, | Settings |
| ⌘Q | Quit |

### Rules

- Numbers show how many mines are in adjacent cells (including diagonals)
- Flag cells you think contain mines
- Reveal all non-mine cells to win
- Hit a mine and it's game over

## Daily Board

Every day, Sweep generates a new puzzle using a deterministic seed based on the date. This means:

- Everyone gets the same board on the same day
- You can compare times with friends
- Come back tomorrow for a fresh challenge

Note: if the first click lands on a mine, the mine is relocated using system randomness. In that edge case, boards may diverge across players after the first click.

## Accessibility

Sweep is designed to be fully playable with VoiceOver:

- **Screen reader support** - All cells and controls have descriptive labels
- **Keyboard navigation** - Full game control via arrow keys, Space, and F
- **State announcements** - Win/loss states are announced automatically

To enable VoiceOver, press Cmd+F5 or go to System Settings → Accessibility → VoiceOver.

## Requirements

- macOS 14.0 (Sonoma) or later

## License

GPL-3.0 - See [LICENSE](LICENSE) for details.
