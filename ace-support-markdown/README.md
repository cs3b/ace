# ace-support-markdown

Safe markdown editing with frontmatter support for ACE gems. Provides zero-corruption document operations through atomic writes, backup/rollback mechanisms, and Kramdown AST-based section editing.

## Purpose

`ace-support-markdown` provides safe, composable Markdown document editing primitives for ACE packages. It is designed for
developer-facing tooling that needs reliable frontmatter and section updates without corrupting files.

## Features

- **Zero Corruption**: Atomic file operations with backup and rollback
- **Frontmatter Editing**: Safe YAML frontmatter updates with validation
- **Section Editing**: Kramdown AST-based section manipulation (exact string matching)
- **Document Building**: Fluent API for programmatic document generation
- **Immutable Models**: Functional transformations prevent accidental mutations
- **Performance**: <10ms frontmatter updates, <50ms section edits
- **ATOM Architecture**: Testable, composable, maintainable

## Installation

Add to your Gemfile:

```ruby
gem 'ace-support-markdown', '~> 0.1'
```

## Quick Start

```ruby
require 'ace/support/markdown'

# Edit existing document
editor = Ace::Support::Markdown::Organisms::DocumentEditor.new("task.md")
editor.update_frontmatter({"status" => "done", "updated_at" => "today"})
editor.replace_section("References", "- New reference")
result = editor.save!(backup: true, validate_before: true)

# Build new document
builder = Ace::Support::Markdown::Molecules::DocumentBuilder.new
doc = builder
  .frontmatter({"id" => "task.001", "status" => "draft"})
  .title("My Task")
  .add_section(heading: "Description", content: "Task details here")
  .build

puts doc.to_markdown
```

## API Documentation

### DocumentEditor (Main API)

Fluent interface for editing markdown documents with frontmatter and sections.

```ruby
editor = DocumentEditor.new("path/to/file.md")

# Frontmatter operations
editor.update_frontmatter({"status" => "done", "priority" => "high"})
editor.set_field("estimate", "2h")

# Section operations
editor.replace_section("References", "New content")
editor.append_to_section("Acceptance Criteria", "- Additional criterion")
editor.delete_section("Implementation Notes")
editor.add_section("New Section", "Content here", level: 2)

# Save with safety features
result = editor.save!(
  backup: true,              # Create backup before writing
  validate_before: true,     # Validate before saving
  rules: {                   # Optional validation rules
    required_fields: ["id", "status"],
    enums: {"status" => ["pending", "done"]}
  }
)

# Result hash
result[:success]      # => true/false
result[:backup_path]  # => "/path/to/file.md.backup.20251018_162800"
result[:errors]       # => []

# Rollback if needed
editor.rollback if result[:errors].any?
```

### SafeFileWriter

Atomic file operations with backup and validation.

```ruby
# Basic write with backup
result = SafeFileWriter.write(
  "file.md",
  content,
  backup: true
)

# Write with custom validation
result = SafeFileWriter.write(
  "file.md",
  content,
  backup: true,
  validate: true,
  validator: ->(content) {
    # Return array of errors, or empty array if valid
    content.include?("required text") ? [] : ["Missing required text"]
  }
)

# Restore from backup
SafeFileWriter.restore_from_backup("file.md", backup_path)

# Cleanup old backups (keep last 5)
SafeFileWriter.cleanup_backups("file.md", keep: 5)
```

### DocumentBuilder

Programmatic document generation with fluent API.

```ruby
builder = DocumentBuilder.new

doc = builder
  .frontmatter({"id" => "task.001", "status" => "draft"})
  .set_field("priority", "high")
  .title("Task Title")
  .add_section(heading: "Description", content: "Details here", level: 2)
  .add_section(heading: "References", content: "- Ref 1", level: 2)
  .build

# Convert to markdown
markdown = doc.to_markdown

# Or build directly to string
markdown_str = builder.to_markdown

# Validate before building
validation = builder.validate
if validation[:valid]
  doc = builder.build
else
  puts "Errors: #{validation[:errors]}"
end
```

### FrontmatterEditor

Atomic frontmatter updates with nested key support.

```ruby
# Update multiple fields
updated_doc = FrontmatterEditor.update(document, {
  "status" => "done",
  "update.last-updated" => "today"  # Nested key with dot notation
})

# Update single field
updated_doc = FrontmatterEditor.update_field(document, "status", "done")

# Delete field
updated_doc = FrontmatterEditor.delete_field(document, "old_field")

# Special values
FrontmatterEditor.update(document, {
  "updated_at" => "today",     # Converts to YYYY-MM-DD
  "timestamp" => "now"          # Converts to YYYY-MM-DD HH:MM:SS
})
```

### SectionEditor

Section manipulation using exact string matching.

```ruby
# Replace section content
updated_doc = SectionEditor.replace_section(document, "References", new_content)

# Append to section
updated_doc = SectionEditor.append_to_section(document, "Acceptance Criteria", "- New item")

# Delete section
updated_doc = SectionEditor.delete_section(document, "Old Section")

# Insert section before another
new_section = Section.new(heading: "New Section", level: 2, content: "Content")
updated_doc = SectionEditor.insert_section_before(document, "References", new_section)

# Add section at end
updated_doc = SectionEditor.add_section(document, new_section)
```

### Models

Immutable document representations.

```ruby
# Parse from content
doc = MarkdownDocument.parse(markdown_content, file_path: "task.md")

# Parse with sections extracted
doc = MarkdownDocument.parse_with_sections(markdown_content)

# Access data
doc.frontmatter              # => {"id" => "task.001", ...}
doc.get_frontmatter("id")    # => "task.001"
doc.raw_body                 # => "# Title\n\nContent..."
doc.sections                 # => [Section, Section, ...]
doc.find_section("References")  # => Section or nil

# Immutable transformations
new_doc = doc.with_frontmatter({"status" => "done"})
new_doc = doc.with_body("New body content")
new_doc = doc.with_sections(new_sections_array)

# Statistics
doc.stats  # => {frontmatter_fields: 5, body_length: 1234, sections_count: 4, word_count: 250}

# Convert to markdown
markdown = doc.to_markdown
```

## Architecture

**ATOM Pattern:**
- **Atoms**: Pure functions (FrontmatterExtractor, SectionExtractor, FrontmatterSerializer, DocumentValidator)
- **Molecules**: Composed operations (FrontmatterEditor, SectionEditor, KramdownProcessor, DocumentBuilder)
- **Organisms**: Orchestration (DocumentEditor, SafeFileWriter)
- **Models**: Immutable data (MarkdownDocument, Section)

## Safety Guarantees

1. **Atomic Writes**: Uses temp file + atomic move (prevents partial writes)
2. **Automatic Backup**: Creates timestamped backups before modifications
3. **Validation**: Pre-write and post-write validation with rollback
4. **Immutable Models**: Transformations return new instances
5. **Error Handling**: Detailed error messages with rollback on failure

## Performance

- Frontmatter updates: <10ms
- Section edits: <50ms
- Large documents (10k lines): <200ms
- Benchmark: `ruby test/smoke_test.rb`

## Testing

```bash
ace-test ace-support-markdown                                   # Run full package test suite
ace-test ace-support-markdown/test/integration/readme_examples_test.rb  # Run README example tests only
```

Test coverage:
- 35+ tests
- 212+ assertions
- Corruption prevention tests
- Edge case validation
- Performance benchmarks

## Real-World Examples

### Example 1: Task Management System (from ace-taskflow)

**Scenario**: Auto-fixing task status when files are in wrong directory

```ruby
# Fix task status with automatic backup and validation
def fix_task_status(file_path, new_status)
  # Use DocumentEditor (Organism layer) for high-level file operations
  # This abstracts away the complexity of parsing, updating, and writing
  editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)
  editor.update_frontmatter("status" => new_status)

  # Always validate before save to catch errors early
  # Pre-flight validation is cheaper than rollback operations
  result = editor.save!(backup: true, validate_before: true)

  if result[:success]
    puts "✓ Updated status to '#{new_status}'"
    puts "  Backup created: #{result[:backup_path]}"
  else
    puts "✗ Failed: #{result[:errors].join(', ')}"
    # Rollback restores from the automatically-created backup
    # This ensures files are never left in a corrupted state
    editor.rollback
  end
end

# Usage
fix_task_status("tasks/042-implement-feature/task.042.md", "done")
```

**Output:**
```
✓ Updated status to 'done'
  Backup created: tasks/042-implement-feature/task.042.md.backup.20251023_143025_456
```

### Example 2: Documentation Updates (from ace-docs)

**Scenario**: Bulk update documentation with nested frontmatter and special values

```ruby
# Update documentation metadata across multiple files
def update_documentation_metadata(documents, updates)
  # Track results for batch operation visibility
  results = { success: 0, failed: 0, errors: [] }

  documents.each do |doc_path|
    begin
      editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(doc_path)

      # Use dot notation for nested YAML keys (e.g., "update.last-updated")
      # Special values like "today" are automatically converted to YYYY-MM-DD format
      processed_updates = {
        "update.last-updated" => "today",        # Converts to YYYY-MM-DD
        "update.frequency" => updates[:frequency],
        "metadata.version" => updates[:version]
      }

      editor.update_frontmatter(processed_updates)
      # Skip validation for batch operations to improve performance
      # We trust the input data and prefer speed over safety checks
      result = editor.save!(backup: true, validate_before: false)

      if result[:success]
        results[:success] += 1
      else
        results[:failed] += 1
        results[:errors] << { path: doc_path, errors: result[:errors] }
      end
    rescue StandardError => e
      # Catch any unexpected errors to prevent batch operation from failing completely
      # StandardError captures all runtime errors while allowing system signals through
      results[:failed] += 1
      results[:errors] << { path: doc_path, errors: [e.message] }
    end
  end

  results
end

# Usage
docs = Dir.glob("docs/**/*.md")
result = update_documentation_metadata(docs, frequency: "weekly", version: "1.0")
puts "Updated: #{result[:success]}, Failed: #{result[:failed]}"
```

### Example 3: Complex Multi-Section Operations

**Scenario**: Update task with multiple sections and frontmatter changes

```ruby
# Complete task update with validation
def complete_task_with_summary(task_path, completion_notes)
  # DocumentEditor supports fluent interface - chain multiple operations
  editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(task_path)

  # Update multiple frontmatter fields atomically
  # All changes are applied together to prevent partial updates
  editor.update_frontmatter({
    "status" => "done",
    "completed_at" => "today",
    "needs_review" => false
  })

  # Add new section with dynamic content
  # Level 2 (##) ensures proper hierarchy in document structure
  summary = <<~MARKDOWN
    **Status**: ✅ **COMPLETE** - #{Time.now.strftime('%Y-%m-%d')}

    ### What Was Delivered
    #{completion_notes}

    ### Validation
    - All tests passing
    - Code review approved
    - Documentation updated
  MARKDOWN

  editor.add_section("Task Completion Summary", summary, level: 2)

  # Append to existing section without replacing content
  # This preserves original acceptance criteria while adding completion status
  editor.append_to_section("Acceptance Criteria", "\n✅ All criteria met")

  # Custom validation rules ensure data integrity
  # Enums catch typos in status values before writing to disk
  result = editor.save!(
    backup: true,
    validate_before: true,
    rules: {
      required_fields: ["id", "status", "completed_at"],
      enums: { "status" => ["pending", "in-progress", "done"] }
    }
  )

  if result[:success]
    puts "✓ Task completed successfully"
    puts "  Backup: #{result[:backup_path]}"
  else
    puts "✗ Validation failed: #{result[:errors].join(', ')}"
    editor.rollback
  end
end

# Usage
completion_notes = <<~NOTES
- Implemented core feature with ATOM architecture
- Added 35 tests with 100% coverage
- Updated documentation and CHANGELOG
NOTES

complete_task_with_summary("tasks/079-feature/task.079.md", completion_notes)
```

### Example 4: Safe File Writing with Custom Validation

**Scenario**: Create new file with content validation

```ruby
# Create new task file with custom validation
def create_validated_task(task_number, title, template)
  file_path = "tasks/#{task_number}-#{title.downcase.gsub(/\s+/, '-')}/task.#{task_number}.md"

  # Build content from template using Ruby's sprintf-style interpolation
  # This ensures consistent formatting across all task files
  content = template % {
    task_id: "v.1.0+task.#{task_number}",
    title: title,
    created_at: Time.now.strftime('%Y-%m-%d')
  }

  # Custom validator as a lambda for domain-specific validation rules
  # Returns array of errors (empty array means valid)
  # This pattern allows flexible, project-specific validation logic
  validator = ->(content) {
    errors = []
    errors << "Missing '## Objective' section" unless content.include?("## Objective")
    errors << "Missing '## Acceptance Criteria' section" unless content.include?("## Acceptance Criteria")
    errors << "Task ID must match format" unless content.match?(/id: v\.\d+\.\d+\+task\.\d+/)
    errors
  }

  # SafeFileWriter for new file creation with validation
  # validate: true triggers the custom validator before writing
  result = Ace::Support::Markdown::Organisms::SafeFileWriter.write(
    file_path,
    content,
    backup: true,
    validate: true,
    validator: validator
  )

  if result[:success]
    puts "✓ Created: #{file_path}"
  else
    puts "✗ Validation failed: #{result[:errors].join(', ')}"
  end
end

# Usage
template = <<~TEMPLATE
---
id: %{task_id}
status: draft
created_at: %{created_at}
---

# %{title}

## Objective

[Task objective here]

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
TEMPLATE

create_validated_task("080", "Implement New Feature", template)
```

### Example 5: Error Handling and Recovery

**Scenario**: Robust error handling with rollback

```ruby
# Safe update with comprehensive error handling
def safe_update_with_recovery(file_path, updates)
  editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)
  original_backup = nil
  success_flag = false

  begin
    # Pre-flight validation catches issues before making any changes
    # Fail fast to avoid unnecessary work on invalid documents
    unless editor.valid?(rules: { required_fields: ["id", "status"] })
      return { success: false, error: "Document invalid before update" }
    end

    # Apply updates in memory (no disk writes yet)
    editor.update_frontmatter(updates)

    # Validate changes before committing to disk
    # This ensures updates don't violate business rules
    validation = editor.validate(rules: {
      required_fields: ["id", "status", "priority"],
      enums: { "status" => ["pending", "in-progress", "done"] }
    })

    unless validation[:valid]
      return {
        success: false,
        error: "Validation failed",
        errors: validation[:errors],
        warnings: validation[:warnings]
      }
    end

    # Atomic write with automatic backup creation
    result = editor.save!(backup: true, validate_before: true)

    if result[:success]
      original_backup = result[:backup_path]
      success_flag = true  # Mark operation as successful
      { success: true, backup: original_backup }
    else
      { success: false, error: "Save failed", errors: result[:errors] }
    end

  # Rescue specific errors first for targeted error handling
  # This allows appropriate responses based on error type
  rescue Ace::Support::Markdown::ValidationError => e
    { success: false, error: "Validation error: #{e.message}" }

  rescue Ace::Support::Markdown::FileOperationError => e
    { success: false, error: "File operation error: #{e.message}" }

  # Catch all other runtime errors as a safety net
  # StandardError captures application errors but not system signals (SIGINT, etc.)
  rescue StandardError => e
    { success: false, error: "Unexpected error: #{e.message}" }

  ensure
    # Rollback only if backup exists and operation didn't succeed
    # Using ensure guarantees cleanup even if control flow is interrupted
    editor.rollback if original_backup && !success_flag
  end
end

# Usage with retry logic
def update_with_retry(file_path, updates, max_retries: 3)
  max_retries.times do |attempt|
    result = safe_update_with_recovery(file_path, updates)

    if result[:success]
      puts "✓ Updated successfully (attempt #{attempt + 1})"
      return true
    else
      puts "✗ Attempt #{attempt + 1} failed: #{result[:error]}"
      sleep 0.1 * (attempt + 1)  # Exponential backoff
    end
  end

  puts "✗ All retry attempts failed"
  false
end

# Usage
updates = { "status" => "in-progress", "priority" => "high" }
update_with_retry("tasks/042-feature/task.042.md", updates)
```

### Example 6: Batch Operations with Progress Tracking

**Scenario**: Process multiple files with progress reporting

```ruby
# Batch update with progress tracking and error collection
def batch_update_tasks(task_files, updates)
  # Collect comprehensive metrics for batch operations
  # This allows post-processing analysis and retry strategies
  results = {
    total: task_files.length,
    succeeded: 0,
    failed: 0,
    errors: [],
    backups: []
  }

  task_files.each_with_index do |file_path, idx|
    progress = "#{idx + 1}/#{task_files.length}"

    begin
      editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)
      editor.update_frontmatter(updates)

      # Each file operation is independent - failures don't stop the batch
      # Backups protect against partial failures in the batch
      result = editor.save!(backup: true, validate_before: true)

      if result[:success]
        results[:succeeded] += 1
        # Track backups for potential cleanup or rollback of entire batch
        results[:backups] << result[:backup_path]
        puts "[#{progress}] ✓ #{File.basename(file_path)}"
      else
        results[:failed] += 1
        # Collect errors for analysis - don't halt batch on single failure
        results[:errors] << {
          file: file_path,
          errors: result[:errors]
        }
        puts "[#{progress}] ✗ #{File.basename(file_path)}: #{result[:errors].join(', ')}"
      end

    rescue StandardError => e
      # Isolate failures - one corrupt file doesn't fail entire batch
      # Continue processing remaining files for maximum throughput
      results[:failed] += 1
      results[:errors] << {
        file: file_path,
        errors: [e.message]
      }
      puts "[#{progress}] ✗ #{File.basename(file_path)}: #{e.message}"
    end
  end

  # Print summary
  puts "\n" + "=" * 60
  puts "BATCH UPDATE SUMMARY"
  puts "=" * 60
  puts "Total: #{results[:total]}"
  puts "Succeeded: #{results[:succeeded]} ✓"
  puts "Failed: #{results[:failed]} ✗"
  puts "\nBackups created: #{results[:backups].length}"

  if results[:errors].any?
    puts "\nErrors:"
    results[:errors].each do |error|
      puts "  - #{error[:file]}: #{error[:errors].join(', ')}"
    end
  end

  results
end

# Usage
task_files = Dir.glob("tasks/**/task.*.md")
updates = { "updated_at" => "today", "version" => "1.0" }
result = batch_update_tasks(task_files, updates)

# Cleanup old backups (keep last 5 for each file)
if result[:succeeded] > 0
  task_files.each do |file_path|
    Ace::Support::Markdown::Organisms::SafeFileWriter.cleanup_backups(file_path, keep: 5)
  end
  puts "\n✓ Cleaned up old backups (kept last 5 per file)"
end
```

**Output:**
```
[1/12] ✓ task.042.md
[2/12] ✓ task.043.md
[3/12] ✗ task.044.md: Missing required field: id
[4/12] ✓ task.045.md
...

============================================================
BATCH UPDATE SUMMARY
============================================================
Total: 12
Succeeded: 10 ✓
Failed: 2 ✗

Backups created: 10

Errors:
  - tasks/044-broken/task.044.md: Missing required field: id
  - tasks/051-invalid/task.051.md: YAML syntax error

✓ Cleaned up old backups (kept last 5 per file)
```

## Migration from Existing Code

**From ace-docs FrontmatterManager:**

```ruby
# Before
FrontmatterManager.update_document(document, {"status" => "done"})

# After
editor = DocumentEditor.new(document.path)
editor.update_frontmatter({"status" => "done"})
editor.save!(backup: true)
```

**From ace-taskflow DoctorFixer:**

```ruby
# Before
new_content = rebuild_content_with_frontmatter(frontmatter, body)
File.write(file_path, new_content)

# After
SafeFileWriter.write(file_path, new_content, backup: true, validate: true)
```

## Maintaining Documentation

To ensure README examples stay in sync with the API:

### Automated Validation

The test suite includes **README example validation** (`test/integration/readme_examples_test.rb`):

```bash
# Run all package tests including README examples
ace-test ace-support-markdown

# Run only README example tests
ace-test ace-support-markdown/test/integration/readme_examples_test.rb
```

These tests extract patterns from the README examples and verify they work against the actual API. If the API changes, the tests will fail, alerting you to update the documentation.

### When Making API Changes

1. **Update the implementation** in `lib/`
2. **Update relevant tests** in `test/`
3. **Update README examples** to reflect new API
4. **Run test suite** - README example tests will catch mismatches
5. **Update CHANGELOG.md** with the changes

### Adding New Examples

When adding examples to the README:

1. Add the example code to README.md
2. Add a corresponding test case in `test/integration/readme_examples_test.rb`
3. Ensure the test validates the example's behavior
4. Run the test suite to verify

This ensures all documentation examples remain executable and accurate as the gem evolves.

## Development

```bash
bundle install
ace-test ace-support-markdown
```

## Platform Support

This gem supports the following platforms:
- **macOS**: Apple Silicon (arm64-darwin) and Intel (x86_64-darwin)
- **Linux**: x86_64-linux
- **Ruby**: Generic ruby platform

**Ruby Version**: >= 3.2.0 (tested on 3.3 & 3.4)

If you encounter platform-specific bundle issues, the lockfile includes all common platforms. If you need additional platform support:

```bash
bundle lock --add-platform <your-platform>
```

## Contributing

This gem is part of the ACE (AI-assisted Coding Environment) meta-project.

Part of [ACE](../README.md) - Modular CLI toolkit for AI-assisted development.

## License

[MIT License](https://opensource.org/licenses/MIT)
