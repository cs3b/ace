# frozen_string_literal: true

module Ace
  module Search
    module Atoms
      # Centralized debug logging for ace-search
      #
      # NOTE: This logger caches the ENV["DEBUG"] state on first use for performance
      # and is intended for single-threaded, short-lived CLI processes.
      #
      # Usage:
      #   DebugLogger.log("message")
      #   DebugLogger.section("Title") do
      #     DebugLogger.log("detail 1")
      #     DebugLogger.log("detail 2")
      #   end
      module DebugLogger
        # Check if debug logging is enabled via DEBUG environment variable
        #
        # @return [Boolean] true if DEBUG is set to "1" or "true"
        def self.enabled?
          @enabled ||= begin
            debug_value = ENV["DEBUG"]
            debug_value == "1" || debug_value == "true"
          end
        end

        # Log a debug message to stderr if debugging is enabled
        #
        # @param message [String] Message to log
        # @param prefix [String] Prefix for the message (default: "DEBUG")
        # @return [void]
        def self.log(message, prefix: "DEBUG")
          return unless enabled?
          warn "#{prefix}: #{message}"
        end

        # Log a section with title and optional block for grouped output
        #
        # @param title [String] Section title
        # @yield Optional block to execute within the section
        # @return [void]
        def self.section(title)
          return unless enabled?

          warn "=" * 60
          warn "DEBUG: #{title}"
          yield if block_given?
          warn "=" * 60
        end

        # Reset the enabled cache (useful for testing)
        #
        # @return [void]
        def self.reset!
          @enabled = nil
        end
      end
    end
  end
end
