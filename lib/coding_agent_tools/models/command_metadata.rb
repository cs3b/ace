# frozen_string_literal: true

module CodingAgentTools
  module Models
    # CommandMetadata represents YAML frontmatter metadata for Claude commands
    # This is a model - pure data carrier with no behavior
    class CommandMetadata
      attr_reader :last_modified, :source, :auto_generated, :version, :custom_fields

      def initialize(
        last_modified: nil,
        source: nil,
        auto_generated: false,
        version: nil,
        **custom_fields
      )
        @last_modified = last_modified
        @source = source
        @auto_generated = auto_generated
        @version = version
        @custom_fields = custom_fields
      end

      # Convert to hash for YAML serialization
      def to_h
        hash = {}
        hash['last_modified'] = last_modified if last_modified
        hash['source'] = source if source
        hash['auto_generated'] = auto_generated if auto_generated
        hash['version'] = version if version
        
        # Add any custom fields
        custom_fields.each do |key, value|
          hash[key.to_s] = value
        end
        
        hash
      end

      # Create from hash (for parsing existing metadata)
      def self.from_hash(hash)
        return new if hash.nil? || hash.empty?
        
        # Extract known fields
        known_fields = {
          last_modified: hash['last_modified'],
          source: hash['source'],
          auto_generated: hash['auto_generated'],
          version: hash['version']
        }
        
        # Collect remaining fields as custom
        custom = hash.reject { |k, _| %w[last_modified source auto_generated version].include?(k) }
        
        new(**known_fields, **custom)
      end

      # Merge with another metadata object
      def merge(other)
        return self unless other.is_a?(CommandMetadata)
        
        merged_hash = to_h.merge(other.to_h)
        self.class.from_hash(merged_hash)
      end

      # Check if metadata indicates auto-generated content
      def auto_generated?
        auto_generated
      end

      # Update last_modified timestamp
      def with_timestamp(timestamp)
        self.class.new(
          last_modified: timestamp,
          source: source,
          auto_generated: auto_generated,
          version: version,
          **custom_fields
        )
      end
    end
  end
end