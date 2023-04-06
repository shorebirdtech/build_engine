#!/bin/sh -e

# Usage:
# ./build.sh git_hash [engine_path]

ENGINE_HASH=$1

# The path to the Flutter engine.
ENGINE_ROOT="${2:-/engine}"
ENGINE_SRC=$ENGINE_ROOT/src
ENGINE_OUT=$ENGINE_SRC/out
UPDATER_SRC=$ENGINE_SRC/third_party/updater

BUCKET_NAME=download.shorebird.dev

echo "Building engine at $1 and uploading to gs://$BUCKET_NAME"

# First update our checkouts to the correct versions.
cd $ENGINE_ROOT
gclient sync --revision src/flutter@$ENGINE_HASH


# Build the Rust library.
cd $UPDATER_SRC/library

# Use the same NDK as the Flutter engine.


# FIXME: This should be part of the gn/ninja build process!
# I haven't investigated how to build rust from GN with the Android NDK yet.

# Build both the arm64 and armv7 versions of the library.
# Use -p 16 to match Flutter's minAndroidSdkVersion
NDK_HOME="$ENGINE_SRC/third_party/android_tools/ndk" cargo ndk -p 16 -t armeabi-v7a build --release

# However aarch64-linux-android16-clang only starts at v21, unsure which
# the Flutter engine uses, using most recent for now?
# Unfortuantely Flutter's NDK doesn't seem to include libunwind?
# https://github.com/flutter/flutter/issues/124280
# FIXME: Using Android Studio NDK for now, this won't work on the bots!
cargo ndk -t arm64-v8a build --release

# Patch the engine with the updater library
# These match paths set in flutter/shell/platform/android/BUILD.gn
UPDATER_OUT=$ENGINE_SRC/flutter/updater
mkdir -p $UPDATER_OUT
cp $UPDATER_SRC/library/include/updater.h $UPDATER_OUT
mkdir -p $UPDATER_OUT/android_aarch64
cp $UPDATER_SRC/target/aarch64-linux-android/release/libupdater.a $UPDATER_OUT/android_aarch64
mkdir -p $UPDATER_OUT/android_arm
cp $UPDATER_SRC/target/armv7-linux-androideabi/release/libupdater.a $UPDATER_OUT/android_arm

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

# Copy Shorebird engine artifacts to Google Cloud Storage.
./upload.sh $ENGINE_HASH $ENGINE_ROOT
