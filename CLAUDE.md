# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (choose a device first)
flutter run

# Run on a specific device
flutter run -d <device-id>

# Analyze for errors and warnings
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build APK (Android)
flutter build apk

# Get dependencies after pubspec changes
flutter pub get
```

## Architecture

**Feature-based structure** under `lib/`:
- `core/` — shared constants, theme, router (no business logic)
- `features/auth/` — screens, services, widgets used across auth flows
- `features/director/` — director role: dashboard shell, tab screens, form screens
- `features/home/` — legacy placeholder screen (unused; actual home is `DirectorDashboardScreen`)

**Entry point flow:**
`main.dart` → Firebase init + orientation lock → `TeaStateApp` (`app.dart`) → `MaterialApp.router` with `AppRouter.router` → `SplashScreen` → auth check → role dashboard.

**Navigation** uses GoRouter 14.x (`lib/core/router/app_router.dart`). All route path constants live in `AppRoutes`. Currently `/home` and `/director` both resolve to `DirectorDashboardScreen`. `/supervisor` is defined as a constant but has no `GoRoute` yet.

**Auth** is backed by `FirebaseAuthService` implementing the abstract `AuthService` interface (`features/auth/services/auth_service.dart`). Email/password and Google Sign-In are both live. After successful auth, navigate to `AppRoutes.home`.

**Director dashboard** (`director_dashboard_screen.dart`) is a shell with an `IndexedStack` + `NavigationBar` (4 tabs: Home, Workers, Reports, Settings). The tabs list is built inside `build()` — not as a `static const` — so that the `DirectorHomeTab` can receive callbacks (e.g., `onViewReports` switches to tab index 2 without pushing a route).

**All API calls are stubbed** with `Future.delayed`. The real endpoints are documented in `// TODO` comments in each form's `_submit()` method.

## Design System

**Colors** — all in `AppColors` (`core/constants/app_colors.dart`):
- Primary palette: `primary` (#2D6A4F), `primaryDark` (#1B4332), `primaryMid`, `primaryLight`, `primaryFaint`
- Backgrounds: `background` (#F8F4EE cream), `inputFill` (#F0F5F0)
- Status: `success` (#00875A), `error` (#B00020)

**Typography** — two fonts, always applied explicitly (not via `Theme.of(context).textTheme`):
- Headings / branding / screen titles: `GoogleFonts.playfairDisplay()`
- Body / labels / numbers / data: `GoogleFonts.dmSans()` — use w800 for numeric stat values

**Theme** (`core/theme/app_theme.dart`) is Material 3 (`useMaterial3: true`). `InputDecorationTheme` is globally configured — form fields inherit border radius (14), fill color, and focus/error border styles automatically.

## Rules & Gotchas

- **Never use `withOpacity()`** — it is deprecated. Always use `withValues(alpha: x)` instead.
- **`DropdownButtonFormField`** — use `initialValue:` not `value:` (deprecated after Flutter 3.33.0-1.0.pre).
- **Date formatting** — no `intl` package in pubspec. Format dates manually or add the package first.
- **App is portrait-only** — locked in `main.dart` via `setPreferredOrientations`.
- **`_role` / `status` fields** are hidden from forms and hardcoded in the API body comment (`'supervisor'` for supervisors, `'active'` for workers).
- **Mock estate data** (`_Estate` list with 4 Sri Lankan estates) is duplicated in both `add_supervisor_screen.dart` and `add_worker_screen.dart`. When the API is wired up, both should fetch from a shared source.
- **`home_screen.dart`** in `features/home/` is an orphaned placeholder — it is not referenced by any route and can be deleted.

## Pending / Stub Areas

- Supervisor dashboard (`/supervisor` route and screen) — not yet built.
- Real API integration for all form `_submit()` methods.
- `_mockWorkers` in `workers_tab.dart` and mock `_periods`/`_estateReports` in `reports_tab.dart` — replace with API calls.
- Route constants `AppRoutes.estates`, `.reports`, `.settings` are declared but have no corresponding `GoRoute`.
