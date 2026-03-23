# frozen_string_literal: true

module Ace
  module Support
    module Markdown
      module Models
        # Immutable representation of a markdown section
        # Contains heading information and content
        class Section
          attr_reader :heading, :level, :content, :metadata

          # Create a new Section
          # @param heading [String] The section heading text
          # @param level [Integer] The heading level (1-6)
          # @param content [String] The section content (without heading)
          # @param metadata [Hash] Optional metadata about the section
          def initialize(heading:, level:, content:, metadata: {})
            @heading = heading.freeze
            @level = level.freeze
            @content = content.freeze
            @metadata = metadata.freeze

            validate!
          end

          # Create a new Section with updated content
          # @param new_content [String] The new content
          # @return [Section] New Section instance
          def with_content(new_content)
            Section.new(
              heading: @heading,
              level: @level,
              content: new_content,
              metadata: @metadata
            )
          end

          # Create a new Section with updated heading
          # @param new_heading [String] The new heading
          # @return [Section] New Section instance
          def with_heading(new_heading)
            Section.new(
              heading: new_heading,
              level: @level,
              content: @content,
              metadata: @metadata
            )
          end

          # Create a new Section with updated metadata
          # @param new_metadata [Hash] The new metadata
          # @return [Section] New Section instance
          def with_metadata(new_metadata)
            Section.new(
              heading: @heading,
              level: @level,
              content: @content,
              metadata: new_metadata
            )
          end

          # Convert section to markdown string
          # @return [String] The complete section as markdown
          def to_markdown
            heading_prefix = "#" * @level
            "#{heading_prefix} #{@heading}\n\n#{@content}"
          end

          # Check if section is empty (no content)
          # @return [Boolean]
          def empty?
            @content.nil? || @content.strip.empty?
          end

          # Get word count of section content
          # @return [Integer]
          def word_count
            @content.split(/\s+/).length
          end

          # Compare sections for equality
          # @param other [Section]
          # @return [Boolean]
          def ==(other)
            other.is_a?(Section) &&
              @heading == other.heading &&
              @level == other.level &&
              @content == other.content
          end

          # Hash representation
          # @return [Hash]
          def to_h
            {
              heading: @heading,
              level: @level,
              content: @content,
              metadata: @metadata
            }
          end

          private

          def validate!
            raise ArgumentError, "Heading cannot be nil or empty" if @heading.nil? || @heading.empty?
            raise ArgumentError, "Level must be between 1 and 6" unless (1..6).cover?(@level)
            raise ArgumentError, "Content cannot be nil" if @content.nil?
            raise ArgumentError, "Metadata must be a hash" unless @metadata.is_a?(Hash)
          end
        end
      end
    end
  end
end
