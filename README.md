# DocScanner

A Microsoft-Lens-style document scanner for iOS: scan → crop → filter → export as PDF.

## What it does

- **Scan**: Uses Apple's built-in [VisionKit](https://developer.apple.com/documentation/visionkit) document scanner, which auto-detects page edges, corrects perspective, and supports multi-page capture out of the box — no custom edge-detection code needed.
- **Crop**: A manual crop screen lets you drag the four corners of a quad over any page and re-flatten it (`CIFilter.perspectiveCorrection`), for cases VisionKit's auto-detection didn't nail.
- **Filter**: Each page can be Original / Grayscale / Black & White.
- **Reorder / delete pages** before finalizing.
- **Export**: Pages are assembled into a PDF (`UIGraphicsPDFRenderer`) and saved to the app's Documents folder, then handed to the system Share Sheet — covers Mail, Save to Files, AirDrop, Messages, etc.

## Project structure

```
DocScanner/
  project.yml                 # XcodeGen spec — generates the .xcodeproj (not committed)
  Sources/
    DocScannerApp.swift       # App entry point
    Models/ScanPage.swift     # A single scanned page + its filter
    Scanning/DocumentCameraView.swift   # SwiftUI wrapper around VNDocumentCameraViewController
    Services/
      ImageFilterService.swift  # Grayscale / B&W CIFilters
      PDFGenerator.swift        # Renders pages into a PDF
      DocumentStore.swift       # Saves/lists/deletes PDFs in the app's Documents dir
    Utilities/                  # Share sheet wrapper, small helpers
    Views/
      ContentView.swift         # Home screen: list of saved scans, "New Scan" button
      ScanReviewView.swift      # Review captured pages: reorder, delete, filter, crop, save
      CropView.swift / CropOverlay.swift  # Draggable-corner manual crop screen
  Resources/Assets.xcassets   # App icon / accent color placeholders
  .github/workflows/ios-build.yml  # CI: builds the app on every push (see below)
```

No third-party dependencies — everything is built on Apple's own frameworks (SwiftUI, VisionKit, CoreImage, UIKit's PDF renderer).

## Why there's no `.xcodeproj` in this repo

Xcode project files are painful to hand-edit and merge. Instead, [XcodeGen](https://github.com/yonaskolb/XcodeGen) generates `DocScanner.xcodeproj` from `project.yml` on demand — that's a one-line command (`xcodegen generate`) that any Mac with Homebrew can run.

## Building this without owning a Mac

You said you don't have a Mac, so here's the realistic path:

### 1. CI build check (already set up, free)

`.github/workflows/ios-build.yml` runs on every push to GitHub: it installs XcodeGen, generates the project, and builds it for the iOS Simulator on a macOS GitHub Actions runner. This tells you **the code compiles** without needing your own Mac at all. To use it:

```bash
cd DocScanner
git init
git add .
git commit -m "Initial DocScanner project"
git remote add origin <your-github-repo-url>
git push -u origin main
```

Then check the "Actions" tab on GitHub for the build result.

### 2. Actually running it on your iPhone

A Simulator build proves the code compiles, but VisionKit's document camera **requires a real device** — there's no camera in the Simulator. With a paid Apple Developer Program membership, the `TestFlight` workflow (`.github/workflows/testflight.yml`) builds, signs and uploads the app from GitHub's macOS runners — no Mac needed. Then install it on your iPhone from the TestFlight app.

One-time setup:

1. **Register the bundle ID** `com.danpina.docscanner` at developer.apple.com → Certificates, Identifiers & Profiles → Identifiers (App IDs, type "App").
2. **Create the app record** at appstoreconnect.apple.com → Apps → New App (iOS, pick that bundle ID; the app *name* must be unique on the App Store, but it can differ from the name shown on the home screen).
3. **Create an API key**: App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys → generate with the **Admin** role (needed so Xcode can manage signing certificates for you). Download the `.p8` file (only possible once) and note the Key ID and Issuer ID.
4. **Add four repository secrets** (GitHub repo → Settings → Secrets and variables → Actions): `APPLE_TEAM_ID` (developer.apple.com → Membership details), `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_KEY_P8` (paste the full text of the `.p8` file).
5. **Run it**: Actions tab → TestFlight → Run workflow. The build number is the run number, so every run uploads a new build. After Apple finishes processing (a few minutes), add yourself as an internal tester in App Store Connect → TestFlight and install via the TestFlight app on your iPhone.

If you do have a Mac (or a rented cloud Mac), you can also run it directly from Xcode — see below.

### 3. Local iteration tips once you're on a Mac

```bash
brew install xcodegen
xcodegen generate
open DocScanner.xcodeproj
```

Then just build & run onto your connected iPhone from Xcode (⌘R).

## Known limitations / next steps

- App icon is a simple generated placeholder design (`Resources/Assets.xcassets/AppIcon.appiconset`) — swap in your own 1024×1024 PNG (no transparency) any time.
- PDF pages are laid out on US Letter size; add A4 as an option if you need it.
- Filters are simple CIFilters (grayscale/B&W) — Lens-style "whiteboard" or "business card" auto-enhance modes could be added later.
- No cloud backup/sync of saved scans — everything lives in the app's local Documents folder for now.
