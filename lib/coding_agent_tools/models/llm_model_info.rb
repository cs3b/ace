# frozen_string_literal: true

module CodingAgentTools
  module Models
    # LlmModelInfo represents an AI model with its metadata
    # This is a pure data structure following ATOM architecture - no external IO
    LlmModelInfo = Struct.new(:id, :name, :description, :default, keyword_init: true) do
      # Check if this is the default model
      # @return [Boolean]
      def default?
        default
      end

      # String representation for display
      # @return [String]
      def to_s
        output = []
        output << "ID: #{id}"
        output << "Name: #{name}"
        output << "Description: #{description}"
        output << "Status: Default model" if default?
        output.join("\n")
      end

      # Hash representation
      # @return [Hash]
      def to_h
        {
          id: id,
          name: name,
          description: description,
          default: default
        }
      end

      # JSON representation
      # @return [Hash] JSON-compatible hash
      def to_json_hash
        to_h
      end

      # Equality comparison
      # @param other [LlmModelInfo]
      # @return [Boolean]
      def ==(other)
        return false unless other.is_a?(LlmModelInfo)

        id == other.id &&
          name == other.name &&
          description == other.description &&
          default == other.default
      end

      # Hash code for using as hash keys
      # @return [Integer]
      def hash
        [id, name, description, default].hash
      end

      alias_method :eql?, :==
    end
  end
end
