## Dockerfile to set up a build environment for the Flutter engine.

## Must use bionic (18.04) so that `buildroot` scripts run properly:
## https://github.com/flutter/buildroot/blob/master/build/install-build-deps.sh#L68
FROM --platform=amd64 ubuntu:bionic AS build

# Fix warnings related to: https://github.com/moby/moby/issues/27988
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# List our SSH keys, to make sure they're there:
# RUN ls -al /workspace/root/.ssh
RUN ls -al ~/.ssh

# Test our SSH connection before continuing:
RUN ssh -T git@github.com

# Install download dependencies
RUN apt-get update && apt-get install -y apt-utils
RUN apt-get install -y curl git python3 python3-pip

# Install Chrome depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
ENV PATH="/depot_tools:${PATH}"

# Download the custom Flutter engine
WORKDIR /engine

# Flutter uses Chrome's depot_tools to manage dependencies.
# We need to create a .gclient file to tell it where to get the engine.
# See:
# https://chromium.googlesource.com/chromium/tools/depot_tools/+/HEAD/README.gclient.md
# Eventually we could re-work the Flutter engine to use Git Submodules.
COPY dot_gclient .gclient
RUN gclient sync \
        --no-history \
        --shallow \
        --verbose

# Install build dependencies
WORKDIR /engine/src
RUN apt-get install -y lsb-core sudo
RUN ./build/install-build-deps-android.sh --no-prompt
RUN ./build/install-build-deps.sh --no-prompt

# Install Rust dependencies
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

# Install `cargo ndk`
RUN cargo install cargo-ndk

COPY build.sh .
RUN chmod +x ./build.sh
ENTRYPOINT [ "/build.sh" ]