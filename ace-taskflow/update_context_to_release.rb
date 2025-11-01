#!/usr/bin/env ruby
# Script to complete the context -> release rename in ace-taskflow

require 'fileutils'

# Define the files and patterns to update
UPDATES = {
  # Phase 3: Loaders & Resolvers
  'lib/ace/taskflow/molecules/task_loader.rb' => [
    { from: 'context_path', to: 'release_path' },
    { from: '@context', to: '@release' },
    { from: 'resolve_context(', to: 'resolve_release(' },
    { from: 'def resolve_context(context)', to: 'def resolve_release(release)' },
    { from: 'case context', to: 'case release' }
  ],

  'lib/ace/taskflow/molecules/release_resolver.rb' => [
    { from: 'resolve_context(context)', to: 'resolve_release(release)' },
    { from: '@param context', to: '@param release' },
    { from: 'def resolve_context(context)', to: 'def resolve_release(release)' },
    { from: 'case context', to: 'case release' }
  ],

  'lib/ace/taskflow/molecules/task_filter.rb' => [
    { from: 'filter_by_context(tasks, context)', to: 'filter_by_release(tasks, release)' },
    { from: '@param context', to: '@param release' },
    { from: 'def filter_by_context(tasks, context)', to: 'def filter_by_release(tasks, release)' },
    { from: 'filters[:context]', to: 'filters[:release]' },
    { from: 'task[:context]', to: 'task[:release]' }
  ],

  # Phase 4: Reference Parser
  'lib/ace/taskflow/atoms/task_reference_parser.rb' => [
    { from: 'normalize_context(context)', to: 'normalize_release(release)' },
    { from: 'release_context?(context)', to: 'is_release_version?(release)' },
    { from: 'def normalize_context(context)', to: 'def normalize_release(release)' },
    { from: 'def release_context?(context)', to: 'def is_release_version?(release)' },
    { from: 'format(context, number', to: 'format(release, number' },
    { from: ', context:', to: ', release:' },
    { from: '@param context', to: '@param release' }
  ],

  # Phase 5: Command Classes
  'lib/ace/taskflow/commands/task_command.rb' => [
    { from: 'parse_context(', to: 'parse_release(' },
    { from: 'context:', to: 'release:' },
    { from: 'context: "', to: 'release: "' }
  ],

  'lib/ace/taskflow/commands/idea_command.rb' => [
    { from: 'parse_context(', to: 'parse_release(' },
    { from: 'context_name(context)', to: 'release_name(release)' },
    { from: 'def parse_context(', to: 'def parse_release(' },
    { from: 'def context_name(context)', to: 'def release_name(release)' },
    { from: 'case context', to: 'case release' }
  ],

  'lib/ace/taskflow/commands/retro_command.rb' => [
    { from: 'parse_context(', to: 'parse_release(' },
    { from: 'context_name(context)', to: 'release_name(release)' },
    { from: 'def parse_context(', to: 'def parse_release(' },
    { from: 'def context_name(context)', to: 'def release_name(release)' },
    { from: 'context:', to: 'release:' },
    { from: 'context = ', to: 'release = ' }
  ],

  'lib/ace/taskflow/commands/retros_command.rb' => [
    { from: 'context_name(context)', to: 'release_name(release)' },
    { from: 'def context_name(context)', to: 'def release_name(release)' },
    { from: 'options[:context]', to: 'options[:release]' },
    { from: 'context: "', to: 'release: "' },
    { from: 'context = ', to: 'release = ' }
  ],

  # Phase 6: Display Formatters
  'lib/ace/taskflow/molecules/idea_display_formatter.rb' => [
    { from: 'context_name(context)', to: 'release_name(release)' },
    { from: 'def self.context_name(context)', to: 'def self.release_name(release)' },
    { from: '@param context', to: '@param release' },
    { from: 'case context', to: 'case release' }
  ],

  # Phase 8: Other Organisms
  'lib/ace/taskflow/organisms/task_scheduler.rb' => [
    { from: 'context: "all"', to: 'release: "all"' },
    { from: 'context:', to: 'release:' }
  ],

  'lib/ace/taskflow/organisms/task_migrator.rb' => [
    { from: 'migrate_context(context_path', to: 'migrate_release(release_path' },
    { from: 'def migrate_context(context_path', to: 'def migrate_release(release_path' },
    { from: 'contexts_to_migrate', to: 'releases_to_migrate' },
    { from: 'contexts.each do |context_path|', to: 'releases.each do |release_path|' },
    { from: 'contexts = []', to: 'releases = []' },
    { from: 'contexts <<', to: 'releases <<' },
    { from: '@param context', to: '@param release' }
  ],

  'lib/ace/taskflow/organisms/taskflow_doctor.rb' => [
    { from: 'context = active_release[:name]', to: 'release = active_release[:name]' },
    { from: 'context:', to: 'release:' }
  ],

  # Phase 9: Arg Parsers
  'lib/ace/taskflow/molecules/idea_arg_parser.rb' => [
    { from: 'parse_context(', to: 'parse_release(' },
    { from: 'def self.parse_context(', to: 'def self.parse_release(' }
  ],

  'lib/ace/taskflow/molecules/task_arg_parser.rb' => [
    { from: '[:context]', to: '[:release]' },
    { from: 'context:', to: 'release:' },
    { from: 'context = ', to: 'release = ' }
  ],

  'lib/ace/taskflow/molecules/tasks_arg_parser.rb' => [
    { from: 'filters[:context]', to: 'filters[:release]' }
  ]
}

# Test files - common patterns
TEST_PATTERNS = [
  { from: '.list_tasks(context:', to: '.list_tasks(release:' },
  { from: '.create_task("', to: '.create_task("' }, # Keep but update context: param
  { from: ', context: "', to: ', release: "' },
  { from: '.get_next_task(context:', to: '.get_next_task(release:' },
  { from: '.get_statistics(context:', to: '.get_statistics(release:' },
  { from: '.get_recent_tasks(context:', to: '.get_recent_tasks(release:' },
  { from: 'context: "v.', to: 'release: "v.' },
  { from: 'context: "current"', to: 'release: "current"' },
  { from: 'context: "backlog"', to: 'release: "backlog"' },
  { from: 'context: "all"', to: 'release: "all"' },
  { from: '{ id: "task.001", context:', to: '{ id: "task.001", release:' },
  { from: 't[:context]', to: 't[:release]' },
  { from: 'task[:context]', to: 'task[:release]' },
  { from: 'idea[:context]', to: 'idea[:release]' },
  { from: '[:context]', to: '[:release]' },
  { from: '.context', to: '.release' },  # For model attributes
  { from: 'assert_equal "current", preset[:context]', to: 'assert_equal "current", preset[:release]' },
  { from: 'assert_equal "current", result[:context]', to: 'assert_equal "current", result[:release]' }
]

def update_file(file_path, patterns)
  return unless File.exist?(file_path)

  content = File.read(file_path)
  original_content = content.dup

  patterns.each do |pattern|
    content.gsub!(pattern[:from], pattern[:to])
  end

  if content != original_content
    File.write(file_path, content)
    puts "✓ Updated: #{file_path}"
    true
  else
    puts "  No changes: #{file_path}"
    false
  end
end

puts "Starting context → release rename..."
puts "=" * 60

# Update main source files
puts "\nUpdating source files..."
updated_count = 0
UPDATES.each do |file, patterns|
  full_path = File.join("/Users/mc/Ps/ace-meta/.ace-wt/task.088/ace-taskflow", file)
  updated_count += 1 if update_file(full_path, patterns)
end

# Update test files
puts "\nUpdating test files..."
Dir.glob("/Users/mc/Ps/ace-meta/.ace-wt/task.088/ace-taskflow/test/**/*_test.rb").each do |test_file|
  updated_count += 1 if update_file(test_file, TEST_PATTERNS)
end

puts "\n" + "=" * 60
puts "Update complete! #{updated_count} files modified."
puts "\nNext steps:"
puts "1. Run: bundle exec rake test"
puts "2. Verify key commands work:"
puts "   - ace-taskflow tasks all --release v.0.9.0"
puts "   - ace-taskflow task create 'Test' --release backlog"
puts "3. Check that special values work: all, backlog, current, v.x.x.x"