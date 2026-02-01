# Quick Build Guide for ZedSecure

## Windows (PowerShell)

### 1. Set NDK_HOME
```powershell
# Find your NDK path (usually in Android SDK)
$env:NDK_HOME = "C:\Users\YourName\AppData\Local\Android\Sdk\ndk\26.1.10909125"

# Or find it automatically
$ndkPath = Get-ChildItem "$env:LOCALAPPDATA\Android\Sdk\ndk" -Directory | Select-Object -First 1
$env:NDK_HOME = $ndkPath.FullName
```

### 2. Build hev-socks5-tunnel
```powershell
cd ZedSecure

# Fix Windows symlink issue (only needed once)
.\fix-hevtun-symlinks.ps1

# Build native libraries
.\compile-hevtun.ps1
```

### 3. Build APK
```powershell
flutter build apk --split-per-abi
```

---

## Common Issues

### "NDK_HOME not set"
```powershell
# Check current value
$env:NDK_HOME

# Set it (replace with your actual path)
$env:NDK_HOME = "C:\Users\Beny\AppData\Local\Android\Sdk\ndk\26.1.10909125"
```

### "hev-socks5-tunnel source not found"
```powershell
# Clone it to parent directory
cd ..
git clone --recursive https://github.com/heiher/hev-socks5-tunnel hev-socks5-tunnel-main
cd ZedSecure
```

This replaces symlink files with actual header files.

### "ndk-build.cmd not found"
Install NDK via Android Studio:
1. Open Android Studio
2. Tools → SDK Manager
3. SDK Tools tab
4. Check "NDK (Side by side)"
5. Click Apply

---

## Output

After successful build, you'll find:
- Native libraries: `android/app/src/main/jniLibs/`
  - `armeabi-v7a/libhev-socks5-tunnel.so`
  - `arm64-v8a/libhev-socks5-tunnel.so`
  - `x86/libhev-socks5-tunnel.so`
  - `x86_64/libhev-socks5-tunnel.so`

- APK files: `build/app/outputs/flutter-apk/`
  - `app-armeabi-v7a-release.apk`
  - `app-arm64-v8a-release.apk`
  - `app-x86-release.apk`
  - `app-x86_64-release.apk`

---

## Full Documentation

See [BUILD_HEVTUN.md](BUILD_HEVTUN.md) for detailed information.
