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

## Milestones
- **Alpha (internal)**: Manual entry plus per-person assignment (add diners, assign items, see per-person totals); currency picker and service charge presets work end-to-end; receipt + per-person math covered by unit tests; UI test covers enabling “Next” after valid price entry and a happy-path assignment; no crashes on device/simulator for receipts up to 50 items.
- **Beta (limited users)**: Receipt import via photo (OCR) with manual correction; exporting/sharing of totals (per-person summary and simple breakdown); lightweight persistence of last receipt/diners; UI tests cover add/delete items, per-person assignment, and export happy path; crash-free session target set and monitored.
- **v1 / Release (public)**: Full history/persistence (saved receipts and diners); richer share/export options (itemized breakdowns); analytics and crash reporting; accessibility pass (labels, Dynamic Type, contrast); CI running unit/UI tests on a known simulator plus lint/formatting; onboarding and empty states.

## Alpha Requirements (with current status)
- Manual receipt entry in chosen currency with service charge presets; totals rounded and accurate (Status: met).
- Add/drag/tap to create up to 50 items with guardrails and running total updates (Status: met).
- “Next” disabled until a valid price is entered; review screen shows items and service total (Status: met).
- Per-person assignment: add diners, assign items, show per-person totals including service (Status: not started).
- Crash-free for receipts up to 50 items on device/simulator (Status: partial—needs explicit soak test).
- Unit/UI coverage for receipt math and primary flow (Status: partial—basic tests exist, expand per below).

### Alpha Requirements Breakdown (Given/When/Then)
| Feature | Given | When | Then | Status |
| --- | --- | --- | --- | --- |
| Item entry | An empty receipt | I enter an item name and price | The item appears in the list and contributes to the running total | Met |
| Running total | A receipt with priced items | I update an item price | Running total recalculates and rounds to 2 decimals | Met |
| Currency selection | Currency picker is shown | I select a currency code | Item formatting and totals display in the chosen currency | Met |
| Service charge preset | Service charge picker is shown | I pick a preset | Total with service recalculates and rounds to 2 decimals | Met |
| Add items (tap) | Add button is available and <50 items exist | I tap the add button | A new item row is appended | Met |
| Add items (tap limit guard) | Add button is available and 50 items exist | I tap the add button | No new row is added and I see a guardrail/alert | Met |
| Add items (drag) | Add button is available and <50 items exist | I drag to add multiple rows | Rows are added up to the drag count without exceeding 50 | Met |
| Add items (drag limit guard) | Dragging would exceed 50 items | I drag to add multiple rows | Rows are capped at 50 and a guardrail/alert prevents exceeding the limit | Met |
| Navigation gating (disabled) | Entry screen with no valid price | I have not entered any valid price | “Next” is disabled | Met |
| Navigation gating (enabled) | Entry screen with at least one valid price | I enter a valid price | “Next” enables | Met |
| Review display | A receipt with items and service charge | I navigate to the review screen | The list shows all items and the total with service | Met |
| Review add diner (valid) | Review screen visible and <20 diners | I add a diner (prefilled placeholder, editable) with a unique, non-blank name | The diner is added; max 20 enforced | Not started |
| Review add diner (blank/duplicate) | Review screen visible | I submit blank or duplicate name | I see validation; no diner is added | Not started |
| Review assign guard | No diners exist | I tap “Assign” on an item | I’m prompted to add a diner first; no crash | Not started |
| Review (item-centric assign) | A receipt and diners exist | I tap “Assign” on an item and choose diners (multi-select) | The item shows selected diners; item cost splits evenly with residue to last diner | Not started |
| Review assignment summary | Items assigned in review | I view per-person summary | Per-person totals reflect review assignments and sum to receipt total with service | Not started |
| Assignment flow entry | Review screen visible | I proceed to the assignment screen | Assignment screen shows items and existing diners | Not started |
| Assignment back navigation | Assignment screen visible | I go back to review | I return without losing assignments | Not started |
| Add diner (valid) | Assignment screen open and <20 diners exist | I enter a non-blank, unique name and confirm | The diner appears with zero subtotal | Not started |
| Add diner (blank) | Assignment screen open | I submit a blank name | I see a validation message and no diner is added | Not started |
| Add diner (duplicate) | A diner with the same name exists | I submit that name again | I am prompted to choose a unique name; no duplicate is added | Not started |
| Add diner (limit) | 20 diners exist | I attempt to add another | I am blocked with a clear message; no diner is added | Not started |
| Assign items (person-centric) | Items and diners exist | I open a diner and select items they ate (multi-select) | The diner subtotal increases by their share (even split; residue to last diner) | Not started |
| Reassign item | An item is assigned | I change its assignee(s) | Previous diner subtotal decreases; new diner subtotal increases; item shows new assignee(s) | Not started |
| Unassign item | An item is assigned | I clear its assignee(s) | The item shows unassigned; diner subtotal decreases accordingly | Not started |
| Per-person totals sum | Items assigned across diners | I view per-person totals | Sum of per-person totals equals receipt total with service | Not started |
| Service charge allocation | Service charge is set and items are assigned | I view per-person totals | Service charge is distributed proportionally to item subtotals; totals round to 2 decimals | Not started |
| Unassigned items guard | One or more items are unassigned | I attempt to finish assignment | I’m warned or blocked until all items are assigned | Not started |
| No diners edge case | No diners exist | I attempt to assign an item | I’m prompted to add a diner first (no crash) | Not started |
| Stability at scale | A receipt with up to 50 items | I use entry, review, and assignment flows | App stays responsive and does not crash (device/simulator) | Partial |
| Test coverage | Codebase and CI/local runs | I run the test suite | Unit tests cover receipt/per-person math; UI tests cover entry gating, limits, and assignment happy path | Partial |

## Alpha Test Stubs (to drive TDD)
Suggested new/expanded tests; add to existing targets and mark `TODO` until implemented.

```swift
// SmartSplitTests (unit) — one per requirement
func testItemEntryAddsToRunningTotal()
func testRunningTotalUpdatesOnPriceChange()
func testCurrencySelectionFormatsTotals()
func testServiceChargePresetUpdatesTotal()
func testAddItemTapAppendsUnderLimit()
func testAddItemTapBlockedAtLimit()
func testAddItemDragAddsMultipleUnderLimit()
func testAddItemDragBlockedAtLimit()
func testNavigationNextDisabledWithoutPrice()
func testNavigationNextEnabledWithPrice()
func testReviewShowsItemsAndServiceTotal()
func testReviewAddDinerValidName()
func testReviewAddDinerRejectsBlankOrDuplicate()
func testReviewAssignGuardWithNoDiners()
func testReviewItemCentricAssignmentEvenSplitResidue()
func testReviewPerPersonSummaryMatchesTotals()
func testAssignmentEntryShowsItemsAndDiners()
func testAssignmentBackNavigationPreservesState()
func testAssignmentAddDinerValid()
func testAssignmentAddDinerRejectsBlank()
func testAssignmentAddDinerRejectsDuplicate()
func testAssignmentAddDinerBlockedAtLimit()
func testPersonCentricSelectionUpdatesSubtotalEvenSplitResidue()
func testReassignItemMovesSubtotalBetweenDiners()
func testUnassignItemClearsSubtotal()
func testPerPersonTotalsSumToReceiptWithService()
func testServiceChargeAllocationProportional()
func testUnassignedItemsBlockedOnFinish()
func testNoDinersPromptOnAssign()
func testFiftyItemsDoesNotCrash()
func testTestCoveragePlaceholder() // ensure suite hook present

// SmartSplitUITests (UI) — one per requirement
func testUIItemEntryAndRunningTotal()
func testUICurrencySelectionFormatsTotals()
func testUIServiceChargePresetUpdatesTotal()
func testUIAddItemTapAndLimitGuard()
func testUIAddItemDragAndLimitGuard()
func testUINavigationNextDisableEnable()
func testUIReviewDisplaysItemsAndTotal()
func testUIReviewAddDinerValidation()
func testUIReviewItemCentricAssignment()
func testUIReviewPerPersonSummary()
func testUIAssignmentEntryAndBackNavigation()
func testUIAssignmentAddDinerValidationAndLimit()
func testUIPersonCentricSelectionFlow()
func testUIReassignAndUnassignItem()
func testUIPerPersonTotalsAndServiceAllocation()
func testUIUnassignedItemsGuardOnFinish()
func testUINoDinersPromptOnAssign()
func testUIStabilityWithFiftyItems()
```

## Screen Interaction Model (Alpha)
**Review (item-centric)**
- Shows itemized receipt, service charge picker, and per-person summary.
- Each item row has an Assign control (chips or sheet) to select one or more diners; if no diners exist, prompt to add one first.
- Diners can be added inline with prefilled placeholders (e.g., “Diner 1”) up to 20, editable with validation against blanks/duplicates.
- Item assignment splits cost evenly across selected diners; rounding residue goes to the last diner. Per-person summary updates live.
- Best when one person knows who ate what, item by item.

**Assignment (person-centric)**
- Lists diners; selecting a diner opens a checklist of all items to mark what they ate (multi-select, multi-diner per item).
- Uses the same even-split logic with residue to the last diner selected for an item.
- Diners can be added inline with placeholders and the same validation/limits; if none exist, prompt to add before selecting.
- Per-person totals (subtotal + allocated service charge) show and update live; sum matches receipt total with service.
- Best when diners self-select their items.
## Future Extensions
- Smarter OCR: auto-detect totals, service, and taxes; highlight uncertain items for confirmation.
- Payment requests: send per-person pay links or integrate with common payment apps.
- Wallet/payments integrations: Apple Wallet/Pay, Monzo (UK) or similar banking APIs where feasible.
- Group coordination: invite others to confirm their items in-app; resolve conflicts when two people claim an item.
- Offline-first sync: allow splits without connectivity, then sync/share when online.

## Quality & Delivery Enhancements
- CI: run `xcodebuild test -scheme SmartSplit -destination 'platform=iOS Simulator,name=iPhone 15'` on PRs; cache DerivedData where possible.
- Tooling: adopt swiftformat + swiftlint with a shared config; add per-target build settings checks (treat warnings as errors for app/logic).
- Testing depth: add unit tests for split math, currency changes, and rounding reconciliation; broaden UI tests to cover add/delete items, per-person assignment, and share flow.
- Observability: enable OSLog for key flows; add crash reporting and minimal, privacy-respecting analytics with opt-out.

## UX/Feature Follow-ups
- Refine assignment popover styling/behavior: more responsive/dynamic sizing and layout polish.
- Add a person-centric assignment screen where each diner can tick all items they ate.
- Add a summary screen that shows all items, assignments, per-person totals, and service.
- Support multiple quantities per item (e.g., 3× fries) in both entry and assignment flows.
