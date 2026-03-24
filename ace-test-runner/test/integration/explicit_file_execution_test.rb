# frozen_string_literal: true

require_relative "../test_helper"
require "ace/test_runner/organisms/test_orchestrator"

class ExplicitFileExecutionTest < Minitest::Test
  def test_orchestrator_bypasses_groups_when_explicit_files_provided
    # Create configuration with both groups and explicit files
    options = {
      files: ["test/atoms/test_detector_test.rb"],
      config_path: nil
    }

    orchestrator = Ace::TestRunner::Organisms::TestOrchestrator.new(options)

    # The orchestrator should NOT execute sequentially when explicit files are provided
    refute orchestrator.send(:should_execute_sequentially?),
      "Expected should_execute_sequentially? to return false when explicit files are provided"
  end

  def test_orchestrator_uses_groups_when_no_files_provided
    # Create configuration with groups but no explicit files
    options = {
      files: nil,
      target: "smoke",
      config_path: nil
    }

    orchestrator = Ace::TestRunner::Organisms::TestOrchestrator.new(options)
    configuration = orchestrator.configuration

    # Manually set execution_mode and groups to simulate grouped execution
    configuration.instance_variable_set(:@execution_mode, "grouped")
    configuration.instance_variable_set(:@groups, {"smoke" => ["test/atoms/test_detector_test.rb"]})

    # Should execute sequentially when no files but groups and target are configured
    assert orchestrator.send(:should_execute_sequentially?),
      "Expected should_execute_sequentially? to return true when groups and target are configured without explicit files"
  end

  def test_orchestrator_handles_empty_files_array
    # Create configuration with empty files array
    options = {
      files: [],
      config_path: nil
    }

    orchestrator = Ace::TestRunner::Organisms::TestOrchestrator.new(options)

    # Empty array should NOT bypass groups (!@configuration.files.empty? evaluates to false)
    # When config has grouped mode with "all" group, should return true
    # (empty array doesn't trigger the explicit files bypass on line 268)
    result = orchestrator.send(:should_execute_sequentially?)

    # Result depends on whether config has grouped mode + groups defined
    # In the project's config, mode is "grouped" and "all" group exists
    assert result,
      "Expected should_execute_sequentially? to return true for empty files array when grouped mode is configured"
  end

  def test_orchestrator_handles_multiple_explicit_files
    # Create configuration with multiple explicit files
    options = {
      files: [
        "test/atoms/test_detector_test.rb",
        "test/models/test_configuration_test.rb"
      ],
      config_path: nil
    }

    orchestrator = Ace::TestRunner::Organisms::TestOrchestrator.new(options)

    # Should bypass groups when multiple files are provided
    refute orchestrator.send(:should_execute_sequentially?),
      "Expected should_execute_sequentially? to return false when multiple explicit files are provided"
  end

  def test_orchestrator_handles_file_with_line_number
    # Create configuration with file:line format
    options = {
      files: ["test/atoms/test_detector_test.rb:42"],
      config_path: nil
    }

    orchestrator = Ace::TestRunner::Organisms::TestOrchestrator.new(options)

    # Should bypass groups even with line number notation
    refute orchestrator.send(:should_execute_sequentially?),
      "Expected should_execute_sequentially? to return false when file with line number is provided"
  end

  def test_configuration_preserves_explicit_files
    # Verify that explicit files are preserved in configuration
    options = {
      files: ["test/atoms/test_detector_test.rb"],
      config_path: nil
    }

    orchestrator = Ace::TestRunner::Organisms::TestOrchestrator.new(options)
    configuration = orchestrator.configuration

    assert_equal ["test/atoms/test_detector_test.rb"], configuration.files,
      "Expected configuration to preserve explicit files"
  end

  def test_find_test_files_returns_explicit_files
    # Verify that find_test_files returns only the explicit files
    options = {
      files: ["test/atoms/test_detector_test.rb"],
      config_path: nil
    }

    orchestrator = Ace::TestRunner::Organisms::TestOrchestrator.new(options)

    # Call find_test_files (private method)
    files = orchestrator.send(:find_test_files)

    assert_equal ["test/atoms/test_detector_test.rb"], files,
      "Expected find_test_files to return only the explicit files"
  end

  def test_precedence_files_over_target
    # When both files and target are provided, files should take precedence
    options = {
      files: ["test/atoms/test_detector_test.rb"],
      target: "smoke",
      config_path: nil
    }

    orchestrator = Ace::TestRunner::Organisms::TestOrchestrator.new(options)

    # Should bypass groups because explicit files are provided
    refute orchestrator.send(:should_execute_sequentially?),
      "Expected should_execute_sequentially? to return false when both files and target are provided"

    # And find_test_files should return only the explicit files
    files = orchestrator.send(:find_test_files)
    assert_equal ["test/atoms/test_detector_test.rb"], files,
      "Expected find_test_files to return only explicit files, ignoring target"
  end
end
