# Template Sync Script Architecture Design

## Overview

Design document for the `markdown-sync-embedded-documents` script that synchronizes XML-embedded template content in workflow instructions with their corresponding template files.

## Script Architecture

### File Structure

```
.ace/tools/exe-old/markdown-sync-embedded-documents    # Main Ruby script implementation
.ace/tools/exe-old/_binstubs/markdown-sync-embedded-documents  # Binstub wrapper
handbook sync-templates                 # Thin wrapper for project root
```

## Command-Line Interface

### Script Name

`markdown-sync-embedded-documents`

### Command-Line Options

```bash
# Basic usage - sync all workflow files
markdown-sync-embedded-documents

# Dry run - show what would be changed
markdown-sync-embedded-documents --dry-run

# Verbose output
markdown-sync-embedded-documents --verbose

# Custom path to scan
markdown-sync-embedded-documents --path .ace/handbook/workflow-instructions

# Auto-commit changes
markdown-sync-embedded-documents --commit

# Help
markdown-sync-embedded-documents --help
```

### Option Details

**`--dry-run`**

- Show what changes would be made without modifying files
- Display content differences for each template
- Output summary of potential actions

**`--verbose`**

- Detailed output during processing
- Show file paths being processed
- Display template extraction and comparison details
- Report skipped files and reasons

**`--path PATH`**

- Specify directory to scan for workflow files
- Default: `.ace/handbook/workflow-instructions`
- Recursively processes `.wf.md` files

**`--commit`**

- Automatically commit changes after synchronization
- Use standardized commit message format
- Only commits if changes were made

**`--help`**

- Display usage information and examples
- Show all available options

## Core Algorithm

### 1. File Discovery

```ruby
def find_workflow_files(base_path)
  Dir.glob(File.join(base_path, "**/*.wf.md"))
end
```

### 2. XML Template Extraction

```ruby
def extract_templates(content)
  # Regex: /<templates>(.*?)<\/templates>/m
  # For each match, extract individual <template path="..."> blocks
  # Return array of {path: "...", content: "..."}
end
```

### 3. Template File Reading

```ruby
def read_template_file(template_path)
  # Handle file not found errors
  # Read and return template file content
  # Normalize line endings
end
```

### 4. Content Comparison

```ruby
def content_differs?(embedded_content, file_content)
  # Normalize whitespace and line endings
  # Compare cleaned content
  # Return true if synchronization needed
end
```

### 5. XML Update

```ruby
def update_embedded_template(content, template_path, new_content)
  # Find specific <template path="..."> block
  # Replace content while preserving XML structure
  # Maintain indentation and formatting
end
```

### 6. File Writing and Commit

```ruby
def write_file_and_commit(file_path, updated_content, commit_option)
  # Write updated content to file
  # If --commit option, stage and commit with standardized message
end
```

## Error Handling

### Template File Not Found

```
ERROR: Template file not found: .ace/handbook/templates/missing.template.md
  Referenced in: .ace/handbook/workflow-instructions/example.wf.md
  Action: Create template file or update path reference
```

### Invalid XML Structure

```
ERROR: Invalid XML template structure in: .ace/handbook/workflow-instructions/example.wf.md
  Line 123: <template path="..." missing closing tag
  Action: Fix XML syntax in workflow file
```

### Permission Errors

```
ERROR: Cannot write to file: .ace/handbook/workflow-instructions/example.wf.md
  Reason: Permission denied
  Action: Check file permissions
```

## Output Format

### Standard Operation

```
Scanning workflow files in: .ace/handbook/workflow-instructions/
Found 17 workflow files to process

Processing: create-adr.wf.md
  ✅ Template synchronized: .ace/handbook/templates/project-docs/decisions/adr.template.md

Processing: create-task.wf.md
  ℹ️  Template up-to-date: .ace/handbook/templates/release-tasks/task.template.md

Processing: update-roadmap.wf.md
  ⚠️  Template file not found: .ace/handbook/templates/missing.template.md

Summary:
  Files processed: 17
  Templates synchronized: 1
  Templates up-to-date: 15
  Errors: 1
```

### Dry Run Output

```
DRY RUN MODE - No files will be modified

Processing: create-adr.wf.md
  📋 WOULD UPDATE: .ace/handbook/templates/project-docs/decisions/adr.template.md
  
  Differences found:
  - Line 5: [OLD] ## Status
  + Line 5: [NEW] ## Status
  
  - Line 6: [OLD] Proposed
  + Line 6: [NEW] [Proposed | Accepted | Deprecated | Superseded]

Summary:
  Would synchronize: 1 template
  Would skip: 16 templates (up-to-date)
```

### Verbose Output

```
DEBUG: Scanning directory: .ace/handbook/workflow-instructions/
DEBUG: Found workflow file: create-adr.wf.md
DEBUG: Extracting templates from: create-adr.wf.md
DEBUG: Found template: .ace/handbook/templates/project-docs/decisions/adr.template.md
DEBUG: Reading template file: .ace/handbook/templates/project-docs/decisions/adr.template.md
DEBUG: Comparing content...
DEBUG: Content differs, updating embedded template
DEBUG: Writing updated content to: create-adr.wf.md
```

## Commit Message Format

```
chore: sync embedded templates

- Updated template in create-adr.wf.md
- Synchronized 1 template, 16 up-to-date

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Validation and Testing

### Input Validation

- Verify workflow file paths exist and are readable
- Validate XML template structure before processing
- Check template file paths are within `.ace/handbook/templates/`

### Edge Cases

- Empty template content
- Templates with special characters or encoding
- Very large template files
- Concurrent file access

### Success Criteria

- Correctly identifies all XML template sections
- Accurately extracts template paths from simplified single-attribute format  
- Compares content reliably ignoring whitespace differences
- Updates only templates that have changed
- Preserves XML structure and formatting
- Handles errors gracefully with helpful messages
- Supports all command-line options as specified

## Implementation Approach

### Phase 1: Core XML Processing

1. Implement XML template extraction using regex
2. Add template file reading with error handling
3. Create content comparison logic

### Phase 2: File Processing

1. Add workflow file discovery
2. Implement content update mechanism
3. Add file writing with backup option

### Phase 3: Command-Line Interface

1. Add option parsing with OptionParser
2. Implement dry-run and verbose modes
3. Add help documentation

### Phase 4: Git Integration

1. Add commit functionality
2. Implement standardized commit messages
3. Add git status checking

This design provides a robust foundation for automated template synchronization while following project conventions and handling edge cases appropriately.
