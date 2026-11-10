# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "base64"

module Ace
  module Lab
    module Auth
      # Forgejo 15 requires Basic admin credentials and sudo on the
      # user-token endpoints. Both scopes and repository restrictions must
      # be confirmed by the response; secrets never appear in argv.
      class ForgejoProviderTest < Minitest::Test
        Status = Struct.new(:success?, :exitstatus, keyword_init: true)

        def provider(response_body = {"sha1" => "SECRET", "id" => 1, "scopes" => ["write:repository"], "repositories" => [{"full_name" => "cs3b/ace"}]})
          @seen = []
          @headers = []
          runner = ->(argv) {
            at = argv.index { |part| part.is_a?(String) && part.start_with?("@") }
            @headers << (at ? File.read(argv[at][1..]).strip : nil)
            @seen << argv
            response_body.is_a?(String) ? response_body : JSON.generate(response_body)
          }
          Plugins::ForgejoProvider.new(runner: runner)
        end

        attr_reader :seen, :headers

        def profile
          token_file = File.join(Dir.mktmpdir, "issuer.token")
          File.write(token_file, "ISSUER-SECRET\n")
          {"issuer" => {"url" => "https://forge.example.com",
            "account" => "lab-role-dev", "admin_username" => "forge-admin", "password_file" => token_file},
           "scopes" => ["write:repository"]}
        end

        def header_of
          refute_nil headers.fetch(0), "Authorization must travel as a curl -H @file header"
          headers.fetch(0)
        end

        def test_issue_uses_basic_authenticated_sudo_user_endpoint_and_repo_targets
          prov = provider
          granted = prov.issue(profile: profile,
            lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})

          assert_equal "SECRET", granted["token"]
          argv = seen.fetch(0)
          assert_includes argv, "https://forge.example.com/api/v1/users/lab-role-dev/tokens"
          assert_equal "-q", argv[1]
          assert_equal "20", argv[argv.index("--max-time") + 1]
          assert_equal "POST", argv[argv.index("-X") + 1]
          assert_equal "Authorization: Basic #{Base64.strict_encode64("forge-admin:ISSUER-SECRET")}\nSudo: lab-role-dev", header_of
          refute_includes argv, "ISSUER-SECRET", "the issuer secret never appears in argv (ps)"
          payload = JSON.parse(argv[argv.index("-d") + 1])
          assert_equal "ace-lab-lease-x", payload["name"]
          assert_equal [{"owner" => "cs3b", "name" => "ace"}], payload["repositories"],
            "Forgejo RepoTargetOption is an owner+name object, not a bare string"
          assert_equal %w[write:repository], payload["scopes"]
        end

        def test_repo_entries_without_an_owner_are_refused_before_any_request
          prov = provider
          ["ace", "cs3b/", "/ace"].each do |entry|
            error = assert_raises(Providers::RefusedError) do
              prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => [entry]})
            end
            assert_match(/not an identifiable 'owner\/name' target/, error.message)
            assert_match(/all-repositories token/, error.message)
          end
          assert_empty seen, "no request is sent for an unidentifiable repo scope"
        end

        def test_issue_refuses_an_empty_repository_payload
          prov = provider
          error = assert_raises(Providers::RefusedError) do
            prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => []})
          end
          assert_match(/empty repositories payload.*ALL/, error.message)
          assert_empty seen, "no request may be sent for an all-repositories grant"
        end

        def test_issue_validates_the_granted_scopes_against_the_request
          prov = provider({"sha1" => "SECRET", "id" => 1,
            "scopes" => ["read:repository"]})
          error = assert_raises(Providers::TransientError) do
            prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
          end
          assert_match(/granted scopes \[read:repository\] do not cover the requested \[write:repository\]/,
            error.message)

          prov = provider({"sha1" => "SECRET", "id" => 1,
            "scopes" => ["write:repository"], "repositories" => [{"full_name" => "cs3b/ace"}]})
          granted = prov.issue(profile: profile,
            lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
          assert_equal "SECRET", granted["token"]
        end

        def test_rejects_unconfirmed_or_overbroad_repository_scope
          [nil, [], [{"full_name" => "cs3b/other"}]].each do |repositories|
            prov = provider({"sha1" => "SECRET", "id" => 1, "scopes" => ["write:repository"], "repositories" => repositories})
            error = assert_raises(Providers::TransientError) do
              prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
            end
            assert_match(/did not confirm.*repository restrictions/, error.message)
          end
        end

        def test_accepts_forgejo_canonical_repository_case
          prov = provider({"sha1" => "SECRET", "scopes" => ["write:repository"],
            "repositories" => [{"full_name" => "cs3b/ace"}]})
          grant = prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => ["Cs3b/ACE"]})
          assert_equal "SECRET", grant["token"]
        end

        def test_refuses_invalid_issuer_inputs_before_network
          cases = [
            {"account" => "dev\nSudo: root"},
            {"admin_username" => "admin:other"},
            {"password_file" => "/nonexistent/forgejo-password"}
          ]
          cases.each do |overrides|
            config = profile
            config["issuer"].merge!(overrides)
            prov = provider
            assert_raises(Providers::RefusedError) do
              prov.issue(profile: config, lease: {"id" => "lease-x", "repos" => ["cs3b/ace"]})
            end
            assert_empty seen
          end
          config = profile
          File.write(config["issuer"]["password_file"], "\n")
          assert_raises(Providers::RefusedError) do
            provider.issue(profile: config, lease: {"id" => "lease-x", "repos" => ["cs3b/ace"]})
          end
          assert_empty seen
        end

        def test_exec_projects_only_this_lease_into_private_fj_configuration
          Dir.mktmpdir do |dir|
            credential = File.join(dir, "lease-test-worker")
            File.write(credential, "LEASE-TOKEN")
            projection = nil
            provider = Plugins::ForgejoProvider.new
            provider.stub(:linux_xdg?, true) do
              provider.with_exec_environment(profile: profile, credential: credential) do |env|
                projection = env.fetch("XDG_DATA_HOME")
                assert_equal "C.UTF-8", env.fetch("LC_ALL"), "leased tools need UTF-8 and stable Git prompts"
                path = File.join(projection, "forgejo-cli", "keys.json")
                data = JSON.parse(File.read(path))
                assert_equal({"forge.example.com" => {"type" => "Application", "token" => "LEASE-TOKEN"}}, data["hosts"])
                assert_empty data["aliases"]
                assert_equal 0o600, File.stat(path).mode & 0o777
                refute_includes env.values, "LEASE-TOKEN"
                env = env.merge("ACE_LAB_CREDENTIAL_FILE" => credential)
                askpass = env.fetch("GIT_ASKPASS")
                refute askpass.start_with?(dir + "/"), "credential mounts may be noexec; executable must come from runtime"
                assert File.executable?(askpass)
                username, status = Open3.capture2(env, askpass, "Username for 'https://forge.example.com': ")
                assert status.success?
                assert_equal "lab-role-dev\n", username
                password, status = Open3.capture2(env, askpass, "Password for 'https://lab-role-dev@forge.example.com': ")
                assert status.success?
                assert_equal "LEASE-TOKEN", password
                _output, status = Open3.capture2(env, askpass, "Password for 'https://lab-role-dev@other.example.com': ")
                refute status.success?, "the credential must not be offered to a different forge"
              end
            end
            refute File.exist?(projection)
          end
        end

        def test_handoff_cleanup_removes_a_crashed_session_projection
          Dir.mktmpdir do |dir|
            handoff = CredentialHandoff.new(dir, recipient: "worker")
            credential = handoff.deliver("lease-x", "LEASE-TOKEN")
            projection = Dir.mktmpdir("#{File.basename(credential)}.forgejo-session-", dir)
            File.write(File.join(projection, "secret"), "LEASE-TOKEN")
            assert_equal :cleared, handoff.clear("lease-x")
            refute File.exist?(credential)
            refute File.exist?(projection)
          end
        end

        def test_exec_refuses_platforms_where_fj_does_not_honor_linux_xdg
          provider = Plugins::ForgejoProvider.new
          provider.stub(:linux_xdg?, false) do
            assert_raises(Providers::RefusedError) do
              provider.with_exec_environment(profile: profile, credential: "/unused") { flunk "must not run" }
            end
          end
        end

        def test_exec_uses_literal_ipv6_authority_and_refuses_other_prompts
          Dir.mktmpdir do |dir|
            credential = File.join(dir, "lease-worker")
            File.write(credential, "LEASE-TOKEN")
            config = profile
            config["issuer"]["url"] = "http://[::1]:3000"
            provider = Plugins::ForgejoProvider.new
            provider.stub(:linux_xdg?, true) do
              provider.with_exec_environment(profile: config, credential: credential) do |env|
                data = JSON.parse(File.read(File.join(env.fetch("XDG_DATA_HOME"), "forgejo-cli", "keys.json")))
                assert data["hosts"].key?("[::1]:3000")
                env = env.merge("ACE_LAB_CREDENTIAL_FILE" => credential)
                output, status = Open3.capture2(env, env.fetch("GIT_ASKPASS"), "Password for 'http://lab-role-dev@[::1]:3000': ")
                assert status.success?
                assert_equal "LEASE-TOKEN", output
                _output, status = Open3.capture2(env, env.fetch("GIT_ASKPASS"), "Password for 'http://lab-role-dev@::1:3000': ")
                refute status.success?
              end
            end
          end
        end

        def test_exec_reports_missing_lease_credential_as_refusal
          provider = Plugins::ForgejoProvider.new
          provider.stub(:linux_xdg?, true) do
            error = assert_raises(Providers::RefusedError) do
              provider.with_exec_environment(profile: profile, credential: "/nonexistent/lease") { flunk }
            end
            assert_match(/credential is unreadable/, error.message)
          end
        end

        def test_rejects_unconfirmed_or_extra_scopes
          [nil, ["write:repository", "write:issue"]].each do |scopes|
            prov = provider({"sha1" => "SECRET", "id" => 1, "scopes" => scopes,
              "repositories" => [{"full_name" => "cs3b/ace"}]})
            assert_raises(Providers::TransientError) do
              prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
            end
          end
        end

        def test_rejects_missing_or_empty_token
          [nil, ""].each do |token|
            prov = provider({"sha1" => token, "scopes" => ["write:repository"],
              "repositories" => [{"full_name" => "cs3b/ace"}]})
            assert_raises(Providers::TransientError) do
              prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
            end
          end
        end

        def test_rejects_non_object_response_as_an_unknown_outcome
          prov = provider("[]")
          error = assert_raises(Providers::TransientError) do
            prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
          end
          assert_match(/invalid token response/, error.message)
        end

        def test_rejects_non_origin_issuer_url_before_request
          config = profile
          config["issuer"]["url"] = "https://forge.example.com/untrusted"
          prov = provider
          assert_raises(Providers::RefusedError) do
            prov.issue(profile: config, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
          end
          assert_empty seen
        end

        def test_missing_issuer_is_refused_before_network
          config = profile
          config.delete("issuer")
          prov = provider
          assert_raises(Providers::RefusedError) do
            prov.issue(profile: config, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
          end
          assert_empty seen
          prov.stub(:linux_xdg?, true) do
            error = assert_raises(Providers::RefusedError) do
              prov.with_exec_environment(profile: config, credential: "/unused") { flunk }
            end
            assert_match(/issuer is invalid/, error.message)
          end
          assert_raises(Providers::RefusedError) { prov.revoke(profile: config, token_ref: "ace-lab-lease-x") }
          config["issuer"] = "not a mapping"
          assert_raises(Providers::RefusedError) do
            prov.issue(profile: config, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
          end
        end

        def test_rejects_plain_http_to_non_loopback_issuer
          config = profile
          config["issuer"]["url"] = "http://forge.example.com"
          prov = provider
          error = assert_raises(Providers::RefusedError) do
            prov.issue(profile: config, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
          end
          assert_match(/HTTPS except on loopback/, error.message)
          assert_empty seen
        end

        def test_accepts_plain_http_for_loopback_issuers
          %w[http://127.0.0.1:3000 http://localhost http://LOCALHOST http://[::1]:3000].each do |url|
            config = profile
            config["issuer"]["url"] = url
            grant = provider.issue(profile: config, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
            assert_equal "SECRET", grant["token"]
          end
        end

        def test_revoke_rejects_plain_http_to_non_loopback_before_request
          config = profile
          config["issuer"]["url"] = "http://forge.example.com"
          prov = Plugins::ForgejoProvider.new(capture: ->(_argv) { flunk "network request must not happen" })
          assert_raises(Providers::RefusedError) { prov.revoke(profile: config, token_ref: "ace-lab-lease-x") }
        end

        def test_token_name_is_deterministic_from_the_lease_id
          assert_equal "ace-lab-lease-x",
            Plugins::ForgejoProvider.new.token_ref_for(lease_id: "lease-x"),
            "the remote identity exists before any response — the R5 recovery anchor"
        end

        def test_revoke_deletes_the_exact_token_name_on_the_user_endpoint
          responses = [["", "", Status.new(success?: true, exitstatus: 0)]]
          captures = []
          capture = ->(argv) {
            at = argv.index { |part| part.is_a?(String) && part.start_with?("@") }
            captures << [argv, at ? File.read(argv[at][1..]).strip : nil]
            responses.shift
          }
          prov = Plugins::ForgejoProvider.new(capture: capture)

          assert_equal :revoked,
            prov.revoke(profile: profile, token_ref: "ace-lab-lease-x")
          argv, header = captures.fetch(0)
          assert_includes argv, "https://forge.example.com/api/v1/users/lab-role-dev/tokens/ace-lab-lease-x"
          assert_equal "20", argv[argv.index("--max-time") + 1]
          assert_equal "DELETE", argv[argv.index("-X") + 1]
          assert_equal "Authorization: Basic #{Base64.strict_encode64("forge-admin:ISSUER-SECRET")}\nSudo: lab-role-dev", header
        end

        def test_revoke_settles_a_404_unknown_token_as_already_invalid
          responses = [["", "curl: (22) The requested URL returned error: 404\n",
                        Status.new(success?: false, exitstatus: 22)]]
          capture = ->(_argv) { responses.shift }
          prov = Plugins::ForgejoProvider.new(capture: capture)

          assert_equal :already_invalid,
            prov.revoke(profile: profile, token_ref: "ace-lab-never-minted"),
            "404 means the deterministic name never existed remotely — an idempotent result"
        end

        def test_revoke_failure_without_404_stays_transient
          responses = [["", "curl: (22) The requested URL returned error: 500\n",
                        Status.new(success?: false, exitstatus: 22)]]
          capture = ->(_argv) { responses.shift }
          prov = Plugins::ForgejoProvider.new(capture: capture)

          error = assert_raises(Providers::TransientError) do
            prov.revoke(profile: profile, token_ref: "ace-lab-lease-x")
          end
          assert_match(/forgejo revoke failed/, error.message)
        end

        def test_revoke_timeout_is_not_a_confirmed_404
          capture = ->(_argv) { ["", "curl: (28) timed out after 404 milliseconds", Status.new(success?: false, exitstatus: 28)] }
          prov = Plugins::ForgejoProvider.new(capture: capture)
          assert_raises(Providers::TransientError) do
            prov.revoke(profile: profile, token_ref: "ace-lab-lease-x")
          end
        end
      end
    end
  end
end
