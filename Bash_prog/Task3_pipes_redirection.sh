#!/usr/bin/env bash
# -----------------------------------------------------------------
# @title        Task3_pipes_redirection.sh
# @author       Ishmael Adam Ahmed
# @index        6126624
# @school       Kwame Nkrumah University of Science and Technology (KNUST)
# @description  Demonstrates pipes, redirection, grep, sort, uniq,
#               wc, awk, and cut using a self-contained fake log.
# @date         2026-09-20
# -----------------------------------------------------------------

set -u

usage() {
    echo "Usage: $0"
    echo
    echo "Processes a self-contained fake log using Bash pipelines"
    echo "and writes the analysis summary to results.txt."
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
}

# This script takes no normal arguments.
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi

    echo "Error: This script does not accept positional arguments." >&2
    usage
    exit 1
fi

log_file="fake_access.log"
results_file="results.txt"
error_file="errors.log"

# Create the fake log using a heredoc.
if cat > "$log_file" <<'EOF'
2026-09-20 08:01:12 INFO  192.168.1.10 GET /index.html
2026-09-20 08:02:15 INFO  192.168.1.11 GET /login
2026-09-20 08:03:20 WARN  192.168.1.10 GET /admin
2026-09-20 08:04:05 ERROR 192.168.1.20 POST /login
2026-09-20 08:05:11 INFO  192.168.1.12 GET /products
2026-09-20 08:06:30 INFO  192.168.1.10 GET /about
2026-09-20 08:07:44 ERROR 192.168.1.20 GET /admin
2026-09-20 08:08:19 WARN  192.168.1.13 GET /dashboard
2026-09-20 08:09:02 INFO  192.168.1.11 GET /home
2026-09-20 08:10:55 ERROR 192.168.1.21 POST /checkout
2026-09-20 08:11:23 INFO  192.168.1.10 GET /contact
2026-09-20 08:12:47 WARN  192.168.1.14 GET /settings
2026-09-20 08:13:16 INFO  192.168.1.12 GET /products
2026-09-20 08:14:38 ERROR 192.168.1.20 GET /login
2026-09-20 08:15:09 INFO  192.168.1.15 GET /index.html
2026-09-20 08:16:27 INFO  192.168.1.10 GET /search
2026-09-20 08:17:41 WARN  192.168.1.11 GET /api
2026-09-20 08:18:52 ERROR 192.168.1.21 POST /api
2026-09-20 08:19:33 INFO  192.168.1.12 GET /about
2026-09-20 08:20:18 INFO  192.168.1.10 GET /home
2026-09-20 08:21:46 ERROR 192.168.1.20 GET /checkout
2026-09-20 08:22:10 WARN  192.168.1.13 GET /admin
2026-09-20 08:23:35 INFO  192.168.1.11 GET /products
2026-09-20 08:24:59 INFO  192.168.1.10 GET /login
2026-09-20 08:25:21 ERROR 192.168.1.21 GET /settings
2026-09-20 08:26:44 INFO  192.168.1.12 GET /dashboard
2026-09-20 08:27:08 WARN  192.168.1.14 GET /api
2026-09-20 08:28:31 ERROR 192.168.1.20 POST /login
2026-09-20 08:29:57 INFO  192.168.1.15 GET /about
2026-09-20 08:30:16 INFO  192.168.1.10 GET /contact
2026-09-20 08:31:42 ERROR 192.168.1.21 GET /admin
2026-09-20 08:32:05 WARN  192.168.1.11 GET /dashboard
2026-09-20 08:33:29 INFO  192.168.1.12 GET /home
2026-09-20 08:34:53 INFO  192.168.1.10 GET /products
2026-09-20 08:35:17 ERROR 192.168.1.20 POST /checkout
2026-09-20 08:36:40 INFO  192.168.1.13 GET /index.html
2026-09-20 08:37:22 WARN  192.168.1.14 GET /settings
2026-09-20 08:38:45 ERROR 192.168.1.21 GET /api
2026-09-20 08:39:11 INFO  192.168.1.11 GET /login
2026-09-20 08:40:36 INFO  192.168.1.10 GET /about
2026-09-20 08:41:58 ERROR 192.168.1.20 GET /dashboard
2026-09-20 08:42:24 WARN  192.168.1.12 GET /admin
2026-09-20 08:43:47 INFO  192.168.1.15 GET /products
2026-09-20 08:44:03 ERROR 192.168.1.21 POST /login
2026-09-20 08:45:29 INFO  192.168.1.10 GET /home
2026-09-20 08:46:51 WARN  192.168.1.13 GET /api
2026-09-20 08:47:15 ERROR 192.168.1.20 GET /settings
2026-09-20 08:48:38 INFO  192.168.1.11 GET /contact
2026-09-20 08:49:02 INFO  192.168.1.12 GET /index.html
2026-09-20 08:50:26 ERROR 192.168.1.21 GET /checkout
2026-09-20 08:51:44 INFO  192.168.1.10 GET /dashboard
EOF
then
    echo "Fake log created: $log_file"
else
    echo "Error: Failed to create fake log." >&2
    exit 1
fi

# Start a fresh results file.
if : > "$results_file"; then
    :
else
    echo "Error: Failed to create results file." >&2
    exit 1
fi

# Start a fresh error log.
if : > "$error_file"; then
    :
else
    echo "Error: Failed to create error log." >&2
    exit 1
fi

# Count the total number of log lines.
total_lines=$(wc -l < "$log_file" 2>>"$error_file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to count total log lines." >&2
    exit 1
fi

# Count INFO, WARN, and ERROR entries.
info_count=$(grep -c " INFO " "$log_file" 2>>"$error_file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to count INFO entries." >&2
    exit 1
fi

warn_count=$(grep -c " WARN " "$log_file" 2>>"$error_file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to count WARN entries." >&2
    exit 1
fi

error_count=$(grep -c " ERROR " "$log_file" 2>>"$error_file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to count ERROR entries." >&2
    exit 1
fi

# Extract IP addresses, sort them, count duplicates, and show the top 3.
top_ips=$(
    awk '{print $4}' "$log_file" 2>>"$error_file" |
    sort |
    uniq -c |
    sort -nr |
    head -n 3
)

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to calculate top IP addresses." >&2
    exit 1
fi

# Extract every ERROR line.
error_lines=$(grep " ERROR " "$log_file" 2>>"$error_file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to extract ERROR lines." >&2
    exit 1
fi

# Demonstrate cut by extracting the date from the first log line.
first_date=$(head -n 1 "$log_file" | cut -d' ' -f1 2>>"$error_file")

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to extract date using cut." >&2
    exit 1
fi

# Write the complete analysis summary to results.txt.
if cat > "$results_file" <<EOF
Log Analysis Results
===================

First log date: $first_date

Total log lines: $total_lines

Log level counts:
INFO:  $info_count
WARN:  $warn_count
ERROR: $error_count

Top 3 IP addresses:
$top_ips

All ERROR lines:
$error_lines
EOF
then
    :
else
    echo "Error: Failed to write results." >&2
    exit 1
fi

echo "Analysis complete."
echo "Results saved to: $results_file"
echo "Pipeline errors saved to: $error_file"

exit 0
