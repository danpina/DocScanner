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

A Simulator build proves the code compiles, but VisionKit's document camera **requires a real device** — there's no camera in the Simulator. To install on your iPhone and test the camera/crop/PDF flow, you need Xcode running on a Mac at some point. Two practical options since you don't own one:

- **Rent a cloud Mac** (e.g. MacinCloud, MacStadium). Clone this repo there, run `brew install xcodegen && xcodegen generate`, open `DocScanner.xcodeproj`, sign in with your Apple ID under Signing & Capabilities (a free Apple ID is enough to install on your own device for 7 days at a time — no paid account needed), connect your iPhone (via USB passthrough if the provider supports it, or their remote-desktop client), and hit Run.
- **Borrow a Mac briefly** just to do the first device pairing/build — after that, an Apple Developer Program membership ($99/yr) lets you distribute builds via **TestFlight**, which you could then install purely from your iPhone without touching a Mac again. This is more setup (code signing certificates, App Store Connect) — worth doing once you're happy with the app and want to iterate without cloud-Mac rentals each time. Ask me when you're ready to set that up.

### 3. Local iteration tips once you're on a Mac

```bash
brew install xcodegen
xcodegen generate
open DocScanner.xcodeproj
```

Then just build & run onto your connected iPhone from Xcode (⌘R).

## Known limitations / next steps

- App icon is a placeholder (empty slot) — add a real 1024×1024 icon before any App Store submission.
- PDF pages are laid out on US Letter size; add A4 as an option if you need it.
- Filters are simple CIFilters (grayscale/B&W) — Lens-style "whiteboard" or "business card" auto-enhance modes could be added later.
- No cloud backup/sync of saved scans — everything lives in the app's local Documents folder for now.
