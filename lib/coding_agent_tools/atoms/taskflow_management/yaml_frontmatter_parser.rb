# frozen_string_literal: true

require "yaml"

module CodingAgentTools
  module Atoms
    module TaskflowManagement
      # YamlFrontmatterParser provides YAML frontmatter parsing utilities
      # This is an atom - it has no dependencies on other parts of this gem
      class YamlFrontmatterParser
        # Result of parsing a document with frontmatter
        ParseResult = Struct.new(:frontmatter, :content, :raw_frontmatter, :has_frontmatter?) do
          def valid?
            !frontmatter.nil?
          end

          def empty_frontmatter?
            frontmatter.nil? || frontmatter.empty?
          end
        end

        # Parse error for malformed YAML
        class ParseError < StandardError
          attr_reader :line_number, :column, :yaml_error

          def initialize(message, line_number: nil, column: nil, yaml_error: nil)
            super(message)
            @line_number = line_number
            @column = column
            @yaml_error = yaml_error
          end
        end

        # Security error for potentially malicious YAML
        class SecurityError < StandardError; end

        # Parse YAML frontmatter from a string
        # @param content [String] Content to parse
        # @param delimiter [String] Frontmatter delimiter (default: "---")
        # @param safe_mode [Boolean] Whether to use safe YAML parsing (default: true)
        # @return [ParseResult] Parse result with frontmatter and content
        # @raise [ParseError] If YAML is malformed
        # @raise [SecurityError] If YAML contains unsafe content
        def self.parse(content, delimiter: "---", safe_mode: true)
          raise ArgumentError, "content cannot be nil" if content.nil?
          raise ArgumentError, "delimiter cannot be nil or empty" if delimiter.nil? || delimiter.empty?

          # Handle empty content
          return ParseResult.new({}, "", "", false) if content.strip.empty?

          # Split content into lines for processing
          lines = content.split("\n")

          # Check if first line is delimiter
          unless lines.first&.strip == delimiter
            # No frontmatter - return entire content as body
            return ParseResult.new({}, content, "", false)
          end

          # Find closing delimiter
          closing_delimiter_index = find_closing_delimiter(lines, delimiter)

          if closing_delimiter_index.nil?
            # No closing delimiter found - treat as regular content
            return ParseResult.new({}, content, "", false)
          end

          # Extract frontmatter lines (excluding delimiters)
          frontmatter_lines = lines[1...closing_delimiter_index]
          raw_frontmatter = frontmatter_lines.join("\n")

          # Extract content after closing delimiter
          content_lines = lines[(closing_delimiter_index + 1)..]
          parsed_content = content_lines.join("\n")

          # Parse YAML frontmatter
          parsed_frontmatter = parse_yaml_safely(raw_frontmatter, safe_mode)

          ParseResult.new(parsed_frontmatter, parsed_content, raw_frontmatter, true)
        end

        # Parse YAML frontmatter from a file
        # @param file_path [String] Path to file to parse
        # @param delimiter [String] Frontmatter delimiter (default: "---")
        # @param safe_mode [Boolean] Whether to use safe YAML parsing (default: true)
        # @return [ParseResult] Parse result with frontmatter and content
        # @raise [ParseError] If YAML is malformed
        # @raise [SecurityError] If YAML contains unsafe content
        # @raise [ArgumentError] If file doesn't exist or isn't readable
        def self.parse_file(file_path, delimiter: "---", safe_mode: true)
          raise ArgumentError, "file_path cannot be nil or empty" if file_path.nil? || file_path.empty?

          # Basic security check first
          if file_path.include?("\0") || file_path.match?(/[\x00-\x1f\x7f]/)
            raise SecurityError, "File path contains invalid characters"
          end

          raise ArgumentError, "File does not exist: #{file_path}" unless File.exist?(file_path)
          raise ArgumentError, "File is not readable: #{file_path}" unless File.readable?(file_path)

          begin
            content = File.read(file_path, encoding: "UTF-8")
          rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
            # Try reading as binary and force UTF-8 encoding
            content = File.read(file_path, mode: "rb")
            content = content.force_encoding("UTF-8")
            raise ArgumentError, "File contains invalid UTF-8 content: #{file_path}" unless content.valid_encoding?
          rescue => e
            raise ArgumentError, "Error reading file: #{e.message}"
          end

          parse(content, delimiter: delimiter, safe_mode: safe_mode)
        end

        # Check if content has YAML frontmatter
        # @param content [String] Content to check
        # @param delimiter [String] Frontmatter delimiter (default: "---")
        # @return [Boolean] True if content has frontmatter
        def self.has_frontmatter?(content, delimiter: "---")
          return false if content.nil? || content.strip.empty?

          lines = content.split("\n")
          return false if lines.empty?

          # Check if first line is delimiter
          return false unless lines.first&.strip == delimiter

          # Find closing delimiter
          closing_delimiter_index = find_closing_delimiter(lines, delimiter)
          !closing_delimiter_index.nil?
        end

        # Extract only the frontmatter as a hash
        # @param content [String] Content to parse
        # @param delimiter [String] Frontmatter delimiter (default: "---")
        # @param safe_mode [Boolean] Whether to use safe YAML parsing (default: true)
        # @return [Hash] Parsed frontmatter hash
        def self.extract_frontmatter(content, delimiter: "---", safe_mode: true)
          result = parse(content, delimiter: delimiter, safe_mode: safe_mode)
          result.frontmatter || {}
        end

        # Extract only the content (without frontmatter)
        # @param content [String] Content to parse
        # @param delimiter [String] Frontmatter delimiter (default: "---")
        # @return [String] Content without frontmatter
        def self.extract_content(content, delimiter: "---")
          result = parse(content, delimiter: delimiter, safe_mode: false)
          result.content || ""
        end

        # Validate YAML frontmatter structure
        # @param frontmatter [Hash] Frontmatter to validate
        # @param required_keys [Array<String>] Required keys that must be present
        # @param allowed_keys [Array<String>] Allowed keys (nil means all keys allowed)
        # @return [Hash] Validation result with :valid?, :errors, :warnings
        def self.validate_frontmatter(frontmatter, required_keys: [], allowed_keys: nil)
          result = {
            valid?: true,
            errors: [],
            warnings: []
          }

          return result if frontmatter.nil? || frontmatter.empty?

          # Check required keys
          required_keys.each do |key|
            unless frontmatter.key?(key) || frontmatter.key?(key.to_sym)
              result[:errors] << "Missing required key: #{key}"
              result[:valid?] = false
            end
          end

          # Check allowed keys if specified
          if allowed_keys
            frontmatter.keys.each do |key|
              key_str = key.to_s
              result[:warnings] << "Unknown key: #{key_str}" unless allowed_keys.include?(key_str)
            end
          end

          result
        end

        class << self
          private

          # Find the closing delimiter in lines
          # @param lines [Array<String>] Lines to search
          # @param delimiter [String] Delimiter to find
          # @return [Integer, nil] Index of closing delimiter or nil if not found
          def find_closing_delimiter(lines, delimiter)
            # Start from line 1 (skip opening delimiter)
            (1...lines.length).each do |i|
              return i if lines[i].strip == delimiter
            end
            nil
          end

          # Parse YAML safely with security checks
          # @param yaml_content [String] YAML content to parse
          # @param safe_mode [Boolean] Whether to use safe parsing
          # @return [Hash] Parsed YAML hash
          # @raise [ParseError] If YAML is malformed
          # @raise [SecurityError] If YAML contains unsafe content
          def parse_yaml_safely(yaml_content, safe_mode)
            # Handle empty YAML
            return {} if yaml_content.strip.empty?

            # Security checks for potentially dangerous YAML
            perform_security_checks(yaml_content) if safe_mode

            begin
              parsed = if safe_mode
                # Use safe_load to prevent code execution
                # Allow Date, Time, and DateTime for task metadata
                YAML.safe_load(yaml_content, permitted_classes: [Date, Time, DateTime], aliases: false)
              else
                # Use regular load (less secure but more permissive)
                YAML.load(yaml_content)
              end

              # Ensure result is a hash
              case parsed
              when Hash
                parsed
              when nil
                {}
              else
                raise ParseError, "YAML frontmatter must be a hash/object, got #{parsed.class}"
              end
            rescue Psych::SyntaxError => e
              raise ParseError.new(
                "Invalid YAML syntax: #{e.message}",
                line_number: e.line,
                column: e.column,
                yaml_error: e
              )
            rescue ArgumentError => e
              # Check if it's a date parsing error
              unless e.message.include?("invalid date") || e.message.include?("Date")
                raise ParseError.new("YAML parsing error: #{e.message}", yaml_error: e)
              end

              raise ParseError.new(
                "Invalid date format in YAML: #{e.message}. Use ISO format (YYYY-MM-DD) for dates.", yaml_error: e
              )
            end
          end

          # Perform security checks on YAML content
          # @param yaml_content [String] YAML content to check
          # @raise [SecurityError] If content appears malicious
          def perform_security_checks(yaml_content)
            # Check for potentially dangerous patterns
            dangerous_patterns = [
              %r{!ruby/object}i,        # Ruby object serialization
              %r{!ruby/class}i,         # Ruby class references
              %r{!ruby/module}i,        # Ruby module references
              %r{!ruby/regexp}i,        # Ruby regexp objects
              %r{!ruby/string}i,        # Ruby string objects
              %r{!!ruby/object}i,       # Alternative Ruby object syntax
              %r{!!python/object}i,     # Python object serialization
              /!!binary/i, # Binary data
              %r{!![a-z]+/object}i, # Generic object serialization
              /<%.*%>/,                # ERB-style tags
              /{{.*}}/,                # Template-style tags
              /\$\{.*\}/,              # Variable substitution
              /eval\(/i,               # Eval function calls
              /system\(/i,             # System function calls
              /`.*`/,                  # Backtick command execution
              /\bexec\b/i,             # Exec commands
              /\bpopen\b/i,            # Process opening
              /\bfork\b/i,             # Process forking
              /\brequire\b/i,          # Code requiring
              /\binclude\b/i,          # Code including
              /\bload\b/i,             # Code loading
              /\beval\b/i,             # Code evaluation
              /\bsend\b/i,             # Method sending
              /\bdefine_method\b/i,    # Method definition
              /\bclass_eval\b/i,       # Class evaluation
              /\bmodule_eval\b/i,      # Module evaluation
              /\binstance_eval\b/i     # Instance evaluation
            ]

            dangerous_patterns.each do |pattern|
              if yaml_content.match?(pattern)
                raise SecurityError, "YAML content contains potentially dangerous pattern: #{pattern}"
              end
            end

            # Check for excessive nesting (YAML bomb prevention)
            max_nesting = 50
            current_nesting = 0
            yaml_content.each_char do |char|
              case char
              when "{", "[", "-"
                current_nesting += 1
                raise SecurityError, "YAML content exceeds maximum nesting level" if current_nesting > max_nesting
              when "}", "]"
                current_nesting -= 1
              end
            end

            # Check for excessive length
            raise SecurityError, "YAML content exceeds maximum length" if yaml_content.length > 100_000
          end
        end
      end
    end
  end
end
