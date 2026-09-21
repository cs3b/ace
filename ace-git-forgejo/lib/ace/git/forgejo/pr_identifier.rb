# frozen_string_literal: true

module Ace
  module Git
    module Forgejo
      # Parse Forgejo pull request URL references into structured form.
      #
      # Supports the Forgejo-specific formats:
      # - Simple number: "123"
      # - Qualified reference: "owner/repo#456"
      # - Forgejo URL: "https://forgejo.example.com/owner/repo/pulls/789"
      module PrIdentifier
        # Parsed identifier result. `forgejo_format` is the numeric form
        # accepted by `fj pr` commands.
        ParseResult = Data.define(:number, :repo, :forgejo_format)

        MAX_IDENTIFIER_LENGTH = 256

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

            canonical_number = number.to_i.to_s
            ParseResult.new(number: canonical_number, repo: nil, forgejo_format: canonical_number)
          when /\A(?<repo>[a-zA-Z0-9_\-.]+\/[a-zA-Z0-9_\-.]+)#(?<number>\d+)\z/
            match = ::Regexp.last_match
            ParseResult.new(number: match[:number], repo: match[:repo], forgejo_format: match[:number])
          when %r{\Ahttps?://[^/]+/(?<repo>[^/]+/[^/]+)/pulls/(?<number>\d+)\z}i
            match = ::Regexp.last_match
            ParseResult.new(number: match[:number], repo: match[:repo], forgejo_format: match[:number])
          else
            raise ArgumentError, "Invalid PR identifier format: #{input_str}"
          end
        end
      end
    end
  end
end
