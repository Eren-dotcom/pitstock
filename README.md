# 🔧 PitStock — AI Spare Parts Inventory (Indian Car Parts)

A graphics-rich **Flutter (Android)** app to manage a spare-parts shop / garage
inventory, with **free, offline AI**: bill/invoice OCR, live camera scanning,
barcode matching, and advanced fuzzy search. Ships with a starter **Indian car
spare-parts catalogue** and the maker companies (brands) behind them.

---

## ✨ Features delivered

### Core inventory
- Full CRUD for parts (name, part no, brand/maker, category, vehicle make/model,
  unit, cost/selling price, GST %, barcode, rack location, supplier, notes, photo).
- Offline-first **SQLite** database (`sqflite`) — works with no internet.
- **Stock movement audit trail** (in / out / adjust / bill-import / scan-import).
- Low-stock & out-of-stock **alerts** with a dedicated screen.
- Quick +/- stock controls on each part.

### 🤖 AI features (all FREE + on-device, no API key, works offline)
> Powered by **Google ML Kit**, which bundles models on-device. No cloud, no cost,
> no per-scan billing, and no data leaves the phone.

1. **Bill / Invoice Scanner (OCR)** — `bill_scan_screen.dart`
   - Snap or pick a photo of a supplier bill.
   - `google_mlkit_text_recognition` extracts text **offline**.
   - A heuristic parser (`ocr_service.dart`) turns lines into item rows
     (name, qty, price), auto-matches them to your catalogue, and you review
     before committing.
2. **Live Scan shop / garage** — `live_scan_screen.dart`
   - **Barcode mode**: `google_mlkit_barcode_scanning` instantly matches a part
     by barcode (or offers to create a new one).
   - **Object mode**: `google_mlkit_object_detection` continuously detects &
     labels objects in frame for rapid logging.
3. **Advanced Search** — `search_service.dart` + `search_screen.dart`
   - Fuzzy/typo-tolerant matching (`fuzzywuzzy`) across name, part no, brand,
     vehicle, barcode.
   - Multi-facet filters (category, brand, vehicle), price range, stock state.
   - Sorting (relevance, name, qty, price, recent), autocomplete suggestions.
   - **Voice search** (`speech_to_text`).

### 📊 Graphics-rich UI
- Custom gradient theme, Google Fonts (Poppins), light/dark mode.
- Animated splash, dashboard with gradient stat cards, bar & pie charts
  (`fl_chart`), progress bars, smooth animations (`flutter_animate`).
- Bottom nav with notched center **AI action** button.
- Fully **portrait-locked** and responsive — fits all Android screen sizes
  (uses `SafeArea`, flexible layouts, `ListView`/`GridView` so nothing overflows).

### 📤 Reports & export
- Export inventory to **CSV** and a **PDF** stock report (`export_service.dart`).
- Dashboard analytics: stock value by category (pie), top brands (bars), KPIs.

### 🇮🇳 Indian car spare-parts catalogue
See `lib/data/catalogue_data.dart`:
- **18 categories**: Engine, Brakes, Suspension, Filters, Electrical, Battery,
  Tyres, Belts & Hoses, Clutch & Transmission, Cooling, Lighting, Body & Exterior,
  Lubricants & Fluids, Ignition, Steering, Wipers, Bearings, Exhaust.
- **33 maker companies (brands)**: Bosch, MRF, Apollo, CEAT, JK Tyre, Exide,
  Amaron, Lucas TVS, Sundaram (TVS), Brakes India, Rane, Gabriel, Endurance,
  Minda, Spark Minda, Mahle, Mann Filter, Purolator, Elofic, Castrol, Servo
  (IOCL), Mobil, Valeo, NGK, Denso, Fenner, Gates, SKF, FAG, Maruti/Tata/Mahindra/
  Hyundai genuine, etc.
- **40+ seeded sample parts** across popular models (Swift, Alto, WagonR, Dzire,
  i10, i20, Creta, Nexon, XUV500, Seltos…) with part numbers, GST, prices, barcodes
  and rack locations.

> ⚠️ Part numbers, prices and barcodes in the seed catalogue are realistic
> **samples** for demo. Verify against your supplier invoices before selling.

---

## 🏗 Project structure
```
lib/
├─ main.dart                  app bootstrap, providers, DB seed
├─ theme/app_theme.dart       gradients, light/dark themes
├─ models/                    part, stock_movement, scanned_item
├─ data/                      database_helper, catalogue_data, seed_data
├─ services/                  ocr, scanner, search, export
├─ providers/                 inventory, settings (state mgmt)
├─ widgets/                   stat_card, part_tile
├─ utils/                     formatters, mlkit_input
└─ screens/                   splash, home_shell, dashboard, inventory,
                              search, analytics, settings, part_detail,
                              part_edit, low_stock, bill_scan, live_scan,
                              scan_review
android/                      manifest, gradle, MainActivity (build config)
```

---

## ▶️ How to build the APK

This sandbox has no Flutter SDK, so build on your machine:

```bash
# 1. Install Flutter (https://docs.flutter.dev/get-started/install)
flutter --version          # 3.3+ required

# 2. From the project folder
cd pitstock
flutter create . --platforms=android   # generates gradle wrapper + ios/web if needed
flutter pub get

# 3. Run on a device/emulator
flutter run

# 4. Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> `flutter create .` regenerates any missing platform glue (gradle wrapper jar,
> drawables) without overwriting the provided `lib/` and manifest. The included
> `android/` files set package = `com.pitstock.app`, minSdk 21, and ML Kit deps.

Permissions requested at runtime: **Camera**, **Microphone** (voice search),
**Photos**.

---

## 🆕 v1.1 — Advanced features added

### Part tracking
- **OEM vs Aftermarket** flag on every part (shown as a badge + filterable).
- **Vehicle fitment**: make / model / **year-from–year-to** range (`Part.fitment`).
- **Shelf + Bin** location tracking (`shelf`, `bin`, `binLocation`), with legacy
  rack location kept for compatibility.

### Automation
- **Barcode scanner** (already live) + **printable Code-128 labels** for parts &
  bins (`label_service.dart`, Settings → Print barcode labels).
- **Low-stock alerts** (threshold-based) — on dashboard & alerts screen.
- **Work-order / job-card integration** (`work_order.dart`, `workorders_screen.dart`):
  build a job with parts + labour, then **Complete → auto-deduct** parts from
  inventory (once, with insufficient-stock warnings).
- **Core-charge tracking**: refundable deposit per part; "old core returned?"
  toggle on each job line removes the charge; appears on the invoice.

### POS / GST invoicing
- One-tap **GST tax invoice** PDF from a work order or directly
  (`invoice_service.dart`): CGST/SGST split, core charges, invoice numbering,
  history screen (`invoices_screen.dart`).

### Bulk import
- Import **CSV or Excel (.xlsx)** supplier price lists (`import_service.dart`,
  `bulk_import_screen.dart`) → review → commit. Flexible, case-insensitive
  column mapping.

### Role-Based Access Control (RBAC)
- **Owner / Manager / Staff** roles (`app_user.dart`, `auth_provider.dart`).
- PIN login (`login_screen.dart`). Demo PINs: Owner 1111 · Manager 2222 · Staff 3333.
- Capability matrix gates: delete parts, manage users, view reports, **and view
  original invoice images**. Owner manages users in Settings → Users & roles.

### 🔐 Bill-scanner privacy (all four methods implemented)
1. **Preview & Select** — review screen with per-item checkboxes; ignores
   financial/private text.
2. **Targeted AI extraction** — `OcrService._isolateLineItemRegion()` parses only
   the line-item table, dropping headers (shop/GSTIN/address) & footers
   (totals/tax/bank/signature).
3. **On-device cropping** — `image_cropper` lets the user restrict the scan area
   strictly to the parts list before any OCR.
4. **Role-based image access** — parsed parts go to the shared inventory, but the
   **original invoice image is stored only for Owner/Manager** roles
   (`invoice_images` table, gated by `UserRole.canViewInvoiceImages`).

> 💬 On the recommended tech in your spec: this build uses the **custom-code**
> path (Flutter) you chose. For OCR, instead of paid cloud services (Google Cloud
> Document AI / Azure Form Recognizer), it uses **free, on-device ML Kit** so
> there's no cost and no data leaves the phone. If you later want cloud-grade
> table extraction, `OcrService` is isolated so you can swap in Document AI /
> Form Recognizer behind the same interface. No-code MVPs (Glide/AppSheet) are
> great for quick trials but can't do the offline on-device AI, custom invoicing,
> or rich UI you asked for.

---

## 🆕 v1.2 — Photo recognition + Natural-language search

### 📸 Photo-based part recognition (`More → Photo ID`, or the AI menu)
- Snap or pick a photo of a part → **on-device AI** guesses what it is →
  maps to a PitStock category → shows **matching stock** or lets you add it.
- Two engines, both offline & free (`part_recognition_service.dart`):
  1. **Custom TFLite** — drop a trained `assets/models/parts_model.tflite`
     (+ `parts_labels.txt`) and it auto-activates for true part-specific
     recognition. Train one with the included `tools/train_parts_model.py`
     (MobileNetV2 transfer learning) or Google Teachable Machine.
  2. **ML Kit fallback** — Google's free generic image labeller works with
     **zero training** so the feature is usable immediately.
- See `assets/models/README.md` for the model spec & training guide.

> ⚠️ Honest note: a model can't be *trained* inside this build environment (no
> dataset/GPU). The full recognition pipeline + fallback ship working today; add
> your `.tflite` later for higher accuracy — no code changes needed.

### 💬 Natural-language search (`Search` tab → "Smart" toggle, on by default)
- Type or speak plain English, e.g. **"brake pads for swift under 1000"**,
  **"cheap genuine filters for creta"**, **"low stock batteries above 200"**.
- `nl_search_service.dart` parses it 100% on-device into structured filters:
  category, brand/maker, vehicle make, **price range**, stock state, OEM/
  aftermarket, and sort — then fuzzy-matches the leftover words.
- Shows **"Understood:" chips** so the user sees exactly what was parsed, plus
  tappable example prompts. Works with the mic (voice) too.

---

## 🆕 v1.3 — Backup & Restore (Owner-only)

`Settings → Backup & Restore` (or `More → Backup`). Protects shops from data loss.

- **Create backup & share** — dumps the *entire* database (parts, stock
  movements, work orders + lines, invoices, users, settings/meta, invoice-image
  refs) into one portable `.pitstock` JSON file and opens the share sheet
  (Google Drive / WhatsApp / email / Files). A timestamped copy is also kept
  on-device.
- **On-device backups list** — restore any previous local snapshot in one tap.
- **Restore from a file** — pick any `.pitstock` file; a confirm dialog shows
  the backup's date & record count before it **replaces** all current data
  atomically (single DB transaction). All providers reload immediately after.
- **Validation** — files are checked for the PitStock magic header; corrupt or
  foreign files are rejected with a friendly message.
- **Role-gated** — only the **Owner** can back up or restore
  (`UserRole.canBackup`).

Code: `services/backup_service.dart`, `screens/backup_screen.dart`, and
`DatabaseHelper.exportAllTables()` / `importAllTables()`.

> Fully offline — no cloud account required. The user decides where the backup
> file is stored.

---

## 💡 Recommended features you can add next (roadmap)

I kept the architecture modular so these slot in cleanly:

**Sales & billing**
- POS / invoice generator with GST split (CGST/SGST), customer ledger.
- Barcode/QR **label printing** for racks and parts.
- Returns & warranty tracking.

**Stock intelligence**
- Auto **reorder suggestions** & purchase orders to suppliers.
- Demand forecasting (simple moving average → on-device ML).
- Dead-stock / fast-mover reports, ABC analysis.
- Multi-warehouse / multi-branch stock.

**AI upgrades**
- Train a custom **TFLite** model to recognise specific parts visually
  (still offline & free).
- Smarter bill parsing using layout/table detection.
- Natural-language search ("brake pads for swift under 1000").
- Photo-based duplicate detection when adding parts.

**Business & collaboration**
- Multi-user with roles (owner/staff) + activity log.
- Cloud backup/sync (optional — Firebase free tier or Supabase).
- WhatsApp share of quotes/low-stock to suppliers.
- Offline-first sync queue.

**Vehicle fitment**
- Part ↔ vehicle compatibility matrix ("fits these models/years").
- VIN / registration lookup to suggest compatible parts.

**Quality-of-life**
- Bulk import/export (Excel), supplier price lists.
- Expiry tracking for fluids/batteries, serial-number tracking.
- Hindi/regional language UI, currency & tax presets.
- Home-screen widget for low-stock count; daily backup reminder.

---

## 🆓 Why this AI is free & offline
| Need | Library | Cost | Offline |
|------|---------|------|---------|
| Bill OCR | google_mlkit_text_recognition | Free | ✅ |
| Barcode | google_mlkit_barcode_scanning | Free | ✅ |
| Object detect | google_mlkit_object_detection | Free | ✅ |
| Voice search | speech_to_text | Free | ✅ (device STT) |
| Fuzzy search | fuzzywuzzy | Free | ✅ |

No OpenAI/Gemini API keys, no monthly fees, no internet dependency for the
core AI. (If you later want a cloud LLM for natural-language features, that's an
optional add-on.)
```
```
