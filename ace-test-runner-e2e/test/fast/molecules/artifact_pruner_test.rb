# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"

class ArtifactPrunerTest < Minitest::Test
  ArtifactPruner = Ace::Test::EndToEndRunner::Molecules::ArtifactPruner

  def test_prune_is_noop_when_root_is_missing
    Dir.mktmpdir do |tmpdir|
      result = ArtifactPruner.new.prune(base_dir: tmpdir)

      assert_equal 0, result[:deleted_count]
      assert_equal File.join(File.expand_path(tmpdir), ".ace-local", "test-e2e"), result[:root]
    end
  end

  def test_prune_preserves_runtime_cache_and_suite_reports_only
    Dir.mktmpdir do |tmpdir|
      root = File.join(tmpdir, ".ace-local", "test-e2e")
      FileUtils.mkdir_p(root)

      keep_runtime_cache = File.join(root, "runtime-cache")
      keep_suite_report = File.join(root, "8abc123-suite-report.md")
      keep_suite_final = File.join(root, "8abc124-suite-final-report.md")
      remove_package_report = File.join(root, "8abc125-ace-lint-report.md")
      remove_preflight = File.join(root, "8abc126-ace-lint-preflight")
      remove_reports = File.join(root, "8abc127-lint-ts001-reports")
      remove_support = File.join(root, "8abc127-lint-ts001.support")
      remove_misc = File.join(root, "leftover-dir")

      FileUtils.mkdir_p(keep_runtime_cache)
      FileUtils.mkdir_p(remove_preflight)
      FileUtils.mkdir_p(remove_reports)
      FileUtils.mkdir_p(remove_support)
      FileUtils.mkdir_p(remove_misc)
      File.write(keep_suite_report, "# suite\n")
      File.write(keep_suite_final, "# suite final\n")
      File.write(remove_package_report, "# package\n")

      result = ArtifactPruner.new.prune(base_dir: tmpdir)

      assert_equal 5, result[:deleted_count]
      assert Dir.exist?(keep_runtime_cache)
      assert File.exist?(keep_suite_report)
      assert File.exist?(keep_suite_final)
      refute File.exist?(remove_package_report)
      refute Dir.exist?(remove_preflight)
      refute Dir.exist?(remove_reports)
      refute Dir.exist?(remove_support)
      refute Dir.exist?(remove_misc)
    end
  end
end
