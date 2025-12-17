# SmartSplit

SmartSplit is a SwiftUI iOS app for splitting restaurant bills by what each person actually ate. Enter (or scan) the bill, match items to diners, and apply service automatically so everyone pays their share.

## Intended User Flow
- Scenario: At the table, you photograph the receipt, tell the app how many people are paying, and assign each line item to a name. The app applies the service charge and shows what each person owes.
- Current build: Manual entry + review. You enter items by hand, pick a currency, and choose a service charge; a review screen shows the total. Camera/OCR and per-person assignment are not yet wired up.

## Current Features
- Enter receipt line items with names and prices in your local currency (or choose another currency code).
- Drag or tap the add button to create multiple new item rows quickly (up to 50 items with guardrails).
- See a running total on the entry screen and a confirmation screen that echoes back every item.
- Apply a service charge from common percentage presets to get a final total.

## Project Structure
- `SmartSplitApp.swift`: App entry point wiring the first view.
- `ContentView.swift`: Receipt entry UI, currency picker, item adding interactions, and running total logic.
- `SecondView.swift`: Review screen showing all items, service charge picker, and final total calculation.
- `Assets.xcassets`, `Preview Content/`: Image and preview assets.
- `SmartSplitTests`, `SmartSplitUITests`: Xcode-generated test targets (currently minimal).

## Running Locally
1) Open `SmartSplit.xcodeproj` in Xcode (iOS 17+ target recommended).
2) Select an iOS Simulator or a connected device.
3) Build and run (`⌘R`). No external dependencies are required.

## Key Behaviors & Limits
- Currency defaults to the device locale with a GBP fallback.
- Item rows are capped at 50 to avoid runaway lists; dragging the add button previews how many will be added.
- Receipt totals use `Decimal` to reduce floating-point rounding surprises.

## Roadmap Ideas
- Camera/OCR: snap the bill, extract items automatically, and auto-suggest matches to diners.
- Per-person assignment: collect names/headcount, assign items, and show per-person totals with service.
- Sharing/export: send each person their owed amount or export a receipt breakdown.
- Persistence: save prior splits and allow quick re-use of common diners.
