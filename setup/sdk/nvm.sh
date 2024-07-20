#!/bin/bash

# Source the update_zshrc.sh script
# echo " path: ${BASH_SOURCE[0]}"
# parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
# cd "$parent_path"

source "$(dirname "${BASH_SOURCE[0]}")/../utils/update_zshrc.sh"


DEFAULT_NVM_SECTION_START="# Start NVM section"
DEFAULT_NVM_SECTION_END="# END NVM section"

# Function to check if nvm is installed
# Parameters: None
# Returns: 0 if nvm is installed, 1 otherwise
is_nvm_installed() {

     # Source nvm if it's not already loaded
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"
    fi

    if command -v nvm &> /dev/null; then
        echo "nvm is installed."
        return 0
    else
        echo "nvm is not installed."
        return 1
    fi
}

install_nvm() {
    # Ensure nvm is installed
    if ! is_nvm_installed; then
        echo "nvm not found, installing..."

        brew install nvm
        mkdir -p ~/.nvm

        update_nvm_in_zshrc

        # echo 'export NVM_DIR="$HOME/.nvm"' >> $DEFAULT_ZSHRC_PATH
        # echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> $DEFAULT_ZSHRC_PATH
        # source $DEFAULT_ZSHRC_PATH
    else
        echo "nvm is already installed."
    fi
}




# Function to update NVM_DIR and nvm initialization in .zshrc
# Parameters: None
# Returns: None
update_nvm_in_zshrc() {
    local nvm_prefix=$(brew --prefix nvm)
    local nvm_sh_path="$nvm_prefix/nvm.sh"
    local nvm_bash_completion_path="$nvm_prefix/etc/bash_completion.d/nvm"
    
    # local zshrc_path="${1:-$HOME/.zshrc}"
    update_exported_variable "NVM_DIR" '$HOME/.nvm'

    # Add nvm initialization if not present
#     if ! grep -q '\.nvm/nvm.sh' "$DEFAULT_ZSHRC_PATH"; then
#         sed -i '' "/$DEFAULT_NVM_SECTION_END/i\\
# [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\" # This loads nvm  \\
# [ -s \"\$NVM_DIR/etc/bash_completion.d/nvm\" ] && \. \"\$NVM_DIR/etc/bash_completion.d/nvm\"  # This loads nvm bash_completion
# " "$DEFAULT_ZSHRC_PATH"
    
#     fi

       # Add nvm initialization if not present
    if ! grep -q '\.nvm/nvm.sh' "$DEFAULT_ZSHRC_PATH"; then
        sed -i '' "/$DEFAULT_NVM_SECTION_END/i\\
[ -s \"$nvm_sh_path\" ] && \. \"$nvm_sh_path\" # This loads nvm  \\
[ -s \"$nvm_bash_completion_path\" ] && \. \"$nvm_bash_completion_path\"  # This loads nvm bash_completion
" "$DEFAULT_ZSHRC_PATH"
    fi
}



# Call the install_homebrew function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nvm
fi


export -f is_nvm_installed
export -f install_nvm

