# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/endcap"

class CampaignResultSnapshotTest < AceAssignTestCase
  def test_receipt_consumer_uses_same_held_snapshot_and_retains_policy_parent_guards
    with_temp_cache do |root|
      selected = {"version" => 1, "campaign_id" => "campaign", "contract_identity" => "a" * 64,
        "subject" => {"repository" => "local:#{root}", "local_candidate_id" => "candidate"},
        "policy" => {"revision" => "delivery", "minimum_rounds" => 3, "clean_rounds" => 2,
          "required_scopes" => ["full"], "required_checks" => ["tests"]}}
      result = {"schema" => "ace.review.accepted-result/v1", "campaign_id" => "campaign", "accepted" => true}
      receipt = {"campaign" => {"id" => "campaign", "result" => {}}, "operation" => "review", "verdict" => "succeeded",
        "head" => "b" * 40, "producer" => {"actor" => "worker"}, "review" => {"reviewer" => {"actor" => "reviewer"}}}
      descriptor = Object.new
      descriptor.define_singleton_method(:project) { |_| {"campaign_repository" => root} }
      map = {"project_id" => "project"}
      context = {map: map, descriptor: descriptor}
      definition = Struct.new(:review_campaign).new(selected)
      manager = Object.new
      yielded_snapshot = result
      manager.define_singleton_method(:accepted_result_snapshot) { |_| raise "second campaign read forbidden" }
      manager.define_singleton_method(:with_verified_result!) do |**args, &block|
        raise ArgumentError, "wrong original campaign" unless args[:subject] == selected.fetch("subject")
        block.call({"accepted" => true}, yielded_snapshot)
      end
      launch = Object.new
      launch.define_singleton_method(:control_registration_context!) { |*args, **kwargs| context }
      launch.define_singleton_method(:preview_attempt_definition!) { |**| definition }
      launch.define_singleton_method(:campaign_manager_for!) { |*args, **kwargs| manager }
      launch.define_singleton_method(:protected_descriptor_sha256!) { "original" }
      deployment = Object.new
      deployment.define_singleton_method(:project) { |_| {"campaign_policy" => "policy-path"} }
      owner = Ace::Assign::Authority::Endcap.allocate
      owner.instance_variable_set(:@launch, launch)
      owner.instance_variable_set(:@deployment, deployment)
      owner.define_singleton_method(:retained_origin) { |*| {"scope" => "010", "base_head" => "c" * 40} }
      candidate = {"head" => "b" * 40, "tree" => "d" * 40, "sha256" => "e" * 64, "bytes" => 6, "bundle_ref" => "bundle"}
      owner.define_singleton_method(:retained_candidate) { |*| candidate }
      owner.define_singleton_method(:exact_candidate!) { |value, _| value }
      owner.define_singleton_method(:campaign_execution_dependencies!) { |**| {} }
      parent_checks = 0
      owner.define_singleton_method(:campaign_parent_candidate!) { |**| parent_checks += 1 }
      journal = Object.new
      journal.define_singleton_method(:bounded_blob) { |*args, **kwargs| "bundle" }
      transfer = Object.new
      transfer.define_singleton_method(:with_campaign_repository) { |**args, &block| block.call(:held_candidate) }
      held = Object.new
      policy_checks = 0
      held.define_singleton_method(:verify_unchanged!) { policy_checks += 1 }
      policy = Object.new
      policy.define_singleton_method(:with) { |_, &block| block.call({"delivery" => selected.fetch("policy")}, held) }
      args = {journal: journal, commit: "pinned", events: [], params: {"candidate_generation" => 1},
        map: map, receipt: receipt, result: result, historical: false}
      Ace::Assign::Authority::CandidateTransfer.stub(:new, transfer) do
        Ace::Assign::Authority::CampaignConsumerPolicy.stub(:new, policy) do
          assert_equal :consumed, owner.send(:with_campaign_receipt!, **args) { :consumed }
          assert_equal 1, parent_checks
          assert_equal 2, policy_checks
          yielded_snapshot = result.merge("result_identity" => "different")
          assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
            owner.send(:with_campaign_receipt!, **args) { flunk "changed snapshot reached consumer" }
          end
          assert_equal 1, parent_checks
          assert_equal 2, policy_checks
        end
      end
    end
  end
end
