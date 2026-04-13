# frozen_string_literal: true

require "test_helper"
require "yaml"

class TestEnvironmentTest < Minitest::Test
  def setup
    @env = Ace::TestSupport::TestEnvironment.new("test-gem")
    @original_home = ENV["HOME"]
    @original_config_path = ENV["ACE_CONFIG_PATH"]
    @original_pwd = Dir.pwd
  end

  def teardown
    # Ensure cleanup even if tests fail
    @env.teardown if @env
    ENV["HOME"] = @original_home
    ENV["ACE_CONFIG_PATH"] = @original_config_path
    Dir.chdir(@original_pwd) if @original_pwd && Dir.exist?(@original_pwd)
  end

  def test_initialize_sets_gem_name
    env = Ace::TestSupport::TestEnvironment.new("custom-gem")
    assert_equal "custom-gem", env.instance_variable_get(:@gem_name)
  end

  def test_setup_creates_directory_structure
    @env.setup

    assert Dir.exist?(@env.temp_dir), "Temp directory should exist"
    assert Dir.exist?(@env.home_dir), "Home directory should exist"
    assert Dir.exist?(@env.project_dir), "Project directory should exist"
    assert Dir.exist?(@env.gem_dir), "Gem directory should exist"
  end

  def test_setup_changes_environment_variables
    @env.setup

    assert_equal @env.home_dir, ENV["HOME"], "HOME should be set to test home"
    assert_nil ENV["ACE_CONFIG_PATH"], "ACE_CONFIG_PATH should be cleared"
    assert_equal File.realpath(@env.project_dir), File.realpath(Dir.pwd), "Should change to project directory"
  end

  def test_teardown_restores_environment
    @env.setup
    test_dir = @env.temp_dir

    @env.teardown

    assert_equal @original_home, ENV["HOME"], "HOME should be restored"
    assert_equal @original_config_path, ENV["ACE_CONFIG_PATH"], "ACE_CONFIG_PATH should be restored"
    assert_equal @original_pwd, Dir.pwd, "Working directory should be restored"
    refute Dir.exist?(test_dir), "Temp directory should be cleaned up"
  end

  def test_create_project_config_dir
    @env.setup
    config_dir = @env.create_project_config_dir

    assert Dir.exist?(config_dir)
    assert config_dir.include?(".ace/test-gem")
    assert config_dir.start_with?(@env.project_dir)
  end

  def test_create_home_config_dir
    @env.setup
    config_dir = @env.create_home_config_dir

    assert Dir.exist?(config_dir)
    assert config_dir.include?(".ace/test-gem")
    assert config_dir.start_with?(@env.home_dir)
  end

  def test_create_gem_config_dir
    @env.setup
    config_dir = @env.create_gem_config_dir

    assert Dir.exist?(config_dir)
    assert config_dir.include?("config/ace/test-gem")
    assert config_dir.start_with?(@env.gem_dir)
  end

  def test_create_config_dirs_creates_all_directories
    @env.setup
    @env.create_config_dirs

    assert Dir.exist?(File.join(@env.project_dir, ".ace", "test-gem"))
    assert Dir.exist?(File.join(@env.home_dir, ".ace", "test-gem"))
    assert Dir.exist?(File.join(@env.gem_dir, "config", "ace", "test-gem"))
  end

  def test_write_config_to_project_location
    @env.setup
    content = {"test" => "data"}.to_yaml
    path = @env.write_config(:project, "config.yml", content)

    assert File.exist?(path)
    assert_equal content, File.read(path)
    assert path.start_with?(@env.project_dir)
  end

  def test_write_config_to_home_location
    @env.setup
    content = {"home" => "config"}.to_yaml
    path = @env.write_config(:home, "settings.yml", content)

    assert File.exist?(path)
    assert_equal content, File.read(path)
    assert path.start_with?(@env.home_dir)
  end

  def test_write_config_to_gem_location
    @env.setup
    content = {"gem" => "defaults"}.to_yaml
    path = @env.write_config(:gem, "defaults.yml", content)

    assert File.exist?(path)
    assert_equal content, File.read(path)
    assert path.start_with?(@env.gem_dir)
  end

  def test_write_config_raises_on_invalid_type
    @env.setup

    assert_raises(ArgumentError, "Unknown config type") do
      @env.write_config(:invalid, "file.yml", "content")
    end
  end

  def test_write_env_file_creates_env_file
    @env.setup
    content = "TEST_VAR=value\nANOTHER_VAR=data"
    path = @env.write_env_file(".env", content)

    assert File.exist?(path)
    assert_equal content, File.read(path)
    assert_equal File.join(@env.project_dir, ".env"), path
  end

  def test_write_env_file_with_custom_name
    @env.setup
    path = @env.write_env_file(".env.test", "TEST=1")

    assert File.exist?(path)
    assert File.exist?(File.join(@env.project_dir, ".env.test"))
  end

  def test_create_subdirectory
    @env.setup
    subdir = @env.create_subdirectory("nested/deep/dir")

    assert Dir.exist?(subdir)
    assert subdir.start_with?(@env.project_dir)
    assert Dir.exist?(File.join(@env.project_dir, "nested", "deep", "dir"))
  end

  def test_chdir_to_subdirectory
    @env.setup
    @env.create_subdirectory("subdir")
    @env.chdir("subdir")

    assert_equal File.realpath(File.join(@env.project_dir, "subdir")), File.realpath(Dir.pwd)
  end

  def test_chdir_without_argument_returns_to_project_dir
    @env.setup
    @env.create_subdirectory("subdir")
    @env.chdir("subdir")
    assert Dir.pwd.end_with?("subdir")

    @env.chdir
    assert_equal File.realpath(@env.project_dir), File.realpath(Dir.pwd)
  end

  def test_config_path_returns_correct_paths
    @env.setup

    project_path = @env.config_path(:project)
    assert_equal File.join(@env.project_dir, ".ace", "test-gem"), project_path

    home_path = @env.config_path(:home)
    assert_equal File.join(@env.home_dir, ".ace", "test-gem"), home_path

    gem_path = @env.config_path(:gem)
    assert_equal File.join(@env.gem_dir, "config", "ace", "test-gem"), gem_path
  end

  def test_config_path_raises_on_invalid_type
    @env.setup

    assert_raises(ArgumentError, "Unknown config type") do
      @env.config_path(:invalid)
    end
  end

  def test_verify_structure_reports_directory_existence
    @env.setup
    structure = @env.verify_structure

    assert structure[:temp], "Temp dir should exist"
    assert structure[:home], "Home dir should exist"
    assert structure[:project], "Project dir should exist"
    assert structure[:gem], "Gem dir should exist"
  end

  def test_verify_structure_before_setup
    structure = @env.verify_structure

    refute structure[:temp], "Temp dir should not exist before setup"
    refute structure[:home], "Home dir should not exist before setup"
    refute structure[:project], "Project dir should not exist before setup"
    refute structure[:gem], "Gem dir should not exist before setup"
  end

  def test_create_sample_file
    @env.setup
    file_path = @env.create_sample_file("test/sample.txt", "Sample content")

    assert File.exist?(file_path)
    assert_equal "Sample content", File.read(file_path)
    assert_equal File.join(@env.project_dir, "test", "sample.txt"), file_path
  end

  def test_create_sample_file_with_nested_path
    @env.setup
    file_path = @env.create_sample_file("deeply/nested/file.rb", "class Test; end")

    assert File.exist?(file_path)
    assert Dir.exist?(File.join(@env.project_dir, "deeply", "nested"))
  end

  def test_multiple_setups_and_teardowns
    env1 = Ace::TestSupport::TestEnvironment.new("gem1")
    env2 = Ace::TestSupport::TestEnvironment.new("gem2")

    env1.setup
    env2.setup

    assert Dir.exist?(env1.temp_dir)
    assert Dir.exist?(env2.temp_dir)
    refute_equal env1.temp_dir, env2.temp_dir

    env1.teardown
    refute Dir.exist?(env1.temp_dir)
    assert Dir.exist?(env2.temp_dir)

    env2.teardown
    refute Dir.exist?(env2.temp_dir)
  end
end
