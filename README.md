# faster

An iOS intermittent-fasting and weight-loss coach. Personalized, local-first, Apple Health–aware.

- **Platform:** iOS 17.5+
- **Language:** Swift 5.10, SwiftUI
- **Persistence:** SwiftData (on-device only)
- **Integrations:** HealthKit, UNUserNotificationCenter, WidgetKit, ActivityKit (Live Activity / Dynamic Island)
- **Status:** Source scaffolded. You need a Mac with Xcode 15.4+ to generate the project, build, and run.

---

## Features (v1)

- Onboarding with BMR / TDEE / safe-deficit math (Mifflin-St Jeor) and goal-date projection
- Fasting protocols: 16:8, 18:6, 20:4, OMAD
- Active fast timer with phase labels (anabolic → early fast → glycogen depletion → fat-burning → deep ketosis)
- Hour-by-hour guidance cards (JSON-driven) — what to drink, when to add electrolytes, how to break the fast gently
- **"What's allowed while fasting"** browser — water, black coffee, tea, electrolytes, and foods that break the fast, with notes
- Smart local notifications — fast start, break-fast 30-min warning, hydration, electrolytes at 12h, eating-window close, daily weigh-in
- Weight logging + Swift Charts trend (7-day moving average) + straight-line goal projection
- Water tracking with daily target from body weight (writes to Apple Health)
- Apple Health read (`bodyMass`, `height`, `stepCount`, `activeEnergyBurned`, `dietaryWater`) and write (`bodyMass`, `dietaryWater`, and — opt-in — fasting sessions as `mindfulSession`)
- Streaks + weekly summary (completed = ≥ 90% of target duration)
- Live Activity / Dynamic Island + Home / Lock Screen widget
- CSV and JSON data export
- **Dark-mode toggle** (System / Light / Dark) in Settings
- Safety guardrails: SCOFF screening, pregnancy/breastfeeding block, BMI floors, medication acknowledgements, kcal floors (1500 M / 1200 F), protocol gating, 1h cooldown between fasts

---

## Project layout

```
faster/
├── project.yml                    # XcodeGen spec (generates faster.xcodeproj)
├── faster/
│   ├── Info.plist
│   ├── faster.entitlements        # HealthKit, App Group
│   ├── App/                       # @main, DI, RootView
│   ├── Core/
│   │   ├── Persistence/           # SwiftData SchemaV1 + factory
│   │   ├── Calculations/          # Pure Swift: BMR/TDEE/phase/hydration
│   │   ├── HealthKit/             # HKHealthStore wrapper
│   │   ├── Notifications/         # UNUserNotificationCenter actor
│   │   └── DesignSystem/
│   ├── Features/
│   │   ├── Onboarding/Screens/    # 9-step flow
│   │   ├── Fasting/               # TodayView, timer, controller, guidance, LiveActivity
│   │   ├── Weight/                # Log + Swift Charts
│   │   ├── Water/                 # Ring + quick-log
│   │   ├── Streaks/               # StreakService + weekly summary
│   │   └── Settings/              # SettingsView + ExportService
│   ├── Widgets/                   # WidgetKit + Live Activity extension target
│   └── Resources/
│       └── guidance.json          # Hourly cards + allowed consumables
└── fasterTests/                   # XCTest
```

---

## Prerequisites

You must build this on **macOS** with:

- **Xcode 15.4 or later** (Xcode 16+ recommended)
- **Command Line Tools**: `xcode-select --install`
- **XcodeGen** (generates the `.xcodeproj` from `project.yml`): `brew install xcodegen`
- (For App Store) **An Apple Developer account** ($99/year) enrolled at <https://developer.apple.com>

---

## 1. Generate the Xcode project

From the repo root:

```bash
brew install xcodegen       # once
xcodegen generate           # creates faster.xcodeproj
open faster.xcodeproj
```

XcodeGen creates three targets:

- `faster` — the main app
- `FastingWidgetExtension` — WidgetKit + Live Activity
- `fasterTests` — XCTest bundle

You'll need to set a **Development Team** in Xcode once:

- Select the `faster` target → **Signing & Capabilities** → **Team**.
- Do the same for `FastingWidgetExtension`.
- Change the bundle identifiers if `com.faster.app*` is already taken on your account.
  Update them in **three places** (main app, widget extension, App Group).

---

## 2. Run tests

Unit tests cover BMR/TDEE math, fasting-phase boundaries, guidance resolution, fasting controller lifecycle, and notification scheduling caps.

**From Xcode:** `⌘U`.

**From the command line:**

```bash
xcodebuild test \
  -project faster.xcodeproj \
  -scheme faster \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## 3. Run in the Simulator

1. In Xcode, pick an iPhone simulator (e.g., **iPhone 15 Pro**, iOS 17.5+).
2. Press `⌘R`.
3. Walk through onboarding. Grant notification permission.
4. To test Apple Health in the simulator: open the **Health** app in the simulator, add some sample weights, then in faster tap **Weight → Sync with Health**.
5. To test notifications quickly, pick the 16:8 protocol then use **Adjust Start** to push the start time back ~15 h — the break-fast notification will fire within a few minutes.

> HealthKit and local notifications both work in the Simulator, but some behaviors (Live Activity, Dynamic Island, widget background refresh) are only fully testable on a real device.

---

## 4. Install on your iPhone (free, personal use)

You do **not** need a paid developer account to run the app on your own iPhone — a free Apple ID works, but builds expire after 7 days and must be re-signed.

1. Connect your iPhone via USB (or Wi-Fi pairing).
2. Trust the Mac on the phone.
3. In Xcode, sign in with your Apple ID: **Xcode → Settings → Accounts → +**.
4. Select the `faster` target → **Signing & Capabilities**:
   - Tick **Automatically manage signing**.
   - Choose your **Personal Team**.
   - If the bundle id is taken, change it (e.g., `com.yourname.faster`).
5. Do the same for the `FastingWidgetExtension` target. Its bundle id must be a child of the main app's (e.g., `com.yourname.faster.FastingWidget`).
6. Pick your iPhone as the run destination and press `⌘R`.
7. On the phone, open **Settings → General → VPN & Device Management → [Your Apple ID] → Trust**.
8. Launch **faster** from the Home Screen.

**HealthKit on device:** the first time you tap any Health action, iOS shows the permissions sheet. Turn everything on to see the full experience. You can later revisit in **Settings → Health → Data Access & Devices → faster**.

**Notifications on device:** accept the prompt during onboarding. If you missed it, enable in **Settings → Notifications → faster**.

**Live Activity / Dynamic Island:** start a fast — the Live Activity appears on the Lock Screen and (on iPhone 14 Pro and later) in the Dynamic Island.

---

## 5. Deploy to the App Store

### Prerequisites

- Enrolled Apple Developer Program membership ($99/year): <https://developer.apple.com/programs/>.
- An App Store Connect record created at <https://appstoreconnect.apple.com>:
  - **My Apps → +** → **New App** → iOS, choose your bundle id (e.g., `com.yourname.faster`), SKU, and primary language.

### One-time setup in Xcode

1. Signing & Capabilities on the main target:
   - Team: your paid developer team
   - Signing Certificate: **Apple Distribution**
   - Capabilities: **HealthKit**, **App Groups** (for widget data sharing), **Push Notifications** is *not* required.
2. Bump `MARKETING_VERSION` (e.g., `1.0`) and `CURRENT_PROJECT_VERSION` (e.g., `1`) in `project.yml` and regenerate: `xcodegen generate`.

### App Store review requirements you must prepare

- **Privacy manifest** (`PrivacyInfo.xcprivacy`) — Apple now requires one. Declare HealthKit data categories read/written and that the app does *not* collect or track users externally.
- **Privacy policy URL** (required by App Store Connect; HealthKit apps must have one).
- **App Review notes**: mention you use HealthKit for fasting/weight, and that fasting sessions are stored as Mindful Minutes with explicit user opt-in. This is the approach mainstream fasting apps use and Apple accepts.
- **Medical disclaimer** in the app (already included in onboarding + the Today-view footer + Settings).
- **Screenshots** for required iPhone sizes (6.7" and 6.5"). Run in the simulator and capture with `⌘S`.
- **App icon**: add 1024×1024 PNG to `Assets.xcassets/AppIcon.appiconset`.

### Archive + upload

1. Select **Any iOS Device (arm64)** as the destination.
2. Xcode menu → **Product → Archive**.
3. When the Organizer opens, pick the archive → **Distribute App → App Store Connect → Upload**.
4. Xcode validates, re-signs with your distribution profile, and uploads to App Store Connect.

Alternatively, from the command line:

```bash
xcodebuild -project faster.xcodeproj -scheme faster \
  -sdk iphoneos -configuration Release archive \
  -archivePath build/faster.xcarchive
xcodebuild -exportArchive \
  -archivePath build/faster.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist      # you create this once
xcrun altool --upload-app -f build/export/faster.ipa \
  -t ios -u you@example.com -p "@keychain:AC_PASSWORD"
```

### TestFlight and submission

1. In App Store Connect → **TestFlight**, wait for the processing email (~15 min).
2. Fill in **Test Information**, add internal/external testers.
3. Once tested, go to the **App Store** tab, fill in description, keywords, screenshots, age rating (likely 17+ because of health content), and privacy details.
4. **Submit for Review**. Typical turnaround is 24–48 hours.

---

## Editing the guidance copy

All coaching text lives in `faster/Resources/guidance.json`. Reload the app to see changes. The loader is behind a `GuidanceProvider` protocol so a future version can fetch updated copy from a CDN without changing call sites.

---

## Key implementation notes

- **Elapsed fast time** is always derived from `Date.now − fastSession.actualStart`. Never trust an in-memory counter — the app can be killed or the phone restarted mid-fast.
- **Notifications** are rebuilt atomically (`removeAllPendingNotificationRequests()` + full rebuild) whenever the fasting state or plan changes. The system cap is 64 pending; we stay under 60.
- **Fasting sessions in Apple Health** are written as `HKCategoryTypeIdentifier.mindfulSession`. HealthKit has no native fasting type, and `HKWorkoutType` would incorrectly inflate activity rings. The toggle is opt-in and honestly labeled.
- **Pure-Swift calculations** (`Core/Calculations/`) are independent of SwiftUI and SwiftData so they're easy to unit-test.
- **SwiftData schema** is versioned from day one via `VersionedSchema`. Future migrations go in `FasterMigrationPlan`.

---

## Safety + medical

faster is **not medical advice** and is not a treatment for any condition. The app blocks users under 18, anyone pregnant or breastfeeding, and anyone with a current or target BMI below 18.5. Users on insulin, sulfonylureas, blood-pressure medications, or medications taken with food see a consult-your-doctor interstitial. SCOFF-style screening routes users with positive answers to NEDA (US) or regional equivalents.

If you fork this project, preserve these guardrails.
