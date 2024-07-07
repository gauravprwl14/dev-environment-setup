#!/bin/bash

# Source the update_zshrc.sh script
source ./utils/update_zshrc.sh

if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

else
    echo "Homebrew is already installed. Updating Homebrew..."

    # Update Homebrew
    brew update

fi


# Define Homebrew path
HOMEBREW_VARIABLE_NAME="HOMEBREW"
HOMEBREW_VARIABLE_VALUE="/opt/homebrew/bin"

 # Call the update_zshrc function, passing only the Homebrew path
update_zshrc "$HOMEBREW_VARIABLE_NAME" "$HOMEBREW_VARIABLE_VALUE"



# # Ensure the Homebrew path is added to .zshrc if not already present
# ZSHRC_PATH="../.zshrc"
# HOMEBREW_PATH='/opt/homebrew/bin'

# # Check if .zshrc exists
# if [ ! -f "$ZSHRC_PATH" ]; then
#     echo "Error: .zshrc file not found at $ZSHRC_PATH"
#     exit 1
# fi

# # Add identifiers for Variable and PATH sections if not present
# if ! grep -q '# Begin Variable section' "$ZSHRC_PATH"; then
#     echo -e "\n# Begin Variable section\n# End Variable section" >> "$ZSHRC_PATH"
# fi

# if ! grep -q '# Begin PATH section' "$ZSHRC_PATH"; then
#     echo -e "\n# Begin PATH section\n# End PATH section" >> "$ZSHRC_PATH"
# fi

# # Add HOMEBREW_PATH variable if not present
# if ! grep -q 'export HOMEBREW=' "$ZSHRC_PATH"; then
#     sed -i '' '/# Begin Variable section/a\
# export HOMEBREW='"$HOMEBREW_PATH"'
# ' "$ZSHRC_PATH"
# fi

# # Check if Homebrew path is already in the PATH section
# if ! grep -q 'export PATH=.*\$HOMEBREW' "$ZSHRC_PATH"; then
#     sed -i '' '/# End PATH section/ i\
# export PATH=$PATH:$HOMEBREW
# ' "$ZSHRC_PATH"
#     echo "Homebrew path added to .zshrc"
# else
#     echo "Homebrew path already exists in .zshrc"
# fi

# echo "Homebrew installation and path setup complete."
