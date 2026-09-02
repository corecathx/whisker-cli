#!/bin/bash

set -e

export WHISKER_VERSION="dev"
export WHISKER_COMMIT="dev"

echo "building whisker..."
haxe dev.hxml

echo "preparing executable..."
cd target/cpp
mv ./Main ./whisker
chmod +x ./whisker

echo "installing to /usr/bin..."
sudo mv ./whisker /usr/bin/whisker
echo "done!"