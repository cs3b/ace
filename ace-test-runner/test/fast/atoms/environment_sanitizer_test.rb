# frozen_string_literal: true

require "test_helper"

class EnvironmentSanitizerTest < Minitest::Test
  def setup
    @policy = Ace::TestRunner::Models::EnvironmentPolicy.new
  end

  def test_poisoned_parent_environment_yields_only_preserved_keys
    parent_env = {
      "PATH" => "/usr/bin:/bin",
      "LANG" => "en_US.UTF-8",
      "TMPDIR" => "/tmp",
      "LAB_SOCKET" => "/tmp/lab.sock",
      "ACE_RUNTIME_ENDPOINT" => "http://10.0.0.1:9999",
      "ANTHROPIC_API_KEY" => "poison",
      "HTTP_PROXY" => "http://10.0.0.1:1",
      "RUBYOPT" => "-rpoison",
      "HOME" => "/Users/someone",
      "XDG_CONFIG_HOME" => "/Users/someone/.config"
    }

    child = Ace::TestRunner::Atoms::EnvironmentSanitizer.sanitize(parent_env, @policy)

    assert_equal({"PATH" => "/usr/bin:/bin", "LANG" => "en_US.UTF-8", "TMPDIR" => "/tmp"}, child)
  end

  def test_sanitizer_never_mutates_input_or_global_env
    parent_env = {"PATH" => "/usr/bin", "LAB_SOCKET" => "/tmp/lab.sock"}
    env_snapshot = ENV.to_h

    Ace::TestRunner::Atoms::EnvironmentSanitizer.sanitize(parent_env, @policy)

    assert_equal({"PATH" => "/usr/bin", "LAB_SOCKET" => "/tmp/lab.sock"}, parent_env)
    assert_equal env_snapshot, ENV.to_h
  end

  def test_nil_values_are_dropped
    child = Ace::TestRunner::Atoms::EnvironmentSanitizer.sanitize({"PATH" => nil, "LANG" => "C"}, @policy)

    assert_equal({"LANG" => "C"}, child)
  end

  def test_fixture_home_keys_are_not_copied_pending_replacement
    child = Ace::TestRunner::Atoms::EnvironmentSanitizer.sanitize(
      {"HOME" => "/Users/someone", "PATH" => "/usr/bin"},
      @policy
    )

    refute child.key?("HOME")
    assert child.key?("PATH")
  end

  def test_dropped_keys_reports_names_only
    dropped = Ace::TestRunner::Atoms::EnvironmentSanitizer.dropped_keys(
      {"PATH" => "/usr/bin", "LAB_SOCKET" => "/tmp/lab.sock"},
      @policy
    )

    assert_equal %w[LAB_SOCKET], dropped
  end
end
