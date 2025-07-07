#!/bin/bash
# Session management functions for code review
# Extracted from review-code.wf.md lines 78-95

# Generate timestamp for session naming
# Usage: generate_session_timestamp
# Output: YYYYMMDD-HHMMSS format timestamp
generate_session_timestamp() {
  date +%Y%m%d-%H%M%S
}

# Generate session name from components
# Usage: generate_session_name <focus> <target> [timestamp]
# Example: generate_session_name "code" "HEAD~1..HEAD" -> "code-HEAD~1..HEAD-20240106-143052"
generate_session_name() {
  local focus="$1"
  local target="$2"
  local timestamp="${3:-$(generate_session_timestamp)}"
  
  # Sanitize target for use in directory name
  local sanitized_target=$(echo "$target" | sed 's|/|-|g; s|\.\.|..|g')
  
  echo "${focus}-${sanitized_target}-${timestamp}"
}

# Create session directory structure
# Usage: create_session_directory <base_path> <session_name>
# Returns: Full path to created session directory
create_session_directory() {
  local base_path="$1"
  local session_name="$2"
  
  if [[ -z "$base_path" ]] || [[ -z "$session_name" ]]; then
    echo "Error: create_session_directory requires base_path and session_name" >&2
    return 1
  fi
  
  local session_dir="${base_path}/${session_name}"
  
  if ! mkdir -p "$session_dir"; then
    echo "Error: Failed to create session directory: $session_dir" >&2
    return 1
  fi
  
  echo "$session_dir"
}

# Write session metadata file
# Usage: write_session_metadata <session_dir> <command> <target> <focus> <context>
write_session_metadata() {
  local session_dir="$1"
  local command="$2"
  local target="$3"
  local focus="$4"
  local context="${5:-auto}"
  
  if [[ -z "$session_dir" ]] || [[ ! -d "$session_dir" ]]; then
    echo "Error: Invalid session directory: $session_dir" >&2
    return 1
  fi
  
  local metadata_file="${session_dir}/session.meta"
  
  cat > "$metadata_file" <<EOF
command: ${command}
timestamp: $(date -Iseconds)
target: ${target}
focus: ${focus}
context: ${context}
EOF
  
  if [[ ! -f "$metadata_file" ]]; then
    echo "Error: Failed to write session metadata" >&2
    return 1
  fi
  
  return 0
}

# Get session info from metadata file
# Usage: get_session_info <session_dir>
# Output: Space-separated values: command timestamp target focus context
get_session_info() {
  local session_dir="$1"
  local metadata_file="${session_dir}/session.meta"
  
  if [[ ! -f "$metadata_file" ]]; then
    echo "Error: Session metadata not found: $metadata_file" >&2
    return 1
  fi
  
  # Extract values using grep and sed
  local command=$(grep "^command:" "$metadata_file" | sed 's/^command: //')
  local timestamp=$(grep "^timestamp:" "$metadata_file" | sed 's/^timestamp: //')
  local target=$(grep "^target:" "$metadata_file" | sed 's/^target: //')
  local focus=$(grep "^focus:" "$metadata_file" | sed 's/^focus: //')
  local context=$(grep "^context:" "$metadata_file" | sed 's/^context: //')
  
  echo "$command" "$timestamp" "$target" "$focus" "$context"
}

# Create full session structure with metadata
# Usage: create_review_session <base_path> <focus> <target> <context>
# Returns: Full path to created session directory
create_review_session() {
  local base_path="$1"
  local focus="$2"
  local target="$3"
  local context="${4:-auto}"
  
  # Generate session components
  local timestamp=$(generate_session_timestamp)
  local session_name=$(generate_session_name "$focus" "$target" "$timestamp")
  
  # Create session directory
  local session_dir=$(create_session_directory "$base_path" "$session_name")
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  
  # Write metadata
  local command="@review-code ${focus} ${target} ${context}"
  if ! write_session_metadata "$session_dir" "$command" "$target" "$focus" "$context"; then
    # Clean up on failure
    rm -rf "$session_dir"
    return 1
  fi
  
  echo "$session_dir"
}