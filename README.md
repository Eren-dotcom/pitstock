# PitStock - Vehicle Parts Inventory Management

A Flutter-based inventory management system for automotive parts shops, featuring AI-powered bill scanning, role-based access control, and comprehensive reporting.

## Features

✨ **AI-Powered Features**
- 📷 Bill/Invoice Scanner with on-device OCR
- 🔍 Live Scan for parts & barcodes
- 🤖 Part identification by photo

👥 **Role-Based Access Control**
- Owner: Full access including data backup/restore
- Manager: Can view reports, manage inventory, view invoices
- Staff: Can manage inventory and bill customers

📊 **Core Features**
- Complete inventory tracking with barcode support
- Work order & job management
- Invoice creation and tracking
- CSV/PDF export
- Barcode label printing
- Full data backup & restore

🔐 **Privacy First**
- On-device processing (no cloud uploads)
- Local SQLite database
- User authentication with PIN

## Building

This project is automatically built using GitHub Actions. Every push to `main` triggers an APK build.

### Manual Build
```bash
flutter pub get
flutter build apk --release
```

## Architecture

- **Frontend**: Flutter with Provider state management
- **Database**: SQLite with local storage
- **AI**: Google ML Kit (on-device)
- **Exports**: PDF, CSV, barcode labels
