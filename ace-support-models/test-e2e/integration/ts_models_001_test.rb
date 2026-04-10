# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"
require "json"
require "time"

class TSMODELS001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @models_exe = File.join(@root, "exe", "ace-models")
    @providers_exe = File.join(@root, "exe", "ace-llm-providers")
  end

  def run_models(*args, chdir:, env: {})
    Open3.capture3(env, @models_exe, *args, chdir: chdir)
  end

  def run_providers(*args, chdir:, env: {})
    Open3.capture3(env, @providers_exe, *args, chdir: chdir)
  end

  def seed_cache(dir)
    cache_dir = File.join(dir, "cache", "ace-models")
    FileUtils.mkdir_p(cache_dir)
    File.write(File.join(cache_dir, "api.json"), JSON.pretty_generate({
      "providers" => {
        "anthropic" => {
          "name" => "Anthropic",
          "models" => {
            "claude-sonnet-4" => {"name" => "Claude Sonnet 4"}
          }
        }
      }
    }))
    File.write(File.join(cache_dir, "metadata.json"), JSON.pretty_generate({"generated_at" => Time.now.utc.iso8601}))
    {"XDG_CACHE_HOME" => File.join(dir, "cache")}
  end

  def test_tc_001_help_surface
    stdout, stderr, status = run_models("--help", chdir: @root)
    assert status.success?, stderr
    assert_match(/ace-models/, stdout + stderr)
    assert_match(/COMMANDS/, stdout + stderr)
    assert_match(/EXAMPLES/, stdout + stderr)

    stdout, stderr, status = run_providers("--help", chdir: @root)
    assert status.success?, stderr
    assert_match(/ace-llm-providers/, stdout + stderr)
    assert_match(/COMMANDS/, stdout + stderr)
    assert_match(/EXAMPLES/, stdout + stderr)
  end

  def test_tc_002_models_cache_clear
    Dir.mktmpdir("ace-models-e2e-") do |dir|
      env = seed_cache(dir)
      cache_file = File.join(dir, "cache", "ace-models", "api.json")

      assert(File.exist?(cache_file))

      stdout, stderr, status = run_models("clear", chdir: dir, env: env)
      assert status.success?, stderr
      assert_match(/Cache cleared successfully/i, stdout + stderr)
      refute(File.exist?(cache_file))
    end
  end

  def test_tc_003_providers_list_show
    Dir.mktmpdir("ace-models-e2e-") do |dir|
      env = seed_cache(dir)

      stdout, stderr, status = run_providers("list", chdir: dir, env: env)
      assert status.success?, stderr
      assert_match(/Providers \(/, stdout)
      assert_match(/anthropic/i, stdout)

      stdout, stderr, status = run_providers("show", "anthropic", chdir: dir, env: env)
      assert status.success?, stderr
      assert_match(/Provider: anthropic/i, stdout)
      assert_match(/claude-sonnet-4/i, stdout)
    end
  end

  def test_tc_004_invalid_filter
    Dir.mktmpdir("ace-models-e2e-") do |dir|
      env = seed_cache(dir)

      stdout, stderr, status = run_models("search", "-f", "badfilter", chdir: dir, env: env)
      refute status.success?
      assert_match(/Invalid filter format/i, stderr)
      assert_match(/Invalid model search filters/i, stderr)
    end
  end
end
