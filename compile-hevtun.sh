#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

if [[ ! -d $NDK_HOME ]]; then
  echo "Android NDK: NDK_HOME not found. please set env \$NDK_HOME"
  exit 1
fi

TMPDIR=$(mktemp -d)
clear_tmp () {
  rm -rf $TMPDIR
}
trap 'echo -e "Aborted, error $? in command: $BASH_COMMAND"; trap ERR; clear_tmp; exit 1' ERR INT

HEV_SOURCE="../hev-socks5-tunnel-main"

if [[ ! -d "$HEV_SOURCE" ]]; then
  echo "Error: hev-socks5-tunnel source not found at $HEV_SOURCE"
  exit 1
fi

mkdir -p "$TMPDIR/jni"
pushd "$TMPDIR"

echo 'include $(call all-subdir-makefiles)' > jni/Android.mk

ln -s "$(cd "$__dir/$HEV_SOURCE" && pwd)" jni/hev-socks5-tunnel

"$NDK_HOME/ndk-build" \
    NDK_PROJECT_PATH=. \
    APP_BUILD_SCRIPT=jni/Android.mk \
    "APP_ABI=armeabi-v7a arm64-v8a x86 x86_64" \
    APP_PLATFORM=android-24 \
    NDK_LIBS_OUT="$TMPDIR/libs" \
    NDK_OUT="$TMPDIR/obj" \
    "APP_CFLAGS=-O3 -DPKGNAME=com/zedsecure/vpn" \
    "APP_LDFLAGS=-Wl,--build-id=none -Wl,--hash-style=gnu" \

mkdir -p "$__dir/android/app/src/main/jniLibs"
cp -r "$TMPDIR/libs/"* "$__dir/android/app/src/main/jniLibs/"

popd
rm -rf $TMPDIR

echo "✅ hev-socks5-tunnel built successfully!"
echo "📦 Libraries copied to android/app/src/main/jniLibs/"
