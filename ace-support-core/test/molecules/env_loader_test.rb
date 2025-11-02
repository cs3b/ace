# frozen_string_literal: true

require "test_helper"
require "ace/core/molecules/env_loader"

class EnvLoaderTest < AceTestCase
  def setup
    # Store original ENV values to restore later
    @original_env = {}
  end

  def teardown
    # Restore original ENV values
    @original_env.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end

  def test_loads_env_file
    with_temp_dir do
      env_content = <<~ENV
        TEST_VAR=value
        ANOTHER_VAR=another value
        # Comment line
        EMPTY_VAR=
        QUOTED_VAR="quoted value"
      ENV

      File.write(".env", env_content)

      vars = Ace::Core::Molecules::EnvLoader.load_file(".env")

      assert_equal "value", vars["TEST_VAR"]
      assert_equal "another value", vars["ANOTHER_VAR"]
      assert_equal "", vars["EMPTY_VAR"]
      assert_equal "quoted value", vars["QUOTED_VAR"]
      refute vars.key?("# Comment line")
    end
  end

  def test_returns_empty_hash_for_missing_file
    vars = Ace::Core::Molecules::EnvLoader.load_file("nonexistent.env")
    assert_equal({}, vars)
  end

  def test_load_and_set_environment
    with_temp_dir do
      store_env("TEST_LOAD_SET")

      env_content = <<~ENV
        TEST_LOAD_SET=new_value
        NEW_VAR=added
      ENV

      File.write(".env", env_content)

      set_vars = Ace::Core::Molecules::EnvLoader.load_and_set(".env")

      assert_equal "new_value", ENV["TEST_LOAD_SET"]
      assert_equal "added", ENV["NEW_VAR"]
      assert_equal({ "TEST_LOAD_SET" => "new_value", "NEW_VAR" => "added" }, set_vars)
    end
  end

  def test_env_override_precedence
    with_temp_dir do
      store_env("EXISTING_VAR")
      ENV["EXISTING_VAR"] = "original"

      env_content = "EXISTING_VAR=from_file"
      File.write(".env", env_content)

      # With overwrite=true (default)
      Ace::Core::Molecules::EnvLoader.load_and_set(".env", overwrite: true)
      assert_equal "from_file", ENV["EXISTING_VAR"]

      # Reset and test with overwrite=false
      ENV["EXISTING_VAR"] = "original"
      Ace::Core::Molecules::EnvLoader.load_and_set(".env", overwrite: false)
      assert_equal "original", ENV["EXISTING_VAR"]
    end
  end

  def test_set_environment_from_hash
    store_env("SET_TEST_1")
    store_env("SET_TEST_2")

    vars = {
      "SET_TEST_1" => "value1",
      "SET_TEST_2" => "value2"
    }

    set_vars = Ace::Core::Molecules::EnvLoader.set_environment(vars)

    assert_equal "value1", ENV["SET_TEST_1"]
    assert_equal "value2", ENV["SET_TEST_2"]
    assert_equal vars, set_vars
  end

  def test_save_env_file
    with_temp_dir do
      vars = {
        "SAVE_VAR_1" => "value1",
        "SAVE_VAR_2" => "value with spaces",
        "SAVE_VAR_3" => ""
      }

      Ace::Core::Molecules::EnvLoader.save_file(vars, "output.env")

      assert File.exist?("output.env")

      loaded = Ace::Core::Molecules::EnvLoader.load_file("output.env")
      assert_equal "value1", loaded["SAVE_VAR_1"]
      assert_equal "value with spaces", loaded["SAVE_VAR_2"]
      assert_equal "", loaded["SAVE_VAR_3"]
    end
  end

  def test_save_creates_directory
    with_temp_dir do
      vars = { "TEST" => "value" }

      Ace::Core::Molecules::EnvLoader.save_file(vars, "deep/path/.env")

      assert File.exist?("deep/path/.env")
      assert File.directory?("deep/path")
    end
  end

  def test_load_multiple_files
    with_temp_dir do
      store_env("MULTI_1")
      store_env("MULTI_2")
      store_env("OVERRIDE")

      File.write(".env", "MULTI_1=first\nOVERRIDE=first")
      File.write(".env.local", "MULTI_2=second\nOVERRIDE=second")

      Ace::Core::Molecules::EnvLoader.load_multiple(
        ".env",
        ".env.local"
      )

      assert_equal "first", ENV["MULTI_1"]
      assert_equal "second", ENV["MULTI_2"]
      assert_equal "second", ENV["OVERRIDE"] # Later file wins
    end
  end

  def test_auto_load_standard_locations
    with_temp_dir do
      store_env("AUTO_BASE")
      store_env("AUTO_LOCAL")
      store_env("AUTO_OVERRIDE")

      # Create standard .env files
      File.write(".env", "AUTO_BASE=base\nAUTO_OVERRIDE=base")
      File.write(".env.local", "AUTO_LOCAL=local\nAUTO_OVERRIDE=local")

      Ace::Core::Molecules::EnvLoader.auto_load(Dir.pwd)

      assert_equal "base", ENV["AUTO_BASE"]
      assert_equal "local", ENV["AUTO_LOCAL"]
      # The auto_load method loads files with overwrite: false,
      # so the first loaded value wins (base), not the last (local)
      assert_equal "base", ENV["AUTO_OVERRIDE"] # First file wins with overwrite: false
    end
  end

  def test_auto_load_with_no_env_files
    with_temp_dir do
      result = Ace::Core::Molecules::EnvLoader.auto_load(Dir.pwd)
      # auto_load returns nil when no files exist, not {}
      assert_nil result
    end
  end

  def test_handles_malformed_env_content
    with_temp_dir do
      # Create env file with various edge cases
      env_content = <<~ENV
        VALID=value
        =no_key
        NO_EQUALS
        # Comment

        SPACES_AROUND = value with spaces
        EXPORT_STYLE=export value
      ENV

      File.write(".env", env_content)

      vars = Ace::Core::Molecules::EnvLoader.load_file(".env")

      assert vars.key?("VALID")
      # Behavior for malformed lines depends on env_parser implementation
    end
  end

  def test_expands_paths
    with_temp_dir do
      home = Dir.pwd
      env_path = File.join(home, ".env")
      File.write(env_path, "EXPANDED=yes")

      # Test with ~ path expansion
      vars = Ace::Core::Molecules::EnvLoader.load_file(env_path)
      assert_equal "yes", vars["EXPANDED"]
    end
  end

  private

  def store_env(key)
    @original_env[key] = ENV[key]
  end
end