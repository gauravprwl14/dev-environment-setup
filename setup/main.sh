#!/bin/bash

# Ensure the scipt is run from the directory containing the other script
cd "$(dirname "$0")"


# Install Homebrew
# ./sdk/homebrew.sh
# ./sdk/watchman.sh
# ./sdk/mas.sh
# ./sdk/nvm.sh
# ./sdk/node.sh
# ./sdk/java.sh
# ./sdk/android_studio.sh
# ./sdk/xcode.sh
# ./sdk/docker.sh
# ./sdk/apps/db/postgres.sh
# ./sdk/cocoapods.sh
# ./sdk/fvm.sh
# ./sdk/dart.sh
./sdk/flutter.sh


echo " All installations complete. Exiting..."


