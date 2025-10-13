#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'
require 'optparse'
require 'pathname'
require 'set'

class PathUpdateCodemod
  BINARY_EXTENSIONS = %w[.jpg .jpeg .png .gif .pdf .zip .tar .gz .bz2 .exe .dll .so .dylib .bin .dat .db .sqlite].freeze
  SKIP_DIRS = %w[.git .svn node_modules vendor bundle .bundle coverage tmp log].freeze

  attr_reader :mappings, :options, :stats

  def initialize(mappings_file, options = {})
    @mappings = load_mappings(mappings_file)
    @options = {
      dry_run: true,
      backup: true,
      verbose: false,
      root: '.',
      exclude_patterns: [],
      include_patterns: ['*']
    }.merge(options)

    @stats = {
      files_scanned: 0,
      files_modified: 0,
      total_replacements: 0,
      errors: []
    }
  end

  def run
    puts "Starting path update codemod..."
    puts "Mode: #{@options[:dry_run] ? 'DRY RUN' : 'APPLY'}"
    puts "Root directory: #{File.expand_path(@options[:root])}"
    puts "Mappings: #{@mappings.size} path conversions"
    puts "-" * 60

    process_directory(@options[:root])

    print_summary
  end

  private

  def load_mappings(file)
    unless File.exist?(file)
      raise "Mappings file not found: #{file}"
    end

    config = YAML.load_file(file)
    mappings = config['mappings'] || {}

    # Sort mappings by length (longest first) to avoid partial replacements
    mappings.sort_by { |k, _| -k.length }.to_h
  end

  def process_directory(dir)
    Dir.glob(File.join(dir, '**', '*'), File::FNM_DOTMATCH).each do |path|
      next if File.directory?(path)
      next if should_skip?(path)

      process_file(path)
    end
  end

  def should_skip?(path)
    # Skip binary files
    return true if BINARY_EXTENSIONS.any? { |ext| path.end_with?(ext) }

    # Skip .DS_Store files
    return true if File.basename(path) == '.DS_Store'

    # Skip symlinks
    return true if File.symlink?(path)

    # Skip directories
    path_parts = path.split('/')
    return true if path_parts.any? { |part| SKIP_DIRS.include?(part) }

    # Skip based on exclude patterns
    @options[:exclude_patterns].any? { |pattern| File.fnmatch(pattern, path) }
  end

  def process_file(file_path)
    @stats[:files_scanned] += 1

    begin
      content = File.read(file_path, encoding: 'UTF-8')
      original_content = content.dup
      replacements = 0

      # Apply all mappings
      @mappings.each do |old_path, new_path|
        # Create patterns for different contexts
        patterns = generate_patterns(old_path, new_path)

        patterns.each do |pattern, replacement|
          count = content.scan(pattern).size
          if count > 0
            content.gsub!(pattern, replacement)
            replacements += count

            if @options[:verbose]
              puts "  #{file_path}: Replacing '#{old_path}' -> '#{new_path}' (#{count} occurrences)"
            end
          end
        end
      end

      if replacements > 0
        @stats[:files_modified] += 1
        @stats[:total_replacements] += replacements

        if @options[:dry_run]
          puts "[DRY RUN] Would modify: #{file_path} (#{replacements} replacements)"
          if @options[:verbose]
            show_diff(original_content, content, file_path)
          end
        else
          # Create backup if requested
          if @options[:backup]
            backup_file = "#{file_path}.bak"
            FileUtils.cp(file_path, backup_file)
          end

          # Write the modified content
          File.write(file_path, content)
          puts "[APPLIED] Modified: #{file_path} (#{replacements} replacements)"
        end
      end

    rescue => e
      @stats[:errors] << "Error processing #{file_path}: #{e.message}"
      puts "ERROR: #{file_path} - #{e.message}" if @options[:verbose]
    end
  end

  def generate_patterns(old_path, new_path)
    patterns = {}

    # Escape special regex characters in the path
    escaped_old = Regexp.escape(old_path)

    # Pattern 1: Simple path reference with word boundaries or common delimiters
    # This prevents matching "some.ace/tools/" when looking for ".ace/tools/"
    # Use both lookbehind and lookahead to ensure proper word boundaries
    if old_path.end_with?('/')
      # For paths with trailing slash, ensure the slash is followed by appropriate characters
      patterns[/(?<=^|\s|\/|\.|\(|\[|'|"|\||`)#{escaped_old}(?=\w|\/|$|\s|\)|'|"|\]|`)/] = new_path
    else
      # For paths without trailing slash, ensure proper boundaries
      patterns[/(?<=^|\s|\/|\.|\(|\[|'|"|\||`)#{escaped_old}(?=\/|$|\s|\)|'|"|\]|`)/] = new_path
    end

    # Pattern 2: In quotes (preserve quotes) - already has boundaries
    patterns[/"#{escaped_old}"/] = "\"#{new_path}\""
    patterns[/'#{escaped_old}'/] = "'#{new_path}'"

    # Pattern 3: In markdown links - already has boundary
    patterns[/\]\(#{escaped_old}/] = "](#{new_path}"

    # Pattern 4: In markdown references - already has boundary
    patterns[/\[([^\]]+)\]:\s*#{escaped_old}/] = "[\\1]: #{new_path}"

    patterns
  end

  def show_diff(original, modified, file_path)
    puts "\n--- Diff for #{file_path} ---"
    original_lines = original.lines
    modified_lines = modified.lines

    [original_lines.size, modified_lines.size].max.times do |i|
      orig_line = original_lines[i]
      mod_line = modified_lines[i]

      if orig_line != mod_line
        puts "- #{orig_line}" if orig_line
        puts "+ #{mod_line}" if mod_line
      end
    end
    puts "--- End diff ---\n"
  end

  def print_summary
    puts "\n" + "=" * 60
    puts "CODEMOD SUMMARY"
    puts "=" * 60
    puts "Files scanned: #{@stats[:files_scanned]}"
    puts "Files modified: #{@stats[:files_modified]}"
    puts "Total replacements: #{@stats[:total_replacements]}"

    if @stats[:errors].any?
      puts "\nErrors encountered:"
      @stats[:errors].each { |error| puts "  - #{error}" }
    end

    if @options[:dry_run]
      puts "\n[DRY RUN MODE] No files were actually modified."
      puts "Run with --apply to make actual changes."
    end
  end
end

# CLI interface
if __FILE__ == $0
  options = {
    dry_run: true,
    backup: true,
    verbose: false,
    root: '.'
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"

    opts.on("-a", "--apply", "Apply changes (default is dry-run)") do
      options[:dry_run] = false
    end

    opts.on("-n", "--no-backup", "Don't create backup files") do
      options[:backup] = false
    end

    opts.on("-v", "--verbose", "Show detailed output") do
      options[:verbose] = true
    end

    opts.on("-r", "--root PATH", "Root directory to process (default: current directory)") do |path|
      options[:root] = path
    end

    opts.on("-m", "--mappings FILE", "Path mappings YAML file (default: path_mappings.yml)") do |file|
      options[:mappings_file] = file
    end

    opts.on("-e", "--exclude PATTERN", "Exclude files matching pattern") do |pattern|
      options[:exclude_patterns] ||= []
      options[:exclude_patterns] << pattern
    end

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!

  # Default mappings file
  mappings_file = options[:mappings_file] || File.join(File.dirname(__FILE__), 'path_mappings.yml')

  begin
    codemod = PathUpdateCodemod.new(mappings_file, options)
    codemod.run
  rescue => e
    puts "ERROR: #{e.message}"
    exit 1
  end
end