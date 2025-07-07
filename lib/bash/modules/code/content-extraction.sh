#!/bin/bash
# Content extraction functions for code review
# Extracted from review-code.wf.md lines 134-200

# Extract git diff for various target types
# Usage: extract_git_diff <target> <output_file>
extract_git_diff() {
  local target="$1"
  local output_file="$2"
  
  if [[ -z "$target" ]] || [[ -z "$output_file" ]]; then
    echo "Error: extract_git_diff requires target and output_file" >&2
    return 1
  fi
  
  local diff_command=""
  
  # Determine git diff command based on target
  case "$target" in
    "staged")
      diff_command="git diff --staged --no-color"
      ;;
    "unstaged")
      diff_command="git diff --no-color"
      ;;
    "working")
      diff_command="git diff HEAD --no-color"
      ;;
    *..*)
      # Commit range
      diff_command="git diff $target --no-color"
      ;;
    *)
      echo "Error: Invalid git diff target: $target" >&2
      return 1
      ;;
  esac
  
  # Execute diff and save to file
  if ! $diff_command > "$output_file"; then
    echo "Error: Failed to execute git diff for target: $target" >&2
    return 1
  fi
  
  # Check if diff is empty
  if [[ ! -s "$output_file" ]]; then
    echo "Warning: Git diff is empty for target: $target" >&2
  fi
  
  return 0
}

# Write diff metadata
# Usage: write_diff_metadata <target> <diff_file> <meta_file>
write_diff_metadata() {
  local target="$1"
  local diff_file="$2"
  local meta_file="$3"
  
  if [[ ! -f "$diff_file" ]]; then
    echo "Error: Diff file not found: $diff_file" >&2
    return 1
  fi
  
  local line_count=$(wc -l < "$diff_file")
  
  cat > "$meta_file" <<EOF
# Diff Metadata
target: ${target}
type: git_diff
size: ${line_count} lines
EOF
  
  return 0
}

# Create XML container for file content
# Usage: create_xml_container <output_file>
create_xml_container() {
  local output_file="$1"
  
  cat > "$output_file" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<documents>
EOF
  
  return 0
}

# Add file to XML container
# Usage: add_file_to_xml <file_path> <xml_file>
add_file_to_xml() {
  local file_path="$1"
  local xml_file="$2"
  
  if [[ ! -f "$file_path" ]]; then
    echo "Error: File not found: $file_path" >&2
    return 1
  fi
  
  # Add document opening tag
  echo "  <document path=\"$file_path\">" >> "$xml_file"
  echo "    <![CDATA[" >> "$xml_file"
  
  # Add file content
  cat "$file_path" >> "$xml_file"
  
  # Add closing tags
  echo "    ]]>" >> "$xml_file"
  echo "  </document>" >> "$xml_file"
  
  return 0
}

# Close XML container
# Usage: close_xml_container <xml_file>
close_xml_container() {
  local xml_file="$1"
  
  echo '</documents>' >> "$xml_file"
  
  return 0
}

# Extract files matching pattern
# Usage: extract_file_pattern <pattern> <output_file>
extract_file_pattern() {
  local pattern="$1"
  local output_file="$2"
  
  # Create XML container
  if ! create_xml_container "$output_file"; then
    return 1
  fi
  
  # Find files matching pattern
  local file_count=0
  while IFS= read -r -d '' file; do
    if add_file_to_xml "$file" "$output_file"; then
      ((file_count++))
    fi
  done < <(find . -path "$pattern" -type f -print0)
  
  # Close XML container
  close_xml_container "$output_file"
  
  if [[ $file_count -eq 0 ]]; then
    echo "Warning: No files found matching pattern: $pattern" >&2
  fi
  
  echo "$file_count"
  return 0
}

# Extract single file
# Usage: extract_single_file <file_path> <output_file>
extract_single_file() {
  local file_path="$1"
  local output_file="$2"
  
  if [[ ! -f "$file_path" ]]; then
    echo "Error: File not found: $file_path" >&2
    return 1
  fi
  
  # Create XML container
  create_xml_container "$output_file"
  
  # Add the single file
  add_file_to_xml "$file_path" "$output_file"
  
  # Close XML container
  close_xml_container "$output_file"
  
  return 0
}

# Write file pattern metadata
# Usage: write_file_metadata <target> <type> <file_count> <meta_file>
write_file_metadata() {
  local target="$1"
  local type="$2"
  local file_count="$3"
  local meta_file="$4"
  
  cat > "$meta_file" <<EOF
target: ${target}
type: ${type}
files: ${file_count}
EOF
  
  if [[ "$type" == "single_file" ]] && [[ -f "$target" ]]; then
    local line_count=$(wc -l < "$target")
    echo "size: ${line_count} lines" >> "$meta_file"
  fi
  
  return 0
}

# Main content extraction dispatcher
# Usage: extract_review_content <target> <session_dir>
extract_review_content() {
  local target="$1"
  local session_dir="$2"
  
  # Determine target type and extract content
  if [[ "$target" == "staged" ]] || [[ "$target" == "unstaged" ]] || [[ "$target" == "working" ]] || [[ "$target" =~ \.\. ]]; then
    # Git diff targets
    local diff_file="${session_dir}/input.diff"
    local meta_file="${session_dir}/input.meta"
    
    if extract_git_diff "$target" "$diff_file"; then
      write_diff_metadata "$target" "$diff_file" "$meta_file"
      echo "diff"
      return 0
    fi
  elif [[ -f "$target" ]]; then
    # Single file
    local xml_file="${session_dir}/input.xml"
    local meta_file="${session_dir}/input.meta"
    
    if extract_single_file "$target" "$xml_file"; then
      write_file_metadata "$target" "single_file" 1 "$meta_file"
      echo "xml"
      return 0
    fi
  else
    # File pattern
    local xml_file="${session_dir}/input.xml"
    local meta_file="${session_dir}/input.meta"
    
    local file_count=$(extract_file_pattern "$target" "$xml_file")
    if [[ $? -eq 0 ]]; then
      write_file_metadata "$target" "file_pattern" "$file_count" "$meta_file"
      echo "xml"
      return 0
    fi
  fi
  
  return 1
}