#!/usr/bin/env bash
# -----------------------------------------------------------------
# @title        Task5_crud_app.sh
# @author       Ishmael Adam Ahmed
# @index        6126624
# @school       Kwame Nkrumah University of Science and Technology (KNUST)
# @description  Provides a menu-driven todo-list CRUD application
#               with validation, confirmation, and backups.
# @date         2026-09-20
# -----------------------------------------------------------------

set -u

DATA_FILE="todo.txt"
BACKUP_FILE="todo.txt.bak"

usage() {
    echo "Usage: $0"
    echo
    echo "Starts a menu-driven todo-list CRUD application."
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
}

# This function creates the data file if it does not exist.
initialize_data_file() {
    if [[ -e "$DATA_FILE" ]]; then
        if [[ ! -f "$DATA_FILE" ]]; then
            echo "Error: '$DATA_FILE' exists but is not a regular file." >&2
            return 1
        fi
        return 0
    fi

    if touch "$DATA_FILE"; then
        return 0
    else
        echo "Error: Failed to create '$DATA_FILE'." >&2
        return 1
    fi
}

# Add a new todo item.
add_item() {
    local task

    echo
    echo "=== Add Todo ==="

    read -r -p "Enter task: " task

    if [[ -z "$task" ]]; then
        echo "Error: Task cannot be empty." >&2
        return 1
    fi

    if printf '%s\n' "$task" >> "$DATA_FILE"; then
        echo "Task added successfully."
        return 0
    else
        echo "Error: Failed to add task." >&2
        return 1
    fi
}

# Display all todo items.
view_items() {
    echo
    echo "=== Todo List ==="

    if [[ ! -s "$DATA_FILE" ]]; then
        echo "No todo items found."
        return 0
    fi

    local number=1
    local task

    while IFS= read -r task; do
        printf "%d. %s\n" "$number" "$task"
        ((number++))
    done < "$DATA_FILE"

    return 0
}

# Search todo items by keyword.
search_items() {
    local keyword

    echo
    echo "=== Search Todo ==="

    read -r -p "Enter search keyword: " keyword

    if [[ -z "$keyword" ]]; then
        echo "Error: Search keyword cannot be empty." >&2
        return 1
    fi

    if grep -inF "$keyword" "$DATA_FILE"; then
        return 0
    else
        if [[ $? -eq 1 ]]; then
            echo "No matching todo items found."
            return 0
        fi

        echo "Error: Search operation failed." >&2
        return 1
    fi
}

# Update an existing todo item.
update_item() {
    local item_number
    local new_task
    local total_items
    local old_task
    local temp_file

    echo
    echo "=== Update Todo ==="

    if [[ ! -s "$DATA_FILE" ]]; then
        echo "No todo items found."
        return 0
    fi

    view_items

    read -r -p "Enter the item number to update: " item_number

    if [[ ! "$item_number" =~ ^[0-9]+$ ]]; then
        echo "Error: Item number must be a positive integer." >&2
        return 1
    fi

    if (( item_number < 1 )); then
        echo "Error: Item number must be at least 1." >&2
        return 1
    fi

    total_items=$(wc -l < "$DATA_FILE")

    if (( item_number > total_items )); then
        echo "Error: Todo item #$item_number does not exist." >&2
        return 1
    fi

    old_task=$(sed -n "${item_number}p" "$DATA_FILE")

    echo "Current task: $old_task"
    read -r -p "Enter the new task: " new_task

    if [[ -z "$new_task" ]]; then
        echo "Error: New task cannot be empty." >&2
        return 1
    fi

    # Create a backup before modifying the original data.
    if cp "$DATA_FILE" "$BACKUP_FILE"; then
        echo "Backup created: $BACKUP_FILE"
    else
        echo "Error: Failed to create backup. Update cancelled." >&2
        return 1
    fi

    temp_file=$(mktemp)

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create temporary file." >&2
        return 1
    fi

    if awk -v n="$item_number" -v replacement="$new_task" \
        'NR == n { print replacement; next } { print }' \
        "$DATA_FILE" > "$temp_file"; then
        :
    else
        echo "Error: Failed to prepare updated todo list." >&2
        rm -f "$temp_file"
        return 1
    fi

    if mv "$temp_file" "$DATA_FILE"; then
        echo "Todo item updated successfully."
        return 0
    else
        echo "Error: Failed to save updated todo list." >&2
        rm -f "$temp_file"
        return 1
    fi
}

# Delete an existing todo item.
delete_item() {
    local item_number
    local total_items
    local task
    local confirmation
    local temp_file

    echo
    echo "=== Delete Todo ==="

    if [[ ! -s "$DATA_FILE" ]]; then
        echo "No todo items found."
        return 0
    fi

    view_items

    read -r -p "Enter the item number to delete: " item_number

    if [[ ! "$item_number" =~ ^[0-9]+$ ]]; then
        echo "Error: Item number must be a positive integer." >&2
        return 1
    fi

    if (( item_number < 1 )); then
        echo "Error: Item number must be at least 1." >&2
        return 1
    fi

    total_items=$(wc -l < "$DATA_FILE")

    if (( item_number > total_items )); then
        echo "Error: Todo item #$item_number does not exist." >&2
        return 1
    fi

    task=$(sed -n "${item_number}p" "$DATA_FILE")

    echo "Selected task: $task"
    read -r -p "Are you sure you want to delete it? [y/N]: " confirmation

    if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
        echo "Deletion cancelled."
        return 0
    fi

    # Create a backup before modifying the original data.
    if cp "$DATA_FILE" "$BACKUP_FILE"; then
        echo "Backup created: $BACKUP_FILE"
    else
        echo "Error: Failed to create backup. Deletion cancelled." >&2
        return 1
    fi

    temp_file=$(mktemp)

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create temporary file." >&2
        return 1
    fi

    if awk -v n="$item_number" 'NR != n { print }' \
        "$DATA_FILE" > "$temp_file"; then
        :
    else
        echo "Error: Failed to prepare updated todo list." >&2
        rm -f "$temp_file"
        return 1
    fi

    if mv "$temp_file" "$DATA_FILE"; then
        echo "Todo item deleted successfully."
        return 0
    else
        echo "Error: Failed to save updated todo list." >&2
        rm -f "$temp_file"
        return 1
    fi
}

# Validate command-line arguments.
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi

    echo "Error: This application does not accept positional arguments." >&2
    usage
    exit 1
fi

# Initialize the todo data file.
if ! initialize_data_file; then
    exit 1
fi

echo "================================"
echo "       TODO CRUD APPLICATION"
echo "================================"

# Main application loop.
while true; do
    echo
    echo "1. Add Todo"
    echo "2. View Todos"
    echo "3. Search Todos"
    echo "4. Update Todo"
    echo "5. Delete Todo"
    echo "6. Exit"

    read -r -p "Choose an option [1-6]: " choice

    case "$choice" in
        1)
            add_item
            ;;
        2)
            view_items
            ;;
        3)
            search_items
            ;;
        4)
            update_item
            ;;
        5)
            delete_item
            ;;
        6)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Error: Invalid menu option. Please choose 1-6." >&2
            ;;
    esac
done
