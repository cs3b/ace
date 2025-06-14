# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # Model represents an AI model with its metadata
    # This is a molecule - a simple data structure with behavior
    class Model
      attr_reader :id, :name, :description, :default

      # Initialize a new Model
      # @param id [String] Model identifier (e.g., "gemini-1.5-pro")
      # @param name [String] Human-readable model name (e.g., "Gemini 1.5 Pro")
      # @param description [String] Model description
      # @param default [Boolean] Whether this is the default model
      def initialize(id:, name:, description:, default: false)
        @id = id
        @name = name
        @description = description
        @default = default
      end

      # Check if this is the default model
      # @return [Boolean]
      def default?
        @default
      end

      # String representation for display
      # @return [String]
      def to_s
        output = []
        output << "ID: #{@id}"
        output << "Name: #{@name}"
        output << "Description: #{@description}"
        output << "Status: Default model" if default?
        output.join("\n")
      end

      # Hash representation
      # @return [Hash]
      def to_h
        {
          id: @id,
          name: @name,
          description: @description,
          default: @default
        }
      end

      # JSON representation
      # @return [Hash] JSON-compatible hash
      def to_json_hash
        to_h
      end

      # Equality comparison
      # @param other [Model]
      # @return [Boolean]
      def ==(other)
        return false unless other.is_a?(Model)

        @id == other.id &&
          @name == other.name &&
          @description == other.description &&
          @default == other.default
      end

      # Hash code for using as hash keys
      # @return [Integer]
      def hash
        [@id, @name, @description, @default].hash
      end

      alias_method :eql?, :==
    end
  end
end
