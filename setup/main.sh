#!/bin/bash

# Ensure the scipt is run from the directory containing the other script
cd "$(dirname "$0")"


# Install Homebrew
# ./sdk/homebrew.sh
# ./sdk/mas.sh
# ./sdk/node.sh
# ./sdk/nvm.sh
# ./sdk/watchman.sh
# ./sdk/xcode.sh
./sdk/docker.sh
# ./sdk/apps/db/postgres.sh


echo " All installations complete. Exiting..."


