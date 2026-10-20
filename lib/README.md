# SmartFinance AI - Milestone 1 Submission

## Project Overview
SmartFinance AI is a prescriptive, AI-powered personal finance tracker designed to solve the "paycheck-to-paycheck" anxiety for Ugandan students and professionals by calculating a dynamic daily "Safe-to-Spend" limit.

## Part C: Project Build & Structure

### Minimum SDK and Justification
- **Minimum SDK:** Android API Level 21 (Android 5.0 Lollipop).
- **Why:** API 21 covers over 95% of active Android devices in Uganda. It supports modern Flutter features and Material Design 3, ensuring the app runs smoothly on older budget smartphones commonly used by students.

### Project Structure (Mapping Android Concepts to Flutter)
As per the course requirement to apply Android concepts to a cross-platform framework, here is the mapping of the project structure:
1. **Manifest (`android/app/src/main/AndroidManifest.xml`):** Defines app permissions (Internet) and the main launcher activity.
2. **Java/Kotlin Classes (`lib/screens/`):** In Flutter, UI and logic are combined in Dart files. `login_screen.dart`, `register_screen.dart`, and `home_screen.dart` act as the equivalent of Android Activities/Fragments.
3. **Layout Files (`lib/screens/`):** Instead of XML layouts, Flutter uses declarative Dart Widgets. I used `Stack` (equivalent to `FrameLayout`) to layer glassmorphism effects, and `Column`/`Row` (equivalent to `LinearLayout`) to arrange inputs.
4. **Resources (`lib/core/theme/app_theme.dart`):** Satisfies the requirement to "keep text and colours in resource files". All colors and typography are defined here, preventing hard-coded values.
5. **Gradle Scripts (`android/app/build.gradle` & `pubspec.yaml`):** `build.gradle` handles native Android dependencies, while `pubspec.yaml` manages Flutter/Dart packages.
6. **Connecting Views to Code:** Instead of `findViewById`, I used `TextEditingController` and `GlobalKey<FormState>` to connect input fields to validation logic.

### Layouts, Controls, and Adapters
- **Nested Layouts:** I used a `Stack` (FrameLayout) as the root to layer the background gradient, with a `Column` (LinearLayout) nested inside to stack the glassmorphic form fields.
- **Choice Controls:** Implemented a `Checkbox` for "Remember Me" on Login, and a `DropdownButton` (equivalent to Android's `Spinner`) on the Home screen to filter transactions.
- **Adapter:** Implemented `ListView.builder` on the Home screen. This is the exact Flutter equivalent of Android's `RecyclerView`/`Adapter`, efficiently rendering the dynamic list of sample financial transactions.

### Screen Testing
- The app was tested in **Portrait** and **Landscape** orientations. The `SingleChildScrollView` ensures forms do not overflow when rotated.
- Tested on two screen configurations: Pixel 4 API 33 (Emulator) and [Insert your physical phone model, e.g., Samsung A14].
- **APK Installation:** The app was successfully built as a signed APK and installed on a physical Android device.

*(Insert Screenshot of App on Emulator here)*
*(Insert Screenshot of App on Physical Phone here)*
*(Insert Screenshot of App in Landscape Mode here)*

---

## Part D: Event Handling & Validation

### Validation Rules
1. **Email Field:** Cannot be empty. Must contain an "@" symbol and a "." (dot).
2. **Password Field:** Cannot be empty. Must be at least 6 characters long.
3. **Feedback:** If validation fails, red error text appears directly below the specific input field. If successful, a green SnackBar displays a personalized welcome message (e.g., "Welcome back, Emmanuel!").

### User Actions Implemented
1. **Button Tap:** Tapping "Login" triggers validation and navigation.
2. **Checkbox Toggle:** Tapping "Remember me" updates the boolean state in real-time.
3. **Text Link Tap:** Tapping "Don't have an account? Register" navigates to the Register screen.

---

## Part E: The Lifecycle (Learning Log)

### Sources Used
- Official Flutter Documentation: `WidgetsBindingObserver` and `AppLifecycleState`.
- Android Developer Documentation: Activity Lifecycle (for conceptual mapping).

### What I Learned
In native Android, activities have explicit callbacks like `onPause()` and `onResume()`. In Flutter, I learned that to observe the app lifecycle, I must mix in `WidgetsBindingObserver` to my State class and override `didChangeAppLifecycleState`. I also learned that rotating the phone destroys the current Widget tree and rebuilds it from scratch, meaning `initState` and `dispose` are called again.

### Problem I Solved
**The Problem:** Initially, when I minimized the app, my lifecycle logs were not printing to the console. 
**The Solution:** I realized that simply overriding `didChangeAppLifecycleState` is not enough; you must explicitly register the observer. I fixed this by adding `WidgetsBinding.instance.addObserver(this);` inside `initState()`, and removing it in `dispose()`.

### Lifecycle Observation Log
*(Insert Screenshot of your Debug Console here showing the logs: 🟢 LIFECYCLE: LoginScreen launched, 🟡 LIFECYCLE STATE CHANGED TO: AppLifecycleState.paused, etc.)*

---

## AI Tools Declaration
As per Section 4 of the coursework guidelines:
- **Qwen AI:** Used for architectural planning, generating the Flutter UI skeleton for the glassmorphism design, and structuring the README documentation. All code was reviewed, understood, and manually integrated by the student.