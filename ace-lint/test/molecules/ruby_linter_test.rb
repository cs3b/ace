# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Molecules::RubyLinterTest < Minitest::Test
  def setup
    @file_path = "lib/test.rb"
  end

  def stub_standardrb_runner(output: "", stderr: "", exit_status: 0)
    mock_result = {
      success: exit_status == 0,
      errors: [],
      warnings: []
    }

    # If output contains JSON, parse it and populate errors/warnings
    if exit_status != 0 && !output.empty?
      begin
        data = JSON.parse(output)
        if data.is_a?(Hash) && data.key?("files")
          data["files"].each do |file_data|
            file_path = file_data["path"]
            offenses = file_data["offenses"] || []
            offenses.each do |offense|
              item = {
                file: file_path,
                line: offense.dig("location", "line") || 0,
                column: offense.dig("location", "column") || 0,
                message: "#{offense['cop_name']}: #{offense['message']}"
              }
              if ["error", "fatal"].include?(offense["severity"])
                mock_result[:errors] << item
              else
                mock_result[:warnings] << item
              end
            end
          end
        end
        # Update success based on whether there are errors
        # Warnings are OK, only errors should make success false
        mock_result[:success] = mock_result[:errors].empty?
      rescue JSON::ParserError
        # Keep empty result
      end
    end

    Ace::Lint::Atoms::StandardrbRunner.stub(:run, mock_result) do
      yield
    end
  end

  def test_lint_returns_success_result_for_clean_file
    stub_standardrb_runner(exit_status: 0) do
      result = Ace::Lint::Molecules::RubyLinter.lint(@file_path)

      assert result.success?
      assert_empty result.errors
      assert_empty result.warnings
      assert_equal @file_path, result.file_path
    end
  end

  def test_lint_returns_failure_result_for_errors
    json_output = {
      "files" => [
        {
          "path" => @file_path,
          "offenses" => [
            {
              "severity" => "error",
              "message" => "Syntax error",
              "cop_name" => "Syntax",
              "location" => { "line" => 5, "column" => 10 }
            }
          ]
        }
      ]
    }.to_json

    stub_standardrb_runner(output: json_output, exit_status: 1) do
      result = Ace::Lint::Molecules::RubyLinter.lint(@file_path)

      refute result.success?
      assert_equal 1, result.errors.size
      assert_equal @file_path, result.file_path
      assert_match(/Syntax: Syntax error/, result.errors.first.message)
    end
  end

  def test_lint_returns_success_with_warnings
    json_output = {
      "files" => [
        {
          "path" => @file_path,
          "offenses" => [
            {
              "severity" => "convention",
              "message" => "Missing frozen string literal",
              "cop_name" => "Style/FrozenStringLiteralComment",
              "location" => { "line" => 1, "column" => 0 }
            }
          ]
        }
      ]
    }.to_json

    stub_standardrb_runner(output: json_output, exit_status: 1) do
      result = Ace::Lint::Molecules::RubyLinter.lint(@file_path)

      # No errors means success (warnings are ok)
      assert result.success?
      assert_empty result.errors
      assert_equal 1, result.warnings.size
      assert_match(/Style\/FrozenStringLiteralComment/, result.warnings.first.message)
    end
  end

  def test_lint_with_both_errors_and_warnings
    json_output = {
      "files" => [
        {
          "path" => @file_path,
          "offenses" => [
            {
              "severity" => "convention",
              "message" => "Line too long",
              "cop_name" => "Metrics/LineLength",
              "location" => { "line" => 10, "column" => 80 }
            },
            {
              "severity" => "error",
              "message" => "Undefined variable",
              "cop_name" => "Lint/UndefinedVariable",
              "location" => { "line" => 15, "column" => 5 }
            }
          ]
        }
      ]
    }.to_json

    stub_standardrb_runner(output: json_output, exit_status: 1) do
      result = Ace::Lint::Molecules::RubyLinter.lint(@file_path)

      refute result.success?
      assert_equal 1, result.errors.size
      assert_equal 1, result.warnings.size
    end
  end

  def test_lint_with_fix_flag_sets_formatted
    stub_standardrb_runner(exit_status: 0) do
      result = Ace::Lint::Molecules::RubyLinter.lint(@file_path, options: { fix: true })

      assert result.formatted?
    end
  end

  def test_lint_without_fix_flag_not_formatted
    stub_standardrb_runner(exit_status: 0) do
      result = Ace::Lint::Molecules::RubyLinter.lint(@file_path)

      refute result.formatted?
    end
  end

  def test_lint_handles_standardrb_not_available
    unavailable_result = {
      success: false,
      errors: [{ message: "StandardRB is not installed. Install it with: gem install standardrb" }],
      warnings: []
    }

    Ace::Lint::Atoms::StandardrbRunner.stub(:run, unavailable_result) do
      result = Ace::Lint::Molecules::RubyLinter.lint(@file_path)

      refute result.success?
      assert_equal 1, result.errors.size
      assert_match(/not installed/, result.errors.first.message)
    end
  end

  def test_lint_handles_exception_gracefully
    Ace::Lint::Atoms::StandardrbRunner.stub(:run, ->(*) { raise "Boom!" }) do
      result = Ace::Lint::Molecules::RubyLinter.lint(@file_path)

      refute result.success?
      assert_equal 1, result.errors.size
      assert_match(/Ruby linting failed/, result.errors.first.message)
    end
  end

  def test_lint_passes_options_to_runner
    options_passed = nil

    # Stub with a callable that captures arguments
    Ace::Lint::Atoms::StandardrbRunner.stub(:run, ->(file_paths, fix: false) {
      options_passed = { fix: fix }
      { success: true, errors: [], warnings: [] }
    }) do
      Ace::Lint::Molecules::RubyLinter.lint(@file_path, options: { fix: true })
    end

    assert_equal true, options_passed[:fix]
  end

  def test_multiple_offenses_parsed_correctly
    json_output = {
      "files" => [
        {
          "path" => @file_path,
          "offenses" => [
            { "severity" => "convention", "message" => "Offense 1", "cop_name" => "Cop1", "location" => { "line" => 1, "column" => 0 } },
            { "severity" => "warning", "message" => "Offense 2", "cop_name" => "Cop2", "location" => { "line" => 2, "column" => 0 } },
            { "severity" => "convention", "message" => "Offense 3", "cop_name" => "Cop3", "location" => { "line" => 3, "column" => 0 } }
          ]
        }
      ]
    }.to_json

    stub_standardrb_runner(output: json_output, exit_status: 1) do
      result = Ace::Lint::Molecules::RubyLinter.lint(@file_path)

      assert_equal 3, result.warnings.size
      assert result.success?
    end
  end

  # Batch processing tests
  def test_batch_lint_with_multiple_files
    file1 = "lib/file1.rb"
    file2 = "lib/file2.rb"
    file3 = "lib/file3.rb"

    json_output = {
      "files" => [
        {
          "path" => file1,
          "offenses" => [
            { "severity" => "convention", "message" => "Offense 1", "cop_name" => "Cop1", "location" => { "line" => 1, "column" => 0 } }
          ]
        },
        {
          "path" => file2,
          "offenses" => [
            { "severity" => "error", "message" => "Offense 2", "cop_name" => "Cop2", "location" => { "line" => 2, "column" => 0 } }
          ]
        },
        {
          "path" => file3,
          "offenses" => []
        }
      ]
    }.to_json

    stub_standardrb_runner(output: json_output, exit_status: 1) do
      results = Ace::Lint::Molecules::RubyLinter.lint_batch([file1, file2, file3])

      assert_equal 3, results.size
      assert_equal file1, results[0].file_path
      assert_equal 1, results[0].warnings.size
      assert results[0].success?

      assert_equal file2, results[1].file_path
      assert_equal 1, results[1].errors.size
      refute results[1].success?

      assert_equal file3, results[2].file_path
      assert_empty results[2].errors
      assert_empty results[2].warnings
      assert results[2].success?
    end
  end

  def test_batch_lint_with_empty_file_list
    results = Ace::Lint::Molecules::RubyLinter.lint_batch([])
    assert_empty results
  end

  def test_batch_lint_with_fix_flag
    file1 = "lib/file1.rb"
    file2 = "lib/file2.rb"

    stub_standardrb_runner(output: "no offenses", exit_status: 0) do
      results = Ace::Lint::Molecules::RubyLinter.lint_batch([file1, file2], options: { fix: true })

      assert_equal 2, results.size
      results.each do |result|
        assert result.formatted?
      end
    end
  end

  def test_batch_lint_handles_exception_gracefully
    file1 = "lib/file1.rb"
    file2 = "lib/file2.rb"

    Ace::Lint::Atoms::StandardrbRunner.stub(:run, ->(*) { raise "Batch failed" }) do
      results = Ace::Lint::Molecules::RubyLinter.lint_batch([file1, file2])

      assert_equal 2, results.size
      results.each do |result|
        refute result.success?
        assert_equal 1, result.errors.size
        assert_match(/Batch linting failed/, result.errors.first.message)
      end
    end
  end

  def test_batch_lint_groups_offenses_by_file
    file1 = "lib/file1.rb"
    file2 = "lib/file2.rb"

    json_output = {
      "files" => [
        {
          "path" => file1,
          "offenses" => [
            { "severity" => "convention", "message" => "Warning 1", "cop_name" => "Cop1", "location" => { "line" => 1, "column" => 0 } },
            { "severity" => "warning", "message" => "Warning 2", "cop_name" => "Cop2", "location" => { "line" => 2, "column" => 0 } }
          ]
        },
        {
          "path" => file2,
          "offenses" => [
            { "severity" => "convention", "message" => "Warning 3", "cop_name" => "Cop3", "location" => { "line" => 3, "column" => 0 } }
          ]
        }
      ]
    }.to_json

    stub_standardrb_runner(output: json_output, exit_status: 1) do
      results = Ace::Lint::Molecules::RubyLinter.lint_batch([file1, file2])

      assert_equal 2, results.size
      assert_equal 2, results[0].warnings.size
      assert_equal 1, results[1].warnings.size
    end
  end
end
