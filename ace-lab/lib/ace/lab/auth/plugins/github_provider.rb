# frozen_string_literal: true

require "json"
require "openssl"
require "base64"

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
          def initialize(runner: nil)
            @runner = runner || method(:run_curl)
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
            payload = JSON.generate({"repositories" => lease.fetch("repos"),
              "permissions" => github_permissions(profile.fetch("scopes"))}.compact)
            result = @runner.call(
              ["curl", "-sS", "-f", "-X", "POST",
                "#{base}/app/installations/#{installation}/access_tokens",
                "-H", "Accept: application/vnd.github+json",
                "-H", "Authorization: Bearer #{jwt}",
                "-d", payload]
            )
            body = JSON.parse(result)
            token = body["token"] or raise Providers::TransientError, "github did not return an installation token"
            {"token" => token, "token_ref" => body["id"].to_s,
             "provider_expiry" => body["expires_at"],
             "via" => {"kind" => "file"}}
          rescue JSON::ParserError
            raise Providers::TransientError, "github returned an unparseable response"
          end

          def revoke(profile:, token_ref:)
            issuer = profile.fetch("issuer")
            base = issuer["api_url"] || "https://api.github.com"
            installation = issuer["installation_id"] or raise Providers::RefusedError,
              "github profile has no installation_id"
            key_file = issuer["key_file"]
            app_id = issuer["app_id"]
            jwt = app_jwt(app_id, File.read(key_file))
            _out, err, status = run_capture(
              ["curl", "-sS", "-X", "DELETE",
                "#{base}/installation/token",
                "-H", "Authorization: Bearer #{jwt}"]
            )
            return :revoked if status.success?

            if status.exitstatus == 401 || err.include?("401")
              # 401 on the installation endpoint means the token is
              # already invalid — an idempotent result, not a failure.
              return :already_invalid
            end

            raise Providers::OutcomeUnknownError,
              "github revoke outcome unknown: #{err.to_s.lines.first&.strip}"
          end

          private

          # Profile scopes map onto installation token permissions
          # (read/write per subject); the deployment's App installation
          # must already grant them — the request cannot widen rights.
          def github_permissions(scopes)
            scopes.to_h do |scope|
              subject, level = scope.split(":", 2)
              [subject, level || "read"]
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
