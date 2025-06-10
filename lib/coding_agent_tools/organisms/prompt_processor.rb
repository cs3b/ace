# frozen_string_literal: true

require_relative "../atoms/json_formatter"

module CodingAgentTools
  module Organisms
    # PromptProcessor handles prompt input from various sources
    # This is an organism - it orchestrates processing of prompts from strings or files
    class PromptProcessor
      # Maximum file size to read (10MB)
      MAX_FILE_SIZE = 10 * 1024 * 1024

      # Initialize prompt processor
      # @param options [Hash] Configuration options
      # @option options [Integer] :max_file_size Maximum file size to read
      def initialize(**options)
        @max_file_size = options.fetch(:max_file_size, MAX_FILE_SIZE)
      end

      # Process prompt input from string or file
      # @param input [String] Direct prompt text or file path
      # @param from_file [Boolean] Whether input is a file path
      # @return [String] Processed prompt text
      # @raise [Error] If file cannot be read or is too large
      def process(input, from_file: false)
        text_content = if from_file
          read_prompt_from_file(input) # This already strips the content
        else
          input # Raw input string, validate_prompt_string will strip it
        end
        # validate_prompt_string will check if (already stripped if from file) text_content is empty,
        # and raise if so. It also returns the stripped version.
        validate_prompt_string(text_content)
      end

      # Process multiple prompts
      # @param inputs [Array<String>] Array of prompts or file paths
      # @param from_files [Boolean] Whether inputs are file paths
      # @return [Array<String>] Processed prompts
      def process_multiple(inputs, from_files: false)
        inputs.map { |input| process(input, from_file: from_files) }
      end

      # Build a conversation from multiple prompts
      # @param prompts [Array<String>] Array of prompts
      # @param roles [Array<String>] Array of roles (user/assistant)
      # @return [Array<Hash>] Conversation structure
      def build_conversation(prompts, roles = nil)
        roles ||= prompts.map.with_index { |_, i| i.even? ? "user" : "assistant" }

        prompts.zip(roles).map do |prompt, role|
          {
            role: role,
            content: prompt
          }
        end
      end

      # Extract prompts from JSON file
      # @param file_path [String] Path to JSON file
      # @param prompt_key [String] Key to extract prompts from
      # @return [Array<String>, String] Extracted prompt(s)
      def extract_from_json(file_path, prompt_key = "prompt")
        content = read_file(file_path)
        data = Atoms::JSONFormatter.safe_parse(content)

        unless data
          raise Error, "Invalid JSON in file: #{file_path}"
        end

        extract_prompt_from_data(data, prompt_key)
      end

      # Format prompt with template variables
      # @param template [String] Prompt template with {variable} placeholders
      # @param variables [Hash] Variables to substitute
      # @return [String] Formatted prompt
      def format_template(template, variables = {})
        result = template.dup

        variables.each do |key, value|
          # Ensure both single and double brace placeholders are substituted.
          # Substitute double braces first to prevent {{var}} becoming {value} if only single was subbed.
          result.gsub!("{{#{key}}}", value.to_s)
          result.gsub!("{#{key}}", value.to_s)
        end

        # Check for unfilled variables (both {var} and {{var}})
        # This regex finds {var} or {{var}} and captures 'var'
        unfilled_single = result.scan(/(?<!\{)\{(\w+)\}(?!\})/).flatten
        unfilled_double = result.scan(/\{\{(\w+)\}\}/).flatten
        unfilled = (unfilled_single + unfilled_double).uniq

        unless unfilled.empty?
          raise Error, "Unfilled template variables: #{unfilled.join(", ")}"
        end

        result
      end

      # Validate prompt length and content
      # @param prompt [String] Prompt to validate
      # @param max_length [Integer] Maximum allowed length
      # @return [String] Validated prompt
      def validate(prompt, max_length: nil)
        # Check if prompt is empty
        if prompt.nil? || prompt.strip.empty?
          raise Error, "Prompt cannot be empty"
        end

        # Check length if specified
        if max_length && prompt.length > max_length
          raise Error, "Prompt exceeds maximum length of #{max_length} characters"
        end

        prompt.strip
      end

      # Split long prompt into chunks
      # @param prompt [String] Long prompt to split
      # @param chunk_size [Integer] Maximum size per chunk
      # @param overlap [Integer] Overlap between chunks
      # @return [Array<String>] Array of prompt chunks
      def split_into_chunks(prompt, chunk_size: 4000, overlap: 200)
        return [prompt] if prompt.length <= chunk_size

        chunks = []
        position = 0

        while position < prompt.length
          chunk_end = position + chunk_size
          chunk = prompt[position...chunk_end]

          # Try to split at sentence boundary
          if chunk_end < prompt.length
            last_period = chunk.rindex(/[.!?]\s/)
            if last_period && last_period > chunk_size * 0.7
              chunk = prompt[position...(position + last_period + 1)]
              chunk_end = position + last_period + 1
            end
          end

          chunks << chunk.strip

          if chunk_end >= prompt.length
            position = prompt.length # Reached the end
          else
            next_pos = chunk_end - overlap
            # If overlap is too large (i.e., next_pos isn't advancing past current position)
            # or if chunk_end itself didn't advance (unlikely but a safeguard),
            # then move position to chunk_end to ensure progress.
            position = if next_pos > position
              next_pos
            else # overlap >= chunk_size or chunk_end didn't advance
              chunk_end
            end
          end
        end

        # Remove any empty chunks and ensure at least one chunk if prompt was not empty
        final_chunks = chunks.map(&:strip).reject(&:empty?)
        if final_chunks.empty? && !prompt.strip.empty?
          return [prompt.strip]
        end
        final_chunks
      end

      private

      # Read prompt from file
      # @param file_path [String] Path to file
      # @return [String] File contents
      def read_prompt_from_file(file_path)
        unless File.exist?(file_path)
          raise Error, "Prompt file not found: #{file_path}"
        end

        file_size = File.size(file_path)
        if file_size > @max_file_size
          raise Error, "File too large: #{file_size} bytes (max: #{@max_file_size})"
        end

        content = read_file(file_path)

        # Auto-detect and validate JSON files
        if file_path.downcase.end_with?(".json")
          data = Atoms::JSONFormatter.safe_parse(content)
          unless data
            raise Error, "Invalid JSON in file: #{file_path}"
          end
        end

        content
      end

      # Read file contents
      # @param file_path [String] Path to file
      # @return [String] File contents
      def read_file(file_path)
        File.read(file_path, encoding: "UTF-8").strip
      rescue Errno::EACCES => e
        new_error = Error.new("Permission denied reading file: #{file_path}")
        new_error.set_backtrace(e.backtrace)
        raise new_error
      rescue Errno::ENOENT => e
        new_error = Error.new("File not found: #{file_path}")
        new_error.set_backtrace(e.backtrace)
        raise new_error
      rescue => e
        new_error = Error.new("Error reading file #{file_path}: #{e.message}")
        new_error.set_backtrace(e.backtrace)
        raise new_error
      end

      # Validate prompt string
      # @param prompt [String] Prompt to validate
      # @return [String] Validated prompt
      def validate_prompt_string(prompt)
        if prompt.nil? || prompt.strip.empty?
          raise Error, "Prompt cannot be empty"
        end

        prompt.strip
      end

      # Extract prompt from parsed data
      # @param data [Hash, Array] Parsed JSON data
      # @param key [String] Key to look for
      # @return [String, Array<String>] Extracted prompt(s)
      def extract_prompt_from_data(data, key)
        case data
        when Hash
          if data.key?(key)
            data[key]
          elsif data.key?(key.to_sym)
            data[key.to_sym]
          else
            raise Error, "Key '#{key}' not found in JSON data"
          end
        when Array
          data.map { |item| extract_prompt_from_data(item, key) }.flatten
        else
          raise Error, "Unexpected data type in JSON: #{data.class}"
        end
      end
    end
  end
end
