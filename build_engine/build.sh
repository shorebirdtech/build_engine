#!/bin/sh -e

# FIXME: This script should be deleted and instead these steps be part
# of the GN build process.
# I haven't investigated how to build rust from GN with the Android NDK yet.

# Usage:
# ./build.sh engine_path

ENGINE_ROOT=$1

ENGINE_SRC=$ENGINE_ROOT/src
ENGINE_OUT=$ENGINE_SRC/out
UPDATER_SRC=$ENGINE_SRC/third_party/updater

# Build the Rust library.
cd $UPDATER_SRC/library

# Use the same NDK as the Flutter engine.
# Use -p 16 to match Flutter's minAndroidSdkVersion
NDK_HOME="$ENGINE_SRC/third_party/android_tools/ndk" \
    cargo ndk \
    -p 16 \
    --target armv7-linux-androideabi \
    build --release

# Flutter's NDK only includes libunwind for armv7 our current Rust build
# seems to depend on it existing:
# https://github.com/flutter/flutter/issues/124280
# FIXME: Using Android Studio NDK for now, this won't work on the bots!
cargo ndk \
    --target aarch64-linux-android \
    --target x86_64-linux-android \
    --target i686-linux-android \
    build --release

# Patch the engine with the updater library
# These match paths set in flutter/shell/platform/android/BUILD.gn
UPDATER_OUT=$ENGINE_SRC/flutter/updater
mkdir -p $UPDATER_OUT
cp $UPDATER_SRC/library/include/updater.h $UPDATER_OUT

mkdir -p $UPDATER_OUT/android_aarch64
cp $UPDATER_SRC/target/aarch64-linux-android/release/libupdater.a $UPDATER_OUT/android_aarch64

mkdir -p $UPDATER_OUT/android_arm
cp $UPDATER_SRC/target/armv7-linux-androideabi/release/libupdater.a $UPDATER_OUT/android_arm

mkdir -p $UPDATER_OUT/android_x64
cp $UPDATER_SRC/target/x86_64-linux-android/release/libupdater.a $UPDATER_OUT/android_x64

mkdir -p $UPDATER_OUT/android_x86
cp $UPDATER_SRC/target/i686-linux-android/release/libupdater.a $UPDATER_OUT/android_x86

# Build the patch tool.
# Again, this belongs as part of the gn build.
cd $UPDATER_SRC/patch
cargo build --release

# Compile the engine using the steps here:
# https://github.com/flutter/flutter/wiki/Compiling-the-engine#compiling-for-android-from-macos-or-linux
cd $ENGINE_SRC

# Android arm64 release
./flutter/tools/gn --android --android-cpu=arm64 --runtime-mode=release --no-goma
ninja -C ./out/android_release_arm64

# Android arm32 release
./flutter/tools/gn --android --runtime-mode=release --no-goma
ninja -C ./out/android_release

# Android x64 release
./flutter/tools/gn --android --android-cpu=x64 --runtime-mode=release --no-goma
ninja -C ./out/android_release_x64

# Android x86 release
./flutter/tools/gn --android --android-cpu=x86 --runtime-mode=release --no-goma
ninja -C ./out/android_release_x86
