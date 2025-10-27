# Code Snapshot Utility

A versatile Bash script to collect and format the content of selected directories and files into a single, structured text file (`snapshot.txt`) or pipe the output to a command. This output is ideal for sharing code context with AI models or for documentation.

## Usage

```bash
./snapshot.sh [OPTIONS]
```

At least one of the inclusion flags (`-d` or `-f`) must be provided.

## Options

| Flag (Short/Long)             | Argument             | Description                                                             |
| :---------------------------- | :------------------- | :---------------------------------------------------------------------- |
| `-d, --directory`             | `<dir1> [dir2]...`   | One or more directories to include **recursively**.                     |
| `-f, --file`                  | `<file1> [file2]...` | One or more specific files to include.                                  |
| `-e, --extension`             | `<ext1> [ext2]...`   | Only include files with these extensions (e.g., `ts`, `json`). Must be used with `-d`. |
| `-o, --output`                | `<file_or_command>`  | Output file path or command to pipe to (e.g., `pbcopy`, `less`).        |
| `-iext, --ignore-extensions`  | `<ext1> [ext2]...`   | File extensions to ignore (e.g., `png`, `zip`, `log`, `ts`).            |
| `-ifile, --ignore-files`      | `<file1> [file2]...` | Specific files to ignore by full path/name (e.g., `package-lock.json`). |
| `-idir, --ignore-directories` | `<dir1> [dir2]...`   | Directories to ignore (e.g., `node_modules`, `.git`, `dist`).           |
| `-h, --help`                  |                      | Display the help message and exit.                                      |

### Output File Exclusion
- The output file (default `snapshot.txt` or custom file via `-o`) is automatically excluded from processing.
- When using command output (e.g., `-o pbcopy`), no file exclusion is needed.

## Examples

Generate a snapshot of the current directory, explicitly including `my-config.yaml`, while ignoring build outputs, node dependencies, and log files:

```bash
./snapshot.sh \
  -d . \
  -f my-config.yaml \
  -idir node_modules dist \
  -iext log sh
```

Filter only TypeScript and JSON files from a directory:
```bash
./snapshot.sh -d src/ -e ts json
```

Pipe output to clipboard (macOS):
```bash
./snapshot.sh -d src/ -e ts -o pbcopy
```

Pipe output to a pager:
```bash
./snapshot.sh -d . -o less
```

Write output to a custom file:
```bash
./snapshot.sh -d src/ -e ts tsx -o my-code.txt
```

## Output Format

The output is always written to `snapshot.txt` (or the specified output) in the following structured format, designed for machine readability:

```
# FILE PATH: src/components/Button.tsx
# CONTENT:
{{
import React from 'react';

const Button = ({ children }) => (
  <button>{children}</button>
);

export default Button;
}}

# END OF FILE

# FILE PATH: package.json
# CONTENT:
{{
{
  "name": "my-project",
  "version": "1.0.0"
}
}}

# END OF FILE
```
