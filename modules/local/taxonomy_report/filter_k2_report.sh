#!/bin/bash

# Description:
# This script filters and prints rows from Kraken2 report files based on specified criteria.
# It allows users to select rows that match a specific taxonomic rank and meet a minimum
# threshold of either percentage or count. The output is sorted by the selection criterion
# in descending order and includes only the specified criterion value (with percentage values
# displayed with a "%"), count, and full scientific name.

# Usage:
# ./filter_k2_report.sh --taxa [RANK] --per [MIN_PERCENT] --file [FILE(S)]
# or
# ./filter_k2_report.sh --taxa [RANK] --count [MIN_COUNT] --file [FILE(S)]
# Where:
# - [RANK] is the taxonomic rank to filter by (e.g., S for species).
# - [MIN_PERCENT] is the minimum percentage threshold for a row to be included. Use with --per.
# - [MIN_COUNT] is the minimum count threshold for a row to be included. Use with --count.
# - [FILE(S)] is one or more Kraken2 report files to be processed. Wildcards can be used
#   to specify multiple files.

# Parameters:
# --taxa: Specifies the taxonomic rank to filter by (e.g., S, G, F). Default is S (species).
# --per: Sets the minimum percentage threshold for inclusion in the output.
# --count: Sets the minimum count threshold for inclusion in the output.
# --file: Specifies the file(s) to process. Accepts wildcards for multiple files.

# Initialize variables
rank="S"
threshold=0
mode=""
files=()

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --taxa) rank="$2"; shift ;;
        --per) threshold="$2"; mode="percent"; shift ;;
        --count) threshold="$2"; mode="count"; shift ;;
        --file) shift; files=("$@"); break ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check if both --per and --count are not used at the same time
if [ "${#files[@]}" -eq 0 ] || [ -z "$threshold" ] || [ -z "$mode" ]; then
    echo "Error: You must specify either --per or --count, not both, and at least one file."
    exit 1
fi

# Function to filter, sort, and print the report based on rank and threshold
print_filtered_report() {
    local file=$1
    local rank=$2
    local threshold=$3
    local mode=$4
    echo "File: $file"
    if [ "$mode" == "percent" ]; then
        awk -v rank="$rank" -v threshold="$threshold" '{
            if ($4 == rank && $1 >= threshold) {
                name = ""; 
                for (i=6; i<=NF; i++) name = name $i " "; 
                printf "%.2f%%\t%s\t%s\n", $1, $2, name
            }
        }' "$file" | sort -k1,1nr
    else
        awk -v rank="$rank" -v threshold="$threshold" '{
            if ($4 == rank && $2 >= threshold) {
                name = ""; 
                for (i=6; i<=NF; i++) name = name $i " "; 
                printf "%s\t%.2f%%\t%s\n", $2, $1, name
            }
        }' "$file" | sort -k1,1nr
    fi
}

# Loop through all specified files and apply the filter and sorting
for file in "${files[@]}"; do
    print_filtered_report "$file" "$rank" "$threshold" "$mode"
done