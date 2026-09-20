#!/usr/bin/env bash
# -----------------------------------------------------------------
# @title        Task2_permissions_sudo.sh
# @author       Ishmael Adam Ahmed
# @index        6126624
# @school       Kwame Nkrumah University of Science and Technology (KNUST)
# @description  Demonstrates symbolic and numeric file permissions,
#               chmod operations, and conditional sudo/chown handling.
# @date         2026-09-20
# -----------------------------------------------------------------

set -u

usage() {
    echo "Usage: $0 <file-path>"
    echo
    echo "Reports file permissions, demonstrates numeric and symbolic chmod,"
    echo "and attempts chown only when the script is running as root."
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
}

# Check that exactly one argument was provided.
if [[ $# -eq 0 ]]; then
    echo "Error: File path is required." >&2
    usage
    exit 1
fi

if [[ $# -gt 1 ]]; then
    echo "Error: Too many arguments." >&2
    usage
    exit 1
fi

# Display help when requested.
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

file="$1"

# Make sure the supplied path exists.
if [[ ! -e "$file" ]]; then
    echo "Error: File does not exist: $file" >&2
    exit 1
fi

# The assignment expects a file path, so reject directories.
if [[ ! -f "$file" ]]; then
    echo "Error: '$file' is not a regular file." >&2
    exit 1
fi

# Report the current symbolic permissions.
symbolic_permissions=$(stat -c "%A" "$file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to read symbolic permissions." >&2
    exit 1
fi

# Report the current numeric permissions.
numeric_permissions=$(stat -c "%a" "$file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to read numeric permissions." >&2
    exit 1
fi

echo "File: $file"
echo "Current symbolic permissions: $symbolic_permissions"
echo "Current numeric permissions:  $numeric_permissions"

# Demonstrate chmod using numeric notation.
# 640 means:
#   Owner  = read + write
#   Group  = read
#   Others = no permissions
echo
echo "Applying numeric permissions: 640"

if chmod 640 "$file"; then
    echo "Numeric chmod succeeded."
else
    echo "Error: Failed to apply numeric chmod." >&2
    exit 1
fi

# Verify the numeric chmod operation.
numeric_after_chmod=$(stat -c "%a" "$file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to verify numeric chmod." >&2
    exit 1
fi

echo "Permissions after numeric chmod: $numeric_after_chmod"

# Demonstrate chmod using symbolic notation.
# u+x adds execute permission for the file owner.
echo
echo "Applying symbolic permission: u+x"

if chmod u+x "$file"; then
    echo "Symbolic chmod succeeded."
else
    echo "Error: Failed to apply symbolic chmod." >&2
    exit 1
fi

# Verify the symbolic chmod operation.
symbolic_after_chmod=$(stat -c "%A" "$file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to verify symbolic chmod." >&2
    exit 1
fi

numeric_after_symbolic=$(stat -c "%a" "$file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to read final numeric permissions." >&2
    exit 1
fi

echo "Final symbolic permissions: $symbolic_after_chmod"
echo "Final numeric permissions:  $numeric_after_symbolic"

# Check whether the script is running as root.
echo
if [[ "$(id -u)" -eq 0 ]]; then
    echo "Running as root."

    # Demonstrate chown by changing ownership to root.
    if chown root:root "$file"; then
        echo "chown succeeded: owner changed to root:root"
    else
        echo "Warning: chown failed." >&2
    fi
else
    echo "Not running as root."
    echo "Skipping chown because root privileges are required."
fi

# Report the final ownership and permissions.
echo
echo "Final file information:"

if stat -c "Owner: %U | Group: %G | Permissions: %A (%a)" "$file"; then
    :
else
    echo "Error: Failed to display final file information." >&2
    exit 1
fi

exit 0
