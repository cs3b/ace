# frozen_string_literal: true

require_relative '../models/installation_stats'

module CodingAgentTools
  module Molecules
    # StatisticsCollector manages installation statistics
    # This is a molecule - it operates on the InstallationStats model
    class StatisticsCollector
      attr_reader :stats

      def initialize(initial_stats: nil)
        @stats = case initial_stats
                 when Models::InstallationStats
                   initial_stats
                 when Hash
                   Models::InstallationStats.new(**initial_stats)
                 when nil
                   Models::InstallationStats.new
                 else
                   raise ArgumentError, "initial_stats must be InstallationStats, Hash, or nil"
                 end
      end

      # Record a file creation
      # @param file_type [Symbol] Type of file (:command, :agent, :custom_command, etc.)
      def record_created(file_type = nil)
        @stats.increment(:created)
        record_by_type(file_type) if file_type
      end

      # Record a skipped file
      # @param file_type [Symbol] Type of file
      def record_skipped(file_type = nil)
        @stats.increment(:skipped)
      end

      # Record an updated file
      # @param file_type [Symbol] Type of file
      def record_updated(file_type = nil)
        @stats.increment(:updated)
        record_by_type(file_type) if file_type
      end

      # Record an error
      # @param message [String] Error message
      def record_error(message)
        @stats.add_error(message)
      end

      # Record operation result
      # @param result [Hash] Operation result with :status
      # @param file_type [Symbol] Type of file
      def record_operation(result, file_type = nil)
        case result[:status]
        when :completed
          record_created(file_type)
        when :skipped
          record_skipped(file_type)
        when :updated
          record_updated(file_type)
        when :failed
          record_error(result[:error] || "Unknown error")
        end
      end

      # Get summary statistics
      # @return [Hash] Summary of operations
      def summary
        {
          total_operations: @stats.created + @stats.skipped + @stats.updated,
          successful: @stats.created + @stats.updated,
          skipped: @stats.skipped,
          errors: @stats.errors.size,
          by_type: {
            commands: @stats.total_commands,
            agents: @stats.agents
          }
        }
      end

      # Generate summary message
      # @return [String] Human-readable summary
      def summary_message
        parts = []
        parts << "Created: #{@stats.created}" if @stats.created > 0
        parts << "Updated: #{@stats.updated}" if @stats.updated > 0
        parts << "Skipped: #{@stats.skipped}" if @stats.skipped > 0
        parts << "Errors: #{@stats.errors.size}" if @stats.errors?
        
        parts.join(", ")
      end

      # Check if installation was successful
      # @return [Boolean] true if no errors
      def success?
        !@stats.errors?
      end

      # Reset statistics
      def reset!
        @stats = Models::InstallationStats.new
      end

      # Merge with another collector's stats
      # @param other [StatisticsCollector] Other collector
      def merge!(other)
        other_stats = other.stats
        
        @stats.created += other_stats.created
        @stats.skipped += other_stats.skipped
        @stats.updated += other_stats.updated
        @stats.errors.concat(other_stats.errors)
        @stats.custom_commands += other_stats.custom_commands
        @stats.generated_commands += other_stats.generated_commands
        @stats.workflow_commands += other_stats.workflow_commands
        @stats.agents += other_stats.agents
      end

      private

      def record_by_type(file_type)
        case file_type
        when :custom_command
          @stats.increment(:custom_commands)
        when :generated_command
          @stats.increment(:generated_commands)
        when :workflow_command
          @stats.increment(:workflow_commands)
        when :agent
          @stats.increment(:agents)
        end
      end
    end
  end
end