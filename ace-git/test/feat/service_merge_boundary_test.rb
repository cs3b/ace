# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/protected_merge_flow_fixture"
require_relative "../../../ace-assign/test/support/prepared_workspace_resource_fixture"
require "ace/git/cli"
require "ace/git/forgejo"
require "ace/git/github"
require "stringio"
require "ace/assign/cli/commands/delivery"
require "ace/lab/cli/commands/service"
require "ace/hitl"
require_relative "../../../ace-hitl/test/support/lifecycle_fixtures"

# Actual wire/claim/candidate/import owners; only kernel identity, process
# execution and remote provider transport are controlled excluded boundaries.
class ServiceMergeBoundaryTest < AceGitTestCase
  include ProtectedMergeFlowFixture
  include Ace::Assign::PreparedWorkspaceResourceFixture

  def configure_result_owner_fixture
    super
    configure_original_workspace_resource
  end

  def test_actual_wrong_provider_sha_retains_uncertainty_without_merge_or_delivery
    @wrong_provider_head = true
    exercise_completion
  end

  def test_lost_remote_merge_reply_never_becomes_delivery_or_retry
    @uncertain_provider_merge = true
    exercise_completion
  end

  def test_actual_red_ci_only_does_not_veto_reviewed_authorized_merge
    @red_ci, @merge_provider = true, "github"
    exercise_completion
  end

  def test_public_merge_uses_canonical_silence_proposal_without_another_proposal
    @public_lab, @authorization_mode = true, :proposal
    exercise_completion
  end

  def test_public_merge_direct_decision_creates_no_redundant_proposal
    @public_lab, @authorization_mode = true, :direct
    exercise_completion
  end

  def test_public_merge_scoped_standing_decision_creates_no_redundant_proposal
    @public_lab, @authorization_mode = true, :standing
    exercise_completion
  end

  def test_public_merge_missing_authorization_blocks_then_creates_exact_pending_proposal
    @public_lab, @authorization_mode = true, :missing
    exercise_completion
  end

  def test_public_merge_out_of_scope_authorization_blocks_then_creates_exact_pending_proposal
    @public_lab, @authorization_mode = true, :out_of_scope
    exercise_completion
  end


  def test_public_lab_request_and_status_use_original_receiver_and_canonical_result
    @public_lab = true
    exercise_completion
  end

  def test_public_lab_lost_claim_reply_recovers_by_exact_canonical_status_and_replay
    @public_lab = true
    @lose_public_claim = true
    exercise_completion
  end

  def test_public_lab_request_refuses_selector_service_and_foreign_birth_controls
    @public_lab = true
    @public_refusals = %i[selectors missing_service foreign_birth]
    exercise_completion
  end

  def test_public_lab_request_refuses_stale_candidate_and_missing_authorization
    @public_lab = true
    @public_refusals = %i[stale_head stale_generation missing_authorization]
    exercise_completion
  end

  def test_public_lab_request_refuses_candidate_without_accepted_review
    @public_lab = true
    @missing_review = true
    @public_refusals = [:missing_review]
    exercise_completion
  end

  def test_public_lab_pending_status_refuses_changed_input_and_foreign_birth
    @public_lab = true
    @public_status_refusals = true
    exercise_completion
  end

  def test_public_github_url_canonical_preserves_one_original_delivery
    @public_lab, @merge_provider, @merge_selection = true, "github", :remote
    exercise_completion
  end

  def test_public_github_url_fork_preserves_one_original_delivery
    @public_lab, @merge_provider, @merge_selection, @merge_fork = true, "github", :remote, true
    exercise_completion
  end

  def test_public_forgejo_default_canonical_preserves_one_original_delivery
    @public_lab, @merge_selection = true, :default
    exercise_completion
  end

  def test_public_forgejo_default_fork_preserves_one_original_delivery
    @public_lab, @merge_selection, @merge_fork = true, :default, true
    exercise_completion
  end

  def test_public_forgejo_named_fork_preserves_one_original_delivery
    @public_lab, @merge_fork = true, true
    exercise_completion
  end

  def test_real_receiver_fixed_cli_neutral_merge_and_canonical_receipt_import
    exercise_completion
  end

  def test_completion_interruption_before_cas_publishes_no_partial_result_or_import
    @interrupt_before_cas = true
    exercise_completion
  end

  def test_measure_original_request_service_admission_only
    @measure_request_admission = true
    exercise_completion
  end

  def test_original_service_artifact_refuses_foreign_principal_and_reused_worker_birth
    @identity_controls = true
    exercise_completion
  end

  def test_original_merge_consumer_refuses_stale_selectors_and_direct_local_artifact
    @selector_controls = true
    exercise_completion
  end

  def test_canonical_status_refuses_a_forged_later_delivery_result
    @forged_control = true
    exercise_completion
  end









  # Same controlled gate/release handshake as PreparedWorkFetchTest#issue_original;
  # no native worker is executed. Public original-input fetch requires issued
  # state; the inherited result-only fixture otherwise stops at bound.
end
