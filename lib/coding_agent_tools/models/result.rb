# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Generic Result class for success/failure operations
    # Used throughout the reflection system for consistent error handling
    class Result
      # Create a successful result with optional data
      # @param data [Hash] Optional data to include in the result
      # @return [Result] A successful result instance
      def self.success(**data)
        new(success: true, data: data, error: nil)
      end

      # Create a failed result with an error message
      # @param error [String] Error message describing the failure
      # @return [Result] A failed result instance
      def self.failure(error)
        new(success: false, data: {}, error: error)
      end

      # Initialize a Result instance
      # @param success [Boolean] Whether the operation was successful
      # @param data [Hash] Data associated with the result
      # @param error [String, nil] Error message if failed
      def initialize(success:, data:, error:)
        @success = success
        @data = data || {}
        @error = error
        freeze
      end

      attr_reader :data, :error

      # Check if the result represents a successful operation
      # @return [Boolean] True if successful, false otherwise
      def success?
        @success
      end

      # Check if the result represents a failed operation
      # @return [Boolean] True if failed, false otherwise  
      def failure?
        !@success
      end

      # Check if the result is valid (alias for success?)
      # @return [Boolean] True if successful, false otherwise
      def valid?
        success?
      end

      # Access data using method calls (for backward compatibility)
      # This allows accessing result.reports, result.metrics, etc.
      def method_missing(method_name, *args)
        if @data.key?(method_name)
          @data[method_name]
        else
          super
        end
      end

      # Check if method exists in data or on object
      def respond_to_missing?(method_name, include_private = false)
        @data.key?(method_name) || super
      end

      # Convert result to hash representation
      # @return [Hash] Hash representation of the result
      def to_h
        {
          success: @success,
          data: @data,
          error: @error
        }.compact
      end

      # Convert to JSON representation
      # @return [String] JSON representation
      def to_json(*args)
        to_h.to_json(*args)
      end
    end
  end
end