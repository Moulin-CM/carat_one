# 📋 CaratOne Subscription Feature — Complete Implementation Guide

> **Status:** Planning / Design phase
> **App:** CaratOne (Flutter — jewelry/diamond trader business management)
> **Stack already in place:** Firebase Auth + Realtime DB, AdMob (`google_mobile_ads`), MVVM with Provider

---

## Table of Contents

1. [Overall Flow (User Journey)](#1-overall-flow-user-journey)
2. [Recommended Plan Tiers](#2-recommended-plan-tiers)
3. [Feature Gating Matrix](#3-feature-gating-matrix)
4. [The "Watch Video" Rewarded-Ad Flow](#4-the-watch-video-rewarded-ad-flow-income-backstop)
5. [Trial Mechanics (Anti-Abuse)](#5-trial-mechanics-anti-abuse)
6. [Billing Platform Choice](#6-billing-platform-choice)
7. [Restriction Enforcement Points](#7-restriction-enforcement-points)
8. [UI/UX Touches](#8-uiux-touches)
9. [Edge Cases & Policies](#9-edge-cases--policies)
10. [Data Model — New Firebase Nodes](#10-data-model--new-firebase-nodes)
11. [New Files / Components to Add](#11-new-files--components-to-add)
12. [Rollout Phases](#12-suggested-rollout-phases)
13. [Suggestions / Watch-outs](#13-suggestions--watch-outs)
14. [Next Steps](#14-next-steps)

---

## 1. Overall Flow (User Journey)

```
New Sign-up
    │
    ▼
🎁 Free Trial — 7 days, ALL features unlocked
    │
    ▼ (Day 8)
Trial Expired ──► Tries to add Purchase/Sell ──► Paywall Dialog
                                                    │
                              ┌─────────────────────┼─────────────────────┐
                              ▼                     ▼                     ▼
                          Buy Plan              Watch Video           Cancel
                              │                     │                     │
                              ▼                     ▼                     ▼
                    Pro / Business /          Rewarded Ad →         Stay restricted
                    Starter monthly           +1 entry credit
                    (auto-renew)
```

---

## 2. Recommended Plan Tiers

We recommend **3 tiers** (industry standard — gives upgrade headroom without analysis paralysis). All monthly, auto-renew.

| Plan | Price (₹/mo) | Target user |
|------|------|-------------|
| **Starter** | ₹149 | Solo trader, low volume |
| **Pro** ⭐ (most popular) | ₹299 | Active trader (default highlight) |
| **Business** | ₹599 | Established firm, multi-device |

> **Pricing tip:** keep Pro at **~2× Starter** so it always looks like the "value" choice. Business at 2× Pro signals "premium".

---

## 3. Feature Gating Matrix

| Feature | Free Trial (7d) | Starter ₹149 | Pro ₹299 | Business ₹599 | After trial (no plan) |
|---|---|---|---|---|---|
| **Add Purchase** | ✅ Unlimited | 30/month | ✅ Unlimited | ✅ Unlimited | ❌ Blocked (or +1 per ad) |
| **Add Sell (Invoice)** | ✅ Unlimited | 30/month | ✅ Unlimited | ✅ Unlimited | ❌ Blocked (or +1 per ad) |
| View existing Purchases/Sells | ✅ | ✅ | ✅ | ✅ | ✅ Read-only |
| Edit / Delete entries | ✅ | ✅ | ✅ | ✅ | ❌ |
| Inventory CRUD | ✅ | ✅ | ✅ | ✅ | ❌ Add blocked |
| Expense Ledger | ✅ | ✅ | ✅ | ✅ | ❌ Add blocked |
| Withdrawals | ✅ | ✅ | ✅ | ✅ | ❌ Add blocked |
| Buy/Sell Report | ✅ | ✅ Monthly only | ✅ All ranges | ✅ All ranges | ✅ View past |
| Brokerage Report | ✅ | ❌ | ✅ | ✅ | View only |
| Expense Statement Report | ✅ | ✅ Monthly only | ✅ All ranges | ✅ All ranges | View only |
| PDF Print/Share/Email | ✅ | 10/month | ✅ Unlimited | ✅ Unlimited | ❌ |
| Reminders | ✅ | 5 active | ✅ Unlimited | ✅ Unlimited | View only |
| JSON Export/Import | ✅ | Export only | ✅ Both | ✅ Both | ❌ |
| Multi-device sync | ✅ | 1 device | 2 devices | ✅ Unlimited | n/a |
| AdMob banner ads | Hidden | Visible | Hidden | Hidden | Visible |
| Priority support | — | — | — | ✅ | — |
| **"Watch Ad" entry top-up** | n/a | n/a | n/a | n/a | ✅ +1 per ad, max 5/day |

> **Why these splits:** "Add Purchase / Add Sell" is the money-making feature — that's the primary paywall trigger. Reports/PDFs are the natural Pro upsell. Multi-device is the Business hook.

---

## 4. The "Watch Video" Rewarded-Ad Flow (Income Backstop)

This is the **key insight** — keeps revenue flowing from non-payers via AdMob.

### Rules

- 1 rewarded ad watched → **+1 entry credit** (Purchase OR Sell)
- Daily cap: **5 ads/day per user** (prevents abuse, protects subscription revenue)
- Credits expire at midnight (don't accumulate — pushes users to subscribe)
- Show a clear counter: *"You have 3 free entries today. Tap Watch Video for 1 more."*
- Track ad-watch count server-side (Firebase) so users can't cheat by reinstalling

### Why a daily cap matters

Without it, power users will **never** subscribe — they'll just watch 30 ads at the start of the month. The cap forces the math: a user adding 10 entries/day finds it easier to pay ₹149 than watch 50 ads.

---

## 5. Trial Mechanics (Anti-Abuse)

### ❌ What NOT to do
- Don't store trial start in `SharedPreferences` (wiped on uninstall → infinite trials)
- Don't trust device clock (`DateTime.now()`) — easy to fake by changing system time

### ✅ What to do

Store on Firebase under `users/{uid}/subscription/`:

```json
{
  "trialStartedAt": "<Firebase ServerValue.timestamp>",
  "trialEndsAt":    "<trialStartedAt + 7 days>",
  "plan": "trial | starter | pro | business | expired",
  "platform": "android | ios",
  "purchaseToken": "...",
  "expiryDate": "<epoch ms>",
  "autoRenewing": true,
  "graceUntil": "<epoch ms>",
  "lastVerifiedAt": "<epoch ms>"
}
```

Use **Firebase server time** for the "is trial active?" check:

```dart
final offsetSnap = await FirebaseDatabase.instance.ref('.info/serverTimeOffset').get();
final serverOffset = (offsetSnap.value as num?)?.toInt() ?? 0;
final nowMs = DateTime.now().millisecondsSinceEpoch + serverOffset;
final isTrialActive = nowMs < trialEndsAt;
```

### Reinstall abuse mitigation

- Same Firebase UID = same trial state (already solved by tying to email/auth)
- Same email re-signup → already-used trial flag persists
- New email per trial: accept this leakage **or** add phone-OTP verification later

---

## 6. Billing Platform Choice

| Platform | Plugin | Notes |
|---|---|---|
| **Android** | `in_app_purchase: ^3.x` (Google Play Billing v6) | Required by Play Store policy for digital subscriptions |
| **iOS** | Same plugin (uses StoreKit 2) | Required by App Store policy |
| **Windows / macOS / Web** | Skip subscription on these — show *"Subscribe via mobile app"* | Play/App Store mandates don't apply outside mobile |

### Server-side receipt verification is mandatory

Never trust the client. Use Firebase Cloud Functions:

- **Android:** Google Play Developer API → `purchases.subscriptionsv2.get`
- **iOS:** App Store Server API → `inApps/v1/subscriptions/{originalTransactionId}`
- Verify on every app launch + on real-time developer notifications (RTDN webhook)

> **Indian compliance note:** Subscriptions ≥ ₹15,000/year mandate UPI Autopay e-mandate. Our plans are well below that, but Google Play handles UPI Autopay setup for us — no extra work.

---

## 7. Restriction Enforcement Points

Wrap the **entry points** (not the whole screens) so users can still *view* old data:

| Existing screen | Where to gate |
|---|---|
| `views/add_purchase` (FAB / button) | Tap on "+" → check `SubscriptionService.canAddPurchase()` → if false, show paywall dialog |
| `views/create_invoice` (FAB / button) | Same — `canAddSell()` |
| `views/inventory` add | Same |
| `views/expense` add credit/debit | Same |
| `views/withdrawal` add | Same |
| `views/reminders` add | Same |
| Report period dropdown (Starter) | Disable "Yearly"/"Custom", show lock icon |
| PDF generate button | Decrement quota, then allow |

Single source of truth: a `SubscriptionService` + `SubscriptionViewModel` (Provider) that exposes `canAddPurchase`, `canAddSell`, `quotaRemaining`, `daysLeftInTrial`, etc.

---

## 8. UI/UX Touches

### 1. Trial countdown banner on Dashboard
*"⏳ 3 days left in your free trial. See plans →"*
(Subtle through day 5, urgent red on day 6+)

### 2. Paywall dialog (matches the spec)

```
┌──────────────────────────────────────┐
│ 🔒 Free trial finished               │
│                                      │
│ Subscribe to continue adding         │
│ Purchases and Sells, or watch a      │
│ short video for 1 free entry.        │
│                                      │
│ Today's free entries: 2 / 5          │
│                                      │
│  [📺 Watch Video]   [✨ Buy Plan]    │
└──────────────────────────────────────┘
```

### 3. Plans screen
3 cards side-by-side, "Most Popular" badge on Pro, monthly price big, feature checklist below.

### 4. "Premium" badge
In app bar for paid users (small dopamine hit, social proof).

### 5. Renewal reminder
Push notification 2 days before renewal so users don't feel surprise-charged → reduces refund/chargeback rate.

---

## 9. Edge Cases & Policies

| Scenario | Handling |
|---|---|
| Payment fails on renewal | 3-day **grace period** → app stays unlocked, banner: *"Update payment method"*; after grace → restricted |
| User cancels mid-cycle | Access until `expiryDate`, then drop to restricted |
| Refund issued | Cloud Function listens to RTDN → immediately sets `plan: expired` |
| User on plane / offline | Last verified state cached for 7 days; after that, requires online check |
| Existing users (rolled out today) | **Grandfather decision:** give them all a fresh 7-day trial starting on update install — generates good will + lets them experience the full app before deciding |
| Plan downgrade (Pro → Starter) | Apply at next renewal, not immediately |
| Family sharing / shared device | Tied to Firebase UID, not device — works automatically |
| GST on subscription | Google Play / App Store handles GST collection & invoicing in India — we receive the net amount |

---

## 10. Data Model — New Firebase Nodes

```
users/{uid}/
  subscription/
    plan: "trial" | "starter" | "pro" | "business" | "expired" | "grace"
    trialStartedAt: <serverTimestamp>
    trialEndsAt: <ms>
    expiryDate: <ms>              // null for trial
    autoRenewing: bool
    purchaseToken: string         // Android
    originalTransactionId: string // iOS
    platform: "android" | "ios"
    graceUntil: <ms>
    lastVerifiedAt: <ms>

  usage/
    {YYYY-MM-DD}/
      purchasesAdded: int
      sellsAdded: int
      adsWatched: int
      adCreditsRemaining: int
      pdfsGenerated: int

  subscriptionHistory/
    {pushId}/
      event: "trial_started" | "subscribed" | "renewed" | "cancelled" | "expired" | "refunded"
      plan: string
      timestamp: <serverTimestamp>
      amount: number
```

---

## 11. New Files / Components to Add

```
lib/
├── models/
│   ├── subscription_plan.dart         # enum + plan metadata (price, name, perks)
│   ├── subscription_status.dart       # current user state
│   └── usage_quota.dart
├── services/
│   ├── subscription_service.dart      # Firebase + Play/App Store coordinator
│   ├── billing_service.dart           # in_app_purchase wrapper
│   ├── quota_service.dart             # daily counters
│   └── rewarded_ad_credit_service.dart
├── viewmodels/
│   └── subscription_viewmodel.dart
├── views/
│   ├── plans_screen.dart              # the 3-tier picker
│   ├── trial_banner.dart              # dashboard banner
│   └── paywall_dialog.dart            # the "Buy Plan / Watch Video" dialog
└── widgets/
    └── premium_lock_overlay.dart      # for locked features

functions/                              # Firebase Cloud Functions (new)
├── verifyAndroidReceipt.ts
├── verifyIosReceipt.ts
└── playStoreRTDNWebhook.ts            # real-time renewal notifications
```

### New `pubspec.yaml` dependencies (planned)

```yaml
in_app_purchase: ^3.2.0
crypto: ^3.0.3            # for receipt hashing if needed
```

---

## 12. Suggested Rollout Phases

| Phase | Scope | Why |
|---|---|---|
| **Phase 1** | Add `SubscriptionService` + Firebase schema + trial countdown banner. **No restrictions yet** — just observe. | Risk-free shadow rollout; collects real trial-end data |
| **Phase 2** | Wire `in_app_purchase`, build Plans screen, server verification | Backend hardened before any user pays |
| **Phase 3** | Add paywall dialog + "Watch Video" rewarded-ad flow | Soft launch — quotas low at first |
| **Phase 4** | Enforce restrictions on Add Purchase / Add Sell | The actual revenue switch — flip after 1 week of Phase 3 telemetry |
| **Phase 5** | Tier-specific limits (PDF count, multi-device, reports) | Polish — drives Starter→Pro upgrades |

---

## 13. Suggestions / Watch-outs

1. **Don't paywall existing users immediately** — they'll uninstall. Give them a 7-day trial on update.
2. **Show the price in INR with ₹** — users are India-focused; "$1.99" feels foreign.
3. **Highlight Pro as "Most Popular"** — anchoring effect; most pick the middle option.
4. **Avoid yearly plans for now** ✅ (monthly recurring revenue is more predictable for a young app, and yearly creates refund-risk concentration).
5. **Translate the paywall dialog** if there are Hindi/Gujarati users — conversion lift can be 20–40%.
6. **Add a "Restore Purchases" button** on the Plans screen — Apple **requires** this; Google strongly recommends it.
7. **Track funnel events** in Firebase Analytics: `trial_started`, `paywall_shown`, `paywall_dismissed`, `ad_watched_for_credit`, `plan_selected`, `purchase_completed`, `purchase_failed`. We need this data to tune prices later.
8. **Quota reset timezone:** reset daily counters at user's local midnight (use IST for India), not UTC — feels fairer.
9. **Don't gate the "View" of old data** ever — even after subscription lapses. Locking users out of *their own data* triggers refund chargebacks and 1-star reviews.
10. **Privacy Policy + Terms must be updated** before launch — Play Store rejection risk otherwise. Add a "Subscription Terms" section explaining auto-renew, cancellation via Play Store, no refund for unused time.

---

## 14. Next Steps

If this plan is approved, the recommended kickoff is:

1. **Phase 1 implementation** — `SubscriptionService` + Firebase schema + trial countdown banner (read-only, no restrictions yet)
2. After that lands, move to **Phase 2** (wire `in_app_purchase`)

### Open decisions to confirm

- [ ] Plan tier names + prices (Starter ₹149 / Pro ₹299 / Business ₹599)?
- [ ] Daily ad-credit cap (proposed: 5/day)?
- [ ] Existing-user grandfather policy (proposed: fresh 7-day trial on update)?
- [ ] Grace period on payment failure (proposed: 3 days)?
- [ ] Localization — paywall in Hindi/Gujarati at launch, or English-only first?

---

*Document version: 1.0 — Initial draft*
*Last updated: 2026-05-07*
