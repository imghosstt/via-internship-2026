#!/usr/bin/env bash
# -----------------------------------------------------------------
# @title        Task4_return_codes_error_handling.sh
# @author       Ishmael Adam Ahmed
# @index        6126624
# @school       Kwame Nkrumah University of Science and Technology (KNUST)
# @description  Demonstrates return codes, error handling, logging,
#               system checks, and trap-based temporary-file cleanup.
# @date         2026-09-20
#
# Exit code scheme:
#   0 = All checks passed
#   1 = Invalid usage or input
#   2 = Host unreachable
#   3 = Disk space check failed
#   4 = File check failed
#   5 = Required command missing
#   6 = Temporary-file cleanup failed
# -----------------------------------------------------------------

set -u

usage() {
    echo "Usage: $0 <hostname>"
    echo
    echo "Runs four system checks:"
    echo "  1. Host reachability"
    echo "  2. Disk space"
    echo "  3. File existence/readability"
    echo "  4. Required command availability"
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
}

# Temporary files are created during execution and removed by trap.
temp_dir=""

cleanup() {
    local cleanup_status=0

    if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
        if rm -rf "$temp_dir"; then
            :
        else
            cleanup_status=1
        fi
    fi

    return "$cleanup_status"
}

# Always clean up temporary files when the script exits.
trap 'cleanup' EXIT

# Handle Ctrl+C gracefully.
handle_interrupt() {
    echo
    echo "Interrupted by user. Cleaning up..." >&2
    exit 130
}

trap 'handle_interrupt' INT

# Validate the argument count.
if [[ $# -eq 0 ]]; then
    echo "Error: Hostname is required." >&2
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

hostname="$1"

# Basic hostname validation.
if [[ -z "$hostname" ]]; then
    echo "Error: Hostname cannot be empty." >&2
    exit 1
fi

# Create a temporary working directory.
temp_dir=$(mktemp -d)

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create temporary directory." >&2
    exit 6
fi

echo "Temporary directory created: $temp_dir"
echo
echo "Running system checks for host: $hostname"
echo "----------------------------------------"

check_status() {
    local status="$1"
    local check_name="$2"
    local failure_code="$3"

    if [[ "$status" -eq 0 ]]; then
        echo "[PASS] $check_name"
        return 0
    else
        echo "[FAIL] $check_name" >&2
        echo "Failure exit code: $failure_code" >&2
        return "$failure_code"
    fi
}

# ---------------------------------------------------------------
# Check 1: Host reachability
# ---------------------------------------------------------------
echo
echo "Check 1: Host reachability"

ping -c 1 -W 2 "$hostname" >"$temp_dir/ping_output.log" 2>&1
ping_status=$?

if check_status "$ping_status" "Host is reachable" 2; then
    :
else
    echo "Ping output saved to: $temp_dir/ping_output.log" >&2
    exit 2
fi

# ---------------------------------------------------------------
# Check 2: Disk space
# ---------------------------------------------------------------
echo
echo "Check 2: Disk space"

# Require at least 10% free space on the current filesystem.
available_percent=$(df -P . | awk 'NR==2 {gsub("%","",$5); print 100-$5}')
df_status=$?

if [[ "$df_status" -ne 0 ]]; then
    check_status 1 "Disk space information could not be read" 3
    exit 3
fi

if [[ "$available_percent" -ge 10 ]]; then
    disk_status=0
else
    disk_status=1
fi

if check_status "$disk_status" "At least 10% disk space is available (${available_percent}% free)" 3; then
    :
else
    exit 3
fi

# ---------------------------------------------------------------
# Check 3: File exists and is readable
# ---------------------------------------------------------------
echo
echo "Check 3: File existence and readability"

test_file="$temp_dir/test_readable.txt"

if echo "Temporary test file" > "$test_file"; then
    :
else
    echo "Error: Could not create temporary test file." >&2
    exit 4
fi

if [[ -f "$test_file" && -r "$test_file" ]]; then
    file_status=0
else
    file_status=1
fi

if check_status "$file_status" "Temporary file exists and is readable" 4; then
    :
else
    exit 4
fi

# ---------------------------------------------------------------
# Check 4: Required command availability
# ---------------------------------------------------------------
echo
echo "Check 4: Required command availability"

required_command="awk"

if command -v "$required_command" >/dev/null 2>&1; then
    command_status=0
else
    command_status=1
fi

if check_status "$command_status" "Required command '$required_command' is installed" 5; then
    :
else
    exit 5
fi

echo
echo "----------------------------------------"
echo "All checks completed successfully."
echo "Temporary files will now be cleaned up."

exit 0
