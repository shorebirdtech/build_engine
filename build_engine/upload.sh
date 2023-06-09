#!/bin/sh -e

# Usage:
# ./upload.sh engine_path git_hash
ENGINE_ROOT=$1
ENGINE_HASH=$2

STORAGE_BUCKET="download.shorebird.dev"
SHOREBIRD_ROOT=gs://$STORAGE_BUCKET/shorebird/$ENGINE_HASH

ENGINE_SRC=$ENGINE_ROOT/src
ENGINE_OUT=$ENGINE_SRC/out
ENGINE_FLUTTER=$ENGINE_SRC/flutter

cd $ENGINE_FLUTTER
# `cutler` would know how to calculate this.
# Can't just `git merge-base` because the engine branches for each
# major version (e.g. 3.7, 3.8) (e.g. upstream/flutter-3.7-candidate.1)
# but it's not clear which branch we're forked from, only that we took
# some tag and added our commits (but we don't know what tag).
BASE_ENGINE_TAG=`git describe --tags --abbrev=0`
BASE_ENGINE_HASH=`git rev-parse $BASE_ENGINE_TAG`

# Build the artifacts manifest:
MANIFEST_FILE=`mktemp`
# This is a hack, assuming we have a _shorebird checkout next to the engine.
cd $ENGINE_ROOT/../_shorebird
./shorebird/packages/artifact_proxy/tool/generate_manifest.sh $BASE_ENGINE_HASH > $MANIFEST_FILE

# FIXME: This should not be in shell, it's too complicated/repetative.
# Only need the libflutter.so (and flutter.jar) artifacts
# Artifact list: https://github.com/shorebirdtech/shorebird/blob/main/packages/artifact_proxy/lib/config.dart

INFRA_ROOT="gs://$STORAGE_BUCKET/flutter_infra_release/flutter/$ENGINE_HASH"
MAVEN_VER="1.0.0-$ENGINE_HASH"
MAVEN_ROOT="gs://$STORAGE_BUCKET/download.flutter.io/io/flutter"

# Android Arm64 release Flutter artifacts
ARCH_OUT=$ENGINE_OUT/android_release_arm64
ZIPS_OUT=$ARCH_OUT/zip_archives/android-arm64-release
ZIPS_DEST=$INFRA_ROOT/android-arm64-release
gsutil cp $ZIPS_OUT/artifacts.zip $ZIPS_DEST/artifacts.zip
gsutil cp $ZIPS_OUT/symbols.zip $ZIPS_DEST/symbols.zip
# Android Arm64 release Maven artifacts
ARCH_PATH=$ARCH_OUT/arm64_v8a_release
MAVEN_PATH=$MAVEN_ROOT/arm64_v8a_release/$MAVEN_VER/arm64_v8a_release-$MAVEN_VER
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
MAVEN_PATH=$MAVEN_ROOT/armeabi_v7a_release/$MAVEN_VER/armeabi_v7a_release-$MAVEN_VER
gsutil cp $ARCH_PATH.pom $MAVEN_PATH.pom
gsutil cp $ARCH_PATH.jar $MAVEN_PATH.jar
gsutil cp $ARCH_PATH.maven-metadata.xml $MAVEN_PATH.maven-metadata.xml

# Not sure which flutter_embedding_release files to use? 32 or 64 bit?
# It does not seem to contain the libflutter.so file, but does seem to
# differ between the two build dirs.
ARCH_OUT=$ENGINE_OUT/android_release
ARCH_PATH=$ARCH_OUT/flutter_embedding_release
MAVEN_PATH=$MAVEN_ROOT/flutter_embedding_release/$MAVEN_VER/flutter_embedding_release-$MAVEN_VER
gsutil cp $ARCH_PATH.pom $MAVEN_PATH.pom
gsutil cp $ARCH_PATH.jar $MAVEN_PATH.jar
gsutil cp $ARCH_PATH.maven-metadata.xml $MAVEN_PATH.maven-metadata.xml

# Android x64 release Flutter artifacts
ARCH_OUT=$ENGINE_OUT/android_release_x64
ZIPS_OUT=$ARCH_OUT/zip_archives/android-x64-release
ZIPS_DEST=$INFRA_ROOT/android-x64-release
gsutil cp $ZIPS_OUT/artifacts.zip $ZIPS_DEST/artifacts.zip
gsutil cp $ZIPS_OUT/symbols.zip $ZIPS_DEST/symbols.zip
# Android x64 release Maven artifacts
ARCH_PATH=$ARCH_OUT/x86_64_release
MAVEN_PATH=$MAVEN_ROOT/x86_64_release/$MAVEN_VER/x86_64_release-$MAVEN_VER
gsutil cp $ARCH_PATH.pom $MAVEN_PATH.pom
gsutil cp $ARCH_PATH.jar $MAVEN_PATH.jar
gsutil cp $ARCH_PATH.maven-metadata.xml $MAVEN_PATH.maven-metadata.xml

# This is a hack.  We build/upload the Mac amr64 patch tool from this machine
# and pull down (hopefully the correct version of) the tool from GHA.
gsutil cp $ENGINE_OUT/host_release_arm64/patch.zip $SHOREBIRD_ROOT/patch-darwin-arm64.zip

TMP_DIR=$(mktemp -d)

PATCH_VERSION=0.0.0
GH_RELEASE=https://github.com/shorebirdtech/updater/releases/download/patch-v$PATCH_VERSION/
cd $TMP_DIR
curl -L $GH_RELEASE/patch-x86_64-apple-darwin.zip -o patch-x86_64-apple-darwin.zip
curl -L $GH_RELEASE/patch-x86_64-pc-windows-msvc.zip -o patch-x86_64-pc-windows-msvc.zip
curl -L $GH_RELEASE/patch-x86_64-unknown-linux-gnu.zip -o patch-x86_64-unknown-linux-gnu.zip

gsutil cp patch-x86_64-apple-darwin.zip $SHOREBIRD_ROOT/patch-darwin-x64.zip
gsutil cp patch-x86_64-pc-windows-msvc.zip $SHOREBIRD_ROOT/patch-windows-x64.zip
gsutil cp patch-x86_64-unknown-linux-gnu.zip $SHOREBIRD_ROOT/patch-linux-x64.zip

gsutil cp $MANIFEST_FILE $SHOREBIRD_ROOT/artifacts_manifest.yaml


# Match the upload pattern from iOS:
# https://github.com/flutter/engine/commit/1d7f0c66c316a37105601b13136f890f6595aebc