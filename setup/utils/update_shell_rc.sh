#!/bin/bash

# Cross-platform shell rc updater (macOS + Linux)
# Replaces update_zshrc.sh with support for .zshrc, .bashrc, and .profile

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DEFAULT_VARIABLE_SECTION_BEGIN="# Begin Variable section"
DEFAULT_VARIABLE_SECTION_END="# End Variable section"
DEFAULT_PATH_SECTION_BEGIN="# Begin PATH section"
DEFAULT_PATH_SECTION_END="# End PATH section"

export DEFAULT_VARIABLE_SECTION_BEGIN
export DEFAULT_VARIABLE_SECTION_END
export DEFAULT_PATH_SECTION_BEGIN
export DEFAULT_PATH_SECTION_END

# ---------------------------------------------------------------------------
# get_rc_file — detect which shell rc file to use based on $SHELL
# Returns the absolute path to the rc file via stdout
# ---------------------------------------------------------------------------
get_rc_file() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo "$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        echo "$HOME/.bashrc"
    else
        echo "$HOME/.profile"
    fi
}

# ---------------------------------------------------------------------------
# portable_sed_inplace <sed_args...>
# Wraps sed -i in a way that works on both GNU (Linux) and BSD (macOS)
# ---------------------------------------------------------------------------
portable_sed_inplace() {
    if sed --version 2>&1 | grep -q GNU; then
        # GNU sed (Linux)
        sed -i "$@"
    else
        # BSD sed (macOS)
        sed -i '' "$@"
    fi
}

# ---------------------------------------------------------------------------
# check_rc_exists [rc_file]
# Prints the rc file path and returns 1 if the file does not exist
# ---------------------------------------------------------------------------
check_rc_exists() {
    local rc_file="${1:-$(get_rc_file)}"

    echo "RC file path: $rc_file"

    if [ ! -f "$rc_file" ]; then
        echo "Error: shell rc file not found at $rc_file"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# add_to_shell_rc <var_name> <var_value> [rc_file]
# Idempotently adds:
#   - export VAR_NAME=value  inside the Variable section
#   - export PATH=$PATH:$VAR_NAME  inside the PATH section
# ---------------------------------------------------------------------------
add_to_shell_rc() {
    local variable_name="$1"
    local variable_value="$2"
    local rc_file="${3:-$(get_rc_file)}"

    local variable_section_begin="$DEFAULT_VARIABLE_SECTION_BEGIN"
    local variable_section_end="$DEFAULT_VARIABLE_SECTION_END"
    local path_section_begin="$DEFAULT_PATH_SECTION_BEGIN"
    local path_section_end="$DEFAULT_PATH_SECTION_END"

    # Ensure the rc file exists
    check_rc_exists "$rc_file" || return 1

    # Add Variable section markers if not present
    if ! grep -qF "$variable_section_begin" "$rc_file"; then
        printf '\n%s\n%s\n' "$variable_section_begin" "$variable_section_end" >> "$rc_file"
    fi

    # Add PATH section markers if not present
    if ! grep -qF "$path_section_begin" "$rc_file"; then
        printf '\n%s\n%s\n' "$path_section_begin" "$path_section_end" >> "$rc_file"
    fi

    # Add variable export inside Variable section if not already present
    if ! grep -q "export ${variable_name}=" "$rc_file"; then
        portable_sed_inplace \
            "/${variable_section_begin}/a\\
export ${variable_name}=${variable_value}" \
            "$rc_file"
        echo "Added: export ${variable_name}=${variable_value}"
    else
        echo "Variable ${variable_name} already present in $rc_file"
    fi

    # Add PATH entry inside PATH section if not already present
    if ! grep -qE "export PATH=.*\\\$${variable_name}" "$rc_file"; then
        portable_sed_inplace \
            "/${path_section_end}/i\\
export PATH=\$PATH:\$${variable_name}" \
            "$rc_file"
        echo "Added PATH entry for ${variable_name}"
    else
        echo "PATH entry for ${variable_name} already present in $rc_file"
    fi
}

# ---------------------------------------------------------------------------
# add_path_to_shell_rc <path_value> [rc_file]
# Appends a raw path value to the PATH section if not already present
# ---------------------------------------------------------------------------
add_path_to_shell_rc() {
    local path_value="$1"
    local rc_file="${2:-$(get_rc_file)}"

    local path_section_begin="$DEFAULT_PATH_SECTION_BEGIN"
    local path_section_end="$DEFAULT_PATH_SECTION_END"

    # Ensure the rc file exists
    check_rc_exists "$rc_file" || return 1

    # Add PATH section markers if not present
    if ! grep -qF "$path_section_begin" "$rc_file"; then
        printf '\n%s\n%s\n' "$path_section_begin" "$path_section_end" >> "$rc_file"
    fi

    # Only add if this exact path value is not already referenced
    if ! grep -qF "$path_value" "$rc_file"; then
        portable_sed_inplace \
            "/${path_section_end}/i\\
export PATH=\"\$PATH:${path_value}\"" \
            "$rc_file"
        echo "Added PATH entry: $path_value"
    else
        echo "PATH entry already present in $rc_file: $path_value"
    fi
}

# ---------------------------------------------------------------------------
# update_exported_variable <var_name> <var_value> [rc_file]
# Updates an existing export or inserts a new one inside the Variable section.
# Does NOT add a corresponding PATH entry.
# ---------------------------------------------------------------------------
update_exported_variable() {
    local variable_name="$1"
    local variable_value="$2"
    local rc_file="${3:-$(get_rc_file)}"

    local variable_section_begin="$DEFAULT_VARIABLE_SECTION_BEGIN"
    local variable_section_end="$DEFAULT_VARIABLE_SECTION_END"

    echo "RC file path: $rc_file"

    # Ensure the rc file exists
    if [ ! -f "$rc_file" ]; then
        echo "Error: shell rc file not found at $rc_file"
        return 1
    fi

    # Add Variable section markers if not present
    if ! grep -qF "$variable_section_begin" "$rc_file"; then
        printf '\n%s\n%s\n' "$variable_section_begin" "$variable_section_end" >> "$rc_file"
    fi

    # Update existing export or insert a new one
    if grep -q "export ${variable_name}=" "$rc_file"; then
        portable_sed_inplace \
            "s|export ${variable_name}=.*|export ${variable_name}=${variable_value}|" \
            "$rc_file"
        echo "Updated: export ${variable_name}=${variable_value}"
    else
        portable_sed_inplace \
            "/${variable_section_end}/i\\
export ${variable_name}=${variable_value}" \
            "$rc_file"
        echo "Inserted: export ${variable_name}=${variable_value}"
    fi
}

# ---------------------------------------------------------------------------
# Backward-compatibility alias
# update_zshrc <var_name> <var_value> [rc_file] — delegates to add_to_shell_rc
# ---------------------------------------------------------------------------
update_zshrc() {
    add_to_shell_rc "$@"
}

# ---------------------------------------------------------------------------
# Export all functions
# ---------------------------------------------------------------------------
export -f get_rc_file
export -f portable_sed_inplace
export -f check_rc_exists
export -f add_to_shell_rc
export -f add_path_to_shell_rc
export -f update_exported_variable
export -f update_zshrc

# ---------------------------------------------------------------------------
# BASH_SOURCE guard — when executed directly, print detected rc file path
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Detected shell rc file: $(get_rc_file)"
fi
