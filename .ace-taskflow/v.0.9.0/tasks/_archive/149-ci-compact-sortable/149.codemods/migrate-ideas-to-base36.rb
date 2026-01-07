#!/usr/bin/env ruby
# frozen_string_literal: true

# CORRECTED Migration script to convert WRONG Base36 directories to CORRECT Base36 format
# The previous migration used a reimplemented Base36Encoder with wrong algorithm.
# This script uses Ace::Timestamp.encode DIRECTLY from the gem.
#
# Usage:
#   ruby migrate-ideas-to-base36.rb --dry-run  # Preview changes
#   ruby migrate-ideas-to-base36.rb            # Execute migration

require "bundler/setup"
require "ace/timestamp"
require "time"
require "fileutils"

# Decoder for the WRONG algorithm that was used previously
# This is needed to reverse the incorrect encoding back to a timestamp
module WrongBase36Decoder
  ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz"
  YEAR_ZERO = 2000  # Must match ace-timestamp gem default

  def self.decode(base36_str)
    value = 0
    base36_str.each_char do |c|
      idx = ALPHABET.index(c)
      return nil if idx.nil?
      value = value * 36 + idx
    end
    # value is minutes since epoch
    epoch = Time.utc(YEAR_ZERO, 1, 1, 0, 0, 0)
    epoch + (value * 60)
  end
end

class Base36Corrector
  # Pattern for incorrectly encoded directories (6 lowercase alphanumeric chars followed by dash)
  WRONG_BASE36_PATTERN = /^([0-9a-z]{6})-(.*)$/

  def initialize(root_path, dry_run: false)
    @root_path = root_path
    @dry_run = dry_run
    @renamed = []
    @skipped = []
    @errors = []
  end

  def migrate!
    puts "Scanning for incorrectly-encoded Base36 directories in #{@root_path}..."
    puts "Mode: #{@dry_run ? 'DRY RUN' : 'EXECUTE'}"
    puts "Using: Ace::Timestamp.encode (gem version)"
    puts

    wrong_dirs = find_wrong_directories
    puts "Found #{wrong_dirs.length} directories to correct"
    puts

    wrong_dirs.each do |dir_path|
      correct_directory(dir_path)
    end

    print_summary
  end

  private

  def find_wrong_directories
    pattern = File.join(@root_path, "**", "*")
    Dir.glob(pattern)
       .select { |path| Dir.exist?(path) }
       .select { |path| needs_correction?(File.basename(path)) }
       .sort
  end

  def needs_correction?(dirname)
    match = dirname.match(WRONG_BASE36_PATTERN)
    return false unless match

    wrong_id = match[1]
    # Check if this looks like an incorrectly encoded ID (starts with 01 or 00)
    # Correct IDs for 2025-2026 dates start with 8 or 9
    return false if wrong_id.start_with?("8", "9")

    # Try to decode and verify it's a reasonable date
    time = WrongBase36Decoder.decode(wrong_id)
    return false unless time

    # Sanity check: should be between 2020 and 2030
    time.year >= 2020 && time.year <= 2030
  end

  def correct_directory(dir_path)
    dirname = File.basename(dir_path)
    parent_dir = File.dirname(dir_path)

    match = dirname.match(WRONG_BASE36_PATTERN)
    return unless match

    wrong_id = match[1]
    title = match[2]

    # Decode the wrong ID back to timestamp
    time = WrongBase36Decoder.decode(wrong_id)
    unless time
      @errors << { old: dir_path, error: "Could not decode wrong ID: #{wrong_id}" }
      puts "  ERROR: Could not decode #{wrong_id}"
      return
    end

    # Re-encode using the CORRECT algorithm from the gem
    correct_id = Ace::Timestamp.encode(time)

    # If they're the same (shouldn't happen but check), skip
    if wrong_id == correct_id
      @skipped << { path: dir_path, reason: "Already correct" }
      return
    end

    # Construct new dirname
    new_dirname = "#{correct_id}-#{title}"
    new_path = File.join(parent_dir, new_dirname)

    # Check for conflicts
    if File.exist?(new_path)
      @errors << { old: dir_path, new: new_path, error: "Target already exists" }
      puts "  SKIP: #{dirname} -> #{new_dirname} (target exists)"
      return
    end

    # Execute rename
    if @dry_run
      puts "  WOULD RENAME: #{dirname}"
      puts "            TO: #{new_dirname}"
      puts "       (time: #{time.strftime('%Y-%m-%d %H:%M')})"
      @renamed << { old: dir_path, new: new_path, time: time }
    else
      begin
        # Use git mv to preserve history
        result = system("git", "mv", dir_path, new_path)
        if result
          puts "  RENAMED: #{dirname}"
          puts "       TO: #{new_dirname}"
          @renamed << { old: dir_path, new: new_path, time: time }
        else
          # Fallback to regular mv if not in git
          FileUtils.mv(dir_path, new_path)
          puts "  RENAMED (non-git): #{dirname}"
          puts "                 TO: #{new_dirname}"
          @renamed << { old: dir_path, new: new_path, time: time }
        end
      rescue StandardError => e
        @errors << { old: dir_path, new: new_path, error: e.message }
        puts "  ERROR: #{dirname} - #{e.message}"
      end
    end
  end

  def print_summary
    puts
    puts "=" * 60
    puts "MIGRATION SUMMARY"
    puts "=" * 60
    puts "Directories renamed: #{@renamed.length}"
    puts "Skipped: #{@skipped.length}"
    puts "Errors: #{@errors.length}"

    if @errors.any?
      puts
      puts "ERRORS:"
      @errors.each do |err|
        puts "  - #{File.basename(err[:old])}: #{err[:error]}"
      end
    end

    if @dry_run && @renamed.any?
      puts
      puts "Run without --dry-run to execute these changes."
    end

    # Show a few examples of the mappings
    if @renamed.any?
      puts
      puts "SAMPLE MAPPINGS:"
      @renamed.first(5).each do |r|
        old_name = File.basename(r[:old])
        new_name = File.basename(r[:new])
        puts "  #{old_name[0..20]}... -> #{new_name[0..20]}..."
      end
    end
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  dry_run = ARGV.include?("--dry-run")
  root_path = ARGV.find { |arg| !arg.start_with?("--") } || ".ace-taskflow"

  unless Dir.exist?(root_path)
    puts "Error: Directory not found: #{root_path}"
    exit 1
  end

  corrector = Base36Corrector.new(root_path, dry_run: dry_run)
  corrector.migrate!
end
