#!/bin/sh -e

# Usage:
# ./build.sh engine_path engine_hash

# The path to the Flutter engine.
ENGINE_ROOT=$1
ENGINE_HASH=$2

# Get the absolute path to the directory of this script.
SCRIPT_DIR=$(cd $(dirname $0) && pwd)

echo "Building engine at $ENGINE_ROOT and uploading to gs://download.shorebird.dev"

# First update our checkouts to the correct versions.
# gclient sync -r src/flutter@${ENGINE_HASH}
# doesn't seem to work, it seems to get stuck trying to
# rebase the engine repo. So we do it manually.
# Similar to https://bugs.chromium.org/p/chromium/issues/detail?id=584742
cd $ENGINE_ROOT/src/flutter
git fetch
git checkout $ENGINE_HASH

cd $ENGINE_ROOT
gclient sync


cd $SCRIPT_DIR
# Then run the build (this should just be a ninja call).
./build.sh $ENGINE_ROOT

# Copy Shorebird engine artifacts to Google Cloud Storage.
./upload.sh $ENGINE_ROOT $ENGINE_HASH
