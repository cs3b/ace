# ace-support-markdown

Safe markdown editing with frontmatter support for ACE gems. Provides zero-corruption document operations through atomic writes, backup/rollback mechanisms, and Kramdown AST-based section editing.

## Features

- ✅ **Zero Corruption**: Atomic file operations with backup and rollback
- ✅ **Frontmatter Editing**: Safe YAML frontmatter updates with validation
- ✅ **Section Editing**: Kramdown AST-based section manipulation (exact string matching)
- ✅ **Document Building**: Fluent API for programmatic document generation
- ✅ **Immutable Models**: Functional transformations prevent accidental mutations
- ✅ **Performance**: <10ms frontmatter updates, <50ms section edits
- ✅ **ATOM Architecture**: Testable, composable, maintainable

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
result = editor.save!(backup: true, validate: true)

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
bundle exec rake test    # Run full test suite
```

Test coverage:
- 35+ tests
- 212+ assertions
- Corruption prevention tests
- Edge case validation
- Performance benchmarks

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

## Development

```bash
bundle install
bundle exec rake test
```

## Contributing

This gem is part of the ACE (AI-assisted Coding Environment) meta-project.

## License

[MIT License](https://opensource.org/licenses/MIT)
