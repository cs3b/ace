#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

# Define the gems to update and their new versions
# NOTE: This is a legacy codemod file from the infrastructure gem renaming
# ace-context was renamed to ace-bundle in v0.9.0
# NOTE: Version numbers below are placeholders and may not reflect current versions
TIER_2_GEMS = {
  'ace-bundle' => { from: '0.16.0', to: '0.29.2' },  # Update to current version
  'ace-git-commit' => { from: '0.11.0', to: '0.11.1' },
  'ace-git-diff' => { from: '0.1.1', to: '0.1.2' },
  'ace-llm' => { from: '0.9.4', to: '0.9.5' },
  'ace-taskflow' => { from: '0.15.1', to: '0.15.2' }
}

TIER_3_GEMS = {
  'ace-search' => { from: '0.11.2', to: '0.11.3' },
  'ace-lint' => { from: '0.3.0', to: '0.3.1' },
  'ace-docs' => { from: '0.6.1', to: '0.6.2' },
  'ace-review' => { from: '0.11.1', to: '0.11.2' },
  'ace-support-markdown' => { from: '0.1.2', to: '0.1.3' }
}

def update_gemspec(gem_name)
  gemspec_path = "#{gem_name}/#{gem_name}.gemspec"
  return unless File.exist?(gemspec_path)

  content = File.read(gemspec_path)

  # Update ace-core to ace-support-core
  content.gsub!('spec.add_dependency "ace-core"', 'spec.add_dependency "ace-support-core"')
  content.gsub!('spec.add_runtime_dependency "ace-core"', 'spec.add_runtime_dependency "ace-support-core"')

  # Update ace-test-support to ace-support-test-helpers
  content.gsub!('spec.add_development_dependency "ace-test-support"', 'spec.add_development_dependency "ace-support-test-helpers"')

  File.write(gemspec_path, content)
  puts "✅ Updated #{gemspec_path}"
end

def update_version(gem_name, new_version)
  # Try different version file patterns
  version_files = [
    "#{gem_name}/lib/ace/#{gem_name.sub('ace-', '').tr('-', '_')}/version.rb",
    "#{gem_name}/lib/ace/#{gem_name.sub('ace-', '')}/version.rb",
    "#{gem_name}/lib/#{gem_name.tr('-', '/')}/version.rb"
  ]

  version_file = version_files.find { |f| File.exist?(f) }
  return unless version_file

  content = File.read(version_file)
  content.gsub!(/VERSION = ["'][\d.]+["']/, "VERSION = \"#{new_version}\"")
  File.write(version_file, content)
  puts "✅ Updated version in #{version_file} to #{new_version}"
end

def update_changelog(gem_name, _new_version)
  changelog_path = "#{gem_name}/CHANGELOG.md"
  return unless File.exist?(changelog_path)

  content = File.read(changelog_path)

  # Find the position to insert the new entry
  if content.match(/^## \[Unreleased\]/m)
    # Insert after [Unreleased]
    content.sub!(/^## \[Unreleased\]\n/m, <<~ENTRY)
## [Unreleased]

## [#{_new_version}] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Changed dependency from `ace-test-support` to `ace-support-test-helpers` (if applicable)
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

    ENTRY
  elsif content.match(/^## \[[\d.]+\]/m)
    # Insert before the first version entry
    content.sub!(/^(## \[[\d.]+\])/m, <<~ENTRY)
## [#{_new_version}] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Changed dependency from `ace-test-support` to `ace-support-test-helpers` (if applicable)
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

\\1
    ENTRY
  else
    # Append to the file
    content += <<~ENTRY

## [#{_new_version}] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Changed dependency from `ace-test-support` to `ace-support-test-helpers` (if applicable)
  - Part of ecosystem-wide naming convention alignment for infrastructure gems
    ENTRY
  end

  File.write(changelog_path, content)
  puts "✅ Updated CHANGELOG for #{gem_name}"
end

def process_gems(gems_hash, tier_name)
  puts "\n🔧 Processing #{tier_name} gems..."

  gems_hash.each do |gem_name, versions|
    puts "\n📦 Processing #{gem_name}..."

    unless Dir.exist?(gem_name)
      puts "⚠️  Directory #{gem_name} not found, skipping..."
      next
    end

    update_gemspec(gem_name)
    update_version(gem_name, versions[:to])
    update_changelog(gem_name, versions[:to])
  end
end

# Main execution
puts "🚀 Starting gem dependency updates..."

process_gems(TIER_2_GEMS, "Tier 2")
process_gems(TIER_3_GEMS, "Tier 3")

puts "\n✨ All gems updated successfully!"
puts "\n📝 Next steps:"
puts "1. Update root Gemfile"
puts "2. Run comprehensive test suite"
puts "3. Create migration guide"