# PitStock — AI-Powered Automotive Spare Parts & Garage Inventory Management

**PitStock** is a comprehensive, offline-first mobile application designed for automotive spare parts shops, car dealerships, and independent repair garages. It combines AI bill scanning, intelligent natural language search, full POS counter sales with GST calculation, workshop job cards, vendor purchase orders, customer vehicle CRM, physical stock audits, barcode label printing, and multi-format reporting.

---

## 🚀 Key Modules & Features (A to Z)

### 🛒 1. Point of Sale (POS) & Billing
- **Counter Checkout POS**: Fast sale creation with one-tap catalogue selection, barcode scanning, and labour charges.
- **Customer & Vehicle Linking**: Auto-fill customer details, phone, and vehicle registration number (e.g. `MH-12-AB-1234`).
- **Flexible Discounts & Payment Modes**: Supports Cash, UPI / QR Code, Debit/Credit Card, Net Banking, and Credit / Due.
- **GST Calculation**: Dual tax breakdown (CGST + SGST or IGST) across standard Indian tax slabs (0%, 5%, 12%, 18%, 28%).
- **Returnable Core Charges**: Exchange old parts (batteries, starters, alternators, radiators) with refundable deposit credits.
- **Automated Stock Deduction**: Deducts sold parts from inventory on checkout and records timestamped movement logs.
- **Instant Tax Invoice Generation**: Generate printable/shareable A4 Tax Invoices with UPI payment QR codes.

### 🚗 2. Garage Workshop & Job Cards
- **Digital Job Cards**: Full lifecycle management (`Open`, `In Progress`, `Waiting for Parts`, `Ready for Delivery`, `Completed`, `Cancelled`).
- **Vehicle Inspection Details**: Track odometer (km), fuel level gauge, customer complaints, and mechanic diagnosis notes.
- **Assigned Technicians**: Allocate job cards to mechanics and technicians.
- **Printable Workshop Job Card PDF**: Generates physical clip-board job card sheets with signature sign-offs.
- **One-Tap Billing Conversion**: Complete jobs to automatically deduct consumed parts and generate customer invoices.

### 📦 3. Inventory & SKU Management
- **Extensive Indian Parts Catalogue**: Seeded starter catalogue of common car parts (Maruti Suzuki, Tata, Mahindra, Hyundai, Toyota, Kia, Universal) across 18 automotive categories.
- **OEM vs. Aftermarket Parts**: Classify parts with fitment years, maker brand (Bosch, MRF, Exide, Castrol, Mann, etc.), and part numbers.
- **Shelf & Bin Location**: Precise warehouse/rack tracking (e.g. `Shelf A1 - Bin 03`).
- **Safety Stock & Reorder Points**: Min safety stock, max shelf capacity, and automatic reorder quantity suggestions.
- **Quick Adjustments with Reason Codes**: Rapid restock (+5, +10), customer returns, damage write-offs, and custom adjustments.
- **Duplicate / Clone Part**: Create new product variants instantly from existing parts.

### 🏭 4. Suppliers & Purchase Orders (PO)
- **Supplier Directory**: Vendor directory with contact numbers, email, physical addresses, GSTIN, and payment terms (e.g. Credit 30 Days).
- **Purchase Orders Workflow**: Draft, issue, and manage POs with expected delivery dates.
- **Interactive Stock Receiving**: Receive partial or full shipments with automatic quantity increments and cost price logging.
- **Printable PO PDFs**: Formatted purchase order documents ready to send to parts distributors.

### 👥 5. Customer & Vehicle CRM
- **Customer Registry**: Customer profiles with transaction histories, lifetime spend, and visit frequencies.
- **Vehicle History Registry**: Register multiple vehicles per customer (make, model, year, fuel type, VIN, engine no, odometer).
- **Direct Actions**: Instant call and quick checkout shortcuts.

### 🤖 6. AI & Smart Recognition Tools
- **AI Bill / Invoice Scanner (OCR)**: On-device OCR reads photographed paper invoices, extracts items/rates/quantities, and auto-matches to your catalogue.
- **Privacy Crop Tool**: Restrict scans to line-item regions, keeping financial headers and private data secure.
- **Live Camera Scanner**: Real-time object and barcode detection using Google ML Kit.
- **Photo Part Identification**: Identifies spare parts via on-device machine learning with support for custom TFLite models (`assets/models/parts_model.tflite`).
- **Smart Natural Language Search**: Offline parser understands colloquial phrases like *"brake pads for swift under 1000"*, *"shocker for nexon"*, or *"engine oil 5w-30"*.

### 🏷️ 7. Barcode & Label Studio
- **Multi-Layout Label Generation**:
  1. *Product Barcode Labels* (Code-128, MRP, Shelf location, Brand).
  2. *Shelf & Bin Rack Tags* (Large location font + QR Code).
  3. *Price Stickers* (Compact shelf tags).
- **Custom Quantity Batch Printing**: Select parts and quantities to generate standard printable A4 label sheets.

### 📋 8. Physical Stock Audit & Reconciliation
- **Shelf/Bin Physical Count Audit**: Filter by shelf or category to verify physical inventory against database numbers.
- **Discrepancy Calculation**: Highlights missing or excess units with net value variance.
- **One-Tap Reconciliation**: Applies batch adjustments with audit movement records.

### 📊 9. Reports & Business Analytics
- **Valuation Overview**: Real-time Stock Value, Potential Sales Revenue, and Expected Gross Profit.
- **Category & Brand Breakdown**: Interactive Pie and Bar charts for inventory distribution.
- **Dead & Overstocked Inventory**: Identifies tied-up capital and surplus stock above maximum thresholds.
- **Reorder Budget Calculator**: Estimates the exact replenishment capital required to restore low-stock parts.
- **CSV & PDF Exports**: One-click export for Inventory Valuations, Sales Reports, and Stock Movement audit logs.

### 🔐 10. Role-Based Access Control (RBAC) & Backups
- **Role Permissions**:
  - **Owner**: Full administrative access, user management, deletions, and backups.
  - **Manager**: Reports, price edits, inventory management, and invoice inspection.
  - **Staff**: POS sales, billing, and stock adjustments (price edits & deletion restricted).
- **Offline Single-File Backup (`.pitstock`)**: Complete snapshot of all SQLite tables (parts, movements, orders, invoices, customers, suppliers) with one-click restore and sharing (Google Drive, WhatsApp, Email).

---

## 🛠️ Architecture & Tech Stack

- **Framework**: Flutter 3.x (Material 3)
- **State Management**: Provider
- **Database**: SQLite (`sqflite`) with offline-first local persistence
- **AI / ML**: Google ML Kit (Text Recognition, Barcode Scanning, Object Detection, Image Labeling) + TensorFlow Lite (`tflite_flutter`)
- **Graphics & UI**: `fl_chart`, `google_fonts`, `flutter_animate`, `shimmer`
- **Document & Label Services**: `pdf`, `printing`, `csv`, `excel`

---

## 📱 Default Demo Credentials

| Role | User Name | PIN |
| :--- | :--- | :--- |
| **Owner** | Rajesh Sharma (Owner) | `1111` |
| **Manager** | Amit Verma (Manager) | `2222` |
| **Staff** | Suresh Kumar (Staff) | `3333` |

---

## 📦 Building and Running

```bash
# Get dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Build release APK
flutter build apk --release
```
