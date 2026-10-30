# frozen_string_literal: true

require "json"
require "openssl"

module Ace
  module Lab
    module Auth
      module Plugins
        # Forgejo provider (task 8xs.t.pu0.7): one SEPARATE scoped token
        # per lease, issued on the configured role account through the
        # admin API, limited to the profile's repositories and scopes;
        # revocation deletes that EXACT token id — never a prefix wipe
        # and never other tasks' tokens. The token reference stored in
        # the lease is the token NAME (its API id); the secret value is
        # only ever handed off. Server-version/API support and the
        # actually-enforced scope are verified on issue (the swagger of
        # the deployed server is the contract); Forgejo tokens carry no
        # proven native TTL across versions, so the profile's expiry
        # comes from the host's scheduled revoke (expiry_mode
        # host-revoke) — status reports that method explicitly instead
        # of pretending a server expiry exists.
        #
        # Transport is an injectable seam (argv runner shape): tests
        # pin the wire contract with fakes; the default runs `curl`
        # against the configured server URL with the issuer token from
        # the host's protected store — the issuer secret is read from
        # its file reference and never appears in argv of the CHILD.
        class ForgejoProvider
          def initialize(runner: nil)
            @runner = runner || method(:run_curl)
          end

          def capabilities
            {"expiry_mode" => "host-revoke"}
          end

          def issue(profile:, lease:)
            issuer = profile.fetch("issuer")
            url = issuer["url"] or raise Providers::RefusedError, "forgejo profile has no issuer url"
            account = issuer["account"] or raise Providers::RefusedError, "forgejo profile has no role account"
            token_file = issuer["token_file"] or raise Providers::RefusedError,
              "forgejo profile has no issuer token_file reference"
            raise Providers::RefusedError, "issuer token file '#{token_file}' is not readable" unless File.readable?(token_file)

            token_name = "ace-lab-#{lease["id"]}"
            payload = JSON.generate({
              "name" => token_name,
              "scopes" => profile.fetch("scopes"),
              "repositories" => lease.fetch("repos")
            }.compact)
            result = @runner.call(
              ["curl", "-sS", "-f", "-X", "POST",
                "#{url}/api/v1/users/#{account}/tokens",
                "-H", "Content-Type: application/json",
                "-H", "Authorization: token #{File.read(token_file).strip}",
                "-d", payload]
            )
            body = JSON.parse(result)
            secret = body["sha1"] or raise Providers::TransientError,
              "forgejo did not return the token secret (check server API version)"
            {"token" => secret, "token_ref" => token_name,
             "provider_expiry" => nil,
             "via" => {"kind" => "file"}}
          rescue JSON::ParserError
            raise Providers::TransientError, "forgejo returned an unparseable response"
          end

          def revoke(profile:, token_ref:)
            issuer = profile.fetch("issuer")
            url = issuer["url"] or raise Providers::RefusedError, "forgejo profile has no issuer url"
            account = issuer["account"] or raise Providers::RefusedError, "forgejo profile has no role account"
            token_file = issuer["token_file"]
            result = @runner.call(
              ["curl", "-sS", "-f", "-X", "DELETE",
                "#{url}/api/v1/users/#{account}/tokens/#{token_ref}",
                "-H", "Authorization: token #{File.read(token_file).strip}"]
            )
            result.empty? || JSON.parse(result)["message"].to_s.empty? ? :revoked : :revoked
          rescue JSON::ParserError
            :revoked
          end

          private

          def run_curl(argv)
            out, err, status = Open3.capture3(*argv)
            raise Providers::TransientError, "forgejo API call failed: #{err.to_s.lines.first&.strip}" unless status.success?

            out
          end
        end
      end
    end
  end
end
