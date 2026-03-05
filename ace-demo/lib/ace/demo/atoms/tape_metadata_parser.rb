# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module TapeMetadataParser
        module_function

        def parse(content)
          metadata = {}
          seen_metadata = false

          content.each_line do |line|
            stripped = line.strip

            if stripped.empty?
              break if seen_metadata

              next
            end

            break unless stripped.start_with?("#")

            match = stripped.match(/\A#\s*([^:]+):\s*(.*)\z/)
            next unless match

            key = normalize_key(match[1])
            metadata[key] = match[2].strip
            seen_metadata = true
          end

          metadata
        end

        def normalize_key(key)
          key.to_s.strip.downcase.gsub(/\s+/, "_")
        end
        private_class_method :normalize_key
      end
    end
  end
end
