#!/bin/bash
# Module loader for bash modules - provides a standardized way to load and validate bash modules
# This enables reusable shell logic extraction from workflow files

# Set default modules directory relative to this script
BASH_MODULES_DIR="${BASH_MODULES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/modules}"

# Track loaded modules to prevent double-loading
# Use a colon-separated list for compatibility
LOADED_MODULES=""

# Load a bash module by category and name
# Usage: load_module <category> <module_name>
# Example: load_module code session-management
load_module() {
  local category="$1"
  local module_name="$2"
  
  # Validate arguments
  if [[ -z "$category" ]] || [[ -z "$module_name" ]]; then
    echo "Error: load_module requires category and module_name arguments" >&2
    return 1
  fi
  
  # Check if already loaded
  local module_key="${category}/${module_name}"
  if [[ ":${LOADED_MODULES}:" == *":${module_key}:"* ]]; then
    return 0  # Already loaded, success
  fi
  
  local module_path="${BASH_MODULES_DIR}/${category}/${module_name}.sh"
  
  if [[ ! -f "$module_path" ]]; then
    echo "Error: Module not found: $module_path" >&2
    return 1
  fi
  
  # Source the module
  if source "$module_path"; then
    LOADED_MODULES="${LOADED_MODULES}:${module_key}"
    return 0
  else
    echo "Error: Failed to source module: $module_path" >&2
    return 1
  fi
}

# Validate that a module provides expected functions
# Usage: validate_module_functions <function1> <function2> ...
validate_module_functions() {
  local missing_functions=()
  
  for func in "$@"; do
    if ! type -t "$func" >/dev/null 2>&1; then
      missing_functions+=("$func")
    fi
  done
  
  if [[ ${#missing_functions[@]} -gt 0 ]]; then
    echo "Error: Module missing required functions: ${missing_functions[*]}" >&2
    return 1
  fi
  
  return 0
}

# List available modules
# Usage: list_modules [category]
list_modules() {
  local category="$1"
  
  if [[ -n "$category" ]]; then
    # List modules in specific category
    local category_dir="${BASH_MODULES_DIR}/${category}"
    if [[ -d "$category_dir" ]]; then
      find "$category_dir" -name "*.sh" -type f | sed "s|${BASH_MODULES_DIR}/||; s|\.sh$||"
    fi
  else
    # List all modules
    find "$BASH_MODULES_DIR" -name "*.sh" -type f | sed "s|${BASH_MODULES_DIR}/||; s|\.sh$||"
  fi
}

# Check if a module is loaded
# Usage: is_module_loaded <category> <module_name>
is_module_loaded() {
  local category="$1"
  local module_name="$2"
  local module_key="${category}/${module_name}"
  
  [[ ":${LOADED_MODULES}:" == *":${module_key}:"* ]]
}

# Reset loaded modules (mainly for testing)
reset_loaded_modules() {
  LOADED_MODULES=""
}