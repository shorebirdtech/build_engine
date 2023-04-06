#!/bin/sh -e

# Usage:
# ./build.sh git_hash [engine_path]

ENGINE_HASH=$1
# The path to the Flutter engine.
ENGINE_ROOT="${2:-/engine}"

echo "Building engine at $1 and uploading to gs://$BUCKET_NAME"

# First update our checkouts to the correct versions.
cd $ENGINE_ROOT
gclient sync --revision src/flutter@$ENGINE_HASH

# Then run the build (this should just be a ninja call).
./build_no_sync.sh $ENGINE_ROOT

# Copy Shorebird engine artifacts to Google Cloud Storage.
./upload.sh $ENGINE_HASH $ENGINE_ROOT
