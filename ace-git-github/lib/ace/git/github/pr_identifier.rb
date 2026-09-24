# frozen_string_literal: true

module Ace
  module Git
    module Github
      # Parse GitHub pull request identifiers into structured form.
      #
      # Supports the GitHub-specific formats:
      # - Simple number: "123"
      # - Qualified reference: "owner/repo#456"
      # - GitHub URL: "https://github.com/owner/repo/pull/789"
      module PrIdentifier
        # `gh_format` is a stable identity; gh CLI requires --repo separately.
        ParseResult = Data.define(:number, :repo, :gh_format) do
          def cli_target_args
            repo ? [number, "--repo", repo] : [number]
          end
        end

        # Maximum length for PR identifier to bound regex work
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
            ParseResult.new(number: canonical_number, repo: nil, gh_format: canonical_number)
          when /\A(?<repo>[a-zA-Z0-9_\-.]+\/[a-zA-Z0-9_\-.]+)#(?<number>\d+)\z/
            match = ::Regexp.last_match
            ParseResult.new(number: match[:number], repo: match[:repo], gh_format: "#{match[:repo]}##{match[:number]}")
          when %r{\Ahttps://github\.com/(?<repo>[^/]+/[^/]+)/pull/(?<number>\d+)}
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
