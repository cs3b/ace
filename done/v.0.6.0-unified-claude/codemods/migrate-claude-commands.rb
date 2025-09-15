#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to migrate Claude commands from subdirectory structure to flat structure
# Adds origin metadata to track command source

require 'pathname'
require 'fileutils'
require 'yaml'

class ClaudeCommandMigrator
  def initialize(commands_dir)
    @commands_dir = Pathname.new(commands_dir)
    @custom_dir = @commands_dir / '_custom'
    @generated_dir = @commands_dir / '_generated'
    @migrated = { custom: 0, generated: 0, errors: [] }
  end

  def migrate!
    puts "Starting Claude commands migration..."
    puts "Commands directory: #{@commands_dir}"
    puts

    # Migrate custom commands
    if @custom_dir.exist?
      puts "Migrating custom commands..."
      migrate_custom_commands
    end

    # Migrate generated commands
    if @generated_dir.exist?
      puts "\nMigrating generated commands..."
      migrate_generated_commands
    end

    # Report results
    puts "\nMigration Summary:"
    puts "  Custom commands migrated: #{@migrated[:custom]}"
    puts "  Generated commands migrated: #{@migrated[:generated]}"
    if @migrated[:errors].any?
      puts "  Errors encountered:"
      @migrated[:errors].each { |error| puts "    - #{error}" }
    end
  end

  private

  def migrate_custom_commands
    Dir.glob(@custom_dir / '*.md').each do |file_path|
      begin
        migrate_custom_command(file_path)
      rescue => e
        @migrated[:errors] << "#{File.basename(file_path)}: #{e.message}"
      end
    end
  end

  def migrate_custom_command(file_path)
    pathname = Pathname.new(file_path)
    filename = pathname.basename
    target_path = @commands_dir / filename

    # Read the original content
    content = pathname.read

    # Add YAML frontmatter if it doesn't exist
    unless content.start_with?("---\n")
      # Extract command name from filename (without .md)
      command_name = filename.to_s.gsub('.md', '').gsub('-', ' ').split.map(&:capitalize).join(' ')
      
      # Build frontmatter
      frontmatter = [
        "---",
        "origin: custom",
        "description: #{command_name}",
        "---",
        ""
      ].join("\n")

      content = frontmatter + content
    else
      # Add origin to existing frontmatter
      content = add_origin_to_frontmatter(content, 'custom')
    end

    # Write to flat structure
    target_path.write(content)
    puts "  ✓ Migrated: #{filename}"
    @migrated[:custom] += 1
  end

  def migrate_generated_commands
    Dir.glob(@generated_dir / '*.md').each do |file_path|
      begin
        migrate_generated_command(file_path)
      rescue => e
        @migrated[:errors] << "#{File.basename(file_path)}: #{e.message}"
      end
    end
  end

  def migrate_generated_command(file_path)
    pathname = Pathname.new(file_path)
    filename = pathname.basename
    target_path = @commands_dir / filename

    # Read the original content
    content = pathname.read

    # Add origin to existing frontmatter
    content = add_origin_to_frontmatter(content, 'generated')

    # Write to flat structure
    target_path.write(content)
    puts "  ✓ Migrated: #{filename}"
    @migrated[:generated] += 1
  end

  def add_origin_to_frontmatter(content, origin)
    # Extract frontmatter and body
    if content =~ /\A---\n(.*?)\n---\n(.*)$/m
      yaml_content = $1
      body = $2

      # Parse YAML
      begin
        data = YAML.safe_load(yaml_content) || {}
      rescue
        data = {}
      end

      # Add origin field if not present
      data['origin'] ||= origin

      # Rebuild content with ordered keys
      ordered_keys = ['origin', 'description', 'allowed-tools', 'argument-hint', 'model']
      yaml_lines = ["---"]
      
      ordered_keys.each do |key|
        if data[key]
          if key == 'argument-hint'
            yaml_lines << "#{key}: \"#{data[key]}\""
          else
            yaml_lines << "#{key}: #{data[key]}"
          end
        end
      end

      # Add any other keys not in our ordered list
      data.each do |key, value|
        unless ordered_keys.include?(key)
          yaml_lines << "#{key}: #{value}"
        end
      end

      yaml_lines << "---"
      yaml_lines.join("\n") + "\n" + body
    else
      # No frontmatter found, add it
      frontmatter = [
        "---",
        "origin: #{origin}",
        "---",
        ""
      ].join("\n")
      frontmatter + content
    end
  end
end

# Main execution
if __FILE__ == $0
  commands_dir = ARGV[0] || File.expand_path('../../../.ace/handbook/.integrations/claude/commands', __dir__)
  
  unless File.directory?(commands_dir)
    puts "Error: Commands directory not found: #{commands_dir}"
    exit 1
  end

  migrator = ClaudeCommandMigrator.new(commands_dir)
  migrator.migrate!
end