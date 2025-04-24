#!/usr/bin/env ruby
# frozen_string_literal: true

# md_link_check.rb — Simple Markdown link validator
# -------------------------------------------------
# Recursively scans Markdown files and reports links that do not resolve to
# existing files on disk.
#
# Usage:
#   ruby md_link_check.rb [options] path1 [path2 ...]
#
# Options:
#   -r, --root DIR     Project root for resolving *root-relative* links (default '.')
#   -c, --context N    Show N lines of context around a broken link (default 3)
#
# Behaviour:
#   • Ignores links inside fenced code blocks (``` … ```), since those are
#     illustrative examples.
#   • For visible inline links:
#       – External schemes (http://, https://, mailto:) are skipped.
#       – In‑page anchors (#...) are skipped.
#       – The validator first resolves the target relative to the file’s
#         directory; if missing, it tries from the project root.
#
# Exit status:
#   0  – no broken links found
#   1  – at least one broken link detected

require 'optparse'
require 'pathname'

options = { root: '.', context: 3 }
OptionParser.new do |opts|
  opts.banner = 'Usage: md_link_check.rb [options] path1 [path2 ...]'

  opts.on('-r', '--root DIR', 'Project root for resolving root-relative links') do |v|
    options[:root] = v
  end

  opts.on('-c', '--context N', Integer, 'Lines of context to show around each broken link') do |v|
    options[:context] = v
  end
end.parse!(ARGV)

paths = ARGV.empty? ? [options[:root]] : ARGV
root_path = Pathname.new(File.expand_path(options[:root]))

# Collect *.md files
md_files = paths.flat_map do |p|
  File.directory?(p) ? Dir.glob(File.join(p, '**', '*.md')) : [p]
end

LINK_REGEX = /\[[^\]]+\]\(([^)]+)\)/
SCHEME_SKIP = %r{^(?:[a-z][a-z0-9+\-.]*://|mailto:)}i.freeze
BrokenLink = Struct.new(:file, :line_no, :link, :context_lines)

broken_links = []

md_files.each do |file|
  lines = File.readlines(file, chomp: true)
  in_code_block = false

  lines.each_with_index do |line, idx|
    # toggle code‑block mode
    fence_start = line.lstrip[0,3]
    if fence_start == '```' || fence_start == '~~~'
      in_code_block = !in_code_block
      next
    end

    next if in_code_block

    line.scan(LINK_REGEX) do |match|
      raw_target = match.first.strip
      next if raw_target.match?(SCHEME_SKIP) || raw_target.start_with?('#')

      target_path = raw_target.split('#').first
      candidate = Pathname.new(File.expand_path(target_path, File.dirname(file)))
      candidate = Pathname.new(File.expand_path(target_path, root_path)) unless candidate.exist?
      next if candidate.exist?

      start = [idx - options[:context], 0].max
      finish = [idx + options[:context], lines.size - 1].min
      snippet = lines[start..finish]
      broken_links << BrokenLink.new(file, idx + 1, raw_target, snippet)
    end
  end
end

if broken_links.empty?
  puts '✅ No broken links.'
  exit 0
else
  puts "❌ Broken links found: #{broken_links.size}"
  broken_links.each do |b|
    puts "\nFile: #{b.file}  Line: #{b.line_no}"
    puts "Link: #{b.link}"
    puts 'Context:'
    context_start_line = b.line_no - options[:context]
    b.context_lines.each_with_index do |ctx_line, i|
      puts format('%4d | %s', context_start_line + i, ctx_line)
    end
  end
  exit 1
end
