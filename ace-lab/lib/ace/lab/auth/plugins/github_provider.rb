# frozen_string_literal: true

require "json"
require "openssl"
require "base64"
require "tempfile"

module Ace
  module Lab
    module Auth
      module Plugins
        # GitHub provider (task 8xs.t.pu0.7): GitHub App JWT →
        # installation access token for the CHOSEN repositories and
        # permissions; the response's real `expires_at` becomes the
        # provider expiry the status reports separately from the
        # lease's use-until. The App key NEVER reaches the executor;
        # the issued token is opaque, one per lease. An earlier
        # use-until than the native expiry requires the host's
        # scheduled revoke at use_until (DELETE /installation/token —
        # 401 means the token is already invalid, anything else
        # network-shaped stays outcome-unknown, never a claimed
        # revocation).
        class GithubProvider
          def initialize(runner: nil, capture: nil)
            @runner = runner || method(:run_curl)
            @capture = capture || method(:run_capture)
          end

          def capabilities
            {"expiry_mode" => "provider"}
          end

          def issue(profile:, lease:)
            issuer = profile.fetch("issuer")
            base = issuer["api_url"] || "https://api.github.com"
            installation = issuer["installation_id"] or raise Providers::RefusedError,
              "github profile has no installation_id"
            key_file = issuer["key_file"] or raise Providers::RefusedError, "github profile has no key_file reference"
            app_id = issuer["app_id"] or raise Providers::RefusedError, "github profile has no app_id"
            raise Providers::RefusedError, "app key file '#{key_file}' is not readable" unless File.readable?(key_file)

            jwt = app_jwt(app_id, File.read(key_file))
            repos = lease.fetch("repos")
            if repos.empty?
              raise Providers::RefusedError,
                "an empty repository list would mint a token for ALL installation " \
                "repositories — refuse before issuing"
            end

            payload = JSON.generate({"repositories" => repos,
              "permissions" => github_permissions(profile.fetch("scopes"))}.compact)
            result = with_secret_header("Authorization: Bearer #{jwt}") do |header|
              @runner.call(
                ["curl", "-sS", "-f", "-X", "POST",
                  "#{base}/app/installations/#{installation}/access_tokens",
                  "-H", "Accept: application/vnd.github+json",
                  *header,
                  "-d", payload]
              )
            end
            body = JSON.parse(result)
            token = body["token"] or raise Providers::TransientError, "github did not return an installation token"
            {"token" => token, "token_ref" => body["id"].to_s,
             "provider_expiry" => body["expires_at"],
             "via" => {"kind" => "file"}}
          rescue JSON::ParserError
            raise Providers::TransientError, "github returned an unparseable response"
          end

          # GitHub revokes the installation token that AUTHENTICATES
          # the request (DELETE /installation/token -> 204): the
          # credential is the ISSUED lease token, never a fresh App
          # JWT - an App JWT names no installation token and revokes
          # nothing. curl runs with --fail so an HTTP error can never
          # surface as process success; 401 means the token is already
          # invalid (an idempotent result), anything else
          # network-shaped stays outcome-unknown, never a claimed
          # revocation.
          def revoke(profile:, token_ref:, token: nil)
            if token.to_s.empty?
              raise Providers::OutcomeUnknownError,
                "the issued installation token (token_ref #{token_ref}) is required to revoke " \
                "it - GitHub revokes the token that authenticates the request; outcome unknown"
            end

            issuer = profile.fetch("issuer")
            base = issuer["api_url"] || "https://api.github.com"
            _out, err, status = with_secret_header("Authorization: Bearer #{token}") do |header|
              @capture.call(
                ["curl", "-sS", "-f", "-X", "DELETE",
                  "#{base}/installation/token",
                  "-H", "Accept: application/vnd.github+json",
                  *header]
              )
            end
            return :revoked if status.success?

            if err.to_s.match?(/\b401\b/)
              # 401 on the installation endpoint means the token is
              # already invalid — an idempotent result, not a failure.
              return :already_invalid
            end

            raise Providers::OutcomeUnknownError,
              "github revoke outcome unknown: #{err.to_s.lines.first&.strip}"
          end

          # No deterministic remote identity: the installation token's
          # id is only known from the creation RESPONSE — an unknown
          # issue outcome cannot be settled by reconstruction and must
          # wait for reconcile/native expiry, never a blind re-mint.
          def token_ref_for(lease_id:)
            nil
          end

          # GitHub's OWN permission schema for installation tokens —
          # these are the real permission keys of the
          # POST /app/installations/{id}/access_tokens contract (NOT
          # Forgejo repository rights): blanket-mapping one provider's
          # subjects onto the other silently produces permission keys
          # the endpoint rejects or ignores.
          INSTALLATION_PERMISSIONS = %w[
            actions administration checks content_references contents
            deployments environments issues labels members merge_queues
            metadata organization_administration organization_custom_org_roles
            organization_custom_properties organization_hooks
            organization_packages organization_personal_access_requests
            organization_personal_access_tokens organization_plan
            organization_projects organization_rulesets organization_secrets
            organization_self_hosted_runners organization_user_blocking
            packages pages pull_requests repository_advisories
            repository_hooks repository_projects secret_scanning_alerts
            secrets security_events statuses team_discussions
            vulnerability_alerts workflows
          ].freeze
          PERMISSION_LEVELS = %w[read write admin].freeze

          private

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

          # Profile scopes map onto installation token permissions as
          # `level:subject` strings validated against GitHub's actual
          # permission schema (e.g. `write:contents` →
          # {"contents" => "write"}); the deployment's App installation
          # must already grant them — the request cannot widen rights.
          def github_permissions(scopes)
            scopes.to_h do |scope|
              level, subject = scope.split(":", 2)
              subject, level = scope, "read" if subject.nil?
              if subject.empty? || level.empty? || !PERMISSION_LEVELS.include?(level)
                raise Providers::RefusedError,
                  "github scope '#{scope}' is malformed (expected level:subject with " \
                  "level in #{PERMISSION_LEVELS.join('|')}, e.g. write:contents)"
              end
              unless INSTALLATION_PERMISSIONS.include?(subject)
                raise Providers::RefusedError,
                  "github scope '#{scope}': '#{subject}' is not a GitHub installation " \
                  "permission (real examples: contents, pull_requests, members, issues) " \
                  "— GitHub permission names are not Forgejo repository scopes"
              end

              [subject, level]
            end
          end

          # Minimal RS256 GitHub App JWT (stdlib only): the App key
          # stays issuer-side; the JWT lives for one request window.
          def app_jwt(app_id, key_pem)
            key = OpenSSL::PKey::RSA.new(key_pem)
            now = Time.now.to_i
            header = Base64.urlsafe_encode64(JSON.generate({"alg" => "RS256", "typ" => "JWT"}),
              padding: false)
            claims = Base64.urlsafe_encode64(JSON.generate({
              "iat" => now - 60, "exp" => now + 540, "iss" => app_id
            }), padding: false)
            signature = Base64.urlsafe_encode64(key.sign("SHA256", "#{header}.#{claims}"),
              padding: false)
            "#{header}.#{claims}.#{signature}"
          end

          def run_curl(argv)
            out, _err, status = run_capture(argv)
            raise Providers::TransientError, "github API call failed (exit #{status.exitstatus})" unless status.success?

            out
          end

          def run_capture(argv)
            require "open3"
            Open3.capture3(*argv)
          end
        end
      end
    end
  end
end
