# frozen_string_literal: true

require_relative "../test_helper"

class TestScenarioTest < Minitest::Test
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario

  def test_basic_attributes
    scenario = create_scenario
    assert_equal "TS-LINT-001", scenario.test_id
    assert_equal "Test Title", scenario.title
    assert_equal "lint", scenario.area
    assert_equal "ace-lint", scenario.package
    assert_equal "high", scenario.priority
    assert_equal "~15min", scenario.duration
  end

  def test_default_values
    scenario = TestScenario.new(
      test_id: "TS-TEST-001",
      title: "Test",
      area: "test",
      package: "ace-test",
      file_path: "/tmp/test/scenario.yml",
      content: "content"
    )
    assert_equal "medium", scenario.priority
    assert_equal "~5min", scenario.duration
    assert_equal({}, scenario.requires)
    assert_nil scenario.timeout
  end

  def test_short_package
    assert_equal "lint", create_scenario(package: "ace-lint").short_package
    assert_equal "git-commit", create_scenario(package: "ace-git-commit").short_package
    assert_equal "review", create_scenario(package: "ace-review").short_package
  end

  def test_short_package_without_ace_prefix
    assert_equal "mypackage", create_scenario(package: "mypackage").short_package
  end

  def test_short_id
    assert_equal "ts001", create_scenario(test_id: "TS-LINT-001").short_id
    assert_equal "ts015", create_scenario(test_id: "TS-REVIEW-015").short_id
    assert_equal "ts003", create_scenario(test_id: "TS-GIT-003").short_id
  end

  def test_short_id_with_digits_in_area_name
    assert_equal "ts001", create_scenario(test_id: "TS-B36TS-001").short_id
    assert_equal "ts002", create_scenario(test_id: "TS-B36TS-002").short_id
    assert_equal "ts005", create_scenario(test_id: "TS-ASSIGN-005").short_id
  end

  def test_short_id_with_alphabetic_suffix
    assert_equal "ts001a", create_scenario(test_id: "TS-BUNDLE-001a").short_id
    assert_equal "ts001b", create_scenario(test_id: "TS-BUNDLE-001b").short_id
    assert_equal "ts001c", create_scenario(test_id: "TS-BUNDLE-001c").short_id
    assert_equal "ts003a", create_scenario(test_id: "TS-COWORKER-003a").short_id
    assert_equal "ts003b", create_scenario(test_id: "TS-COWORKER-003b").short_id
    assert_equal "ts003c", create_scenario(test_id: "TS-COWORKER-003c").short_id
    assert_equal "ts003d", create_scenario(test_id: "TS-COWORKER-003d").short_id
    assert_equal "ts004a", create_scenario(test_id: "TS-COMMIT-004a").short_id
    assert_equal "ts004b", create_scenario(test_id: "TS-COMMIT-004b").short_id
    assert_equal "ts004c", create_scenario(test_id: "TS-COMMIT-004c").short_id
    assert_equal "ts004d", create_scenario(test_id: "TS-COMMIT-004d").short_id
  end

  def test_dir_name
    scenario = create_scenario(test_id: "TS-LINT-001", package: "ace-lint")
    assert_equal "8xyz12-lint-ts001", scenario.dir_name("8xyz12")
  end

  # New optional fields

  def test_new_fields_defaults
    scenario = create_scenario
    assert_equal [], scenario.setup_steps
    assert_nil scenario.dir_path
    assert_nil scenario.fixture_path
    assert_equal [], scenario.test_cases
    assert_equal [], scenario.tags
    assert_nil scenario.tool_under_test
    assert_equal({}, scenario.sandbox_layout)
  end

  def test_new_fields_set
    tc = Ace::Test::EndToEndRunner::Models::TestCase.new(
      tc_id: "TC-001", title: "Test", content: "body", file_path: "/tmp/tc.md"
    )
    scenario = create_scenario(
      setup_steps: ["git-init", "copy-fixtures"],
      timeout: 900,
      dir_path: "/tmp/scenario",
      fixture_path: "/tmp/scenario/fixtures",
      test_cases: [tc],
      tags: ["smoke", "happy-path"],
      tool_under_test: "ace-lint",
      sandbox_layout: { "output/" => "Report output" }
    )
    assert_equal 900, scenario.timeout
    assert_equal ["git-init", "copy-fixtures"], scenario.setup_steps
    assert_equal "/tmp/scenario", scenario.dir_path
    assert_equal "/tmp/scenario/fixtures", scenario.fixture_path
    assert_equal [tc], scenario.test_cases
    assert_equal ["smoke", "happy-path"], scenario.tags
    assert_equal "ace-lint", scenario.tool_under_test
    assert_equal({ "output/" => "Report output" }, scenario.sandbox_layout)
  end

  # test_case_ids from test_cases array

  def test_test_case_ids_from_test_cases
    tc1 = Ace::Test::EndToEndRunner::Models::TestCase.new(
      tc_id: "TC-001", title: "First", content: "body", file_path: "/tmp/tc1.md"
    )
    tc2 = Ace::Test::EndToEndRunner::Models::TestCase.new(
      tc_id: "TC-002", title: "Second", content: "body", file_path: "/tmp/tc2.md"
    )
    scenario = create_scenario(test_cases: [tc1, tc2])
    assert_equal ["TC-001", "TC-002"], scenario.test_case_ids
  end

  def test_test_case_ids_empty_when_no_test_cases
    scenario = create_scenario(test_cases: [])
    assert_equal [], scenario.test_case_ids
  end

  private

  def create_scenario(overrides = {})
    defaults = {
      test_id: "TS-LINT-001",
      title: "Test Title",
      area: "lint",
      package: "ace-lint",
      priority: "high",
      duration: "~15min",
      file_path: "/tmp/test/scenario.yml",
      content: "# Test content"
    }
    TestScenario.new(**defaults.merge(overrides))
  end
end
