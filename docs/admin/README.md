# Carat One — Web Admin Panel

Secure, dependency-free admin console for the Carat One Firebase backend.
Lives under `docs/admin/` alongside the marketing site so both ship together
from GitHub Pages.

Pages: **Login · Dashboard · Users · Website Inquiries · In-App Support ·
Analytics & Performance · Ad Income**.

## What it does

| Page                       | Reads / writes                                              |
| -------------------------- | ----------------------------------------------------------- |
| `index.html` (Login)       | Firebase Auth + reads `/admins/{uid}` to gate access.       |
| `dashboard.html`           | Aggregates all of the below into KPI cards + charts.        |
| `users.html`               | Reads `/users`. Deletes profiles. (Cloud Function for Auth) |
| `inquiries.html`           | Live-reads `/website_inquiries` (from the marketing form).  |
| `support.html`             | Live-reads `/support_tickets` (from the Flutter app).       |
| `analytics.html`           | Reads `/analytics/{yyyy-MM-dd}`. Charts + weekly report.    |
| `ad-income.html`           | Reads / writes `/ad_income/{yyyy-MM}`.                      |

## Security model

Access is enforced in **three** layers — do not skip any of them:

1. **Auth membership** — Only Firebase Auth users whose uid exists under
   `/admins/{uid}` in Realtime Database can sign in. The client checks this
   after `signInWithEmailAndPassword` and signs the user out if the record
   is missing.
2. **RTDB rules** — `database.rules.json` locks down every admin-only path
   (`/admins`, `/users`, `/support_tickets`, `/analytics`, `/ad_income`) to
   authenticated admins. `/website_inquiries` allows unauthenticated
   *creates* (so anon-auth visitors can submit the contact form) but reads
   / updates / deletes remain admin-only.
3. **Cloud Functions** — Anything the Web SDK can't do (list Auth users,
   disable / delete Auth accounts) runs in `functions/index.js` behind
   `assertAdmin()`, which re-verifies `/admins/{uid}` on every call.

There is no other way in. The public HTML files are just static assets; the
config baked into them (`assets/js/firebase.js`) is safe to expose — the
Firebase Web SDK config is **not** a secret, it's a public identifier
whose security is guaranteed entirely by rules on the server.

## First-time setup

### 1. Create your first admin

Open the Firebase Console → Authentication → **Add user** with your email +
a strong password. Then open Realtime Database and add this record:

```
/admins/{your-uid}/name: "Rakesh Shah"
/admins/{your-uid}/role: "owner"
```

The `owner` role is required to create *other* admins (see the rules — only
owners can write into `/admins`). Once you have one owner, add more from
the console the same way, using `role: "admin"` or `role: "analyst"` for
non-owner accounts.

### 2. Deploy the RTDB rules

```powershell
# from repo root
firebase login
firebase use caratone-1098a
firebase deploy --only database --config docs/admin/firebase.json
```

Or paste the contents of `database.rules.json` into
Firebase Console → Realtime Database → **Rules** and hit **Publish**.

### 3. (Optional) Deploy the Cloud Functions

These are only required for Auth-listing / Auth-disable actions in the
Users page. Blaze plan required.

```powershell
cd docs/admin/functions
npm install
cd ..
firebase deploy --only functions --config firebase.json
```

Region defaults to `asia-south1` — change in `functions/index.js` if you
want the callables somewhere else.

### 4. Ship the site

The admin panel is just static HTML/JS. Committing `docs/admin/*` and
pushing publishes it to whatever GitHub Pages URL your marketing site
uses (`https://<your-github-user>.github.io/<repo>/admin/`, or your
custom domain).

> **⚠️ URL is publicly reachable.** Anyone can browse to the login page —
> RTDB rules are what actually protect the data. Do **not** relax them.

## Data shapes

### `/website_inquiries/{pushId}` — from the marketing form

```json
{
    "name": "Rakesh Shah",
    "email": "rakesh@company.com",
    "phone": "+91 98xxxxxxxx",
    "subject": "Sales enquiry",
    "message": "Interested in your GST invoicing…",
    "status": "new",              // new | in_progress | closed
    "source": "website",
    "page": "/",
    "referrer": "https://google.com/",
    "userAgent": "…",
    "createdAt": 1735293421000,
    "createdAtServer": 1735293421100
}
```

### `/support_tickets/{pushId}` — from the Flutter app

Write this from a "Contact support" screen inside the app:

```dart
await FirebaseDatabase.instance.ref('support_tickets').push().set({
    'uid': FirebaseAuth.instance.currentUser!.uid,
    'email': user.email,
    'userName': profile.userName,
    'subject': subjectController.text,
    'message': messageController.text,
    'category': 'billing',   // free-form
    'status': 'open',
    'createdAt': DateTime.now().millisecondsSinceEpoch,
});
```

The admin panel adds `/replies/{pushId}` items when the operator replies.

### `/analytics/{yyyy-MM-dd}/{pushId}` — from `AnalyticsService`

Handled automatically by `lib/services/analytics_service.dart`. Event types:

* `install` — first launch of a new build
* `session_start` — every cold launch
* `session_end` — app paused / detached (has `extras.duration` in seconds)
* `feature` — call `AnalyticsService.instance.logFeature('invoice_create')`
* `crash` — auto-fired by `FlutterError.onError`
* `purchase` — call `AnalyticsService.instance.logPurchase(…)`

### `/ad_income/{yyyy-MM}` — admin-entered

```json
{
    "month": "2026-07",
    "banner": 4523.4,
    "interstitial": 8921.0,
    "rewarded": 1204.6,
    "other": 0,
    "total": 14649.0,
    "notes": "Diwali bump",
    "updatedAt": 1735293421000
}
```

## Design system

The admin panel mirrors the marketing site's design tokens
(`--bg-0..2`, `--primary`, `--accent`, `--violet`, `--rose`, `--gold`,
Plus Jakarta Sans + Instrument Serif). Shared CSS lives in
`assets/css/admin.css`; all animations (aurora blobs, custom cursor,
card spotlight, reveal-on-scroll, KPI hover-lift, italic serif shimmer,
skeletons, toasts, modals) are implemented once there and shared across
every page.

## File layout

```
docs/
├── admin/
│   ├── index.html                 # Login
│   ├── dashboard.html
│   ├── users.html
│   ├── inquiries.html
│   ├── support.html
│   ├── analytics.html
│   ├── ad-income.html
│   ├── database.rules.json        # RTDB security rules
│   ├── firebase.json              # deploy target
│   ├── functions/
│   │   ├── index.js               # Callable Auth-admin functions
│   │   └── package.json
│   ├── assets/
│   │   ├── css/admin.css
│   │   └── js/
│   │       ├── firebase.js        # SDK init (config is public)
│   │       ├── auth-guard.js      # admin gating
│   │       ├── shell.js           # sidebar/topbar renderer
│   │       ├── ui.js              # cursor, aurora, toasts, formatters
│   │       ├── charts.js          # tiny SVG line/bar/spark
│   │       └── data.js            # RTDB path helpers
│   └── README.md                  # you are here
└── index.html                     # Marketing site + contact form
```
