# PowerShell script to build hev-socks5-tunnel for Android

$ErrorActionPreference = "Stop"

Write-Host "=== Building hev-socks5-tunnel for ZedSecure ===" -ForegroundColor Cyan

# Check NDK_HOME
if (-not $env:NDK_HOME) {
    Write-Host "ERROR: NDK_HOME environment variable not set!" -ForegroundColor Red
    Write-Host "Please set NDK_HOME to your Android NDK path" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $env:NDK_HOME)) {
    Write-Host "ERROR: NDK_HOME path does not exist: $env:NDK_HOME" -ForegroundColor Red
    exit 1
}

Write-Host "OK NDK_HOME found: $env:NDK_HOME" -ForegroundColor Green

# Check hev-socks5-tunnel source
$HEV_SOURCE = "..\hev-socks5-tunnel-main"
if (-not (Test-Path $HEV_SOURCE)) {
    Write-Host "ERROR: hev-socks5-tunnel source not found at: $HEV_SOURCE" -ForegroundColor Red
    Write-Host "Please clone hev-socks5-tunnel to the parent directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "OK hev-socks5-tunnel source found" -ForegroundColor Green

# Create temporary directory
$TMPDIR = New-Item -ItemType Directory -Path "$env:TEMP\hevtun-build-$(Get-Random)" -Force
Write-Host "OK Created temp directory: $TMPDIR" -ForegroundColor Green

try {
    # Create jni directory
    $JNI_DIR = New-Item -ItemType Directory -Path "$TMPDIR\jni" -Force
    
    # Create Android.mk
    "include `$(call all-subdir-makefiles)" | Out-File -FilePath "$JNI_DIR\Android.mk" -Encoding ASCII -NoNewline
    Write-Host "OK Created Android.mk" -ForegroundColor Green
    
    # Copy hev-socks5-tunnel source
    $HEV_ABS_PATH = Resolve-Path $HEV_SOURCE
    $LINK_PATH = "$JNI_DIR\hev-socks5-tunnel"
    
    Write-Host "Copying hev-socks5-tunnel source..." -ForegroundColor Yellow
    Copy-Item -Path $HEV_ABS_PATH -Destination $LINK_PATH -Recurse -Force
    
    Write-Host "Fixing all symlinks..." -ForegroundColor Yellow
    
    $symlinkDirs = @(
        "$LINK_PATH\third-part\hev-task-system\include",
        "$LINK_PATH\third-part\yaml\include",
        "$LINK_PATH\src\core\include"
    )
    
    foreach ($dir in $symlinkDirs) {
        if (Test-Path $dir) {
            Get-ChildItem -Path $dir -Filter "*.h" -Recurse | ForEach-Object {
                $symlinkFile = $_.FullName
                $content = Get-Content $symlinkFile -Raw -ErrorAction SilentlyContinue
                
                if ($content -and $content.Trim().StartsWith("..")) {
                    $relativePath = $content.Trim()
                    $targetFile = Join-Path $_.DirectoryName $relativePath
                    $targetFile = [System.IO.Path]::GetFullPath($targetFile)
                    
                    if (Test-Path $targetFile) {
                        Copy-Item -Path $targetFile -Destination $symlinkFile -Force
                    }
                }
            }
        }
    }
    
    Write-Host "OK Copied and fixed hev-socks5-tunnel source" -ForegroundColor Green
    
    # Run ndk-build
    Write-Host "`nBuilding native libraries..." -ForegroundColor Cyan
    $NDK_BUILD = Join-Path $env:NDK_HOME "ndk-build.cmd"
    
    if (-not (Test-Path $NDK_BUILD)) {
        Write-Host "ERROR: ndk-build.cmd not found at: $NDK_BUILD" -ForegroundColor Red
        exit 1
    }
    
    Push-Location $TMPDIR
    
    & $NDK_BUILD `
        "NDK_PROJECT_PATH=." `
        "APP_BUILD_SCRIPT=jni/Android.mk" `
        "APP_ABI=armeabi-v7a arm64-v8a x86 x86_64" `
        "APP_PLATFORM=android-24" `
        "NDK_LIBS_OUT=$TMPDIR\libs" `
        "NDK_OUT=$TMPDIR\obj" `
        "APP_CFLAGS=-O3 -DPKGNAME=dev/amirzr/flutter_v2ray_client/v2ray/core"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: ndk-build failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Pop-Location
    
    Write-Host "OK Build completed successfully" -ForegroundColor Green
    
    # Copy libraries to jniLibs
    $JNILIBS_DIR = "android\app\src\main\jniLibs"
    if (-not (Test-Path $JNILIBS_DIR)) {
        New-Item -ItemType Directory -Path $JNILIBS_DIR -Force | Out-Null
    }
    
    Write-Host "`nCopying libraries to $JNILIBS_DIR..." -ForegroundColor Cyan
    
    $LIBS_SOURCE = "$TMPDIR\libs"
    if (Test-Path $LIBS_SOURCE) {
        Copy-Item -Path "$LIBS_SOURCE\*" -Destination $JNILIBS_DIR -Recurse -Force
        Write-Host "OK Libraries copied successfully" -ForegroundColor Green
        
        # List copied files
        Write-Host "`nCopied libraries:" -ForegroundColor Cyan
        Get-ChildItem -Path $JNILIBS_DIR -Recurse -Filter "*.so" | ForEach-Object {
            $size = [math]::Round($_.Length / 1KB, 2)
            Write-Host "  $($_.Name) - $size KB" -ForegroundColor Gray
        }
    } else {
        Write-Host "ERROR: Build output not found at $LIBS_SOURCE" -ForegroundColor Red
        exit 1
    }
    
} finally {
    # Cleanup
    Write-Host "`nCleaning up temporary files..." -ForegroundColor Yellow
    Remove-Item -Path $TMPDIR -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "OK Cleanup completed" -ForegroundColor Green
}

Write-Host "`n=== Build completed successfully! ===" -ForegroundColor Green
Write-Host "You can now build the APK with: flutter build apk --split-per-abi" -ForegroundColor Cyan
