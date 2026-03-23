# frozen_string_literal: true

module Ace
  module Support
    module Nav
      module Atoms
        # Infers file extensions for protocol-based resource resolution
        # Implements DWIM (Do What I Mean) extension inference
        class ExtensionInferrer
          # Default extension inference order when not configured
          DEFAULT_FALLBACK_ORDER = %w[
            protocol_shorthand
            protocol_full
            generic_markdown
            bare
          ].freeze

          class << self
            # Generate candidate extensions for a pattern based on protocol config
            # @param pattern [String] The search pattern (e.g., "markdown-style")
            # @param protocol_extensions [Array<String>] Protocol-specific extensions (e.g., [".g.md", ".guide.md"])
            # @param enabled [Boolean] Whether extension inference is enabled
            # @param fallback_order [Array<String>] Order of extension types to try
            # @return [Array<String>] List of candidate patterns to try
            def infer_extensions(pattern, protocol_extensions: [], enabled: true, fallback_order: DEFAULT_FALLBACK_ORDER)
              return [pattern] unless enabled
              return [pattern] if pattern.empty?

              # Guard against nil fallback_order
              fallback_order ||= DEFAULT_FALLBACK_ORDER

              # Extract shorthand extensions from protocol extensions
              # e.g., from [".g.md", ".guide.md"] extract [".g"]
              shorthand_extensions = extract_shorthand_extensions(protocol_extensions)

              candidates = []

              fallback_order.each do |fallback_type|
                case fallback_type
                when "protocol_shorthand"
                  # Try with shorthand extensions first (e.g., ".g")
                  shorthand_extensions.each do |ext|
                    candidate = "#{pattern}#{ext}"
                    candidates << candidate unless candidates.include?(candidate)
                  end
                when "protocol_full"
                  # Try with full protocol extensions (e.g., ".g.md", ".guide.md")
                  protocol_extensions.each do |ext|
                    candidate = "#{pattern}#{ext}"
                    candidates << candidate unless candidates.include?(candidate)
                  end
                when "generic_markdown"
                  # Try with generic markdown extension (e.g., ".md")
                  candidate = "#{pattern}.md"
                  candidates << candidate unless candidates.include?(candidate)
                when "bare"
                  # Try with no extension
                  candidates << pattern unless candidates.include?(pattern)
                end
              end

              candidates
            end

            # Check if a pattern already includes an extension from the list
            # @param pattern [String] The pattern to check
            # @param extensions [Array<String>] List of extensions to check against
            # @return [Boolean] True if pattern ends with any of the extensions
            def has_extension?(pattern, extensions)
              return false if pattern.nil? || pattern.empty?
              return false if extensions.nil? || extensions.empty?

              extensions.any? { |ext| pattern.end_with?(ext) }
            end

            # Extract shorthand extensions from full protocol extensions
            # e.g., from [".g.md", ".guide.md"] extract [".g"]
            # @param protocol_extensions [Array<String>] Full protocol extensions
            # @return [Array<String>] Shorthand extensions
            def extract_shorthand_extensions(protocol_extensions)
              return [] if protocol_extensions.nil? || protocol_extensions.empty?

              shorthand_extensions = []

              protocol_extensions.each do |ext|
                # Extract the part before the first dot after the initial dot
                # e.g., ".g.md" -> ".g", ".guide.md" -> ".guide"
                parts = ext.split(".")
                if parts.length >= 2
                  shorthand = ".#{parts[1]}"
                  shorthand_extensions << shorthand unless shorthand_extensions.include?(shorthand)
                end
              end

              shorthand_extensions
            end

            # Get the base pattern without any extension
            # @param pattern [String] The pattern to process
            # @param extensions [Array<String>] List of extensions to strip
            # @return [String] Pattern without extension
            def strip_extension(pattern, extensions)
              return pattern if extensions.nil? || extensions.empty?

              result = pattern.dup
              extensions.each do |ext|
                result = result.sub(/#{Regexp.escape(ext)}\z/, "") if result.end_with?(ext)
              end

              result
            end
          end

          # Instance method wrappers for backwards compatibility (deprecated)
          def infer_extensions(...)
            self.class.infer_extensions(...)
          end

          def has_extension?(...)
            self.class.has_extension?(...)
          end

          def extract_shorthand_extensions(...)
            self.class.extract_shorthand_extensions(...)
          end

          def strip_extension(...)
            self.class.strip_extension(...)
          end
        end
      end
    end
  end
end
