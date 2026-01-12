# Code Snapshot Utility

A versatile Bash script to collect and format the content of files and directories into a single, structured XML file. Perfect for sharing code context with AI models or for documentation.

## Features

- **Simple positional arguments** - Just `snapshot.sh .` to snapshot current directory
- **Auto-detection** - Automatically detects files vs directories
- **XML output format** - Clean, LLM-friendly structure with `<file>`, `<path>`, `<content>` tags
- **Git diff integration** - Include diffs alongside file contents with `--diff`
- **Smart ignoring** - Default ignores for `node_modules`, `.git`, plus custom `.snapshotignore` support
- **Extensible filtering** - Include/exclude by extension, file, or directory
- **Flexible output** - Write to file, pipe to commands (`pbcopy`, `less`), or use default timestamped files

## Quick Start

```bash
# Snapshot current directory
./snapshot.sh .

# Snapshot specific files and folders
./snapshot.sh src package.json README.md

# Snapshot with git diff
./snapshot.sh . --diff

# Snapshot changes vs main branch
./snapshot.sh src --diff main

# Copy to clipboard (macOS)
./snapshot.sh src -o pbcopy
```

## Usage

```bash
./snapshot.sh <path1> [path2] ... [OPTIONS]
```

**Arguments:**

- `<path1> [path2] ...` - Files and/or directories to include (auto-detected)

## Options

## Options

| Flag (Short/Long)            | Argument             | Description                                                                                 |
| :--------------------------- | :------------------- | :------------------------------------------------------------------------------------------ |
| `-o, --output`               | `<file_or_command>`  | Output file path or command to pipe to. Default: timestamped file in `snapshots/`           |
| `-e, --extension`            | `<ext1> [ext2]...`   | Only include files with these extensions (e.g., `ts`, `json`). Applies to directories only. |
| `-i, --ignore`               | `<path1> [path2]...` | Files or directories to ignore (auto-detected).                                             |
| `-iext, --ignore-extensions` | `<ext1> [ext2]...`   | File extensions to ignore (e.g., `png`, `zip`, `log`).                                      |
| `--diff [args]`              | `<git-diff-args>`    | Include git diff for processed files. Accepts git diff arguments.                           |
| `-h, --help`                 |                      | Display the help message and exit.                                                          |

### Default Ignores

The script automatically ignores:

- `node_modules/`
- `.git/`
- `snapshots/` (output directory)
- Output file

### .snapshotignore Support

Create a `.snapshotignore` file at your repository root to define custom ignore patterns:

```gitignore
# Comments and blank lines are ignored

# Ignore specific files
test.txt
.env

# Ignore directories (trailing slash optional)
build/
dist/

# Ignore extensions
*.log
*.tmp
```

## Examples

### Basic Usage

```bash
# Snapshot current directory (creates snapshots/scripts_YYYYMMDD_HHMMSS.txt)
./snapshot.sh .

# Snapshot specific directory
./snapshot.sh src

# Snapshot multiple paths
./snapshot.sh src tests package.json
```

### Filtering

```bash
# Only TypeScript and JSON files
./snapshot.sh src -e ts json

# Ignore specific files and directories (auto-detected)
./snapshot.sh . -i package-lock.json build dist node_modules

# Ignore with trailing slash for directories
./snapshot.sh . -i build/ dist/ coverage/

# Ignore extensions
./snapshot.sh . -iext log tmp cache
```

### Git Integration

```bash
# Include unstaged changes
./snapshot.sh src --diff

# Diff against main branch
./snapshot.sh . --diff main

# Diff between commits
./snapshot.sh src --diff abc123..def456

# Diff staged changes
./snapshot.sh . --diff --staged
```

### Output Options

```bash
# Custom output file
./snapshot.sh src -o my-snapshot.txt

# Pipe to clipboard (macOS)
./snapshot.sh src -o pbcopy

# Pipe to pager
./snapshot.sh . -o less

# Pipe to another command
./snapshot.sh src -e ts tsx -o "grep -v 'test'"
```

### Combined Examples

```bash
# TypeScript files with diff vs main, excluding tests
./snapshot.sh src -e ts tsx --diff main -i __tests__

# Snapshot with custom ignores
./snapshot.sh . -i node_modules build dist -iext log tmp -o context.txt
```

## Output Format

The output uses clean XML tags optimized for LLM understanding:

**Without git diff:**

```xml
<file>
<path>
src/components/Button.tsx
</path>

<content>
import React from 'react';

const Button = ({ children }) => (
  <button>{children}</button>
);

export default Button;
</content>
</file>
```

**With git diff:**

```xml
<file>
<path>
src/utils/helper.ts
</path>
<diff>
diff --git a/src/utils/helper.ts b/src/utils/helper.ts
index 1234567..abcdefg 100644
--- a/src/utils/helper.ts
+++ b/src/utils/helper.ts
@@ -1,3 +1,4 @@
 export function helper() {
-  return 'old';
+  // Updated implementation
+  return 'new';
 }
</diff>

<content>
export function helper() {
  // Updated implementation
  return 'new';
}
</content>
</file>
```

## How It Works

1. **Auto-setup**: Creates `snapshots/` directory at git repository root (added to `.gitignore`)
2. **Smart detection**: Distinguishes files from directories automatically
3. **Default naming**: Generates timestamped files like `<repo-name>_20260112_143022.txt`
4. **Ignore patterns**: Loads `.snapshotignore` from repo root, applies default ignores
5. **Processing**: Recursively processes directories, formats each file with XML tags
6. **Git integration**: Optionally includes diffs for only the processed files

## Installation

```bash
# Clone or download the script
chmod +x snapshot.sh

# Optional: Add to PATH
sudo ln -s $(pwd)/snapshot.sh /usr/local/bin/snapshot
```
