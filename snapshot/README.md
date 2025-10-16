# Code Snapshot Utility

A versatile Bash script to collect and format the content of selected directories and files into a single, structured text file (`snapshot.txt`). This output is ideal for sharing code context with AI models or for documentation.

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
| `-iext, --ignore-extensions`  | `<ext1> [ext2]...`   | File extensions to ignore (e.g., `png`, `zip`, `log`, `ts` ).           |
| `-ifile, --ignore-files`      | `<file1> [file2]...` | Specific files to ignore by full path/name (e.g., `package-lock.json`). |
| `-idir, --ignore-directories` | `<dir1> [dir2]...`   | Directories to ignore (e.g., `node_modules`, `.git`, `dist`).           |
| `-h, --help`                  |                      | Display the help message and exit.                                      |

## Example

Generate a snapshot of the current directory, explicitly including `my-config.yaml`, while ignoring build outputs, node dependencies, and log files:

```bash
./snapshot.sh \
  -d . \
  -f my-config.yaml \
  -idir node_modules dist \
  -iext log sh
```

## Output Format

The output is always written to `snapshot.txt` in the following structured format, designed for machine readability:

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
