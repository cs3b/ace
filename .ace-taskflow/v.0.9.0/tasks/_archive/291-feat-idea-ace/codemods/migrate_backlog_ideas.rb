#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time codemod: migrate ideas from .ace-taskflow/_backlog/ideas/ to .ace-ideas/.
#
# Routing rules:
#   - B36TS idea, status done/obsolete OR created_at > 60 days ago → .ace-ideas/_archive/{month}/{week}/
#   - B36TS idea, recent (≤60 days, status: pending/active) → .ace-ideas/ root
#   - From _maybe/ subfolder → .ace-ideas/_maybe/
#   - Legacy (no B36TS ID) → .ace-ideas/_archive/{month}/{week}/ using file mtime
#   - _anyday/ items → .ace-ideas/ root if recent, else _archive
#
# Usage:
#   ruby migrate_backlog_ideas.rb --dry-run   # preview without writing
#   ruby migrate_backlog_ideas.rb             # execute migration

require "fileutils"
require "optparse"
require "yaml"
require "time"

dry_run = false
OptionParser.new do |opts|
  opts.banner = "Usage: migrate_backlog_ideas.rb [--dry-run]"
  opts.on("--dry-run", "Print actions without modifying filesystem") { dry_run = true }
end.parse!

project_root = ENV["PROJECT_ROOT_PATH"] || File.expand_path("../../../../../..", __dir__)
$LOAD_PATH.unshift File.join(project_root, "ace-b36ts/lib")
$LOAD_PATH.unshift File.join(project_root, "ace-support-config/lib")
$LOAD_PATH.unshift File.join(project_root, "ace-support-core/lib")
require "ace/b36ts"

backlog_ideas_dir = File.join(project_root, ".ace-taskflow/_backlog/ideas")
unless Dir.exist?(backlog_ideas_dir)
  puts "Backlog ideas directory not found: #{backlog_ideas_dir}"
  exit 0
end

target_root    = File.join(project_root, ".ace-ideas")
target_maybe   = File.join(target_root, "_maybe")
target_archive = File.join(target_root, "_archive")

puts dry_run ? "DRY RUN — no files will be moved\n\n" : "Executing migration...\n\n"

B36TS_IDEA_RE = /\A[0-9a-z]{6}-/
ARCHIVE_STATUSES = %w[done obsolete archived].freeze
CUTOFF_DAYS = 60

def read_frontmatter(folder_path)
  spec_files = Dir.glob(File.join(folder_path, "*.idea.s.md"))
  return {} if spec_files.empty?

  content = File.read(spec_files.first)
  if content.start_with?("---")
    end_idx = content.index("---", 3)
    if end_idx
      return YAML.safe_load(content[3..end_idx - 1]) || {} rescue {}
    end
  end
  {}
end

def parse_time(raw)
  case raw
  when Time then raw
  when DateTime then raw.to_time
  else Time.parse(raw.to_s) rescue nil
  end
end

def partition_for(time)
  result = Ace::B36ts.encode_split(time, levels: %i[month week])
  "#{result[:month]}/#{result[:week]}"
end

def move_item(src, dst_dir, name, dry_run:, label:)
  dst = File.join(dst_dir, name)
  if File.exist?(dst)
    puts "  SKIP (collision): #{name} already at #{dst_dir}"
    return :skipped
  end
  if dry_run
    puts "  MOVE: #{src}"
    puts "    ->  #{dst}  [#{label}]"
    :moved
  else
    begin
      FileUtils.mkdir_p(dst_dir)
      FileUtils.mv(src, dst)
      puts "  moved: #{name} → #{label}"
      :moved
    rescue => e
      puts "  ERROR: #{e.message}"
      :error
    end
  end
end

stats = { moved: 0, skipped: 0, errors: 0, archived: 0, active: 0, maybe: 0 }
now = Time.now

# Helper: scan a source directory and route each idea
def scan_and_route(src_dir, subfolder_hint: nil, dry_run:, stats:, now:,
                   target_root:, target_maybe:, target_archive:)
  Dir.entries(src_dir).sort.each do |name|
    next if name.start_with?(".")
    folder_path = File.join(src_dir, name)
    next unless File.directory?(folder_path)

    # Recurse into known special subdirs (_maybe, _anyday) at top level
    if name == "_maybe" && subfolder_hint.nil?
      puts "\n[_maybe/]"
      scan_and_route(folder_path, subfolder_hint: :maybe, dry_run: dry_run,
                     stats: stats, now: now, target_root: target_root,
                     target_maybe: target_maybe, target_archive: target_archive)
      next
    end
    if name == "_anyday" && subfolder_hint.nil?
      puts "\n[_anyday/]"
      scan_and_route(folder_path, subfolder_hint: :anyday, dry_run: dry_run,
                     stats: stats, now: now, target_root: target_root,
                     target_maybe: target_maybe, target_archive: target_archive)
      next
    end

    frontmatter = read_frontmatter(folder_path)
    status      = frontmatter["status"].to_s.downcase
    raw_date    = frontmatter["completed_at"] || frontmatter["created_at"]
    item_time   = (parse_time(raw_date) if raw_date) || File.mtime(folder_path)
    age_days    = (now - item_time) / 86_400
    b36ts_idea  = name.match?(B36TS_IDEA_RE)

    # Determine destination
    if subfolder_hint == :maybe
      dst_dir = target_maybe
      label   = "_maybe/"
      result  = move_item(folder_path, dst_dir, name, dry_run: dry_run, label: label)
      stats[:maybe] += 1 if result == :moved
    elsif !b36ts_idea ||
          ARCHIVE_STATUSES.include?(status) ||
          age_days > CUTOFF_DAYS
      archive_date = item_time
      partition    = partition_for(archive_date)
      dst_dir      = File.join(target_archive, partition)
      label        = "_archive/#{partition}/"
      result       = move_item(folder_path, dst_dir, name, dry_run: dry_run, label: label)
      stats[:archived] += 1 if result == :moved
    else
      # Recent + pending/active B36TS idea → root (or _anyday root)
      dst_dir = target_root
      label   = ".ace-ideas/ (root)"
      result  = move_item(folder_path, dst_dir, name, dry_run: dry_run, label: label)
      stats[:active] += 1 if result == :moved
    end

    case result
    when :moved   then stats[:moved] += 1
    when :skipped then stats[:skipped] += 1
    when :error   then stats[:errors] += 1
    end
  end
end

scan_and_route(
  backlog_ideas_dir,
  dry_run: dry_run,
  stats: stats,
  now: now,
  target_root: target_root,
  target_maybe: target_maybe,
  target_archive: target_archive
)

puts "\nSummary: #{stats[:moved]} moved (#{stats[:archived]} archived, #{stats[:active]} active, #{stats[:maybe]} maybe), #{stats[:skipped]} skipped, #{stats[:errors]} errors."

if dry_run
  puts "\nRun without --dry-run to execute."
else
  puts "\nVerify with:"
  puts "  ace-idea list"
  puts "  ace-idea list --in archive"
  puts "  ace-idea list --in maybe"
end
