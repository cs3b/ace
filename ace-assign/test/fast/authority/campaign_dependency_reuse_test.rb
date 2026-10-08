# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/endcap"

module Ace
  module Assign
    class CampaignDependencyReuseTest < Minitest::Test
      def test_reuse_is_local_to_exact_prefix_child_phase_policy_and_receipt
        bytes = "canonical bytes"
        artifact = {"path" => "canonical", "sha256" => Digest::SHA256.hexdigest(bytes)}
        execution = {"parent_assignment_id" => "parent", "parent_attempt_id" => "parent-attempt", "phase" => "collection",
          "head" => "a" * 40, "base" => "b" * 40, "parent_scope" => "010", "parent_candidate_generation" => 1,
          "policy_digest" => "c" * 64}
        row_checks = parent_checks = full_checks = raw_reads = 0
        journal = Object.new
        journal.define_singleton_method(:canonical_event_inventory!) do |commit:|
          {"events" => {"child" => [{"attempt_id" => "child-attempt"}, {"attempt_id" => "other-attempt"},
            {"payload" => {"operation" => "register_assignment", "data" => {"lifecycle_control" => {}, "mapping_id" => "child-map"}}}]}}
        end
        descriptor = Object.new
        descriptor.define_singleton_method(:mapping) { |_| {"project_id" => "project"} }
        launch = Object.new
        launch.define_singleton_method(:control_original_descriptor!) { |_| descriptor }
        launch.define_singleton_method(:preview_attempt_definition!) { |**_| Struct.new(:campaign_execution).new(execution) }
        launch.define_singleton_method(:completion_terminal!) do |**_|
          row_checks += 1
          {"definition_digest" => "d" * 64, "original_binding_digest" => "e" * 64}
        end
        owner = Authority::Endcap.allocate
        owner.instance_variable_set(:@launch, launch)
        owner.define_singleton_method(:campaign_parent_candidate!) { |**_| parent_checks += 1 }
        owner.define_singleton_method(:with_campaign_execution_evidence!) do |**args, &consumer|
          full_checks += 1
          proof = {"artifacts" => [artifact], "execution_binding" => args.fetch(:execution_binding)}
          consumer.call(proof, ->(_) { raw_reads += 1; bytes })
        end
        make = ->(commit) { owner.send(:campaign_execution_dependencies!, journal: journal, commit: commit,
          parent_params: {"assignment_id" => "parent", "attempt_id" => "parent-attempt"}, parent_map: {"project_id" => "project"}) }
        reference = {"attempt_id" => "child-attempt", "digest" => "f" * 64}
        read = make.call("1" * 40).fetch(:review_evidence)
        2.times { read.call(reference, head: execution.fetch("head"), artifacts: [artifact]) }
        assert_equal 1, full_checks
        assert_equal 1, raw_reads
        assert_equal 1, row_checks, "same-prefix terminal row is immutable"
        assert_equal 2, parent_checks, "fresh parent checks must still run"
        read.call(reference.merge("attempt_id" => "other-attempt"), head: execution.fetch("head"), artifacts: [artifact])
        read.call(reference.merge("digest" => "0" * 64), head: execution.fetch("head"), artifacts: [artifact])
        execution["policy_digest"] = "0" * 64
        make.call("1" * 40).fetch(:review_evidence).call(reference, head: execution.fetch("head"), artifacts: [artifact])
        assert_equal 4, full_checks
        make.call("2" * 40).fetch(:review_evidence).call(reference, head: execution.fetch("head"), artifacts: [artifact])
        make.call("1" * 40).fetch(:review_evidence).call(reference, head: execution.fetch("head"), artifacts: [artifact])
        execution["phase"] = "approval"
        make.call("1" * 40).fetch(:approval_evidence).call(reference, head: execution.fetch("head"), artifacts: [artifact], producer: nil, reviewer: nil)
        assert_equal 7, full_checks, "new commit, operation and phase must verify normally"
      end
    end
  end
end
