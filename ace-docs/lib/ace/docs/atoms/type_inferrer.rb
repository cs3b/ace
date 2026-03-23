# frozen_string_literal: true

module Ace
  module Docs
    module Atoms
      # Infers document type from file extension and patterns
      # with configurable priority hierarchy
      class TypeInferrer
        # Map of file extensions to document types
        EXTENSION_MAP = {
          ".wf.md" => "workflow",
          ".g.md" => "guide",
          ".template.md" => "template",
          ".api.md" => "api"
        }.freeze

        # Infer type from file extension
        # @param path [String] File path
        # @return [String, nil] Document type or nil
        def self.from_extension(path)
          EXTENSION_MAP.each do |ext, type|
            return type if path.end_with?(ext)
          end
          nil
        end

        # Resolve document type using priority hierarchy:
        # 1. Explicit frontmatter doc-type (highest priority)
        # 2. Config pattern type
        # 3. README basename inference
        # 4. File extension inference (lowest priority)
        #
        # @param path [String] File path
        # @param pattern_type [String, nil] Type from config pattern matching
        # @param frontmatter_type [String, nil] Explicit doc-type from frontmatter
        # @return [String, nil] Resolved document type
        def self.resolve(path, pattern_type: nil, frontmatter_type: nil)
          # Priority 1: Explicit frontmatter (overrides everything)
          return frontmatter_type if frontmatter_type && !frontmatter_type.empty?

          # Priority 2: Config pattern type
          return pattern_type if pattern_type && !pattern_type.empty?

          # Priority 3: Basename inference
          if File.basename(path).casecmp("README.md").zero?
            return "root_readme" if root_readme?(path)

            return "readme"
          end

          # Priority 4: Extension-based inference
          extension_type = from_extension(path)
          return extension_type if extension_type

          nil
        end

        def self.root_readme?(path)
          normalized = path.to_s.sub(%r{\A\./}, "")
          return true if normalized.casecmp("README.md").zero?

          File.expand_path(path.to_s) == File.join(Dir.pwd, "README.md")
        rescue
          false
        end
        private_class_method :root_readme?
      end
    end
  end
end
