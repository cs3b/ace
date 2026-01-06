#!/usr/bin/env ruby
# frozen_string_literal: true

# Migration script to convert timestamp-format directories to Base36 format
# Usage:
#   ruby migrate-ideas-to-base36.rb --dry-run  # Preview changes
#   ruby migrate-ideas-to-base36.rb            # Execute migration

require "time"
require "fileutils"

# Simple Base36 encoder for timestamps (same logic as Ace::Timestamp)
module Base36Encoder
  ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz"
  YEAR_ZERO = 2020 # Default year_zero

  def self.encode(time, year_zero: YEAR_ZERO)
    total_minutes = minutes_since_epoch(time, year_zero)
    encode_minutes(total_minutes)
  end

  def self.minutes_since_epoch(time, year_zero)
    epoch = Time.utc(year_zero, 1, 1, 0, 0, 0)
    ((time.to_i - epoch.to_i) / 60).to_i
  end

  def self.encode_minutes(total_minutes)
    result = ""
    value = total_minutes

    6.times do
      result = ALPHABET[value % 36] + result
      value /= 36
    end

    result
  end
end

class Base36Migrator
  TIMESTAMP_PATTERN = /^(\d{8})-(\d{6})-(.*)$/

  def initialize(root_path, dry_run: false)
    @root_path = root_path
    @dry_run = dry_run
    @renamed = []
    @errors = []
  end

  def migrate!
    puts "Scanning for timestamp directories in #{@root_path}..."
    puts "Mode: #{@dry_run ? 'DRY RUN' : 'EXECUTE'}"
    puts

    timestamp_dirs = find_timestamp_directories
    puts "Found #{timestamp_dirs.length} directories to migrate"
    puts

    timestamp_dirs.each do |dir_path|
      migrate_directory(dir_path)
    end

    print_summary
  end

  private

  def find_timestamp_directories
    pattern = File.join(@root_path, "**", "*")
    Dir.glob(pattern)
       .select { |path| Dir.exist?(path) }
       .select { |path| File.basename(path).match?(TIMESTAMP_PATTERN) }
       .sort
  end

  def migrate_directory(dir_path)
    dirname = File.basename(dir_path)
    parent_dir = File.dirname(dir_path)

    match = dirname.match(TIMESTAMP_PATTERN)
    return unless match

    date_part = match[1]  # YYYYMMDD
    time_part = match[2]  # HHMMSS
    title = match[3]

    # Parse timestamp
    timestamp_str = "#{date_part}-#{time_part}"
    time = Time.strptime(timestamp_str, "%Y%m%d-%H%M%S")

    # Encode to Base36
    base36_id = Base36Encoder.encode(time)

    # Construct new dirname
    new_dirname = "#{base36_id}-#{title}"
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
      @renamed << { old: dir_path, new: new_path, dirname: dirname, new_dirname: new_dirname }
    else
      begin
        # Use git mv to preserve history
        result = system("git", "mv", dir_path, new_path)
        if result
          puts "  RENAMED: #{dirname}"
          puts "       TO: #{new_dirname}"
          @renamed << { old: dir_path, new: new_path, dirname: dirname, new_dirname: new_dirname }
        else
          # Fallback to regular mv if not in git
          FileUtils.mv(dir_path, new_path)
          puts "  RENAMED (non-git): #{dirname}"
          puts "                 TO: #{new_dirname}"
          @renamed << { old: dir_path, new: new_path, dirname: dirname, new_dirname: new_dirname }
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
  end
end

# Main execution
if __FILE__ == $0
  dry_run = ARGV.include?("--dry-run")
  root_path = ARGV.find { |arg| !arg.start_with?("--") } || ".ace-taskflow"

  unless Dir.exist?(root_path)
    puts "Error: Directory not found: #{root_path}"
    exit 1
  end

  migrator = Base36Migrator.new(root_path, dry_run: dry_run)
  migrator.migrate!
end
