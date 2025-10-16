# Dev Utility Scripts

This repository hosts a collection of reusable Bash scripts designed to streamline common developer workflows, focusing on automation, context capture, and project maintenance.

## Scripts Included

| Script            | Description                                                                                                                                            | Primary Use Case                                                                         |
| :---------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------- |
| **`snapshot.sh`** | **Code Snapshot Utility:** Recursively aggregates the content of specified files and directories into a single, structured text file (`snapshot.txt`). | Generating comprehensive project context for AI analysis, documentation, or code review. |

## Installation

These scripts are designed to run directly on any Unix-like environment (Linux, macOS, WSL).

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/your-username/dev-scripts.git
    cd dev-scripts
    ```
2.  **Ensure Execution Rights:**
    ```bash
    chmod +x *.sh
    ```
3.  **Optional: Add to PATH:** For convenient access from any directory, you can add this repository's directory to your system's `$PATH`.

## Contributing

We welcome contributions to improve existing scripts or add new utilities\! Please submit a pull request with a clear description of the new script's function and usage.
