#!/usr/bin/env ruby
# frozen_string_literal: true

# Migrate .claude/skills from flat ace_* to ace/* subfolder structure
#
# Usage:
#   ruby scripts/migrate-skills.rb --dry-run  # Preview changes
#   ruby scripts/migrate-skills.rb            # Execute migration

require 'fileutils'

DRY_RUN = ARGV.include?('--dry-run')
SKILLS_DIR = File.expand_path('../.claude/skills', __dir__)

$migrated = 0
$errors = []

def migrate_skill(old_dir, new_dir, old_name, new_name)
  old_basename = File.basename(old_dir)
  new_relpath = new_dir.sub(SKILLS_DIR + '/', '')

  puts "#{old_basename}/ → #{new_relpath}/"
  puts "  name: #{old_name} → #{new_name}"

  return if DRY_RUN

  # Create parent directory
  FileUtils.mkdir_p(File.dirname(new_dir))

  # Move directory
  FileUtils.mv(old_dir, new_dir)

  # Update SKILL.md name field
  skill_file = File.join(new_dir, 'SKILL.md')
  content = File.read(skill_file)
  content.sub!(/^name:\s*#{Regexp.escape(old_name)}/, "name: #{new_name}")
  File.write(skill_file, content)

  $migrated += 1
end

puts "=== Migrating ace_* skills ===\n\n"

# Process ace_* skills (derive path from SKILL.md name field)
Dir.glob(File.join(SKILLS_DIR, 'ace_*')).sort.each do |old_dir|
  skill_file = File.join(old_dir, 'SKILL.md')

  unless File.exist?(skill_file)
    $errors << "Missing SKILL.md: #{old_dir}"
    next
  end

  content = File.read(skill_file)
  old_name = content[/^name:\s*(.+)/, 1]&.strip

  unless old_name
    $errors << "Missing name field: #{skill_file}"
    next
  end

  # ace:timestamp → timestamp (path derived from name, not directory)
  new_name = old_name.sub(/^ace:/, '')
  new_dir = File.join(SKILLS_DIR, 'ace', new_name)

  migrate_skill(old_dir, new_dir, old_name, new_name)
end

puts "\n=== Migrating meta-* skills ===\n\n"

# Process meta-* skills
Dir.glob(File.join(SKILLS_DIR, 'meta-*')).sort.each do |old_dir|
  skill_file = File.join(old_dir, 'SKILL.md')

  unless File.exist?(skill_file)
    $errors << "Missing SKILL.md: #{old_dir}"
    next
  end

  dir_name = File.basename(old_dir)
  content = File.read(skill_file)
  old_name = content[/^name:\s*(.+)/, 1]&.strip

  # meta-manage-agents → meta/manage-agents
  new_name = dir_name.sub(/^meta-/, 'meta/')
  new_dir = File.join(SKILLS_DIR, 'ace', new_name)

  migrate_skill(old_dir, new_dir, old_name, new_name)
end

puts "\n=== Summary ==="
puts "Migrated: #{$migrated} skills"
puts "Errors: #{$errors.size}"
$errors.each { |e| puts "  - #{e}" }
puts "\n#{DRY_RUN ? 'DRY RUN - no changes made' : 'Migration complete!'}"
