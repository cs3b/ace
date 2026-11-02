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
          assert_equal "https://forge.example.com/api/v1/users/lab-role-dev/tokens", argv[5]
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

        def test_rejects_unconfirmed_or_extra_scopes
          [nil, ["write:repository", "write:issue"]].each do |scopes|
            prov = provider({"sha1" => "SECRET", "id" => 1, "scopes" => scopes,
              "repositories" => [{"full_name" => "cs3b/ace"}]})
            assert_raises(Providers::TransientError) do
              prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => %w[cs3b/ace]})
            end
          end
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
          assert_equal "https://forge.example.com/api/v1/users/lab-role-dev/tokens/ace-lab-lease-x",
            argv[5]
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
      end
    end
  end
end
