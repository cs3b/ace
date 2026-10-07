# frozen_string_literal: true
require "test_helper"
require "timeout"

class PreparedCandidateReviewTest < AceReviewTest
  BINDING = {"assignment_id" => "assignment", "attempt_id" => "attempt", "candidate_generation" => 1,
             "head" => "a" * 40, "purpose_id" => "review-purpose", "tree" => "b" * 40}.freeze

  class ControlledProvider
    attr_accessor :verdict, :findings, :extraction, :partial, :wrong_head, :change_report, :no_verdict, :oversized, :mismatch_response, :change_prompt, :fifo
    attr_reader :calls
    def initialize
      @calls, @verdict, @findings, @extraction = [], "approved", [], '{"findings":[]}'
    end

    def execute(system_prompt:, user_prompt:, model:, session_dir:, output_file: nil, **options)
      @calls << {model: model, system: system_prompt, user: user_prompt, options: options}
      if model == "role:review-default"
        packet = JSON.parse(user_prompt)
        candidate = packet.fetch("candidate")
        response = JSON.generate("schema" => "ace.review.candidate-verdict/v1", "head" => (wrong_head ? "c" * 40 : candidate.fetch("head")),
          "tree" => candidate.fetch("tree"), "subject_sha256" => packet.fetch("subject_sha256"),
          "verdict" => verdict, "summary" => "Executed review", "findings" => findings)
        response = '{"findings":[]}' if no_verdict
        response = "x" * 65_537 if oversized
        output_file ||= File.join(session_dir, "review-report-fixture.md")
        @report_path = output_file
      else
        response = extraction
        File.write(@report_path, "changed after executed review") if change_report
      end
      FileUtils.mkdir_p(session_dir)
      File.write(output_file, response)
      if fifo && model == "role:review-default"
        File.unlink(output_file)
        File.mkfifo(output_file, 0o600)
      end
      File.write(File.join(session_dir, "user.prompt.md"), "substituted prompt") if change_prompt && model == "role:review-default"
      {success: true, response: (mismatch_response ? "different" : response), output_file: output_file,
       requested_selector: model, execution: {"status" => (partial ? "failed" : "succeeded"),
         "provider" => "controlled", "model" => "test-reviewer"}}
    end
  end

  def setup
    super
    @provider = ControlledProvider.new
    @manager = Ace::Review::Organisms::ReviewManager.new(project_root: @test_dir)
    @directory = File.join(@test_dir, "prepared-review")
    @subject = "FILE src/main.rb\nputs 'candidate'\n"
    @limits = Struct.new(:context_limit, :output_limit).new(200_000, 8192)
  end

  def run_review(candidate: BINDING, subject: @subject)
    Ace::Review::Molecules::LlmExecutor.stub(:new, @provider) do
      Ace::Review::Atoms::ContextLimitResolver.stub(:resolve_details, @limits) do
        @manager.execute_prepared_candidate(candidate: candidate, subject: subject, session_dir: @directory)
      end
    end
  end

  def test_actual_manager_and_feedback_pipeline_produce_explicit_bound_approval
    result = run_review
    assert result[:success], result[:error]
    assert_equal "approved", result[:verdict]
    assert_equal BINDING, result[:candidate]
    assert_equal ["role:review-default", "role:review-synthesizer"], @provider.calls.map { |call| call[:model] }
    assert_equal 900, @provider.calls.first[:options][:timeout]
    assert_equal 3, result[:artifacts].size
    metadata = YAML.safe_load(result[:artifacts].fetch("metadata.yml"), permitted_classes: [Symbol])
    assert_equal BINDING, metadata.fetch("candidate_binding")
    assert_equal "succeeded", metadata.dig("feedback_extraction", "status")
    assert_equal [], metadata.dig("feedback_extraction", "finding_ids")
    assert_equal Digest::SHA256.hexdigest(@subject), metadata.fetch("subject_sha256")
    assert_equal ["exact-candidate-review-execution", "complete-review-feedback-inventory"], result[:checks].map { |c| c["name"] }
    assert result[:artifacts].values.all? { |bytes| bytes.bytesize <= 65_536 }
  end

  def test_extraction_uses_held_report_even_when_path_becomes_fifo
    @manager.singleton_class.class_eval do
      def validate_candidate_provider_output!(result, directory)
        held = super
        File.unlink(result.fetch(:output_file))
        File.mkfifo(result.fetch(:output_file), 0o600)
        held
      end
    end
    result = Timeout.timeout(2) { run_review }
    refute result[:success], "Final non-regular artifact must still refuse"
    assert_equal 2, @provider.calls.size
    assert_includes @provider.calls.last.fetch(:user), "Executed review"
  end

  def test_ordinary_single_model_entry_retains_its_execution_and_no_feedback_behavior
    FileUtils.mkdir_p(@directory)
    data = {model: "role:review-default", system_prompt: "ordinary instructions",
            user_prompt: JSON.generate("candidate" => BINDING, "subject_sha256" => Digest::SHA256.hexdigest(@subject))}
    options = Ace::Review::Models::ReviewOptions.new(no_feedback: true)
    result = Ace::Review::Molecules::LlmExecutor.stub(:new, @provider) do
      @manager.send(:execute_single_model, data, @directory, options, "role:review-default")
    end
    assert result[:success], result[:error]
    assert_equal 1, @provider.calls.size
    refute @provider.calls.first[:options].key?(:timeout)
    refute result.key?(:verdict)
    assert File.file?(result[:output_file])
  end

  def test_explicit_unavailable_or_changes_requested_does_not_become_approval
    @provider.verdict = "unavailable"
    result = run_review
    assert result[:success], result[:error]
    assert_equal "unavailable", result[:verdict]
  end

  def test_no_explicit_verdict_cannot_be_inferred_from_zero_findings
    @provider.no_verdict = true
    result = run_review
    refute result[:success]
    assert_includes result[:error], "explicit exact-candidate verdict"
  end

  def test_wrong_head_refuses_even_when_provider_and_extraction_succeed
    @provider.wrong_head = true
    refute run_review[:success]
  end

  def test_provider_success_hash_does_not_hide_partial_execution
    @provider.partial = true
    result = run_review
    refute result[:success]
    assert_equal 1, @provider.calls.size
    assert_includes result[:error], "execution is incomplete"
  end

  def test_report_must_equal_completed_provider_output
    @provider.mismatch_response = true
    refute run_review[:success]
    assert_equal 1, @provider.calls.size
  end

  def test_original_prompt_identity_cannot_be_replaced_by_provider_metadata
    @provider.change_prompt = true
    result = run_review
    refute result[:success]
    assert_includes result[:error], "provenance differs"
  end

  def test_report_cannot_change_during_feedback_extraction
    @provider.change_report = true
    refute run_review[:success]
  end

  def test_malformed_extraction_cannot_mean_no_findings
    @provider.extraction = '{}'
    result = run_review
    refute result[:success]
    assert_includes result[:error], "extraction is incomplete"
  end

  def test_explicit_report_findings_prevent_approval_even_if_synthesis_loses_them
    @provider.findings = [{"title" => "Bug", "finding" => "src/main.rb has a defect"}]
    result = run_review
    refute result[:success]
    assert_includes result[:error], "conflicts with recorded findings"
  end

  def test_fifo_report_refuses_without_waiting_for_a_writer
    @provider.fifo = true
    result = Timeout.timeout(2) { run_review }
    refute result[:success]
    assert_includes result[:error], "artifact is unavailable"
    assert_equal 1, @provider.calls.size
  end

  def test_oversized_report_refuses_before_extraction
    @provider.oversized = true
    refute run_review[:success]
    assert_equal 1, @provider.calls.size
  end

  def test_claimed_session_never_runs_provider_again
    assert run_review[:success]
    count = @provider.calls.size
    refute run_review[:success]
    assert_equal count, @provider.calls.size
  end

  def test_invalid_binding_and_full_packet_budget_refuse_before_provider
    refute run_review(candidate: BINDING.merge("candidate_generation" => 1.0))[:success]
    refute run_review(subject: "source " * 150_000)[:success]
    assert_empty @provider.calls
    refute Dir.exist?(@directory)
  end
end
