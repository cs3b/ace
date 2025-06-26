#!/usr/bin/env bash
# get-current-release-path: Determine the appropriate directory for storing tasks and return version info
# Returns the path to current release directory if one exists, otherwise returns backlog path
# Also returns the version string extracted from the current release directory name

set -euo pipefail

# Function to print usage instructions
print_usage() {
    echo "Usage: docs-dev/tools/get-current-release-path.sh [OPTIONS]"
    echo ""
    echo "Determines the appropriate directory for storing newly created tasks."
    echo "Returns two lines: directory path and version string (empty if no current release)."
    echo ""
    echo "Options:"
    echo "  -h, --help    Display this help message"
    echo ""
    echo "Output format:"
    echo "  Line 1: Directory path (e.g., 'docs-project/current/v.0.3.0-codename' or 'docs-dev/backlog/tasks')"
    echo "  Line 2: Version string (e.g., 'v.0.3.0' or empty string)"
}

# Parse command-line arguments
case "${1:-}" in
    -h|--help)
        print_usage
        exit 0
        ;;
    "")
        # No arguments is fine, proceed with main logic
        ;;
    *)
        echo "Error: Unknown option '$1'" >&2
        print_usage >&2
        exit 1
        ;;
esac

# Main logic to find current release directory
current_release_pattern="docs-project/current/v.*.*.*-*"

# Find directories matching the current release pattern
release_dirs=(docs-project/current/v.*.*.*)
if [[ ${#release_dirs[@]} -eq 1 && -d "${release_dirs[0]}" ]]; then
    # Found exactly one current release directory
    release_dir="${release_dirs[0]}"
    
    # Extract version from directory name
    # Pattern: docs-project/current/v.X.Y.Z-codename -> v.X.Y.Z
    dir_name=$(basename "$release_dir")
    if [[ $dir_name =~ ^(v\.[0-9]+\.[0-9]+\.[0-9]+)- ]]; then
        version="${BASH_REMATCH[1]}"
    else
        # Fallback: try to extract just v.X.Y.Z pattern even without codename
        if [[ $dir_name =~ ^(v\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
            version="${BASH_REMATCH[1]}"
        else
            version=""
        fi
    fi
    
    echo "$release_dir"
    echo "$version"
elif [[ ${#release_dirs[@]} -gt 1 ]]; then
    # Multiple release directories found - this shouldn't happen but handle gracefully
    # Take the first one lexicographically
    for dir in "${release_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            release_dir="$dir"
            break
        fi
    done
    
    if [[ -n "${release_dir:-}" ]]; then
        dir_name=$(basename "$release_dir")
        if [[ $dir_name =~ ^(v\.[0-9]+\.[0-9]+\.[0-9]+)- ]]; then
            version="${BASH_REMATCH[1]}"
        else
            if [[ $dir_name =~ ^(v\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
                version="${BASH_REMATCH[1]}"
            else
                version=""
            fi
        fi
        
        echo "$release_dir"
        echo "$version"
    else
        # Fallback to backlog
        echo "docs-dev/backlog/tasks"
        echo ""
    fi
else
    # No current release directory found, use backlog
    echo "docs-dev/backlog/tasks"
    echo ""
fi