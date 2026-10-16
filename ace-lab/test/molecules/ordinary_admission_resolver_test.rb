# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module Molecules
      class OrdinaryAdmissionResolverTest < Minitest::Test
        HEAD = "a" * 40
        BASE = "b" * 40
        DIGEST = "c" * 64

        def setup
          @decision = {
            "operation" => "merge", "project_id" => "atlas",
            "assignment_id" => "asg1", "attempt_id" => "at1", "queue_entry" => "010",
            "input_digest" => DIGEST, "forge" => "forgejo",
            "pr_url" => "https://forge.example.com/acme/widget/pulls/7",
            "head_repository" => "acme/widget", "head_ref" => "refs/heads/feat/x",
            "candidate_head" => HEAD, "base_repository" => "acme/widget",
            "base_ref" => "refs/heads/main", "expected_base_head" => BASE,
            "expires_at" => (Time.now.utc + 3600).iso8601
          }
          @resolver = OrdinaryAdmissionResolver.new({"authorizations" => {"decision-1" => @decision}})
        end

        def test_exact_decision_authorizes
          result = @resolver.decide("decision-1", binding)
          assert result.authorized?
          assert_equal @decision, result.decision
          assert_nil result.code
        end

        def test_missing_unresolved_or_malformed_reference_refuses
          [@resolver.decide("unknown", binding),
            @resolver.decide(nil, binding),
            @resolver.decide("../escape", binding)].each do |result|
            refute result.authorized?
            assert_equal "ordinary_merge_authorization_invalid", result.code
          end
        end

        def test_shape_mismatch_is_not_an_ordinary_merge_decision
          resolver = OrdinaryAdmissionResolver.new({"authorizations" => {
            "decision-1" => @decision.except("queue_entry")
          }})
          result = resolver.decide("decision-1", binding)
          refute result.authorized?
          assert_includes result.message, "not an ordinary merge decision"
        end

        def test_non_merge_operation_never_resolves
          resolver = OrdinaryAdmissionResolver.new({"authorizations" => {"decision-1" =>
            @decision.merge("operation" => "publish")}})
          refute resolver.decide("decision-1", binding).authorized?
          # A non-merge requested operation is refused before any decision.
          refute @resolver.decide("decision-1", binding.merge("operation" => "publish")).authorized?
        end

        def test_every_binding_key_must_match_exactly_no_wildcards_or_defaults
          partial = OrdinaryAdmissionResolver.new({"authorizations" => {"decision-1" =>
            @decision.except("forge")}})
          # A decision missing a closed key is a shape refusal, not a grant.
          refute partial.decide("decision-1", binding).authorized?

          mismatched = {
            "project_id" => "borealis", "assignment_id" => "other", "attempt_id" => "other",
            "queue_entry" => "020", "input_digest" => "9" * 64, "forge" => "other",
            "pr_url" => "https://other/pulls/1", "head_repository" => "o/r",
            "head_ref" => "refs/heads/o", "candidate_head" => "9" * 40,
            "base_repository" => "o/r", "base_ref" => "refs/heads/o",
            "expected_base_head" => "9" * 40
          }.map { |key, value| @resolver.decide("decision-1", binding.merge(key => value)) }
          mismatched.each do |result|
            refute result.authorized?
            assert_equal "ordinary_merge_authorization_invalid", result.code
          end
        end

        def test_expired_or_invalid_expiry_refuses
          expired = OrdinaryAdmissionResolver.new({"authorizations" => {"decision-1" =>
            @decision.merge("expires_at" => "2020-01-01T00:00:00Z")}})
          refute expired.decide("decision-1", binding).authorized?
          broken = OrdinaryAdmissionResolver.new({"authorizations" => {"decision-1" =>
            @decision.merge("expires_at" => "not-a-time")}})
          refute broken.decide("decision-1", binding).authorized?
        end

        def test_invalid_policy_document_fails_closed
          assert_raises Ace::Lab::InvalidConfigurationError do
            OrdinaryAdmissionResolver.new({})
          end
        end

        # ---- per-request trusted refresh (8x3.t.xz9.5) ---------------------

        def test_refresh_resolves_against_the_fresh_document_not_the_boot_snapshot
          fresh = {"authorizations" => {"decision-1" => @decision}}
          resolver = OrdinaryAdmissionResolver.new({"authorizations" => {}},
            path: "/etc/lab/ace-lab/authorization.yml", loader: ->(_path) { fresh })
          result = resolver.decide("decision-1", binding)
          assert result.authorized?
        end

        def test_refresh_reloads_per_decision_never_caches_the_first_read
          reads = []
          loader = lambda do |path|
            reads << path
            {"authorizations" => (reads.size >= 2) ? {} : {"decision-1" => @decision}}
          end
          resolver = OrdinaryAdmissionResolver.new({"authorizations" => {"decision-1" => @decision}},
            path: "/etc/lab/ace-lab/authorization.yml", loader: loader)
          assert resolver.decide("decision-1", binding).authorized?
          # A root-revoked decision fails closed on the NEXT request.
          refute resolver.decide("decision-1", binding).authorized?
          assert_equal 2, reads.size
        end

        def test_malformed_refreshed_document_fails_closed
          resolver = OrdinaryAdmissionResolver.new({"authorizations" => {"decision-1" => @decision}},
            path: "/etc/lab/ace-lab/authorization.yml", loader: ->(_path) { {"authorizations" => nil} })
          error = assert_raises(Ace::Lab::InvalidConfigurationError) do
            resolver.decide("decision-1", binding)
          end
          assert_includes error.message, "authorizations mapping"
        end

        def test_failed_trusted_refresh_never_falls_back_to_the_stale_snapshot
          resolver = OrdinaryAdmissionResolver.new({"authorizations" => {"decision-1" => @decision}},
            path: "/etc/lab/ace-lab/authorization.yml",
            loader: ->(_path) { raise Ace::Lab::InvalidConfigurationError, "trust failed" })
          error = assert_raises(Ace::Lab::InvalidConfigurationError) do
            resolver.decide("decision-1", binding)
          end
          assert_includes error.message, "trust failed"
        end

        def test_changed_static_configuration_refuses_even_with_a_valid_decision
          original = {"authorizations" => {"decision-1" => @decision},
                      "ordinary" => {"projects" => {"atlas" => {"admission" => "enabled"}}}}
          changed = Marshal.load(Marshal.dump(original))
          changed["ordinary"]["projects"]["atlas"]["admission"] = "disabled"
          resolver = OrdinaryAdmissionResolver.new(original, path: "/trusted/policy.yml",
            loader: ->(_path) { changed })
          error = assert_raises(Ace::Lab::InvalidConfigurationError) do
            resolver.decide("decision-1", binding)
          end
          assert_includes error.message, "configuration changed"
        end

        def test_without_a_trusted_path_the_boot_snapshot_resolves_unchanged
          loader = ->(_path) { flunk "must not reload without a trusted path" }
          resolver = OrdinaryAdmissionResolver.new({"authorizations" => {"decision-1" => @decision}},
            loader: loader)
          assert resolver.decide("decision-1", binding).authorized?
        end

        private

        def binding
          {
            "operation" => "merge", "project_id" => "atlas", "assignment_id" => "asg1",
            "attempt_id" => "at1", "queue_entry" => "010", "input_digest" => DIGEST,
            "forge" => "forgejo", "pr_url" => "https://forge.example.com/acme/widget/pulls/7",
            "head_repository" => "acme/widget", "head_ref" => "refs/heads/feat/x",
            "candidate_head" => HEAD, "base_repository" => "acme/widget",
            "base_ref" => "refs/heads/main", "expected_base_head" => BASE
          }
        end
      end
    end
  end
end
