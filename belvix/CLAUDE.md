# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Flutter mobile app for a Continuous Glucose Monitoring (CGM) platform. It pairs over BLE with Eaglenos/Bionime CGM sensors via a native SDK bridge, syncs readings to a backend, and renders a glucose dashboard plus food/exercise/insulin/finger-blood logging.

Note the naming drift: the pubspec package is `mobile_app`, the Android/iOS application is `com.belvix.app` (Belvix branding), and the `MaterialApp` title is `"CGM Platform"`. The repo directory is `belvix`.

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run on connected device/emulator (debug)
flutter run -d chrome           # run on web
flutter analyze                 # static analysis / lint (flutter_lints)
flutter test                    # run all tests
flutter test test/widget_test.dart           # run a single test file
flutter build apk --release     # Android release build
flutter build ios --release     # iOS release build
dart run flutter_launcher_icons # regenerate launcher icons from assets/logos
```

Passing CGM SDK credentials at launch (defaults are baked into `lib/app/constants/cgm_credentials.dart`):

```bash
flutter run --dart-define=CGM_APP_ID=... --dart-define=CGM_APP_SECRET=...
```

`build_runner`, `freezed`, and `json_serializable` are listed as dev dependencies but are **not used** — there are no `.g.dart`/`.freezed.dart` files. Models are hand-written (see Conventions). Do not assume codegen.

## Architecture

### Layering
Code lives under `lib/features/<feature>/` following a loose Clean Architecture split:
- `data/` — `datasource/` (Dio calls), `models/` (hand-written `fromJson`/`toJson`/`copyWith`), `repository/` (`*_impl.dart`).
- `domain/` — `repository/` (abstract interface) + `usecases/` (thin call wrappers). **Only some features have a domain layer** (`auth`, `onboarding`, `profile`). Simpler features (`food`, `exercise`, `insulin`, `finger_blood`) skip it and have the provider talk to data directly.
- `presentation/` — `providers/` (`ChangeNotifier`), `screens/`, `widgets/`.

Shared/cross-cutting code is in `lib/core/` (network, storage, services, generic widgets) and `lib/app/` (theme, router, constants).

### State management
Uses the `provider` package with `ChangeNotifier`, wired in a single `MultiProvider` in `lib/main.dart`. **`flutter_riverpod` is a dependency but is not used** — follow the `provider` pattern. Providers instantiate their own usecases/repositories directly (manual DI, e.g. `LoginUsecase(AuthRepositoryImpl())`); there is no DI container.

### Navigation / auth gating
`go_router` is a dependency but routing is done **imperatively with `Navigator`**, not declarative routes. The gate lives in `lib/app/router/app_router.dart`: `AppRouter.resolveHome(token, user)` returns the correct landing screen based on `token` + `UserModel` flags, in order: no token → Welcome, `!isProfileCompleted` → ProfileSetup, `!isOnboardingCompleted` → Onboarding, `!isCgmConnected` → CGM Connect Intro, else → MainNavigation. App starts at `SplashScreen`. A global `navigatorKey` (`lib/core/constants/app_globals.dart`) is set on `MaterialApp` for navigation outside widget context.

### Networking
Single static Dio instance: `DioClient.dio` (`lib/core/network/dio_client.dart`). An interceptor injects `Authorization: Bearer <token>` from `StorageService.getToken()` on every request. Base URL is **hardcoded** to `https://cgm-app.duckdns.org/api` (a commented-out LAN URL sits next to it for local backend work). Datasources return raw `Response`; repositories unwrap `response.data["data"]` and map to models.

### Persistence
`StorageService` (`lib/core/storage/storage_service.dart`) is a static wrapper over `flutter_secure_storage`. It holds the auth token, the JSON-encoded user, profile/onboarding/CGM completion flags, and the persisted CGM session (SN, device name, manufacturer, auto-reconnect flag). `StorageService.clear()` wipes everything (logout).

### CGM SDK bridge (the core subsystem)
Glucose data comes from a native SDK exposed to Dart over platform channels:

- **Dart facade**: `lib/features/cgm/sdk/cgm_sdk.dart` (`CgmSdk`) wraps `CgmMethodChannel` (imperative: `init`/`auth`/`startScan`/`connect`/`getHistory`/`startHeartbeat`/…) and `CgmEventChannel` (a single normalized broadcast `Stream<Map<String,dynamic>>` where every event has a `type` discriminator). Channel names: `cgm_sdk/method` and `cgm_sdk/events`.
- **Native side (Android)**: `android/app/src/main/kotlin/com/belvix/app/` — `MainActivity.kt` registers the channels, `CgmSdkBridge.kt` adapts the Eaglenos `com.eaglenos.blehealth` SDK callbacks (glucose, device info, scan results, bind step, sync progress, errors) into channel events.
- **Session orchestration**: `CgmSessionManager` (`lib/features/cgm/session/cgm_session_manager.dart`) is an app-lifetime singleton that owns the *single* SDK event subscription and the canonical `CgmSessionState`. It runs the connection state machine (`CGMConnectionStatus` enum in `cgm_session_state.dart`: disconnected → reconnecting → searching → connecting → warmup → syncing → active, plus error/off-path states), handles auto-reconnect with exponential backoff, persists the paired device, registers the device with the backend once connected, and tracks Bluetooth adapter state. It is `bootstrap()`-ed in `main()` **before `runApp`** and gets an `onAppResumed()` hook from `MyApp`'s `WidgetsBindingObserver`. The dashboard provider subscribes to its `states` stream.

Glucose unit note: the SDK reports mmol/L; the dashboard renders mg/dL. Convert with `mmolToMgDl()` (bottom of `cgm_sdk.dart`).

### App startup sequence (`main.dart`)
`WidgetsFlutterBinding.ensureInitialized()` → `NotificationService.init()` → `CgmSdk.init()` → `CgmSessionManager.instance.bootstrap()` → `runApp`. Each init is wrapped in try/catch so a single failure doesn't block boot.

## Conventions

- **Models** are hand-written: a `fromJson` factory (defensively null-coalescing, and tolerant of both `_id` and `id`), `toJson`, and `copyWith`. Match this style rather than adding codegen.
- **Immutable state with sentinel copyWith**: `CgmSessionState.copyWith` uses a `_sentinel` Object to distinguish "not passed" from "explicitly set to null" for nullable fields. Reuse this pattern when nulling out fields matters.
- Repositories implement a `domain/repository` interface only where a domain layer exists; otherwise the `*_impl` / datasource is used directly.
- The codebase is auto-formatted to a narrow column width, producing heavily wrapped multi-line calls — let `dart format` handle this; don't hand-fight the wrapping.

## Security note
`lib/app/constants/cgm_credentials.dart` is committed with real-looking default `CGM_APP_ID`/`CGM_APP_SECRET` values (overridable via `--dart-define`). Treat these as sensitive; prefer dart-define overrides for anything non-development.
