#!/usr/bin/env ruby

# Convert XML template format from dual-attribute (path + template-path) to single-attribute (path only)
# This script removes the path attribute (target location) and keeps only template-path renamed to path

require 'fileutils'

def convert_template_attributes(content)
  # Pattern to match: <template path="target" template-path="source">
  # Replace with: <template path="source">
  
  content.gsub(/<template\s+path="[^"]*"\s+template-path="([^"]*)"/) do
    template_path = $1
    %(<template path="#{template_path}")
  end
end

def process_file(file_path)
  puts "Processing: #{file_path}"
  
  # Read the file
  content = File.read(file_path)
  
  # Convert template attributes
  updated_content = convert_template_attributes(content)
  
  # Check if changes were made
  if content != updated_content
    # Write back to file
    File.write(file_path, updated_content)
    puts "  ✅ Updated template attributes"
  else
    puts "  ℹ️  No template attributes found"
  end
end

# Get workflow files that contain template-path
workflow_files = `grep -l "template-path" #{ARGV[0] || '/Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-handbook/workflow-instructions'}/*.wf.md`.strip.split("\n")

if workflow_files.empty?
  puts "No workflow files with template-path found"
  exit 0
end

puts "Converting #{workflow_files.length} workflow files to single path attribute format:"
puts

workflow_files.each do |file|
  process_file(file)
end

puts
puts "Conversion complete!"