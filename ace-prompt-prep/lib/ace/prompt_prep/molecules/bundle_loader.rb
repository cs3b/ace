# frozen_string_literal: true

module Ace
  module PromptPrep
    module Molecules
      # Load bundle via ace-bundle Ruby API
      #
      # This module calls Ace::Bundle.load_file and returns the result.
      class BundleLoader
        # Valid bundle format options
        VALID_FORMATS = ["markdown-xml", "markdown", "xml"].freeze

        # Load bundle from prompt file with validation
        #
        # @param prompt_path [String] Path to prompt file
        # @param options [Hash] Additional options
        # @option options [String] :format Output format ('markdown-xml', 'markdown', 'xml')
        # @option options [Boolean] :embed_source Whether to embed source content
        # @return [String] Bundle content or empty string on error
        def self.call(prompt_path, options = {})
          # Input validation
          return "" unless valid_prompt_path?(prompt_path)
          return "" unless valid_options?(options)

          debug_log("Loading bundle from: #{prompt_path}", :bundle_loading)

          begin
            require "ace/bundle"
          rescue LoadError
            warn "Error: ace-bundle gem not available"
            return ""
          end

          begin
            # Validate that the prompt file exists and is readable
            unless File.exist?(prompt_path)
              warn "Error: Prompt file does not exist: #{prompt_path}"
              return ""
            end

            unless File.readable?(prompt_path)
              warn "Error: Prompt file is not readable: #{prompt_path}"
              return ""
            end

            # Resolve symlinks and validate project boundaries
            real_path = begin
              File.realpath(prompt_path)
            rescue
              prompt_path
            end
            project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current

            unless real_path.start_with?(project_root)
              warn "Error: File path resolves outside project: #{real_path}"
              return ""
            end

            # Check file size to prevent processing extremely large files
            file_size = File.size(prompt_path)
            max_size_bytes = (Ace::PromptPrep.config.dig("security", "max_file_size_mb") || 10) * 1024 * 1024
            debug_log("File size: #{file_size} bytes (limit: #{max_size_bytes / 1024 / 1024}MB)", :bundle_loading)
            if file_size > max_size_bytes
              warn "Error: Prompt file too large (#{file_size} bytes), exceeds limit of #{max_size_bytes / 1024 / 1024}MB"
              return ""
            end

            bundle_data = Ace::Bundle.load_file(
              prompt_path,
              format: options[:format] || "markdown-xml",
              embed_source: options[:embed_source].nil? || options[:embed_source]
            )

            # Validate bundle data structure
            if bundle_data.nil?
              warn "Warning: Bundle data is nil"
              return ""
            end

            # Extract content with validation
            content = bundle_data.content
            if content.nil?
              warn "Warning: Bundle content is nil"
              return ""
            end

            # Validate content type
            unless content.is_a?(String)
              warn "Warning: Bundle content is not a string (#{content.class})"
              return ""
            end

            # Validate content length
            if content.empty?
              warn "Warning: Bundle content is empty"
              return ""
            end

            debug_log("Bundle loaded successfully, content length: #{content.length} characters", :bundle_loading)
            content
          rescue => e
            warn "Error: Failed to load bundle: #{e.message}"
            ""
          end
        end

        private

        # Debug logging for troubleshooting and development
        #
        # @param message [String] Debug message
        # @param category [Symbol, nil] Optional category for filtering
        def self.debug_log(message, category = nil)
          return unless Ace::PromptPrep.config.dig("debug", "enabled")
          return if category && !Ace::PromptPrep.config.dig("debug", category.to_s)

          warn "[DEBUG] #{message}"
        end

        # Validate prompt path input
        #
        # @param prompt_path [String, nil] Path to validate
        # @return [Boolean] True if valid
        def self.valid_prompt_path?(prompt_path)
          return false if prompt_path.nil?
          return false if prompt_path.to_s.strip.empty?

          path_str = prompt_path.to_s

          # Check for various path traversal patterns
          return false if path_str.include?("../")
          return false if path_str.include?("..\\")
          return false if path_str.include?("%2e%2e")  # URL encoded
          return false if path_str.include?("..%2f")
          return false if path_str.include?("%2e%2e%2f")

          # Reject absolute paths (should be relative to project)
          return false if File.absolute_path?(path_str) && !path_str.start_with?("/")

          # Check for shell escape patterns
          return false if path_str.include?(";")
          return false if path_str.include?("&")
          return false if path_str.include?("|")
          return false if path_str.include?("`")

          true
        end

        # Validate options hash
        #
        # @param options [Hash] Options to validate
        # @return [Boolean] True if valid
        def self.valid_options?(options)
          return true unless options.is_a?(Hash)

          # Validate format option if provided
          if options.key?(:format)
            format = options[:format]
            unless format.is_a?(String) && VALID_FORMATS.include?(format)
              warn "Warning: Invalid format '#{format}', using default 'markdown-xml'"
              options[:format] = "markdown-xml"
            end
          end

          # Validate embed_source option if provided
          if options.key?(:embed_source)
            unless [true, false].include?(options[:embed_source])
              warn "Warning: Invalid embed_source value, using default true"
              options[:embed_source] = true
            end
          end

          true
        end
      end
    end
  end
end
