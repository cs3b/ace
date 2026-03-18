#!/usr/bin/env ruby
# Codemod: Update package README references from ace-meta to ace
# Fixes stale org references (ace-ecosystem, ace-meta/ace-core, etc.)

require 'find'

REPLACEMENTS = [
  # Stale org references (must come before generic replacements)
  ['https://github.com/ace-ecosystem/ace-meta', 'https://github.com/cs3b/ace'],
  ['https://github.com/ace-meta/ace-core', 'https://github.com/cs3b/ace'],
  ['https://github.com/ace-meta/ace-test-runner', 'https://github.com/cs3b/ace'],
  # Standard cs3b/ace-meta URLs
  ['https://github.com/cs3b/ace-meta', 'https://github.com/cs3b/ace'],
  # Text references
  ['cd ace-meta/', 'cd ace/'],
  ['cd ace-meta', 'cd ace'],
  ['the ace-meta project', 'the ace project'],
  ['the ace-meta monorepo', 'the ace monorepo'],
  ['ace-meta root', 'ace root'],
  ['ace-meta/', 'ace/'],
]

changed_files = []

Dir.glob('ace-*/README.md').each do |readme|
  content = File.read(readme)
  original = content.dup

  REPLACEMENTS.each do |old_text, new_text|
    content.gsub!(old_text, new_text)
  end

  if content != original
    File.write(readme, content)
    changed_files << readme
    puts "  Updated: #{readme}"
  end
end

puts "\n#{changed_files.length} README files updated."
