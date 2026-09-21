# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Parse provider-neutral pull request identifiers into structured form.
      #
      # Supports the forge-neutral forms:
      # - Simple number: "123"
      # - Qualified reference: "owner/repo#456"
      #
      # Provider-specific identifier formats (for example full web URLs) belong
      # to the provider packages, not to the core.
      module PrIdentifier
        # Parsed identifier result
        ParseResult = Data.define(:number, :repo)

        # Maximum identifier length to bound regex work
        MAX_IDENTIFIER_LENGTH = 256

        # Parse a pull request identifier string.
        #
        # Returns nil for nil/empty input (no PR specified), raises ArgumentError
        # for invalid formats. This lets callers distinguish "no PR" (nil input)
        # from "invalid PR" (bad format).
        #
        # @param input [String, Integer] pull request identifier
        # @return [ParseResult, nil] parsed identifier, or nil for nil/empty input
        # @raise [ArgumentError] if identifier format is invalid
        #
        # @example Simple number
        #   parse(123) # => ParseResult(number: "123", repo: nil)
        #
        # @example Qualified reference
        #   parse("owner/repo#456") # => ParseResult(number: "456", repo: "owner/repo")
        #
        # @example Nil/empty input
        #   parse(nil) # => nil
        def self.parse(input)
          return nil if input.nil?

          input_str = input.to_s.strip
          return nil if input_str.empty?

          if input_str.length > MAX_IDENTIFIER_LENGTH
            raise ArgumentError, "PR identifier too long (max #{MAX_IDENTIFIER_LENGTH} characters)"
          end

          case input_str
          when /\A(\d+)\z/
            number = ::Regexp.last_match(1)
            raise ArgumentError, "Invalid PR identifier format: #{input_str}" if number.to_i.zero?

            # Canonical form (no leading zeros) for consistent downstream use
            ParseResult.new(number: number.to_i.to_s, repo: nil)
          when /\A(?<repo>[a-zA-Z0-9_\-.]+\/[a-zA-Z0-9_\-.]+)#(?<number>\d+)\z/
            match = ::Regexp.last_match
            ParseResult.new(number: match[:number], repo: match[:repo])
          else
            raise ArgumentError, "Invalid PR identifier format: #{input_str}"
          end
        end
      end
    end
  end
end
