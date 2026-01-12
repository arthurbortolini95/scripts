#!/bin/bash

# Define the default output file name
OUTPUT_FILE="snapshot.txt"
OUTPUT_COMMAND=""
COMMAND_OUTPUT_TEMPFILE=""

# Initialize arrays for arguments
DIRECTORIES=()
FILES=()
EXTENSIONS=()
IGNORE_EXTENSIONS=()
IGNORE_FILES=()
IGNORE_DIRS=()

# --- Argument Parsing ---
# Use getopts-style parsing for long and short arguments
# Based on a common pattern for handling variable-length arguments with flags

parse_args() {
    # Set default ignores (extensible)
    IGNORE_DIRS+=("node_modules" ".git")
    
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
            -e|--extension)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    # Prepend a dot for easier checking later
                    EXTENSIONS+=(".$1")
                    shift
                done
                ;;
            -o|--output)
                if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                    # Check if it looks like a command (contains special chars or is a known command)
                    # or if it's an existing command in PATH, treat as command
                    if [[ "$2" == *"|"* ]] || [[ "$2" == *">"* ]] || [[ "$2" == *"<"* ]] || [[ "$2" == *"&"* ]] || command -v "${2%% *}" >/dev/null 2>&1; then
                        OUTPUT_COMMAND="$2"
                        OUTPUT_FILE=""
                    else
                        # Treat as file path
                        OUTPUT_FILE="$2"
                        OUTPUT_COMMAND=""
                        # Add output file to ignore list
                        IGNORE_FILES+=("$OUTPUT_FILE")
                    fi
                    shift 2
                else
                    echo "Error: --output requires a value" >&2
                    exit 1
                fi
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

    # Add default output file to ignore list if using file output
    if [[ -n "$OUTPUT_FILE" ]]; then
        IGNORE_FILES+=("$OUTPUT_FILE")
    fi

    # Validate that -e/--extension is used with -d/--directory
    if [ ${#EXTENSIONS[@]} -gt 0 ] && [ ${#DIRECTORIES[@]} -eq 0 ]; then
        echo "Error: --extension (-e) can only be used with --directory (-d)" >&2
        exit 1
    fi
}

# --- Helper Functions ---

# Cleanup function for temporary files
cleanup() {
    if [[ -n "$COMMAND_OUTPUT_TEMPFILE" && -f "$COMMAND_OUTPUT_TEMPFILE" ]]; then
        rm -f "$COMMAND_OUTPUT_TEMPFILE"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Function to display usage help
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Takes a snapshot of files from specified directories and/or files."
    echo "By default, output is written to 'snapshot.txt' in the current directory."
    echo "The output file itself is automatically excluded from processing."
    echo ""
    echo "Mandatory (at least one of -d or -f must be provided):"
    echo "  -d, --directory <dir1> [dir2]...    : One or more directories to include."
    echo "  -f, --file <file1> [file2]...       : One or more specific files to include."
    echo ""
    echo "Optional Output:"
    echo "  -o, --output <file_or_command>      : Output file path or command to pipe to."
    echo "                                        If not provided, defaults to 'snapshot.txt'."
    echo "                                        Examples: 'output.txt' or 'pbcopy' or 'less'"
    echo ""
    echo "Optional Filtering:"
    echo "  -e, --extension <ext1> [ext2]...    : File extensions to include (e.g., ts js json)."
    echo "                                        Can only be used with --directory (-d)."
    echo "                                        If not specified, all files are included."
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

    # Skip the output file if it's being used for file output
    if [[ -n "$OUTPUT_FILE" ]]; then
        local abs_output_file=$(realpath "$OUTPUT_FILE" 2>/dev/null || echo "$OUTPUT_FILE")
        local abs_file_path=$(realpath "$file_path" 2>/dev/null || echo "$file_path")
        if [[ "$abs_file_path" == "$abs_output_file" ]]; then
            return
        fi
    fi

    # Check extension filtering (only for directory processing)
    if [[ ${#EXTENSIONS[@]} -gt 0 && "$2" == "from_directory" ]]; then
        local extension="${file_path##*.}"
        local full_extension=".${extension}"
        local matches_extension=false
        for allowed_ext in "${EXTENSIONS[@]}"; do
            if [[ "$full_extension" == "$allowed_ext" ]]; then
                matches_extension=true
                break
            fi
        done
        if [[ "$matches_extension" == false ]]; then
            return
        fi
    fi

    # Output the required format
    local content=$(cat <<EOF
# FILE PATH: $file_path
# CONTENT:
{{
$(cat "$file_path")

}}

# END OF FILE

EOF
)

    # Send output to file or command
    if [[ -n "$OUTPUT_COMMAND" ]]; then
        # For command output, write to temporary file
        if [[ -z "$COMMAND_OUTPUT_TEMPFILE" ]]; then
            COMMAND_OUTPUT_TEMPFILE=$(mktemp)
        fi
        echo "$content" >> "$COMMAND_OUTPUT_TEMPFILE"
    else
        echo "$content" >> "$OUTPUT_FILE"
    fi
}

# --- Main Logic ---

main() {
    # Clear the output file before starting (only if using file output)
    if [[ -n "$OUTPUT_FILE" ]]; then
        > "$OUTPUT_FILE"
    fi

    if [ ${#DIRECTORIES[@]} -eq 0 ] && [ ${#FILES[@]} -eq 0 ]; then
        echo "Error: You must provide at least one directory (-d) or one file (-f)." >&2
        print_help
        exit 1
    fi

    echo "--- Snapshot generation started ---"
    if [[ -n "$OUTPUT_COMMAND" ]]; then
        echo "Output command: $OUTPUT_COMMAND"
    else
        echo "Output file: $OUTPUT_FILE"
    fi

    if [[ ${#EXTENSIONS[@]} -gt 0 ]]; then
        echo "Filtering by extensions: ${EXTENSIONS[*]}"
    fi

    # 1. Process files explicitly provided with -f
    for file_path in "${FILES[@]}"; do
        process_file "$file_path" "from_file"
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
            process_file "$file" "from_directory"
        done < <(find "$dir_path" -type f -print0 2>/dev/null)
    done

    echo "--- Snapshot generation complete ---"
    
    # If using command output, pipe all content from temp file and clean up
    if [[ -n "$OUTPUT_COMMAND" ]]; then
        if [[ -n "$COMMAND_OUTPUT_TEMPFILE" && -f "$COMMAND_OUTPUT_TEMPFILE" ]]; then
            cat "$COMMAND_OUTPUT_TEMPFILE" | eval "$OUTPUT_COMMAND"
            rm -f "$COMMAND_OUTPUT_TEMPFILE"
        fi
    else
        echo "Total lines in snapshot: $(wc -l < "$OUTPUT_FILE")"
    fi
}

# Run the argument parsing with all provided script arguments
parse_args "$@"

# Execute the main function
main