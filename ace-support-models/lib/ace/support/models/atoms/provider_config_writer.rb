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
              config = read_config(path)
              config["models"] = Array(models)
              write(path, config)
              true
            end

            # Write a complete config file
            # @param path [String] Path to config file
            # @param config [Hash] Config hash
            # @return [Boolean] true on success
            def write(path, config)
              ensure_directory(File.dirname(path))
              content = format_config(config)
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
              config = read_config(path)
              config["last_synced"] = date
              write(path, config)
              true
            end

            # Update both models and last_synced in one operation
            # @param path [String] Path to config file
            # @param models [Array<String>] New list of model IDs
            # @param date [Date] Date to set for last_synced
            # @return [Boolean] true on success
            def update_models_and_sync_date(path, models, date = Date.today, limits: nil)
              config = read_config(path)
              config["models"] = Array(models)
              config["last_synced"] = date

              unless limits.nil?
                normalized_limits = normalize_limits(limits)
                if normalized_limits.empty?
                  config.delete("limits")
                else
                  config["limits"] = normalized_limits
                end
                config.delete("context_limit")
              end

              write(path, config)
              true
            end

            private

            def write_file(path, content)
              # Validate YAML before writing to catch regex manipulation errors
              YAML.safe_load(content, permitted_classes: [Symbol, Date], aliases: true)
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

            def read_config(path)
              raise ConfigError, "Config file not found: #{path}" unless File.exist?(path)

              YAML.safe_load(File.read(path), permitted_classes: [Symbol, Date], aliases: true) || {}
            rescue Errno::EACCES => e
              raise ConfigError, "Permission denied reading #{path}: #{e.message}"
            rescue Psych::SyntaxError => e
              raise ConfigError, "Invalid YAML in #{path}: #{e.message}"
            end

            def normalize_limits(limits)
              return {} unless limits.is_a?(Hash)

              normalized = {}

              default_limits = normalize_limit_entry(limits["default"] || limits[:default])
              normalized["default"] = default_limits if default_limits.any?

              models = limits["models"] || limits[:models]
              normalized_models = normalize_model_limits(models)
              normalized["models"] = normalized_models if normalized_models.any?

              normalized
            end

            def normalize_model_limits(models)
              return {} unless models.is_a?(Hash)

              models.each_with_object({}) do |(model, entry), normalized|
                next if model.to_s.strip.empty?

                normalized_entry = normalize_limit_entry(entry)
                normalized[model.to_s] = normalized_entry if normalized_entry.any?
              end.sort.to_h
            end

            def normalize_limit_entry(entry)
              return {} unless entry.is_a?(Hash)

              normalized = {}

              context = normalize_limit_value(entry["context"] || entry[:context])
              output = normalize_limit_value(entry["output"] || entry[:output])

              normalized["context"] = context unless context.nil?
              normalized["output"] = output unless output.nil?
              normalized
            end

            def normalize_limit_value(value)
              return nil if value.nil?

              Integer(value)
            rescue ArgumentError, TypeError
              nil
            end

            def format_config(config)
              YAML.dump(canonicalize_config(config)).sub(/\A---\n/, "")
            end

            def canonicalize_config(config)
              config = config.dup
              config.delete("_source_file")

              ordered = {}
              preferred_order = %w[
                name
                last_synced
                class
                gem
                models_dev_id
                models
                limits
                aliases
                api_key
                capabilities
                default_options
                backends
                endpoint
                version
              ]

              preferred_order.each do |key|
                ordered[key] = config.delete(key) if config.key?(key)
              end

              config.each do |key, value|
                ordered[key] = value
              end

              ordered
            end
          end
        end
      end
    end
  end
end
