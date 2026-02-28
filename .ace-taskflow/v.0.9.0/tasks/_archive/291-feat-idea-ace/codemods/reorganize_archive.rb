#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time codemod: reorganize flat .ace-ideas/_archive/ into B36TS month/week partitions.
#
# Before: .ace-ideas/_archive/8ppq7w-dark-mode/
# After:  .ace-ideas/_archive/8p/4/8ppq7w-dark-mode/
#
# Usage:
#   ruby reorganize_archive.rb --dry-run   # preview without writing
#   ruby reorganize_archive.rb             # execute migration

require "fileutils"
require "optparse"
require "yaml"
require "time"

dry_run = false
OptionParser.new do |opts|
  opts.banner = "Usage: reorganize_archive.rb [--dry-run]"
  opts.on("--dry-run", "Print actions without modifying filesystem") { dry_run = true }
end.parse!

# Bootstrap gem load path for ace-b36ts
project_root = ENV["PROJECT_ROOT_PATH"] || File.expand_path("../../../../../..", __dir__)
$LOAD_PATH.unshift File.join(project_root, "ace-b36ts/lib")
$LOAD_PATH.unshift File.join(project_root, "ace-support-config/lib")
$LOAD_PATH.unshift File.join(project_root, "ace-support-core/lib")
require "ace/b36ts"

archive_dir = File.join(project_root, ".ace-ideas/_archive")
abort "Archive directory not found: #{archive_dir}" unless Dir.exist?(archive_dir)

puts dry_run ? "DRY RUN — no files will be moved\n\n" : "Executing reorganization...\n\n"

IDEA_FOLDER_RE = /\A[0-9a-z]{6}-/

# Parse date from idea frontmatter file
def read_archive_date(folder_path)
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

# Compute partition path using ace-b36ts
def partition_for(time)
  result = Ace::B36ts.encode_split(time, levels: %i[month week])
  "#{result[:month]}/#{result[:week]}"
end

stats = { moved: 0, skipped: 0, errors: 0 }

Dir.entries(archive_dir).sort.each do |name|
  next if name.start_with?(".")
  folder_path = File.join(archive_dir, name)
  next unless File.directory?(folder_path)

  # Skip partition sub-directories (e.g. "8p", "4") — they are 1-2 chars
  unless name.match?(IDEA_FOLDER_RE)
    puts "SKIP (not a flat idea folder): #{name}"
    next
  end

  archive_date = read_archive_date(folder_path) || File.mtime(folder_path)
  partition = partition_for(archive_date)

  target_parent = File.join(archive_dir, partition)
  target_path   = File.join(target_parent, name)

  if File.exist?(target_path)
    puts "SKIP (already exists): #{partition}/#{name}"
    stats[:skipped] += 1
    next
  end

  if dry_run
    puts "MOVE: _archive/#{name}"
    puts "  ->  _archive/#{partition}/#{name}  (date: #{archive_date.strftime('%Y-%m-%d')})"
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
  stats[:moved] += 1 if dry_run
end

puts "\nSummary: #{stats[:moved]} to move, #{stats[:skipped]} skipped, #{stats[:errors]} errors."

if dry_run
  puts "\nRun without --dry-run to execute."
else
  puts "\nVerify with:"
  puts "  ace-idea list --in archive"
end
