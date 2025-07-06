#!/usr/bin/env ruby
# diff-list-modified-files: Analyse a diff and list modified file paths with optional filtering
# Usage:
#   diff-list-modified-files [options]
#
# Options:
#   --diff FILE        : Path to a diff file (if not provided, read from STDIN)
#   --format FORMAT    : Output format: 'list' or 'md' (default: md)
#   --filter-include   : Comma-separated list of glob patterns to include (e.g. "*.rb,*.md")
#   --filter-exclude   : Comma-separated list of glob patterns to exclude (e.g. "test/*")
#   --output FILE      : Output file path (default: STDOUT)
#
# The tool will:
#   1. Parse the diff to obtain the list of modified files.
#   2. Apply include and exclude filters if specified.
#   3. Output either a list of file paths or a markdown report with embedded file content.
#
# Example:
#   diff-list-modified-files --diff changes.diff --format md --filter-include "*.rb,*.md" --filter-exclude "test/*" --output report.md

require "optparse"
require "fileutils"

options = {
  format: "md",
  filter_include: nil,
  filter_exclude: nil,
  diff_file: nil,
  output: nil
}

opts = OptionParser.new do |opts|
  opts.banner = "Usage: diff-list-modified-files [options]"

  opts.on("-d", "--diff FILE", "Path to diff file (if omitted, reads from STDIN)") do |file|
    options[:diff_file] = file
  end

  opts.on("-f", "--format FORMAT", "Output format: list or md (default: md)") do |format|
    options[:format] = format
  end

  opts.on("--filter-include PATTERNS", "Comma-separated glob patterns to include") do |patterns|
    options[:filter_include] = patterns.split(",").map(&:strip)
  end

  opts.on("--filter-exclude PATTERNS", "Comma-separated glob patterns to exclude") do |patterns|
    options[:filter_exclude] = patterns.split(",").map(&:strip)
  end

  opts.on("-o", "--output FILE", "Output file path (default: STDOUT)") do |file|
    options[:output] = file
  end

  opts.on("-h", "--help", "Displays help") do
    puts opts
    exit
  end
end

begin
  opts.parse!(ARGV)
rescue OptionParser::InvalidOption => e
  warn e.message
  exit 1
end

# Read diff content from file or STDIN
diff_content = ""
if options[:diff_file]
  unless File.exist?(options[:diff_file])
    warn "Diff file #{options[:diff_file]} does not exist."
    exit 1
  end
  diff_content = File.read(options[:diff_file])
else
  diff_content = STDIN.read
end

# Extract modified file paths from diff.
# Look for lines starting with "+++ " that indicate the new file path.
modified_files = []
diff_content.each_line do |line|
  if line.start_with?("+++ ")
    # Remove the '+++ ' prefix and any leading markers such as "a/" or "b/"
    path = line[4..-1].strip
    next if path == "/dev/null"
    path.sub!(/^(a|b)\//, "")
    modified_files << path unless path.empty?
  end
end

modified_files.uniq!

# ------------------------------------------------------------------
# Glob-based include / exclude filtering with defensive checks
#
# 1. Detect if the user forgot to quote their patterns and the shell
#    expanded them before they reached Ruby.
# 2. Use File.fnmatch with FNM_PATHNAME | FNM_EXTGLOB so that patterns
#    like **/* work as expected on any platform.

GLOB_FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB

# Returns true when the pattern no longer contains any glob metacharacters
# *and* exists on disk – a strong hint that the shell expanded it.
def shell_expanded?(pattern)
  pattern !~ /[\*\?\[\{]/ && File.exist?(pattern)
end

# Guard against silently-expanded patterns
[options[:filter_include], options[:filter_exclude]].compact.flatten.each do |pat|
  if shell_expanded?(pat)
    warn "Pattern '#{pat}' appears to have been expanded by the shell. Wrap glob patterns in single quotes, e.g. --filter-include 'lib/**/*'."
    exit 1
  end
end

# ------------------  INCLUDE  -------------------------------------
if options[:filter_include] && !options[:filter_include].empty?
  modified_files.select! do |file|
    options[:filter_include].any? { |pattern| File.fnmatch(pattern, file, GLOB_FLAGS) }
  end
end

# ------------------  EXCLUDE  -------------------------------------
if options[:filter_exclude] && !options[:filter_exclude].empty?
  modified_files.reject! do |file|
    options[:filter_exclude].any? { |pattern| File.fnmatch(pattern, file, GLOB_FLAGS) }
  end
end

modified_files.sort!

# Generate output.
output_str = ""

if options[:format] == "list"
  # List format: each file on a separate line.
  output_str = modified_files.join("\n")
else
  # Markdown format: include each file with embedded content.
  output_str << "# Diff Analysis Report\n\n"
  if modified_files.empty?
    output_str << "No modified files found.\n"
  else
    output_str << "## Modified Files\n\n"
    modified_files.each do |file|
      output_str << "### #{file}\n\n"
      output_str << "```\n"
      if File.exist?(file)
        begin
          file_content = File.read(file)
          output_str << file_content
        rescue => e
          output_str << "Error reading file: #{e.message}"
        end
      else
        output_str << "File not found on disk.\n"
      end
      output_str << "\n```\n\n"
    end
  end
end

# Write to output file if specified, else print to STDOUT.
if options[:output]
  begin
    File.write(options[:output], output_str)
    puts "Output written to #{options[:output]}"
  rescue => e
    warn "Error writing output file: #{e.message}"
    exit 1
  end
else
  puts output_str
end
