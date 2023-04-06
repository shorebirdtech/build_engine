#!/bin/sh -e

# Usage:
# ./build_engine git_hash [engine_path]

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
# FIXME: This should not be in shell, it's too complicated/repetative.
# Only need the libflutter.so (and flutter.jar) artifacts
# Artifact list: https://github.com/shorebirdtech/shorebird/pull/222/commits/a1fbbf7b93029b90ebd79c9ffeaafd3ee475cf20

INFRA_ROOT="gs://download.shorebird.dev/flutter_infra_release/flutter/$ENGINE_HASH"
MAVEN_VER="1.0.0-$ENGINE_HASH"
MAVEN_ROOT="gs://download.shorebird.dev/download.flutter.io/io/flutter/$MAVEN_VER"

# Android Arm64 release Flutter artifacts
ARCH_OUT=$ENGINE_OUT/android_release_arm64
ZIPS_OUT=$ARCH_OUT/zip_archives/android-arm64-release
ZIPS_DEST=$INFRA_ROOT/android-arm64-release
gsutil cp $ZIPS_OUT/artifacts.zip $ZIPS_DEST/artifacts.zip
gsutil cp $ZIPS_OUT/symbols.zip $ZIPS_DEST/symbols.zip
# Android Arm64 release Maven artifacts
ARCH_PATH=$ARCH_OUT/arm64_v8a_release
MAVEN_PATH=$MAVEN_ROOT/android-arm64-release/arm64_v8a_release-$MAVEN_VER
gsutil cp $ARCH_PATH.pom $MAVEN_PATH.pom
gsutil cp $ARCH_PATH.jar $MAVEN_PATH.jar
gsutil cp $ARCH_PATH.maven-metadata.xml $MAVEN_PATH.maven-metadata.xml

# Android Arm32 release Flutter artifacts
ARCH_OUT=$ENGINE_OUT/android_release
ZIPS_OUT=$ARCH_OUT/zip_archives/android-arm-release
ZIPS_DEST=$INFRA_ROOT/android-arm-release
gsutil cp $ZIPS_OUT/artifacts.zip $ZIPS_DEST/artifacts.zip
gsutil cp $ZIPS_OUT/symbols.zip $ZIPS_DEST/symbols.zip
# Android Arm32 release Maven artifacts
ARCH_PATH=$ARCH_OUT/armeabi_v7a_release
MAVEN_PATH=$MAVEN_ROOT/android-arm-release/armeabi_v7a_release-$MAVEN_VER
gsutil cp $ARCH_PATH.pom $MAVEN_PATH.pom
gsutil cp $ARCH_PATH.jar $MAVEN_PATH.jar
gsutil cp $ARCH_PATH.maven-metadata.xml $MAVEN_PATH.maven-metadata.xml

# Not sure which flutter_embedding_release files to use? 32 or 64 bit?
# It does not seem to contain the libflutter.so file, but does seem to
# differ between the two build dirs.
ARCH_OUT=$ENGINE_OUT/android_release
ARCH_PATH=$ARCH_OUT/flutter_embedding_release
MAVEN_PATH=$MAVEN_ROOT/android-arm-release/flutter_embedding_release-$MAVEN_VER
gsutil cp $ARCH_PATH.pom $MAVEN_PATH.pom
gsutil cp $ARCH_PATH.jar $MAVEN_PATH.jar
gsutil cp $ARCH_PATH.maven-metadata.xml $MAVEN_PATH.maven-metadata.xml