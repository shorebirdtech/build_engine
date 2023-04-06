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
cd $ENGINE_ROOT
gclient sync --revision src/flutter@$ENGINE_HASH


cd $SCRIPT_DIR
# Then run the build (this should just be a ninja call).
./build.sh $ENGINE_ROOT

# Copy Shorebird engine artifacts to Google Cloud Storage.
./upload.sh $ENGINE_ROOT $ENGINE_HASH
