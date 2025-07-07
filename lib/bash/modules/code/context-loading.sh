#!/bin/bash
# Context loading functions for code review
# Provides functions to load project context based on mode

# Load automatic project context documents
# Usage: load_auto_context
# Returns: 0 on success, 1 on failure
# Output: Sets CONTEXT_DOCUMENTS array
load_auto_context() {
  # Initialize context documents array
  CONTEXT_DOCUMENTS=()
  
  # Define standard project documents to load
  local doc_blueprint="docs/blueprint.md"
  local doc_vision="docs/what-do-we-build.md"
  local doc_architecture="docs/architecture.md"
  
  # Check and load blueprint
  if [[ -f "$doc_blueprint" ]]; then
    CONTEXT_DOCUMENTS+=("blueprint:$doc_blueprint")
  else
    echo "Warning: Blueprint document not found: $doc_blueprint" >&2
  fi
  
  # Check and load vision
  if [[ -f "$doc_vision" ]]; then
    CONTEXT_DOCUMENTS+=("vision:$doc_vision")
  else
    echo "Warning: Vision document not found: $doc_vision" >&2
  fi
  
  # Check and load architecture (optional)
  if [[ -f "$doc_architecture" ]]; then
    CONTEXT_DOCUMENTS+=("architecture:$doc_architecture")
  fi
  
  # Return success if at least one document loaded
  if [[ ${#CONTEXT_DOCUMENTS[@]} -gt 0 ]]; then
    return 0
  else
    echo "Error: No project context documents found" >&2
    return 1
  fi
}

# Load custom context from specified file
# Usage: load_custom_context <file_path>
# Returns: 0 on success, 1 on failure
# Output: Sets CONTEXT_DOCUMENTS array
load_custom_context() {
  local custom_file="$1"
  
  if [[ -z "$custom_file" ]]; then
    echo "Error: Custom context file path required" >&2
    return 1
  fi
  
  if [[ ! -f "$custom_file" ]]; then
    echo "Error: Custom context file not found: $custom_file" >&2
    return 1
  fi
  
  # Initialize with custom document
  CONTEXT_DOCUMENTS=("custom:$custom_file")
  
  return 0
}

# Skip context loading (none mode)
# Usage: skip_context_loading
# Returns: Always 0
# Output: Sets empty CONTEXT_DOCUMENTS array
skip_context_loading() {
  CONTEXT_DOCUMENTS=()
  return 0
}

# Main context loader dispatcher
# Usage: load_project_context <mode> [custom_path]
# Returns: 0 on success, 1 on failure
# Output: Sets CONTEXT_DOCUMENTS array
load_project_context() {
  local mode="${1:-auto}"
  local custom_path="$2"
  
  case "$mode" in
    "auto")
      load_auto_context
      ;;
    "none")
      skip_context_loading
      ;;
    "custom")
      if [[ -z "$custom_path" ]]; then
        echo "Error: Custom mode requires a file path" >&2
        return 1
      fi
      load_custom_context "$custom_path"
      ;;
    *)
      # If mode looks like a file path, treat as custom
      if [[ -f "$mode" ]]; then
        load_custom_context "$mode"
      else
        echo "Error: Invalid context mode: $mode" >&2
        return 1
      fi
      ;;
  esac
}

# Add context documents to prompt file
# Usage: add_context_to_prompt <prompt_file>
# Requires: CONTEXT_DOCUMENTS array to be set
add_context_to_prompt() {
  local prompt_file="$1"
  
  if [[ -z "$prompt_file" ]]; then
    echo "Error: Prompt file path required" >&2
    return 1
  fi
  
  echo -e "\n  <project-context>" >> "$prompt_file"
  
  # Add each context document
  for doc_spec in "${CONTEXT_DOCUMENTS[@]}"; do
    local doc_type="${doc_spec%%:*}"
    local doc_path="${doc_spec#*:}"
    
    if [[ -f "$doc_path" ]]; then
      echo "    <document type=\"$doc_type\">" >> "$prompt_file"
      echo "      <![CDATA[" >> "$prompt_file"
      cat "$doc_path" >> "$prompt_file"
      echo "      ]]>" >> "$prompt_file"
      echo "    </document>" >> "$prompt_file"
    fi
  done
  
  echo "  </project-context>" >> "$prompt_file"
  
  return 0
}

# Get context summary for logging
# Usage: get_context_summary
# Requires: CONTEXT_DOCUMENTS array to be set
# Output: Human-readable context summary
get_context_summary() {
  if [[ ${#CONTEXT_DOCUMENTS[@]} -eq 0 ]]; then
    echo "No context loaded"
  else
    echo "Loaded ${#CONTEXT_DOCUMENTS[@]} document(s):"
    for doc_spec in "${CONTEXT_DOCUMENTS[@]}"; do
      local doc_type="${doc_spec%%:*}"
      local doc_path="${doc_spec#*:}"
      echo "  - $doc_type: $doc_path"
    done
  fi
}

# Check if context documents are available
# Usage: check_context_availability
# Returns: 0 if at least one standard doc exists, 1 otherwise
check_context_availability() {
  local available=0
  
  [[ -f "docs/blueprint.md" ]] && available=1
  [[ -f "docs/what-do-we-build.md" ]] && available=1
  [[ -f "docs/architecture.md" ]] && available=1
  
  if [[ $available -eq 1 ]]; then
    return 0
  else
    echo "Warning: No standard project context documents found in docs/" >&2
    return 1
  fi
}