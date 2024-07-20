#!/bin/bash

# # Function to install Java using SDKMAN
# install_java() {
#     if ! command -v sdk &> /dev/null; then
#         echo "SDKMAN not found, installing..."
#         curl -s "https://get.sdkman.io" | bash
#         source "$HOME/.sdkman/bin/sdkman-init.sh"
#     fi

#     # Specify the version of Java to install
#     JAVA_VERSION="11.0.11.hs-adpt"

#     if ! sdk list java | grep -q "$JAVA_VERSION"; then
#         echo "Installing Java $JAVA_VERSION..."
#         sdk install java $JAVA_VERSION
#         sdk default java $JAVA_VERSION
#     else
#         echo "Java $JAVA_VERSION is already installed."
#     fi
# }

# Source the Homebrew install script to ensure Homebrew is installed
source "$(dirname "${BASH_SOURCE[0]}")/homebrew.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/update_zshrc.sh"

DEFAULT_JAVA_SDKMAN_SECTION_START="# Start JAVA_SDKMAN section"
DEFAULT_JAVA_SDKMAN_SECTION_END="# END JAVA_SDKMAN section"


# Function to check if SDKMAN! is installed
is_sdkman_installed() {
    if [ -d "$HOME/.sdkman" ]; then
        echo "SDKMAN! is installed."
        return 0
    else
        echo "SDKMAN! is not installed."
        return 1
    fi
}

# Function to install SDKMAN!
install_sdkman() {
    if ! is_sdkman_installed; then
        echo "Installing SDKMAN!..."
        curl -s "https://get.sdkman.io" | bash
        echo "SDKMAN! installation completed."

        # Initialize SDKMAN! in .zshrc
        initialize_sdkman_in_zshrc
        echo "SDKMAN! initialization added to $DEFAULT_ZSHRC_PATH."

        # Install Java
        install_zulu
    fi
}


# Function to initialize SDKMAN! in .zshrc
initialize_sdkman_in_zshrc() {

    if ! grep -q "$DEFAULT_JAVA_SDKMAN_SECTION_START" "$DEFAULT_ZSHRC_PATH"; then
        echo -e "\n$DEFAULT_JAVA_SDKMAN_SECTION_START\n$DEFAULT_JAVA_SDKMAN_SECTION_END" >> "$DEFAULT_ZSHRC_PATH"
    fi

    # Add SDKMAN initialization if not present
    if ! grep -q '\.sdkman/bin/sdkman-init.sh' "$DEFAULT_JAVA_SDKMAN_SECTION_START"; then
        sed -i '' "/$DEFAULT_JAVA_SDKMAN_SECTION_START/a\\
[[ -s \"\$HOME/.sdkman/bin/sdkman-init.sh\" ]] && source \"\$HOME/.sdkman/bin/sdkman-init.sh\"
" "$DEFAULT_ZSHRC_PATH"
        echo "SDKMAN! initialization added to $DEFAULT_ZSHRC_PATH."
    else
        echo "SDKMAN! initialization already present in $DEFAULT_ZSHRC_PATH."
    fi
}


# # Function to install Java using SDKMAN!
# install_java() {
#     # if ! is_java_installed; then
#         echo "Installing Java..."
#         source "$HOME/.sdkman/bin/sdkman-init.sh"
#         sdk install java
#         echo "Java installation completed."

#         # local java_home_path=$(sdk env init | grep JAVA_HOME | awk -F '=' '{print $2}')
#         # update_zshrc "JAVA_HOME" "$java_home_path"
#     # fi
# }


# # Function to check if Java is installed
# is_java_installed() {
#     echo "Checking if Java is installed..."
    
#     if command -v java &> /dev/null; then
#         echo "Java is installed."
#         java -version
#         return 0
#     else
#         echo "Java is not installed. Please visit http://www.java.com for information on installing Java."
#         return 1
#     fi
# }


# Function to check if zulu is installed
is_zulu_installed() {
    if brew list zulu &> /dev/null; then
        echo "zulu is installed."
        return 0
    else
        echo "zulu is not installed."
        return 1
    fi
}


# Function to install Zulu
install_zulu() {
    
    # Ensure homebrew is installed
    install_homebrew

    if ! is_zulu_installed; then
        echo "Installing Zulu..."
        brew install --cask zulu@17

        # Extract the Zulu version and update the JAVA_HOME path
        extract_and_update_zulu_version

        echo "Zulu installation completed."
    fi
}

# Function to Extract Zulu Version
extract_and_update_zulu_version () {
    echo "Extracting Zulu version..."
    
    # Run the brew command and capture the output
    brew_output=$(brew info --cask zulu@17)

    # Extract the full version number from the output
    full_version=$(echo "$brew_output" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)


    if [ -z "$full_version" ]; then
        echo "Could not determine the installed version of Zulu JDK."
        return 1
    fi

    # Extract the major version number
    major_version=$(echo "$full_version" | cut -d '.' -f 1)

    # Construct the JAVA_HOME path
    echo "Zulu major_version: $major_version"
    local java_home_path="/Library/Java/JavaVirtualMachines/zulu-${major_version}.jdk/Contents/Home/"
    
    # Update the JAVA_HOME path in .zshrc
    update_zshrc "JAVA_HOME" "$java_home_path"
}


export -f is_sdkman_installed
export -f install_sdkman
export -f is_zulu_installed
export -f install_zulu


# Call the install functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_sdkman
fi