#!/bin/bash

# Function to recursively change permissions of all .sh files
# Parameters: 
#   $1 - Directory path to start the search (default: current directory)
# Returns: None
change_permissions() {
    local directory_path="${1:-.}"  # Default to current directory if no parameter is passed

    # Find all .sh files and change permissions to make them executable
    find "$directory_path" -type f -name "*.sh" -exec chmod +x {} \;

    echo "Permissions changed for all .sh files in $directory_path and its subdirectories."
}

# Call the function
change_permissions "$1"
