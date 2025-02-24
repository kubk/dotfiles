#!/bin/bash
# Check if at least one directory argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [-e extensions] <directory1> [directory2] [directory3] ..."
    echo "Options:"
    echo "  -e    Comma-separated list of file extensions (e.g., '.tsx,.ts,.js')"
    exit 1
fi

# Parse extension option
extensions=""
while getopts "e:" opt; do
    case $opt in
        e) extensions=$OPTARG ;;
    esac
done
shift $((OPTIND-1))

# Check if all provided paths are valid directories
for dir in "$@"; do
    if [ ! -d "$dir" ]; then
        echo "Error: Directory '$dir' does not exist"
        exit 1
    fi
done

# Output file name
output_file="concatenated_files.txt"

# Remove output file if it exists
[ -f "$output_file" ] && rm "$output_file"

# Process all directories
total_files=0
for dir in "$@"; do
    echo "Processing directory: $dir"
    
    # Find all files, sort them, and concatenate
    if [ -n "$extensions" ]; then
        # Convert comma-separated extensions into -name patterns with proper escaping
        patterns=""
        IFS=',' read -ra exts <<< "$extensions"
        for ext in "${exts[@]}"; do
            if [ -n "$patterns" ]; then
                patterns="$patterns -o"
            fi
            patterns="$patterns -name \"*$ext\""
        done
        eval "find \"$dir\" -type f \( $patterns \) -print0"
    else
        find "$dir" -type f -print0
    fi | \
        sort -z | \
        while IFS= read -r -d '' file; do
            echo -e "\n// File: $file\n" >> "$output_file"
            cat "$file" >> "$output_file"
        done
    
    # Count files in this directory
    if [ -n "$extensions" ]; then
        current_files=$(eval "find \"$dir\" -type f \( $patterns \) | wc -l")
    else
        current_files=$(find "$dir" -type f | wc -l)
    fi
    total_files=$((total_files + current_files))
done

# Calculate statistics
char_count=$(wc -m < "$output_file")
size_bytes=$(stat -f %z "$output_file" 2>/dev/null || stat -c %s "$output_file")
size_mb=$(echo "scale=2; $size_bytes / 1048576" | bc)

# Print summary
echo -e "\n=== Summary ==="
echo "Output file: $output_file"
echo "Total directories processed: $#"
echo "Total files processed: $total_files"
echo "Total characters: $char_count"
echo "File size: ${size_mb}MB"
