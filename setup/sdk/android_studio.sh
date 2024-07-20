#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../utils/update_zshrc.sh"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if wget and tar are installed
if ! command_exists curl; then
    echo "wget is not installed. Please install wget and try again."
    exit 1
fi

if ! command_exists hdiutil; then
    echo "hdiutil is not installed. Please ensure you are running on macOS."
    exit 1
fi

if ! command_exists tar; then
    echo "tar is not installed. Please install tar and try again."
    exit 1
fi
if ! command_exists shasum; then
    echo "shasum is not installed. Please install shasum and try again."
    exit 1
fi

# Define the output file name
OUTPUT_FILE="android-studio-latest-mac-m3_01.dmg"

# Define the mount point
MOUNT_POINT="/Volumes/AndroidStudio"

# Main function to install Android Studio
main_install_android_studio() {

    fetch_android_studio_url
    download_android_studio
    mount_dmg
    find_android_studio_app
    install_android_studio
    unmount_dmg
    cleanup

    add_to_path
    
    # todo:
    # 1. install command line tools
    # 2. install sdk manager

    setupSDK
    setupAVD
    echo "Android Studio installed successfully."
}

# Function to fetch the latest Android Studio download URL
fetch_android_studio_url() {
    echo "Fetching the latest version of Android Studio..."

    # Variables for Android Studio download URL components
    BASE_URL="https://redirector.gvt1.com/edgedl/android/studio/install"
    VERSION="2024.1.1.12"
    FILENAME="android-studio-${VERSION}-mac_arm.dmg"

     android_studio_url="${BASE_URL}/${VERSION}/${FILENAME}"

    if [ -z "$android_studio_url" ]; then
        echo "Failed to fetch the download URL for Android Studio."
        exit 1
    fi

    echo "Download URL: $android_studio_url"


}

# Function to find the correct path of Android Studio.app in the mounted volume
find_android_studio_app() {
    echo "Finding Android Studio.app in the mounted volume..."
    android_studio_app_path=$(find /Volumes/AndroidStudio -name "Android Studio.app" -print -quit)
    
    if [ -z "$android_studio_app_path" ]; then
        echo "Failed to find Android Studio.app in the mounted volume."
        hdiutil detach /Volumes/AndroidStudio
        exit 1
    fi

    echo "Found Android Studio.app at: $android_studio_app_path"
}

# Function to download Android Studio
download_android_studio() {

    # Use curl to download the file
    echo "Downloading Android Studio for Mac M3 chip..."
    # curl -L -o $OUTPUT_FILE $URL

    # echo "Downloading Android Studio..."
    curl -L -o $OUTPUT_FILE $android_studio_url

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "Download completed successfully. The file has been saved as $OUTPUT_FILE."
    else
        echo "Download failed. Please check your internet connection or the URL."
    fi

    echo "Downloaded DMG file Name: $OUTPUT_FILE"
}



# Function to mount the DMG file
mount_dmg() {
    
    
    echo "Mounting Android Studio DMG... $OUTPUT_FILE"
    hdiutil attach $OUTPUT_FILE -mountpoint $MOUNT_POINT
}


# Function to install Android Studio
install_android_studio() {

# Find the application in the mounted DMG
    APP_PATH=$(find "$MOUNT_POINT" -name "*.app" -maxdepth 1)

# Copy the application to the Applications folder
if [ -d "$APP_PATH" ]; then
    echo "Installing the application to /Applications..."
    cp -R "$APP_PATH" /Applications/
    
    # Check if the copy was successful
    if [ $? -eq 0 ]; then
        echo "Application installed successfully to /Applications."
    else
        echo "Failed to install the application."
        exit 1
    fi
else
    echo "Application not found in the mounted DMG."
    exit 1
fi
}


# Function to unmount the DMG file
unmount_dmg() {
    echo "Unmounting Android Studio DMG..."
    hdiutil detach $MOUNT_POINT
}

# Function to clean up the downloaded DMG
cleanup() {
    echo "Cleaning up..."
    # rm -f ./android-studio.dmg
    rm -f $OUTPUT_FILE

}

# Function to add Android Studio to PATH
add_to_path() {
    
    # Define the path to the Android SDK
    ANDROID_SDK_ROOT="\$HOME/Library/Android/sdk"
    # echo "Adding Android Studio to PATH..."
    update_exported_variable "ANDROID_HOME" "$ANDROID_SDK_ROOT"
    
    

    # Define the path to the Command-Line Tools
    CMDLINE_TOOLS="\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
    update_zshrc "CMDLINE_TOOLS" "$CMDLINE_TOOLS"
    
    update_zshrc "ANDROID_EMULATOR" "\$ANDROID_SDK_ROOT/emulator"
    update_zshrc "ANDROID_PLATFORM_TOOLS" "\$ANDROID_SDK_ROOT/platform-tools"

}

# setup required SDK components

setupSDK() {
    # Install the Android SDK
    echo "Installing the Android SDK..."
    sdkmanager "platform-tools" "emulator" "system-images;android-34;google_apis;arm64-v8a" "build-tools;34.0.0"
}

# Create an AVD for the emulator
setupAVD() {
    echo "Creating an AVD..."
    avdmanager create avd -n avd_device -k "system-images;android-34;google_apis;arm64-v8a" -d pixel_3a

    # start the emulator
    # emulator -avd avd_device
}


# Call the install_homebrew function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_install_android_studio
fi


# export -f is_nvm_installed
export -f main_install_android_studio