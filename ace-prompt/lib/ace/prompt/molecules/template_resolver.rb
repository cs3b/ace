# frozen_string_literal: true

begin
  require "ace/nav"
  require "ace/nav/organisms/navigation_engine"
rescue LoadError
  # ace-nav not available
end

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

          # Try ace-nav Ruby API first (security fix)
          if available?
            begin
              engine = Ace::Nav::Organisms::NavigationEngine.new
              resolved_path = engine.resolve(protocol_uri)
              return resolved_path if resolved_path && File.exist?(resolved_path)
            rescue => e
              # Fall through to local resolution
            end
          end

          # Fallback: resolve from gem directly for ace-prompt templates
          if protocol_uri.start_with?("tmpl://ace-prompt/")
            template_name = protocol_uri.sub("tmpl://ace-prompt/", "")
            gem_path = File.expand_path("../../../../handbook/templates", __FILE__)
            template_path = File.join(gem_path, "#{template_name}.template.md")

            return template_path if File.exist?(template_path)
          end

          raise TemplateNotFoundError, "Template not found: #{protocol_uri}"
        rescue TemplateNotFoundError
          raise
        rescue => e
          raise TemplateNotFoundError, "Failed to resolve template: #{e.message}"
        end

        # Check if ace-nav is available
        # @return [Boolean] True if ace-nav gem is loaded
        def self.available?
          defined?(Ace::Nav::Organisms::NavigationEngine)
        end
      end
    end
  end
end
