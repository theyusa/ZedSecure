# Building hev-socks5-tunnel for ZedSecure

## Prerequisites

1. **Android NDK** installed and `NDK_HOME` environment variable set
2. **hev-socks5-tunnel** source code at `../hev-socks5-tunnel-main`

## Build Steps

### Windows (PowerShell)

```powershell
# Set NDK_HOME if not already set
$env:NDK_HOME = "C:\Android\sdk\ndk\26.1.10909125"  # Update with your NDK path

# Fix Windows symlink issue (only needed once)
.\fix-hevtun-symlinks.ps1

# Run the build script
.\compile-hevtun.ps1
```

### Linux/macOS (Bash)

```bash
# Make the script executable
chmod +x compile-hevtun.sh

# Run the build script
./compile-hevtun.sh
```

This will:
- Build hev-socks5-tunnel for all Android architectures (armeabi-v7a, arm64-v8a, x86, x86_64)
- Copy the compiled `.so` files to `android/app/src/main/jniLibs/`

### 2. Build the APK

```bash
# Build debug APK
flutter build apk --debug

# Build release APK with split per ABI
flutter build apk --release --split-per-abi
```

## Setting up NDK_HOME

### Windows
```powershell
# Temporary (current session only)
$env:NDK_HOME = "C:\Android\sdk\ndk\26.1.10909125"

# Permanent (system environment variable)
[System.Environment]::SetEnvironmentVariable("NDK_HOME", "C:\Android\sdk\ndk\26.1.10909125", "User")
```

### Linux/macOS
```bash
# Add to ~/.bashrc or ~/.zshrc
export NDK_HOME=/path/to/android-ndk

# Or temporary
export NDK_HOME=/path/to/android-ndk
```

## What is hev-socks5-tunnel?

hev-socks5-tunnel (also known as "New TUN" in v2rayNG) is a lightweight, high-performance tun2socks implementation that:

- Redirects TCP/UDP traffic through a SOCKS5 proxy
- Supports IPv4/IPv6 dual stack
- Has better performance than traditional TUN implementations
- Uses less memory and CPU

## Architecture

```
┌─────────────────┐
│   Flutter App   │
│   (Dart/UI)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  HevTunService  │
│   (Kotlin)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   JNI Wrapper   │
│   (hev_jni.c)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ hev-socks5-     │
│    tunnel       │
│  (Native C)     │
└─────────────────┘
```

## Files Structure

```
ZedSecure/
├── compile-hevtun.sh                          # Build script
├── android/app/src/main/
│   ├── kotlin/com/zedsecure/vpn/
│   │   └── HevTunService.kt                   # Kotlin service
│   ├── cpp/
│   │   ├── CMakeLists.txt                     # CMake config
│   │   └── hev_jni.c                          # JNI wrapper
│   └── jniLibs/                               # Compiled .so files (generated)
│       ├── armeabi-v7a/
│       │   └── libhev-socks5-tunnel.so
│       ├── arm64-v8a/
│       │   └── libhev-socks5-tunnel.so
│       ├── x86/
│       │   └── libhev-socks5-tunnel.so
│       └── x86_64/
│           └── libhev-socks5-tunnel.so
```

## Usage in Code

```kotlin
val hevTun = HevTunService(
    context = context,
    vpnInterface = vpnInterface,
    socksPort = 10808,
    mtu = 9000,
    ipv4Address = "10.10.14.1",
    ipv6Address = "fc00::1",
    preferIpv6 = false
)

// Start the tunnel
hevTun.start()

// Get statistics
val stats = hevTun.getStats()
// stats[0] = tx_packets
// stats[1] = tx_bytes
// stats[2] = rx_packets
// stats[3] = rx_bytes

// Stop the tunnel
hevTun.stop()
```

## Configuration

The tunnel is configured via YAML format:

```yaml
tunnel:
  mtu: 9000
  ipv4: 10.10.14.1
  ipv6: 'fc00::1'

socks5:
  port: 10808
  address: 127.0.0.1
  udp: 'udp'

misc:
  tcp-read-write-timeout: 300000
  udp-read-write-timeout: 60000
  log-level: warn
```

## Troubleshooting

### Windows: NDK_HOME not found
```powershell
# Check if NDK_HOME is set
$env:NDK_HOME

# Set it temporarily
$env:NDK_HOME = "C:\Android\sdk\ndk\26.1.10909125"

# Or find your NDK path
Get-ChildItem "C:\Android\sdk\ndk" -Directory
```

### Windows: ndk-build.cmd not found
Make sure you have NDK installed via Android Studio SDK Manager.

### Windows: Permission denied or symlink issues
Windows doesn't handle Unix symlinks properly. The header files in `hev-task-system/include/` are symlinks that appear as text files containing relative paths.

**Solution:**
```powershell
# Run the fix script to replace symlinks with actual files
.\fix-hevtun-symlinks.ps1
```

This script automatically replaces all symlink files with their actual header content.

### Linux/macOS: NDK_HOME not found
```bash
export NDK_HOME=/path/to/android-ndk
```

### hev-socks5-tunnel source not found
Make sure the source is at `../hev-socks5-tunnel-main` relative to ZedSecure directory.

```bash
# Clone it if needed
cd ..
git clone --recursive https://github.com/heiher/hev-socks5-tunnel hev-socks5-tunnel-main
cd ZedSecure
```

### Library not loaded
Check that `libhev-socks5-tunnel.so` exists in `android/app/src/main/jniLibs/` for all architectures.

## References

- [hev-socks5-tunnel GitHub](https://github.com/heiher/hev-socks5-tunnel)
