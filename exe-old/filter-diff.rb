#!/usr/bin/env ruby
# frozen_string_literal: true
#
# filter_diff.rb – remove selected paths from a unified diff
#
# Usage:
#   ruby filter_diff.rb DIFF_FILE [PATTERN …] [-p PATTERN_FILE] [-o OUTPUT]
#
#   • DIFF_FILE        – path to the original .diff / .patch file
#   • PATTERN …        – any number of shell-style globs to ignore
#   • -p, --pattern-file FILE
#                       read additional ignore globs (one per line) from FILE
#   • -o, --output FILE
#                       write filtered diff to FILE instead of “DIFF_FILE-filtered.diff”
#
# The script prints a summary:
#   – list of files removed
#   – line count before vs. after
#   – percentage reduction
#
# Example:
#     ruby filter_diff.rb changes.diff spec/** docs/** -p ignore.txt
#

require 'optparse'
require 'set'

opts = { globs: [] }

OptionParser.new do |o|
  o.banner = "Usage: #{$PROGRAM_NAME} DIFF_FILE [PATTERN …] [options]"

  o.on('-p', '--pattern-file FILE', 'File with ignore globs') { |f| opts[:pattern_file] = f }
  o.on('-o', '--output FILE', 'Filtered diff path')          { |f| opts[:output] = f }
  o.on('-h', '--help', 'Show this help') { puts o; exit }
end.parse!(into: opts)

abort 'Please provide a diff file.' if ARGV.empty?
diff_path = ARGV.shift

# Collect ignore globs
globs = opts[:globs] + ARGV
if opts[:pattern_file]
  globs += File.readlines(opts[:pattern_file], chomp: true).reject(&:empty?)
end
abort 'No ignore patterns supplied.' if globs.empty?

out_path = opts[:output] || diff_path.sub(/(\.diff|\.patch)?$/i, '-filtered.diff')

before_lines = 0
after_lines  = 0
removed      = Set.new
filtered     = []
block        = []
keep_block   = true
current_file = nil

flush = proc do
  if keep_block
    filtered.concat(block)
    after_lines += block.size
  else
    removed << current_file if current_file
  end
  block.clear
end

File.foreach(diff_path, chomp: false) do |line|
  before_lines += 1
  if line.start_with?('diff --git ')
    flush.call
    current_file = line.split[2].sub(%r{\Aa/}, '')
    keep_block   = globs.none? { |g| File.fnmatch?(g, current_file, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
  end
  block << line
end
flush.call

File.write(out_path, filtered.join)

cut        = before_lines - after_lines
percentage = (cut * 100.0 / before_lines).round(1)

puts <<~SUMMARY
  Filtered diff: #{out_path}

  Removed files (#{removed.size}):
  #{removed.to_a.sort.join("\n")}

  Lines before: #{before_lines}
  Lines after : #{after_lines}
  Cut          : #{cut} lines (#{percentage}%)
SUMMARY
