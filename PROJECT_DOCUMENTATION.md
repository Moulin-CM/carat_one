# CaratOne - Project Documentation

## 1. Project Overview
**CaratOne** is a specialized cross-platform business management application designed for diamond traders and jewelry businesses. It simplifies invoice generation, inventory tracking, and purchase management while ensuring data is synchronized across devices via Firebase.

### Key Objectives:
- Professional PDF invoice generation with automated tax calculations.
- Real-time inventory tracking (carat and value).
- Purchase and payment scheduling with reminders.
- Secure cloud storage and data portability (Export/Import).

---

## 2. Technical Stack
- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Realtime Database)
- **State Management**: Provider (MVVM Architecture)
- **PDF Engine**: `pdf` and `printing` packages
- **Local Features**: `shared_preferences`, `flutter_local_notifications`
- **Data Sharing**: `share_plus`, `file_picker`

---

## 3. Project Structure (MVVM)
The project follows a strict Model-View-ViewModel separation to ensure maintainability:

```text
lib/
├── models/          # Data structures (POJOs)
├── viewmodels/      # Business logic and state handling
├── views/           # UI screens and components
├── services/        # External API/Storage integrations
├── widgets/         # Reusable UI components
└── main.dart        # App entry point & configuration
```

---

## 4. Core Features

### 4.1. Invoice Management
- **Creation**: Multi-step form to capture buyer details and line items.
- **Calculations**: Automatic computation of CGST, SGST, IGST, and Total Amount.
- **PDF Generation**: Matches professional industry templates with "Amount in Words" conversion.
- **Management**: List view with search, edit, delete, and direct sharing capabilities.

### 4.2. Inventory Tracking
- **Stock Management**: Track diamond lots by carat and price per carat.
- **Tax Integration**: Supports GST calculations on stock additions.
- **Dashboard**: Visual summaries of total items, total carat weight, and total stock value.

### 4.3. Purchase & Payment Tracking
- **Purchase Logs**: Record details including Seller Name, Broker, and Size (Alpha-Numeric).
- **Payment Scheduling**: Track 'Cash' vs 'Bill' payments and due dates.
- **Sold Carat Tracking**: Monitor how much of a specific purchase lot has been sold.

### 4.4. Reminders & Notifications
- **Automated Alerts**: Local notifications for upcoming payment deadlines.
- **Reminder View**: Dedicated screen to manage all active business reminders.

### 4.5. User Profiles & Authentication
- **Secure Access**: Email/Password login via Firebase.
- **Business Identity**: Manage company name, address, PAN, GSTIN, and Bank details (automatically populated in invoices).

### 4.6. Data Tools
- **Export/Import**: Backup all invoices to a JSON file for local storage or migration.
- **Force Update**: System to ensure all users are on the latest app version via Firebase config.

---

## 5. Data Models

| Model | Purpose |
| :--- | :--- |
| `InvoiceModel` | Stores buyer info, items, tax rates, and totals. |
| `PurchaseModel` | Tracks stock purchases, brokers, and payment statuses. |
| `InventoryModel` | Represents current stock items and their valuation. |
| `UserProfileModel` | Business identity and banking information. |
| `AppVersionModel` | Used for the Force Update system. |

---

## 6. Firebase Database Structure
The Realtime Database is organized by User ID (`uid`) to ensure data privacy:

```json
{
  "users": {
    "USER_ID": {
      "profile": { ... },
      "invoices": { "INV_ID": { ... } },
      "inventory": { "ITEM_ID": { ... } },
      "purchases": { "PURCH_ID": { ... } }
    }
  },
  "app_version": {
    "latestVersion": "1.0.4",
    "forceUpdate": true
  }
}
```

---

## 7. Setup & Installation
1. **Dependencies**: Run `flutter pub get`.
2. **Firebase**: 
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
   - Enable Email Auth and Realtime Database in Firebase Console.
3. **Environment**: Minimum SDK `3.0.0`.

---

## 8. Development Standards
- **Naming**: camelCase for variables/functions, PascalCase for classes.
- **Services**: All database interactions must go through the `Services` layer.
- **UI**: Uses Material 3 design with a custom blue-centric color scheme (`0xFF4F8AF4`).
