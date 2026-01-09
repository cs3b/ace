#!/usr/bin/env ruby
# frozen_string_literal: true

# Migration script to convert legacy file formats to new formats
#
# Idea files:
#   - idea.s.md → {slug}.idea.s.md
#   - {slug}.s.md → {slug}.idea.s.md
#
# Retro files:
#   - YYYY-MM-DD-{slug}.md → {base36-id}-{slug}.md
#   - YYYYMMDD-{slug}.md → {base36-id}-{slug}.md

require "fileutils"
require "time"
require "pathname"
require "ace/timestamp"
require_relative "../atoms/id_title_extractor"

class LegacyFileMigrator
  attr_reader :root_path, :dry_run, :backup_dir

  def initialize(root_path:, dry_run: true)
    @root_path = root_path
    @dry_run = dry_run
    @stats = { ideas: 0, retros: 0, errors: 0, skipped: 0 }
    @backup_dir = nil
  end

  def run
    puts "=========================================="
    puts "Legacy File Migration"
    puts "=========================================="
    mode_text = dry_run ? "DRY RUN (no changes)" : "FORCE (will modify files)"
    puts "Mode: #{mode_text}"
    puts "Root: #{root_path}"
    puts

    # Create backup before making changes
    create_backup unless dry_run

    # Migrate ideas
    puts "\n[1/2] Migrating idea files..."
    migrate_idea_files

    # Migrate retros
    puts "\n[2/2] Migrating retrospective files..."
    migrate_retro_files

    # Print summary
    print_summary
  end

  private

  def create_backup
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    @backup_dir = File.join(root_path, ".ace-taskflow", ".backup", "pre-migration-#{timestamp}")

    backup_pathname = Pathname.new(backup_dir)
    root_pathname = Pathname.new(root_path)
    puts "Creating backup at: #{backup_pathname.relative_path_from(root_pathname)}"
    FileUtils.mkdir_p(backup_dir)

    # Backup .ace-taskflow directory
    ace_dir = File.join(root_path, ".ace-taskflow")
    if Dir.exist?(ace_dir)
      system("cp -r #{ace_dir} #{File.join(backup_dir, "ace-taskflow")}")
      puts "  ✓ Backup created"
    end
  end

  def migrate_idea_files
    # Find all directories containing idea.s.md
    idea_s_md_files = Dir.glob(File.join(root_path, ".ace-taskflow", "**", "idea.s.md"))

    idea_s_md_files.each do |source_path|
      migrate_idea_s_md(source_path)
    end

    # Find all .s.md files (excluding .idea.s.md and idea.s.md)
    s_md_files = Dir.glob(File.join(root_path, ".ace-taskflow", "**", "*.s.md"))
      .reject { |f| f.end_with?(".idea.s.md") || f.end_with?("/idea.s.md") }

    s_md_files.each do |source_path|
      migrate_s_md(source_path)
    end
  end

  def migrate_idea_s_md(source_path)
    dir_path = File.dirname(source_path)
    dir_name = File.basename(dir_path)

    # Extract slug from directory name (format: abc123-slug or just slug)
    id, slug = Ace::Taskflow::Atoms::IdTitleExtractor.extract_from_dirname(dir_name)

    # If directory has no ID, use the whole directory name as slug
    slug ||= dir_name

    # Generate new filename: {slug}.idea.s.md
    new_filename = sanitize_slug(slug) + ".idea.s.md"
    target_path = File.join(dir_path, new_filename)

    rename_file(source_path, target_path, "idea.s.md → #{new_filename}")
  end

  def migrate_s_md(source_path)
    filename = File.basename(source_path)
    basename = filename.sub(/\.s\.md$/, "")

    # Extract ID and title from basename
    id, slug = Ace::Taskflow::Atoms::IdTitleExtractor.extract_from_dirname(basename)

    # If no ID prefix, use entire basename as slug
    slug ||= basename

    # Generate new filename: {slug}.idea.s.md
    new_filename = sanitize_slug(slug) + ".idea.s.md"
    target_path = File.join(File.dirname(source_path), new_filename)

    rename_file(source_path, target_path, "#{filename} → #{new_filename}")
  end

  def migrate_retro_files
    # Find all retro files with date prefixes
    retro_files = Dir.glob(File.join(root_path, ".ace-taskflow", "**", "retros", "*.md"))
      .select { |f| File.basename(f) =~ /^(20\d{2}-\d{2}-\d{2}|20\d{6})-/ }

    retro_files.each do |source_path|
      migrate_retro_file(source_path)
    end
  end

  def migrate_retro_file(source_path)
    filename = File.basename(source_path, ".md")

    # Extract date prefix and slug
    if filename =~ /^(\d{4})-(\d{2})-(\d{2})-(.+)$/
      # YYYY-MM-DD-slug.md format
      year, month, day, slug = $1, $2, $3, $4
      date_time = Time.utc(year.to_i, month.to_i, day.to_i, 0, 0, 0)
    elsif filename =~ /^(20\d{6})-(.+)$/
      # YYYYMMDD-slug.md format
      date_str = $1
      slug = $2
      year = date_str[0..3].to_i
      month = date_str[4..5].to_i
      day = date_str[6..7].to_i
      date_time = Time.utc(year, month, day, 0, 0, 0)
    else
      puts "  ⚠️  Unknown format: #{filename}"
      @stats[:skipped] += 1
      return
    end

    # Generate Base36 ID from timestamp
    base36_id = Ace::Timestamp.encode(date_time)

    # Generate new filename: {base36-id}-{slug}.md
    new_filename = "#{base36_id}-#{slug}.md"
    target_path = File.join(File.dirname(source_path), new_filename)

    rename_file(source_path, target_path, "#{File.basename(source_path)} → #{new_filename}")
  end

  def rename_file(source_path, target_path, description)
    if source_path == target_path
      @stats[:skipped] += 1
      return
    end

    if File.exist?(target_path)
      puts "  ⚠️  Target exists, skipping: #{description}"
      @stats[:skipped] += 1
      return
    end

    if dry_run
      puts "  Would rename: #{description}"
    else
      FileUtils.mv(source_path, target_path)
      puts "  ✓ Renamed: #{description}"
    end

    # Track count
    if source_path.include?("ideas")
      @stats[:ideas] += 1
    elsif source_path.include?("retros")
      @stats[:retros] += 1
    end
  end

  def sanitize_slug(slug)
    # Convert to lowercase, replace invalid chars with hyphens
    slug.to_s.downcase
      .gsub(/[.\\\/]/, "")           # Remove dots, slashes, backslashes
      .gsub(/[^a-z0-9-]/i, "-")      # Replace non-alphanumerics with hyphens
      .gsub(/-+/, "-")               # Collapse multiple hyphens
      .gsub(/^-|-$/, "")             # Remove leading/trailing hyphens
  end

  def print_summary
    puts "\n=========================================="
    puts "Migration Summary"
    puts "=========================================="
    puts "Ideas migrated:  #{@stats[:ideas]}"
    puts "Retros migrated: #{@stats[:retros]}"
    puts "Skipped:         #{@stats[:skipped]}"
    puts "Errors:          #{@stats[:errors]}"
    puts "Total files:     #{@stats[:ideas] + @stats[:retros]}"
    puts

    if dry_run
      puts "⚠️  DRY RUN MODE - No files were actually modified"
      puts "   Run with --force to perform the migration"
    else
      puts "✓ Migration complete!"
      backup_pathname = Pathname.new(backup_dir)
      root_pathname = Pathname.new(root_path)
      puts "  Backup saved at: #{backup_pathname.relative_path_from(root_pathname)}"
    end
  end
end

# Parse arguments
dry_run = ARGV.include?("--force") ? false : true

# Find root directory (mono-repo root where .ace-taskflow lives)
# Script is at: ace-taskflow/lib/ace/taskflow/scripts/migrate_legacy_files.rb
# Need to go up 6 levels to reach mono-repo root
root_path = File.expand_path("../../../../../../", __FILE__)

# Run migration
migrator = LegacyFileMigrator.new(root_path: root_path, dry_run: dry_run)
migrator.run
