# frozen_string_literal: true

require_relative "b36ts/version"

# Load ace-config for configuration cascade management
require "ace/support/config"

# Atoms
require_relative "b36ts/atoms/compact_id_encoder"
require_relative "b36ts/atoms/formats"
require_relative "b36ts/atoms/format_specs"

# Molecules
require_relative "b36ts/molecules/config_resolver"

# Commands
require_relative "b36ts/commands/encode_command"
require_relative "b36ts/commands/decode_command"
require_relative "b36ts/commands/config_command"

# CLI
require_relative "b36ts/cli"

module Ace
  # B36ts module providing Base36 compact ID generation for timestamps.
  #
  # This module provides a 6-character Base36 encoding for timestamps that
  # replaces traditional 14-character timestamp formats (YYYYMMDD-HHMMSS).
  #
  # @example Quick encoding
  #   Ace::B36ts.encode(Time.now)
  #   # => "i50jj3"
  #
  # @example Quick decoding
  #   Ace::B36ts.decode("i50jj3")
  #   # => 2025-01-06 12:30:00 UTC
  #
  # @example Format detection
  #   Ace::B36ts.detect_format("i50jj3")      # => :"2sec"
  #   Ace::B36ts.detect_format("20250106-123000") # => :timestamp
  #
  module B36ts
    class Error < StandardError; end

    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Encode a Time object to a compact ID (convenience method)
    #
    # @param time [Time] The time to encode
    # @param format [Symbol, nil] Output format (default: :"2sec")
    #   Supported formats: :month (2 chars), :week (3 chars), :day (3 chars),
    #   :"40min" (4 chars), :"2sec" (6 chars), :"50ms" (7 chars), :ms (8 chars)
    # @param year_zero [Integer, nil] Optional year_zero override
    # @return [String] Compact ID (length varies by format)
    def self.encode(time, format: nil, year_zero: nil)
      config = Molecules::ConfigResolver.resolve(year_zero: year_zero)
      effective_format = format || config[:default_format]&.to_sym || :"2sec"

      Atoms::CompactIdEncoder.encode_with_format(
        time,
        format: effective_format,
        year_zero: config[:year_zero],
        alphabet: config[:alphabet]
      )
    end

    # Decode a compact ID to a Time object (convenience method)
    #
    # @param compact_id [String] The compact ID to decode
    # @param format [Symbol, nil] Format of the ID (default: :"2sec" for 6-char, or auto-detect)
    # @param year_zero [Integer, nil] Optional year_zero override
    # @return [Time] Decoded time in UTC
    def self.decode(compact_id, format: nil, year_zero: nil)
      config = Molecules::ConfigResolver.resolve(year_zero: year_zero)

      if format
        Atoms::CompactIdEncoder.decode_with_format(
          compact_id,
          format: format,
          year_zero: config[:year_zero],
          alphabet: config[:alphabet]
        )
      else
        # Default to 2sec format for backward compatibility with 6-char IDs
        Atoms::CompactIdEncoder.decode(
          compact_id,
          year_zero: config[:year_zero],
          alphabet: config[:alphabet]
        )
      end
    end

    # Decode a compact ID with automatic format detection (convenience method)
    #
    # Automatically detects the format based on ID length and value ranges:
    # - 2 chars: month format
    # - 3 chars: day or week format (auto-detected by 3rd char value)
    # - 4 chars: 40min format
    # - 6 chars: 2sec format
    # - 7 chars: 50ms format
    # - 8 chars: ms format
    #
    # @param compact_id [String] The compact ID to decode (2-8 characters)
    # @param year_zero [Integer, nil] Optional year_zero override
    # @return [Time] Decoded time in UTC
    # @raise [ArgumentError] If format cannot be detected
    def self.decode_auto(compact_id, year_zero: nil)
      config = Molecules::ConfigResolver.resolve(year_zero: year_zero)
      Atoms::CompactIdEncoder.decode_auto(
        compact_id,
        year_zero: config[:year_zero],
        alphabet: config[:alphabet]
      )
    end

    # Encode a Time object into split components for hierarchical paths
    #
    # @param time [Time] The time to encode
    # @param levels [Array<Symbol>, String] Split levels (month, week, day, block)
    # @param path_only [Boolean] Return only the path string
    # @param year_zero [Integer, nil] Optional year_zero override
    # @return [Hash, String] Split component hash or path string
    def self.encode_split(time, levels:, path_only: false, year_zero: nil)
      config = Molecules::ConfigResolver.resolve(year_zero: year_zero)
      result = Atoms::CompactIdEncoder.encode_split(
        time,
        levels: levels,
        year_zero: config[:year_zero],
        alphabet: config[:alphabet]
      )

      path_only ? result[:path] : result
    end

    # Decode a hierarchical split path into a Time object
    #
    # @param path_string [String] Split path string
    # @param year_zero [Integer, nil] Optional year_zero override
    # @return [Time] Decoded time in UTC
    def self.decode_path(path_string, year_zero: nil)
      config = Molecules::ConfigResolver.resolve(year_zero: year_zero)
      Atoms::CompactIdEncoder.decode_path(
        path_string,
        year_zero: config[:year_zero],
        alphabet: config[:alphabet]
      )
    end

    # Validate if a string is a valid 6-character compact ID (legacy method)
    #
    # NOTE: This method only validates 6-character "2sec" format IDs.
    # For validating IDs of any format, use valid_any_format? instead.
    #
    # @param compact_id [String] The string to validate
    # @return [Boolean] True if valid 6-char compact ID format
    # @see valid_any_format? for validating all format lengths
    def self.valid?(compact_id)
      Atoms::CompactIdEncoder.valid?(compact_id)
    end

    # Validate if a string is a valid compact ID of any format
    #
    # Supports all 7 formats: month (2 chars), week (3 chars), day (3 chars),
    # 40min (4 chars), 2sec (6 chars), 50ms (7 chars), ms (8 chars).
    #
    # @param compact_id [String] The string to validate (2-8 characters)
    # @return [Boolean] True if valid compact ID of any format
    def self.valid_any_format?(compact_id)
      Atoms::CompactIdEncoder.valid_any_format?(compact_id)
    end

    # Detect the format of a timestamp string
    #
    # @param value [String] The timestamp string
    # @return [Symbol, nil] :"2sec", :timestamp, or nil
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
