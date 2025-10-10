#!/usr/bin/env fish

# Fish shell PATH Setup for tools-meta project
# This script adds the dev-tools/exe directory to your PATH for the current session
# Usage: source setup.fish

function detect_project_root
    # Get the directory where this script is located
    set script_dir (dirname (status --current-filename))
    
    # If this script is in the original location (config/bin-setup-env), use relative path
    if string match -q "*config/bin-setup-env" $script_dir
        # Go up 3 levels: config/bin-setup-env -> config -> dev-tools -> project-root
        set project_root (dirname (dirname (dirname $script_dir)))
        if test -d "$project_root/.git"; or test -f "$project_root/coding_agent_tools.gemspec"; or test -f "$project_root/Gemfile"
            echo $project_root
            return 0
        end
    end
    
    # Fallback: try to find project root by looking for markers from current directory
    set search_path (pwd)
    while test "$search_path" != "/"
        if test -d "$search_path/.git"; or test -f "$search_path"/*.gemspec; or test -f "$search_path/Gemfile"
            echo $search_path
            return 0
        end
        # Also check for dev-* directories indicating multi-repo structure
        set dev_dirs 0
        for dev_dir in "dev-tools" "dev-handbook" "dev-taskflow"
            if test -d "$search_path/$dev_dir"
                set dev_dirs (math $dev_dirs + 1)
            end
        end
        if test $dev_dirs -ge 2
            echo $search_path
            return 0
        end
        set search_path (dirname $search_path)
    end
    
    echo "Error: Could not detect project root. Current directory: "(pwd) >&2
    echo "Try setting PROJECT_ROOT environment variable to your tools-meta project root" >&2
    echo "Example: set -gx PROJECT_ROOT /path/to/your/tools-meta" >&2
    return 1
end

# Get project root
if set -q PROJECT_ROOT
    set TOOLS_PROJECT_ROOT $PROJECT_ROOT
else
    set TOOLS_PROJECT_ROOT (detect_project_root)
    if test $status -ne 0
        exit 1
    end
end

set TOOLS_EXE_DIR "$TOOLS_PROJECT_ROOT/dev-tools/exe"

# Check if the exe directory exists
if not test -d "$TOOLS_EXE_DIR"
    echo "Error: exe directory not found at $TOOLS_EXE_DIR"
    echo "Make sure you're running this script from within the tools-meta project."
    exit 1
end

# Check if already in PATH
if string match -q "*$TOOLS_EXE_DIR*" $PATH
    echo "tools-meta executables already in PATH"
else
    # Add to PATH
    set -gx PATH "$TOOLS_EXE_DIR" $PATH
    echo "Added tools-meta executables to PATH:"
    echo "  $TOOLS_EXE_DIR"
end

# List available executables
echo ""
echo "Available executables:"
for exe in $TOOLS_EXE_DIR/*
    if test -x "$exe"
        echo "  "(basename "$exe")
    end
end

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
echo "To make it permanent, add this line to your ~/.config/fish/config.fish:"
echo "  set -gx PATH \"$TOOLS_EXE_DIR\" \$PATH"