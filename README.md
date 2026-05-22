# flutter_weather

A Flutter weather app targeting iOS and Android.

## Tech Stack

| Item              | Version    | Purpose                                |
| ----------------- | ---------- | -------------------------------------- |
| Flutter SDK       | `3.41.6`   | Pinned via FVM (`.fvmrc`)              |
| Dart              | `3.11.4`   | Bundled with the Flutter SDK above     |
| flutter_riverpod  | `^3.3.1`   | State management (hand-written providers) |
| dio               | `^5.9.2`   | HTTP client for weather API calls      |
| logger            | latest     | Pretty-printed logs (debug verbose, release warning+) |
| Target platforms  | iOS, Android | Mobile only                          |

## Prerequisites

- **macOS** with Xcode (for iOS) and Android Studio / Android SDK (for Android)
- **Homebrew** — used to install FVM
- A running iOS Simulator or Android Emulator (or a connected device)

## Install

### 1. Install FVM (Flutter Version Management)

```bash
brew tap leoafarias/fvm
brew install fvm
```

### 2. Clone the repo

```bash
git clone https://github.com/drakehuang81/flutter_weather.git
cd flutter_weather
```

### 3. Provision the pinned Flutter SDK

`.fvmrc` declares the Flutter version. FVM downloads it on first use:

```bash
fvm install
fvm use 3.41.6
```

### 4. Fetch packages

```bash
fvm flutter pub get
```

### 5. (Optional) Verify the toolchain

```bash
fvm flutter doctor
```

## Run

Always invoke Flutter through FVM so the pinned version is used:

```bash
fvm flutter run            # auto-detect device
fvm flutter run -d ios     # iOS simulator
fvm flutter run -d android # Android emulator
```

## Project Conventions

- All `flutter` / `dart` commands go through `fvm` (e.g. `fvm flutter test`, `fvm dart format .`).
- `.fvm/` (SDK symlink cache) is git-ignored; `.fvmrc` (version lock) is committed.
- Claude Code artifacts (`CLAUDE.md`, `.claude/`, `.mcp.json`) are git-ignored.

## Architecture

### Project Layout

```
lib/
├── core/
│   ├── infra/
│   │   └── network/          # HTTP infrastructure (Dio-based)
│   │       ├── api_request.dart    # Abstract API contract
│   │       ├── api_exception.dart  # Unified error type
│   │       ├── http_method.dart    # HTTP verb enum
│   │       └── http_service.dart   # Executor + interceptors
│   └── utils/
│       └── log.dart          # Cross-cutting logger
└── main.dart
```

### Network Layer

The network layer is built around an abstract `ApiRequest<T>` contract — each endpoint
declares its own `baseUrl`, `path`, `method`, `headers`, `queryParameters`, `body`, and
`parseResponse` mapping. `HttpService` is the only executor; it owns a `Dio` instance,
maps `DioException` to a domain `ApiException`, and (in debug builds) installs a log
interceptor that prints every request / response / error through the `Log` utility.

**Defining an endpoint**

```dart
class GetWeatherRequest extends ApiRequest<WeatherDto> {
  GetWeatherRequest(this.city);
  final String city;

  @override
  String get baseUrl => 'https://api.example.com';
  @override
  String get path => '/v1/weather';
  @override
  HttpMethod get method => HttpMethod.get;
  @override
  Map<String, dynamic>? get queryParameters => {'city': city};

  @override
  WeatherDto parseResponse(dynamic response) =>
      WeatherDto.fromJson(response as Map<String, dynamic>);
}
```

**Calling it**

```dart
final http = HttpService();
try {
  final weather = await http.execute(GetWeatherRequest('Taipei'));
} on ApiException catch (e) {
  if (e.isUnauthorized) { /* refresh token */ }
  else if (e.isNetworkError) { /* offline UI */ }
  else { Log.e('weather request failed', e, e.stackTrace); }
}
```

**Logging**

```dart
Log.d('debug detail');
Log.i('informational message');
Log.w('warning');
Log.e('error', error, stackTrace);
```

Verbosity is `trace` in debug builds and `warning` in release; no extra config needed.

## IDE Setup

Point your IDE at the FVM-managed SDK so analyzer and run configs use the pinned version:

- **VS Code** — add to `.vscode/settings.json`:
  ```json
  { "dart.flutterSdkPath": ".fvm/flutter_sdk" }
  ```
- **Android Studio / IntelliJ** — Settings → Languages & Frameworks → Flutter → Flutter SDK path: `.fvm/flutter_sdk`
