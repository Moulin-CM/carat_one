# Invoice Generator - CaratOne

A modern, cross-platform invoice generator app built with Flutter and Firebase. Create professional invoices with automatic tax calculations, user authentication, and cloud storage.

## Features

### Core Functionality
- **Invoice Generation**: Create professional invoices with customizable buyer and seller details
- **Multiple Items Support**: Add multiple items with HSN codes, carat, and rates
- **Automatic Tax Calculations**: CGST, SGST, and IGST calculations based on tax rates
- **Amount in Words**: Automatic conversion of amounts to words
- **PDF Generation**: Generate and share PDF invoices
- **Invoice Management**: View, edit, and delete saved invoices
- **Inventory Management**: Manage diamond inventory with carat tracking, price per carat, and total value calculations
- **Inventory Dashboard**: View comprehensive statistics including total items, total carat, total value, and monthly trends

### User Features
- **User Authentication**: Secure sign-up and login with Firebase Authentication
- **User Profiles**: Complete user profile management with company details, tax information, and bank details
- **Multi-step Sign-up**: Organized sign-up process with validation
- **Session Management**: Automatic session handling and routing
- **Cloud Storage**: Invoices stored securely in Firebase Realtime Database
- **User-specific Data**: Each user only sees and manages their own invoices

### Technical Features
- **MVVM Architecture**: Clean, maintainable code structure
- **Firebase Integration**: Authentication and Realtime Database
- **Force Update System**: Automatic version checking and update prompts via Firebase
- **Responsive UI**: Modern, premium UI design with gradient cards
- **Form Validation**: Comprehensive client-side validation
- **Cross-platform**: Works on Android, iOS, Windows, and macOS

## Project Structure

```
lib/
├── models/              # Data models (Invoice, Inventory, User Profile)
├── views/               # UI screens (Views)
│   ├── auth/           # Authentication views
│   ├── invoice/        # Invoice views
│   ├── inventory/      # Inventory views
│   └── profile/        # Profile view
├── viewmodels/          # ViewModels (Business logic)
├── services/            # Services (Firebase, Storage, PDF)
└── main.dart           # App entry point
```

## Setup

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Firebase account
- Platform-specific development tools:
  - **Android**: Android Studio with Android SDK
  - **iOS**: Xcode (macOS only)
  - **Windows**: Visual Studio with Windows SDK
  - **macOS**: Xcode

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)

2. Add your app to the Firebase project:
   - **Android**: Add Android app and download `google-services.json`
   - **iOS**: Add iOS app and download `GoogleService-Info.plist`
   - **Web**: Add Web app (optional)

3. Place the configuration files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

4. Enable Firebase Authentication:
   - Go to Authentication > Sign-in method
   - Enable Email/Password authentication

5. Set up Firebase Realtime Database:
   - Create a Realtime Database
   - Set up security rules (see below)

6. Generate `firebase_options.dart`:
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```

### Firebase Realtime Database Rules

```json
{
  "rules": {
    "app_version": {
      ".read": true,
      ".write": false
    },
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid",
        "profile": {
          ".read": "$uid === auth.uid",
          ".write": "$uid === auth.uid"
        },
        "invoices": {
          ".read": "$uid === auth.uid",
          ".write": "$uid === auth.uid",
          "$invoiceId": {
            ".read": "$uid === auth.uid",
            ".write": "$uid === auth.uid"
          }
        },
        "inventory": {
          ".read": "$uid === auth.uid",
          ".write": "$uid === auth.uid",
          "$itemId": {
            ".read": "$uid === auth.uid",
            ".write": "$uid === auth.uid"
          }
        }
      }
    }
  }
}
```

**Note**: `app_version` should be readable by everyone (no authentication required) so the app can check versions before login. However, writing should be restricted (only admins).

### Force Update Setup

The app includes a force update feature that checks for new versions on startup. To set this up:

1. **Create `app_version` node** in Firebase Realtime Database with the following structure:
   ```json
   {
     "minRequiredVersion": "1.0.2",
     "minRequiredBuild": 2,
     "latestVersion": "1.0.3",
     "latestBuild": 5,
     "forceUpdate": true,
     "updateMessage": "A new version is available. Please update to continue.",
     "updateUrl": "https://testfairy.com/app/download/YOUR_APP_ID"
   }
   ```

2. See [FORCE_UPDATE_SETUP.md](FORCE_UPDATE_SETUP.md) for detailed setup instructions and troubleshooting.

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd invoice_generator
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Building for Production

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

## Usage

1. **Sign Up**: Create a new account with your company details
2. **Sign In**: Login to your account
3. **Create Invoice**: 
   - Fill in buyer details
   - Enter invoice number and dates
   - Add items (particular, HSN code, carat, rate)
   - Review totals and tax calculations
   - Generate PDF invoice
4. **Manage Invoices**: View, edit, share, or delete saved invoices
5. **Profile**: View and edit your profile information

## Architecture

The app follows **MVVM (Model-View-ViewModel)** architecture:

- **Models**: Data structures (`InvoiceModel`, `UserProfileModel`)
- **Views**: UI components (Flutter widgets)
- **ViewModels**: Business logic and state management (using `ChangeNotifier`)
- **Services**: External services (Firebase, Storage, PDF generation)

State management is handled using the `Provider` package.

## Dependencies

- `firebase_core`: Firebase core functionality
- `firebase_auth`: User authentication
- `firebase_database`: Realtime Database
- `provider`: State management
- `pdf`: PDF generation
- `printing`: PDF printing and sharing
- `intl`: Internationalization and date formatting
- `shared_preferences`: Local storage
- `package_info_plus`: App version information for force update feature

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
