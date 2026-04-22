# CaratOne – Web Setup Guide

The project originally had no `web/` folder. This has now been fixed.
Follow the steps below to run it on web.

---

## Step 1 – One-time web platform registration

Open terminal inside the project folder and run:

```bash
cd carat_one
flutter create --platforms=web .
```

This generates the final `web/index.html`, `flutter.js`, and icons.
It will NOT overwrite your `lib/` code.

---

## Step 2 – Get dependencies

```bash
flutter pub get
```

---

## Step 3 – Run on web

```bash
flutter run -d chrome
```

Or for a production build:

```bash
flutter build web --release
```

Then serve the `build/web/` folder with any web server.

---

## Step 4 – Firebase web config (REQUIRED)

Add your Firebase web config to `web/index.html` just before `</body>`:

```html
<!-- Firebase SDK -->
<script type="module">
  import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.x.x/firebase-app.js';
  // paste your firebaseConfig here from Firebase Console → Project Settings → Web
</script>
```

Or run:
```bash
flutterfire configure
```
to regenerate `lib/firebase_options.dart` with web support included.

---

## Notes

- PDF generation on web opens the browser's print dialog (no file save dialog).
- Push notifications are disabled on web (not supported by flutter_local_notifications).
- All other features (auth, purchases, invoices, Firebase sync) work on web.
