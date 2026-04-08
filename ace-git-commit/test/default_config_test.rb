# frozen_string_literal: true

require_relative "test_helper"
require "yaml"

class GitCommitDefaultConfigTest < TestCase
  def test_packaged_defaults_make_auto_split_explicit
    defaults_path = File.expand_path("../.ace-defaults/git/commit.yml", __dir__)
    config = YAML.safe_load_file(defaults_path)

    assert_equal true, config.dig("git", "split", "enabled")
    assert_equal "config-scope", config.dig("git", "split", "strategy")
    assert_match(/--no-split/, config.dig("git", "split", "description"))
  end
end
