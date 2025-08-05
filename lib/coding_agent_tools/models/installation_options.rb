# frozen_string_literal: true

module CodingAgentTools
  module Models
    # InstallationOptions holds configuration options for Claude command installation
    # This is a model - pure data carrier with no behavior
    class InstallationOptions
      attr_reader :dry_run, :verbose, :backup, :force, :source

      def initialize(
        dry_run: false,
        verbose: false,
        backup: false,
        force: false,
        source: nil
      )
        @dry_run = dry_run
        @verbose = verbose
        @backup = backup
        @force = force
        @source = source
      end

      # Convert to hash for backward compatibility
      def to_h
        {
          dry_run: dry_run,
          verbose: verbose,
          backup: backup,
          force: force,
          source: source
        }
      end

      # Create from hash (for easy conversion)
      def self.from_hash(hash)
        new(
          dry_run: hash.fetch(:dry_run, false),
          verbose: hash.fetch(:verbose, false),
          backup: hash.fetch(:backup, false),
          force: hash.fetch(:force, false),
          source: hash[:source]
        )
      end

      # Check if running in dry-run mode
      def dry_run?
        dry_run
      end

      # Check if verbose output is enabled
      def verbose?
        verbose
      end

      # Check if backup should be created
      def backup?
        backup
      end

      # Check if files should be overwritten
      def force?
        force
      end

      # Check if custom source is specified
      def custom_source?
        !source.nil?
      end
    end
  end
end