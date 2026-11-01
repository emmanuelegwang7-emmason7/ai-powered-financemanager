# 💰 SmartFinance AI — Milestone 3 Submission

> An AI-powered personal finance manager built with Flutter.  
> Helping Ugandan students and professionals escape "paycheck-to-paycheck" anxiety — one smart decision at a time.

---

## 📌 Project Overview

SmartFinance AI is a cross-platform mobile application that gives users real-time insight into their daily spending, lets them declare committed expenses, checks their MoMo wallet balance via USSD, and calculates exactly how much is safe to spend — all stored locally on the device with no internet dependency.

**Milestone 3** focused on **Storage, Persistence, and Security**, adding:

- Full local data persistence using `shared_preferences` (survives app restarts)
- Committed expense management (create, read, delete — stored as JSON)
- Smart Safe-to-Spend card (live calculation: MoMo balance − expenses − today's spending)
- MoMo USSD balance check with timestamped persistence
- 7-day spending trend line chart
- Profile photo picker from device gallery
- Animated custom splash screen
- Security controls: no plain-text passwords stored, parameterised data access

---

## 🗂️ Project Structure — Mapping Android Concepts to Flutter

| Android Concept | Flutter Equivalent | Location in This Project |
|---|---|---|
| `AndroidManifest.xml` | `android/app/src/main/AndroidManifest.xml` | Permissions: CALL_PHONE, READ_PHONE_STATE, READ_MEDIA_IMAGES |
| **Activities** | `StatefulWidget` / `StatelessWidget` | `lib/screens/*.dart` |
| **XML Layouts** | Declarative widget trees | `lib/screens/` & `lib/widgets/` |
| `SQLiteOpenHelper` | `shared_preferences` package | `lib/services/finance_store.dart` |
| `SharedPreferences` (Android) | `shared_preferences` (Flutter) | `lib/services/finance_store.dart` |
| `ContentValues` / `Cursor` | `Map<String, dynamic>` + `jsonEncode/Decode` | `finance_store.dart` committed expenses |
| **Resource Files** | `app_theme.dart` | `lib/core/theme/app_theme.dart` |
| **Explicit Intent** | `Navigator.push` with constructors | Login → Home → Profile |
| **Implicit Intent** | `url_launcher` | `settings_screen.dart` |
| `RecyclerView` + `Adapter` | `ListView.builder` | Home, Transaction History, AI Advisor |
| **Platform Channel** | `MethodChannel` | `MainActivity.kt` ↔ `ussd_service.dart` |
| `TelephonyManager.sendUssdRequest` | Kotlin platform channel | `MainActivity.kt` |

---

## 🗺️ Screen Architecture — 9 Screens

| # | Screen | File | Key Role |
|---|--------|------|----------|
| 1 | Splash | `splash_screen.dart` | Animated logo, auto-navigates to Login |
| 2 | Login | `login_screen.dart` | Form validation, lifecycle observer, passes user data |
| 3 | Register | `register_screen.dart` | 4-field form, password match, terms checkbox |
| 4 | Home / Dashboard | `home_screen.dart` | Smart Safe-to-Spend card, MoMo card, transactions |
| 5 | Today's Plan | `todays_plan_screen.dart` | Committed expense list (persistent CRUD) |
| 6 | Transaction History | `transaction_history_screen.dart` | Dynamic list, filter chips, add + delete |
| 7 | AI Advisor | `ai_advisor_screen.dart` | Chat UI, dynamic message list |
| 8 | Profile | `profile_screen.dart` | Gallery photo picker, displays passed user data |
| 9 | Settings | `settings_screen.dart` | Toggles, opens Email app & Browser |
| 10 | Spending Trends | `spending_chart_screen.dart` | 7-day line chart (actual vs planned) |

---

## 🗃️ Full File Structure

```
lib/
├── core/
│   └── theme/
│       └── app_theme.dart                  # AppColors + AppTextStyles (Poppins)
├── screens/
│   ├── splash_screen.dart                  # Animated splash with logo + progress bar
│   ├── login_screen.dart                   # Auth entry, lifecycle observer
│   ├── register_screen.dart                # Registration with full validation
│   ├── home_screen.dart                    # Dashboard hub, PopScope exit dialog
│   ├── todays_plan_screen.dart             # Committed expenses CRUD (persistent)
│   ├── transaction_history_screen.dart     # Dynamic list, filter, FAB add sheet
│   ├── ai_advisor_screen.dart              # Chat UI with typing indicator
│   ├── profile_screen.dart                 # Gallery photo picker + user data
│   ├── settings_screen.dart                # Toggles + url_launcher
│   └── spending_chart_screen.dart          # fl_chart 7-day line chart
├── services/
│   ├── finance_store.dart                  # All SharedPreferences read/write
│   └── ussd_service.dart                   # Dart side of USSD platform channel
└── widgets/
    ├── reusable_transaction_item.dart      # Reusable transaction card
    ├── delete_confirmation_dialog.dart     # Reusable confirm dialog
    ├── app_wide_menu.dart                  # PopupMenuButton AppBar menu
    ├── momo_balance_card.dart              # USSD balance card with PIN dialog
    └── safe_to_spend_card.dart             # Smart live calculation card
android/
└── app/src/main/kotlin/com/example/financemanager/
    └── MainActivity.kt                     # Kotlin USSD platform channel
```

---

## ✅ Milestone 3 — Feature Implementation

### 1. Local Data Persistence (Storage)

All app data is stored on-device using the `shared_preferences` package — the Flutter equivalent of Android's `SharedPreferences` for simple key-value data and `SQLite` for structured records.

**`FinanceStore`** (`lib/services/finance_store.dart`) is the single source of truth. It handles:

| Data | Storage Key | Type |
|------|-------------|------|
| MoMo balance | `momo_balance` | `int` |
| Telecom name | `momo_telecom` | `String` |
| Last checked timestamp | `momo_checked_at` | `String` (ISO 8601) |
| Committed expenses list | `committed_expenses` | `String` (JSON array) |
| Daily spending | `daily_spending_YYYY-MM-DD` | `int` |

Committed expenses are serialised to JSON before saving:
```dart
final encoded = jsonEncode(expenses.map((e) => e.toJson()).toList());
await _prefs.setString('committed_expenses', encoded);
```
And deserialised on read:
```dart
final list = jsonDecode(raw) as List<dynamic>;
return list.map((e) => CommittedExpense.fromJson(e)).toList();
```

This means all expenses survive app restarts, phone reboots, and background kills.

---

### 2. CRUD Operations on Committed Expenses

The Today's Plan screen provides full Create, Read, Update (via delete+re-add), Delete on the committed expenses list:

```dart
// CREATE
await FinanceStore.addCommittedExpense(expense);

// READ
final expenses = FinanceStore.getCommittedExpenses();

// DELETE (confirmed first via AlertDialog)
await FinanceStore.removeCommittedExpense(expense.id);
```

Every delete is confirmed first by the reusable `AlertDialog` — satisfying the rubric requirement that *"Deletes are confirmed first"*.

---

### 3. Smart Safe-to-Spend Calculation

The Home screen card (`safe_to_spend_card.dart`) reads live from `FinanceStore` and calculates:

```
MoMo Balance (USSD, timestamped)
  − Total Committed Expenses (persistent list)
  = Free Balance

Free Balance
  − Today's Spending (resets daily at midnight)
  = SAFE TO SPEND NOW
```

Color coding:
- 🟢 **Green** — above 50% of free balance remaining
- 🟡 **Amber** — 20–50% remaining
- 🔴 **Red** — below 20% or over budget

---

### 4. MoMo USSD Balance Check (Platform Channel)

A Kotlin platform channel (`MainActivity.kt`) calls `TelephonyManager.sendUssdRequest()` — Android API 26+ — to check the user's real wallet balance from MTN Uganda or Airtel Uganda. The result is parsed by a multi-strategy regex parser and saved to `FinanceStore` with a timestamp.

After a successful check, `SafeToSpendCard` refreshes automatically via a `refreshKey` counter passed from `HomeScreen`.

---

### 5. 7-Day Spending Trend (Line Chart)

`SpendingChartScreen` uses `fl_chart` to render two lines:
- **Solid blue line** — actual daily spending from `FinanceStore`
- **Dashed white line** — planned daily allowance (free balance ÷ 7)

A daily breakdown table below the chart shows each day's status (✓ OK / ↑ Over).

---

## 🔐 Security & Privacy

### Security Controls Table

| Risk | Control Applied | Where in the Code |
|------|----------------|-------------------|
| Plain-text passwords stored | Passwords are **never stored** — login is session-only, no persistence of credentials | `login_screen.dart` — no write to store |
| Unauthorised data access | All `FinanceStore` reads are scoped to the current device — no user_id leakage possible in a local-only store | `lib/services/finance_store.dart` |
| USSD PIN exposure | The PIN is used only to form the USSD string at runtime and is **never stored, logged, or written to disk** | `momo_balance_card.dart` `_checkBalance()` |
| Injection via JSON | Committed expense data is serialised with `dart:convert jsonEncode` — no raw string concatenation | `finance_store.dart` `saveCommittedExpenses()` |
| Gallery photo access | `image_picker` uses Android's native photo picker — the app never gets broad file system access | `profile_screen.dart` `_pickImageFromGallery()` |
| External network calls | No user data is ever transmitted to an external server — all data is local-only | All `FinanceStore` methods |

### Data Protection Statement

SmartFinance AI collects only the user's display name and email address for the session — these are passed through widget constructors and are never written to disk or transmitted to any external server. Committed expenses, spending history, and MoMo balance data are stored exclusively in the device's local `SharedPreferences` storage, which is sandboxed to this app by Android's security model and inaccessible to other apps. The app does not require an internet connection for any current feature, and no personal financial data ever leaves the device.

---

## 📴 Offline Behaviour Statement

When the app has no internet connection, it continues to function perfectly. All data operations (creating committed expenses, logging transactions, reading the Safe-to-Spend calculation, and viewing the 7-day spending chart) are performed entirely on the device using `SharedPreferences` local storage. The only feature that requires network connectivity is the MoMo USSD balance check — which uses the mobile phone network (not Wi-Fi/internet) to query the telecom's USSD gateway. The app is fully offline-capable for all data management features.

---

## 📖 M3 Learning Log: Storage, Persistence & Security

### Sources Used

- [shared_preferences package — pub.dev](https://pub.dev/packages/shared_preferences)
- [Flutter local storage documentation](https://docs.flutter.dev/cookbook/persistence/key-value)
- [Android SharedPreferences documentation](https://developer.android.com/training/data-storage/shared-preferences)
- [Android SQLiteOpenHelper documentation](https://developer.android.com/reference/android/database/sqlite/SQLiteOpenHelper)
- [dart:convert library](https://api.dart.dev/stable/dart-convert/dart-convert-library.html)
- [fl_chart package](https://pub.dev/packages/fl_chart)
- [TelephonyManager.sendUssdRequest — Android docs](https://developer.android.com/reference/android/telephony/TelephonyManager#sendUssdRequest)
- [image_picker package](https://pub.dev/packages/image_picker)

---

### What I Learned: Storage and Persistence

**Mapping Android's SQLiteOpenHelper to Flutter:**

In Android, persistent structured data requires implementing `SQLiteOpenHelper` — you override `onCreate()` to define your table schema, `onUpgrade()` to handle migrations, and write separate `insert()`, `query()`, `update()`, and `delete()` methods using `ContentValues` and `Cursor` objects. It is verbose but powerful.

In Flutter, for a student project with moderate data complexity, the `shared_preferences` package offers a simpler path — the equivalent of Android's `SharedPreferences` but extended to handle JSON-serialised objects. I stored the committed expenses list as a JSON string and deserialised it back into typed `CommittedExpense` objects on every read. This pattern — `jsonEncode` on write, `jsonDecode` on read — gives me the structured data behaviour of SQLite with none of the schema management overhead.

The key difference I learned: Android's `SQLiteOpenHelper` is better when you need complex queries (JOIN, GROUP BY, WHERE across multiple columns). `shared_preferences` is better when your data is a flat list or simple key-value pairs and you want zero setup. For a future version of this app with thousands of transactions, I would migrate to `sqflite` (Flutter's SQLite wrapper), but for M3's scope `shared_preferences` is the right choice.

**Keying daily spending by date:**

One pattern I'm particularly pleased with is the daily spending key:
```dart
static String _dailyKey(DateTime date) =>
    'daily_spending_${date.year}-${date.month}-${date.day}';
```
This means yesterday's spending is automatically isolated in a different key from today's. There is no reset logic, no cron job — the data simply exists under a dated key, and today's key always starts at 0 unless written to. This is a clean, bug-free way to implement daily resets without any scheduled task.

**"Remember Me" and session data:**

The `shared_preferences` package also handles the "Remember Me" feature. When the checkbox is ticked on the Login screen, the email value can be saved to preferences and pre-filled on the next launch. This maps directly to how Android's `SharedPreferences.putString("email", value)` is used for the same feature — same concept, almost identical API.

---

### What I Learned: Security and Privacy

The most important security lesson from M3 was about what **not** to store. Passwords are the clearest example. Even though it would be technically easy to save the user's password to `SharedPreferences` for a "Remember Me" login, I did not do this. The reasons are:

1. `SharedPreferences` on Android is stored as a plain XML file in the app's data directory. While it is sandboxed from other apps, on a rooted device it is readable in plain text.
2. Storing a password — even hashed — in a local key-value store is not necessary for the current feature set. The login is session-only.

For the MoMo PIN specifically: the PIN is typed by the user into a dialog, immediately used to construct the USSD string (`*165*5*1*{PIN}#`), and then the string reference is discarded. The PIN is never assigned to a variable that outlives the function call. This is the correct pattern for handling sensitive credentials in memory.

The USSD code itself does contain the PIN in the string briefly. In a production app I would clear that string from memory immediately after the `sendUssdRequest` call using a zeroing pattern, but at the platform channel level in Kotlin the string is passed directly to the Android API without any logging.

---

### Problem I Solved

**The Problem:** After successfully fetching the MoMo balance and saving it to `FinanceStore`, the `SafeToSpendCard` on the Home screen was not updating — it still showed the "no balance checked" state even though the data was now in storage.

**The Root Cause:** `SafeToSpendCard` is a child widget that reads `FinanceStore` only when Flutter rebuilds it. Saving to the store does not automatically trigger a rebuild of the parent `HomeScreen`.

**The Solution:** I added a `refreshKey` integer to `HomeScreen`'s state and passed it as a parameter to `SafeToSpendCard`. When `MomoBalanceCard` successfully saves a balance, it calls the `onBalanceSaved` callback provided by `HomeScreen`, which increments `_cardRefreshKey` via `setState()`. Flutter sees a changed parameter on `SafeToSpendCard` and rebuilds it, which triggers a fresh read from `FinanceStore`. This is the correct Flutter pattern for parent-driven child refreshes without a state management library.

```dart
// HomeScreen passes the key
SafeToSpendCard(refreshKey: _cardRefreshKey)

// MomoBalanceCard triggers the refresh
MomoBalanceCard(onBalanceSaved: _refreshCard)

// _refreshCard increments the key
void _refreshCard() => setState(() => _cardRefreshKey++);
```

---

## 📸 Screenshots — Milestone 3

*(Take these screenshots from your device and place them in `assets/screenshots/`. Delete the placeholder text below and the images will render.)*

![Safe to Spend Card](assets/screenshots/m3_safe_to_spend.png)
*Figure 1: Smart Safe-to-Spend card showing live calculation — MoMo balance minus committed expenses.*

![Today's Plan — Committed Expenses](assets/screenshots/m3_todays_plan.png)
*Figure 2: Today's Plan screen showing the committed expenses list with live free balance calculation.*

![MoMo Balance Card](assets/screenshots/m3_momo_card.png)
*Figure 3: MoMo balance card with telecom selector, PIN dialog, and last-checked timestamp.*

![Spending Chart](assets/screenshots/m3_chart.png)
*Figure 4: 7-day spending trend — actual (blue) vs planned daily allowance (dashed white).*

![Delete Confirmation](assets/screenshots/m3_delete_dialog.png)
*Figure 5: Delete confirmation dialog — expenses are never removed without user confirmation.*

![Data After Restart](assets/screenshots/m3_persistence.png)
*Figure 6: Committed expenses list still present after closing and reopening the app — proving persistence.*

---

## ✅ Milestone 2 — Feature Implementation (Retained)

### 1. Form Validation & Feedback

Every form uses `GlobalKey<FormState>` and `TextFormField` validators.

- **Login:** email format check, minimum 6-character password, password visibility toggle.
- **Register:** name, email, password, confirm-password match, terms checkbox.
- **Today's Plan (M3):** expense name required, amount must be positive, amount cannot exceed remaining free balance (cross-field validation).

On failure, red error text appears inline. On success, a floating green `SnackBar` confirms the action.

### 2. Navigation, Data Passing & Back Button

8 screens connected via `Navigator.push` / `Navigator.pushReplacement`. User email and name are passed from `LoginScreen` → `HomeScreen` → `ProfileScreen` via constructors (Flutter's `Intent.putExtra` equivalent). `PopScope(canPop: false)` on HomeScreen shows an exit confirmation dialog on back press.

### 3. External App Integration

Settings screen uses `url_launcher` to open the native Email app (`mailto:`), Browser (`https://`), and Play Store.

### 4. Dynamic Lists & Reusable Components

`ReusableTransactionItem` widget used on both Home and Transaction History. `showDeleteConfirmationDialog()` reusable helper used in both screens. `PopupMenuButton` app-wide menu with 5 navigation items.

---

## 🛠️ Tech Stack

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | SDK | UI framework |
| dart | ^3.12.1 | Language |
| google_fonts | ^6.1.0 | Poppins typeface |
| url_launcher | ^6.3.1 | Implicit Intent — Email & Browser |
| image_picker | ^1.1.2 | Gallery photo picker for Profile |
| shared_preferences | ^2.3.2 | Local data persistence (M3) |
| fl_chart | ^0.69.0 | 7-day spending line chart (M3) |
| flutter_launcher_icons | ^0.14.3 | Auto-generate app icon sizes |
| flutter_native_splash | ^2.4.3 | Native splash screen config |

---

## 🚀 Running the App

```bash
# 1. Install all dependencies
flutter pub get

# 2. Generate app icons (requires assets/icon/app_icon.png)
dart run flutter_launcher_icons

# 3. Generate native splash screen (requires assets/splash/splash_logo.png)
dart run flutter_native_splash:create

# 4. Run in debug mode on connected device
flutter run

# 5. Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎨 Design System

All colors and text styles are centralised in `lib/core/theme/app_theme.dart`.

| Token | Hex | Usage |
|-------|-----|-------|
| `AppColors.primary` | `#2563EB` | Buttons, active states, USSD card |
| `AppColors.bgGradientStart` | `#0F172A` | Deep navy background |
| `AppColors.bgGradientEnd` | `#6D28D9` | Royal purple gradient end |
| `AppColors.successGreen` | `#10B981` | Income, OK status, success SnackBars |
| `AppColors.errorRed` | `#EF4444` | Expenses, errors, delete actions |

All cards use **glassmorphism**: `BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))` over a `Colors.white.withValues(alpha: 0.08)` container with a subtle white border.

---

## 🤖 AI Tools Declaration

As per Section 4 of the coursework guidelines:

**Kiro AI (Amazon):** Used throughout for architectural planning, Flutter UI generation (glassmorphic design system, USSD platform channel, SharedPreferences data layer, fl_chart integration), and README documentation. All generated code was reviewed, understood, and manually integrated by the student. Every implementation decision — screen architecture, the Safe-to-Spend formula, the date-keyed daily spending pattern, the USSD PIN security approach, the refreshKey pattern — was directed by the student based on their understanding of the problem.

---

*SmartFinance AI © 2026 — Mobile Application Development, Milestone 3*
