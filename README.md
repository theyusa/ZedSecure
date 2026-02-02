# ZedSecure VPN

<div align="center">

![Version](https://img.shields.io/badge/version-1.8.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.38.4-02569B?logo=flutter)
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
- **Server Management**: Concurrent ping testing, subscription auto-update, auto-select best server
- **Subscription Grouping**: Organize servers by subscription with tab navigation
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
- Subscription traffic & expiry info display

### Data Management
- Backup & Restore configs to JSON
- QR code scan and generate
- Clipboard import support

## Tech Stack

- **Flutter**: 3.9.0+ (Dart 3.9.0+)
- **Kotlin**: 2.1.0
- **Xray-core**: 26.1.23
- **HevTun**: [hev-socks5-tunnel](https://github.com/heiher/hev-socks5-tunnel/) - High-performance TUN library
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
- Android NDK 29.0.14206865
- Java JDK 11+

### Quick Build

```bash
git clone https://github.com/CluvexStudio/ZedSecure.git
cd ZedSecure
flutter pub get
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`

### Building HevTun (Optional)

See [BUILD_HEVTUN.md](BUILD_HEVTUN.md) for detailed instructions.

Quick build:
```bash
# Windows
.\compile-hevtun.ps1

# Linux/macOS
./compile-hevtun.sh
```

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
│   ├── models/
│   │   ├── v2ray_config.dart
│   │   └── subscription.dart
│   └── theme/
│       └── app_theme.dart
├── local_packages/
│   └── flutter_v2ray_client/
├── android/
│   └── app/
│       └── src/main/jniLibs/
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

## What's New in v1.8.0

### 🔄 Database Migration
- **MMKV Integration**: Migrated from SharedPreferences to MMKV for 100x faster performance
- **Multi-Process Support**: All storages use `MULTI_PROCESS_MODE` for VPN service compatibility
- **Auto Migration**: Seamless migration from old SharedPreferences data
- **Optimized Storage**: Separate storages for configs, subscriptions, settings, and cache

### 🎨 UI Improvements
- **Home Screen Redesign**: Improved connection info grid layout
- **Latency Display**: Real-time ping measurement with refresh button
- **Better Icons**: Circular icon containers for Download/Upload/Latency
- **Responsive Design**: FittedBox for speed values to prevent widget expansion
- **GitHub Logo**: SVG icon for better quality in About screen

### 🐛 Bug Fixes
- Fixed duplicate code in v2ray_service.dart
- Fixed latency measurement timeout issues
- Fixed ping cache loading with proper timestamp validation
- Improved error handling for subscription fetching

### 📝 Previous Updates (v1.7.0)
- **HevTun Integration**: Replaced FluxTun with hev-socks5-tunnel
- **Subscription Grouping**: Tab-based navigation for each subscription
- **Subscription Info**: Display traffic usage and expiry date
- **Auto Select Best Server**: Automatically ping and select fastest server

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

## Acknowledgments

- [hev-socks5-tunnel](https://github.com/heiher/hev-socks5-tunnel/) - High-performance TUN implementation
- Xray-core team for the excellent proxy core
- Flutter community for amazing packages

## Disclaimer

This application is for educational and research purposes only. Users are responsible for complying with local laws and regulations.

---

<div align="center">

**CluvexStudio**

[![GitHub](https://img.shields.io/badge/GitHub-CluvexStudio-181717?logo=github)](https://github.com/CluvexStudio)

Made with ❤️ for digital freedom

</div>
