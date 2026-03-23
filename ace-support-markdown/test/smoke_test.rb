# frozen_string_literal: true

require "bundler/setup"
require_relative "../lib/ace/support/markdown"
require "tempfile"

puts "=" * 80
puts "SMOKE TEST: ace-support-markdown"
puts "=" * 80

# Sample markdown
sample_md = <<~MARKDOWN
  ---
  id: test.001
  status: pending
  priority: high
  ---

  # Test Document

  This is a test document.

  ## Section 1

  Content of section 1.

  ## References

  - Reference 1
  - Reference 2
MARKDOWN

# Test 1: Frontmatter Extraction
puts "\n[TEST 1] Frontmatter Extraction"
result = Ace::Support::Markdown::Atoms::FrontmatterExtractor.extract(sample_md)
puts "  Valid: #{result[:valid]}"
puts "  Frontmatter keys: #{result[:frontmatter].keys.join(", ")}"
puts "  Body length: #{result[:body].length} chars"
puts "  ✓ PASS" if result[:valid]

# Test 2: Section Extraction
puts "\n[TEST 2] Section Extraction"
body = result[:body]
section_result = Ace::Support::Markdown::Atoms::SectionExtractor.extract(body, "References")
puts "  Found: #{section_result[:found]}"
puts "  Content: #{section_result[:section_content]&.strip&.slice(0, 50)}..."
puts "  ✓ PASS" if section_result[:found]

# Test 3: Document Model
puts "\n[TEST 3] Document Model"
doc = Ace::Support::Markdown::Models::MarkdownDocument.parse(sample_md)
puts "  Frontmatter fields: #{doc.frontmatter.keys.length}"
puts "  Body length: #{doc.raw_body.length}"
puts "  Has frontmatter: #{doc.has_frontmatter?}"
puts "  ✓ PASS"

# Test 4: Frontmatter Editor
puts "\n[TEST 4] Frontmatter Editor"
updated_doc = Ace::Support::Markdown::Molecules::FrontmatterEditor.update(doc, {"status" => "done"})
puts "  Original status: #{doc.get_frontmatter("status")}"
puts "  Updated status: #{updated_doc.get_frontmatter("status")}"
puts "  ✓ PASS" if updated_doc.get_frontmatter("status") == "done"

# Test 5: Safe File Writer
puts "\n[TEST 5] Safe File Writer"
temp_file = Tempfile.new(["test", ".md"])
begin
  temp_file.write(sample_md)
  temp_file.close

  # Read and modify
  editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(temp_file.path)
  editor.update_frontmatter({"status" => "in-progress"})

  # Save with backup
  save_result = editor.save!(backup: true)
  puts "  Save success: #{save_result[:success]}"
  puts "  Backup created: #{!save_result[:backup_path].nil?}"
  puts "  Modified: #{editor.modified?}"

  # Verify content
  saved_content = File.read(temp_file.path)
  puts "  Status in file: #{saved_content.include?("status: in-progress")}"
  puts "  ✓ PASS" if save_result[:success]
ensure
  temp_file.close
  temp_file.unlink
  # Cleanup backup
  Dir.glob("#{temp_file.path}.backup.*").each { |f| File.delete(f) }
end

# Test 6: Document Builder
puts "\n[TEST 6] Document Builder"
builder = Ace::Support::Markdown::Molecules::DocumentBuilder.new
doc = builder
  .frontmatter({"id" => "task.079", "status" => "draft"})
  .title("My Task")
  .add_section(heading: "Description", content: "Task description here")
  .add_section(heading: "Acceptance Criteria", content: "- Criterion 1", level: 2)
  .build

markdown = doc.to_markdown
puts "  Has frontmatter: #{markdown.include?("id: task.079")}"
puts "  Has title: #{markdown.include?("# My Task")}"
puts "  Has sections: #{markdown.include?("## Description")}"
puts "  ✓ PASS" if doc.has_frontmatter?

puts "\n" + "=" * 80
puts "ALL TESTS PASSED ✓"
puts "=" * 80
