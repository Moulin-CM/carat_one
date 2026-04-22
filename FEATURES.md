# CaratOne — Feature Documentation

CaratOne is a Flutter-based business management app for jewelry/diamond traders. It handles invoicing, inventory, purchase tracking, and business operations with cloud sync via Firebase.

---

## 1. Authentication & User Management

### Sign-Up
- Multi-step sign-up wizard with progress indicator and section-based form
- Captures: email, password, company details, tax info (GST, PAN, CST, VAT, IEC), bank details (bank, branch, account, IFSC)
- Field-level validation with error messages

### Login
- Firebase email/password authentication
- Forgot password flow
- Navigation to sign-up for new users

### Session Management
- `AuthWrapper` routes authenticated vs unauthenticated users
- Automatic Firebase session handling
- Logout with confirmation dialog

### User Profile
- View and edit full business profile (company, contact, tax IDs, bank)
- Changes persist to Firebase and sync across devices

---

## 2. Invoice Management

### Invoice Creation
- Multi-section invoice form
- Seller details auto-populated from user profile
- Buyer details: name, contact person, phone, email, address, GST, PAN, VAT, CST, state name, state code
- Invoice number (auto-generated from prefix + counter), invoice date, terms & conditions
- Supports multiple line items per invoice

### Line Items
- Per-item fields: description/particulars, HSN code, carat weight, rate per carat
- Automatic calculations: amount, sub-total, CGST, SGST, IGST, grand total
- State-based tax logic (IGST for inter-state; CGST+SGST for intra-state)
- Amount-in-words conversion
- Add / edit / delete items inline

### Editing
- Load existing invoice data into form
- Modify buyer, details, or items and re-save

### Search & Filter
- Search invoices by buyer name, invoice number, or date range
- Dynamic list filtering

### Deletion
- Delete with confirmation
- Cleans up associated reminders

### Listing & Viewing
- Invoice list with cards (buyer, number, date, total)
- Recent invoices on dashboard
- Full invoice detail view

---

## 3. PDF Generation, Printing & Sharing

### PDF Generation
- Professional invoice PDF matching business template
- Includes seller, buyer, invoice number/date, itemized table with HSN, tax breakdown (CGST/SGST/IGST), grand total, amount in words, bank details, terms

### Sharing
- Share via email client, system share sheet, or direct file share
- Auto-prompt to email after generation when buyer email exists

### Printing
- Print directly to connected printers
- Printer selection and print preview

---

## 4. Email Invoicing
- Send invoices via default email client with PDF attachment
- Pre-filled recipient, subject, and message body
- Accessible from invoice list, invoice form app bar, and post-generation prompt

---

## 5. Reminders & Notifications

### Reminder Management
- Set custom reminders per invoice with date & time
- Multiple reminders per invoice
- Cancel individual or all reminders for an invoice

### Local Notifications
- Exact-time scheduling (timezone-aware)
- Works offline and when app is closed
- Status color coding: red (overdue), orange (due within 24h), blue (future)

### Reminders Screen
- Dedicated list of active reminders, sorted by date
- Quick cancel, refresh, and dashboard shortcut

---

## 6. Inventory Management

### Inventory Dashboard
- Stat cards: total items, total carat weight, total inventory value
- Visual icons and quick navigation

### Items
- Fields: invoice reference, carat weight, price per carat, description, date added, last updated
- Automatic totals, CGST, SGST, and total-with-GST calculation

### CRUD
- Add, edit, delete inventory items with confirmation
- Search by invoice number or description

---

## 7. Purchase Management

### Purchase Tracking
- Fields: seller, broker, size (e.g. C3/A5), total carat, rate per carat, net amount, discount %, payment type (Cash/Bill), due days, buy date, payment date

### Purchase Dashboard
- Summary bar: opening carats, opening amount, profit/loss (color-coded green/red)

### Purchase List & Details
- Searchable list with payment status and remaining carat
- Detail view shows cash-sold, bill-sold, and remaining carat

### Sell-from-Purchase
- Create invoice directly from a purchase
- Auto-populates available carat and payment type
- Validates carat limit; links invoice back to the purchase for tracking

### Purchase Form
- Create/edit purchases
- Auto net-amount calculation from gross and discount
- Date pickers for buy and payment dates

---

## 8. Settings & Customization

### Tax Configuration
- Sliders for CGST, SGST, IGST rates (0–10%)
- Applied to new invoices in real time

### Invoice Numbering
- Custom prefix (e.g. INV), configurable starting number
- Auto-generation for new invoices; counter reset option

### Default Terms
- Default terms & conditions applied to new invoices, editable per invoice

### App Preferences
- Toggle notifications, toggle auto-save drafts
- Persisted locally and to Firebase

### Data Management
- Export all invoices to JSON
- Import invoices from JSON backup
- Reset settings / invoice counter

---

## 9. Data Export & Import
- JSON export including export date, invoice count, and full invoice data
- Timestamped backup filenames
- File picker import with format validation and success/error tracking
- Share backups via email or cloud services

---

## 10. Dashboard & Analytics

### Main Dashboard
- Stat cards: total invoices, total revenue, this-month invoices, this-month revenue
- Recent 5 invoices (tap to edit)
- Quick actions: New Invoice, View All Invoices
- Pull-to-refresh, gradient visual design

### Bottom Navigation
- Dashboard, Purchases, Invoices, Settings

---

## 11. Force Update System
- Automatic version check at startup via `AuthWrapper`
- Compares current version to minimum and latest versions in Firebase Realtime DB
- **Force update dialog**: non-dismissible, blocks app, links to TestFairy download
- **Optional update dialog**: dismissible
- Configurable: min version, min build, latest version, force flag, message, download URL

---

## 12. Business Profile Data

**Company**: name, address, mobile, email, GST, PAN, CST, VAT, IEC
**Bank**: bank name, branch, account number, IFSC
**Buyer**: name, contact person, phone, email, address, GST, PAN, VAT, CST, state name, state code, place of supply

---

## 13. Technical & Platform Features

- **Architecture**: MVVM with Provider / ChangeNotifier
- **Cloud**: Firebase Realtime Database with per-user data isolation, real-time sync
- **Local storage**: SharedPreferences for settings and temporary files
- **Platforms**: Android, iOS, Windows, macOS, Web
- **Localization**: `intl` for date, currency (INR), and number formatting; structured for multi-language
- **UI**: Material Design 3, custom blue theme (#4F8AF4), reusable widgets (`AppBarFactory`, `CustomButton`, `CustomCard`, `CustomSection`, `CustomTextField`, `CustomInfoRow`, `ForceUpdateDialog`), loading states, empty states, portrait lock on mobile

---

## 14. Validation & Error Handling
- Validation for email, password, numeric fields, GST/PAN, bank account, phone, required fields
- Graceful handling of network, Firebase, notification, and import errors
- Data consistency checks on import

---

## 15. Navigation Map

Welcome → Login / Sign-Up → Version Check → Main Shell
Main Shell tabs: Dashboard · Purchases · Invoices · Settings
Additional screens: Profile, Invoice Form, Invoice Details, Purchase Form, Purchase Details, Inventory List, Inventory Form, Reminders, Export/Import
