#!/usr/bin/env bash
# -----------------------------------------------------------------
# @title        Task1_file_handling.sh
# @author       Ishmael Adam Ahmed
# @index        6126624
# @school       Kwame Nkrumah University of Science and Technology (KNUST)
# @description  Demonstrates file and directory creation, writing,
#               appending, displaying, backup, and safe deletion.
# @date         2026-09-20
# -----------------------------------------------------------------

set -u

usage() {
    echo "Usage: $0 <target-directory>"
    echo
    echo "Creates a directory if needed and performs basic file operations inside it."
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
}

# Check that exactly one argument was provided.
if [[ $# -eq 0 ]]; then
    echo "Error: Target directory is required." >&2
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

target_dir="$1"

# Create the target directory if it does not exist.
if [[ -d "$target_dir" ]]; then
    echo "Target directory already exists: $target_dir"
elif [[ -e "$target_dir" ]]; then
    echo "Error: '$target_dir' exists but is not a directory." >&2
    exit 1
else
    if mkdir -p "$target_dir"; then
        echo "Created target directory: $target_dir"
    else
        echo "Error: Failed to create target directory: $target_dir" >&2
        exit 1
    fi
fi

file="$target_dir/data.txt"

# Write the initial content to the file.
if echo "This is the initial content of the file." > "$file"; then
    echo "Initial content written to: $file"
else
    echo "Error: Failed to write to '$file'." >&2
    exit 1
fi

# Append additional content to the file.
if echo "This is additional content appended to the file." >> "$file"; then
    echo "Additional content appended to: $file"
else
    echo "Error: Failed to append to '$file'." >&2
    exit 1
fi

# Display the file contents.
echo
echo "File contents:"

if cat "$file"; then
    :
else
    echo "Error: Failed to display '$file'." >&2
    exit 1
fi

# Create a backup copy of the file.
backup_file="${file}.bak"

if cp "$file" "$backup_file"; then
    echo
    echo "Backup created: $backup_file"
else
    echo "Error: Failed to create backup." >&2
    exit 1
fi

# Ask the user for confirmation before deleting the original.
read -r -p "Do you want to delete the original file? [y/N]: " confirm

if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    if rm "$file"; then
        echo "Original file deleted: $file"
    else
        echo "Error: Failed to delete the original file." >&2
        exit 1
    fi
else
    echo "Original file was not deleted."
fi

exit 0
```

