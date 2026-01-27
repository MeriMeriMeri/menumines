# App Store Distribution Setup

Instructions for configuring the GitHub Actions release pipeline to build and upload MenuMines to TestFlight.

## Prerequisites

- An Apple Developer account ($99/year) at https://developer.apple.com/programs/
- Access to App Store Connect at https://appstoreconnect.apple.com

## Step 1: Apple Developer Portal

Go to https://developer.apple.com/account/resources

### Register the App ID

1. Go to **Identifiers** → click **+**
2. Select **App IDs** → **App**
3. Enter description: `MenuMines`
4. Bundle ID: **Explicit** → `com.merimerimeri.menumines`
5. No additional capabilities needed (App Sandbox is handled via entitlements)
6. Click **Register**

### Create an Apple Distribution Certificate

1. Go to **Certificates** → click **+**
2. Select **Apple Distribution**
3. Follow the instructions to create a Certificate Signing Request (CSR) using Keychain Access:
   - Open Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
   - Enter your email, leave CA Email blank, select "Saved to disk"
4. Upload the CSR and download the certificate
5. Double-click to install it in your Keychain

### Export the Certificate as .p12

1. Open **Keychain Access**
2. Find the certificate named "Apple Distribution: ..." (under My Certificates)
3. Right-click → **Export**
4. Save as `.p12` format with a strong password — you'll need both the file and password later

### Create a Mac App Store Provisioning Profile

1. Go to **Profiles** → click **+**
2. Select **Mac App Store** (under Distribution)
3. Select App ID: `com.merimerimeri.menumines`
4. Select your Apple Distribution certificate
5. Name it something like `MenuMines Mac App Store`
6. Download the `.provisionprofile` file

## Step 2: App Store Connect

Go to https://appstoreconnect.apple.com

### Create the App Record

1. Go to **My Apps** → click **+** → **New App**
2. Platform: **macOS**
3. Name: `MenuMines`
4. Bundle ID: select `com.merimerimeri.menumines`
5. SKU: `menumines` (or any unique string)
6. Access: Full Access

### Generate an API Key

1. Go to **Users and Access** → **Integrations** → **App Store Connect API**
2. Click **Generate API Key**
3. Name: `GitHub Actions`
4. Access: **App Manager** (minimum required role)
5. Click **Generate**
6. **Download the .p8 file immediately** — it can only be downloaded once
7. Note the **Key ID** shown in the table
8. Note the **Issuer ID** shown at the top of the page

## Step 3: GitHub Repository Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these 8 secrets:

| Secret Name | Value | How to Get It |
|---|---|---|
| `APPLE_CERTIFICATE_P12_BASE64` | Base64-encoded .p12 file | Run: `base64 -i YourCert.p12 \| pbcopy` |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the .p12 | The password you set during export |
| `PROVISIONING_PROFILE_BASE64` | Base64-encoded .provisionprofile | Run: `base64 -i MenuMines.provisionprofile \| pbcopy` |
| `APPLE_TEAM_ID` | 10-character Team ID | Apple Developer → Membership details |
| `ASC_KEY_ID` | API Key ID | From Step 2 (shown in API keys table) |
| `ASC_ISSUER_ID` | API Issuer ID | From Step 2 (shown at top of API keys page) |
| `ASC_API_KEY_P8_BASE64` | Base64-encoded .p8 file | Run: `base64 -i AuthKey_XXXXXXXX.p8 \| pbcopy` |
| `SENTRY_DSN` | Sentry DSN URL | From your Sentry project settings |

## Step 4: Trigger a Release

### Option A: Push a tag

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Option B: Manual trigger

1. Go to GitHub → **Actions** tab
2. Select **Release to TestFlight**
3. Click **Run workflow**

## Verification

After the workflow completes:

1. Check the GitHub Actions run for green status
2. Go to App Store Connect → **TestFlight** → your build should appear within ~15 minutes
3. Apple will process the build (can take up to an hour for first submission)
4. Once processed, you can distribute to testers or submit for review

## Troubleshooting

### "No signing identity found"
The certificate wasn't imported correctly. Verify the base64 encoding:
```bash
echo "$APPLE_CERTIFICATE_P12_BASE64" | base64 --decode > /tmp/test.p12
file /tmp/test.p12  # should say "data"
```

### "No provisioning profile matching"
The profile doesn't match the bundle ID or certificate. Re-create it in the Developer portal ensuring you select:
- The correct App ID (`com.merimerimeri.menumines`)
- The correct Apple Distribution certificate

### "Unable to upload"
Verify the App Store Connect API key has sufficient permissions (App Manager role) and the Key ID / Issuer ID are correct.

### Build number conflicts
Each TestFlight upload needs a unique build number. The workflow uses `github.run_number` which auto-increments. If you get a conflict, trigger another run.
