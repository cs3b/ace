# frozen_string_literal: true

require_relative "../test_helper"

class TestDiscovererTest < Minitest::Test
  def setup
    @discoverer = Ace::Test::EndToEndRunner::Molecules::TestDiscoverer.new
    @base_dir = File.expand_path("../../..", __dir__)
  end

  def test_find_tests_for_existing_package
    files = @discoverer.find_tests(package: "ace-lint", base_dir: @base_dir)
    refute_empty files, "Should find E2E tests in ace-lint"
    assert files.all? { |f| f.end_with?("scenario.yml") },
      "All files should be scenario.yml"
  end

  def test_find_tests_for_nonexistent_package
    files = @discoverer.find_tests(package: "ace-nonexistent", base_dir: @base_dir)
    assert_empty files, "Should find no tests for nonexistent package"
  end

  def test_find_specific_test_by_id
    files = @discoverer.find_tests(
      package: "ace-lint",
      test_id: "TS-LINT-001",
      base_dir: @base_dir
    )
    assert_equal 1, files.size, "Should find exactly one test for TS-LINT-001"
    assert files.first.include?("TS-LINT-001"), "File should contain test ID"
  end

  def test_find_specific_test_nonexistent_id
    files = @discoverer.find_tests(
      package: "ace-lint",
      test_id: "TS-LINT-999",
      base_dir: @base_dir
    )
    assert_empty files, "Should find no tests for nonexistent ID"
  end

  def test_find_tests_returns_sorted
    files = @discoverer.find_tests(package: "ace-lint", base_dir: @base_dir)
    assert_equal files.sort, files, "Results should be sorted"
  end

  def test_list_packages
    packages = @discoverer.list_packages(base_dir: @base_dir)
    refute_empty packages, "Should find packages with E2E tests"
    assert_includes packages, "ace-lint", "Should include ace-lint"
  end

  def test_find_tests_in_temp_directory
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-example", ["TC-001", "TC-002"])

      files = @discoverer.find_tests(package: "my-package", base_dir: tmpdir)
      assert_equal 1, files.size, "Should find the scenario file"
      assert files.first.end_with?("scenario.yml")
    end
  end

  def test_find_tests_by_comma_separated_ids
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-first", ["TC-001"])
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-002-second", ["TC-001"])
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-003-third", ["TC-001"])

      files = @discoverer.find_tests(
        package: "my-package",
        test_id: "TS-TEST-001,TS-TEST-002",
        base_dir: tmpdir
      )
      assert_equal 2, files.size, "Should find exactly two tests"
      assert files.any? { |f| f.include?("TS-TEST-001") }
      assert files.any? { |f| f.include?("TS-TEST-002") }
    end
  end

  def test_find_tests_by_partial_comma_separated_ids
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-first", ["TC-001"])
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-002-second", ["TC-001"])
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-003-third", ["TC-001"])

      files = @discoverer.find_tests(
        package: "my-package",
        test_id: "001,002",
        base_dir: tmpdir
      )
      assert_equal 2, files.size, "Should find two tests by partial IDs"
      assert files.any? { |f| f.include?("001") }
      assert files.any? { |f| f.include?("002") }
    end
  end

  def test_find_tests_comma_separated_with_spaces
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-first", ["TC-001"])
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-002-second", ["TC-001"])

      files = @discoverer.find_tests(
        package: "my-package",
        test_id: "001, 002",
        base_dir: tmpdir
      )
      assert_equal 2, files.size, "Should handle whitespace in comma-separated IDs"
    end
  end

  def test_find_tests_comma_separated_deduplicates
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-first", ["TC-001"])

      files = @discoverer.find_tests(
        package: "my-package",
        test_id: "001,TS-TEST-001",
        base_dir: tmpdir
      )
      assert_equal 1, files.size, "Should deduplicate overlapping ID matches"
    end
  end

  # --- TS-Format Discovery ---

  def test_find_scenarios_in_temp_directory
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-example", ["TC-001", "TC-002"])

      scenarios = @discoverer.find_scenarios(package: "my-package", base_dir: tmpdir)

      assert_equal 1, scenarios.size
      assert_equal "TS-TEST-001", scenarios.first.test_id
    end
  end

  def test_find_scenarios_filters_by_test_id
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-first", ["TC-001"])
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-002-second", ["TC-001"])

      scenarios = @discoverer.find_scenarios(package: "my-package", test_id: "TS-TEST-001", base_dir: tmpdir)

      assert_equal 1, scenarios.size
      assert_equal "TS-TEST-001", scenarios.first.test_id
    end
  end

  def test_find_scenarios_returns_sorted
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-002-second", ["TC-001"])
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-first", ["TC-001"])

      scenarios = @discoverer.find_scenarios(package: "my-package", base_dir: tmpdir)

      assert_equal "TS-TEST-001", scenarios.first.test_id
      assert_equal "TS-TEST-002", scenarios.last.test_id
    end
  end

  def test_find_scenarios_for_nonexistent_package
    Dir.mktmpdir do |tmpdir|
      scenarios = @discoverer.find_scenarios(package: "nonexistent", base_dir: tmpdir)
      assert_empty scenarios
    end
  end

  def test_find_scenarios_returns_test_cases
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-example", ["TC-001", "TC-002", "TC-003"])

      scenarios = @discoverer.find_scenarios(package: "my-package", base_dir: tmpdir)
      tc_ids = scenarios.first.test_cases.map(&:tc_id)

      assert_equal ["TC-001", "TC-002", "TC-003"], tc_ids
    end
  end

  def test_find_tests_filters_by_tags
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-smoke", ["TC-001"], tags: ["smoke"])
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-002-deep", ["TC-001"], tags: ["deep"])

      files = @discoverer.find_tests(package: "my-package", tags: "smoke", base_dir: tmpdir)

      assert_equal 1, files.size
      assert files.first.include?("TS-TEST-001")
    end
  end

  def test_find_tests_filters_by_exclude_tags
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-smoke", ["TC-001"], tags: ["smoke"])
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-002-deep", ["TC-001"], tags: ["deep"])

      files = @discoverer.find_tests(package: "my-package", exclude_tags: "deep", base_dir: tmpdir)

      assert_equal 1, files.size
      assert files.first.include?("TS-TEST-001")
    end
  end

  def test_find_tests_include_then_exclude_exclude_wins
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-smoke", ["TC-001"], tags: ["smoke"])
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-002-smoke-deep", ["TC-001"], tags: ["smoke", "deep"])

      files = @discoverer.find_tests(
        package: "my-package",
        tags: "smoke",
        exclude_tags: "deep",
        base_dir: tmpdir
      )

      assert_equal 1, files.size
      assert files.first.include?("TS-TEST-001")
    end
  end

  def test_list_packages_includes_ts_format_packages
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "ace-lint", "TS-LINT-001-test", ["TC-001"])

      packages = @discoverer.list_packages(base_dir: tmpdir)

      assert_includes packages, "ace-lint"
    end
  end

  private

  def create_ts_scenario(base_dir, package, scenario_name, tc_ids, tags: nil)
    scenario_dir = File.join(base_dir, package, "test-e2e", "scenarios", scenario_name)
    FileUtils.mkdir_p(scenario_dir)

    test_id = scenario_name.split("-")[0..2].join("-")
    extra = []
    extra << "tags: [#{tags.join(", ")}]" if tags

    File.write(File.join(scenario_dir, "scenario.yml"), <<~YAML)
      test-id: #{test_id}
      title: Test Scenario
      area: test
      setup:
        - git-init
      #{extra.join("\n")}
    YAML

    runner_files = tc_ids.map { |tc_id| "          - ./#{tc_id}-test.runner.md" }.join("\n")
    verify_files = tc_ids.map { |tc_id| "          - ./#{tc_id}-test.verify.md" }.join("\n")

    File.write(File.join(scenario_dir, "runner.yml.md"), <<~MD)
            ---
            bundle:
              files:
      #{runner_files}
            ---
      
            # Runner
            Workspace root: (current directory)
    MD

    File.write(File.join(scenario_dir, "verifier.yml.md"), <<~MD)
            ---
            bundle:
              files:
      #{verify_files}
            ---
      
            # Verifier
    MD

    tc_ids.each do |tc_id|
      File.write(File.join(scenario_dir, "#{tc_id}-test.runner.md"), "# Goal #{tc_id}\nRun #{tc_id}\n")
      File.write(File.join(scenario_dir, "#{tc_id}-test.verify.md"), "# Verify #{tc_id}\nCheck #{tc_id}\n")
    end
  end
end
