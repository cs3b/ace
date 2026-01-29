# frozen_string_literal: true

require_relative "../test_helper"

class AddCommandTest < AceCoworkerTestCase
  def test_add_creates_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Coworker.config["cache_dir"] = cache_dir

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = nil
      output = capture_io do
        result = Ace::Coworker::CLI::Commands::Add.new.call(
          name: "fix-bug",
          instructions: "Fix the bug"
        )
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "Created: jobs/"
      assert_includes output.first, "fix-bug"

      Ace::Coworker.reset_config!
    end
  end

  def test_add_without_session
    with_temp_cache do |cache_dir|
      Ace::Coworker.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Coworker::CLI::Commands::Add.new.call(name: "fix-bug")
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active session"

      Ace::Coworker.reset_config!
    end
  end
end
