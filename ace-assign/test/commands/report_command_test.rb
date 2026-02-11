# frozen_string_literal: true

require_relative "../test_helper"

class ReportCommandTest < AceAssignTestCase
  def test_report_completes_phase
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Phase done!")

      Ace::Assign.config["cache_dir"] = cache_dir

      # Start an assignment first
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = nil
      output = capture_io do
        result = Ace::Assign::CLI::Commands::Report.new.call(file: report_path)
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "Phase 010 (init) completed"
      assert_includes output.first, "Advancing to phase 020"

      Ace::Assign.reset_config!
    end
  end

  def test_report_with_missing_file
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::Report.new.call(file: "nonexistent.md")
      end

      assert_includes error.message, "not found"

      Ace::Assign.reset_config!
    end
  end

  def test_report_without_assignment
    with_temp_cache do |cache_dir|
      report_path = create_report(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::Report.new.call(file: report_path)
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"

      Ace::Assign.reset_config!
    end
  end
end
