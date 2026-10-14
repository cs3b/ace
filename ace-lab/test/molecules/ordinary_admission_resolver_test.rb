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
          @resolver = OrdinaryAdmissionResolver.new("authorizations" => {"decision-1" => @decision})
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
          resolver = OrdinaryAdmissionResolver.new("authorizations" => {
            "decision-1" => @decision.except("queue_entry")
          })
          result = resolver.decide("decision-1", binding)
          refute result.authorized?
          assert_includes result.message, "not an ordinary merge decision"
        end

        def test_non_merge_operation_never_resolves
          resolver = OrdinaryAdmissionResolver.new("authorizations" => {"decision-1" =>
            @decision.merge("operation" => "publish")})
          refute resolver.decide("decision-1", binding).authorized?
          # A non-merge requested operation is refused before any decision.
          refute @resolver.decide("decision-1", binding.merge("operation" => "publish")).authorized?
        end

        def test_every_binding_key_must_match_exactly_no_wildcards_or_defaults
          partial = OrdinaryAdmissionResolver.new("authorizations" => {"decision-1" =>
            @decision.except("forge")})
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
          expired = OrdinaryAdmissionResolver.new("authorizations" => {"decision-1" =>
            @decision.merge("expires_at" => "2020-01-01T00:00:00Z")})
          refute expired.decide("decision-1", binding).authorized?
          broken = OrdinaryAdmissionResolver.new("authorizations" => {"decision-1" =>
            @decision.merge("expires_at" => "not-a-time")})
          refute broken.decide("decision-1", binding).authorized?
        end

        def test_invalid_policy_document_fails_closed
          assert_raises Ace::Lab::InvalidConfigurationError do
            OrdinaryAdmissionResolver.new({})
          end
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
