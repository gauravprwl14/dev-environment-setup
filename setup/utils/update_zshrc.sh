#!/bin/bash

# Default values for section identifiers
DEFAULT_VARIABLE_SECTION_BEGIN="# Begin Variable section"
DEFAULT_VARIABLE_SECTION_END="# End Variable section"
DEFAULT_PATH_SECTION_BEGIN="# Begin PATH section"
DEFAULT_PATH_SECTION_END="# End PATH section"
DEFAULT_ZSHRC_PATH="$HOME/.zshrc"
# DEFAULT_ZSHRC_PATH="../.zshrc"
# local zshrc_path="../.zshrc"

# Function to update Variable and Paths in .zshrc file

# Function to update .zshrc file
# Parameters:
#   $1 - Variable name (required)
#   $2 - Variable value (required)
#   $3 - Path to .zshrc file (optional, default: $HOME/.zshrc)
#   $4 - Variable section begin identifier (optional, default: $DEFAULT_VARIABLE_SECTION_BEGIN)
#   $5 - Variable section end identifier (optional, default: $DEFAULT_VARIABLE_SECTION_END)
#   $6 - Path section begin identifier (optional, default: $DEFAULT_PATH_SECTION_BEGIN)
#   $7 - Path section end identifier (optional, default: $DEFAULT_PATH_SECTION_END)

update_zshrc() {
    local zshrc_path=$DEFAULT_ZSHRC_PATH
    
    # Local Testing 
    # local zshrc_path="../.zshrc"
    

    local variable_name="$1"
    local variable_value="$2"
    local zshrc_path="${3:-$zshrc_path}"
    local variable_section_begin="${4:-$DEFAULT_VARIABLE_SECTION_BEGIN}"
    local variable_section_end="${5:-$DEFAULT_VARIABLE_SECTION_END}"
    local path_section_begin="${6:-$DEFAULT_PATH_SECTION_BEGIN}"
    local path_section_end="${7:-$DEFAULT_PATH_SECTION_END}"
    local path_value="\$${variable_name}"

    # Check if .zshrc exists
    check_zshrc_exists "$zshrc_path"
    # if [ ! -f "$zshrc_path" ]; then
    #     echo "Error: .zshrc file not found at $zshrc_path"
    #     return 1
    # fi

    # Add identifiers for Variable and PATH sections if not present
    if ! grep -q "$variable_section_begin" "$zshrc_path"; then
        echo -e "\n$variable_section_begin\n$variable_section_end" >> "$zshrc_path"
    fi

    if ! grep -q "$path_section_begin" "$zshrc_path"; then
        echo -e "\n$path_section_begin\n$path_section_end" >> "$zshrc_path"
    fi

    # Add variable if not present
    if ! grep -q "export $variable_name=" "$zshrc_path"; then
        sed -i '' "/$variable_section_begin/a\\
export $variable_name=$variable_value
" "$zshrc_path"
    fi

    # Add path if not present
    if ! grep -q "export PATH=.*\$$variable_name" "$zshrc_path"; then
        sed -i '' "/$path_section_end/i\\
export PATH=\$PATH:\$$variable_name
" "$zshrc_path"
        echo "$variable_name path added to .zshrc"
    else
        echo "$variable_name path already exists in .zshrc"
    fi
}



# Function to update an exported variable in .zshrc
# Parameters:
#   $1 - Variable name (required)
#   $2 - Variable value (required)
#   $3 - Path to .zshrc file (optional, default: $HOME/.zshrc)
#   $4 - Variable section begin identifier (optional, default: $DEFAULT_VARIABLE_SECTION_BEGIN)
#   $5 - Variable section end identifier (optional, default: $DEFAULT_VARIABLE_SECTION_END)
update_exported_variable() {
    local variable_name="$1"
    local variable_value="$2"
    
    local zshrc_path="${3:-$DEFAULT_ZSHRC_PATH}"
    
    local variable_section_begin="${4:-$DEFAULT_VARIABLE_SECTION_BEGIN}"
    local variable_section_end="${5:-$DEFAULT_VARIABLE_SECTION_END}"

    # Check if .zshrc exists
    echo "Zshrc Path $zshrc_path"
    if [ ! -f "$zshrc_path" ]; then
        echo "Error: .zshrc file not found at $zshrc_path"
        return 1
    fi

    # Add identifiers for Variable section if not present
    if ! grep -q "$variable_section_begin" "$zshrc_path"; then
        echo -e "\n$variable_section_begin\n$variable_section_end" >> "$zshrc_path"
    fi

    # Add or update the variable
    if grep -q "export $variable_name=" "$zshrc_path"; then
        sed -i '' "s|export $variable_name=.*|export $variable_name=$variable_value|" "$zshrc_path"
    else
        sed -i '' "/$variable_section_end/i\\
export $variable_name=$variable_value
" "$zshrc_path"
    fi
}


# Function to check if .zshrc file exists
# Parameters:
#   $1 - Path to .zshrc file (required)
check_zshrc_exists() {
    local zshrc_path="${1:-$DEFAULT_ZSHRC_PATH}"
    
    echo "Zshrc Path $zshrc_path"
    if [ ! -f "$zshrc_path" ]; then
        echo "Error: .zshrc file not found at $zshrc_path"
        return 1
    fi
}


export -f update_zshrc
export -f update_exported_variable
export DEFAULT_ZSHRC_PATH
