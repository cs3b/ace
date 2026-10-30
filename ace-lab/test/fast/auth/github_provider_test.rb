# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "openssl"

module Ace
  module Lab
    module Auth
      # The GitHub provider's wire contract (PR #398 review): the DELETE
      # /installation/token request is authenticated with the ISSUED
      # installation token (GitHub revokes the token that authenticates
      # the request), curl runs with --fail so an HTTP error can never
      # surface as process success, 401 is the idempotent
      # already-invalid result, any other non-success outcome stays
      # outcome-unknown — never a claimed revocation — and secrets
      # travel in 0600 ephemeral header files, never in argv.
      class GithubProviderTest < Minitest::Test
        Status = Struct.new(:success?, :exitstatus, keyword_init: true)

        # The capture/runner seams snapshot the `curl -H @file` content
        # AT CALL TIME — the ephemeral header file is gone by the time
        # assertions run.
        def snapshot_headers(argv)
          at = argv.index { |part| part.is_a?(String) && part.start_with?("@") }
          at ? File.read(argv[at][1..]).strip : nil
        end

        def provider(responses)
          seen = []
          headers = []
          capture = ->(argv) {
            seen << argv
            headers << snapshot_headers(argv)
            responses.shift
          }
          [Plugins::GithubProvider.new(capture: capture), seen, headers]
        end

        def profile
          {"issuer" => {"installation_id" => 42, "app_id" => 99,
            "key_file" => "/nonexistent-key.pem", "api_url" => "https://api.github.com"},
           "scopes" => ["write:repository", "read:organization"]}
        end

        # The Authorization value for the `curl -H @file` entry, from the
        # call-time snapshot (the ephemeral file no longer exists).
        def header_of(headers)
          refute_nil headers.fetch(0), "Authorization must travel as a curl -H @file header"
          headers.fetch(0)
        end

        def test_revoke_authenticates_with_the_issued_installation_token_and_fails_on_http_error
          provider, seen, headers = provider([["", "", Status.new(success?: true, exitstatus: 0)]])

          assert_equal :revoked,
            provider.revoke(profile: profile, token_ref: "12345", token: "ghs_ISSUED_TOKEN")

          argv = seen.fetch(0)
          assert_equal "https://api.github.com/installation/token", argv[5]
          assert_includes argv, "-f", "curl must fail on HTTP errors, never exit 0 on a 401/403"
          assert_equal "Authorization: Bearer ghs_ISSUED_TOKEN", header_of(headers),
            "the ISSUED installation token authenticates the revoke, not a fresh App JWT"
          refute_includes argv, "Bearer ghs_ISSUED_TOKEN",
            "the secret never appears in argv (visible in ps)"
        end

        def test_http_401_with_a_well_formed_request_is_already_invalid_not_revoked
          provider, = provider([
            ["", "curl: (22) The requested URL returned error: 401\n",
             Status.new(success?: false, exitstatus: 22)]
          ])

          assert_equal :already_invalid,
            provider.revoke(profile: profile, token_ref: "12345", token: "ghs_ISSUED_TOKEN")
        end

        def test_process_success_shape_with_an_http_error_body_is_never_revoked
          # The pre-fix failure shape: curl without --fail exits 0 on HTTP
          # errors. With --fail the capture seam sees a failed status for
          # the same wire outcome — a 403 body must never claim revocation.
          provider, = provider([
            ['{"message":"Resource not accessible by integration"}', "",
             Status.new(success?: false, exitstatus: 22)]
          ])

          error = assert_raises(Providers::OutcomeUnknownError) do
            provider.revoke(profile: profile, token_ref: "12345", token: "ghs_ISSUED_TOKEN")
          end
          assert_match(/outcome unknown/, error.message)
        end

        def test_lost_response_stays_outcome_unknown
          provider, = provider([
            ["", "curl: (7) Failed to connect to api.github.com",
             Status.new(success?: false, exitstatus: 7)]
          ])

          error = assert_raises(Providers::OutcomeUnknownError) do
            provider.revoke(profile: profile, token_ref: "12345", token: "ghs_ISSUED_TOKEN")
          end
          assert_match(/outcome unknown/, error.message)
        end

        def test_revoke_without_the_issued_token_value_is_outcome_unknown
          provider, seen, = provider([])

          error = assert_raises(Providers::OutcomeUnknownError) do
            provider.revoke(profile: profile, token_ref: "12345", token: nil)
          end
          assert_match(/issued installation token .* is required/, error.message)
          assert_empty seen, "no request is sent without the revocation credential"
        end

        def test_issue_orients_level_subject_scopes_onto_github_permissions
          key = File.join(Dir.mktmpdir, "key.pem")
          File.write(key, OpenSSL::PKey::RSA.new(1024).to_pem)
          issuer = profile["issuer"].merge("key_file" => key)
          seen = []
          headers = []
          runner = ->(argv) {
            seen << argv
            headers << snapshot_headers(argv)
            JSON.generate({"token" => "ghs_X", "id" => 7, "expires_at" => "2026-10-30T12:00:00Z"})
          }
          granted = Plugins::GithubProvider.new(runner: runner)
            .issue(profile: profile.merge("issuer" => issuer), lease: {"repos" => %w[ace]})

          assert_equal "ghs_X", granted["token"]
          argv = seen.fetch(0)
          payload = JSON.parse(argv[argv.index("-d") + 1])
          assert_equal({"repository" => "write", "organization" => "read"},
            payload["permissions"],
            "write:repository must orient to {'repository' => 'write'}")
          assert_equal %w[ace], payload["repositories"]
          assert_match(/\AAuthorization: Bearer /, header_of(headers),
            "the App JWT also travels in the ephemeral header file, never in argv")
          refute_match(/Bearer /, argv.join(" "), "no secret in argv")
        end

        def test_issue_refuses_an_empty_repository_list
          key = File.join(Dir.mktmpdir, "key.pem")
          File.write(key, OpenSSL::PKey::RSA.new(1024).to_pem)
          issuer = profile["issuer"].merge("key_file" => key)
          runner = ->(_argv) { flunk "no request may be sent for an empty repository grant" }

          error = assert_raises(Providers::RefusedError) do
            Plugins::GithubProvider.new(runner: runner)
              .issue(profile: profile.merge("issuer" => issuer), lease: {"repos" => []})
          end
          assert_match(/empty repository list.*ALL/, error.message)
        end
      end
    end
  end
end
