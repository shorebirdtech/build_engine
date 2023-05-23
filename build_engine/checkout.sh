#!/bin/sh -e

# This script checks out the git repos needed to build the engine.
# These are:
#   https://chromium.googlesource.com/chromium/tools/depot_tools.git
#     - This is used to check out our fork of the Flutter engine
#   https://github.com/shorebirdtech/flutter
#   https://github.com/shorebirdtech/engine (via gclient sync)
#     - This contains our fork of the Flutter engine and the updater
#   https://github.com:shorebirdtech/_shorebird
#     - This contains `shorebird` as a submodule
#     - NOTE: this is a private repo and requires permission to clone
#
# This also checkouts out Chromium's depot_tools, which we use for our engine
# checkout.
# 
# Usage:
# $ ./checkout.sh ~/.engine_checkout
#
# This will check out all necessary repos into the ~/.engine_checkout directory.


CHECKOUT_ROOT=$1

if [ -z "$CHECKOUT_ROOT" ]; then
    echo "Missing argument: checkout_root"
    echo "Usage: $0 checkout_root"
    exit 1
fi

mkdir -p $CHECKOUT_ROOT
cd $CHECKOUT_ROOT

check_out_depot_tools() {
    if [[ ! -d "depot_tools" ]]; then
        git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    fi
}

check_out_build_engine() {
    if [[ ! -d "build_engine" ]]; then
        git clone git@github.com:shorebirdtech/build_engine.git
    fi
}

check_out_flutter_fork() {
    if [[ ! -d "flutter" ]]; then
        git clone git@github.com:shorebirdtech/flutter.git
    fi
    cd flutter
    if [[ ! $(git config --get remote.upstream.url) ]]; then
        git remote add upstream https://github.com/flutter/flutter
    fi
    git fetch upstream
    cd ..
}

check_out__shorebird() {
    if [[ ! -d "_shorebird" ]]; then
        git clone git@github.com:shorebirdtech/_shorebird.git
    fi
    cd _shorebird # cwd: $CHECKOUT_ROOT/_shorebird
    git submodule init
    git submodule update
    cd .. # cwd: $CHECKOUT_ROOT
}

check_out_engine() {
    if [[ ! -d "engine" ]]; then
        mkdir engine
    fi

    cd engine # cwd: $CHECKOUT_ROOT/engine
    curl https://raw.githubusercontent.com/shorebirdtech/build_engine/main/build_engine/dot_gclient > .gclient
    ../depot_tools/gclient sync

    cd src
    git checkout shorebird/main
    cd ..
    gclient sync

    cd src/flutter # cwd: $CHECKOUT_ROOT/engine/src/flutter
    if [[ ! $(git config --get remote.upstream.url) ]]; then
        git remote add upstream https://github.com/flutter/engine
    fi
    git fetch upstream
    
    cd ../../.. # cwd: $CHECKOUT_ROOT
}

check_out_depot_tools
check_out__shorebird
check_out_flutter_fork
check_out_engine
