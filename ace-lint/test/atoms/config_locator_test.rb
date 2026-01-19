# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class Ace::Lint::Atoms::ConfigLocatorTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry @tmpdir
  end

  def test_locate_with_explicit_path_existing
    config_path = File.join(@tmpdir, ".rubocop.yml")
    File.write(config_path, "# rubocop config")

    result = Ace::Lint::Atoms::ConfigLocator.locate(
      :rubocop,
      project_root: @tmpdir,
      explicit_path: config_path
    )

    assert_equal :explicit, result[:source]
    assert_equal config_path, result[:path]
    assert result[:exists]
  end

  def test_locate_with_explicit_path_missing
    missing_path = File.join(@tmpdir, "nonexistent.yml")

    result = Ace::Lint::Atoms::ConfigLocator.locate(
      :rubocop,
      project_root: @tmpdir,
      explicit_path: missing_path
    )

    assert_equal :explicit, result[:source]
    assert_equal missing_path, result[:path]
    refute result[:exists]
  end

  def test_locate_finds_ace_config
    ace_config_dir = File.join(@tmpdir, ".ace", "lint")
    FileUtils.mkdir_p(ace_config_dir)
    config_path = File.join(ace_config_dir, ".rubocop.yml")
    File.write(config_path, "# custom config")

    result = Ace::Lint::Atoms::ConfigLocator.locate(:rubocop, project_root: @tmpdir)

    assert_equal :ace_config, result[:source]
    assert_equal config_path, result[:path]
    assert result[:exists]
  end

  def test_locate_finds_native_config
    config_path = File.join(@tmpdir, ".rubocop.yml")
    File.write(config_path, "# native config")

    result = Ace::Lint::Atoms::ConfigLocator.locate(:rubocop, project_root: @tmpdir)

    assert_equal :native, result[:source]
    assert_equal config_path, result[:path]
    assert result[:exists]
  end

  def test_locate_ace_config_takes_precedence_over_native
    # Create both ace and native configs
    ace_config_dir = File.join(@tmpdir, ".ace", "lint")
    FileUtils.mkdir_p(ace_config_dir)
    ace_path = File.join(ace_config_dir, ".rubocop.yml")
    File.write(ace_path, "# ace config")

    native_path = File.join(@tmpdir, ".rubocop.yml")
    File.write(native_path, "# native config")

    result = Ace::Lint::Atoms::ConfigLocator.locate(:rubocop, project_root: @tmpdir)

    assert_equal :ace_config, result[:source]
    assert_equal ace_path, result[:path]
  end

  def test_locate_standardrb_returns_none_by_default
    # StandardRB is zero-config, so no config expected unless user adds one
    result = Ace::Lint::Atoms::ConfigLocator.locate(:standardrb, project_root: @tmpdir)

    # Either :none or :gem_defaults (StandardRB has no gem defaults)
    assert_includes [:none, :gem_defaults], result[:source]
  end

  def test_locate_with_relative_explicit_path
    config_path = File.join(@tmpdir, "config", "rubocop.yml")
    FileUtils.mkdir_p(File.dirname(config_path))
    File.write(config_path, "# config")

    result = Ace::Lint::Atoms::ConfigLocator.locate(
      :rubocop,
      project_root: @tmpdir,
      explicit_path: "config/rubocop.yml"
    )

    assert_equal :explicit, result[:source]
    assert_equal config_path, result[:path]
    assert result[:exists]
  end

  def test_resolve_path_handles_absolute
    absolute = "/absolute/path/config.yml"
    result = Ace::Lint::Atoms::ConfigLocator.resolve_path(absolute, @tmpdir)
    assert_equal absolute, result
  end

  def test_resolve_path_handles_relative
    result = Ace::Lint::Atoms::ConfigLocator.resolve_path("relative/config.yml", @tmpdir)
    assert_equal File.join(@tmpdir, "relative/config.yml"), result
  end
end
