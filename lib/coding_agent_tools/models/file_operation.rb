# frozen_string_literal: true

require 'pathname'

module CodingAgentTools
  module Models
    # FileOperation represents a file operation to be performed during installation
    # This is a model - pure data carrier with no behavior
    class FileOperation
      attr_reader :source, :target, :type, :metadata, :status

      # Operation types
      TYPES = [:copy, :create, :update, :skip].freeze
      
      # Operation statuses
      STATUSES = [:pending, :completed, :failed, :skipped].freeze

      def initialize(source:, target:, type:, metadata: nil, status: :pending)
        @source = source.is_a?(Pathname) ? source : Pathname.new(source.to_s)
        @target = target.is_a?(Pathname) ? target : Pathname.new(target.to_s)
        @type = validate_type(type)
        @metadata = metadata
        @status = validate_status(status)
      end

      # Get source filename
      def source_filename
        source.basename.to_s
      end

      # Get target filename
      def target_filename
        target.basename.to_s
      end

      # Check if operation is a copy
      def copy?
        type == :copy
      end

      # Check if operation is a create
      def create?
        type == :create
      end

      # Check if operation is an update
      def update?
        type == :update
      end

      # Check if operation should be skipped
      def skip?
        type == :skip || status == :skipped
      end

      # Check if operation is pending
      def pending?
        status == :pending
      end

      # Check if operation is completed
      def completed?
        status == :completed
      end

      # Check if operation failed
      def failed?
        status == :failed
      end

      # Create a new operation with updated status
      def with_status(new_status)
        self.class.new(
          source: source,
          target: target,
          type: type,
          metadata: metadata,
          status: new_status
        )
      end

      # Create a new operation with updated metadata
      def with_metadata(new_metadata)
        self.class.new(
          source: source,
          target: target,
          type: type,
          metadata: new_metadata,
          status: status
        )
      end

      # Convert to hash for serialization
      def to_h
        {
          source: source.to_s,
          target: target.to_s,
          type: type,
          metadata: metadata,
          status: status
        }
      end

      private

      def validate_type(type)
        type = type.to_sym
        unless TYPES.include?(type)
          raise ArgumentError, "Invalid operation type: #{type}. Must be one of: #{TYPES.join(', ')}"
        end
        type
      end

      def validate_status(status)
        status = status.to_sym
        unless STATUSES.include?(status)
          raise ArgumentError, "Invalid operation status: #{status}. Must be one of: #{STATUSES.join(', ')}"
        end
        status
      end
    end
  end
end