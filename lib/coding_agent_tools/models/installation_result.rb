# frozen_string_literal: true

require_relative "installation_stats"

module CodingAgentTools
  module Models
    # InstallationResult represents the outcome of a Claude command installation
    # This is a model - pure data carrier with no behavior
    class InstallationResult
      attr_reader :success, :exit_code, :stats

      def initialize(success:, exit_code:, stats:)
        @success = success
        @exit_code = exit_code
        @stats = case stats
        when InstallationStats
          stats
        when Hash
          # Support hash for backward compatibility
          InstallationStats.new(**stats)
        else
          raise ArgumentError, "stats must be InstallationStats or Hash"
        end
      end

      # Check if installation was successful
      def success?
        success
      end

      # Check if installation failed
      def failure?
        !success
      end

      # Get errors from stats
      def errors
        stats.errors
      end

      # Check if there are any errors
      def errors?
        stats.errors?
      end

      # Convert to hash for backward compatibility
      def to_h
        {
          success: success,
          exit_code: exit_code,
          stats: stats.to_h
        }
      end

      # Create a successful result
      def self.success(stats)
        new(success: true, exit_code: 0, stats: stats)
      end

      # Create a failed result
      def self.failure(stats, exit_code: 1)
        new(success: false, exit_code: exit_code, stats: stats)
      end
    end
  end
end
