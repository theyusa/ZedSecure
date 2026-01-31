# Changelog

All notable changes to ZedSecure VPN will be documented in this file.

## [1.6.0] - 2026-01-31

### Added
- **Update Checker System**: Automatically checks for new releases on app start with skip version feature
- **Full V2Ray Configuration Viewer**: View complete JSON configuration sent to V2Ray core
- **Custom JSON Config Import**: Import custom V2Ray configurations directly from JSON
- **Hysteria2 Protocol Support**: Full implementation with password, bandwidth, obfuscation, TLS, and port hopping
- **WireGuard Protocol Support**: Complete support with secretKey, publicKey, preSharedKey, localAddress, MTU, and reserved
- **Connection Latency Display**: Real-time ping with manual refresh button on home screen
- **Country Detection System**: Cloudflare API integration with multiple fallback endpoints
- **Dynamic Island Widget**: Connection status display at top of home screen when connected

### Changed
- **Config Builder**: DNS and routing rules now match v2rayNG exactly for better compatibility
- **Notification Design**: iOS-like notification with real-time upload/download stats and duration
- **Edit Config Screen**: Removed JSON mode, only form editor remains
- **Config Viewer**: Editable mode for custom configs with JSON validation

### Fixed
- Per-App Proxy now finds all user apps correctly (was only finding 23 apps)
- Edit config screen duplicate `_buildFormEditor` method error
- Config name no longer changes when viewing Full V2Ray Configuration
- Hysteria2 URL parsing with correct password placement and port hopping parameters
- TLS settings order in stream configuration (allowInsecure, fingerprint, serverName, show)
- WebSocket settings headers order to match v2rayNG

### Technical
- Updated to Gradle 8.14 and AGP 8.11.1
- Kotlin upgraded to 2.1.0
- Added `package_info_plus` dependency for version checking
- Improved JSON config generation to match v2rayNG structure

## [1.5.0] - 2026-01-15

### Added
- iOS-style UI redesign with glassmorphism effects
- Dynamic Island connection status display
- Ring animation connect button
- SVG country flags with real location detection
- FluxTun custom TUN library integration
- ARMv7 architecture support
- Improved socket protection
- Real country detection via Cloudflare

### Changed
- Complete UI overhaul with modern design
- Bottom navigation with smooth animations
- Glass-style cards and components

### Fixed
- Socket protection for VPN connections
- Country flag display issues

## [1.0.0] - 2025-12-01

### Added
- Initial release
- VMess, VLESS, Trojan, Shadowsocks protocol support
- TCP, WebSocket, HTTP/2, gRPC, QUIC, XHTTP, HTTPUpgrade transports
- Subscription management
- Per-App proxy (Split Tunneling)
- QR code scan and generate
- Backup & Restore configs
- Light/Dark mode support
- Real-time statistics

---

## Legend
- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements
- **Technical**: Technical changes and updates
