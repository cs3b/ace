# frozen_string_literal: true

require "yaml"

module Ace
  module Review
    module Molecules
      # Reads feedback files from disk and parses them into FeedbackItem instances.
      #
      # Handles YAML frontmatter parsing and markdown section extraction.
      # Returns error hashes for malformed files rather than raising exceptions.
      #
      # @example Read a single file
      #   reader = FeedbackFileReader.new
      #   result = reader.read("/path/to/8o7abc-missing-error.s.md")
      #   result[:success]       #=> true
      #   result[:feedback_item] #=> FeedbackItem instance
      #
      # @example Read all files in a directory
      #   reader = FeedbackFileReader.new
      #   results = reader.read_all("/path/to/feedback")
      #   results #=> [FeedbackItem, FeedbackItem, ...]
      #
      class FeedbackFileReader
        # YAML frontmatter pattern: content between --- markers at start of file
        FRONTMATTER_PATTERN = /\A---\n(.*?)\n---\n/m

        # Section header pattern: ## Section Name
        SECTION_PATTERN = /^## (\w+)\n/

        # Read a single feedback file
        #
        # @param file_path [String] Path to the .s.md file
        # @return [Hash] Result with :success and :feedback_item or :error
        def read(file_path)
          validate_file_path(file_path)

          content = File.read(file_path)
          parse_content(content, file_path)
        rescue Errno::ENOENT
          {success: false, error: "File not found: #{file_path}"}
        rescue Errno::EACCES
          {success: false, error: "Permission denied: #{file_path}"}
        rescue ArgumentError => e
          {success: false, error: e.message}
        rescue SystemCallError, IOError => e
          {success: false, error: "Failed to read file: #{e.message}"}
        end

        # Read all .s.md files in a directory
        #
        # @param directory [String] Path to the feedback directory
        # @return [Array<Models::FeedbackItem>] Array of successfully parsed items
        def read_all(directory)
          return [] unless Dir.exist?(directory)

          files = Dir.glob(File.join(directory, "*.s.md"))
          items = []

          files.each do |file_path|
            result = read(file_path)
            items << result[:feedback_item] if result[:success]
          end

          items
        end

        # Read feedback files filtered by status
        #
        # @param directory [String] Path to the feedback directory
        # @param status [String] Status to filter by (draft, pending, invalid, skip, done)
        # @return [Array<Models::FeedbackItem>] Array of matching items
        def read_by_status(directory, status)
          read_all(directory).select { |item| item.status == status }
        end

        private

        # Validate the file path
        #
        # @param file_path [String] The file path to validate
        # @raise [ArgumentError] If path is invalid
        def validate_file_path(file_path)
          raise ArgumentError, "file_path is required" if file_path.nil? || file_path.empty?
        end

        # Parse file content into a FeedbackItem
        #
        # @param content [String] The file content
        # @param file_path [String] The file path (for error messages)
        # @return [Hash] Result with :success and :feedback_item or :error
        def parse_content(content, file_path)
          # Extract frontmatter
          frontmatter_match = content.match(FRONTMATTER_PATTERN)
          unless frontmatter_match
            return {success: false, error: "Missing YAML frontmatter in: #{file_path}"}
          end

          frontmatter_yaml = frontmatter_match[1]
          body = content[frontmatter_match.end(0)..]

          # Parse YAML frontmatter
          frontmatter = parse_frontmatter(frontmatter_yaml, file_path)
          return frontmatter if frontmatter[:error]

          # Parse markdown sections
          sections = parse_sections(body)

          # Build FeedbackItem attributes
          attrs = frontmatter[:data].merge(sections)

          # Create FeedbackItem
          feedback_item = Models::FeedbackItem.new(attrs)
          {success: true, feedback_item: feedback_item}
        rescue ArgumentError => e
          {success: false, error: "Invalid feedback item in #{file_path}: #{e.message}"}
        rescue Psych::SyntaxError, TypeError, KeyError => e
          {success: false, error: "Failed to parse #{file_path}: #{e.message}"}
        end

        # Parse YAML frontmatter
        #
        # @param yaml_content [String] The YAML content
        # @param file_path [String] The file path (for error messages)
        # @return [Hash] Result with :data or :error
        def parse_frontmatter(yaml_content, file_path)
          data = YAML.safe_load(yaml_content, permitted_classes: [Time, Date])

          unless data.is_a?(Hash)
            return {error: "Invalid YAML frontmatter in #{file_path}: expected Hash"}
          end

          {data: data}
        rescue Psych::SyntaxError => e
          {error: "YAML syntax error in #{file_path}: #{e.message}"}
        end

        # Parse markdown sections from the body
        #
        # @param body [String] The markdown body after frontmatter
        # @return [Hash] Hash with section names as keys and content as values
        def parse_sections(body)
          sections = {}
          return sections if body.nil? || body.empty?

          # Split by section headers
          parts = body.split(SECTION_PATTERN)

          # First part is any content before first section (usually empty)
          parts.shift if parts.first&.strip&.empty?

          # Process pairs of (section_name, content)
          parts.each_slice(2) do |name, content|
            next unless name && content

            key = section_name_to_key(name)
            sections[key] = content.strip if key
          end

          sections
        end

        # Convert section name to attribute key
        #
        # @param name [String] The section name (e.g., "Finding", "Context")
        # @return [String, nil] The attribute key or nil if not recognized
        def section_name_to_key(name)
          case name.downcase
          when "finding" then "finding"
          when "context" then "context"
          when "research" then "research"
          when "resolution" then "resolution"
          end
        end
      end
    end
  end
end
