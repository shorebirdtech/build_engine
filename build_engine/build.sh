#!/bin/sh -e

# Usage:
# ./build_engine git_hash

ENGINE_HASH=$1

# The path to the Flutter engine.
ENGINE_ROOT=/engine
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
ANDROID_NDK_HOME="/engine/src/third_party/android_tools/ndk"

# Build both the arm64 and armv7 versions of the library.
# Use -p 16 to match Flutter's minAndroidSdkVersion
cargo ndk \
    -p 16 \
    --target=aarch64-linux-android \
    --target=armv7-linux-androideabi \
    # --target=i686-linux-android \
    # --target=x86_64-linux-android \
    build --release

# FIXME: This should be part of the gn/ninja build process!
# I haven't investigated how to build rust from GN with the Android NDK yet.
# Patch the engine with the updater library
# These match paths set in flutter/shell/platform/android/BUILD.gn
UPDATER_OUT=/engine/src/flutter/updater
mkdir -p $UPDATER_OUT
cp $UPDATER_SRC/library/include/updater.h $UPDATER_OUT
mkdir -p $UPDATER_OUT/android_aarch64
COPY $UPDATER_SRC/target/aarch64-linux-android/release/libupdater.a $UPDATER_OUT/android_aarch64
mkdir -p $UPDATER_OUT/android_arm
COPY $UPDATER_SRC/target/armv7-linux-androideabi/release/libupdater.a $UPDATER_OUT/android_arm

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
# Only need the libflutter.so (and flutter.jar) artifacts
RUN gsutil cp $ENGINE_OUT/android_release_arm64/zip_archives/artifact.zip gs://download.shorebird.dev/$ENGINE_HASH/
RUN gsutil cp $ENGINE_OUT/android_release_arm64/zip_archives/symbols.zip gs://download.shorebird.dev/$ENGINE_HASH/

RUN gsutil cp $ENGINE_OUT/android_release/zip_archives/artifact.zip gs://download.shorebird.dev/$ENGINE_HASH/
RUN gsutil cp $ENGINE_OUT/android_release/zip_archives/symbols.zip gs://download.shorebird.dev/$ENGINE_HASH/