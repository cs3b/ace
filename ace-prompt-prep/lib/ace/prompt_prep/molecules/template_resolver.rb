# frozen_string_literal: true

module Ace
  module PromptPrep
    module Molecules
      # Resolves template URIs using ace-nav tmpl:// protocol
      class TemplateResolver
        class << self
          # Resolve a template URI to an absolute file path
          #
          # @param uri [String] Template URI or short form (e.g., "bug" or "tmpl://the-prompt-bug")
          # @return [Hash] Result with :success, :path, :error keys
          def call(uri:)
            # Normalize short form to full URI
            normalized_uri = normalize_template_uri(uri)

            # Try to resolve via ace-nav
            resolved_path = resolve_via_ace_nav(normalized_uri)

            if resolved_path && File.exist?(resolved_path)
              {
                success: true,
                path: resolved_path,
                error: nil
              }
            else
              # Fallback: check for bundled template
              bundled_path = resolve_bundled_template(normalized_uri)
              if bundled_path && File.exist?(bundled_path)
                {
                  success: true,
                  path: bundled_path,
                  error: nil
                }
              else
                {
                  success: false,
                  path: nil,
                  error: "Error: Template not found: #{normalized_uri}"
                }
              end
            end
          rescue => e
            {
              success: false,
              path: nil,
              error: "Error: Failed to resolve template: #{e.message}"
            }
          end

          private

          # Normalize template URI (convert short form to full URI)
          #
          # @param uri [String] Template URI or short form
          # @return [String] Normalized URI
          # @raise [ArgumentError] if URI format is invalid (e.g., contains spaces)
          def normalize_template_uri(uri)
            # If already a full URI, return as-is
            return uri if uri.start_with?("tmpl://")

            # Validate short form before normalization
            validate_uri(uri)

            # Convert short form to full URI
            # e.g., "bug" -> "tmpl://the-prompt-bug"
            "tmpl://the-prompt-#{uri}"
          end

          # Validate URI format - reject spaces, allow valid path characters
          #
          # @param uri [String] Template URI or short form
          # @raise [ArgumentError] if URI contains spaces
          def validate_uri(uri)
            return if uri.start_with?("tmpl://")

            if uri.match?(/\s/)
              raise ArgumentError, "Invalid template URI format (contains spaces): #{uri}"
            end
          end

          # Resolve template using ace-nav Ruby API
          def resolve_via_ace_nav(uri)
            # Try to load ace-nav and use its Ruby API
            require "ace/support/nav/organisms/navigation_engine"

            engine = Ace::Support::Nav::Organisms::NavigationEngine.new
            result = engine.resolve(uri)

            # Return the resolved path if successful
            result[:path] if result && result[:success]
          rescue LoadError => e
            # ace-nav not available, return nil to fall back to bundled templates
            warn "ace-nav not available: #{e.message}" if ENV["DEBUG"]
            nil
          rescue => e
            # Log error but don't fail, fall back to bundled templates
            warn "ace-nav resolution failed: #{e.message}" if ENV["DEBUG"]
            nil
          end

          # Resolve bundled template from gem's handbook directory
          def resolve_bundled_template(uri)
            # Parse URI: tmpl://the-prompt-bug -> the-prompt-bug
            template_name = uri.sub(%r{^tmpl://}, "")
            return nil if template_name == uri || template_name.empty?

            # Construct path to bundled template
            gem_root = File.expand_path("../../../..", __dir__)
            template_path = File.join(gem_root, "handbook", "templates", "#{template_name}.template.md")

            File.exist?(template_path) ? template_path : nil
          end
        end
      end
    end
  end
end
