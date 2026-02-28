#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time codemod: migrate ideas from .ace-taskflow/v.0.9.0/ideas/ to .ace-ideas/
# Usage:
#   ruby migrate_ideas.rb --dry-run   # preview without writing
#   ruby migrate_ideas.rb             # execute migration

require "fileutils"
require "optparse"

dry_run = false
OptionParser.new do |opts|
  opts.banner = "Usage: migrate_ideas.rb [--dry-run]"
  opts.on("--dry-run", "Print actions without modifying filesystem") { dry_run = true }
end.parse!

project_root = ENV["PROJECT_ROOT_PATH"] || File.expand_path("../../../../../..", __dir__)
source_dir   = File.join(project_root, ".ace-taskflow/v.0.9.0/ideas")
target_dir   = File.join(project_root, ".ace-ideas")

abort "Source directory not found: #{source_dir}" unless Dir.exist?(source_dir)

puts dry_run ? "DRY RUN — no files will be moved\n\n" : "Executing migration...\n\n"

# Helper: move a directory (or print if dry-run)
def move_dir(src, dst, dry_run:)
  if dry_run
    puts "MOVE: #{src}"
    puts "  ->  #{dst}"
  else
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.mv(src, dst)
    puts "moved: #{File.basename(src)}"
  end
end

# Ensure target exists
unless dry_run
  FileUtils.mkdir_p(target_dir)
end

entries = Dir.entries(source_dir).reject { |e| e.start_with?(".") || e == "maybe" }.sort

entries.each do |name|
  src = File.join(source_dir, name)
  next unless File.directory?(src)

  dst = File.join(target_dir, name)

  if File.exist?(dst) && !dry_run
    puts "SKIP (already exists at target): #{name}"
    next
  end

  unless name.match?(/\A(_archive|_maybe|_anytime|_next|[0-9a-z]{5,}-)/) || name.match?(/\A\d{7}/)
    puts "WARNING: legacy-named item '#{name}' — moving anyway (won't appear in ace-idea list)"
  end

  move_dir(src, dst, dry_run: dry_run)
end

# Handle maybe/ → merge into _maybe/
maybe_src = File.join(source_dir, "maybe")
if Dir.exist?(maybe_src)
  puts "\nNormalizing maybe/ → _maybe/ ..."
  maybe_target = File.join(target_dir, "_maybe")
  FileUtils.mkdir_p(maybe_target) unless dry_run

  Dir.entries(maybe_src).reject { |e| e.start_with?(".") }.sort.each do |name|
    src = File.join(maybe_src, name)
    dst = File.join(maybe_target, name)

    if File.exist?(dst)
      puts "  SKIP (collision): #{name} already exists in _maybe/"
      next
    end

    if dry_run
      puts "  MOVE: #{src}"
      puts "    ->  #{dst}"
    else
      FileUtils.mv(src, dst)
      puts "  moved: #{name} → _maybe/"
    end
  end

  unless dry_run
    # Remove now-empty maybe/
    remaining = Dir.entries(maybe_src).reject { |e| e.start_with?(".") }
    if remaining.empty?
      FileUtils.rmdir(maybe_src)
      puts "  removed empty: maybe/"
    else
      puts "  WARNING: maybe/ not empty after merge, leaving in place: #{remaining.join(', ')}"
    end
  end
end

puts "\nDone."

if dry_run
  puts "\nRun without --dry-run to execute."
else
  puts "\nVerify with:"
  puts "  ace-idea list"
  puts "  ace-idea list --in archive"
  puts "  ace-idea list --in maybe"
end
