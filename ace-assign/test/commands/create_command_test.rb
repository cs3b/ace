# frozen_string_literal: true

require_relative "../test_helper"

class CreateCommandTest < AceAssignTestCase
  def test_create_with_valid_config
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      # Temporarily override cache dir
      original_config = Ace::Assign.config.dup
      Ace::Assign.config["cache_dir"] = cache_dir

      result = nil
      output = capture_io do
        result = Ace::Assign::CLI::Commands::Create.new.call(config: config_path)
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "Assignment: test-session"
      assert_includes output.first, "Phase 010: init"

      Ace::Assign.reset_config!
    end
  end

  def test_create_with_missing_config
    error = assert_raises(Ace::Core::CLI::Error) do
      Ace::Assign::CLI::Commands::Create.new.call(config: "nonexistent.yaml")
    end

    assert_equal 3, error.exit_code
    assert_includes error.message, "not found"
  end

  def test_create_quiet_mode
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      output = capture_io do
        Ace::Assign::CLI::Commands::Create.new.call(config: config_path, quiet: true)
      end

      assert_empty output.first.strip

      Ace::Assign.reset_config!
    end
  end
end
