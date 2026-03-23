# frozen_string_literal: true

require "yaml"
require "date"
require "securerandom"

module Ace
  module Support
    module Models
      module Atoms
        # Reads provider configuration files with cascade support:
        # - Project: .ace/llm/providers/
        # - User: ~/.ace/llm/providers/
        # - Gem: ace-llm/.ace-defaults/llm/providers/ (single source of truth)
        class ProviderConfigReader
          class << self
            # Find all provider config directories in cascade order
            # @param config_dir [String, nil] Override config directory
            # @return [Array<String>] List of directories (project first, then user, then gem)
            def config_directories(config_dir: nil)
              dirs = []

              if config_dir
                dirs << config_dir if Dir.exist?(config_dir)
              else
                # Project-level config
                project_dir = project_config_dir
                dirs << project_dir if project_dir && Dir.exist?(project_dir)

                # User-level config
                user_dir = user_config_dir
                dirs << user_dir if user_dir && Dir.exist?(user_dir)

                # Gem-level config (ace-llm/providers/)
                gem_dir = gem_config_dir
                dirs << gem_dir if gem_dir && Dir.exist?(gem_dir)
              end

              dirs
            end

            # Find the first writable config directory
            # @param config_dir [String, nil] Override config directory
            # @return [String, nil] Writable directory or nil
            def writable_config_directory(config_dir: nil)
              dirs = config_directories(config_dir: config_dir)
              dirs.find { |dir| writable?(dir) }
            end

            # Read all provider configs from cascade
            # @param config_dir [String, nil] Override config directory
            # @return [Hash<String, Hash>] Provider name => config hash
            def read_all(config_dir: nil)
              configs = {}

              # Read from all directories (later wins for same provider)
              config_directories(config_dir: config_dir).reverse_each do |dir|
                read_directory(dir).each do |name, config|
                  configs[name] = config
                end
              end

              configs
            end

            # Read provider configs from a specific directory
            # @param dir [String] Directory path
            # @return [Hash<String, Hash>] Provider name => config hash
            def read_directory(dir)
              configs = {}

              Dir.glob(File.join(dir, "*.yml")).each do |file|
                name = File.basename(file, ".yml")
                next if name == "template" || name.end_with?(".example")

                config = read_file(file)
                configs[name] = config.merge("_source_file" => file) if config
              end

              configs
            end

            # Read a single provider config file
            # @param path [String] File path
            # @return [Hash, nil] Parsed YAML or nil on error
            def read_file(path)
              return nil unless File.exist?(path)

              content = File.read(path)
              YAML.safe_load(content, permitted_classes: [Symbol, Date])
            rescue Errno::EACCES => e
              raise CacheError, "Permission denied reading #{path}: #{e.message}"
            rescue Psych::SyntaxError => e
              raise ConfigError, "Invalid YAML in #{path}: #{e.message}"
            end

            # Extract models list from a provider config
            # @param config [Hash] Provider config
            # @return [Array<String>] List of model IDs
            def extract_models(config)
              models = config["models"]
              return [] unless models

              case models
              when Array
                models
              when Hash
                models.keys
              else
                []
              end
            end

            # Extract models.dev provider ID from config
            # Falls back to provider name if not specified
            # @param config [Hash] Provider config
            # @return [String] models.dev provider ID
            def extract_models_dev_id(config)
              config["models_dev_id"] || config["name"]
            end

            # Extract last_synced date from config
            # @param config [Hash] Provider config
            # @return [Date, nil] Last sync date or nil
            def extract_last_synced(config)
              value = config["last_synced"]
              return nil unless value

              case value
              when Date
                value
              when String
                Date.parse(value)
              end
            rescue ArgumentError
              nil
            end

            private

            def project_config_dir
              # Use ace-core if available and has project_root method
              if defined?(Ace::Core) && Ace::Core.respond_to?(:project_root)
                project_root = Ace::Core.project_root
                return File.join(project_root, ".ace", "llm", "providers") if project_root
              end

              # Fallback: traverse up from current dir looking for .ace or .git
              find_project_root_dir
            end

            def user_config_dir
              home = ENV["HOME"]
              return nil unless home

              File.join(home, ".ace", "llm", "providers")
            end

            def gem_config_dir
              # Find ace-llm gem's providers directory (from .ace-defaults/ - single source of truth)
              if defined?(Ace::LLM)
                # Try to find via gem spec
                spec = begin
                  Gem::Specification.find_by_name("ace-llm")
                rescue
                  nil
                end
                return File.join(spec.gem_dir, ".ace-defaults", "llm", "providers") if spec
              end

              # Fallback: look relative to this gem in mono-repo development
              # This enables development without installing ace-llm as a gem.
              # Production/installed gem use goes through Gem::Specification above.
              ace_llm_path = find_ace_llm_path
              File.join(ace_llm_path, ".ace-defaults", "llm", "providers") if ace_llm_path
            end

            def find_project_root_dir
              dir = Dir.pwd
              while dir != "/"
                if Dir.exist?(File.join(dir, ".ace")) || Dir.exist?(File.join(dir, ".git"))
                  return File.join(dir, ".ace", "llm", "providers")
                end
                dir = File.dirname(dir)
              end
              nil
            end

            def find_ace_llm_path
              # Look in common locations relative to this gem
              candidates = [
                File.expand_path("../../../../../../ace-llm", __FILE__),
                File.expand_path("../../../../../../../ace-llm", __FILE__)
              ]

              candidates.find { |path| Dir.exist?(path) }
            end

            def writable?(dir)
              return false unless Dir.exist?(dir)

              # Initialize test_file before begin block to ensure it's available in ensure
              test_file = File.join(dir, ".write_test_#{Process.pid}_#{SecureRandom.hex(4)}")
              begin
                File.write(test_file, "test")
                true
              rescue Errno::EACCES, Errno::EROFS
                false
              ensure
                File.delete(test_file) if File.exist?(test_file)
              end
            end
          end
        end
      end
    end
  end
end
