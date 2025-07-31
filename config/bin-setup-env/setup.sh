#!/bin/bash

# Bash/Zsh PATH Setup for tools-meta project
# This script adds the dev-tools/exe directory to your PATH for the current session
# Usage: source setup.sh  OR  . setup.sh

# Determine the project root directory using ProjectRootDetector logic
detect_project_root() {
    local current_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # If this script is in the original location (config/bin-setup-env), use relative path
    if [[ "$current_path" == *"/config/bin-setup-env" ]]; then
        # Go up 3 levels: config/bin-setup-env -> config -> dev-tools -> project-root
        local project_root="$(dirname "$(dirname "$(dirname "$current_path")")")"
        if [[ -d "$project_root/.git" ]] || [[ -f "$project_root/coding_agent_tools.gemspec" ]] || [[ -f "$project_root/Gemfile" ]]; then
            echo "$project_root"
            return 0
        fi
    fi
    
    # Fallback: try to find project root by looking for markers from current directory
    local search_path="$(pwd)"
    while [[ "$search_path" != "/" ]]; do
        if [[ -d "$search_path/.git" ]] || [[ -f "$search_path"/*.gemspec ]] || [[ -f "$search_path/Gemfile" ]]; then
            echo "$search_path"
            return 0
        fi
        # Also check for dev-* directories indicating multi-repo structure
        local dev_dirs=0
        for dev_dir in "dev-tools" "dev-handbook" "dev-taskflow"; do
            [[ -d "$search_path/$dev_dir" ]] && ((dev_dirs++))
        done
        if [[ $dev_dirs -ge 2 ]]; then
            echo "$search_path"
            return 0
        fi
        search_path="$(dirname "$search_path")"
    done
    
    echo "Error: Could not detect project root. Current directory: $(pwd)" >&2
    echo "Try setting PROJECT_ROOT environment variable to your tools-meta project root" >&2
    echo "Example: export PROJECT_ROOT=/path/to/your/tools-meta" >&2
    return 1
}

# Get project root
if [[ -n "$PROJECT_ROOT" ]]; then
    TOOLS_PROJECT_ROOT="$PROJECT_ROOT"
else
    TOOLS_PROJECT_ROOT="$(detect_project_root)"
    if [[ $? -ne 0 ]]; then
        return 1 2>/dev/null || exit 1
    fi
fi

TOOLS_EXE_DIR="$TOOLS_PROJECT_ROOT/dev-tools/exe"

# Check if the exe directory exists
if [[ ! -d "$TOOLS_EXE_DIR" ]]; then
    echo "Error: exe directory not found at $TOOLS_EXE_DIR"
    echo "Make sure you're running this script from within the tools-meta project."
    return 1 2>/dev/null || exit 1
fi

# Check if already in PATH
if echo "$PATH" | grep -q "$TOOLS_EXE_DIR"; then
    echo "tools-meta executables already in PATH"
else
    # Add to PATH
    export PATH="$TOOLS_EXE_DIR:$PATH"
    echo "Added tools-meta executables to PATH:"
    echo "  $TOOLS_EXE_DIR"
fi

# List available executables
echo ""
echo "Available executables:"
for exe in "$TOOLS_EXE_DIR"/*; do
    if [[ -x "$exe" ]]; then
        echo "  $(basename "$exe")"
    fi
done

# Provide usage information
echo ""
echo "Usage examples:"
echo "  task-manager next          # Find next actionable task"
echo "  task-manager list          # List all tasks"
echo "  llm-query \"your prompt\"    # Query LLM providers"
echo "  llm-models                 # List available models"
echo "  coding_agent_tools --help  # Show main CLI help"

# Note about persistence
echo ""
echo "Note: This PATH setup is only for the current session."
echo "To make it permanent, add this line to your ~/.bashrc or ~/.zshrc:"
echo "  export PATH=\"$TOOLS_EXE_DIR:\$PATH\""