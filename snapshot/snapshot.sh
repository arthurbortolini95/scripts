#!/bin/bash

# Define the output file name
OUTPUT_FILE="snapshot.txt"

# Initialize arrays for arguments
DIRECTORIES=()
FILES=()
IGNORE_EXTENSIONS=()
IGNORE_FILES=()
IGNORE_DIRS=()

# --- Argument Parsing ---
# Use getopts-style parsing for long and short arguments
# Based on a common pattern for handling variable-length arguments with flags

parse_args() {
    while (( "$#" )); do
        case "$1" in
            -d|--directory)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    DIRECTORIES+=("$1")
                    shift
                done
                ;;
            -f|--file)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    FILES+=("$1")
                    shift
                done
                ;;
            -iext|--ignore-extensions)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    # Prepend a dot for easier checking later
                    IGNORE_EXTENSIONS+=(".$1")
                    shift
                done
                ;;
            -ifile|--ignore-files)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    IGNORE_FILES+=("$1")
                    shift
                done
                ;;
            -idir|--ignore-directories)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    IGNORE_DIRS+=("$1")
                    shift
                done
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                echo "Error: Unknown argument '$1'" >&2
                print_help
                exit 1
                ;;
        esac
    done
}

# --- Helper Functions ---

# Function to display usage help
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Takes a snapshot of files from specified directories and/or files."
    echo "The output is written to '$OUTPUT_FILE' in the current directory."
    echo ""
    echo "Mandatory (at least one of -d or -f must be provided):"
    echo "  -d, --directory <dir1> [dir2]...    : One or more directories to include."
    echo "  -f, --file <file1> [file2]...       : One or more specific files to include."
    echo ""
    echo "Optional Exclusion Filters:"
    echo "  -iext, --ignore-extensions <ext1>...: One or more file extensions to ignore (e.g., ts js)."
    echo "  -ifile, --ignore-files <file1>...   : One or more specific files to ignore."
    echo "  -idir, --ignore-directories <dir1>..: One or more directories to ignore."
    echo "  -h, --help                          : Display this help message."
}

# Function to check if a file path or directory should be ignored
is_ignored() {
    local path="$1"

    # Check for ignored files (full path match)
    for ignored_file in "${IGNORE_FILES[@]}"; do
        if [[ "$path" == "$ignored_file" ]]; then
            return 0 # True (is ignored)
        fi
    done

    # Check for ignored directories (sub-path match)
    # Using '*/' to match directories even if the input path is a file inside it
    for ignored_dir in "${IGNORE_DIRS[@]}"; do
        # Note: This checks if the path *contains* the ignored directory path component
        # This is a common and robust way to check for directory exclusion in a full path.
        if [[ "$path" == "$ignored_dir" ]] || [[ "$path" == "$ignored_dir/"* ]]; then
            return 0 # True (is ignored)
        fi
    done

    # Check for ignored extensions (for files only)
    if [[ -f "$path" ]]; then
        local extension="${path##*.}"
        local full_extension=".${extension}"
        for ignored_ext in "${IGNORE_EXTENSIONS[@]}"; do
            if [[ "$full_extension" == "$ignored_ext" ]]; then
                return 0 # True (is ignored)
            fi
        done
    fi

    return 1 # False (not ignored)
}

# Function to process and format the content of a file
process_file() {
    local file_path="$1"

    # Check if the file exists and is a regular file
    if [[ ! -f "$file_path" ]]; then
        echo "Warning: File not found or is not a regular file: $file_path" >&2
        return
    fi

    # Check if file should be ignored
    if is_ignored "$file_path"; then
        return
    fi

    # Output the required format to the snapshot file
    {
        echo "# FILE PATH: $file_path"
        echo "# CONTENT:"
        echo "{{"
        # Use cat to output file content directly
        cat "$file_path"
        echo "" # Ensure a newline after content
        echo "}}"
        echo ""
        echo "# END OF FILE"
        echo ""
    } >> "$OUTPUT_FILE"
}

# --- Main Logic ---

main() {
    # Clear the output file before starting
    > "$OUTPUT_FILE"

    if [ ${#DIRECTORIES[@]} -eq 0 ] && [ ${#FILES[@]} -eq 0 ]; then
        echo "Error: You must provide at least one directory (-d) or one file (-f)." >&2
        print_help
        exit 1
    fi

    echo "--- Snapshot generation started ---"
    echo "Output file: $OUTPUT_FILE"

    # 1. Process files explicitly provided with -f
    for file_path in "${FILES[@]}"; do
        process_file "$file_path"
    done

    # 2. Process files found in directories provided with -d
    for dir_path in "${DIRECTORIES[@]}"; do
        if is_ignored "$dir_path"; then
            echo "Skipping ignored directory: $dir_path" >&2
            continue
        fi

        # Find all files within the directory recursively
        # -type f: only regular files
        # -print0: null-separated output for safe handling of paths with spaces/special chars
        while IFS= read -r -d $'\0' file; do
            # The find command may return a relative path, so we normalize it if needed
            # In most cases, find returns './file' or 'dir/file'
            process_file "$file"
        done < <(find "$dir_path" -type f -print0 2>/dev/null)
    done

    echo "--- Snapshot generation complete ---"
    echo "Total lines in snapshot: $(wc -l < "$OUTPUT_FILE")"
}

# Run the argument parsing with all provided script arguments
parse_args "$@"

# Execute the main function
main