# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    class OrdinaryMergePolicyTest < Minitest::Test
      def test_proposal_reference_requires_canonical_authority_even_if_yaml_matches
        reference = "proposal-#{'a' * 24}-r1"
        binding = {"operation" => "merge"}
        policy = Molecules::OrdinaryMergePolicy.new({"authorizations" => {reference => binding}})
        assert_raises(SecurityError) { policy.authorize!(reference, binding) }
        calls = []
        resolver = ->(id, exact) { calls << [id, exact]; {"state" => "approved-by-silence"} }
        policy = Molecules::OrdinaryMergePolicy.new({}, resolver)
        assert_equal "approved-by-silence", policy.authorize!(reference, binding)["state"]
        assert_equal [[reference, binding]], calls
      end

      def test_exact_authorization_and_expired_decision
        binding = {"operation" => "merge", "project_id" => "ace", "assignment_id" => "assign-1",
                   "attempt_id" => "attempt-1", "input_digest" => "a" * 64,
                   "target" => {"resource" => "merge"}, "candidate_head" => "b" * 40,
                   "caller_uid" => Process.uid}
        document = {"authorizations" => {"decision-1" => binding.merge(
          "expires_at" => (Time.now.utc + 3600).iso8601
        )}}
        policy = Molecules::OrdinaryMergePolicy.new(document)
        assert_equal binding["attempt_id"], policy.authorize!("decision-1", binding)["attempt_id"]
        assert_raises(SecurityError) { policy.authorize!("decision-1", binding.merge("project_id" => "other")) }
        assert_raises(SecurityError) { policy.authorize!("decision-1", binding.merge("candidate_head" => "c" * 40)) }
        document["authorizations"]["decision-1"]["expires_at"] = (Time.now.utc - 1).iso8601
        assert_raises(SecurityError) { policy.authorize!("decision-1", binding) }
      end

      def test_ordinary_receiver_is_validated_and_scoped_to_the_project
        policy = Molecules::OrdinaryMergePolicy.new({"ordinary" => {"projects" => {"atlas" => {
          "receiver_id" => "ordinary-receiver", "socket_path" => "/run/ace/atlas/merge.sock",
          "receiver_uid" => 41000, "principal" => "overseer",
          "journal_repository" => "/var/lib/ace/journal", "journal_ref" => "refs/ace/execution"
        }}}})
        assert_equal "overseer", policy.ordinary_receiver!("atlas").fetch("principal")
        assert_nil policy.ordinary_receiver!("borealis")
        assert_raises(Ace::Lab::InvalidConfigurationError) do
          Molecules::OrdinaryMergePolicy.new({"ordinary" => {"projects" => {"atlas" => {"receiver_id" => "r"}}}})
            .ordinary_receiver!("atlas")
        end
      end

      def test_ordinary_decision_matches_the_exact_request_binding
        binding = {"operation" => "merge", "project_id" => "atlas", "assignment_id" => "assign-1",
                   "attempt_id" => "attempt-1", "queue_entry" => "010", "input_digest" => "a" * 64,
                   "forge" => "forgejo", "pr_url" => "https://forge.example.com/acme/widget/pulls/8",
                   "head_repository" => "acme/widget", "head_ref" => "refs/heads/feature",
                   "candidate_head" => "b" * 40, "base_repository" => "acme/widget",
                   "base_ref" => "refs/heads/main", "expected_base_head" => "c" * 40}
        decision = binding.merge("expires_at" => (Time.now.utc + 3600).iso8601)
        policy = Molecules::OrdinaryMergePolicy.new({"authorizations" => {"decision-1" => decision}})
        assert_equal decision.fetch("expires_at"),
          policy.authorize_ordinary!("decision-1", binding).fetch("expires_at")
        assert_raises(SecurityError) do
          policy.authorize_ordinary!("decision-1", binding.merge("queue_entry" => "020"))
        end
        expired = binding.merge("expires_at" => "2020-01-01T00:00:00Z")
        policy = Molecules::OrdinaryMergePolicy.new({"authorizations" => {"decision-1" => expired}})
        assert_raises(SecurityError) { policy.authorize_ordinary!("decision-1", binding) }
        shape = binding.merge("expires_at" => (Time.now.utc + 3600).iso8601).except("queue_entry")
        policy = Molecules::OrdinaryMergePolicy.new({"authorizations" => {"decision-1" => shape}})
        assert_raises(SecurityError) { policy.authorize_ordinary!("decision-1", binding) }
      end
    end
  end
end
