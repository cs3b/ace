# frozen_string_literal: true

require "uri"
require "ace/git"

module Ace
  module Task
    module Molecules
      # Resolves and validates the one persisted remote issue identity.
      module IssueLink
        FIELDS = %w[server_name provider repository_url number url].freeze

        module_function

        def from_input(input, server_name: nil, use_default: false)
          value = input.to_s.strip
          raise ArgumentError, "Issue identifier is empty" if value.empty?

          selected = server_name || use_default ?
            Ace::Git::ServerRegistry.resolve_for(server_name: server_name, use_default: use_default) : nil
          number, candidates = if value.match?(/\A[1-9]\d*\z/)
            [value.to_i, nil]
          elsif (match = value.match(%r{\A(https?://[^\s]+?)/issues/([1-9]\d*)\z}))
            [match[2].to_i, Ace::Git::ServerRegistry.matching_servers(match[1])]
          elsif (match = value.match(/\A([^\s#]+\/[^\s#]+)#([1-9]\d*)\z/))
            [match[2].to_i, Ace::Git::ServerRegistry.servers_for_owner_repo(match[1])]
          else
            raise ArgumentError, "Invalid issue identifier #{input.inspect}; use a positive number or issue URL"
          end

          if candidates
            raise Ace::Git::AmbiguousRemoteError, "Issue repository matches no configured server" if candidates.empty?
            # A URL input must resolve uniquely on its own; explicit selection
            # filters but never disambiguates multiple matches.
            raise Ace::Git::AmbiguousRemoteError,
              "Issue repository matches multiple configured servers" if candidates.length != 1
            if selected && candidates.first.name != selected.name
              raise Ace::Git::ProviderIdentityMismatchError,
                "Issue identifier does not match selected server #{selected.name}"
            end
            selected ||= candidates.first
          else
            selected ||= Ace::Git::ServerRegistry.resolve_for
          end

          {
            "server_name" => selected.name,
            "provider" => selected.provider.to_s,
            "repository_url" => selected.url,
            "number" => number,
            "url" => "#{Ace::Git::Atoms::ServerUrl.web_base(selected.url)}/issues/#{number}"
          }
        end

        def validate!(mapping)
          unless mapping.is_a?(Hash) && mapping.keys.map(&:to_s).sort == FIELDS.sort
            raise ArgumentError, "remote_issue must contain exactly #{FIELDS.join(', ')}"
          end
          identity = mapping.transform_keys(&:to_s)
          number = identity["number"]
          unless number.is_a?(Integer) && number.positive?
            raise ArgumentError, "remote_issue.number must be a positive integer"
          end
          server = Ace::Git::ServerRegistry.resolve(identity["server_name"])
          expected = from_input(number.to_s, server_name: server.name)
          unless identity == expected
            raise Ace::Git::ProviderIdentityMismatchError,
              "Stored remote_issue identity for #{server.name} no longer matches its configured repository/provider"
          end
          server
        end
      end
    end
  end
end
