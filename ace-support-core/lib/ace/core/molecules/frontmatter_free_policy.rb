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

          absolute_path = canonical_path(path)
          root = canonical_path(project_root || Dir.pwd)
          relative_path = relative_path_under(absolute_path, root) || absolute_path

          patterns.any? do |pattern|
            File.fnmatch?(pattern, relative_path, MATCH_FLAGS) ||
              File.fnmatch?(pattern, absolute_path, MATCH_FLAGS)
          end
        end

        def self.canonical_path(path)
          expanded = File.expand_path(path)
          return File.realpath(expanded) if File.exist?(expanded)

          canonical_missing_path(expanded)
        rescue
          File.expand_path(path)
        end

        def self.canonical_missing_path(path)
          parent = path
          suffix = []
          until File.exist?(parent) || parent == File.dirname(parent)
            suffix.unshift(File.basename(parent))
            parent = File.dirname(parent)
          end
          return path unless File.exist?(parent)

          File.join(File.realpath(parent), *suffix)
        end

        def self.relative_path_under(path, root)
          return "." if path == root

          prefix = "#{root}#{File::SEPARATOR}"
          return path.delete_prefix(prefix) if path.start_with?(prefix)

          nil
        end
      end
    end
  end
end
