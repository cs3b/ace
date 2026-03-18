#!/usr/bin/env ruby
# Codemod: Update gemspec homepage and metadata URLs from ace-meta to ace
# Also fixes stale org references (ace-ecosystem, ace-meta/ace-core, etc.)

require 'find'

REPLACEMENTS = {
  # Standard cs3b/ace-meta URLs
  'https://github.com/cs3b/ace-meta' => 'https://github.com/cs3b/ace',
  # Stale org references found in subtask a inventory
  'https://github.com/ace-ecosystem/ace-meta' => 'https://github.com/cs3b/ace',
  'https://github.com/ace-meta/ace-core' => 'https://github.com/cs3b/ace',
  'https://github.com/ace-meta/ace-test-runner' => 'https://github.com/cs3b/ace',
}

changed_files = []

Dir.glob('*/*.gemspec').each do |gemspec|
  content = File.read(gemspec)
  original = content.dup

  REPLACEMENTS.each do |old_url, new_url|
    content.gsub!(old_url, new_url)
  end

  if content != original
    File.write(gemspec, content)
    changed_files << gemspec
    puts "  Updated: #{gemspec}"
  end
end

puts "\n#{changed_files.length} gemspec files updated."
