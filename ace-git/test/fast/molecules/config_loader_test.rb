# frozen_string_literal: true

require "test_helper"

class ConfigLoaderTest < AceGitTestCase
  def test_extract_diff_config_handles_diff_namespace
    config = {
      "diff" => {
        "exclude_patterns" => ["*.log"],
        "exclude_whitespace" => false
      }
    }

    result = Ace::Git::Molecules::ConfigLoader.extract_diff_config(config)

    assert_equal ["*.log"], result["exclude_patterns"]
    assert_equal false, result["exclude_whitespace"]
  end

  def test_extract_diff_config_handles_symbol_keys
    config = {
      diff: {
        exclude_patterns: ["*.log"]
      }
    }

    result = Ace::Git::Molecules::ConfigLoader.extract_diff_config(config)

    assert_equal ["*.log"], result[:exclude_patterns]
  end

  def test_extract_diff_config_handles_direct_keys
    config = {
      "exclude_patterns" => ["*.log"],
      "exclude_whitespace" => true
    }

    result = Ace::Git::Molecules::ConfigLoader.extract_diff_config(config)

    assert_equal config, result
  end

  def test_extract_diff_config_handles_legacy_diffs_array
    config = {
      "diffs" => ["HEAD~5..HEAD", "origin/main...HEAD"]
    }

    result = Ace::Git::Molecules::ConfigLoader.extract_diff_config(config)

    assert_equal ["HEAD~5..HEAD", "origin/main...HEAD"], result["ranges"]
  end

  def test_extract_diff_config_handles_legacy_filters
    config = {
      "filters" => ["lib/**/*.rb"]
    }

    result = Ace::Git::Molecules::ConfigLoader.extract_diff_config(config)

    assert_equal ["lib/**/*.rb"], result["paths"]
  end

  def test_extract_diff_config_returns_empty_for_unrelated_config
    config = {
      "something_else" => "value",
      "another_key" => 123
    }

    result = Ace::Git::Molecules::ConfigLoader.extract_diff_config(config)

    assert_equal({}, result)
  end

  def test_extract_diff_config_handles_nil
    result = Ace::Git::Molecules::ConfigLoader.extract_diff_config(nil)
    assert_equal({}, result)
  end

  def test_extract_diff_config_handles_empty_hash
    result = Ace::Git::Molecules::ConfigLoader.extract_diff_config({})
    assert_equal({}, result)
  end

  def test_load_uses_extract_diff_config
    # Stub the global config to return a nested diff: config
    nested_config = {
      "diff" => {
        "exclude_patterns" => ["vendor/**/*"],
        "exclude_whitespace" => false
      }
    }

    Ace::Git.stub :config, nested_config do
      config = Ace::Git::Molecules::ConfigLoader.load

      assert_instance_of Ace::Git::Models::DiffConfig, config
      assert_includes config.exclude_patterns, "vendor/**/*"
      assert_equal false, config.exclude_whitespace?
    end
  end

  def test_load_with_instance_config_overrides_global
    global_config = {
      "diff" => {
        "exclude_patterns" => ["vendor/**/*"]
      }
    }

    instance_config = {
      "exclude_patterns" => ["custom/**/*"]
    }

    Ace::Git.stub :config, global_config do
      config = Ace::Git::Molecules::ConfigLoader.load(instance_config)

      assert_includes config.exclude_patterns, "custom/**/*"
      refute_includes config.exclude_patterns, "vendor/**/*"
    end
  end
end
