# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/lint_evidence_runner"

class LintEvidenceRunnerTest < AceReviewTest
  def setup
    super
    @session_dir = File.join(@test_dir, "session")
    FileUtils.mkdir_p(@session_dir)
  end

  def test_run_writes_report_when_no_lintable_files_found
    reviewer = Ace::Review::Models::Reviewer.new(name: "lint", model: "tool:lint", provider_kind: "tool")
    runner = Ace::Review::Molecules::LintEvidenceRunner.new(project_root: @test_dir)

    runner.stub :lint_candidate_files, [] do
      result = runner.run(reviewer: reviewer, session_dir: @session_dir)

      assert result[:success]
      assert File.exist?(result[:output_file])
      content = File.read(result[:output_file])
      assert_match(/No lint-eligible files were detected/, content)
      assert_match(/reviewer_type: tool/, content)
    end
  end

  def test_run_executes_lint_command_and_captures_findings
    reviewer = Ace::Review::Models::Reviewer.new(name: "lint", model: "tool:lint", provider_kind: "tool")
    runner = Ace::Review::Molecules::LintEvidenceRunner.new(project_root: @test_dir)

    test_file = File.join(@test_dir, "sample.rb")
    File.write(test_file, "puts 'hello'\n")

    runner.stub :lint_candidate_files, ["sample.rb"] do
      runner.stub :lint_command, ["/bin/sh", "-c", "printf 'lint issue\\n'"] do
        result = runner.run(reviewer: reviewer, session_dir: @session_dir)

        assert result[:success]
        assert_equal 0, result[:lint_exit_code]
        content = File.read(result[:output_file])
        assert_match(/lint issue/, content)
        assert_match(/sample\.rb/, content)
      end
    end
  end
end
