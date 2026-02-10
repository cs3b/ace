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
    assert files.all? { |f| f.end_with?(".mt.md") }, "All files should be .mt.md"
  end

  def test_find_tests_for_nonexistent_package
    files = @discoverer.find_tests(package: "ace-nonexistent", base_dir: @base_dir)
    assert_empty files, "Should find no tests for nonexistent package"
  end

  def test_find_specific_test_by_id
    files = @discoverer.find_tests(
      package: "ace-lint",
      test_id: "MT-LINT-001",
      base_dir: @base_dir
    )
    assert_equal 1, files.size, "Should find exactly one test for MT-LINT-001"
    assert files.first.include?("MT-LINT-001"), "File should contain test ID"
  end

  def test_find_specific_test_nonexistent_id
    files = @discoverer.find_tests(
      package: "ace-lint",
      test_id: "MT-LINT-999",
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
      # Create test structure
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-example.mt.md"), "---\ntest-id: MT-TEST-001\n---\n")
      File.write(File.join(test_dir, "MT-TEST-002-other.mt.md"), "---\ntest-id: MT-TEST-002\n---\n")

      files = @discoverer.find_tests(package: "my-package", base_dir: tmpdir)
      assert_equal 2, files.size, "Should find both test files"
    end
  end

  def test_find_tests_by_comma_separated_ids
    Dir.mktmpdir do |tmpdir|
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-first.mt.md"), "")
      File.write(File.join(test_dir, "MT-TEST-002-second.mt.md"), "")
      File.write(File.join(test_dir, "MT-TEST-003-third.mt.md"), "")

      files = @discoverer.find_tests(
        package: "my-package",
        test_id: "MT-TEST-001,MT-TEST-002",
        base_dir: tmpdir
      )
      assert_equal 2, files.size, "Should find exactly two tests"
      assert files.any? { |f| f.include?("MT-TEST-001") }
      assert files.any? { |f| f.include?("MT-TEST-002") }
    end
  end

  def test_find_tests_by_partial_comma_separated_ids
    Dir.mktmpdir do |tmpdir|
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-first.mt.md"), "")
      File.write(File.join(test_dir, "MT-TEST-002-second.mt.md"), "")
      File.write(File.join(test_dir, "MT-TEST-003-third.mt.md"), "")

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
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-first.mt.md"), "")
      File.write(File.join(test_dir, "MT-TEST-002-second.mt.md"), "")

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
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-first.mt.md"), "")

      files = @discoverer.find_tests(
        package: "my-package",
        test_id: "001,MT-TEST-001",
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

  def test_find_tests_includes_scenario_yml_paths
    Dir.mktmpdir do |tmpdir|
      test_dir = File.join(tmpdir, "my-package", "test", "e2e")
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, "MT-TEST-001-legacy.mt.md"), "")
      create_ts_scenario(tmpdir, "my-package", "TS-TEST-001-new", ["TC-001"])

      files = @discoverer.find_tests(package: "my-package", base_dir: tmpdir)

      assert files.any? { |f| f.end_with?(".mt.md") }, "Should include MT files"
      assert files.any? { |f| f.end_with?("scenario.yml") }, "Should include scenario.yml"
    end
  end

  def test_list_packages_includes_ts_format_packages
    Dir.mktmpdir do |tmpdir|
      create_ts_scenario(tmpdir, "ace-lint", "TS-LINT-001-test", ["TC-001"])

      packages = @discoverer.list_packages(base_dir: tmpdir)

      assert_includes packages, "ace-lint"
    end
  end

  def test_list_packages_deduplicates_mixed_format
    Dir.mktmpdir do |tmpdir|
      # MT format
      mt_dir = File.join(tmpdir, "ace-lint", "test", "e2e")
      FileUtils.mkdir_p(mt_dir)
      File.write(File.join(mt_dir, "MT-LINT-001-legacy.mt.md"), "")
      # TS format
      create_ts_scenario(tmpdir, "ace-lint", "TS-LINT-001-new", ["TC-001"])

      packages = @discoverer.list_packages(base_dir: tmpdir)

      assert_equal 1, packages.count("ace-lint"), "Package should appear only once"
    end
  end

  private

  def create_ts_scenario(base_dir, package, scenario_name, tc_ids)
    scenario_dir = File.join(base_dir, package, "test", "e2e", scenario_name)
    FileUtils.mkdir_p(scenario_dir)

    test_id = scenario_name.split("-")[0..2].join("-")
    File.write(File.join(scenario_dir, "scenario.yml"), <<~YAML)
      test-id: #{test_id}
      title: Test Scenario
      area: test
      setup:
        - git-init
    YAML

    tc_ids.each do |tc_id|
      File.write(File.join(scenario_dir, "#{tc_id}-test.tc.md"), <<~MD)
        ---
        tc-id: #{tc_id}
        title: #{tc_id} Test
        ---

        ## Objective
        Test #{tc_id}.
      MD
    end
  end
end
