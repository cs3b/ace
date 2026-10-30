# frozen_string_literal: true

require "json"
require "openssl"
require "open3"
require "tempfile"

module Ace
  module Lab
    module Auth
      module Plugins
        # Forgejo provider (task 8xs.t.pu0.7): one SEPARATE scoped token
        # per lease, issued on the configured role account through the
        # TOKEN-AUTHENTICATED ADMIN API, limited to the profile's
        # repositories and scopes; revocation deletes that EXACT token
        # name — never a prefix wipe and never other tasks' tokens.
        #
        # Wire contract (PR #398 re-review R1): the issuer credential is
        # an admin PAT, so both endpoints are the admin variants
        # (`POST/DELETE /api/v1/admin/users/{account}/tokens`) — the
        # user-scoped `/api/v1/users/.../tokens` requires BasicAuth or
        # reverse-proxy auth and does not accept `Authorization: token`.
        # Repository scoping uses the server's RepoTargetOption shape:
        # objects with `owner` and `name`. A repo entry without an
        # owner does not identify anything and is REFUSED before any
        # request — never an all-repositories token. The creation
        # response's granted scopes are validated against the request
        # when the server reports them; a mismatch is a classified
        # failure, never a trusted grant. Forgejo tokens carry no proven
        # native TTL across versions, so the profile's expiry comes
        # from the host's scheduled revoke (expiry_mode host-revoke).
        #
        # The token NAME is deterministic from the lease id
        # (`ace-lab-<lease id>`): it is written to the lease record at
        # CREATION, so an interrupted issue (lost response, dead
        # process) can still be settled deterministically — the name is
        # reconstructed and revoked; a 404 means it never existed
        # remotely (:already_invalid, an idempotent result).
        #
        # Transport is an injectable seam (argv runner/capture shapes):
        # tests pin the wire contract with fakes emulating the server;
        # the default runs `curl` with the issuer token from the host's
        # protected store. The issuer secret is read from its file
        # reference and never appears in argv of the CHILD.
        class ForgejoProvider
          def initialize(runner: nil, capture: nil)
            @runner = runner || method(:run_curl)
            @capture = capture || method(:run_capture)
          end

          def capabilities
            {"expiry_mode" => "host-revoke"}
          end

          # Deterministic remote identity: the Forgejo token name is
          # derived from the lease id alone — known before any response.
          def token_ref_for(lease_id:)
            "ace-lab-#{lease_id}"
          end

          def issue(profile:, lease:)
            issuer = profile.fetch("issuer")
            url = issuer["url"] or raise Providers::RefusedError, "forgejo profile has no issuer url"
            account = issuer["account"] or raise Providers::RefusedError, "forgejo profile has no role account"
            token_file = issuer["token_file"] or raise Providers::RefusedError,
              "forgejo profile has no issuer token_file reference"
            raise Providers::RefusedError, "issuer token file '#{token_file}' is not readable" unless File.readable?(token_file)

            token_name = token_ref_for(lease_id: lease["id"])
            scopes = profile.fetch("scopes")
            repositories = repo_targets(lease.fetch("repos"))

            payload = JSON.generate({
              "name" => token_name,
              "scopes" => scopes,
              "repositories" => repositories
            }.compact)
            result = with_secret_header("Authorization: token #{File.read(token_file).strip}") do |header|
              @runner.call(
                ["curl", "-sS", "-f", "-X", "POST",
                  "#{url}/api/v1/admin/users/#{account}/tokens",
                  "-H", "Content-Type: application/json",
                  *header,
                  "-d", payload]
              )
            end
            body = JSON.parse(result)
            secret = body["sha1"] or raise Providers::TransientError,
              "forgejo did not return the token secret (check server API version)"
            validate_granted_scopes(body, scopes)

            {"token" => secret, "token_ref" => token_name,
             "provider_expiry" => nil,
             "via" => {"kind" => "file"}}
          rescue JSON::ParserError
            raise Providers::TransientError, "forgejo returned an unparseable response"
          end

          # The lease token is revoked by its server id (the
          # deterministic token NAME) with the issuer's admin
          # credential; the secret value is not part of this wire
          # contract. 404 is the idempotent already-invalid result —
          # deterministic recovery of an interrupted issue.
          def revoke(profile:, token_ref:, token: nil)
            issuer = profile.fetch("issuer")
            url = issuer["url"] or raise Providers::RefusedError, "forgejo profile has no issuer url"
            account = issuer["account"] or raise Providers::RefusedError, "forgejo profile has no role account"
            token_file = issuer["token_file"]
            _out, err, status = with_secret_header("Authorization: token #{File.read(token_file).strip}") do |header|
              @capture.call(
                ["curl", "-sS", "-f", "-X", "DELETE",
                  "#{url}/api/v1/admin/users/#{account}/tokens/#{token_ref}",
                  *header]
              )
            end
            return :revoked if status.success?
            return :already_invalid if err.to_s.match?(/\b404\b/)

            raise Providers::TransientError,
              "forgejo revoke failed: #{err.to_s.lines.first&.strip}"
          end

          private

          # RepoTargetOption: {"owner" =>, "name" =>} objects parsed
          # from `owner/name` entries. An entry without an owner does
          # not identify a repository — refusing beats issuing an
          # all-repositories token.
          def repo_targets(repos)
            if repos.empty?
              raise Providers::RefusedError,
                "an empty repositories payload would mint a token for ALL of the " \
                "account's repositories — refuse before issuing"
            end

            repos.map do |entry|
              owner, name = entry.to_s.split("/", 2)
              if owner.to_s.empty? || name.to_s.empty?
                raise Providers::RefusedError,
                  "repository '#{entry}' is not an identifiable 'owner/name' target — " \
                  "Forgejo RepoTargetOption requires both; refusing instead of issuing " \
                  "an all-repositories token"
              end
              {"owner" => owner, "name" => name}
            end
          end

          # The response's granted scopes (when the server reports
          # them) must cover the request — the enforced scope is the
          # server's answer, never the request's claim.
          def validate_granted_scopes(body, requested)
            granted = body["scopes"]
            return unless granted.is_a?(Array)

            missing = requested.map(&:to_s) - granted.map(&:to_s)
            unless missing.empty?
              raise Providers::TransientError,
                "forgejo granted scopes [#{granted.join(', ')}] do not cover the " \
                "requested [#{missing.join(', ')}]; refusing the grant"
            end
          end

          # The Authorization secret NEVER appears in curl argv (visible
          # in ps): the header value lives in a 0600 ephemeral file for
          # the duration of one request, passed as `curl -H @file`.
          def with_secret_header(header)
            Tempfile.create("ace-lab-curl-header") do |file|
              file.chmod(0o600)
              file.write("#{header}\n")
              file.close
              yield ["-H", "@#{file.path}"]
            end
          end

          def run_curl(argv)
            out, _err, status = run_capture(argv)
            raise Providers::TransientError, "forgejo API call failed (curl exit #{status.exitstatus})" unless status.success?

            out
          end

          def run_capture(argv)
            Open3.capture3(*argv)
          end
        end
      end
    end
  end
end
