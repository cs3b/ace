#!/usr/bin/env ruby
# Research script to understand Kramdown AST structure

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'kramdown', '~> 2.4'
  gem 'kramdown-parser-gfm', '~> 1.1'
end

require 'kramdown'
require 'kramdown-parser-gfm'

# Sample markdown with frontmatter and sections
sample_markdown = <<~MARKDOWN
  ---
  id: v.0.9.0+task.079
  status: pending
  priority: high
  ---

  # Main Title

  Introduction paragraph.

  ## Section 1

  Content of section 1.

  ### Subsection 1.1

  Content of subsection 1.1.

  ## Section 2

  Content of section 2.

  ## References

  - Reference 1
  - Reference 2
MARKDOWN

puts "=" * 80
puts "KRAMDOWN AST RESEARCH"
puts "=" * 80

# Parse the document
doc = Kramdown::Document.new(sample_markdown, input: 'GFM')

# Helper to print AST structure
def print_ast(element, indent = 0)
  prefix = "  " * indent
  puts "#{prefix}#{element.type} (level: #{element.options[:level] if element.type == :header})"

  if element.type == :header
    # Extract header text
    text_elements = element.children.select { |c| c.type == :text }
    puts "#{prefix}  TEXT: #{text_elements.map(&:value).join}"
  elsif element.type == :text
    puts "#{prefix}  VALUE: #{element.value.inspect}"
  end

  element.children.each { |child| print_ast(child, indent + 1) }
end

puts "\nAST Structure:"
puts "-" * 80
print_ast(doc.root)

puts "\n" + "=" * 80
puts "EXTRACTING HEADERS"
puts "=" * 80

# Function to extract all headers
def extract_headers(root)
  headers = []

  traverse = lambda do |element|
    if element.type == :header
      text = element.children
                   .select { |c| c.type == :text }
                   .map(&:value)
                   .join
      headers << { level: element.options[:level], text: text, element: element }
    end
    element.children.each { |child| traverse.call(child) }
  end

  traverse.call(root)
  headers
end

headers = extract_headers(doc.root)
headers.each do |h|
  puts "#{'#' * h[:level]} #{h[:text]} (level #{h[:level]})"
end

puts "\n" + "=" * 80
puts "EXTRACTING SECTION CONTENT"
puts "=" * 80

# Extract content between two headers
def extract_section_content(root, target_header_text)
  elements = root.children

  # Find the target header
  target_index = elements.find_index do |el|
    el.type == :header &&
    el.children.any? { |c| c.type == :text && c.value == target_header_text }
  end

  return nil unless target_index

  target_header = elements[target_index]
  target_level = target_header.options[:level]

  # Collect elements after header until next same-or-higher level header
  content_elements = []
  (target_index + 1...elements.length).each do |i|
    el = elements[i]

    # Stop if we hit another header of same or higher level
    if el.type == :header && el.options[:level] <= target_level
      break
    end

    content_elements << el
  end

  # Convert elements back to markdown
  # Create a proper document with encoding options
  temp_doc = Kramdown::Document.new('')
  temp_root = temp_doc.root
  temp_root.options[:encoding] = 'UTF-8'
  content_elements.each { |el| temp_root.children << el }

  temp_doc.to_kramdown
end

puts "\nExtracting 'Section 1':"
section1_content = extract_section_content(doc.root, "Section 1")
puts section1_content

puts "\nExtracting 'References':"
refs_content = extract_section_content(doc.root, "References")
puts refs_content

puts "\n" + "=" * 80
puts "FRONTMATTER HANDLING"
puts "=" * 80

# Note: Kramdown doesn't parse frontmatter by default
# We need to extract it manually before parsing
puts "Kramdown does NOT parse YAML frontmatter automatically."
puts "We need to extract frontmatter before parsing the body."

# Extract frontmatter manually
def extract_frontmatter(content)
  if content.start_with?("---\n")
    parts = content.split(/^---\s*$/, 3)
    if parts.length >= 3
      frontmatter = parts[1].strip
      body = parts[2].strip
      return { frontmatter: frontmatter, body: body }
    end
  end
  { frontmatter: nil, body: content }
end

extracted = extract_frontmatter(sample_markdown)
puts "\nFrontmatter:"
puts extracted[:frontmatter]
puts "\nBody (first 100 chars):"
puts extracted[:body][0..100]
