# frozen_string_literal: true

require_relative "../test_helper"

class CreateCommandTest < AceCoworkerTestCase
  def test_create_with_valid_config
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      # Temporarily override cache dir
      original_config = Ace::Coworker.config.dup
      Ace::Coworker.config["cache_dir"] = cache_dir

      result = nil
      output = capture_io do
        result = Ace::Coworker::CLI::Commands::Create.new.call(config: config_path)
      end

      assert_equal 0, result
      assert_includes output.first, "Session: test-session"
      assert_includes output.first, "Step 010: init"

      Ace::Coworker.reset_config!
    end
  end

  def test_create_with_missing_config
    result = nil
    output = capture_io do
      result = Ace::Coworker::CLI::Commands::Create.new.call(config: "nonexistent.yaml")
    end

    assert_equal 3, result
    assert_includes output.first, "Error:"
  end

  def test_create_quiet_mode
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Coworker.config["cache_dir"] = cache_dir

      output = capture_io do
        Ace::Coworker::CLI::Commands::Create.new.call(config: config_path, quiet: true)
      end

      assert_empty output.first.strip

      Ace::Coworker.reset_config!
    end
  end
end
