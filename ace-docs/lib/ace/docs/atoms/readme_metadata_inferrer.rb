# frozen_string_literal: true

module Ace
  module Docs
    module Atoms
      # Infers metadata for README files managed without frontmatter.
      class ReadmeMetadataInferrer
        def self.infer(path:, content:, last_updated: nil)
          return nil unless File.basename(path).casecmp("README.md").zero?

          title = extract_title(content, path)
          parent = parent_label(path)

          metadata = {
            "doc-type" => "user",
            "purpose" => "User-facing introduction for #{parent}",
            "update" => {"frequency" => "on-change"}
          }

          if last_updated
            metadata["ace-docs"] = {"last-updated" => last_updated.strftime("%Y-%m-%d")}
          end

          metadata["title"] = title
          metadata
        end

        def self.extract_title(content, path)
          match = content.to_s.match(/^#\s+([^\n]+)$/)
          return match[1].strip if match

          parent_label(path)
        end
        private_class_method :extract_title

        def self.parent_label(path)
          parent = File.basename(File.dirname(path.to_s))
          parent.nil? || parent.empty? || parent == "." ? File.basename(Dir.pwd) : parent
        end
        private_class_method :parent_label
      end
    end
  end
end
