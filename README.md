# ZedSecure VPN

<div align="center">

![Version](https://img.shields.io/badge/version-1.6.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.38.4-02569B?logo=flutter)
![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84?logo=android)
![License](https://img.shields.io/badge/license-GPL--3.0-green.svg)

A modern VPN application for Android with V2Ray/Xray protocol support and iOS-style UI design.

[Features](#features) • [Installation](#installation) • [Build](#build-from-source) • [Contributing](#contributing)

</div>

---

Telegram Channel: https://t.me/CluvexStudio

## Features

### Core
- **Protocols**: VMess, VLESS, Trojan, Shadowsocks, Hysteria2, WireGuard, SOCKS, HTTP
- **Transports**: TCP, WebSocket, HTTP/2, gRPC, QUIC, XHTTP, HTTPUpgrade, mKCP
- **Security**: TLS, Reality, with fingerprint customization
- **Statistics**: Real-time upload/download speed and total data
- **Server Management**: Concurrent ping testing, subscription auto-update
- **Split Tunneling**: Per-App proxy with system/user apps filter
- **Configuration**: Full V2Ray JSON viewer/editor, custom config import
- **Updates**: Auto-check for new releases with skip version option

### Advanced Settings
- **Mux**: Multiplexing support with concurrency control and xUDP
- **Fragment**: TLS/Reality fragmentation with custom packets, length, interval
- **DNS**: Custom remote/domestic DNS servers with FakeDNS support
- **Routing**: Domain strategy, bypass LAN, custom routing rules
- **Network**: MTU configuration, VPN interface address selection
- **Core**: Log level control, sniffing, route-only mode

### UI/UX
- iOS-style design with glassmorphism effects
- Dynamic Island connection status
- Ring animation connect button
- Light/Dark mode support
- SVG country flags with real location detection
- Connection latency display with refresh
- Real-time notification with stats

### Data Management
- Backup & Restore configs to JSON
- QR code scan and generate
- Clipboard import support

## Tech Stack

- **Flutter**: 3.9.0+ (Dart 3.9.0+)
- **Kotlin**: 2.1.0
- **Xray-core**: 26.1.23
- **FluxTun**: Custom Rust TUN library
- **Gradle**: 8.14 with AGP 8.11.1
- **Target SDK**: Android 16 (API 36)
- **Min SDK**: Android 7.0 (API 24)

## Installation

Download the latest APK from [GitHub Releases](https://github.com/CluvexStudio/ZedSecure/releases)

Recommended: `app-arm64-v8a-release.apk` for most modern devices

### Requirements
- Android 7.0 (Nougat) or higher
- ARM64-v8a or ARMv7 architecture
- ~30 MB storage

## Build from Source

### Prerequisites
- Flutter SDK 3.9.0+
- Android SDK 34+
- Java JDK 11+
- Rust toolchain (for FluxTun)

### Steps

```bash
git clone https://github.com/CluvexStudio/ZedSecure.git
cd ZedSecure
flutter pub get
flutter build apk --release --split-per-abi --target-platform android-arm64
```

Output: `build/app/outputs/flutter-apk/`

### Building FluxTun (Optional)

```bash
cd fluxtun
cargo build --release --target aarch64-linux-android --lib
cargo build --release --target armv7-linux-androideabi --lib
```

Copy `.so` files to `local_packages/flutter_v2ray_client/android/src/main/jniLibs/`

## Project Structure

```
ZedSecure/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── servers_screen.dart
│   │   ├── subscriptions_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   ├── v2ray_service.dart
│   │   └── country_detector.dart
│   └── theme/
│       └── app_theme.dart
├── local_packages/
│   └── flutter_v2ray_client/
├── android/
└── assets/flags/
```

## Supported Protocols

| Protocol | Format | Status |
|----------|--------|--------|
| VMess | `vmess://base64-config` | ✅ Full Support |
| VLESS | `vless://uuid@host:port?params#remark` | ✅ Full Support |
| Trojan | `trojan://password@host:port?params#remark` | ✅ Full Support |
| Shadowsocks | `ss://base64(method:password)@host:port#remark` | ✅ Full Support |
| Hysteria2 | `hysteria2://password@host:port?params#remark` | ✅ Full Support |
| WireGuard | `wireguard://...` | ✅ Full Support |
| SOCKS | `socks://user:pass@host:port#remark` | ✅ Full Support |
| HTTP | `http://user:pass@host:port#remark` | ✅ Full Support |

## What's New in v1.6.0

### 🆕 New Features
- **Update Checker System**: Automatically checks for new releases on app start
- **Full V2Ray Configuration Viewer**: View and edit complete JSON configuration
- **Custom JSON Import**: Import custom V2Ray configurations directly
- **Hysteria2 Protocol**: Full support with obfuscation and port hopping
- **WireGuard Protocol**: Complete implementation with all parameters

### 🔧 Improvements
- **Config Builder**: DNS and routing rules now match v2rayNG exactly
- **Per-App Proxy**: Fixed to find all user apps correctly (not just 23)
- **Connection Latency**: Real-time ping display with manual refresh
- **Country Detection**: Cloudflare API with multiple fallback endpoints
- **Notification Design**: iOS-like notification with real-time statistics

### 🐛 Bug Fixes
- Fixed edit config screen duplicate method error
- Fixed config name changing issue in Full V2Ray Configuration
- Improved JSON parsing for Hysteria2 URLs
- Fixed TLS settings order in stream configuration

### 📝 Previous Updates (v1.5.0)
- iOS-style UI redesign with glassmorphism
- Dynamic Island connection status
- Ring animation connect button
- SVG country flags (no emoji)
- Real country detection via Cloudflare
- FluxTun custom TUN library
- ARMv7 architecture support

## License

GPL-3.0 License

### Attribution Required
When forking or modifying:
```
Based on ZedSecure VPN by CluvexStudio
https://github.com/CluvexStudio/ZedSecure
Licensed under GPL-3.0
```

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/NewFeature`
3. Commit changes: `git commit -m 'Add NewFeature'`
4. Push: `git push origin feature/NewFeature`
5. Open Pull Request

## Disclaimer

This application is for educational and research purposes only. Users are responsible for complying with local laws and regulations.

---

<div align="center">

**CluvexStudio**

[![GitHub](https://img.shields.io/badge/GitHub-CluvexStudio-181717?logo=github)](https://github.com/CluvexStudio)

Made with ❤️ for digital freedom

</div>
