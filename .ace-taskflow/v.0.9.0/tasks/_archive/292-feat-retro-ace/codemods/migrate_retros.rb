#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time codemod: migrate retros from .ace-taskflow/v.0.9.0/retros/ to .ace-retros/
# Usage:
#   ruby migrate_retros.rb --dry-run   # preview without writing
#   ruby migrate_retros.rb             # execute migration

require "fileutils"
require "optparse"
require "time"
require "yaml"

dry_run = false
OptionParser.new do |opts|
  opts.banner = "Usage: migrate_retros.rb [--dry-run]"
  opts.on("--dry-run", "Print actions without modifying filesystem") { dry_run = true }
end.parse!

project_root = ENV["PROJECT_ROOT_PATH"] || File.expand_path("../../../../../..", __dir__)
source_dir   = File.join(project_root, ".ace-taskflow/v.0.9.0/retros")
target_dir   = File.join(project_root, ".ace-retros")

# Load ace-retro gem utilities
$LOAD_PATH.unshift(File.join(project_root, "ace-retro/lib"))
$LOAD_PATH.unshift(File.join(project_root, "ace-b36ts/lib"))
$LOAD_PATH.unshift(File.join(project_root, "ace-support-items/lib"))
$LOAD_PATH.unshift(File.join(project_root, "ace-support-core/lib"))
$LOAD_PATH.unshift(File.join(project_root, "ace-support-models/lib"))
$LOAD_PATH.unshift(File.join(project_root, "ace-support-markdown/lib"))

require "ace/b36ts"
require "ace/retro/atoms/retro_id_formatter"
require "ace/retro/atoms/retro_file_pattern"
require "ace/retro/atoms/retro_frontmatter_defaults"
require "ace/support/items/atoms/slug_sanitizer"
require "ace/support/items/atoms/title_extractor"

abort "Source directory not found: #{source_dir}" unless Dir.exist?(source_dir)

puts dry_run ? "DRY RUN — no files will be written\n\n" : "Executing migration...\n\n"

# --- Constants ---
B36TS_PATTERN = /\A[0-9][0-9a-z]{5}-/
ARCHIVED_DATE_PATTERN = /\A(\d{4})(\d{2})\d{2}-/
LEGACY_DATE_PATTERN = /\A(\d{4})-(\d{2})-/

# --- Counters ---
stats = { b36ts: 0, legacy: 0, archived: 0, skipped: 0, errors: 0 }

# --- Helpers ---

# Extract title from markdown content (first H1 heading)
def extract_title(content)
  Ace::Support::Items::Atoms::TitleExtractor.extract(content)
end

# Infer retro type from content
def infer_type(content)
  return "standard" if content.nil? || content.empty?

  # Check inline **Type** field first (most files have this)
  type_match = content.match(/\*\*Type\*\*:\s*(.+?)$/i)
  if type_match
    type_value = type_match[1].strip.downcase
    return "conversation-analysis" if type_value.include?("conversation")
    return "self-review" if type_value.include?("self-review") || type_value.include?("self review")

    return "standard"
  end

  # Fallback: detect from content structure
  if content.include?("## Conversation Analysis") || content.include?("## Key Decision Points")
    return "conversation-analysis"
  end
  if content.match?(/self[- ]review/i) || content.include?("## Self-Assessment")
    return "self-review"
  end

  "standard"
end

# Derive slug from filename (strip ID prefix, extension, clean up)
def derive_slug(filename, id_prefix: nil)
  slug = filename.dup
  # Remove extension(s)
  slug = slug.sub(/\.(rn\.md|retro\.md|md)$/, "")
  # Remove B36TS ID prefix if present
  slug = slug.sub(/\A#{Regexp.escape(id_prefix)}-/, "") if id_prefix
  # Remove date prefixes for legacy files
  slug = slug.sub(/\A\d{8}-\d{6}-/, "")   # 20250919-230746-
  slug = slug.sub(/\A\d{8}-/, "")          # 20250920-
  slug = slug.sub(/\A\d{4}-\d{2}-\d{2}-/, "") # 2025-09-21-
  slug = slug.sub(/\A\d{4}-\d{2}-/, "")   # 2025-01-
  # Sanitize to kebab-case
  Ace::Support::Items::Atoms::SlugSanitizer.sanitize(slug)
end

# Extract task reference from content if present
def extract_task_ref(content)
  match = content&.match(/task\s+v\.\d+\.\d+\+task\.(\d+(?:\.\d+)?)/i)
  match ? match[1] : nil
end

# Get created_at from git log for a file
def git_created_at(filepath, project_root)
  result = `git -C #{project_root} log --diff-filter=A --format='%aI' -- #{filepath} 2>/dev/null`.strip
  return nil if result.empty?

  Time.parse(result.split("\n").last)
rescue ArgumentError
  nil
end

# Extract date from filename patterns
def date_from_filename(filename)
  # 20250919-230746-...
  if (m = filename.match(/\A(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})-/))
    return Time.utc(m[1].to_i, m[2].to_i, m[3].to_i, m[4].to_i, m[5].to_i, m[6].to_i)
  end
  # 20250920-... (date only, no time)
  if (m = filename.match(/\A(\d{4})(\d{2})(\d{2})-/))
    return Time.utc(m[1].to_i, m[2].to_i, m[3].to_i)
  end
  # 2025-09-21-...
  if (m = filename.match(/\A(\d{4})-(\d{2})-(\d{2})-/))
    return Time.utc(m[1].to_i, m[2].to_i, m[3].to_i)
  end
  # 2025-01-...
  if (m = filename.match(/\A(\d{4})-(\d{2})-/))
    return Time.utc(m[1].to_i, m[2].to_i, 1)
  end
  nil
rescue ArgumentError
  nil
end

# Extract inline date from content
def date_from_content(content)
  match = content&.match(/\*\*Date\*\*:?\s*(\d{4}-\d{2}-\d{2})/)
  return Time.parse(match[1]) if match
  nil
rescue ArgumentError
  nil
end

# Migrate a single retro file
def migrate_retro(source_path, filename, target_base, project_root, dry_run:, stats:,
                  is_archived: false, legacy_id_offset: 0)
  content = File.read(source_path)
  relative_source = source_path.sub("#{project_root}/", "")

  # --- Classify ---
  is_b36ts = filename.match?(B36TS_PATTERN)

  if is_b36ts
    id = filename[0, 6]
    slug = derive_slug(filename, id_prefix: id)
    created_at = Ace::Retro::Atoms::RetroIdFormatter.decode_time(id) rescue nil
    source_tag = "taskflow:v.0.9.0"
    stats[:b36ts] += 1
  else
    # Generate new b36ts ID with offset to avoid collisions
    gen_time = Time.now.utc + legacy_id_offset
    id = Ace::Retro::Atoms::RetroIdFormatter.generate(gen_time)
    slug = derive_slug(filename)
    # Try multiple date sources
    created_at = date_from_filename(filename) || date_from_content(content) ||
                 git_created_at(source_path, project_root) || gen_time
    source_tag = "legacy"
    stats[:legacy] += 1
  end

  # Ensure slug is not empty
  slug = "retro" if slug.nil? || slug.empty?

  # --- Extract metadata from content ---
  title = extract_title(content) || slug.tr("-", " ").capitalize
  # Clean "Reflection: " prefix from title
  title = title.sub(/\AReflection:\s*/i, "").strip
  retro_type = infer_type(content)
  task_ref = extract_task_ref(content)
  status = is_archived ? "done" : "active"

  # --- Build target path ---
  folder_name = Ace::Retro::Atoms::RetroFilePattern.folder_name(id, slug)
  retro_filename = Ace::Retro::Atoms::RetroFilePattern.retro_filename(id, slug)

  if is_archived
    # Chronological sub-path: _archive/YYYY-MM/
    year_month = created_at.strftime("%Y-%m")
    folder_path = File.join(target_base, "_archive", year_month, folder_name)
  else
    folder_path = File.join(target_base, folder_name)
  end
  retro_path = File.join(folder_path, retro_filename)

  # --- Build frontmatter ---
  frontmatter = Ace::Retro::Atoms::RetroFrontmatterDefaults.build(
    id: id,
    title: title,
    type: retro_type,
    status: status,
    created_at: created_at,
    task_ref: task_ref
  )
  frontmatter["source"] = source_tag
  frontmatter["migrated_from"] = relative_source

  # --- Build output content ---
  # Prepend frontmatter to existing content
  fm_yaml = Ace::Retro::Atoms::RetroFrontmatterDefaults.serialize(frontmatter)
  output_content = "#{fm_yaml}\n#{content}"

  # --- Write or report ---
  if dry_run
    label = is_b36ts ? "B36TS" : "LEGACY"
    label = "ARCHIVED" if is_archived
    puts "[#{label}] #{filename}"
    puts "  ID: #{id} | Type: #{retro_type} | Status: #{status}"
    puts "  -> #{retro_path.sub("#{project_root}/", "")}"
    puts ""
  else
    FileUtils.mkdir_p(folder_path)
    File.write(retro_path, output_content)
    puts "migrated: #{filename} -> #{folder_name}/"
  end
end

# --- Main migration ---

FileUtils.mkdir_p(target_dir) unless dry_run

# Collect all source files
main_files = Dir.entries(source_dir)
  .reject { |e| e.start_with?(".") || e == "archived" }
  .select { |e| File.file?(File.join(source_dir, e)) }
  .sort

archived_dir = File.join(source_dir, "archived")
archived_files = if Dir.exist?(archived_dir)
  Dir.entries(archived_dir)
    .reject { |e| e.start_with?(".") }
    .select { |e| File.file?(File.join(archived_dir, e)) }
    .sort
else
  []
end

puts "Source: #{main_files.size} main files, #{archived_files.size} archived files\n\n"

# --- Migrate main files ---
legacy_offset = 0
main_files.each do |filename|
  source_path = File.join(source_dir, filename)
  is_legacy = !filename.match?(B36TS_PATTERN)
  offset = is_legacy ? (legacy_offset += 2) : 0

  migrate_retro(
    source_path, filename, target_dir, project_root,
    dry_run: dry_run, stats: stats, legacy_id_offset: offset
  )
rescue => e
  stats[:errors] += 1
  puts "ERROR: #{filename}: #{e.message}"
end

# --- Migrate archived files ---
puts "\n--- Archived files ---\n\n" unless archived_files.empty?

archived_files.each do |filename|
  source_path = File.join(archived_dir, filename)
  is_legacy = !filename.match?(B36TS_PATTERN)
  offset = is_legacy ? (legacy_offset += 2) : 0

  migrate_retro(
    source_path, filename, target_dir, project_root,
    dry_run: dry_run, stats: stats, is_archived: true, legacy_id_offset: offset
  )
  stats[:archived] += 1
rescue => e
  stats[:errors] += 1
  puts "ERROR (archived): #{filename}: #{e.message}"
end

# --- Summary ---
puts "\n--- Summary ---"
puts "B36TS retros:    #{stats[:b36ts]}"
puts "Legacy retros:   #{stats[:legacy]}"
puts "Archived retros: #{stats[:archived]}"
puts "Errors:          #{stats[:errors]}"

if dry_run
  puts "\nRun without --dry-run to execute."
else
  # Remove source files after successful migration
  if stats[:errors] == 0
    main_files.each { |f| File.delete(File.join(source_dir, f)) }
    archived_files.each { |f| File.delete(File.join(archived_dir, f)) }
    FileUtils.rmdir(archived_dir) if Dir.exist?(archived_dir) && Dir.empty?(archived_dir)
    puts "\nSource files removed."
  else
    puts "\nSource files NOT removed due to errors."
  end

  puts "\nVerify with:"
  puts "  ace-retro list"
  puts "  ace-retro list --in archive"
  puts "  ace-retro doctor"
end
