# frozen_string_literal: true
require_relative '../../test_helper'

class ExecutionVerdictTest < Minitest::Test
  def parsed
    {summary: {runs: 3, passed: 3, failures: 0, errors: 0, skips: 0, assertions: 4},
      failures: [], deprecations: [], duration: 0.1, test_times: []}
  end

  def aggregate(outcomes, fail_fast: false)
    parser = Object.new
    value = parsed
    parser.define_singleton_method(:parse_output) { |_| value }
    executor = Object.new
    executor.define_singleton_method(:execute_with_progress) do |files, _options|
      {stdout: 'green partial summary', stderr: 'diagnostic', success: outcomes.fetch(files.first), duration: 0.1}
    end
    runner = Ace::TestRunner::Organisms::SequentialTargetExecutor.new(test_executor: executor, result_parser: parser)
    runner.execute_targets(outcomes.keys.map { |key| {name: key, files: [key]} }, fail_fast: fail_fast)
  end

  def test_later_success_cannot_hide_unsuccessful_execution
    result = aggregate({first: false, second: true})
    refute result[:success]
    assert_equal 6, result.dig(:parsed_result, :summary, :passed)
    assert_nil result[:stopped_at_target]
  end

  def test_fail_fast_retains_execution_failure
    result = aggregate({first: false, second: true}, fail_fast: true)
    refute result[:success]
    assert_equal :first, result[:stopped_at_target]
    assert_equal 3, result.dig(:parsed_result, :summary, :passed)
  end

  def test_orchestrator_preserves_execution_failure_without_inventing_tests
    orchestrator = Ace::TestRunner::Organisms::TestOrchestrator.allocate
    result = orchestrator.send(:build_result, parsed, {success: false, stdout: '', stderr: 'execution timed out', duration: 1}, Time.now)
    refute result.success?
    assert result.has_failures?
    assert_equal 3, result.total_tests
    assert_equal 0, result.errors
    assert_equal false, result.to_h[:execution_success]
    assert_match(/execution/i, result.summary_line)
    assert_match(/execution timed out/, result.execution_error)
  end

  def test_successful_timeout_text_is_not_failure
    orchestrator = Ace::TestRunner::Organisms::TestOrchestrator.allocate
    result = orchestrator.send(:build_result, parsed, {success: true, stdout: 'timeout', stderr: 'timeout', duration: 1}, Time.now)
    assert result.success?
    assert_nil result.execution_error
    assert aggregate({first: true, second: true})[:success]
  end
  def test_subprocess_fail_fast_takes_precedence_over_single_batch
    executor = Ace::TestRunner::Molecules::TestExecutor.new(launch_env: {})
    executor.define_singleton_method(:execute_per_file_with_progress) { |*_args| :per_file }
    executor.define_singleton_method(:execute_tests) { |*_args| :batch }
    assert_equal :per_file, executor.execute_with_progress(["a", "b"], fail_fast: true, run_in_single_batch: true)
    assert_equal :per_file, executor.execute_with_progress(["a", "b"], per_file: true, fail_fast: false)
    assert_equal :batch, executor.execute_with_progress(["a", "b"], fail_fast: false, run_in_single_batch: true)
  end

end
