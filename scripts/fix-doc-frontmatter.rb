#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to fix document frontmatter with proper doc-type, purpose, and git-based dates
# Usage: ruby scripts/fix-doc-frontmatter.rb [--dry-run]

$LOAD_PATH.unshift(File.expand_path("../ace-docs/lib", __dir__))
require "ace/docs/organisms/document_registry"
require "ace/docs/atoms/frontmatter_parser"
require "yaml"
require "date"

# Parse command line options
DRY_RUN = ARGV.include?("--dry-run")

puts "=" * 80
puts "Fix Document Frontmatter Script"
puts "Mode: #{DRY_RUN ? 'DRY RUN (no changes)' : 'LIVE (will update files)'}"
puts "=" * 80
puts

# Initialize document registry
registry = Ace::Docs::Organisms::DocumentRegistry.new
documents = registry.all

puts "Found #{documents.size} managed documents\n\n"

# Track statistics
stats = {
  total: documents.size,
  skipped: 0,
  updated: 0,
  errors: 0
}

# Helper function to get git last modified date
def get_git_date(file_path)
  result = `git log -1 --format="%cs" -- "#{file_path}" 2>/dev/null`.strip
  result.empty? ? Date.today.strftime("%Y-%m-%d") : result
end

# Helper function to infer doc-type from file path
def infer_doc_type(path)
  basename = File.basename(path)

  case basename
  when /\.wf\.md$/
    "workflow"
  when /\.g\.md$/
    "guide"
  when /\.template\.md$/
    "template"
  when /\.api\.md$/
    "api"
  else
    # Check path patterns
    if path.include?("/docs/") && !path.include?("/api/")
      "context"
    elsif path.include?("/api/") || path.include?("/api-docs/")
      "api"
    elsif path.include?("/templates/")
      "template"
    elsif path.include?("/guides/")
      "guide"
    elsif path.include?("/workflow-instructions/")
      "workflow"
    else
      "document"
    end
  end
end

# Helper function to infer purpose from content or frontmatter
def infer_purpose(document, content)
  # Try existing frontmatter fields
  if document.frontmatter["name"]
    return "#{document.frontmatter['name']} workflow instruction" if document.frontmatter["name"]
  end

  if document.frontmatter["description"]
    return document.frontmatter["description"]
  end

  # Try to extract from first H1 heading
  if content =~ /^#\s+(.+)$/
    heading = $1.strip
    return heading unless heading.empty?
  end

  # Fallback to filename-based
  filename = File.basename(document.path, ".*")
  "#{filename.gsub(/[-_]/, ' ').capitalize} documentation"
end

# Helper function to get update frequency based on doc-type
def get_update_frequency(doc_type)
  case doc_type
  when "workflow", "api"
    "on-change"
  when "context"
    "weekly"
  when "guide"
    "monthly"
  else
    "on-change"
  end
end

# Helper function to update document frontmatter
def update_document_frontmatter(document, updates, dry_run)
  path = document.path
  content = File.read(path)

  # Parse existing frontmatter
  parsed = Ace::Docs::Atoms::FrontmatterParser.parse(content)
  frontmatter = parsed[:frontmatter] || {}
  body_content = parsed[:content] || content

  # Merge updates (preserve existing fields)
  updated_frontmatter = frontmatter.merge(updates) do |key, old_val, new_val|
    # Keep old value for these fields unless they're nil
    if ["name", "description", "parameters", "allowed-tools", "argument-hint"].include?(key)
      old_val || new_val
    else
      # For nested hashes (like "update"), deep merge
      if old_val.is_a?(Hash) && new_val.is_a?(Hash)
        old_val.merge(new_val)
      else
        new_val
      end
    end
  end

  # Format as YAML
  yaml_content = updated_frontmatter.to_yaml.strip
  new_content = [
    "---",
    yaml_content,
    "---",
    "",
    body_content.strip
  ].join("\n") + "\n"

  if dry_run
    puts "  [DRY RUN] Would update frontmatter"
    return true
  else
    File.write(path, new_content)
    return true
  end
rescue => e
  puts "  ERROR: #{e.message}"
  return false
end

# Process each document
documents.each_with_index do |doc, index|
  puts "[#{index + 1}/#{documents.size}] Processing: #{doc.path}"

  # Check if document already has complete frontmatter
  has_doc_type = !doc.doc_type.nil? && !doc.doc_type.empty?
  has_purpose = !doc.purpose.nil? && !doc.purpose.empty?
  has_last_updated = doc.last_updated != nil

  if has_doc_type && has_purpose && has_last_updated
    puts "  ✓ Already complete (doc-type: #{doc.doc_type}, has date)"
    stats[:skipped] += 1
    next
  end

  # Read content for inference
  content = File.read(doc.path)

  # Prepare updates
  updates = {}

  # Add doc-type if missing
  if !has_doc_type
    inferred_type = infer_doc_type(doc.path)
    updates["doc-type"] = inferred_type
    puts "  → Adding doc-type: #{inferred_type}"
  end

  # Add purpose if missing
  if !has_purpose
    inferred_purpose = infer_purpose(doc, content)
    updates["purpose"] = inferred_purpose
    puts "  → Adding purpose: #{inferred_purpose[0..60]}#{'...' if inferred_purpose.length > 60}"
  end

  # Add/update dates
  git_date = get_git_date(doc.path)
  doc_type = doc.doc_type || updates["doc-type"]
  frequency = get_update_frequency(doc_type)

  updates["update"] = {
    "frequency" => frequency,
    "last-updated" => git_date
  }

  # Merge with existing update config if present
  if doc.update_config && !doc.update_config.empty?
    updates["update"] = doc.update_config.merge(updates["update"])
  end

  puts "  → Setting update frequency: #{frequency}"
  puts "  → Setting last-updated: #{git_date} (from git)"

  # Update the document
  if update_document_frontmatter(doc, updates, DRY_RUN)
    stats[:updated] += 1
    puts "  ✓ #{DRY_RUN ? 'Would be updated' : 'Updated successfully'}"
  else
    stats[:errors] += 1
    puts "  ✗ Failed to update"
  end

  puts
end

# Print summary
puts "=" * 80
puts "Summary"
puts "=" * 80
puts "Total documents:     #{stats[:total]}"
puts "Already complete:    #{stats[:skipped]}"
puts "#{DRY_RUN ? 'Would update' : 'Updated'}:        #{stats[:updated]}"
puts "Errors:              #{stats[:errors]}"
puts "=" * 80

if DRY_RUN
  puts "\nRun without --dry-run to apply changes"
else
  puts "\nChanges applied! Run 'ace-docs status' to verify"
end
