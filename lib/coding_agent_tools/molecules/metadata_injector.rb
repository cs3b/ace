# frozen_string_literal: true

require 'yaml'
require_relative '../atoms/taskflow_management/yaml_frontmatter_parser'
require_relative '../models/command_metadata'

module CodingAgentTools
  module Molecules
    # MetadataInjector handles injecting and updating YAML frontmatter metadata
    # This is a molecule - it uses the YamlFrontmatterParser atom
    class MetadataInjector
      def initialize(yaml_parser: Atoms::TaskflowManagement::YamlFrontmatterParser)
        @yaml_parser = yaml_parser
      end

      # Inject or update metadata in content
      # @param content [String] File content
      # @param metadata [Hash, Models::CommandMetadata] Metadata to inject
      # @return [String] Content with updated metadata
      def inject(content, metadata)
        # Convert metadata to hash if it's a CommandMetadata object
        metadata_hash = case metadata
                        when Models::CommandMetadata
                          metadata.to_h
                        when Hash
                          metadata
                        else
                          raise ArgumentError, "metadata must be Hash or CommandMetadata"
                        end

        # Parse existing content
        result = @yaml_parser.parse(content)
        
        if result.has_frontmatter?
          # Update existing frontmatter
          update_existing_frontmatter(result, metadata_hash)
        else
          # Add new frontmatter
          add_new_frontmatter(content, metadata_hash)
        end
      end

      # Extract metadata from content
      # @param content [String] File content
      # @return [Models::CommandMetadata] Extracted metadata
      def extract(content)
        result = @yaml_parser.parse(content)
        Models::CommandMetadata.from_hash(result.frontmatter || {})
      end

      # Check if content has metadata
      # @param content [String] File content
      # @return [Boolean] true if content has frontmatter
      def has_metadata?(content)
        @yaml_parser.has_frontmatter?(content)
      end

      # Remove metadata from content
      # @param content [String] File content
      # @return [String] Content without frontmatter
      def remove_metadata(content)
        result = @yaml_parser.parse(content)
        result.content
      end

      # Update specific metadata fields
      # @param content [String] File content
      # @param updates [Hash] Fields to update
      # @return [String] Content with updated metadata
      def update_fields(content, updates)
        current_metadata = extract(content)
        updated_metadata = current_metadata.to_h.merge(updates)
        inject(content, updated_metadata)
      end

      private

      def update_existing_frontmatter(parse_result, new_metadata)
        # Merge existing and new metadata
        merged_metadata = (parse_result.frontmatter || {}).merge(new_metadata)
        
        # Rebuild content with updated frontmatter
        frontmatter_yaml = YAML.dump(merged_metadata).sub(/^---\n/, '')
        "---\n#{frontmatter_yaml}---\n#{parse_result.content}"
      end

      def add_new_frontmatter(content, metadata)
        # Create new frontmatter
        frontmatter_yaml = YAML.dump(metadata).sub(/^---\n/, '')
        
        # Add to beginning of content
        "---\n#{frontmatter_yaml}---\n\n#{content}"
      end
    end
  end
end