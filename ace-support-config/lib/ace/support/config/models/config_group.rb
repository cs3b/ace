# frozen_string_literal: true

module Ace
  module Support
    module Config
      module Models
        # ConfigGroup represents a set of files sharing the same effective config
        class ConfigGroup
          # Default scope name when no path rule matches and no distributed config is found
          DEFAULT_SCOPE_NAME = "project default"

          # rule_config: Original path rule config (before cascade merge), used for grouping
          #   - When a path rule matches, this contains only the rule's own overrides
          #   - nil for distributed config matches or project default
          #   - Separates grouping (use rule_config) from message generation (use config)
          attr_reader :name, :source, :config, :rule_config, :files

          def initialize(name:, source:, config:, files: [], rule_config: nil)
            @name = name
            @source = source
            @config = config || {}
            @rule_config = rule_config
            @files = Array(files)
            freeze
          end

          def add_file(file)
            self.class.new(
              name: name,
              source: source,
              config: config,
              rule_config: rule_config,
              files: files + [file]
            )
          end

          def file_count
            files.length
          end

          def ==(other)
            other.is_a?(self.class) &&
              other.name == name &&
              other.source == source &&
              other.config == config &&
              other.rule_config == rule_config &&
              other.files == files
          end

          def inspect
            "#<#{self.class.name} name=#{name.inspect} files=#{files.length}>"
          end
        end
      end
    end
  end
end
