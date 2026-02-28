# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # Extracts the first H1 heading from markdown body content.
        class TitleExtractor
          # Extract title from the first `# H1` heading in body content
          # @param body [String] Markdown body content
          # @return [String, nil] Extracted title or nil if none found
          def self.extract(body)
            return nil if body.nil? || body.empty?

            match = body.match(/^#\s+(.+)$/)
            match ? match[1].strip : nil
          end
        end
      end
    end
  end
end
