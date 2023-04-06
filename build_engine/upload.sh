#!/bin/sh -e

# Usage:
# ./upload.sh git_hash engine_path
ENGINE_HASH=$1
ENGINE_ROOT=$2

ENGINE_SRC=$ENGINE_ROOT/src
ENGINE_OUT=$ENGINE_SRC/out

# FIXME: This should not be in shell, it's too complicated/repetative.
# Only need the libflutter.so (and flutter.jar) artifacts
# Artifact list: https://github.com/shorebirdtech/shorebird/pull/222/commits/a1fbbf7b93029b90ebd79c9ffeaafd3ee475cf20

INFRA_ROOT="gs://download.shorebird.dev/flutter_infra_release/flutter/$ENGINE_HASH"
MAVEN_VER="1.0.0-$ENGINE_HASH"
MAVEN_ROOT="gs://download.shorebird.dev/download.flutter.io/io/flutter"

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