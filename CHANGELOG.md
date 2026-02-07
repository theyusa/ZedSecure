# Changelog

All notable changes to ZedSecure VPN will be documented in this file.

## [1.8.1] - 2026-02-07

### 🐛 Bug Fixes
- **Custom Config Connection**: Fixed custom JSON configs from subscriptions failing to connect
  - Changed detection logic to parse JSON structure instead of checking configType
  - Now properly detects configs with inbounds/outbounds keys
- **Custom Config Traffic Stats**: Fixed upload/download statistics for custom configs
  - Ensures first outbound has 'proxy' tag
  - Adds 'direct' and 'block' outbounds if missing
- **Custom Config Ping Test**: Fixed ping test failure for custom JSON configs
  - Modified speedtest config builder to handle JSON configs properly
  - Removes unnecessary inbounds, dns, routing for accurate ping
- **Latency Display**: Simplified ping measurement after connection
  - Removed automatic timer to prevent overlap issues
  - Single ping on connect with manual refresh button
  - Increased timeout to 10 seconds
- **Advanced Settings Dependencies**:
  - Local DNS now automatically enables Fake DNS when activated
  - Fake DNS switch disabled when Local DNS is active
  - Mux dialog shows message when disabled
  - Fragment dialog shows message when disabled

### 🔧 Technical Changes
- Updated version to 1.8.1+10
- Updated Xray-core to 26.2.4
- Improved config builder logic for custom JSON handling
- Enhanced debug logging for troubleshooting
- Better state management for ping measurements

---

## [1.8.0] - 2026-02-02

### 🔄 Database Migration
- **MMKV Integration**: Migrated from SharedPreferences to MMKV (Tencent official package v2.3.0)
  - 100x faster read/write performance
  - Multi-process support for VPN service compatibility
  - Separate storages: MAIN, SERVER_CONFIG, SERVER_AFF, SUBSCRIPTION, SETTINGS
  - All storages use `MULTI_PROCESS_MODE` for stability
- **Auto Migration**: Seamless migration from SharedPreferences on first launch
  - Migrates all configs, subscriptions, settings, and cache
  - No data loss during upgrade

### 🎨 UI Improvements
- **Home Screen Redesign**:
  - Improved connection info grid layout matching reference design
  - Circular icon containers for Download/Upload/Latency
  - Better visual hierarchy and spacing
- **Latency Display**:
  - Real-time ping measurement with 10s timeout
  - Working refresh button with loading state
  - Auto-refresh on connection state change
  - Color-coded latency (green/yellow/red)
- **Responsive Design**:
  - FittedBox for speed values to prevent widget expansion
  - Better handling of large numbers
- **GitHub Logo**: SVG icon in About screen for better quality

### 🐛 Bug Fixes
- Fixed duplicate code in `v2ray_service.dart` causing build errors
- Fixed latency measurement stuck on "Measuring..."
- Fixed ping cache loading with proper timestamp validation (1 hour cache)
- Improved error handling for subscription fetching with better debug logs
- Fixed blocked apps list loading from MMKV

### 🔧 Technical Changes
- Updated version to 1.8.0+9
- Added `assets/images/` directory for app assets
- Improved debug logging for ping measurements
- Better timeout handling for network operations

---

## [1.7.0] - 2026-01-28

### 🆕 New Features
- **HevTun Integration**: Replaced FluxTun with [hev-socks5-tunnel](https://github.com/heiher/hev-socks5-tunnel/)
  - Better performance and stability
  - Native C implementation
  - Lower memory footprint
- **Subscription Grouping**: Tab-based navigation for each subscription (like v2rayNG)
  - Separate tab for each subscription
  - Server count display per subscription
  - Easy switching between subscription groups
- **Subscription Info Display**:
  - Traffic usage with progress bars
  - Expiry date countdown
  - Upload/Download statistics
  - Visual indicators for quota
- **Auto Select Best Server**: Automatically ping and select fastest server
- **Real Ping Testing**: Uses `measureOutboundDelay` for accurate latency

### 🔧 Improvements
- **Server Organization**: Better server management with subscription filtering
- **Traffic Monitoring**: Real-time visual progress bars
- **Expiry Tracking**: Countdown timer for subscription expiration
- **Smart Filtering**: Filter servers by subscription in real-time
- **Enhanced Ping**: Sequential ping with 200ms delay and 15s timeout

### 🐛 Bug Fixes
- Fixed JNI registration for HevTun native library
- Improved subscription update logic to replace old configs
- Fixed country detection with multiple fallback APIs
- Better error handling for subscription parsing

---

## [1.6.0] - 2026-01-20

### 🆕 New Features
- **Update Checker System**:
  - Auto-check for new releases on GitHub
  - Skip version option
  - Manual check from settings
- **Full V2Ray Configuration Viewer and Editor**:
  - View complete JSON config
  - Edit and save custom configs
  - Syntax highlighting
- **Custom JSON Import**: Import custom V2Ray configs from clipboard
- **Protocol Support**:
  - Hysteria2 protocol support
  - WireGuard protocol support

### 🔧 Improvements
- **Per-App Proxy**: Enhanced UI with system/user apps filter
- **Settings Organization**: Better categorization of settings
- **Error Messages**: More descriptive error messages

---

## [1.5.0] - 2026-01-10

### 🆕 Initial Release Features
- **Core Protocols**: VMess, VLESS, Trojan, Shadowsocks, SOCKS, HTTP
- **Transports**: TCP, WebSocket, HTTP/2, gRPC, QUIC, mKCP
- **Security**: TLS, Reality with fingerprint customization
- **Statistics**: Real-time upload/download speed and total data
- **Server Management**: Concurrent ping testing, subscription support
- **Split Tunneling**: Per-App proxy configuration
- **iOS-Style UI**: Modern design with glassmorphism effects
- **Dynamic Island**: Connection status display
- **Light/Dark Mode**: Theme support
- **Country Flags**: SVG flags with real location detection
- **Backup & Restore**: Export/Import configs to JSON
- **QR Code**: Scan and generate QR codes

---

## Version Format

Version format: `MAJOR.MINOR.PATCH+BUILD`
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes
- **BUILD**: Build number (incremental)

## Links

- **GitHub**: https://github.com/CluvexStudio/ZedSecure
- **Telegram**: https://t.me/CluvexStudio
- **Releases**: https://github.com/CluvexStudio/ZedSecure/releases
