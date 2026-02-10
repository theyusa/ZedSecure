# Agent Guide for ZedSecure

This document provides essential information for AI agents working on the ZedSecure repository.

## 🛠 Build, Lint, and Test Commands

ZedSecure is a Flutter project with a local package `flutter_v2ray_client`.

### Setup
- **Install dependencies:**
  ```bash
  flutter pub get
  ```

### Build
- **Build Android APK (Release):**
  ```bash
  flutter build apk --release --split-per-abi
  ```
- **Build HevTun (Linux/macOS):**
  ```bash
  ./compile-hevtun.sh
  ```

### Linting & Analysis
- **Run static analysis:**
  ```bash
  flutter analyze
  ```
- **Format code:**
  ```bash
  flutter format .
  ```

### Testing
- **Currently, there are no unit or integration tests in the project.**
- If adding tests, place them in the `test/` directory and run:
  ```bash
  flutter test
  ```
- **Run a single test file:**
  ```bash
  flutter test test/path_to_test_file.dart
  ```

## 🎨 Code Style Guidelines

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style) and existing project patterns.

### Imports
- Group imports in this order:
  1.  Dart SDK imports (`dart:async`, `dart:convert`, etc.)
  2.  Flutter framework imports (`package:flutter/...`)
  3.  Third-party package imports (`package:provider/...`)
  4.  Local project imports (`package:zedsecure/...`)
  5.  Relative imports (avoid if possible, prefer `package:zedsecure/`)

### Naming Conventions
- **Classes & Types:** `PascalCase` (e.g., `V2RayService`, `V2RayConfig`).
- **Variables & Methods:** `camelCase` (e.g., `isConnected`, `connect()`).
- **Private members:** Prefix with underscore (e.g., `_isInitialized`).
- **Assets:** `snake_case` (e.g., `github_logo.svg`).

### Formatting & Types
- **Strong Typing:** Always specify types for variables, parameters, and return values. Avoid `dynamic`.
- **Immutability:** Use `final` for variables that don't change.
- **Const Constructors:** Use `const` for widgets and constructors where possible to optimize performance.
- **Trailing Commas:** Use trailing commas for better formatting in large widget trees.

### Error Handling
- Use `try-catch-finally` blocks for asynchronous operations and network calls.
- Use `LogService` or `debugPrint` for logging. Avoid `print()`.
- Provide user-friendly error messages in exceptions.

### State Management
- Use `Provider` and `ChangeNotifier` for app-wide state.
- Keep business logic in services (e.g., `lib/services/`) and UI in screens/widgets.
- Services often follow the Singleton pattern:
  ```dart
  static final V2RayService _instance = V2RayService._internal();
  factory V2RayService() => _instance;
  V2RayService._internal();
  ```

### Models
- Implement `fromJson`, `toJson`, and `copyWith` for data models.
- Use `final` fields in models to ensure immutability.

### Persistent Storage
- Use `MmkvManager` (backed by MMKV) for persistent storage instead of `SharedPreferences`.

## 📱 UI/UX Patterns
- **iOS-style Design:** The app uses an iOS-inspired aesthetic with glassmorphism.
- **Widgets:** Prefer custom glass widgets from `lib/widgets/`.
- **Icons:** Use `CupertinoIcons` for the iOS look and feel.

## 📝 Rules & Configuration
- **Linting:** Rules are defined in `analysis_options.yaml`, extending `package:flutter_lints/flutter.yaml`.
- **Core Core:** The VPN core is based on Xray-core via `flutter_v2ray_client`.
- **TUN:** Uses `hev-socks5-tunnel` (HevTun) for high-performance networking.
