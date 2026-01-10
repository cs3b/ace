#!/usr/bin/env ruby
# Update skill frontmatter to add required 'name' field
# Usage: ruby scripts/update-skill-frontmatter.rb [--dry-run]

SKILLS_DIR = '.claude/skills'
DRY_RUN = ARGV.include?('--dry-run')

puts "DRY RUN MODE - no changes will be made" if DRY_RUN
puts "Updating skill frontmatter..."
puts

# Find all SKILL.md files
Dir.glob("#{SKILLS_DIR}/**/SKILL.md").sort.each do |file|
  # Extract skill name from directory path
  dir_parts = File.dirname(file).sub("#{SKILLS_DIR}/", '').split('/')
  skill_name = dir_parts.last

  # Read file content
  content = File.read(file)

  # Check if it starts with frontmatter
  unless content.start_with?('---')
    puts "SKIP: #{file} (no frontmatter)"
    next
  end

  # Check if name field already exists
  if content =~ /^name:\s*\S/m
    puts "SKIP: #{file} (name field already exists)"
    next
  end

  # Find where to insert name field (after first ---)
  new_content = content.sub(/^---\n/) do |match|
    "---\nname: #{skill_name}\n"
  end

  if new_content == content
    puts "SKIP: #{file} (no changes)"
    next
  end

  puts "UPDATE: #{file}"
  puts "  - added name: #{skill_name}"

  next if DRY_RUN

  File.write(file, new_content)
end

puts
puts "Update complete!"
puts "Re-run without --dry-run to apply changes" if DRY_RUN
