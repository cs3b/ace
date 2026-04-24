# frozen_string_literal: true

require_relative "../../test_helper"
require "stringio"
require "tmpdir"

class RunTestTest < Minitest::Test
  RunTest = Ace::Test::EndToEndRunner::CLI::Commands::RunTest

  class StubTestOrchestrator
    attr_reader :calls

    def initialize(results = [])
      @results = results
      @calls = []
    end

    def run(**options)
      @calls << options
      @results
    end
  end

  class StubArtifactPruner
    attr_reader :calls

    def initialize(result = nil)
      @result = result || {
        root_display: ".ace-local/test-e2e",
        deleted_count: 3
      }
      @calls = []
    end

    def prune(base_dir: Dir.pwd)
      @calls << {base_dir: base_dir}
      @result
    end
  end

  class StubRunTest < RunTest
    def initialize(orchestrator:, pruner:)
      super()
      @orchestrator = orchestrator
      @pruner = pruner
    end

    private

    def build_orchestrator(provider:, timeout:, parallel:, progress:)
      @orchestrator
    end

    def build_artifact_pruner
      @pruner
    end
  end

  def test_prune_artifacts_runs_before_orchestration
    pruner = StubArtifactPruner.new
    orchestrator = StubTestOrchestrator.new([passing_result])
    command = StubRunTest.new(orchestrator: orchestrator, pruner: pruner)

    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) { command.call(package: "ace-lint", prune_artifacts: true, quiet: true) }
    end

    assert_equal 1, pruner.calls.length
    assert_equal 1, orchestrator.calls.length
  end

  def test_prune_artifacts_is_rejected_with_dry_run
    pruner = StubArtifactPruner.new
    orchestrator = StubTestOrchestrator.new([passing_result])
    command = StubRunTest.new(orchestrator: orchestrator, pruner: pruner)

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(package: "ace-lint", prune_artifacts: true, dry_run: true, quiet: true)
    end

    assert_match(/cannot be used with --dry-run/, error.message)
    assert_empty pruner.calls
    assert_empty orchestrator.calls
  end

  def test_parse_tags_normalizes_values
    command = RunTest.new

    tags = command.send(:parse_tags, "Smoke, happy-path, use-case:Lint")

    assert_equal ["smoke", "happy-path", "use-case:lint"], tags
  end

  def test_parse_tags_handles_blank_value
    command = RunTest.new

    assert_equal [], command.send(:parse_tags, nil)
    assert_equal [], command.send(:parse_tags, "   ")
  end

  private

  def passing_result
    Ace::Test::EndToEndRunner::Models::TestResult.new(
      test_id: "TS-LINT-001",
      status: "pass",
      test_cases: [{id: "TC-001", status: "pass", description: "", actual: "", notes: ""}],
      summary: "1/1 passed"
    )
  end
end
