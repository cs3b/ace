# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Parse PR identifiers into structured format
      #
      # Supports three formats:
      # - Simple number: "123"
      # - Qualified reference: "owner/repo#456"
      # - GitHub URL: "https://github.com/owner/repo/pull/789"
      #
      # Consolidated from ace-bundle PrIdentifierParser
      module PrIdentifierParser
        # Parsed PR identifier result
        ParseResult = Data.define(:number, :repo, :gh_format)

        # Parse a PR identifier string
        #
        # Returns nil for nil/empty input (no PR specified), raises ArgumentError for
        # invalid formats. This design allows callers to distinguish between "no PR"
        # (nil input -> nil result) and "invalid PR" (bad format -> exception).
        #
        # @param input [String, Integer] PR identifier
        # @return [ParseResult, nil] Parsed identifier with number, repo, and gh_format,
        #   or nil if input is nil/empty
        # @raise [ArgumentError] if identifier format is invalid (non-empty but malformed)
        #
        # @example Simple number
        #   parse(123)
        #   # => ParseResult(number: "123", repo: nil, gh_format: "123")
        #
        # @example Qualified reference
        #   parse("owner/repo#456")
        #   # => ParseResult(number: "456", repo: "owner/repo", gh_format: "owner/repo#456")
        #
        # @example GitHub URL
        #   parse("https://github.com/owner/repo/pull/789")
        #   # => ParseResult(number: "789", repo: "owner/repo", gh_format: "owner/repo#789")
        #
        # @example Nil/empty input
        #   parse(nil)   # => nil
        #   parse("")    # => nil
        #   parse("  ")  # => nil
        # Maximum length for PR identifier to prevent ReDoS attacks
        # GitHub URLs are typically under 200 chars, this provides generous margin
        MAX_IDENTIFIER_LENGTH = 256

        def self.parse(input)
          return nil if input.nil?

          input_str = input.to_s.strip
          return nil if input_str.empty?

          # Validate length to prevent ReDoS attacks on regex patterns
          if input_str.length > MAX_IDENTIFIER_LENGTH
            raise ArgumentError, "PR identifier too long (max #{MAX_IDENTIFIER_LENGTH} characters)"
          end

          case input_str
          when /^(\d+)$/
            # Simple PR number: "123"
            number = ::Regexp.last_match(1)
            # Reject zero: GitHub PR numbers are positive integers starting from 1
            raise ArgumentError, "Invalid PR identifier format: #{input_str}" if number.to_i.zero?
            # Normalize to canonical form (strip leading zeros) for consistent gh_format
            canonical_number = number.to_i.to_s
            ParseResult.new(number: canonical_number, repo: nil, gh_format: canonical_number)

          when /^(?<repo>[a-zA-Z0-9_\-.]+\/[a-zA-Z0-9_\-.]+)#(?<number>\d+)$/
            # Qualified reference: "owner/repo#456"
            # GitHub owner/repo names: alphanumeric, hyphens, underscores, dots only
            match = ::Regexp.last_match
            ParseResult.new(number: match[:number], repo: match[:repo], gh_format: "#{match[:repo]}##{match[:number]}")

          when %r{github\.com/(?<repo>[^/]+/[^/]+)/pull/(?<number>\d+)}
            # GitHub URL: "https://github.com/owner/repo/pull/789"
            match = ::Regexp.last_match
            ParseResult.new(number: match[:number], repo: match[:repo], gh_format: "#{match[:repo]}##{match[:number]}")

          else
            raise ArgumentError, "Invalid PR identifier format: #{input_str}"
          end
        end
      end
    end
  end
end
