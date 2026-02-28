#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time codemod: migrate ideas from release archive locations to .ace-ideas/_archive/.
#
# Sources:
#   .ace-taskflow/_archive/v.*/ideas/
#   .ace-taskflow/v.0.9.0/ideas/_archive/
#
# Target: .ace-ideas/_archive/{month}/{week}/{folder}/
#
# Usage:
#   ruby migrate_release_archives.rb --dry-run   # preview without writing
#   ruby migrate_release_archives.rb             # execute migration

require "fileutils"
require "optparse"
require "yaml"
require "time"

dry_run = false
OptionParser.new do |opts|
  opts.banner = "Usage: migrate_release_archives.rb [--dry-run]"
  opts.on("--dry-run", "Print actions without modifying filesystem") { dry_run = true }
end.parse!

project_root = ENV["PROJECT_ROOT_PATH"] || File.expand_path("../../../../../..", __dir__)
$LOAD_PATH.unshift File.join(project_root, "ace-b36ts/lib")
$LOAD_PATH.unshift File.join(project_root, "ace-support-config/lib")
$LOAD_PATH.unshift File.join(project_root, "ace-support-core/lib")
require "ace/b36ts"

target_archive = File.join(project_root, ".ace-ideas/_archive")

# Collect source directories
source_dirs = []

# .ace-taskflow/_archive/v.*/ideas/
versioned_archives = Dir.glob(File.join(project_root, ".ace-taskflow/_archive/v.*/ideas"))
source_dirs.concat(versioned_archives)

# .ace-taskflow/v.0.9.0/ideas/_archive/
v090_archive = File.join(project_root, ".ace-taskflow/v.0.9.0/ideas/_archive")
source_dirs << v090_archive if Dir.exist?(v090_archive)

if source_dirs.empty?
  puts "No source directories found. Nothing to migrate."
  exit 0
end

puts dry_run ? "DRY RUN — no files will be moved\n\n" : "Executing migration...\n\n"
puts "Sources:"
source_dirs.each { |d| puts "  #{d}" }
puts "Target: #{target_archive}\n\n"

IDEA_FOLDER_RE = /\A[0-9a-z]{6}-/

def read_frontmatter_date(folder_path)
  spec_files = Dir.glob(File.join(folder_path, "*.idea.s.md"))
  return nil if spec_files.empty?

  content = File.read(spec_files.first)
  if content.start_with?("---")
    end_idx = content.index("---", 3)
    if end_idx
      frontmatter = YAML.safe_load(content[3..end_idx - 1]) rescue {}
      frontmatter ||= {}
      raw = frontmatter["completed_at"] || frontmatter["created_at"]
      if raw
        case raw
        when Time then return raw
        when DateTime then return raw.to_time
        else
          begin
            return Time.parse(raw.to_s)
          rescue ArgumentError
            nil
          end
        end
      end
    end
  end
  nil
end

# Try to parse date from legacy folder names like 2025-09-16-01-03-some-slug
def date_from_folder_name(name)
  if (m = name.match(/\A(\d{4})-(\d{2})-(\d{2})/))
    Time.utc(m[1].to_i, m[2].to_i, m[3].to_i) rescue nil
  end
end

def partition_for(time)
  result = Ace::B36ts.encode_split(time, levels: %i[month week])
  "#{result[:month]}/#{result[:week]}"
end

stats = { moved: 0, skipped: 0, errors: 0 }

source_dirs.each do |src_dir|
  next unless Dir.exist?(src_dir)

  Dir.entries(src_dir).sort.each do |name|
    next if name.start_with?(".")
    folder_path = File.join(src_dir, name)
    next unless File.directory?(folder_path)

    # Skip reflection/retro files or non-idea folders
    unless name.match?(IDEA_FOLDER_RE) || name.match?(/\A\d{4}-\d{2}-\d{2}/)
      puts "SKIP (non-idea): #{name}"
      next
    end

    archive_date = read_frontmatter_date(folder_path) ||
                   date_from_folder_name(name) ||
                   File.mtime(folder_path)

    partition = partition_for(archive_date)
    target_parent = File.join(target_archive, partition)
    target_path   = File.join(target_parent, name)

    if File.exist?(target_path)
      puts "SKIP (collision): #{partition}/#{name}"
      stats[:skipped] += 1
      next
    end

    if dry_run
      puts "MOVE: #{folder_path.sub(project_root + '/', '')}"
      puts "  ->  .ace-ideas/_archive/#{partition}/#{name}  (date: #{archive_date.strftime('%Y-%m-%d')})"
      stats[:moved] += 1
    else
      begin
        FileUtils.mkdir_p(target_parent)
        FileUtils.mv(folder_path, target_path)
        puts "moved: #{name} → #{partition}/"
        stats[:moved] += 1
      rescue => e
        puts "ERROR moving #{name}: #{e.message}"
        stats[:errors] += 1
      end
    end
  end
end

puts "\nSummary: #{stats[:moved]} moved, #{stats[:skipped]} skipped, #{stats[:errors]} errors."

if dry_run
  puts "\nRun without --dry-run to execute."
else
  puts "\nVerify with:"
  puts "  ace-idea list --in archive"
end
