# frozen_string_literal: true

require_relative "timestamp/version"

# Load ace-config for configuration cascade management
require 'ace/support/config'

# Atoms
require_relative "timestamp/atoms/compact_id_encoder"
require_relative "timestamp/atoms/formats"

# Molecules
require_relative "timestamp/molecules/config_resolver"

# Commands
require_relative "timestamp/commands/encode_command"
require_relative "timestamp/commands/decode_command"
require_relative "timestamp/commands/config_command"

# CLI
require_relative "timestamp/cli"

module Ace
  # Timestamp module providing Base36 compact ID generation for timestamps.
  #
  # This module provides a 6-character Base36 encoding for timestamps that
  # replaces traditional 14-character timestamp formats (YYYYMMDD-HHMMSS).
  #
  # @example Quick encoding
  #   Ace::Timestamp.encode(Time.now)
  #   # => "i50jj3"
  #
  # @example Quick decoding
  #   Ace::Timestamp.decode("i50jj3")
  #   # => 2025-01-06 12:30:00 UTC
  #
  # @example Format detection
  #   Ace::Timestamp.detect_format("i50jj3")      # => :compact
  #   Ace::Timestamp.detect_format("20250106-123000") # => :timestamp
  #
  module Timestamp
    class Error < StandardError; end

    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Encode a Time object to a compact ID (convenience method)
    #
    # @param time [Time] The time to encode
    # @param year_zero [Integer, nil] Optional year_zero override
    # @return [String] 6-character compact ID
    def self.encode(time, year_zero: nil)
      config = Molecules::ConfigResolver.resolve(year_zero: year_zero)
      Atoms::CompactIdEncoder.encode(
        time,
        year_zero: config[:year_zero],
        alphabet: config[:alphabet]
      )
    end

    # Decode a compact ID to a Time object (convenience method)
    #
    # @param compact_id [String] The 6-character compact ID
    # @param year_zero [Integer, nil] Optional year_zero override
    # @return [Time] Decoded time in UTC
    def self.decode(compact_id, year_zero: nil)
      config = Molecules::ConfigResolver.resolve(year_zero: year_zero)
      Atoms::CompactIdEncoder.decode(
        compact_id,
        year_zero: config[:year_zero],
        alphabet: config[:alphabet]
      )
    end

    # Validate if a string is a valid compact ID
    #
    # @param compact_id [String] The string to validate
    # @return [Boolean] True if valid compact ID format
    def self.valid?(compact_id)
      Atoms::CompactIdEncoder.valid?(compact_id)
    end

    # Detect the format of a timestamp string
    #
    # @param value [String] The timestamp string
    # @return [Symbol, nil] :compact, :timestamp, or nil
    def self.detect_format(value)
      Atoms::Formats.detect(value)
    end

    # Generate a compact ID for the current time (convenience method)
    #
    # @param year_zero [Integer, nil] Optional year_zero override
    # @return [String] 6-character compact ID for current time
    def self.now(year_zero: nil)
      encode(Time.now.utc, year_zero: year_zero)
    end

    # Load configuration using ace-config cascade
    # @return [Hash] Configuration hash
    def self.config
      Molecules::ConfigResolver.resolve
    end

    # Reset configuration cache (useful for testing)
    def self.reset_config!
      Molecules::ConfigResolver.reset!
    end
  end
end
