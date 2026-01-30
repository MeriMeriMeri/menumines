# MenuMines

A minimalist Minesweeper for your menu bar.

## What is MenuMines?

MenuMines is a menu bar Minesweeper game for macOS that brings the classic puzzle to your fingertips:

- **Always accessible** - Lives in your menu bar, one click away
- **Daily puzzle** - Same board for everyone, every day
- **No decisions** - Just open and play, no setup required
- **Distraction-free** - No dock icon, no clutter

## Installation

### Download

Download the latest release from the Releases page.

1. Download `MenuMines.dmg`
2. Open the DMG and drag MenuMines to Applications
3. Launch MenuMines from Applications
4. Click the mine icon in your menu bar to play

### Build from Source

Requires Xcode 15+ and macOS 14+ (Sonoma).

```bash
git clone <repository-url>
cd menumines
xcodebuild -scheme MenuMines -configuration Release
```

The built app will be in `build/Release/MenuMines.app`.

## Distribution

MenuMines supports two distribution channels with separate builds:

| Channel | Target | Update Mechanism | Signing |
|---------|--------|------------------|---------|
| App Store | MenuMines | App Store | Apple Distribution |
| Direct | MenuMinesDirect | Sparkle | Developer ID |

### App Store Release

Triggered by pushing a `v*` tag (e.g., `v1.0.0`):

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `release.yml` workflow archives, signs, and uploads to App Store Connect.

### Direct Distribution Release

Triggered by pushing a `v*-direct` tag (e.g., `v1.0.0-direct`):

```bash
git tag v1.0.0-direct
git push origin v1.0.0-direct
```

The `release-direct.yml` workflow:
1. Builds with `Release-Direct` configuration
2. Signs with Developer ID certificate
3. Notarizes with Apple
4. Creates a signed DMG
5. Signs the release for Sparkle auto-updates
6. Generates `appcast.xml`
7. Creates a GitHub Release with DMG and appcast

### Required GitHub Secrets

#### App Store (release.yml)

| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | App Store Connect API issuer ID |
| `APP_STORE_CONNECT_API_KEY` | App Store Connect API private key |
| `APPLE_DISTRIBUTION_P12_BASE64` | Base64-encoded Apple Distribution certificate |
| `APPLE_DISTRIBUTION_PASSWORD` | Certificate password |
| `SENTRY_DSN` | Sentry DSN for error tracking |

#### Direct Distribution (release-direct.yml)

| Secret | Description |
|--------|-------------|
| `DEVELOPER_ID_P12_BASE64` | Base64-encoded Developer ID Application certificate |
| `DEVELOPER_ID_PASSWORD` | Certificate password |
| `APPLE_ID` | Apple ID for notarization |
| `APPLE_ID_PASSWORD` | App-specific password for notarization |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `SPARKLE_PRIVATE_KEY` | Sparkle Ed25519 private key |
| `SPARKLE_PUBLIC_ED_KEY` | Sparkle Ed25519 public key |
| `SENTRY_DSN` | Sentry DSN for error tracking |

### Generating Sparkle Keys

After adding the Sparkle package, build the project to generate the key tool:

```bash
# Build to fetch Sparkle package
xcodebuild -scheme MenuMines-Direct -configuration Release-Direct

# Find and run the key generator
./DerivedData/MenuMines-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys
```

This outputs:
- Private key saved to `~/.sparkle_private_key`
- Public key printed to stdout

Add both keys to GitHub Secrets as described above.

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

Every day, MenuMines generates a new puzzle using a deterministic seed based on the date. This means:

- Everyone gets the same board on the same day
- You can compare times with friends
- Come back tomorrow for a fresh challenge

Note: if the first click lands on a mine, the mine is relocated using system randomness. In that edge case, boards may diverge across players after the first click.

## Accessibility

MenuMines is designed to be fully playable with VoiceOver:

- **Screen reader support** - All cells and controls have descriptive labels
- **Keyboard navigation** - Full game control via arrow keys, Space, and F
- **State announcements** - Win/loss states are announced automatically

To enable VoiceOver, press Cmd+F5 or go to System Settings → Accessibility → VoiceOver.

## Requirements

- macOS 14.0 (Sonoma) or later

## License

GPL-3.0 - See [LICENSE](LICENSE) for details.
