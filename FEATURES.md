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

## 2. Invoice Management (Sales)

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

### Search & Listing
- Search invoices by buyer name, invoice number, or date range
- List view with cards showing status and totals
- Full invoice detail view with editing capabilities

---

## 3. Purchase Management

### Purchase Tracking
- Fields: seller, broker, size (e.g. C3/A5), total carat, rate per carat, net amount, discount %, payment type (Cash/Bill), due days, buy date, payment date

### Purchase Dashboard
- Summary bar: opening carats, opening amount, profit/loss (color-coded)
- Real-time stock tracking: remaining carat per purchase lot

### Sell-from-Purchase
- Create invoice directly from a purchase entry
- Links sales to specific stock lots for precise inventory tracking
- Validates available carat limits

---

## 4. Finance & Ledger Management

### Expense Tracking (Ledger)
- Record Credit and Debit entries
- Manual "Opening Amount" adjustment for initial balance
- Real-time balance calculation
- **Constraint**: Debits cannot exceed available balance (prevents negative ledger)
- Dismissible entries with deletion confirmation

### Pre-mature Withdrawals
- Track money taken out of the business before maturity
- Fields: person name, amount, taken date, expected return date
- Mark as "Returned" when funds are back
- Deducted from Net Profit calculations until returned

---

## 5. Advanced Business Reporting

### Period Modes
- All reports support **Monthly**, **Yearly**, and **Custom Date Range** filters.

### Expense Statement
- Itemized list of all ledger entries for a period
- Net credit/debit summary
- Grouped by day for easy auditing

### Buy / Sell Report
- Side-by-side comparison of total purchases vs. total sales
- Comparison of total carats bought vs. sold
- Calculation of Net Profit/Loss (Sell - Buy) for the selected period

### Brokerage Report
- Aggregated data per broker
- Shows total brokerage charges across all purchases and sales
- Drill-down into individual entries per broker
- Tracks buy count, sell count, and total carats handled per broker

---

## 6. Inventory Management

### Inventory Dashboard
- Stat cards: total items, total carat weight, total inventory value, average price per carat
- Monthly stock acquisition summary

### CRUD Operations
- Fields: invoice reference, carat weight, price per carat, description, date
- Automatic GST and total value calculations
- Search by invoice number or description

---

## 7. PDF Generation, Printing & Sharing

### Professional PDFs
- **Invoices**: Tax-compliant layout with HSN, bank details, and terms.
- **Expense Statements**: Professional ledger reports.
- **Buy/Sell Reports**: Business performance summaries.
- **Brokerage Reports**: Detailed broker commission statements.

### Output Actions
- **Print**: Direct printing with selection and preview.
- **Share**: System share sheet for WhatsApp, Email, etc.
- **Email**: Automatic attachment for buyer invoices.

---

## 8. Reminders & Notifications

### Reminder Management
- Set multiple custom reminders per invoice
- Status color coding: Red (Overdue), Orange (Due within 24h), Blue (Future)
- Local notifications that work offline and when the app is closed

---

## 9. Settings & Customization

### Configuration
- **Tax**: Adjustable CGST, SGST, IGST rates.
- **Invoicing**: Custom prefix and auto-increment starting number.
- **Terms**: Global default terms and conditions.

### Data Management
- Full JSON Export/Import for backups.
- Reset options for settings and counters.

---

## 10. Dashboard & Analytics

### Unified View
- **Quick Stats**: Total Sells, Total Purchases, Net Profit/Loss, Remaining Carat.
- **Finance Hub**: Quick access to Expenses, Withdrawals, and all Reports.
- **Recent Activity**: List of latest sells for quick access.
- **Quick Actions**: "Sell" and "All Sells" shortcuts.

---

## 11. Force Update System
- Version check at startup via Firebase Realtime DB.
- Force update blocks app for critical versions; optional update for minor releases.
- Links to latest download source.

---

## 12. Technical Specifications

- **Architecture**: MVVM with Provider
- **Cloud**: Firebase Realtime Database (Sync & Persistence)
- **Security**: Per-user data isolation
- **Platforms**: Android, iOS, Windows, macOS, Web
- **Localization**: INR currency formatting, metric carat units

---

## 13. Navigation Map

**Login/Sign-Up** → **Dashboard**
- **Finance**: Expenses · Withdrawals · Buy/Sell Report · Brokerage Report
- **Inventory**: Stock Dashboard · Item List · Add Stock
- **Purchases**: Purchase List · Purchase Details · Add Purchase
- **Invoices**: Invoice List · Invoice Details · Create Invoice
- **Settings**: Profile · Tax Settings · Export/Import · Reminders
