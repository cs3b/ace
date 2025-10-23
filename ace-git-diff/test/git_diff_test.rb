# frozen_string_literal: true

require "test_helper"

class GitDiffTest < AceGitDiffTestCase
  def test_version_defined
    refute_nil Ace::GitDiff::VERSION
    assert_match(/\d+\.\d+\.\d+/, Ace::GitDiff::VERSION)
  end

  def test_config_returns_hash
    assert_instance_of Hash, Ace::GitDiff.config
  end

  def test_default_config_includes_exclude_patterns
    config = Ace::GitDiff.default_config
    assert config.key?("exclude_patterns")
    assert_instance_of Array, config["exclude_patterns"]
    assert config["exclude_patterns"].include?("test/**/*")
  end

  def test_default_config_includes_options
    config = Ace::GitDiff.default_config
    assert config.key?("exclude_whitespace")
    assert config.key?("exclude_renames")
    assert config.key?("exclude_moves")
    assert config.key?("max_lines")
  end
end
