# frozen_string_literal: true

module CodingAgentTools
  module Models
    # LlmModelInfo represents an AI model with its metadata
    # This is a pure data structure following ATOM architecture - no external IO
    LlmModelInfo = Struct.new(:id, :name, :description, :default, :context_size, :max_output_tokens, keyword_init: true) do
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
        output << "Context Size: #{format_context_size}" if context_size
        output << "Max Output: #{format_max_output_tokens}" if max_output_tokens
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
          default: default,
          context_size: context_size,
          max_output_tokens: max_output_tokens
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
          default == other.default &&
          context_size == other.context_size &&
          max_output_tokens == other.max_output_tokens
      end

      # Hash code for using as hash keys
      # @return [Integer]
      def hash
        [id, name, description, default, context_size, max_output_tokens].hash
      end

      # Format context size for human-readable display
      # @return [String]
      def format_context_size
        return "Unknown" if context_size.nil?

        if context_size >= 1_000_000
          "#{(context_size / 1_000_000.0).round(1)}M tokens"
        elsif context_size >= 1_000
          "#{(context_size / 1_000.0).round(1)}K tokens"
        else
          "#{context_size} tokens"
        end
      end

      # Format max output tokens for human-readable display
      # @return [String]
      def format_max_output_tokens
        return "Unknown" if max_output_tokens.nil?

        if max_output_tokens >= 1_000_000
          "#{(max_output_tokens / 1_000_000.0).round(1)}M tokens"
        elsif max_output_tokens >= 1_000
          "#{(max_output_tokens / 1_000.0).round(1)}K tokens"
        else
          "#{max_output_tokens} tokens"
        end
      end

      alias_method :eql?, :==
    end
  end
end
