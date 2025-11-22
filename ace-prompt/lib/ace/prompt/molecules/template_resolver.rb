# frozen_string_literal: true

module Ace
  module Prompt
    module Molecules
      # Resolve tmpl:// protocols via ace-nav
      class TemplateResolver
        class TemplateNotFoundError < Ace::Prompt::Error; end

        # Resolve template protocol to file path
        # @param protocol_uri [String] Template URI (e.g., "tmpl://ace-prompt/base-prompt")
        # @return [String] Resolved file path
        # @raise [TemplateNotFoundError] if template not found
        def self.resolve(protocol_uri)
          return protocol_uri unless protocol_uri.start_with?("tmpl://")

          # Use ace-nav to resolve protocol
          cmd = "ace-nav '#{protocol_uri}' 2>&1"
          output = `#{cmd}`.strip

          if $?.success? && File.exist?(output)
            output
          else
            raise TemplateNotFoundError, "Template not found: #{protocol_uri}"
          end
        rescue => e
          raise TemplateNotFoundError, "Failed to resolve template: #{e.message}"
        end

        # Check if ace-nav is available
        # @return [Boolean] True if ace-nav command exists
        def self.available?
          system("which ace-nav > /dev/null 2>&1")
        end
      end
    end
  end
end
