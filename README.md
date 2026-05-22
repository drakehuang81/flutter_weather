# flutter_weather

A Flutter weather app targeting iOS and Android. Searches the Taiwan Central
Weather Administration (CWA) 36-hour forecast API by city name.

## Tech Stack

| Item                  | Version    | Purpose                                |
| --------------------- | ---------- | -------------------------------------- |
| Flutter SDK           | `3.41.6`   | Pinned via FVM (`.fvmrc`)              |
| Dart                  | `3.11.4`   | Bundled with the Flutter SDK above     |
| flutter_riverpod      | `^3.3.1`   | State management (hand-written `Notifier`s, no codegen) |
| dio                   | `^5.9.2`   | HTTP client for weather API calls      |
| logger                | `^2.7.0`   | Pretty-printed logs (debug verbose, release warning+) |
| flutter_native_splash | dev        | Generates native launch screens (Android + iOS) |
| Target platforms      | iOS, Android | Mobile only                          |

## Prerequisites

- **macOS** with Xcode (for iOS) and Android Studio / Android SDK (for Android)
- **Homebrew** — used to install FVM
- A running iOS Simulator or Android Emulator (or a connected device)
- A **CWA Open Data API token** (free) — see [Configuration](#configuration)

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

> **Splash & native assets** — All native launch-screen files
> (`android/app/src/main/res/drawable*/`, `ios/Runner/Assets.xcassets/LaunchBackground.imageset/`,
> updated `LaunchScreen.storyboard` / `styles.xml` etc.) are pre-generated and
> committed. You do **not** need to run `flutter_native_splash:create` after
> cloning — only re-run it if you change the colour in `pubspec.yaml`.
> See [Splash & launch flow](#splash--launch-flow).

> **iOS first-time** — `ios/Podfile` is committed. The first
> `fvm flutter run -d ios` will trigger `pod install` automatically;
> make sure CocoaPods is installed (`fvm flutter doctor` reports it).

## Configuration

The app calls the CWA F-C0032-001 forecast API, which requires a personal token.

### Get a CWA token (one-time, free)

1. Open <https://opendata.cwa.gov.tw/> and click **註冊** to create a free account.
2. Verify your email and sign in.
3. From the top menu go to **會員資訊 → API 授權碼**, then click **取得授權碼**.
4. Copy the token (a 36–40 character string starting with `CWB-` or similar).

### Inject the token into the build

The app reads the token from `String.fromEnvironment('CWA_API_TOKEN')`, so it
must be provided at **build time** through Dart's compile-time environment.
Two equivalent ways:

#### Option A — Inline `--dart-define` (one-shot)

Best for quick demos, CI pipelines, or when you don't want to keep a local
file. Substitute your real token for `<YOUR_TOKEN>`:

```bash
fvm flutter run --dart-define=CWA_API_TOKEN=<YOUR_TOKEN>

# Or read from a shell variable so the token isn't visible in scrollback:
export CWA_API_TOKEN=<YOUR_TOKEN>
fvm flutter run --dart-define=CWA_API_TOKEN=$CWA_API_TOKEN
```

> ⚠️ Passing the token inline puts it in your shell history. Prefer
> the shell-variable form on shared machines.

#### Option B — `.env` file (recommended for repeated dev runs)

Flutter 3.7+ can load `KEY=VALUE` files directly. `.env` is git-ignored;
just create one yourself in the repo root:

```bash
cat > .env <<'EOF'
CWA_API_TOKEN=YOUR-CWA-TOKEN-HERE
EOF

fvm flutter run --dart-define-from-file=.env
```

Works the same way for any build / test command:

```bash
fvm flutter test       --dart-define-from-file=.env   # (not required — tests use stubs)
fvm flutter build apk  --dart-define-from-file=.env   # release build
fvm flutter build ios  --dart-define-from-file=.env
```

#### What happens if the token is missing?

On launch the app shows a centred overlay reminding you to set the token
(every search would otherwise return `伺服器錯誤（401）`). Dismiss it to
explore the UI, then restart with a `--dart-define` flag once you have the
token.

## Run

Type a city name (e.g. `臺北市`, `高雄市`) and tap **確認**. Pick whichever
injection form you set up above:

```bash
# Option A
fvm flutter run --dart-define=CWA_API_TOKEN=<YOUR_TOKEN>

# Option B
fvm flutter run --dart-define-from-file=.env

# Target a specific platform
fvm flutter run -d ios     --dart-define-from-file=.env
fvm flutter run -d android --dart-define-from-file=.env
```

## Project Conventions

- All `flutter` / `dart` commands go through `fvm` (e.g. `fvm flutter test`, `fvm dart format .`).
- `.fvm/` (SDK symlink cache) is git-ignored; `.fvmrc` (version lock) is committed.
- `.env` and `/scripts/` are git-ignored — never commit secrets.
- Claude Code artifacts (`CLAUDE.md`, `.claude/`, `.mcp.json`) are git-ignored.

## Architecture

Clean Architecture in four tiers; Domain is the dependency core.

```
lib/
├── domain/weather_forecast/         # Entities, VOs, Repository interface, Failures
├── application/
│   ├── result.dart                  # Sealed Result<T, E>
│   └── weather_forecast/
│       └── get_city_forecast.dart   # Use Case: raw input → Result<List<Forecast>, Failure>
├── infra/
│   ├── network/                     # ApiRequest / HttpService / DioHttpService / ApiException
│   └── weather_forecast/            # CWA DTO / Mapper / Request / Repository impl (ACL)
├── presentation/
│   ├── theme/                       # AppTheme + GlassCard + weather icon mapper
│   ├── splash/splash_screen.dart    # Flutter-level splash (1.6s) with entry animation
│   └── weather_search/              # Notifier + ViewState + 4 state widgets + token overlay
├── composition/
│   └── providers.dart               # Riverpod wiring (Composition Root)
├── core/utils/log.dart              # Cross-cutting logger
└── main.dart                        # ProviderScope + MaterialApp + _AppRoot (splash → home)
```

### Dependency rule

Domain is independent of everything. Application depends on Domain only.
Infrastructure implements Domain interfaces. Presentation depends on
Application and Domain. The Composition Root (`providers.dart`) is the
**only** place where concrete implementations are wired into Riverpod
providers.

### Network layer

`ApiRequest<T>` is the abstract endpoint contract — each request declares
its own `baseUrl`, `path`, `method`, `queryParameters`, and `parseResponse`
mapping. `HttpService` is the abstract executor; `DioHttpService` is the
Dio implementation. The Repository (ACL) catches `ApiException` and
`FormatException` and translates them to `DomainFailure`.

### Weather search flow

```
WeatherSearchPage (Riverpod ConsumerStatefulWidget)
 └─ ref.watch(weatherSearchNotifierProvider)
     └─ WeatherSearchNotifier.search(input)         # ≥ 500ms loading time
         └─ ref.read(getCityForecastProvider).call(input)
             ├─ trimmed.isEmpty → Repository.fetchForecasts()           # browse all
             └─ else            → Repository.fetchForecasts(city: ...)  # specific city
                 └─ HttpService.execute(GetCwaForecastRequest)
                     └─ CWA F-C0032-001
```

State machine (sealed `WeatherViewState`):

- `WeatherInitial`  → InitialView (prompt to search)
- `WeatherLoading` → SkeletonView (per-search skeleton, ≥ 500ms)
- `WeatherLoaded`  → ForecastView (single → hero card; multi → compact city list)
- `WeatherFailed`  → ErrorView (retry replays `lastQuery`)

When `CWA_API_TOKEN` is empty, a `MissingTokenOverlay` is rendered on top
of whatever page is shown until the user dismisses it.

### Splash & launch flow

Two layers cooperate to avoid the OS-level white flash before the Dart VM
boots:

1. **Native splash** (Android + iOS) — generated by `flutter_native_splash`
   from the `flutter_native_splash:` block in `pubspec.yaml`. Renders a
   solid `#3B5BA0` background (matching `AppTheme.skyTop`) the moment the
   app icon is tapped.
2. **Flutter splash** (`SplashScreen`) — fades in `skyGradient` starting at
   the same `#3B5BA0`, animates the cloud icon / title / progress line,
   then hands off to `WeatherSearchPage` via a 480 ms fade in `_AppRoot`.

To regenerate the native splash after changing the colour or adding an
image, re-run:

```bash
fvm dart run flutter_native_splash:create
```

Edit the `flutter_native_splash:` block in `pubspec.yaml` first.

### Logging

```dart
Log.d('debug detail');
Log.i('informational message');
Log.w('warning');
Log.e('error', error, stackTrace);
```

Verbosity is `trace` in debug builds and `warning` in release; no extra config needed.

## Tests

```bash
fvm flutter test
```

54 tests cover domain VO/aggregate invariants, DTO/Mapper, Repository ACL
translation (single + browse modes), and Use Case Failure routing. All
tests use in-process fakes (`_StubHttpService`, `_StubRepo`) — no real
network calls.

## IDE Setup

Point your IDE at the FVM-managed SDK so analyzer and run configs use the pinned version:

- **VS Code** — add to `.vscode/settings.json`:
  ```json
  { "dart.flutterSdkPath": ".fvm/flutter_sdk" }
  ```
- **Android Studio / IntelliJ** — Settings → Languages & Frameworks → Flutter → Flutter SDK path: `.fvm/flutter_sdk`

## AI Disclosure

This codebase was developed with assistance from **Claude Code (Anthropic)** —
scaffolding, network layer, use cases, state holder, glass UI, and
documentation drafts. All output is human-reviewed, edited, and tested
before commit.

### Tooling used

- **MCP / Skills / SubAgents**
  - [`ui-ux-pro-max`](https://github.com/) — UI/UX design intelligence (style系統、配色、字體配對) 用於 glass UI 與配色決策
  - [`awesome-claude-code-subagents`](https://github.com/VoltAgent/awesome-claude-code-subagents) by **VoltAgent** — 領域專用 subagents（此專案使用 `flutter-expert`）
  - [`context7`](https://github.com/upstash/context7) — 即時抓取 riverpod / dio / Flutter 等套件的最新官方文件，避免訓練資料過期
  - **superpowers** — TDD、systematic-debugging、writing-plans 等工程紀律 skills

### Workflow

採 **SDD (Spec-Driven Development)**：先把 需求的PDF 與 `spec/design.md` 對齊，再產出 plan → 寫測試 → 實作 → review。

實際執行時開 **2 個 Claude Code session 並行**（一個跑 domain/infra，一個跑 presentation/UI），因為本專案範圍較小；日常專案通常會開 3–5 個 session 並行，主 session 只做整合與決策。
