# frozen_string_literal: true

require "yaml"

module Ace
  module Review
    module Molecules
      # Loads provider catalogs from config cascade and resolves provider entries.
      #
      # Catalog files live at review/providers/<class>.yml in the config cascade.
      # Two classes are supported: llm and tools-lint.
      #
      # Each catalog entry is a named group mapping to an array of provider IDs.
      # The first item in the array is the default.
      #
      # @example Loading and resolving providers
      #   catalog = ProviderCatalog.new(project_root: "/my/project")
      #   entries = catalog.resolve(provider_class: "llm", names: ["review-fast"])
      #   # => [{"name" => "review-fast", "model" => "codex:spark@review-fast"}]
      #
      class ProviderCatalog
        SUPPORTED_CLASSES = %w[llm tools-lint].freeze
        FIELD_KEYS = { "llm" => "model", "tools-lint" => "tool" }.freeze

        def initialize(project_root: nil)
          @project_root = project_root || find_project_root
          @catalogs = {}
        end

        # Resolve catalog entries for a given provider class and list of names.
        #
        # For the "llm" class, names that don't match any catalog entry are treated
        # as inline model IDs (e.g., "codex:codex@review-deep").
        #
        # Each catalog group may contain multiple provider IDs (multi-model groups).
        # Each ID produces a separate entry, all sharing the same group name.
        #
        # @param provider_class [String] "llm" or "tools-lint"
        # @param names [Array<String>] catalog entry names or inline model IDs
        # @return [Array<Hash>] resolved provider entries (each has "name" + class-specific keys)
        # @raise [ArgumentError] if a tools-lint name is not found in the catalog
        def resolve(provider_class:, names:)
          catalog = load_catalog(provider_class)
          field_key = FIELD_KEYS.fetch(provider_class)
          names.flat_map do |name|
            if catalog.key?(name)
              Array(catalog[name]).map { |id| { "name" => name, field_key => id } }
            elsif provider_class == "llm"
              # Treat as inline model ID
              [{ "name" => name, "model" => name }]
            else
              raise ArgumentError, "Unknown provider '#{name}' for class '#{provider_class}'. " \
                                   "Available: #{catalog.keys.join(', ')}"
            end
          end
        end

        # Return all entry names for a given provider class.
        #
        # @param provider_class [String] "llm" or "tools-lint"
        # @return [Array<String>] catalog entry names
        def entry_names(provider_class:)
          load_catalog(provider_class).keys
        end

        private

        def load_catalog(provider_class)
          @catalogs[provider_class] ||= load_catalog_file(provider_class)
        end

        def load_catalog_file(provider_class)
          catalog_file = find_catalog_file(provider_class)
          return {} unless catalog_file && File.exist?(catalog_file)

          raw = YAML.safe_load(File.read(catalog_file), permitted_classes: [Symbol]) || {}
          raw.each_with_object({}) do |(key, value), result|
            result[key.to_s] = Array(value)
          end
        rescue StandardError
          {}
        end

        def find_catalog_file(provider_class)
          finder = Ace::Support::Config.finder
          file = finder.find_file("review/providers/#{provider_class}.yml")
          return file if file && File.exist?(file)

          fallback = File.join(@project_root, ".ace/review/providers/#{provider_class}.yml")
          fallback if File.exist?(fallback)
        rescue StandardError
          nil
        end

        def find_project_root
          Ace::Support::Config.find_project_root || Dir.pwd
        rescue StandardError
          Dir.pwd
        end
      end
    end
  end
end
