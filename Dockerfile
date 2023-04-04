## The custom Flutter engine
##
## Must use bionic (18.04) so that `buildroot` scripts run properly:
## https://github.com/flutter/buildroot/blob/master/build/install-build-deps.sh#L68
FROM --platform=amd64 ubuntu:bionic AS build

# Fix warnings related to: https://github.com/moby/moby/issues/27988
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install download dependencies
RUN apt-get update && apt-get install -y apt-utils
RUN apt-get install -y curl git python3 python3-pip

# Install Chrome depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
ENV PATH="/depot_tools:${PATH}"

# Download the custom Flutter engine
WORKDIR /engine
COPY dot_gclient .gclient
# Could sync to a specific version using:
# gclient sync --revision src/flutter@GIT_COMMIT_OR_REF
RUN gclient sync \
        --no-history \
        --shallow \
        --verbose

# Install build dependencies
WORKDIR /engine/src
RUN apt-get install -y lsb-core sudo
RUN ./build/install-build-deps-android.sh --no-prompt
RUN ./build/install-build-deps.sh --no-prompt

# Record our version
# This probably should be passed into the build?
RUN echo $(git rev-parse HEAD) > /engine-version

# FIXME: Break the updater build into separate image if we know how to
# depend on the ndk from the engine image.
# Build Updater library
WORKDIR /

# Install dependencies
RUN apt-get install -y unzip cmake ninja-build

# Install rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install rust
RUN rustup target add \
        aarch64-linux-android \
        armv7-linux-androideabi \
        i686-linux-android \
        x86_64-linux-android

# Use the NDK bundled with the engine
ENV ANDROID_NDK_HOME="/engine/src/third_party/android_tools/ndk"
RUN cargo install cargo-ndk

# Build the updater library
RUN git clone https://github.com/shorebirdtech/shorebird
WORKDIR /shorebird/updater/library
# Use -p 16 to match Flutter's minAndroidSdkVersion
RUN cargo ndk \
        -p 16 \
        --target=aarch64-linux-android \
        --target=armv7-linux-androideabi \
        # --target=i686-linux-android \
        # --target=x86_64-linux-android \
        # -o /out \
        build --release

# Patch the engine with the updater library
# These match paths set in flutter/shell/platform/android/BUILD.gn
WORKDIR /engine/src/flutter/updater
COPY /shorebird/updater/library/include/updater.h .
WORKDIR /engine/src/flutter/updater/android_aarch64
COPY /shorebird/updater/target/aarch64-linux-android/release/libupdater.a .
WORKDIR /engine/src/flutter/updater/android_arm
COPY /shorebird/updater/target/aarch64-linux-android/release/libupdater.a .


# Compile the engine using the steps here:
# https://github.com/flutter/flutter/wiki/Compiling-the-engine#compiling-for-android-from-macos-or-linux
WORKDIR /engine/src

# We don't need to build host tools.
# RUN ./flutter/tools/gn --no-goma --runtime-mode=release
# RUN ninja -C out/host_release

# Android Arm64
RUN ./flutter/tools/gn --no-goma --android --android-cpu arm64 --runtime-mode=release
RUN ninja -C out/android_release_arm64

# Android Arm32
RUN ./flutter/tools/gn --no-goma --android --runtime-mode=release
RUN ninja -C out/android_release

# RUN ./flutter/tools/gn --no-goma --android --android-cpu x86 --runtime-mode=release
# RUN ninja -C out/android_release_x86
# RUN ./flutter/tools/gn --no-goma --android --android-cpu x64 --runtime-mode=release
# RUN ninja -C out/android_release_x64


# Copy our modified artifacts to Google Cloud Storage.
FROM google/cloud-sdk:alpine AS upload
COPY --from=build /engine/src/out/android_release_arm64/zip_archives /out/android_release_arm64
COPY --from=build /engine/src/out/android_release/zip_archives /out/android_release
COPY --from=build /engine-version /out/VERSION

# Only need the libflutter.so (and flutter.jar) artifacts
RUN gsutil cp /out/android_release_arm64/artifact.zip gs://download.shorebird.dev/$(cat /out/VERSION)/
RUN gsutil cp /out/android_release_arm64/symbols.zip gs://download.shorebird.dev/$(cat /out/VERSION)/

RUN gsutil cp /out/android_release/artifact.zip gs://download.shorebird.dev/$(cat /out/VERSION)/
RUN gsutil cp /out/android_release/symbols.zip gs://download.shorebird.dev/$(cat /out/VERSION)/