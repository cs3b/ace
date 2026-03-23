# frozen_string_literal: true

require "yaml"
require "fileutils"
require "date"

module Ace
  module Support
    module Models
      module Atoms
        # Writes provider configuration files, preserving structure
        # Updates only the models: section while keeping other fields intact
        class ProviderConfigWriter
          class << self
            # Update the models list in a provider config file
            # @param path [String] Path to config file
            # @param models [Array<String>] New list of model IDs
            # @return [Boolean] true on success
            # @raise [ConfigError] on write errors
            def update_models(path, models)
              content = read_file_content(path)
              raise ConfigError, "Config file not found: #{path}" unless content

              updated_content = replace_models_section(content, models)
              write_file(path, updated_content)
              true
            end

            # Write a complete config file
            # @param path [String] Path to config file
            # @param config [Hash] Config hash
            # @return [Boolean] true on success
            def write(path, config)
              ensure_directory(File.dirname(path))
              content = YAML.dump(config)
              write_file(path, content)
              true
            end

            # Create a backup of a config file
            # @param path [String] Path to config file
            # @return [String] Path to backup file
            def backup(path)
              return nil unless File.exist?(path)

              timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
              backup_path = "#{path}.backup.#{timestamp}"
              FileUtils.cp(path, backup_path)
              backup_path
            end

            # Update the last_synced field in a provider config file
            # @param path [String] Path to config file
            # @param date [Date] Date to set (defaults to today)
            # @return [Boolean] true on success
            # @raise [ConfigError] on write errors
            def update_last_synced(path, date = Date.today)
              content = read_file_content(path)
              raise ConfigError, "Config file not found: #{path}" unless content

              updated_content = replace_or_add_field(content, "last_synced", date.to_s)
              write_file(path, updated_content)
              true
            end

            # Update both models and last_synced in one operation
            # @param path [String] Path to config file
            # @param models [Array<String>] New list of model IDs
            # @param date [Date] Date to set for last_synced
            # @return [Boolean] true on success
            def update_models_and_sync_date(path, models, date = Date.today)
              content = read_file_content(path)
              raise ConfigError, "Config file not found: #{path}" unless content

              updated_content = replace_models_section(content, models)
              updated_content = replace_or_add_field(updated_content, "last_synced", date.to_s)
              write_file(path, updated_content)
              true
            end

            private

            def read_file_content(path)
              return nil unless File.exist?(path)

              File.read(path)
            rescue Errno::EACCES => e
              raise ConfigError, "Permission denied reading #{path}: #{e.message}"
            end

            def write_file(path, content)
              # Validate YAML before writing to catch regex manipulation errors
              YAML.safe_load(content, permitted_classes: [Symbol, Date])
              File.write(path, content)
            rescue Psych::SyntaxError => e
              raise ConfigError, "Generated invalid YAML for #{path}: #{e.message}"
            rescue Errno::EACCES => e
              raise ConfigError, "Permission denied writing #{path}: #{e.message}"
            rescue Errno::ENOSPC => e
              raise ConfigError, "No space left writing #{path}: #{e.message}"
            rescue Errno::EROFS => e
              raise ConfigError, "Read-only filesystem: #{path}: #{e.message}"
            end

            def ensure_directory(dir)
              FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
            rescue Errno::EACCES => e
              raise ConfigError, "Permission denied creating directory #{dir}: #{e.message}"
            end

            # Replace the models section in YAML content while preserving structure
            # @param content [String] Original YAML content
            # @param models [Array<String>] New models list
            # @return [String] Updated content
            # @raise [ConfigError] if unsupported YAML styles are detected
            def replace_models_section(content, models)
              # Check for flow-style arrays which are not supported
              if /^\s*models:\s*\[/m.match?(content)
                raise ConfigError, "Flow-style arrays (models: [...]) are not supported for auto-update. " \
                                   "Please convert to block style (models: followed by list items)."
              end

              # Check for inline comments on models: line which are not preserved
              if /^\s*models:\s*#/m.match?(content)
                raise ConfigError, "Inline comments on 'models:' line (e.g., 'models: # comment') are not supported. " \
                                   "Please move the comment to a separate line above 'models:'."
              end

              lines = content.lines
              result = []
              in_models_section = false
              models_base_indent = 0

              lines.each do |line|
                # Detect start of models section (with or without items on same line)
                if line =~ /^(\s*)models:\s*$/
                  in_models_section = true
                  models_base_indent = $1.length
                  result << line

                  # Add new models with standard YAML indent
                  models.each do |model|
                    result << "#{" " * (models_base_indent + 2)}- #{model}\n"
                  end
                  next
                end

                # If in models section, skip old model items
                if in_models_section
                  # Check if this line is a list item (model entry)
                  if line =~ /^(\s*)-\s+/
                    item_indent = $1.length
                    # Skip if it's at the expected indent for models (base + 0 or base + 2)
                    if item_indent == models_base_indent || item_indent == models_base_indent + 2
                      next
                    end
                  end

                  # Empty line - keep but stay in models section
                  if line.strip.empty?
                    result << line
                    next
                  end

                  # A new key at base level (not indented more) ends models section
                  if line =~ /^(\s*)\S/
                    current_indent = $1.length
                    if current_indent <= models_base_indent
                      in_models_section = false
                      result << line
                    end
                    # Otherwise skip (shouldn't happen for well-formed YAML)
                  end
                  next
                end

                result << line
              end

              result.join
            end

            # Replace or add a field in YAML content
            # @param content [String] Original YAML content
            # @param field_name [String] Field name to replace or add
            # @param value [String] New value
            # @return [String] Updated content
            def replace_or_add_field(content, field_name, value)
              lines = content.lines

              # Try to find and replace existing field
              field_found = false
              result = lines.map do |line|
                if line =~ /^(\s*)#{Regexp.escape(field_name)}:\s*(.*)$/
                  field_found = true
                  "#{$1}#{field_name}: #{value}\n"
                else
                  line
                end
              end

              # If field not found, add it after the name or first line
              unless field_found
                insert_index = 0
                result.each_with_index do |line, idx|
                  if /^name:/.match?(line)
                    insert_index = idx + 1
                    break
                  end
                end
                # If no name field, add after first non-comment, non-blank line
                if insert_index == 0
                  result.each_with_index do |line, idx|
                    next if line.strip.empty? || line.strip.start_with?("#") || line.strip.start_with?("---")

                    insert_index = idx + 1
                    break
                  end
                end
                result.insert(insert_index, "#{field_name}: #{value}\n")
              end

              result.join
            end
          end
        end
      end
    end
  end
end
