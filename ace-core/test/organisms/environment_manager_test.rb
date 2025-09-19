# frozen_string_literal: true

require "test_helper"
require "ace/core/organisms/environment_manager"

class EnvironmentManagerTest < Minitest::Test
  def setup
    @original_env = ENV.to_h.dup
  end

  def teardown
    # Restore original environment
    ENV.clear
    @original_env.each { |k, v| ENV[k] = v }
  end

  def test_load_dotenv_files
    with_temp_dir do |dir|
      # Create .env file
      File.write(".env", "TEST_VAR=value\nANOTHER_VAR=123")

      # Create config that enables dotenv
      config_data = {
        "ace" => {
          "environment" => {
            "load_dotenv" => true,
            "dotenv_files" => [".env"]
          }
        }
      }
      create_config_file(".ace/config.yml", config_data.to_yaml)

      manager = Ace::Core::Organisms::EnvironmentManager.new(root_path: dir)
      loaded = manager.load

      assert_equal "value", ENV["TEST_VAR"]
      assert_equal "123", ENV["ANOTHER_VAR"]
      assert_includes loaded.keys, "TEST_VAR"
    end
  end

  def test_save_environment_variables
    with_temp_dir do
      ENV["SAVE_TEST"] = "saved_value"

      manager = Ace::Core::Organisms::EnvironmentManager.new
      manager.save(".env.test", keys: ["SAVE_TEST"])

      assert File.exist?(".env.test")
      content = File.read(".env.test")
      assert_includes content, "SAVE_TEST=saved_value"
    end
  end

  def test_get_and_set_variables
    with_temp_dir do
      manager = Ace::Core::Organisms::EnvironmentManager.new

      manager.set("MANAGER_TEST", "test_value")
      assert_equal "test_value", manager.get("MANAGER_TEST")
      assert manager.key?("MANAGER_TEST")
    end
  end

  def test_list_dotenv_files
    with_temp_dir do |dir|
      # Create config
      config_data = {
        "ace" => {
          "environment" => {
            "dotenv_files" => [".env.local", ".env"]
          }
        }
      }
      create_config_file(".ace/config.yml", config_data.to_yaml)

      # Create one of the files
      File.write(".env", "TEST=1")

      manager = Ace::Core::Organisms::EnvironmentManager.new(root_path: dir)
      files = manager.list_dotenv_files

      assert_equal 1, files.size
      assert files.first.end_with?(".env")
    end
  end

  def test_dotenv_disabled
    with_temp_dir do |dir|
      # Create config that disables dotenv
      config_data = {
        "ace" => {
          "environment" => {
            "load_dotenv" => false
          }
        }
      }
      create_config_file(".ace/config.yml", config_data.to_yaml)

      # Create .env file
      File.write(".env", "SHOULD_NOT_LOAD=true")

      manager = Ace::Core::Organisms::EnvironmentManager.new(root_path: dir)
      loaded = manager.load

      assert_empty loaded
      assert_nil ENV["SHOULD_NOT_LOAD"]
    end
  end
end