# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Atoms::RuboCopRunnerTest < Minitest::Test
  # Helper to stub availability check and Open3.capture3 for testing
  # Uses system_has_command? stub for availability and Open3.capture3 for actual linting
  def stub_rubocop_run(output: "", stderr: "", exit_status: 0, available: true)
    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { exit_status == 0 }
    mock_status.define_singleton_method(:exitstatus) { exit_status }

    # Reset BOTH caches before stubbing so stubs are called (not cached results)
    Ace::Lint::Atoms::StandardrbRunner.reset_availability_cache!
    Ace::Lint::Atoms::RuboCopRunner.reset_availability_cache!

    # Stub the availability check
    Ace::Lint::Atoms::RuboCopRunner.stub(:system_has_command?, available) do
      # Also stub StandardRB to avoid real subprocess calls when tests interleave
      Ace::Lint::Atoms::StandardrbRunner.stub(:system_has_command?, true) do
        # Stub Open3.capture3 for the actual linting command
        Open3.stub(:capture3, ->(*_args) { [output, stderr, mock_status] }) do
          # Pre-populate BOTH caches with stub values so subsequent tests hit cache
          Ace::Lint::Atoms::StandardrbRunner.available?
          Ace::Lint::Atoms::RuboCopRunner.available?
          yield
        end
      end
    end
  end

  def test_available_returns_true_when_rubocop_exists
    stub_rubocop_run(exit_status: 0) do
      assert Ace::Lint::Atoms::RuboCopRunner.available?
    end
  end

  def test_available_returns_false_when_rubocop_missing
    stub_rubocop_run(exit_status: 1, available: false) do
      refute Ace::Lint::Atoms::RuboCopRunner.available?
    end
  end

  def test_run_returns_unavailable_result_when_rubocop_missing
    stub_rubocop_run(exit_status: 1, available: false) do
      result = Ace::Lint::Atoms::RuboCopRunner.run("test.rb")
      refute result[:success]
      assert_match(/No Ruby linter available/, result[:errors].first[:message])
      # Should mention both StandardRB and RuboCop
      assert_match(/StandardRB/, result[:errors].first[:message])
      assert_match(/RuboCop/, result[:errors].first[:message])
    end
  end

  def test_run_with_empty_output_returns_success
    stub_rubocop_run(output: "", exit_status: 0) do
      result = Ace::Lint::Atoms::RuboCopRunner.run("test.rb")
      assert result[:success]
      assert_empty result[:errors]
      assert_empty result[:warnings]
    end
  end

  def test_run_with_no_offenses_returns_success
    stub_rubocop_run(output: "no offenses detected", exit_status: 0) do
      result = Ace::Lint::Atoms::RuboCopRunner.run("test.rb")
      assert result[:success]
      assert_empty result[:errors]
      assert_empty result[:warnings]
    end
  end

  def test_run_with_rubocop_json_format_parses_correctly
    json_output = {
      "files" => [
        {
          "path" => "lib/test.rb",
          "offenses" => [
            {
              "severity" => "convention",
              "message" => "Missing frozen string literal comment",
              "cop_name" => "Style/FrozenStringLiteralComment",
              "location" => {"line" => 1, "column" => 0}
            },
            {
              "severity" => "error",
              "message" => "Unexpected token",
              "cop_name" => "Syntax",
              "location" => {"line" => 5, "column" => 10}
            }
          ]
        }
      ]
    }.to_json

    stub_rubocop_run(output: json_output, exit_status: 1) do
      result = Ace::Lint::Atoms::RuboCopRunner.run("test.rb")

      refute result[:success]
      assert_equal 1, result[:errors].size
      assert_equal 1, result[:warnings].size

      # Check error (severity: error)
      error = result[:errors].first
      assert_equal "lib/test.rb", error[:file]
      assert_equal 5, error[:line]
      assert_equal 10, error[:column]
      assert_match(/Syntax: Unexpected token/, error[:message])

      # Check warning (severity: convention)
      warning = result[:warnings].first
      assert_equal "lib/test.rb", warning[:file]
      assert_equal 1, warning[:line]
      assert_equal 0, warning[:column]
      assert_match(/Style\/FrozenStringLiteralComment/, warning[:message])
    end
  end

  def test_run_with_legacy_array_format_fallback
    # Some tools may output direct array format
    json_output = [
      {
        "severity" => "convention",
        "message" => "Line is too long",
        "cop_name" => "Metrics/LineLength",
        "location" => {
          "path" => "legacy.rb",
          "line" => 10,
          "column" => 80
        }
      }
    ].to_json

    stub_rubocop_run(output: json_output, exit_status: 1) do
      result = Ace::Lint::Atoms::RuboCopRunner.run("legacy.rb")

      assert_equal 1, result[:warnings].size
      warning = result[:warnings].first
      assert_equal "legacy.rb", warning[:file]
      assert_equal 10, warning[:line]
    end
  end

  def test_run_with_text_output_fallback
    text_output = "legacy.rb:10:80: C: Line is too long [100/80]\n"

    stub_rubocop_run(output: "", stderr: text_output, exit_status: 1) do
      result = Ace::Lint::Atoms::RuboCopRunner.run("legacy.rb")

      assert_equal 1, result[:warnings].size
      warning = result[:warnings].first
      assert_equal "legacy.rb", warning[:file]
      assert_equal 10, warning[:line]
      assert_equal 80, warning[:column]
    end
  end

  def test_run_handles_json_parse_error
    stub_rubocop_run(output: "invalid { json", exit_status: 0) do
      result = Ace::Lint::Atoms::RuboCopRunner.run("test.rb")

      # Should return success on parse error in success case
      assert result[:success]
      assert_empty result[:errors]
      assert_empty result[:warnings]
    end
  end

  def test_run_includes_autocorrect_flag_when_requested
    called_with = nil

    # Stub availability check to avoid subprocess, then capture command
    Ace::Lint::Atoms::RuboCopRunner.stub(:available?, true) do
      Open3.stub(:capture3, ->(*args) {
        called_with = args
        ["", "", Object.new.tap { |s| s.define_singleton_method(:success?) { true } }]
      }) do
        Ace::Lint::Atoms::RuboCopRunner.run("test.rb", fix: true)
      end
    end

    # Verify --autocorrect is in the command args (RuboCop's flag for fix)
    # called_with is the full args array, check if it includes --autocorrect
    assert_includes called_with, "--autocorrect"
  end

  def test_build_command_includes_autocorrect_flag
    cmd = Ace::Lint::Atoms::RuboCopRunner.build_command(["test.rb"], fix: true)
    assert_includes cmd, "--autocorrect"
    assert_includes cmd, "test.rb"
  end

  def test_build_command_without_fix
    cmd = Ace::Lint::Atoms::RuboCopRunner.build_command(["test.rb"], fix: false)
    refute_includes cmd, "--autocorrect"
    assert_includes cmd, "test.rb"
  end

  def test_build_command_with_multiple_files
    cmd = Ace::Lint::Atoms::RuboCopRunner.build_command(["test1.rb", "test2.rb"], fix: false)
    assert_includes cmd, "test1.rb"
    assert_includes cmd, "test2.rb"
    # Command now includes --config flag if config exists, so size may vary
    assert cmd.size >= 5  # ["rubocop", "--format", "json", "test1.rb", "test2.rb", + optional config flags]
  end

  def test_run_with_warnings_only_returns_failure_when_non_zero_exit
    # RuboCop exits non-zero for convention/warning level offenses
    # This test ensures we propagate the exit status, not just error count
    json_output = {
      "files" => [
        {
          "path" => "lib/test.rb",
          "offenses" => [
            {
              "severity" => "convention",
              "message" => "Missing frozen string literal comment",
              "cop_name" => "Style/FrozenStringLiteralComment",
              "location" => {"line" => 1, "column" => 0}
            },
            {
              "severity" => "warning",
              "message" => "Useless assignment to variable",
              "cop_name" => "Lint/UselessAssignment",
              "location" => {"line" => 10, "column" => 5}
            }
          ]
        }
      ]
    }.to_json

    # Non-zero exit status (1) indicates violations found
    stub_rubocop_run(output: json_output, exit_status: 1) do
      result = Ace::Lint::Atoms::RuboCopRunner.run("test.rb")

      # Critical: success must be false when exit status is non-zero
      # even though there are no "error" severity offenses
      refute result[:success], "Expected success to be false when RuboCop exits non-zero with warnings"

      # Warnings should still be parsed
      assert_equal 2, result[:warnings].size
      assert_empty result[:errors]
    end
  end

  def test_run_with_warnings_only_returns_success_when_zero_exit
    # If RuboCop exits zero, warnings should not cause failure
    json_output = {
      "files" => [
        {
          "path" => "lib/test.rb",
          "offenses" => [
            {
              "severity" => "convention",
              "message" => "Missing frozen string literal comment",
              "cop_name" => "Style/FrozenStringLiteralComment",
              "location" => {"line" => 1, "column" => 0}
            }
          ]
        }
      ]
    }.to_json

    # Zero exit status means no violations that should fail the build
    stub_rubocop_run(output: json_output, exit_status: 0) do
      result = Ace::Lint::Atoms::RuboCopRunner.run("test.rb")

      # With zero exit, success depends on error presence
      assert result[:success], "Expected success to be true when RuboCop exits zero"
      assert_equal 1, result[:warnings].size
    end
  end

  def test_text_output_with_warnings_only_returns_failure_when_non_zero_exit
    text_output = "lib/test.rb:10:5: W: Useless assignment to variable\n"

    # Non-zero exit status (1) with warnings only
    stub_rubocop_run(output: "", stderr: text_output, exit_status: 1) do
      result = Ace::Lint::Atoms::RuboCopRunner.run("test.rb")

      # Critical: success must be false when exit status is non-zero
      refute result[:success], "Expected success to be false when RuboCop exits non-zero with text warnings"
      assert_equal 1, result[:warnings].size
      assert_empty result[:errors]
    end
  end
end
