# Family Dashboard for Apple

Native SwiftUI clients for iPhone, iPad and Apple TV. The iPhone/iPad target
and tvOS target share the `FamilyDashboardShared` Swift package.

## Requirements

- Xcode 15.4 or newer
- iOS 17 / iPadOS 17 / tvOS 17
- An Apple Developer account and team ID
- The `ha-roku-dashboard` Home Assistant integration at version 0.13 or newer

## Generate the Xcode project

The checked-in `.xcodeproj` is generated from `project.yml`. If you change the
project definition, install [XcodeGen](https://github.com/yonaskolb/XcodeGen)
and run:

```sh
xcodegen generate
```

Open `FamilyDashboard.xcodeproj`, select your Apple Developer team in Signing
& Capabilities, and run either the `FamilyDashboard` or `FamilyDashboardTV`
scheme. The bundle identifier is currently `com.familydashboard.dashboard`;
change it if it is already in use by another app.

## Connection and pairing

The default server address is:

```text
http://homeassistant.local:8123
```

This is intentional. Apple App Transport Security permits local HTTP when
`NSAllowsLocalNetworking` is enabled, and Home Assistant commonly advertises
the `.local` hostname. If you use a bare LAN IP, configure a trusted HTTPS
URL where possible. A per-IP ATS exception is not included by default.

On Apple TV, choose **Show a code to approve**. Open the Family Dashboard
panel in Home Assistant on a phone or computer, choose the link/pairing
button, and approve the pending Apple TV request. The Apple TV never needs a
keyboard. iPhone and iPad offer the same device-initiated flow plus a legacy
pairing-code field.

Credentials are stored in the Apple Keychain and sent only as:

```http
Authorization: Bearer <device-token>
```

The app does not request or store a Home Assistant long-lived access token.

## Shared package tests

The shared package can be tested on macOS or Linux:

```sh
cd FamilyDashboardShared
swift test
```

The fixture in `Tests/DashboardCoreTests/Fixtures/payload.json` was generated
from the Home Assistant integration's real payload and verifies the client
contract, pairing models, action encoding, and server-sent event parser.

## Project layout

```text
FamilyDashboard/                 iPhone + iPad SwiftUI target
FamilyDashboardTV/               Apple TV SwiftUI target
FamilyDashboardShared/
  Sources/DashboardCore/          Codable models, REST, pairing, SSE
  Sources/DashboardUI/            SwiftUI theme, cards, view model, Keychain
  Tests/DashboardCoreTests/       contract and networking tests
project.yml                      XcodeGen source
```

The API contract is maintained in the backend repository at
`api/openapi.yaml` and `api/SCHEMA.md`.

## GitHub Actions builds

The repository includes `.github/workflows/apple.yml`. It runs on GitHub's
`macos-14` runner and:

1. Runs the shared Swift package tests.
2. Builds the iOS app for a generic iOS Simulator destination.
3. Builds the tvOS app for a generic tvOS Simulator destination.

These CI builds intentionally use:

```text
CODE_SIGNING_ALLOWED=NO
CODE_SIGNING_REQUIRED=NO
```

That means no certificates, provisioning profiles, or private signing keys
are required in GitHub. They prove that the package and both app targets
compile, but they do not produce installable App Store or device archives.

The iOS and tvOS targets use different bundle identifiers:

```text
com.familydashboard.dashboard
com.familydashboard.dashboard.tv
```

This avoids bundle identifier conflicts when the targets are later registered
in Apple Developer and App Store Connect.

### Signed releases later

The repository includes `.github/workflows/testflight.yml` for signed
TestFlight releases. It archives and exports both targets using automatic
signing, then uploads the iOS and tvOS IPAs with `xcrun altool`.

Create a protected GitHub Environment named `app-store` and add these secrets
to that environment:

| Secret | Value |
|---|---|
| `APPLE_TEAM_ID` | Your 10-character Apple Developer Team ID |
| `APP_STORE_CONNECT_KEY_ID` | The App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | The App Store Connect issuer UUID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | The complete `.p8` private key, including the BEGIN/END lines |

The App Store Connect API key should have an App Manager or Admin role so
Xcode can manage provisioning and the workflow can upload builds. Register
these bundle IDs in Apple Developer and create the matching apps in App Store
Connect first:

```text
com.familydashboard.dashboard
com.familydashboard.dashboard.tv
```

The release workflow is manual by default and also runs for tags matching
`v*`. A manual run can set `upload` to false to archive/export without
uploading. Keep this workflow restricted to the protected environment; never
put the `.p8` key in repository variables or source files.
