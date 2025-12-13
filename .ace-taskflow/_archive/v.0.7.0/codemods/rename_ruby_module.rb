#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'
require 'optparse'
require 'pathname'

class RubyModuleRenameCodemod
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
      replacements_by_type: {},
      errors: []
    }
  end

  def run
    puts "Starting Ruby module rename codemod..."
    puts "Mode: #{@options[:dry_run] ? 'DRY RUN' : 'APPLY'}"
    puts "Root directory: #{File.expand_path(@options[:root])}"
    puts "Module mappings:"
    puts "  - CodingAgentTools -> AceTools"
    puts "  - coding_agent_tools -> ace_tools"
    puts "  - coding-agent-tools -> ace-tools"
    puts "-" * 60

    process_directory(@options[:root])

    print_summary
  end

  private

  def load_mappings(file)
    unless File.exist?(file)
      raise "Mappings file not found: #{file}"
    end

    YAML.load_file(file)
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
      replacements_detail = {}

      # Apply module name replacements
      if @mappings['modules']
        @mappings['modules'].each do |old_name, new_name|
          patterns = generate_module_patterns(old_name, new_name)

          patterns.each do |pattern, replacement|
            count = content.scan(pattern).size
            if count > 0
              content.gsub!(pattern, replacement)
              replacements += count
              replacements_detail["#{old_name}->#{new_name}"] ||= 0
              replacements_detail["#{old_name}->#{new_name}"] += count

              if @options[:verbose]
                puts "  #{file_path}: Replacing '#{old_name}' -> '#{new_name}' (#{count} occurrences)"
              end
            end
          end
        end
      end

      # Apply path replacements (snake_case)
      if @mappings['paths']
        @mappings['paths'].each do |old_path, new_path|
          patterns = generate_path_patterns(old_path, new_path)

          patterns.each do |pattern, replacement|
            count = content.scan(pattern).size
            if count > 0
              content.gsub!(pattern, replacement)
              replacements += count
              replacements_detail["#{old_path}->#{new_path}"] ||= 0
              replacements_detail["#{old_path}->#{new_path}"] += count

              if @options[:verbose]
                puts "  #{file_path}: Replacing '#{old_path}' -> '#{new_path}' (#{count} occurrences)"
              end
            end
          end
        end
      end

      # Apply special pattern replacements
      if @mappings['patterns']
        @mappings['patterns'].each do |old_pattern, new_pattern|
          count = content.scan(Regexp.new(Regexp.escape(old_pattern))).size
          if count > 0
            content.gsub!(Regexp.new(Regexp.escape(old_pattern)), new_pattern)
            replacements += count
            replacements_detail["pattern:#{old_pattern}"] ||= 0
            replacements_detail["pattern:#{old_pattern}"] += count

            if @options[:verbose]
              puts "  #{file_path}: Pattern '#{old_pattern}' -> '#{new_pattern}' (#{count} occurrences)"
            end
          end
        end
      end

      if replacements > 0
        @stats[:files_modified] += 1
        @stats[:total_replacements] += replacements

        # Track replacements by type
        replacements_detail.each do |type, count|
          @stats[:replacements_by_type][type] ||= 0
          @stats[:replacements_by_type][type] += count
        end

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

  def generate_module_patterns(old_name, new_name)
    patterns = {}
    escaped_old = Regexp.escape(old_name)

    # Module definitions with proper word boundaries
    patterns[/\b(module|class)\s+#{escaped_old}\b/] = "\\1 #{new_name}"

    # Namespace references (::)
    patterns[/\b#{escaped_old}::/] = "#{new_name}::"
    patterns[/::#{escaped_old}\b/] = "::#{new_name}"

    # Inheritance and includes
    patterns[/<\s*#{escaped_old}\b/] = "< #{new_name}"
    patterns[/\binclude\s+#{escaped_old}\b/] = "include #{new_name}"
    patterns[/\bextend\s+#{escaped_old}\b/] = "extend #{new_name}"
    patterns[/\bprepend\s+#{escaped_old}\b/] = "prepend #{new_name}"

    # Method calls and constants
    patterns[/\b#{escaped_old}\.(\w+)/] = "#{new_name}.\\1"
    patterns[/\b#{escaped_old}::(\w+)/] = "#{new_name}::\\1"

    # In strings (for specs, error messages, etc.)
    patterns[/(['"])#{escaped_old}(['"])/] = "\\1#{new_name}\\2"

    # In comments
    patterns[/(#.*)\b#{escaped_old}\b/] = "\\1#{new_name}"

    # Standalone references (must be last to avoid conflicts)
    patterns[/\b#{escaped_old}\b(?!::|\.|_|-)/] = new_name

    patterns
  end

  def generate_path_patterns(old_path, new_path)
    patterns = {}
    escaped_old = Regexp.escape(old_path)

    # Require statements
    patterns[/require\s+['"]#{escaped_old}['"]/] = "require '#{new_path}'"
    patterns[/require_relative\s+['"]#{escaped_old}['"]/] = "require_relative '#{new_path}'"
    patterns[/require\s+['"]#{escaped_old}\//] = "require '#{new_path}/"
    patterns[/require_relative\s+['"]#{escaped_old}\//] = "require_relative '#{new_path}/"

    # Autoload statements
    patterns[/autoload\s+:(\w+),\s+['"]#{escaped_old}['"]/] = "autoload :\\1, '#{new_path}'"

    # File paths in strings
    patterns[/(['"])#{escaped_old}\/([^'"]*['"]) /] = "\\1#{new_path}/\\2"

    # Path references in comments
    patterns[/(#.*\s)#{escaped_old}(\s|$|\/)/] = "\\1#{new_path}\\2"

    # Gem specifications
    patterns[/gem\s+['"]#{escaped_old}['"]/] = "gem '#{new_path}'"

    # General path references (with word boundaries)
    if old_path.include?('-')
      # For dash-case (like coding-agent-tools)
      patterns[/\b#{escaped_old}\b/] = new_path
    else
      # For snake_case (like coding_agent_tools)
      patterns[/\b#{escaped_old}\b/] = new_path
    end

    patterns
  end

  def show_diff(original, modified, file_path)
    puts "\n--- Diff for #{file_path} ---"
    original_lines = original.lines
    modified_lines = modified.lines

    line_num = 0
    [original_lines.size, modified_lines.size].max.times do |i|
      line_num += 1
      orig_line = original_lines[i]
      mod_line = modified_lines[i]

      if orig_line != mod_line
        puts "#{line_num}:"
        puts "- #{orig_line.chomp}" if orig_line
        puts "+ #{mod_line.chomp}" if mod_line
      end
    end
    puts "--- End diff ---\n"
  end

  def print_summary
    puts "\n" + "=" * 60
    puts "MODULE RENAME CODEMOD SUMMARY"
    puts "=" * 60
    puts "Files scanned: #{@stats[:files_scanned]}"
    puts "Files modified: #{@stats[:files_modified]}"
    puts "Total replacements: #{@stats[:total_replacements]}"

    if @stats[:replacements_by_type].any?
      puts "\nReplacements by type:"
      @stats[:replacements_by_type].sort_by { |_, count| -count }.each do |type, count|
        puts "  #{type}: #{count}"
      end
    end

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

    opts.on("-m", "--mappings FILE", "Module mappings YAML file (default: module_mappings.yml)") do |file|
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
  mappings_file = options[:mappings_file] || File.join(File.dirname(__FILE__), 'module_mappings.yml')

  begin
    codemod = RubyModuleRenameCodemod.new(mappings_file, options)
    codemod.run
  rescue => e
    puts "ERROR: #{e.message}"
    exit 1
  end
end