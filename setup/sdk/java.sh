#!/bin/bash

# Function to install Java using SDKMAN
install_java() {
    if ! command -v sdk &> /dev/null; then
        echo "SDKMAN not found, installing..."
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi

    # Specify the version of Java to install
    JAVA_VERSION="11.0.11.hs-adpt"

    if ! sdk list java | grep -q "$JAVA_VERSION"; then
        echo "Installing Java $JAVA_VERSION..."
        sdk install java $JAVA_VERSION
        sdk default java $JAVA_VERSION
    else
        echo "Java $JAVA_VERSION is already installed."
    fi
}