# frozen_string_literal: true

require "json"
require "base64"
require "openssl"
require "open3"
require "tempfile"
require "tmpdir"
require "fileutils"
require "uri"
require "rbconfig"
require "ipaddr"
require_relative "../credential_handoff"

module Ace
  module Lab
    module Auth
      module Plugins
        # Forgejo 15 requires Basic authentication with an administrator
        # credential and Sudo header on the user-token endpoints.  The
        # credential stays in a private, temporary curl header file.  A
        # successful issue must prove the returned repository restrictions.
        # Host-owned issuance and timed revocation are separate requirements.
        class ForgejoProvider
          ASKPASS = File.expand_path("../../../../../libexec/forgejo-askpass", __dir__).freeze
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

          # fj and ACE's Forgejo HTTP adapters read the same XDG login file.
          # Give this child only its leased token, with no ambient fj aliases
          # or logins, and remove the private directory when it exits.
          def with_exec_environment(profile:, credential:)
            unless linux_xdg?
              raise Providers::RefusedError, "forgejo session projection currently requires Linux XDG data directories"
            end
            issuer = profile["issuer"]
            url = issuer_origin!(issuer)
            host = url.hostname
            authority = host.include?(":") ? "[#{host}]" : host
            authority += ":#{url.port}" if url.port != url.default_port
            account = issuer["account"].to_s
            raise Providers::RefusedError, "forgejo role account is invalid" unless account.match?(/\A[a-zA-Z0-9_.-]+\z/)
            token = begin
              File.read(credential).strip
            rescue SystemCallError => e
              raise Providers::RefusedError, "forgejo lease credential is unreadable (#{e.class.name})"
            end
            raise Providers::RefusedError, "forgejo lease credential is empty" if token.empty?
            prefix = CredentialHandoff.projection_prefix(credential)
            Dir.mktmpdir(prefix, File.dirname(credential)) do |dir|
              login_dir = File.join(dir, "forgejo-cli")
              Dir.mkdir(login_dir, 0o700)
              File.open(File.join(login_dir, "keys.json"), File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
                file.write(JSON.generate({"hosts" => {authority => {"type" => "Application", "token" => token}},
                  "aliases" => {}, "default_ssh" => []}))
              end
              # When a root issuer delegates to an isolated OS session, the
              # session can read its files but cannot replace directories
              # while root removes the projection after execution.
              owner = File.stat(credential)
              if Process.euid.zero? && !owner.uid.zero?
                File.chmod(0o711, dir)
                File.chmod(0o711, login_dir)
                File.chown(owner.uid, owner.gid, File.join(login_dir, "keys.json"))
              end
              yield({"XDG_DATA_HOME" => dir, "GIT_ASKPASS" => ASKPASS, "GIT_TERMINAL_PROMPT" => "0",
                "GIT_CONFIG_COUNT" => "2", "GIT_CONFIG_KEY_0" => "credential.helper", "GIT_CONFIG_VALUE_0" => "",
                "GIT_CONFIG_KEY_1" => "credential.useHttpPath", "GIT_CONFIG_VALUE_1" => "false", "LC_ALL" => "C",
                "ACE_LAB_FORGEJO_ORIGIN" => "#{url.scheme}://#{authority}", "ACE_LAB_FORGEJO_SCHEME" => url.scheme,
                "ACE_LAB_FORGEJO_AUTHORITY" => authority, "ACE_LAB_FORGEJO_ACCOUNT" => account})
            end
          end

          def issue(profile:, lease:)
            issuer = profile["issuer"]
            url = issuer_origin!(issuer).to_s.chomp("/")
            account = issuer["account"] or raise Providers::RefusedError, "forgejo profile has no role account"
            header_value = issuer_header(issuer)

            token_name = token_ref_for(lease_id: lease["id"])
            scopes = profile.fetch("scopes")
            requested_repos = lease.fetch("repos")
            repositories = repo_targets(requested_repos)

            payload = JSON.generate({
              "name" => token_name,
              "scopes" => scopes,
              "repositories" => repositories
            }.compact)
            result = with_secret_header(header_value) do |header|
              @runner.call(
                ["curl", "-q", "--connect-timeout", "5", "--max-time", "20", "-sS", "-f", "-X", "POST",
                  "#{url}/api/v1/users/#{account}/tokens",
                  "-H", "Content-Type: application/json",
                  *header,
                  "-d", payload]
              )
            end
            body = JSON.parse(result)
            raise Providers::TransientError, "forgejo returned an invalid token response" unless body.is_a?(Hash)
            secret = body["sha1"]
            unless secret.is_a?(String) && !secret.empty?
              raise Providers::TransientError, "forgejo did not return the token secret (check server API version)"
            end
            validate_granted_scopes(body, scopes)
            validate_granted_repositories(body, requested_repos)

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
            issuer = profile["issuer"]
            url = issuer_origin!(issuer).to_s.chomp("/")
            account = issuer["account"] or raise Providers::RefusedError, "forgejo profile has no role account"
            _out, err, status = with_secret_header(issuer_header(issuer)) do |header|
              @capture.call(
                ["curl", "-q", "--connect-timeout", "5", "--max-time", "20", "-sS", "-f", "-X", "DELETE",
                  "#{url}/api/v1/users/#{account}/tokens/#{token_ref}",
                  *header]
              )
            end
            return :revoked if status.success?
            return :already_invalid if status.exitstatus == 22 &&
              err.to_s.match?(/(?:\A|\n)curl: \(22\) The requested URL returned error: 404\s*(?:\n|\z)/)

            raise Providers::TransientError,
              "forgejo revoke failed: #{err.to_s.lines.first&.strip}"
          end

          private

          def linux_xdg?
            RbConfig::CONFIG.fetch("host_os").start_with?("linux")
          end

          def issuer_origin!(issuer)
            raise Providers::RefusedError, "forgejo issuer is invalid" unless issuer.is_a?(Hash)
            url = URI.parse(issuer.fetch("url"))
            unless %w[http https].include?(url.scheme) && url.host && url.userinfo.nil? &&
                ["", "/"].include?(url.path.to_s) && url.query.nil? && url.fragment.nil?
              raise Providers::RefusedError, "forgejo issuer url must be a bare HTTP(S) origin"
            end
            if url.scheme == "http" && !loopback_host?(url.hostname)
              raise Providers::RefusedError, "forgejo issuer requires HTTPS except on loopback"
            end
            url
          rescue URI::InvalidURIError, KeyError, TypeError
            raise Providers::RefusedError, "forgejo issuer url is invalid"
          end

          def loopback_host?(host)
            return true if host.casecmp?("localhost")

            IPAddr.new(host).loopback?
          rescue IPAddr::InvalidAddressError
            false
          end

          def issuer_header(issuer)
            account = issuer["account"].to_s
            username = issuer["admin_username"].to_s
            path = issuer["password_file"].to_s
            unless account.match?(/\A[a-zA-Z0-9_.-]+\z/) && username.match?(/\A[a-zA-Z0-9_.-]+\z/)
              raise Providers::RefusedError, "forgejo issuer account and admin_username must be valid user names"
            end
            raise Providers::RefusedError, "forgejo issuer password file is not readable" unless File.file?(path) && File.readable?(path)
            password = File.read(path).strip
            raise Providers::RefusedError, "forgejo issuer password is empty" if password.empty?
            "Authorization: Basic #{Base64.strict_encode64("#{username}:#{password}")}\nSudo: #{account}"
          end

          def validate_granted_repositories(body, requested)
            repos = body["repositories"]
            granted = repos.map { |repo| repo.is_a?(Hash) ? repo["full_name"].to_s.downcase : "" }.sort if repos.is_a?(Array)
            return if granted && granted == requested.map { |repo| repo.to_s.downcase }.sort

            raise Providers::TransientError, "forgejo did not confirm the requested repository restrictions"
          end

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

          # The server's answer, not the request, establishes the grant.
          def validate_granted_scopes(body, requested)
            granted = body["scopes"]
            raise Providers::TransientError, "forgejo did not confirm granted scopes" unless granted.is_a?(Array)

            missing = requested.map(&:to_s) - granted.map(&:to_s)
            unless missing.empty?
              raise Providers::TransientError,
                "forgejo granted scopes [#{granted.join(', ')}] do not cover the " \
                "requested [#{missing.join(', ')}]; refusing the grant"
            end
            unless (granted.map(&:to_s) - requested.map(&:to_s)).empty?
              raise Providers::TransientError, "forgejo granted unrequested scopes; refusing the grant"
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
