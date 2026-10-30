# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"

module Auth
  # The GitHub provider's revoke wire contract (PR #398 F5): the DELETE
  # /installation/token request is authenticated with the ISSUED
  # installation token (GitHub revokes the token that authenticates
  # the request), curl runs with --fail so an HTTP error can never
  # surface as process success, 401 is the idempotent already-invalid
  # result, and any other non-success outcome stays outcome-unknown —
  # never a claimed revocation.
  class GithubProviderTest < Minitest::Test
    Status = Struct.new(:success?, :exitstatus, keyword_init: true)

    def provider(responses)
      seen = []
      capture = ->(argv) {
        seen << argv
        responses.shift
      }
      [Ace::Lab::Auth::Plugins::GithubProvider.new(capture: capture), seen]
    end

    def profile
      {"issuer" => {"installation_id" => 42, "app_id" => 99,
        "key_file" => "/nonexistent-key.pem", "api_url" => "https://api.github.com"}}
    end

    def test_revoke_authenticates_with_the_issued_installation_token_and_fails_on_http_error
      provider, seen = provider([["", "", Status.new(success?: true, exitstatus: 0)]])

      assert_equal :revoked,
        provider.revoke(profile: profile, token_ref: "12345", token: "ghs_ISSUED_TOKEN")

      argv = seen.fetch(0)
      assert_equal "https://api.github.com/installation/token", argv[5]
      assert_includes argv, "-f", "curl must fail on HTTP errors, never exit 0 on a 401/403"
      assert_includes argv, "Authorization: Bearer ghs_ISSUED_TOKEN",
        "the ISSUED installation token authenticates the revoke, not a fresh App JWT"
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

      error = assert_raises(Ace::Lab::Auth::Providers::OutcomeUnknownError) do
        provider.revoke(profile: profile, token_ref: "12345", token: "ghs_ISSUED_TOKEN")
      end
      assert_match(/outcome unknown/, error.message)
    end

    def test_lost_response_stays_outcome_unknown
      provider, = provider([
        ["", "curl: (7) Failed to connect to api.github.com",
         Status.new(success?: false, exitstatus: 7)]
      ])

      error = assert_raises(Ace::Lab::Auth::Providers::OutcomeUnknownError) do
        provider.revoke(profile: profile, token_ref: "12345", token: "ghs_ISSUED_TOKEN")
      end
      assert_match(/outcome unknown/, error.message)
    end

    def test_revoke_without_the_issued_token_value_is_outcome_unknown
      provider, seen = provider([])

      error = assert_raises(Ace::Lab::Auth::Providers::OutcomeUnknownError) do
        provider.revoke(profile: profile, token_ref: "12345", token: nil)
      end
      assert_match(/issued installation token .* is required/, error.message)
      assert_empty seen, "no request is sent without the revocation credential"
    end
  end
end
