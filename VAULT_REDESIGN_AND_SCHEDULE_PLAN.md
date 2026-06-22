# On phoneapp — Definitive Implementation Plan (Vault Redesign · Schedule · Reminders · Calendar · SMS)

> **Audience:** a smaller, less-capable execution model.
> **Rule of thumb for the executor:** do exactly what each step says, in order. Do **not** improvise around encryption, filenames, Keychain service strings, or the Core Data model name. When unsure, STOP and re-read §2 (Current State) and §6 (Data-Safety Checklist).
> **Project root (all paths absolute):** `/Users/joel/Downloads/01_App-Business/Screenshots-and-Icons/On phoneapp`
> **App target source dir:** `/Users/joel/Downloads/01_App-Business/Screenshots-and-Icons/On phoneapp/On phoneapp`

---

## 1. Overview & Goals

We are upgrading an existing single-user SwiftUI + Core Data iOS app ("Joel's App", bundle id `joel-test.On-phoneapp`, iOS 26 target). Five workstreams, shipped in phases:

1. **Vault redesign + scan fix.** Modern SwiftUI vault UI (async thumbnails, native search, `ContentUnavailableView`, `ShareLink`). Fix the *perceived* "scan page limit" — which is actually a **memory blow-up on large scans**, not a coded cap — by downsampling pages and lazily rendering PDFs. Add page-review-before-save. **No paywall, no hard cap** (solo user; there is no free/premium tier).
2. **Merge Tasks → "Schedule".** Rename the Tasks tab to **Schedule** and **extend the existing `TaskEntity`** with scheduling fields (start/end time, recurrence, multi-reminder offsets, calendar link). Build an agenda list + a custom month grid. Existing tasks survive untouched as the "Unscheduled" backlog.
3. **Interactive local notifications.** Add Complete / Snooze / Open notification actions, switch to robust `UNCalendarNotificationTrigger`, support recurrence, deep-link taps into the Schedule tab.
4. **Apple Calendar sync.** One-way (app → Calendar) EventKit mirror so scheduled items also get OS-level calendar alerts that fire even if the app is closed.
5. **Optional Twilio SMS backend (opt-in).** Real text messages to **818-621-7399** for items the user explicitly flags "Text me." This is the only feature requiring a server; it is its own opt-in phase.

**Notes feature stays exactly as-is.** Do not touch `NotesAppView.swift` or `NoteEntity`.

**Non-negotiable invariants (full detail in §2 & §6):** preserve the Core Data model name `ToolboxDataModel`, the `VaultItemEntity` schema, the `<UUID>.{jpg|pdf}` on-disk filenames, the Keychain service string `com.onphoneapp.vault.filekey.<filename>`, AES-256-GCM crypto, `NSFileProtectionComplete`, biometrics, and tab tags (Notes=1, Tasks/Schedule=2, Vault=3).

---

## 2. Current State Recap (facts the executor MUST know)

**Core Data is defined by a LIVE `.xcdatamodeld`, not by code.**
- Live model file: `/Users/joel/Downloads/01_App-Business/Screenshots-and-Icons/On phoneapp/ToolboxDataModel.xcdatamodeld/ToolboxDataModel.xcdatamodel/contents`
- The container is `NSPersistentContainer(name: "ToolboxDataModel")` with **no `managedObjectModel:` argument** (`CoreDataManager.swift:23`) — it loads the compiled `.xcdatamodeld` by name. **Do all schema edits in that `contents` file (or the Xcode modeler).**
- `CoreDataModel.swift` (`CoreDataModelBuilder.createModel()`) is **DEAD CODE** — a second, unused, *diverging* programmatic model. **Never wire it in. Do not mirror schema changes into it.** (Optional separate cleanup: delete it. Not required for any phase.)
- All three entities use `codeGenerationType="class"` — Xcode auto-generates the `NSManagedObject` subclasses at build time. The only hand-written entity code is in `CoreDataExtensions.swift` (struct↔entity converters).

**Lightweight migration is already ON** (`CoreDataManager.swift:28-29`):
```swift
description?.shouldMigrateStoreAutomatically = true
description?.shouldInferMappingModelAutomatically = true
```
→ **Adding new optional/defaulted attributes to an existing entity, or adding a whole new entity, upgrades existing stores automatically on next launch. No version bump, no mapping model.** (Renaming/removing/retyping an existing attribute does NOT — never do that.)

**Existing `TaskEntity` schema (verified, all 10 attributes):**
`category` (String, opt), `createdAt` (Date), `dueDate` (Date, opt), `hasReminder` (Bool, default NO), `id` (UUID), `isCompleted` (Bool, default NO), `notes` (String, opt), `priority` (Integer 16, default 1), `reminderTime` (Date, opt), `title` (String).

**Store-level encryption:** `description?.setOption(FileProtectionType.complete, forKey: NSPersistentStoreFileProtectionKey)` (`CoreDataManager.swift:27`). The SQLite store is `NSFileProtectionComplete` (hardware-backed, readable only while device unlocked). Attribute values are plaintext **inside** that protected file.

**Vault encryption (do NOT alter the byte path):** per-file AES-256-GCM via CryptoKit (`EncryptionManager`, `VaultView.swift:624-683`), per-file 256-bit key in Keychain under service `com.onphoneapp.vault.filekey.<filename>` with accessibility `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (`KeychainHelper`, `VaultView.swift:523-622`). Encrypted bytes live as `<UUID>.{jpg|pdf}` files in the app Documents dir, each stamped `FileProtectionType.complete`. Biometrics via `LAContext` / `.deviceOwnerAuthenticationWithBiometrics` (`BiometricAuthManager`, `VaultView.swift:20-78`).

**Tab shell** (`ContentView.swift:41-71`): `TabView(selection: $selectedTab)`, `selectedTab: Int`. Tags: **Home=0, Notes=1, Tasks=2, Vault=3, Settings=4.** `HomeView` receives `$selectedTab` for quick-action navigation.

**App entry** (`On_phoneappApp.swift`): `@UIApplicationDelegateAdaptor(AppDelegate.self)`. `AppDelegate` already conforms to `UNUserNotificationCenterDelegate`, sets the delegate, and requests notification auth `[.alert,.sound,.badge]` at launch (`:42`). `didReceive` (`:64`) currently just prints. No EventKit, no background modes.

**The "scan limit" does NOT exist.** Exhaustive grep found no page cap. The scanner loop (`VaultView.swift:411-419`) ingests all pages; `createPDFData` (`:834-848`) draws every full-resolution `UIImage` at native pixel size; `PDFViewerView.loadAndRenderPDF` (`:1950-1982`) pre-renders every page into one `[UIImage]`. **Large scans spike memory and jank/crash — that is the symptom the user calls a "limit." The fix is memory, not raising a cap.**

**Bundle / build:** bundle id `joel-test.On-phoneapp`; display name "Joel's App"; iOS deployment target 26.0. **No standalone Info.plist or entitlements file** — all Info.plist keys are injected as `INFOPLIST_KEY_*` build settings in `On phoneapp.xcodeproj/project.pbxproj`, duplicated in **both** Debug and Release config blocks. Already present: `NSCameraUsageDescription`, `NSFaceIDUsageDescription`, `NSPhotoLibraryUsageDescription`. **Missing (must add for calendar):** `NSCalendarsFullAccessUsageDescription`.

**Known traps (do not copy):**
- `CoreDataExtensions.swift` force-unwraps (`id!`, `title!`, …) in converters — harden before migration work.
- `SettingsView.deleteAllCompletedTasks()` still mutates UserDefaults `saved_tasks`, not Core Data — pre-existing bug; don't imitate.
- `DataCounter.refreshCounts()` (`HomeView.swift:13-41`) uses hardcoded entity-name strings; it already counts `TaskEntity`.

---

## 3. Phased Roadmap (each phase ships on its own)

| Phase | Title | Ships value | Risk |
|---|---|---|---|
| **P0** | Safe groundwork | Harden converters, dedupe categories, delete dead code, baseline backup | Very low |
| **P1** | Vault redesign + scan/memory fix | Smooth vault, no more "scan limit" | Low–Med |
| **P2** | Schedule (Tasks merge) + entity extension | Tasks gain real time slots + agenda/month UI | Low (additive migration) |
| **P3** | Interactive local notifications | Complete/Snooze/Open + recurrence + deep-link | Low |
| **P4** | Apple Calendar sync (one-way) | OS-level backup alerts | Med (permissions) |
| **P5** | Optional Twilio SMS backend | Real SMS to 818-621-7399 (opt-in) | Med (infra, opt-in) |

**Why this order:** P0 removes crash traps and creates a backup before any data touches. P1 is pure-UI/IO and touches no schema, so it's safe to ship first and delivers the most-felt improvement. P2 introduces the only schema change (additive, auto-migrating) and must precede P3–P5 because notifications/calendar/SMS all read the new scheduling fields. P3 (native, free, no infra) before P4 (permissions) before P5 (server, opt-in) follows increasing cost/complexity. **Do not reorder P2 before P1** only if you want the safest first ship; either order is technically fine since they touch disjoint files — but P1-first is recommended for user-felt value.

---

## 4. Phase-by-Phase Detail

> **Build/verify loop for every phase:** open `On phoneapp.xcodeproj` in Xcode, build for an iPhone simulator (iOS 26), run, exercise the acceptance test. If you have CLI: `xcodebuild -project "/Users/joel/Downloads/01_App-Business/Screenshots-and-Icons/On phoneapp/On phoneapp.xcodeproj" -scheme "On phoneapp" -destination 'platform=iOS Simulator,name=iPhone 16' build`.

---

### PHASE P0 — Safe Groundwork (do this first, no behavior change)

**Goal:** remove crash traps and dead-code divergence, create a single source for vault categories, and snapshot a backup — all before any data-touching work.

**Files to edit/create:**
1. **`On phoneapp/CoreDataExtensions.swift`** — harden converters.
2. **NEW `On phoneapp/VaultCategory.swift`** — single category source.
3. **`On phoneapp/VaultView.swift`** — point both hardcoded category arrays (lines ~1029 and ~2326) at `VaultCategory`.
4. *(Optional)* delete `CoreDataModel.swift`.

**Steps:**

**P0.1 — Harden vault converter against nil.** In `CoreDataExtensions.swift`, change `VaultItemEntity.toVaultItem()` (~lines 25–46) from force-unwraps to a failable/guarded form so a partial/migrated row cannot crash the vault:
```swift
func toVaultItem() -> VaultItem? {
    guard let id = self.id,
          let title = self.title,
          let category = self.category,
          let imageName = self.imageName,
          let createdAt = self.createdAt else { return nil }
    return VaultItem(
        id: id, title: title, category: category,
        imageName: imageName, thumbnailName: self.thumbnailName,
        createdAt: createdAt, tags: self.tags, notes: self.notes,
        extractedText: self.extractedText,
        documentType: VaultDocumentType(rawValue: self.documentType ?? "image") ?? .image
    )
}
```
Then update the call site in `VaultStorageManager.loadItems()` (`VaultView.swift:~730-790`) to `compactMap { $0.toVaultItem() }` so nil rows are skipped instead of crashing. Do the same defensive guard for `TaskEntity.toTask()` and `NoteEntity.toNote()` only if they also force-unwrap (leave them functionally identical otherwise).

**P0.2 — Single category source.** Create `VaultCategory.swift`:
```swift
import Foundation

enum VaultCategory: String, CaseIterable, Identifiable {
    case taxes = "Taxes", rental = "Rental Property", receipts = "Receipts",
         insurance = "Insurance", medical = "Medical", personal = "Personal",
         business = "Business", legal = "Legal", education = "Education", other = "Other"
    var id: String { rawValue }
    var sfSymbol: String {
        switch self {
        case .taxes: return "doc.text"; case .rental: return "house"
        case .receipts: return "receipt"; case .insurance: return "shield"
        case .medical: return "cross.case"; case .personal: return "person"
        case .business: return "briefcase"; case .legal: return "building.columns"
        case .education: return "graduationcap"; case .other: return "folder"
        }
    }
    static var titles: [String] { allCases.map(\.rawValue) }
}
```
Replace the two literal arrays in `VaultView.swift` (~1029, ~2326) with `VaultCategory.titles`. **Do not change the string values** — existing rows store these exact strings in `category`.

**P0.3 — (Optional) delete dead model.** Remove `CoreDataModel.swift` from the project and target. Skip if uncertain; it's harmless dead code.

**P0.4 — Backup baseline (manual, see §6).** Build & run once on the simulator with existing data, confirm vault items, notes, and tasks all still load.

**Acceptance test:** App launches; Vault, Notes, Tasks all show existing items; categories appear identically; no crash when scrolling the vault. (To prove P0.1: if you can, manually null a non-required-looking attribute in a test store row — the vault should skip it, not crash.)

---

### PHASE P1 — Vault Redesign + Scan/Memory Fix

**Goal:** modern, smooth vault UI; eliminate the perceived scan-page limit by fixing memory; add page-review-before-save; tighten two security leaks. **No schema change, no crypto change, no filename change.**

**Files:**
- Edit `On phoneapp/VaultView.swift` (most work).
- NEW `On phoneapp/ThumbnailLoader.swift`
- NEW `On phoneapp/ScanReviewView.swift`

**P1.1 — Memory fix A: downsample before PDF generation (HIGHEST IMPACT).** Replace `createPDFData` (`VaultView.swift:834-848`) with autoreleasepool-wrapped, downsampled drawing:
```swift
private func createPDFData(from images: [UIImage], maxEdge: CGFloat = 2000) -> Data? {
    let pdfData = NSMutableData()
    UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)
    autoreleasepool {
        for image in images {
            autoreleasepool {
                let scaled = Self.downsample(image, maxEdge: maxEdge)
                let rect = CGRect(origin: .zero, size: scaled.size)
                UIGraphicsBeginPDFPageWithInfo(rect, nil)
                scaled.draw(in: rect)
            }
        }
    }
    UIGraphicsEndPDFContext()
    return pdfData as Data
}

static func downsample(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
    let longest = max(image.size.width, image.size.height)
    guard longest > maxEdge else { return image }
    let scale = maxEdge / longest
    let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let fmt = UIGraphicsImageRendererFormat.default(); fmt.scale = 1
    return UIGraphicsImageRenderer(size: newSize, format: fmt).image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
}
```
> Verify OCR still reads small text at 2000px; if it misses, raise `maxEdge` to 2400. 2000px longest edge is visually lossless for documents.

**P1.2 — Memory fix B: downsample at the scanner boundary.** In `DocumentScannerCoordinator.documentCameraViewController` (`VaultView.swift:411-419`), wrap each page in an `autoreleasepool` and downsample as it leaves VisionKit so `scannedImages` never holds full-res originals:
```swift
for pageIndex in 0..<scan.pageCount {
    autoreleasepool {
        let full = scan.imageOfPage(at: pageIndex)
        scannedImages.append(VaultStorageManager.downsample(full, maxEdge: 2000))
    }
}
```
(Reference the same `downsample` helper; make it accessible, e.g. `static` on `VaultStorageManager`.)

**P1.3 — Memory fix C: lazy PDF viewing via PDFKit.** Replace the custom all-pages renderer in `PDFViewerView` (`:1876-1983`) with `PDFKit.PDFView` wrapped in a `UIViewRepresentable`, loading a `PDFDocument(data:)` from the **decrypted** Data. PDFKit handles paging/zoom/tiled memory natively and deletes fragile custom code:
```swift
import PDFKit
struct PDFKitView: UIViewRepresentable {
    let data: Data
    func makeUIView(context: Context) -> PDFView {
        let v = PDFView(); v.autoScales = true
        v.document = PDFDocument(data: data); return v
    }
    func updateUIView(_ v: PDFView, context: Context) {}
}
```
Keep the existing decrypt step that produces `Data`; only the rendering changes. **Do not write the decrypted Data to disk.**

**P1.4 — Real thumbnail caching (kills scroll jank).** Create `ThumbnailLoader.swift`, an `ObservableObject` that loads/decrypts/renders OFF the main thread and publishes on `@MainActor`. Populate the **already-existing but unused** `thumbnailName` field lazily: on first cell appearance, if `thumbnailName == nil`, render a ~300px thumbnail, **encrypt it with the SAME per-file pattern** under a **distinct filename `<UUID>_thumb.jpg`** with its **own** Keychain key, save the name into Core Data, and reuse thereafter.
- **CRITICAL:** the thumbnail's encrypted file and Keychain key MUST be cleaned up in `deleteItem` (`VaultView.swift:1693-1707`) alongside the main file/key — otherwise orphaned keys accumulate. Add the `_thumb.jpg` deletion + its Keychain key deletion there.
```swift
@MainActor final class ThumbnailLoader: ObservableObject {
    @Published var thumbnail: UIImage?
    @Published var pageCount: Int = 1
    @Published var fileSizeString: String = ""
    func load(_ item: VaultItem) async {
        // 1. fileSize via FileManager.attributesOfItem (no decryption needed)
        // 2. if item.thumbnailName exists -> decrypt+show it
        // 3. else decrypt main file off-main, render 300px thumb,
        //    encrypt to <UUID>_thumb.jpg w/ own key, persist thumbnailName, show
    }
}
```

**P1.5 — Async grid/list cells.** Rebuild `VaultItemGridCard` (`:2580`) and `VaultItemListRow` (`:2656`) to use `ThumbnailLoader` via `.task { await loader.load(item) }`, with a `ProgressView` placeholder, a PDF page-count badge, file-size text, and a native `.contextMenu` (Favorite / Rename / `ShareLink` / Delete). Use `LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)])`.

**P1.6 — Native search + empty states.** Replace the custom search UI with `.searchable(text: $searchText, prompt: "Search documents, tags, text")` bound to the existing `filteredItems` computed (`:1371-1390`, already searches OCR text — keep that). Replace `emptyStateView` (`:1544`) and `emptySearchView` (`:1605`) with `ContentUnavailableView` / `ContentUnavailableView.search(text:)`.

**P1.7 — Page review before save (the user-facing scan win).** Create `ScanReviewView.swift` shown **between** the scanner and `AddVaultItemView`. Grid of page thumbnails with delete + reorder (simplest safe reorder: a `List` with `.onMove`). Output the ordered `[UIImage]` into the existing `saveItem` flow:
```swift
struct ScanReviewView: View {
    @State var pages: [UIImage]
    var onContinue: ([UIImage]) -> Void
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, img in
                    HStack { Image(uiImage: img).resizable().scaledToFit().frame(height: 80)
                             Spacer(); Text("Page \(idx+1)").foregroundStyle(.secondary) }
                }
                .onMove { pages.move(fromOffsets: $0, toOffset: $1) }
                .onDelete { pages.remove(atOffsets: $0) }
            }
            .navigationTitle("\(pages.count) Page\(pages.count == 1 ? "" : "s")")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") { onContinue(pages) }.disabled(pages.isEmpty)
                }
            }
        }
    }
}
```

**P1.8 — Share via `ShareLink` + delete decrypted temp (SECURITY FIX).** Replace the fragile `ShareSheetContainer` (`:2505-2526`) and the leaky `prepareForSharing` (`:2258/2294`, which writes a decrypted file to `temporaryDirectory` and never deletes it) with `ShareLink`. Write the decrypted temp file into a dedicated subfolder and **delete it** in `.onDisappear` of the detail view AND on app background. Never leave a decrypted copy behind.

**P1.9 — Re-lock on background (SECURITY FIX, one-liner).** `isUnlocked` is per-view `@State` (`:1357`) and never re-locks. Add to `VaultView`:
```swift
@Environment(\.scenePhase) private var scenePhase
// ...
.onChange(of: scenePhase) { _, phase in
    if phase == .background, securityEnabled { isUnlocked = false }
}
```
Only re-lock when `securityEnabled` is true.

**P1.10 — OCR all pages (search win).** Change `performOCR(on: images[0])` (`:1673`) to loop all pages, join with `\n`, store in the existing `extractedText`. Run on a background `Task` AFTER save so it doesn't block the UI.

**P1.11 — Optional soft warning (NOT a cap).** If `scannedImages.count > 30`, show a non-blocking note: "Large scans use more memory — consider splitting." Do **not** hard-block. There is no premium tier.

**Acceptance test (P1):**
1. Scan a 15–25 page document. App does not crash; memory stays bounded (watch Xcode Memory gauge — should plateau, not climb linearly). The "limit" feeling is gone.
2. In Scan Review, delete a page and reorder two pages; Continue → saved PDF reflects the edits.
3. Scroll a vault with many items — no main-thread jank; thumbnails fade in from placeholders; second scroll is instant (cached).
4. Open a multi-page PDF — paging/zoom smooth (PDFKit).
5. Share a document — Messages/Files sheet appears; after dismiss, confirm the decrypted temp file is gone (no residue in tmp).
6. Enable vault security, background the app, return — vault is locked again.
7. **Regression:** an item created BEFORE this phase still opens and decrypts correctly (proves crypto/filename untouched).

---

### PHASE P2 — Schedule (Tasks Merge) + Entity Extension

**Decision: EXTEND `TaskEntity`. Do NOT create a `ScheduleEvent` entity.** Reason: `TaskEntity` already has `dueDate`, `category`, `priority`, `isCompleted`, `notes`, `hasReminder`, `reminderTime`. A new entity would duplicate ~70% of fields, fork the storage/converter/counter code, and split "things with a due time" across two tables — the opposite of "combine." Extending is additive and auto-migrates. (There is ONE entity: extended `TaskEntity`.)

**Files:**
- Schema: `ToolboxDataModel.xcdatamodeld/ToolboxDataModel.xcdatamodel/contents`
- Converters: `On phoneapp/CoreDataExtensions.swift`
- Struct + CRUD: `On phoneapp/TaskManagerView.swift`
- Tab: `On phoneapp/ContentView.swift:54-58`
- NEW views (or grow `TaskManagerView.swift` in place): `ScheduleView`, `ScheduleAgendaView`, `ScheduleMonthView`, `EventEditSheet`.

**P2.1 — Add attributes to `TaskEntity`.** Open the `.xcdatamodeld` in Xcode (preferred — it keeps the file valid) → select `TaskEntity` → add these **all optional or defaulted** (so existing rows stay valid; lightweight migration is automatic). If hand-editing `contents`, insert inside the `<entity name="TaskEntity" …>` block, **keeping attributes alphabetical** to match Xcode's serializer:
```xml
<attribute name="calendarEventID" optional="YES" attributeType="String"/>
<attribute name="endDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
<attribute name="isAllDay" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
<attribute name="notificationIdsData" optional="YES" attributeType="Binary"/>
<attribute name="recurrenceRule" optional="YES" attributeType="String"/>
<attribute name="reminderOffsetsData" optional="YES" attributeType="Binary"/>
<attribute name="startDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
<attribute name="textMe" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
<attribute name="updatedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
```
**Field semantics (firm decisions):**
- `startDate`/`endDate`: a row is **scheduled** (appears on the calendar) iff `startDate != nil`. A row with only `dueDate` (or nothing) is **unscheduled backlog**. No extra flag needed.
- `isAllDay`: Bool.
- `recurrenceRule`: stores an iCal RRULE **String** (`"FREQ=DAILY"`, `"FREQ=WEEKLY"`, `"FREQ=MONTHLY"`). String (not enum) so it round-trips to EventKit later without migration.
- `reminderOffsetsData`: JSON `[Int]` minutes-before (e.g. `[0,15,60]`), bridged by a computed property (mirror `VaultItemEntity.tags`). **New source of truth for reminders;** keep legacy `hasReminder`/`reminderTime` for fallback.
- `notificationIdsData`: JSON `[String]` of scheduled `UNNotificationRequest` ids, for exact cancellation.
- `calendarEventID`: `EKEvent.eventIdentifier` (P4).
- `textMe`: per-item "send me an SMS" flag (P5).
- `updatedAt`: stamped on every save.

**P2.2 — Extend converters** in `CoreDataExtensions.swift` (`TaskEntity` extension). Add JSON-bridged computed properties and refactor so `from(task:)` delegates to `update(from:)` (fixes the latent from/update drift bug):
```swift
extension TaskEntity {
    public var reminderOffsets: [Int] {
        get { reminderOffsetsData.flatMap { try? JSONDecoder().decode([Int].self, from: $0) } ?? [] }
        set { reminderOffsetsData = try? JSONEncoder().encode(newValue) }
    }
    public var notificationIdentifiers: [String] {
        get { notificationIdsData.flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? [] }
        set { notificationIdsData = try? JSONEncoder().encode(newValue) }
    }
    func toTask() -> Task? {
        guard let id, let title, let createdAt else { return nil }
        return Task(id: id, title: title, isCompleted: isCompleted, createdAt: createdAt,
            dueDate: dueDate, category: category, priority: Int(priority), notes: notes,
            hasReminder: hasReminder, reminderTime: reminderTime,
            startDate: startDate, endDate: endDate, isAllDay: isAllDay,
            recurrenceRule: recurrenceRule, reminderOffsets: reminderOffsets,
            calendarEventID: calendarEventID, notificationIdentifiers: notificationIdentifiers,
            textMe: textMe, updatedAt: updatedAt)
    }
    static func from(task: Task, context: NSManagedObjectContext) -> TaskEntity {
        let e = TaskEntity(context: context)
        e.id = task.id; e.createdAt = task.createdAt
        e.update(from: task); return e
    }
    func update(from task: Task) {
        title = task.title; isCompleted = task.isCompleted; dueDate = task.dueDate
        category = task.category; priority = Int16(task.priority); notes = task.notes
        hasReminder = task.hasReminder; reminderTime = task.reminderTime
        startDate = task.startDate; endDate = task.endDate; isAllDay = task.isAllDay
        recurrenceRule = task.recurrenceRule; reminderOffsets = task.reminderOffsets
        calendarEventID = task.calendarEventID
        notificationIdentifiers = task.notificationIdentifiers
        textMe = task.textMe; updatedAt = Date()
    }
}
```
> If `toTask()` returns optional, update `TaskStorageManager.loadTasks()` to `compactMap`.

**P2.3 — Extend the `Task` struct** (`TaskManagerView.swift:14-64`). Add stored props **all with defaults** so existing `Task(...)` call sites keep compiling:
```swift
var startDate: Date? = nil
var endDate: Date? = nil
var isAllDay: Bool = false
var recurrenceRule: String? = nil
var reminderOffsets: [Int] = []
var calendarEventID: String? = nil
var notificationIdentifiers: [String] = []
var textMe: Bool = false
var updatedAt: Date? = nil
// computed
var isScheduled: Bool { startDate != nil }
var isRecurring: Bool { recurrenceRule != nil }
var effectiveSortDate: Date? { startDate ?? dueDate }
```
Keep `isOverdue`, `isDueToday`, `priorityColor`, `priorityText`.

**P2.4 — Rename the tab.** `ContentView.swift:54-58`: keep **`.tag(2)`**, change `TaskManagerView()` → `ScheduleView()`, label `"Tasks"` → `"Schedule"`, image `checklist` → `calendar`. (First grep `HomeView.swift` for `selectedTab = 2`; if present, it now routes to Schedule — fine, just confirm the label/copy still reads sensibly.) Simplest path: **rename `TaskManagerView` to `ScheduleView` in place** and grow it, preserving all existing CRUD/storage/notification wiring.

**P2.5 — Day-bucketing** (replaces the old 2-segment `filteredTasks` at `:269-297`):
```swift
struct DayBucket: Identifiable { let id = UUID(); let title: String; let date: Date?; var items: [Task] }

var buckets: [DayBucket] {
    let cal = Calendar.current
    let scheduled = tasks.filter { $0.isScheduled }
    let unscheduled = tasks.filter { !$0.isScheduled }
    let overdue = scheduled.filter { !$0.isCompleted && $0.startDate! < cal.startOfDay(for: Date()) }
    let overdueIDs = Set(overdue.map(\.id))
    let byDay = Dictionary(grouping: scheduled.filter { !overdueIDs.contains($0.id) }) {
        cal.startOfDay(for: $0.startDate!)
    }
    var out: [DayBucket] = []
    if !overdue.isEmpty { out.append(.init(title: "Overdue", date: nil, items: overdue.sorted(by: byStart))) }
    for day in byDay.keys.sorted() { out.append(.init(title: dayTitle(day), date: day, items: byDay[day]!.sorted(by: byStart))) }
    if !unscheduled.isEmpty { out.append(.init(title: "Unscheduled", date: nil, items: unscheduled)) }
    return out
}
func byStart(_ a: Task, _ b: Task) -> Bool { (a.startDate ?? .distantFuture) < (b.startDate ?? .distantFuture) }
func dayTitle(_ d: Date) -> String {
    let cal = Calendar.current
    if cal.isDateInToday(d) { return "Today" }
    if cal.isDateInTomorrow(d) { return "Tomorrow" }
    return d.formatted(.dateTime.weekday(.wide).month().day())
}
```

**P2.6 — Agenda view** reuses the existing `TaskRowView` per row, grouped by `buckets` in a `List` with sticky section headers. **Legacy tasks land under "Unscheduled" — visible proof of zero data loss.**

**P2.7 — Month view (DECISION: custom `LazyVGrid`, NOT `UICalendarView` or a library).** Reason: iOS 26 SwiftUI is plenty; `UICalendarView` is heavyweight and styling-hostile; a 7-column grid with per-day dots + a tap-to-show-agenda is ~80 lines and fully themeable. Agenda is the primary view; month is a date picker that scrolls the agenda. `DayCell` shows the day number + up to 3 event dots, highlighted when selected; tapping a day lists that day's events with `TaskRowView`.

**P2.8 — Create/Edit sheet `EventEditSheet`** (evolve `AddTaskView`, `:613`). Add gated controls; promote due time to include time-of-day (the single biggest current gap — old picker was `.date` only):
```swift
Section("When") {
    Toggle("All day", isOn: $isAllDay)
    Toggle("Add to schedule", isOn: $hasStart)   // sets startDate; off => backlog task
    if hasStart {
        DatePicker("Starts", selection: $startDate,
                   displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
        if !isAllDay {
            DatePicker("Ends", selection: $endDate, in: startDate...,
                       displayedComponents: [.date, .hourAndMinute])
        }
        Picker("Repeat", selection: $recurrence) {      // None/Daily/Weekly/Monthly -> RRULE
            ForEach(RecurrenceOption.allCases) { Text($0.label).tag($0) }
        }
    }
}
Section("Reminders") {                                   // multi-select -> reminderOffsets [Int]
    ForEach(ReminderLead.allCases) { lead in Toggle(lead.label, isOn: bindingFor(lead)) }
}
```
`RecurrenceOption`: `.none→nil`, `.daily→"FREQ=DAILY"`, `.weekly→"FREQ=WEEKLY"`, `.monthly→"FREQ=MONTHLY"`. `ReminderLead`: At time(0)/15 min/1 hour/1 day. Edit path reuses `existing.id`, `createdAt`, `isCompleted` (as today, `:813-816`).

**P2.9 — CRUD wiring.** Keep `TaskStorageManager` (`:67-141`) ad-hoc-fetch pattern. Update `loadTasks()` sort to date-first: `startDate/dueDate asc → priority desc → createdAt desc`. `addTask`/`updateTask` save then call the notification seam (P3). **Add the delete-confirmation dialog** (Tasks currently has none — `:462`; match Notes' alert). **`DataCounter` needs NO new line** — Schedule IS `TaskEntity`; adding a `scheduleCount` would double-count. Optionally relabel the Home card "Schedule."

**P2.10 — Snooze** (used by P3 swipe actions):
```swift
func snooze(_ task: Task, by interval: TimeInterval) {
    var t = task
    if let s = t.startDate { t.startDate = s.addingTimeInterval(interval) }
    t.dueDate = t.dueDate?.addingTimeInterval(interval)
    updateTask(t)   // updateTask reschedules notifications
}
```

**Migration safety:** existing `TaskEntity` rows simply gain nil/default values for the 9 new attributes and render as **Unscheduled** backlog — nothing moves, nothing is lost. **Do NOT auto-place legacy `dueDate`-only tasks on the calendar** (a deadline is not a scheduled slot; auto-placing is presumptuous). Leave them in the backlog for the user to schedule.

**Acceptance test (P2):**
1. Launch after the schema change — app opens (auto-migration), **all pre-existing tasks appear under "Unscheduled."** (Zero data loss.)
2. Create an event with start 3:00 PM today + end 4:00 PM → it appears under "Today" at the right time.
3. Switch to Month → today shows a dot; tap today → agenda lists the event.
4. Edit the event's time → it moves; complete it → strikethrough; delete → confirmation dialog appears, then it's gone.
5. Tab reads "Schedule" with a calendar icon; Home count still matches total tasks/events (no double count).

---

### PHASE P3 — Interactive Local Notifications

**Goal:** Complete / Snooze / Open actions from the lock screen; robust calendar-based triggers; recurrence; deep-link taps into Schedule. **This is the SMS *primary* path** (interactive native notifications cover ~95% of "remind me" needs with zero infra).

**Files:**
- `On phoneapp/On_phoneappApp.swift`
- `On phoneapp/TaskManagerView.swift` (`NotificationManager`, `:143-256`)
- NEW `On phoneapp/TaskActions.swift`
- NEW `On phoneapp/DeepLink.swift`
- `On phoneapp/ContentView.swift` (observe DeepLink)

**P3.1 — Register categories/actions** in `NotificationManager`:
```swift
extension NotificationManager {
    static let taskCategoryID = "TASK_REMINDER"
    func registerCategories() {
        let complete = UNNotificationAction(identifier: "COMPLETE_ACTION", title: "Complete", options: [.authenticationRequired])
        let snooze = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Snooze 15 min", options: [])
        let open = UNNotificationAction(identifier: "OPEN_ACTION", title: "Open", options: [.foreground])
        let cat = UNNotificationCategory(identifier: Self.taskCategoryID,
            actions: [complete, snooze, open], intentIdentifiers: [], options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([cat])
    }
}
```
Call `NotificationManager.shared.registerCategories()` in `AppDelegate.didFinishLaunchingWithOptions` right after setting the delegate (`On_phoneappApp.swift:~39`), so actions exist before any notification fires.

**P3.2 — Schedule with `UNCalendarNotificationTrigger` + deterministic ids + recurrence.** Replace the relative-trigger body of `scheduleNotification` (`:196-215`). For a scheduled, incomplete task, for each `offset` in `reminderOffsets` compute fireDate from `startDate`/`reminderTime`, build a request with a **deterministic id** `"\(task.id.uuidString)-\(offset)"` (so we can always reconstruct ids to cancel), set `categoryIdentifier` and `userInfo["taskID"]`:
```swift
content.categoryIdentifier = NotificationManager.taskCategoryID
content.userInfo = ["taskID": task.id.uuidString]
let cal = Calendar.current
var comps: DateComponents; var repeats = false
switch task.recurrenceRule {
case "FREQ=DAILY":   comps = cal.dateComponents([.hour,.minute], from: fireDate); repeats = true
case "FREQ=WEEKLY":  comps = cal.dateComponents([.weekday,.hour,.minute], from: fireDate); repeats = true
case "FREQ=MONTHLY": comps = cal.dateComponents([.day,.hour,.minute], from: fireDate); repeats = true
default:
    comps = cal.dateComponents([.year,.month,.day,.hour,.minute], from: fireDate)
    guard fireDate.timeIntervalSinceNow > -5 else { return }   // skip past one-shots
}
let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: repeats)
let req = UNNotificationRequest(identifier: "\(task.id.uuidString)-\(offset)", content: content, trigger: trigger)
UNUserNotificationCenter.current().add(req)
```
Store the resulting ids into `task.notificationIdentifiers` and save. **Fallback:** if `reminderOffsets` is empty but legacy `reminderTime` exists, schedule one notification at `reminderTime` (so old reminders keep firing).

**P3.3 — Cancel precisely.** On complete/delete, cancel every id in `task.notificationIdentifiers` (already wired via `cancelNotification` at `:451,464` — extend to use the stored id list). Keep recurrence as ONE repeating trigger (never pre-schedule N instances) to respect the **64-pending limit**. Add `rescheduleUpcomingWindow()` (cancel all, re-add only items firing within the next 30 days, capped ~60) and call it on launch and on `scenePhase == .active`.

**P3.4 — Handle actions** — rewrite `AppDelegate.didReceive` (`:64`):
```swift
func userNotificationCenter(_ c: UNUserNotificationCenter, didReceive r: UNNotificationResponse,
                            withCompletionHandler done: @escaping () -> Void) {
    let id = r.notification.request.content.userInfo["taskID"] as? String
    switch r.actionIdentifier {
    case "COMPLETE_ACTION": if let id { TaskActions.markComplete(taskID: id) }
    case "SNOOZE_ACTION":   if let id { TaskActions.snooze(taskID: id, minutes: 15) }
    case "OPEN_ACTION", UNNotificationDefaultActionIdentifier: if let id { DeepLink.shared.pendingTaskID = id }
    default: break
    }
    done()
}
```
`TaskActions.swift`: `markComplete(taskID:)` and `snooze(taskID:minutes:)` load the task via `TaskStorageManager`, mutate, re-schedule/cancel, save. `DeepLink.swift`: `final class DeepLink: ObservableObject { static let shared = DeepLink(); @Published var pendingTaskID: String? }`. `ContentView` observes `DeepLink.shared`; on a non-nil `pendingTaskID`, set `selectedTab = 2` and present the matching task's edit sheet, then clear it.

**Acceptance test (P3):** Create an event with a reminder ~1 min out. On the lock screen, long-press the banner → Complete (without opening the app; verify task becomes completed next launch) and Snooze (verify it re-fires ~15 min later). Tap the banner → app opens to the Schedule tab with that event's editor. Create a Daily-recurring reminder → confirm only ONE pending request exists (not many) via the debug pending-list button.

---

### PHASE P4 — Apple Calendar Sync (one-way, app → Calendar)

**Decision: one-way only.** Write-only mirror into a dedicated "Joel's App" calendar; never read user edits back. Avoids all two-way conflict resolution, needs no background polling, and still gives native OS calendar alerts that fire even if the app is killed/deleted.

**Files:**
- `On phoneapp.xcodeproj/project.pbxproj` (add plist key in BOTH configs)
- NEW `On phoneapp/CalendarSyncManager.swift`
- `On phoneapp/TaskManagerView.swift` (wire upsert/delete)
- `On phoneapp/SettingsView.swift` (toggle, lazy permission)

**P4.1 — Add the Info.plist key** as `INFOPLIST_KEY_*` in **both** the Debug and Release build-config blocks of `project.pbxproj` (mirroring existing `INFOPLIST_KEY_NS*UsageDescription` lines, ~:265-267 and the Release equivalent):
```
INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription = "Joel's App mirrors your scheduled items into your calendar so you also get calendar alerts.";
```
(iOS 17+/26 uses the full-access key; that's the one that gates `requestFullAccessToEvents`.)

**P4.2 — `CalendarSyncManager.swift`:** `EKEventStore` singleton with `requestAccess()` (`try await store.requestFullAccessToEvents()`), `appCalendar()` (find-or-create "Joel's App" calendar), `upsert(task:) -> String?` (find by `calendarEventID` or create, set title/notes/start/end, add `EKAlarm(relativeOffset: 0)`, save, return `eventIdentifier`), `delete(calendarEventID:)`.

**P4.3 — Wire it:** in `addTask`/`updateTask`, if `calendarSyncEnabled`, call `upsert`, write the returned id into `task.calendarEventID`, re-save. In `deleteTask`, call `delete(calendarEventID:)`. **Request access lazily** the first time the user flips the Settings toggle on — never at launch.

**P4.4 — Settings toggle:** in the new Reminders section (SettingsView), add `Toggle("Mirror to Apple Calendar", isOn: $calendarSyncEnabled).onChange { if $0 { Task { _ = await CalendarSyncManager.shared.requestAccess() } } }`.

**Acceptance test (P4):** Enable the toggle → permission prompt appears (proves the plist key). Create a scheduled event → it appears in Apple Calendar under a "Joel's App" calendar with an alert at start time. Edit its time → the calendar event updates (not duplicated). Delete it → it's removed from Calendar. Force-quit the app; the calendar alert still fires.

---

### PHASE P5 — Optional Twilio SMS Backend (opt-in)

This phase is **opt-in** — confirm you want it (see Open Questions). The app changes are small (a `textMe` per-item toggle, already added in P2; a `SMSReminderClient.swift` HTTP wrapper; Settings keys). The server is a tiny Supabase table + Edge Function + 1-minute cron calling Twilio. See §5 for the full SMS decision and architecture.

---

## 5. The SMS Decision

**Hard iOS constraint:** an app **cannot** send an SMS silently in the background. `MFMessageComposeViewController` always needs a manual tap and only works while foregrounded. So true "text me when it's due, even if the app is closed" **requires a server.**

**Recommendation (firm):**
- **Primary = native interactive local notifications (P3).** Lock-screen Complete/Snooze/Open, on-time, zero infra, zero cost. Covers ~95% of the need.
- **Reliability backstop = one-way EventKit calendar mirror (P4).** A second, OS-level alert that fires even if the app is uninstalled.
- **True SMS = optional Twilio backend (P5), per-item only.** Fire a real text to **818-621-7399** ONLY for items the user explicitly flags `textMe = true`. Pay the backend/per-message cost only for the handful of must-not-miss items.
- **Do NOT rely on `MFMessageComposeViewController`** for due-time reminders (manual, foreground-only). At most expose it as a "text this to myself now" convenience button — optional, low priority.

**Minimal backend architecture (own phase, opt-in):**
```
iOS app --POST /reminders--> Supabase Edge Function --> reminders table
                                                          (id, title, body, fire_at, phone, status)
Supabase cron (every 1 min) --> SELECT where fire_at <= now() AND status='pending'
                            --> Twilio POST /Messages (To=+18186217399, From=<twilio#>, Body)
                            --> UPDATE status='sent'
```
- **One Postgres table** `reminders`: `id uuid` (= task UUID so the app updates/cancels by the same id), `title text`, `body text`, `fire_at timestamptz`, `phone text default '+18186217399'`, `status text default 'pending'`.
- **Two routes** in the Edge Function: `POST /reminders` (upsert), `DELETE /reminders/:id`. Protect with a single shared-secret header (solo user, no auth system needed).
- **One cron** (every minute) finds due pending rows, calls Twilio `POST https://api.twilio.com/2010-04-01/Accounts/{SID}/Messages.json` (Basic auth `{SID}:{AUTH_TOKEN}`, form `To/From/Body`), marks `sent`.
- **App side** (`SMSReminderClient.swift`): `upsert(task:)` and `cancel(taskID:)`, called **alongside** the existing notification schedule/cancel calls, gated on `smsEnabled && task.textMe`. On complete/edit/delete, `DELETE /reminders/<id>` so a finished task never texts you.
- Store Twilio SID/token/number as Supabase function secrets — never in the app.

**Acceptance test (P5):** With `smsEnabled` on and an event flagged "Text me" 2 min out, a real SMS arrives at 818-621-7399 at fire time. Complete the event before then → no text arrives (DELETE fired). Verify by checking the `reminders` row flips to `sent`/removed.

---

## 6. Data-Safety Checklist (do this, in order, every phase that touches data)

**Before ANY schema or data work:**
1. **Commit the clean tree** (git is already initialized). Create a feature branch per phase (`git checkout -b p2-schedule`). Never work on `main`.
2. **Back up the live store from a device/simulator that has real data.** In the simulator: copy the app container's `*.sqlite`, `*.sqlite-wal`, `*.sqlite-shm` (find via the store URL printed at `CoreDataManager.swift:~37`) to a safe folder. On device, save a copy before installing the new build.
3. **Back up the Documents directory and Keychain assumptions:** the encrypted `<UUID>.{jpg|pdf}` files live in Documents; their keys live in Keychain. Copy the Documents folder from the simulator container too.

**Schema rules (NEVER violate):**
4. **Only ADD attributes** to `TaskEntity` (P2) — all **optional or defaulted**. Never rename, remove, or retype an existing attribute (that breaks lightweight migration).
5. **Never touch `VaultItemEntity`** schema, the model name `ToolboxDataModel`, the `<UUID>.{jpg|pdf}` filename convention, the Keychain service `com.onphoneapp.vault.filekey.<filename>`, the AES-GCM `.combined` scheme, or `NSFileProtectionComplete`. Any change makes existing encrypted files permanently undecryptable.
6. **Never wire in or mirror to `CoreDataModel.swift`** (dead, diverging). Edit only the `.xcdatamodeld`.

**Vault-specific (P1):**
7. Thumbnails use the **same** encryption pattern, a **distinct** `<UUID>_thumb.jpg` filename, and their **own** Keychain key — and MUST be deleted in `deleteItem` alongside the main file/key (no orphaned keys).
8. Decrypted temp files for sharing go to a dedicated subfolder and are **deleted** on detail-view dismiss and on app background. No decrypted residue.
9. Preserve `@AppStorage("vault_security_enabled")` and `UserDefaults("vault_pin_code")` so the user's existing lock state is unchanged.

**Schedule-specific (P2):**
10. Existing tasks must appear (as "Unscheduled") on first launch after migration — **verify this before doing anything else.** If they don't, STOP and restore from the backup in step 2.
11. **Do not auto-place** legacy `dueDate`-only tasks onto the calendar.

**Verification after each data phase:**
12. Launch on the backed-up store; confirm vault items decrypt, notes load, tasks/events all present. If anything is missing, restore and re-investigate before proceeding.

---

## 7. Open Questions for the User (confirm before/while building)

1. **Twilio SMS backend (P5): build it or not?** It's the only piece needing a server + per-message cost. If "not now," P3 (interactive notifications) + P4 (calendar alerts) already cover on-time, interactive reminders. Default assumption: **skip P5 until confirmed.**
2. **Confirm the SMS destination number 818-621-7399** and whether it should be editable in Settings or hardcoded.
3. **Schedule UI:** ship **agenda list first, month grid second** (recommended), or do you want the month grid in the first Schedule release?
4. **OCR on all pages (P1.10):** yes (better full-document search, slightly more processing per scan) or keep page-1-only? Default: **yes, run in background after save.**
5. **Soft scan warning (P1.11):** want the ">30 pages uses more memory" note, or no warning at all? Default: **show the soft note, no hard cap.**
6. **Legacy due-date tasks:** leave them as Unscheduled backlog (recommended) or auto-place same-day on the calendar?
7. **PIN hardening (out of scope above):** the vault PIN is currently plaintext in UserDefaults. Want a follow-up to move it to Keychain + salted SHA-256? (Recommended security fix; can be its own small phase.)
8. **Replace custom PDF viewer with PDFKit (P1.3):** confirms a slight change in scroll/zoom feel in exchange for native memory handling. OK to switch?

---

## 8. Quick-Start "First PR"

**PR title:** *"Vault: async thumbnails + crash-safe loading + re-lock on background"*

**Smallest valuable, lowest-risk increment — no schema change, no crypto change, no filename change:**
1. **P0.1** — make `VaultItemEntity.toVaultItem()` failable and `compactMap` the load (kills the force-unwrap crash on any malformed row).
2. **P1.4 + P1.5** — add `ThumbnailLoader.swift`; switch grid/list cells to async loading with `ProgressView` placeholders; backfill the unused `thumbnailName` lazily (with `_thumb.jpg` cleanup wired into `deleteItem`).
3. **P1.9** — add `.onChange(of: scenePhase)` re-lock when `securityEnabled`.

**Why this first:** it removes the main-thread scroll jank the user feels on every vault scroll, eliminates a real crash vector, and tightens security — all without touching encryption, filenames, or the Core Data schema, so it's the safest possible first ship and immediately felt.

**Acceptance:** vault scrolls smoothly with placeholder→thumbnail fade-in (instant on second scroll); a pre-existing document still opens and decrypts; with vault security on, backgrounding re-locks the vault; no crash on any existing row.
