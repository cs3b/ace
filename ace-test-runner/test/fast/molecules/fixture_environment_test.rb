# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class FixtureEnvironmentTest < Minitest::Test
  def setup
    @policy = Ace::TestRunner::Models::EnvironmentPolicy.from_config(
      "overrides" => {"PROBE_ENDPOINT" => "http://127.0.0.1:1"},
      "require" => ["PROBE_ENDPOINT"]
    )
    @parent_env = {
      "PATH" => "/usr/bin:/bin",
      "TMPDIR" => "/tmp",
      "HOME" => "/Users/someone",
      "LAB_SOCKET" => "/tmp/lab.sock",
      "ACE_RUNTIME_ENDPOINT" => "http://10.0.0.1:9999",
      "ANTHROPIC_API_KEY" => "poison"
    }
  end

  def teardown
    @fixture&.cleanup
  end

  def test_build_creates_fixture_home_and_xdg_directories_inside_owned_root
    @fixture = build_fixture

    assert Dir.exist?(@fixture.root)
    assert Dir.exist?(File.join(@fixture.root, "home"))
    assert Dir.exist?(File.join(@fixture.root, "home", ".config"))
    assert Dir.exist?(File.join(@fixture.root, "home", ".cache"))
    assert Dir.exist?(File.join(@fixture.root, "home", ".local", "share"))
  end

  def test_launch_environment_replaces_home_and_xdg_with_fixture_paths
    @fixture = build_fixture

    assert_equal File.join(@fixture.root, "home"), @fixture.env["HOME"]
    assert_equal File.join(@fixture.root, "home", ".config"), @fixture.env["XDG_CONFIG_HOME"]
    assert_equal File.join(@fixture.root, "home", ".cache"), @fixture.env["XDG_CACHE_HOME"]
    assert_equal File.join(@fixture.root, "home", ".local", "share"), @fixture.env["XDG_DATA_HOME"]
  end

  def test_launch_environment_excludes_ambient_configuration_and_keeps_allowlist
    @fixture = build_fixture

    refute @fixture.env.key?("LAB_SOCKET")
    refute @fixture.env.key?("ACE_RUNTIME_ENDPOINT")
    refute @fixture.env.key?("ANTHROPIC_API_KEY")
    assert_equal "/usr/bin:/bin", @fixture.env["PATH"]
    assert_equal "1", @fixture.env["MT_NO_AUTORUN"]
  end

  def test_fixture_overrides_apply_after_sanitization
    @fixture = build_fixture

    assert_equal "http://127.0.0.1:1", @fixture.env["PROBE_ENDPOINT"]
  end

  def test_missing_required_override_is_a_setup_error_naming_the_key_only
    policy = Ace::TestRunner::Models::EnvironmentPolicy.from_config("require" => ["PROBE_TOKEN"])

    error = assert_raises(Ace::TestRunner::EnvironmentSetupError) do
      Ace::TestRunner::Molecules::FixtureEnvironment.new(policy: policy, parent_env: @parent_env).build
    end

    assert_includes error.message, "PROBE_TOKEN"
    refute_includes error.message, "poison"
  end

  def test_build_and_cleanup_leave_parent_env_and_global_env_unchanged
    env_snapshot = ENV.to_h

    @fixture = build_fixture
    @fixture.cleanup

    assert_equal({"PATH" => "/usr/bin:/bin", "TMPDIR" => "/tmp", "HOME" => "/Users/someone",
      "LAB_SOCKET" => "/tmp/lab.sock", "ACE_RUNTIME_ENDPOINT" => "http://10.0.0.1:9999",
      "ANTHROPIC_API_KEY" => "poison"}, @parent_env)
    assert_equal env_snapshot, ENV.to_h
  end

  def test_cleanup_removes_only_the_owned_root
    @fixture = build_fixture
    root = @fixture.root
    sibling = File.join(File.dirname(root), "sibling-guard")
    FileUtils.mkdir_p(sibling)

    @fixture.cleanup

    refute Dir.exist?(root)
    assert Dir.exist?(sibling)
  ensure
    FileUtils.rm_rf(sibling) if sibling && Dir.exist?(sibling)
  end

  def test_cleanup_is_idempotent
    @fixture = build_fixture
    root = @fixture.root

    @fixture.cleanup
    @fixture.cleanup

    assert_nil @fixture.root
    refute Dir.exist?(root)
  end

  def test_failed_build_cleans_up_the_created_root
    Dir.mktmpdir do |watch_dir|
      before = Dir.children(watch_dir).sort
      policy = Ace::TestRunner::Models::EnvironmentPolicy.from_config("require" => ["MISSING_KEY"])
      fixture = Ace::TestRunner::Molecules::FixtureEnvironment.new(
        policy: policy,
        parent_env: @parent_env,
        root_factory: ->(prefix) { Dir.mktmpdir(prefix, watch_dir) }
      )

      assert_raises(Ace::TestRunner::EnvironmentSetupError) { fixture.build }

      assert_nil fixture.root
      assert_equal before, Dir.children(watch_dir).sort
    end
  end

  private

  def build_fixture
    Ace::TestRunner::Molecules::FixtureEnvironment.new(
      policy: @policy,
      parent_env: @parent_env
    ).build
  end
end
