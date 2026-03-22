# frozen_string_literal: true

module Ace
  module Core
    module Molecules
      # Shared frontmatter-free policy for path matching and config defaults.
      class FrontmatterFreePolicy
        MATCH_FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH
        DEFAULT_PATTERNS = ["README.md", "*/README.md"].freeze

        def self.patterns(config:, key: "frontmatter_free", default_patterns: DEFAULT_PATTERNS)
          patterns = config[key]
          return patterns if patterns.is_a?(Array) && !patterns.empty?

          default_patterns
        end

        def self.match?(path, patterns:, project_root: Dir.pwd)
          return false if path.nil? || path.to_s.empty?
          return false if patterns.nil? || patterns.empty?

          absolute_path = File.expand_path(path)
          root = File.expand_path(project_root || Dir.pwd)
          relative_path = absolute_path.sub(/^#{Regexp.escape(root)}\/?/, "")

          patterns.any? do |pattern|
            File.fnmatch?(pattern, relative_path, MATCH_FLAGS) ||
              File.fnmatch?(pattern, absolute_path, MATCH_FLAGS)
          end
        end
      end
    end
  end
end
