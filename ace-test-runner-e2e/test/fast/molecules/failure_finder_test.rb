# frozen_string_literal: true

require_relative "../../test_helper"
require "yaml"

class FailureFinderTest < Minitest::Test
  def setup
    @finder = Ace::Test::EndToEndRunner::Molecules::FailureFinder.new
  end

  def test_find_failures_with_no_cache_directory
    Dir.mktmpdir do |tmpdir|
      result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_empty result, "Should return empty array when no cache exists"
    end
  end

  def test_find_failures_with_empty_cache_directory
    Dir.mktmpdir do |tmpdir|
      FileUtils.mkdir_p(File.join(tmpdir, ".ace-local", "test-e2e"))
      result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_empty result, "Should return empty array when cache is empty"
    end
  end

  def test_find_failures_with_passing_tests_only
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "pass",
        "results" => {"passed" => 3, "failed" => 0, "total" => 3},
        "failed_test_cases" => []
      })

      result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_empty result, "Should return empty array when no failures exist"
    end
  end

  def test_find_failures_with_failed_test_cases
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "results" => {"passed" => 2, "failed" => 1, "total" => 3},
        "failed_test_cases" => ["TC-003"]
      })

      result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_equal ["TC-003"], result
    end
  end

  def test_find_failures_with_multiple_failed_test_cases
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "results" => {"passed" => 1, "failed" => 2, "total" => 3},
        "failed_test_cases" => ["TC-001", "TC-003"]
      })

      result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_equal ["TC-001", "TC-003"], result
    end
  end

  def test_find_failures_filters_by_package
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      })
      create_metadata(tmpdir, "8p0002-secrets-ts001-reports", {
        "test-id" => "TS-SECRETS-001",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => ["TC-002"]
      })

      lint_result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_equal ["TC-001"], lint_result

      secrets_result = @finder.find_failures(package: "ace-git-secrets", base_dir: tmpdir)
      assert_equal ["TC-002"], secrets_result
    end
  end

  def test_find_failures_uses_most_recent_per_test_id
    Dir.mktmpdir do |tmpdir|
      # Older run with failures
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001", "TC-002"]
      })
      # More recent run where TC-001 was fixed
      create_metadata(tmpdir, "8p0099-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-002"]
      })

      result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_equal ["TC-002"], result, "Should use most recent run per test-id"
    end
  end

  def test_find_failures_aggregates_across_test_ids
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      })
      create_metadata(tmpdir, "8p0002-lint-mt002-reports", {
        "test-id" => "TS-LINT-002",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-003"]
      })

      result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_includes result, "TC-001"
      assert_includes result, "TC-003"
      assert_equal 2, result.size
    end
  end

  def test_find_failures_deduplicates_ids
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001", "TC-002"]
      })
      create_metadata(tmpdir, "8p0002-lint-mt002-reports", {
        "test-id" => "TS-LINT-002",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001", "TC-003"]
      })

      result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_equal result, result.uniq, "Should not have duplicate IDs"
      assert_includes result, "TC-001"
      assert_includes result, "TC-002"
      assert_includes result, "TC-003"
    end
  end

  def test_find_failures_returns_wildcard_for_legacy_metadata_without_failed_test_cases
    Dir.mktmpdir do |tmpdir|
      # Legacy metadata format without failed_test_cases key but with fail status
      create_metadata(tmpdir, "8p0001-secrets-mt002-reports", {
        "test-id" => "TS-SECRETS-002",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "results" => {"passed" => 5, "failed" => 6, "total" => 11}
      })

      result = @finder.find_failures(package: "ace-git-secrets", base_dir: tmpdir)
      assert_equal ["*"], result, "Should return wildcard when status is fail but no failed_test_cases"
    end
  end

  def test_find_failures_returns_wildcard_for_partial_status_without_failed_test_cases
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-secrets-mt002-reports", {
        "test-id" => "TS-SECRETS-002",
        "package" => "ace-git-secrets",
        "status" => "partial",
        "results" => {"passed" => 5, "failed" => 6, "total" => 11}
      })

      result = @finder.find_failures(package: "ace-git-secrets", base_dir: tmpdir)
      assert_equal ["*"], result, "Should return wildcard when status is partial but no failed_test_cases"
    end
  end

  def test_find_failures_returns_wildcard_for_error_status_without_failed_test_cases
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-secrets-mt002-reports", {
        "test-id" => "TS-SECRETS-002",
        "package" => "ace-git-secrets",
        "status" => "error",
        "results" => {"passed" => 0, "failed" => 0, "total" => 0}
      })

      result = @finder.find_failures(package: "ace-git-secrets", base_dir: tmpdir)
      assert_equal ["*"], result, "Should return wildcard when status is error but no failed_test_cases"
    end
  end

  def test_find_failures_returns_wildcard_for_incomplete_status_without_failed_test_cases
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-secrets-mt002-reports", {
        "test-id" => "TS-SECRETS-002",
        "package" => "ace-git-secrets",
        "status" => "incomplete",
        "results" => {"passed" => 0, "failed" => 0, "total" => 0}
      })

      result = @finder.find_failures(package: "ace-git-secrets", base_dir: tmpdir)
      assert_equal ["*"], result, "Should return wildcard when status is incomplete but no failed_test_cases"
    end
  end

  def test_find_failures_returns_empty_for_pass_status_without_failed_test_cases
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-secrets-mt002-reports", {
        "test-id" => "TS-SECRETS-002",
        "package" => "ace-git-secrets",
        "status" => "pass",
        "results" => {"passed" => 11, "failed" => 0, "total" => 11}
      })

      result = @finder.find_failures(package: "ace-git-secrets", base_dir: tmpdir)
      assert_empty result, "Should return empty when status is pass and no failed_test_cases"
    end
  end

  def test_find_failures_returns_wildcard_for_empty_failed_test_cases_with_fail_status
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-secrets-mt002-reports", {
        "test-id" => "TS-SECRETS-002",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => [],
        "results" => {"passed" => 5, "failed" => 6, "total" => 11}
      })

      result = @finder.find_failures(package: "ace-git-secrets", base_dir: tmpdir)
      assert_equal ["*"], result, "Should return wildcard when failed_test_cases is empty but status is fail"
    end
  end

  def test_find_failures_skips_malformed_yaml
    Dir.mktmpdir do |tmpdir|
      cache_dir = File.join(tmpdir, ".ace-local", "test-e2e", "8p0001-lint-ts001-reports")
      FileUtils.mkdir_p(cache_dir)
      File.write(File.join(cache_dir, "metadata.yml"), "not: valid: yaml: [}")

      result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_empty result, "Should gracefully skip malformed YAML files"
    end
  end

  def test_find_failures_most_recent_pass_clears_failures
    Dir.mktmpdir do |tmpdir|
      # Earlier run failed
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      })
      # Later run passed (no failures)
      create_metadata(tmpdir, "8p0099-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "pass",
        "failed_test_cases" => []
      })

      result = @finder.find_failures(package: "ace-lint", base_dir: tmpdir)
      assert_empty result, "Most recent passing run should clear previous failures"
    end
  end

  def test_find_all_failures
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      })
      create_metadata(tmpdir, "8p0002-secrets-ts001-reports", {
        "test-id" => "TS-SECRETS-001",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => ["TC-002"]
      })

      result = @finder.find_all_failures(base_dir: tmpdir)
      assert_includes result, "TC-001"
      assert_includes result, "TC-002"
      assert_equal 2, result.size
    end
  end

  def test_find_all_failures_with_no_cache
    Dir.mktmpdir do |tmpdir|
      result = @finder.find_all_failures(base_dir: tmpdir)
      assert_empty result
    end
  end

  # --- find_failures_by_package tests ---

  def test_find_failures_by_package_returns_grouped_failures
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      })
      create_metadata(tmpdir, "8p0002-secrets-ts001-reports", {
        "test-id" => "TS-SECRETS-001",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => ["TC-002", "TC-003"]
      })

      result = @finder.find_failures_by_package(
        packages: ["ace-lint", "ace-git-secrets"],
        base_dir: tmpdir
      )

      assert_equal 2, result.size
      assert_equal ["TC-001"], result["ace-lint"]
      assert_equal ["TC-002", "TC-003"], result["ace-git-secrets"]
    end
  end

  def test_find_failures_by_package_omits_packages_with_no_failures
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      })
      create_metadata(tmpdir, "8p0002-review-ts001-reports", {
        "test-id" => "TS-REVIEW-001",
        "package" => "ace-review",
        "status" => "pass",
        "failed_test_cases" => []
      })

      result = @finder.find_failures_by_package(
        packages: ["ace-lint", "ace-review"],
        base_dir: tmpdir
      )

      assert_equal 1, result.size
      assert_includes result.keys, "ace-lint"
      refute_includes result.keys, "ace-review"
    end
  end

  def test_find_failures_by_package_with_no_cache
    Dir.mktmpdir do |tmpdir|
      result = @finder.find_failures_by_package(
        packages: ["ace-lint"],
        base_dir: tmpdir
      )
      assert_empty result
    end
  end

  def test_find_failures_by_package_only_scans_requested_packages
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      })
      create_metadata(tmpdir, "8p0002-secrets-ts001-reports", {
        "test-id" => "TS-SECRETS-001",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => ["TC-002"]
      })

      # Only request ace-lint, ace-git-secrets should not appear
      result = @finder.find_failures_by_package(
        packages: ["ace-lint"],
        base_dir: tmpdir
      )

      assert_equal 1, result.size
      assert_includes result.keys, "ace-lint"
      refute_includes result.keys, "ace-git-secrets"
    end
  end

  def test_find_failures_by_package_uses_most_recent_per_test
    Dir.mktmpdir do |tmpdir|
      # Older run with failures
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001", "TC-002"]
      })
      # Newer run where TC-001 was fixed
      create_metadata(tmpdir, "8p0099-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-002"]
      })

      result = @finder.find_failures_by_package(
        packages: ["ace-lint"],
        base_dir: tmpdir
      )

      assert_equal ["TC-002"], result["ace-lint"]
    end
  end

  # --- find_failures_by_scenario tests ---

  def test_find_failures_by_scenario_returns_per_scenario_data
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-secrets-ts001-reports", {
        "test-id" => "TS-SECRETS-001",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      })
      create_metadata(tmpdir, "8p0002-secrets-mt002-reports", {
        "test-id" => "TS-SECRETS-002",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => ["TC-002", "TC-003"]
      })

      result = @finder.find_failures_by_scenario(
        packages: ["ace-git-secrets"],
        base_dir: tmpdir
      )

      assert_equal 1, result.size
      assert_includes result.keys, "ace-git-secrets"
      scenarios = result["ace-git-secrets"]
      assert_equal 2, scenarios.size
      assert_equal ["TC-001"], scenarios["TS-SECRETS-001"]
      assert_equal ["TC-002", "TC-003"], scenarios["TS-SECRETS-002"]
    end
  end

  def test_find_failures_by_scenario_omits_passing_scenarios
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-secrets-ts001-reports", {
        "test-id" => "TS-SECRETS-001",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      })
      create_metadata(tmpdir, "8p0002-secrets-mt002-reports", {
        "test-id" => "TS-SECRETS-002",
        "package" => "ace-git-secrets",
        "status" => "pass",
        "failed_test_cases" => []
      })
      create_metadata(tmpdir, "8p0003-secrets-mt003-reports", {
        "test-id" => "TS-SECRETS-003",
        "package" => "ace-git-secrets",
        "status" => "pass",
        "failed_test_cases" => []
      })

      result = @finder.find_failures_by_scenario(
        packages: ["ace-git-secrets"],
        base_dir: tmpdir
      )

      scenarios = result["ace-git-secrets"]
      assert_equal 1, scenarios.size
      assert_includes scenarios.keys, "TS-SECRETS-001"
      refute_includes scenarios.keys, "TS-SECRETS-002"
      refute_includes scenarios.keys, "TS-SECRETS-003"
    end
  end

  def test_find_failures_by_scenario_wildcard_handling
    Dir.mktmpdir do |tmpdir|
      # Legacy metadata with fail status but no failed_test_cases
      create_metadata(tmpdir, "8p0001-secrets-ts001-reports", {
        "test-id" => "TS-SECRETS-001",
        "package" => "ace-git-secrets",
        "status" => "fail"
      })

      result = @finder.find_failures_by_scenario(
        packages: ["ace-git-secrets"],
        base_dir: tmpdir
      )

      scenarios = result["ace-git-secrets"]
      assert_equal ["*"], scenarios["TS-SECRETS-001"]
    end
  end

  def test_find_failures_by_scenario_uses_most_recent_per_test
    Dir.mktmpdir do |tmpdir|
      # Older run: TS-SECRETS-001 fails TC-001, TC-002
      create_metadata(tmpdir, "8p0001-secrets-ts001-reports", {
        "test-id" => "TS-SECRETS-001",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => ["TC-001", "TC-002"]
      })
      # Newer run: TS-SECRETS-001 now only fails TC-002
      create_metadata(tmpdir, "8p0099-secrets-ts001-reports", {
        "test-id" => "TS-SECRETS-001",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => ["TC-002"]
      })

      result = @finder.find_failures_by_scenario(
        packages: ["ace-git-secrets"],
        base_dir: tmpdir
      )

      assert_equal ["TC-002"], result["ace-git-secrets"]["TS-SECRETS-001"]
    end
  end

  def test_find_failures_by_scenario_with_no_cache
    Dir.mktmpdir do |tmpdir|
      result = @finder.find_failures_by_scenario(
        packages: ["ace-git-secrets"],
        base_dir: tmpdir
      )
      assert_empty result
    end
  end

  def test_find_failures_by_scenario_multiple_packages
    Dir.mktmpdir do |tmpdir|
      create_metadata(tmpdir, "8p0001-lint-ts001-reports", {
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      })
      create_metadata(tmpdir, "8p0002-secrets-ts001-reports", {
        "test-id" => "TS-SECRETS-001",
        "package" => "ace-git-secrets",
        "status" => "fail",
        "failed_test_cases" => ["TC-002"]
      })
      # ace-review passes, should not appear
      create_metadata(tmpdir, "8p0003-review-ts001-reports", {
        "test-id" => "TS-REVIEW-001",
        "package" => "ace-review",
        "status" => "pass",
        "failed_test_cases" => []
      })

      result = @finder.find_failures_by_scenario(
        packages: ["ace-lint", "ace-git-secrets", "ace-review"],
        base_dir: tmpdir
      )

      assert_equal 2, result.size
      assert_equal({"TS-LINT-001" => ["TC-001"]}, result["ace-lint"])
      assert_equal({"TS-SECRETS-001" => ["TC-002"]}, result["ace-git-secrets"])
      refute_includes result.keys, "ace-review"
    end
  end

  private

  # Helper to create a metadata.yml file in a report directory
  def create_metadata(base_dir, dir_name, data)
    report_dir = File.join(base_dir, ".ace-local", "test-e2e", dir_name)
    FileUtils.mkdir_p(report_dir)
    File.write(File.join(report_dir, "metadata.yml"), YAML.dump(data))
  end
end
