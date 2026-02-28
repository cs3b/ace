#!/usr/bin/env ruby
# frozen_string_literal: true

# Codemod: classify_and_move_ideas.rb
#
# Classifies active ideas in .ace-ideas/ by source, adds a `source:` frontmatter
# field, and moves non-v.0.9.0 ideas to .ace-ideas/_maybe/.
#
# Also migrates remaining loose idea files from .ace-taskflow/_backlog/ideas/
# to .ace-ideas/_maybe/ with source: "backlog".
#
# Source field values:
#   "taskflow:v.0.9.0" — came from .ace-taskflow/v.0.9.0/ideas/ via migration
#   "user"             — created by user after migration (newer B36TS ideas)
#   "legacy"           — non-B36TS named folder (pre-B36TS era)
#   "backlog"          — was in .ace-taskflow/_backlog/ideas/
#
# Usage:
#   ruby classify_and_move_ideas.rb --dry-run   # preview without writing
#   ruby classify_and_move_ideas.rb             # execute

require "fileutils"
require "optparse"

dry_run = false
OptionParser.new do |opts|
  opts.banner = "Usage: classify_and_move_ideas.rb [--dry-run]"
  opts.on("--dry-run", "Print actions without modifying filesystem") { dry_run = true }
end.parse!

PROJECT_ROOT = ENV["PROJECT_ROOT_PATH"] || File.expand_path("../../../../../..", __dir__)
IDEAS_ROOT   = File.join(PROJECT_ROOT, ".ace-ideas")
MAYBE_DIR    = File.join(IDEAS_ROOT, "_maybe")
BACKLOG_DIR  = File.join(PROJECT_ROOT, ".ace-taskflow/_backlog/ideas")

MIGRATION_COMMITS = %w[cc9449150 9773a977d].freeze
# B36TS IDs are exactly 6 base36 chars followed by a hyphen, and always start
# with a digit (timestamp-encoded).  This rules out:
#   - legacy word names like "output-", "preset-", "review-" (start with letter)
#   - legacy date prefixes like "2025111-" (7 chars before hyphen)
B36TS_PATTERN = /\A[0-9][0-9a-z]{5}-/

puts dry_run ? "DRY RUN — no files will be modified\n\n" : "Executing...\n\n"

# ---------------------------------------------------------------------------
# Frontmatter helpers
# ---------------------------------------------------------------------------

def parse_frontmatter(content)
  return [nil, content] unless content.start_with?("---")

  # Find the closing ---
  rest = content[3..]
  close_idx = rest.index(/^---\s*$/)
  return [nil, content] if close_idx.nil?

  fm_text = rest[0, close_idx]
  body    = rest[(close_idx + 3)..]
  [fm_text, body]
end

def add_or_update_source(content, source_value)
  fm_text, body = parse_frontmatter(content)

  if fm_text.nil?
    # No frontmatter — prepend one
    return "---\nsource: \"#{source_value}\"\n---\n#{content}"
  end

  if fm_text.match?(/^source:/)
    # Replace existing source field
    new_fm = fm_text.gsub(/^source:.*$/, "source: \"#{source_value}\"")
  else
    # Append source field before closing ---
    new_fm = fm_text.rstrip + "\nsource: \"#{source_value}\"\n"
  end

  "---\n#{new_fm}---\n#{body}"
end

def update_frontmatter(file_path, source:, dry_run:)
  content = File.read(file_path)
  new_content = add_or_update_source(content, source)

  if content == new_content
    puts "  (no change needed for frontmatter)" if dry_run
    return
  end

  if dry_run
    puts "  UPDATE frontmatter: source: \"#{source}\""
  else
    File.write(file_path, new_content)
  end
end

# ---------------------------------------------------------------------------
# Git helper: find the commit that added a file/dir
# ---------------------------------------------------------------------------

def adding_commit(path)
  result = `git -C #{PROJECT_ROOT.shellescape} log --diff-filter=A --format="%H" -- #{path.shellescape} 2>/dev/null`.strip
  result.empty? ? nil : result.lines.last.strip[0, 9]
end

require "shellwords"

# ---------------------------------------------------------------------------
# Step 1: Classify and process ideas in .ace-ideas/ root (non-_* folders)
# ---------------------------------------------------------------------------

puts "=== Step 1: Classify ideas in .ace-ideas/ root ===\n\n"

root_ideas = Dir.glob("#{IDEAS_ROOT}/*/").reject { |d| File.basename(d).start_with?("_") }.sort

unless dry_run
  FileUtils.mkdir_p(MAYBE_DIR)
end

root_ideas.each do |idea_dir|
  name = File.basename(idea_dir)

  # Find the spec file (may be absent for legacy container folders)
  spec_file = Dir.glob("#{idea_dir}*.idea.s.md").first

  # Determine source
  # Non-B36TS folders are always "legacy" regardless of which commit added them
  # (some legacy folders were carried along in the migration commit)
  commit = adding_commit(idea_dir)

  source = if !B36TS_PATTERN.match?(name)
             "legacy"
           elsif commit && MIGRATION_COMMITS.any? { |mc| commit.start_with?(mc) }
             "taskflow:v.0.9.0"
           else
             "user"
           end

  action = source == "taskflow:v.0.9.0" ? "KEEP  " : "MOVE→_maybe"
  puts "#{action}  #{name}  [source: #{source}]  (commit: #{commit || 'unknown'})"

  if spec_file
    update_frontmatter(spec_file, source: source, dry_run: dry_run)
  else
    puts "  WARNING: no .idea.s.md found — will move without frontmatter update"
  end

  next if source == "taskflow:v.0.9.0"

  # Move to _maybe
  dst = File.join(MAYBE_DIR, name)
  if File.exist?(dst)
    puts "  SKIP move (already exists in _maybe): #{name}"
    next
  end

  if dry_run
    puts "  MOVE: #{idea_dir}"
    puts "    ->  #{dst}"
  else
    FileUtils.mv(idea_dir, dst)
    puts "  moved to _maybe/"
  end
end

# ---------------------------------------------------------------------------
# Step 2: Migrate loose idea files from .ace-taskflow/_backlog/ideas/
# ---------------------------------------------------------------------------

puts "\n=== Step 2: Migrate backlog ideas from .ace-taskflow/_backlog/ideas/ ===\n\n"

unless Dir.exist?(BACKLOG_DIR)
  puts "Backlog directory not found: #{BACKLOG_DIR} — skipping."
else
  loose_files = Dir.glob("#{BACKLOG_DIR}/*.idea.s.md").sort

  if loose_files.empty?
    puts "No loose .idea.s.md files found in backlog."
  else
    loose_files.each do |file_path|
      name = File.basename(file_path)
      dst  = File.join(MAYBE_DIR, name)

      puts "BACKLOG: #{name}"
      update_frontmatter(file_path, source: "backlog", dry_run: dry_run)

      if File.exist?(dst)
        puts "  SKIP move (already exists in _maybe): #{name}"
        next
      end

      if dry_run
        puts "  MOVE: #{file_path}"
        puts "    ->  #{dst}"
      else
        FileUtils.mv(file_path, dst)
        puts "  moved to _maybe/"
      end
    end
  end
end

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

puts "\nDone."

if dry_run
  puts "\nRun without --dry-run to execute."
else
  puts "\nVerify with:"
  puts "  ace-idea list                 # should show only taskflow:v.0.9.0 ideas"
  puts "  ace-idea list --in maybe      # should show newly moved ideas with source field"
  puts "  ace-idea show 8pozex          # source: \"user\", in _maybe"
  puts "  ace-idea show 8ktby7          # source: \"taskflow:v.0.9.0\", in root"
end
