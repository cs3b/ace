# frozen_string_literal: true

require_relative "server_url"

module Ace
  module Git
    module Atoms
      # Parse a user-supplied pull request identifier into its exact components.
      #
      # Three accepted shapes:
      # - bare number:            "25"
      # - owner/repo#number:      "cs3b/ace#25"
      # - full URL:               "https://forge.example.com/cs3b/ace/pull/25"
      #                           "https://forge.example.com/cs3b/ace/pulls/25"
      #
      # A URL's repository part is canonicalized through {ServerUrl.normalize}
      # so identity matching never assumes a hostname. Parsing is purely
      # textual; it never contacts a forge and never infers github.com.
      module PrReference
        # Parsed reference: `number` always present; exactly one of
        # `repository_url` (canonical URL form) or `owner_repo` is set for
        # explicit-repository shapes, both nil for a bare number.
        Reference = Data.define(:number, :repository_url, :owner_repo) do
          # @return [Boolean] true when the reference names a repository
          def repository_explicit?
            !repository_url.nil? || !owner_repo.nil?
          end

          # @return [Hash] plain representation
          def to_h
            {number: number, repository_url: repository_url, owner_repo: owner_repo}
          end
        end

        BARE_NUMBER_PATTERN = /\A\d+\z/
        OWNER_REPO_PATTERN = /\A(?<owner>[\w.\-]+)\/(?<repo>[\w.\-]+)#(?<number>\d+)\z/
        URL_PATTERN = %r{
          \Ahttps?://[^/\s]+/(?<path>.+?)/pulls?/(?<number>\d+)(?:[/?#].*)?\z
        }ix

        class << self
          # Parse a pull request identifier.
          #
          # @param input [String, Integer] identifier in any accepted shape
          # @return [Reference, nil] parsed reference, or nil when unrecognized
          def parse(input)
            text = input.to_s.strip
            return nil if text.empty?

            if (match = text.match(BARE_NUMBER_PATTERN))
              return Reference.new(number: match[0].to_i, repository_url: nil, owner_repo: nil)
            end

            if (match = text.match(OWNER_REPO_PATTERN))
              return Reference.new(
                number: match[:number].to_i,
                repository_url: nil,
                owner_repo: "#{match[:owner]}/#{match[:repo]}"
              )
            end

            if (match = text.match(URL_PATTERN))
              return Reference.new(
                number: match[:number].to_i,
                repository_url: ServerUrl.normalize("#{text.split("/")[0..2].join("/")}/#{match[:path]}"),
                owner_repo: nil
              )
            end

            nil
          end
        end
      end
    end
  end
end
