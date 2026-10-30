# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"

module Ace
  module Lab
    module Auth
      # Forgejo provider wire contract (PR #398 review): the issuer
      # secret travels in a 0600 ephemeral header file (`curl -H
      # @file`), never in argv; an empty repositories payload would
      # mean ALL of the account's repositories and is refused before
      # any request; revoke deletes the exact token id.
      class ForgejoProviderTest < Minitest::Test
        # The runner snapshots the `curl -H @file` content AT CALL TIME —
        # the ephemeral header file is gone by the time assertions run.
        def provider
          @seen = []
          @headers = []
          runner = ->(argv) {
            at = argv.index { |part| part.is_a?(String) && part.start_with?("@") }
            @headers << (at ? File.read(argv[at][1..]).strip : nil)
            @seen << argv
            JSON.generate({"sha1" => "SECRET", "id" => 1})
          }
          Plugins::ForgejoProvider.new(runner: runner)
        end

        attr_reader :seen, :headers

        def profile
          token_file = File.join(Dir.mktmpdir, "issuer.token")
          File.write(token_file, "ISSUER-SECRET\n")
          {"issuer" => {"url" => "https://forge.example.com",
            "account" => "lab-role-dev", "token_file" => token_file},
           "scopes" => ["write:repository"]}
        end

        def header_of
          refute_nil headers.fetch(0), "Authorization must travel as a curl -H @file header"
          headers.fetch(0)
        end

        def test_issue_keeps_the_issuer_secret_out_of_argv
          prov = provider
          granted = prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => %w[ace]})

          assert_equal "SECRET", granted["token"]
          argv = seen.fetch(0)
          assert_equal "https://forge.example.com/api/v1/users/lab-role-dev/tokens", argv[5]
          assert_equal "Authorization: token ISSUER-SECRET", header_of
          refute_includes argv, "ISSUER-SECRET", "the issuer secret never appears in argv (ps)"
          payload = JSON.parse(argv[argv.index("-d") + 1])
          assert_equal %w[ace], payload["repositories"]
          assert_equal "ace-lab-lease-x", payload["name"]
        end

        def test_issue_refuses_an_empty_repository_payload
          prov = provider
          error = assert_raises(Providers::RefusedError) do
            prov.issue(profile: profile, lease: {"id" => "lease-x", "repos" => []})
          end
          assert_match(/empty repositories payload.*ALL/, error.message)
          assert_empty seen, "no request may be sent for an all-repositories grant"
        end

        def test_revoke_deletes_the_exact_token_id_with_a_header_file
          prov = provider
          assert_equal :revoked,
            prov.revoke(profile: profile, token_ref: "ace-lab-lease-x")
          argv = seen.fetch(0)
          assert_equal "https://forge.example.com/api/v1/users/lab-role-dev/tokens/ace-lab-lease-x",
            argv[5]
          assert_equal "Authorization: token ISSUER-SECRET", header_of
          assert_equal "DELETE", argv[argv.index("-X") + 1]
        end
      end
    end
  end
end
