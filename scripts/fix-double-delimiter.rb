#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix double frontmatter delimiters (---\n---\n at start of files)

files_fixed = 0
files_checked = 0

Dir.glob(["docs/**/*.md", "**/handbook/workflow-instructions/**/*.md"]).each do |file|
  files_checked += 1
  content = File.read(file)

  # Check if file starts with double delimiter: ---\n---\n
  if content.start_with?("---\n---\n")
    puts "Fixing: #{file}"
    # Remove the first line (first ---)
    fixed_content = content.lines[1..].join
    File.write(file, fixed_content)
    files_fixed += 1
  end
end

puts "\nChecked #{files_checked} files, fixed #{files_fixed} files"
