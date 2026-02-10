# frozen_string_literal: true

require_relative "../test_helper"

class TestScenarioTest < Minitest::Test
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario

  def test_basic_attributes
    scenario = create_scenario
    assert_equal "MT-LINT-001", scenario.test_id
    assert_equal "Test Title", scenario.title
    assert_equal "lint", scenario.area
    assert_equal "ace-lint", scenario.package
    assert_equal "high", scenario.priority
    assert_equal "~15min", scenario.duration
  end

  def test_default_values
    scenario = TestScenario.new(
      test_id: "MT-TEST-001",
      title: "Test",
      area: "test",
      package: "ace-test",
      file_path: "/tmp/test.mt.md",
      content: "content"
    )
    assert_equal "medium", scenario.priority
    assert_equal "~5min", scenario.duration
    assert_equal({}, scenario.requires)
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
    assert_equal "mt001", create_scenario(test_id: "MT-LINT-001").short_id
    assert_equal "mt015", create_scenario(test_id: "MT-REVIEW-015").short_id
    assert_equal "mt003", create_scenario(test_id: "MT-GIT-003").short_id
  end

  def test_short_id_with_alphabetic_suffix
    assert_equal "mt001a", create_scenario(test_id: "MT-BUNDLE-001a").short_id
    assert_equal "mt001b", create_scenario(test_id: "MT-BUNDLE-001b").short_id
    assert_equal "mt001c", create_scenario(test_id: "MT-BUNDLE-001c").short_id
    assert_equal "mt003a", create_scenario(test_id: "MT-COWORKER-003a").short_id
    assert_equal "mt003b", create_scenario(test_id: "MT-COWORKER-003b").short_id
    assert_equal "mt003c", create_scenario(test_id: "MT-COWORKER-003c").short_id
    assert_equal "mt003d", create_scenario(test_id: "MT-COWORKER-003d").short_id
    assert_equal "mt004a", create_scenario(test_id: "MT-COMMIT-004a").short_id
    assert_equal "mt004b", create_scenario(test_id: "MT-COMMIT-004b").short_id
    assert_equal "mt004c", create_scenario(test_id: "MT-COMMIT-004c").short_id
    assert_equal "mt004d", create_scenario(test_id: "MT-COMMIT-004d").short_id
  end

  def test_dir_name
    scenario = create_scenario(test_id: "MT-LINT-001", package: "ace-lint")
    assert_equal "8xyz12-lint-mt001", scenario.dir_name("8xyz12")
  end

  # TS- format support

  def test_short_id_ts_format
    assert_equal "ts001", create_scenario(test_id: "TS-LINT-001").short_id
    assert_equal "ts015", create_scenario(test_id: "TS-REVIEW-015").short_id
    assert_equal "ts003", create_scenario(test_id: "TS-GIT-003").short_id
  end

  def test_short_id_ts_with_alpha_suffix
    assert_equal "ts001a", create_scenario(test_id: "TS-BUNDLE-001a").short_id
    assert_equal "ts002b", create_scenario(test_id: "TS-LINT-002b").short_id
  end

  def test_dir_name_ts_format
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
  end

  def test_new_fields_set
    tc = Ace::Test::EndToEndRunner::Models::TestCase.new(
      tc_id: "TC-001", title: "Test", content: "body", file_path: "/tmp/tc.md"
    )
    scenario = create_scenario(
      setup_steps: ["git-init", "copy-fixtures"],
      dir_path: "/tmp/scenario",
      fixture_path: "/tmp/scenario/fixtures",
      test_cases: [tc]
    )
    assert_equal ["git-init", "copy-fixtures"], scenario.setup_steps
    assert_equal "/tmp/scenario", scenario.dir_path
    assert_equal "/tmp/scenario/fixtures", scenario.fixture_path
    assert_equal [tc], scenario.test_cases
  end

  # scenario_format

  def test_scenario_format_ts
    assert_equal :ts, create_scenario(test_id: "TS-LINT-001").scenario_format
  end

  def test_scenario_format_mt
    assert_equal :mt, create_scenario(test_id: "MT-LINT-001").scenario_format
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

  def test_test_case_ids_falls_back_to_content
    content = "## Test Cases\n\n### TC-001: First Test\nCheck it.\n\n### TC-002: Second Test\nVerify it."
    scenario = create_scenario(content: content, test_cases: [])
    assert_equal ["TC-001", "TC-002"], scenario.test_case_ids
  end

  private

  def create_scenario(overrides = {})
    defaults = {
      test_id: "MT-LINT-001",
      title: "Test Title",
      area: "lint",
      package: "ace-lint",
      priority: "high",
      duration: "~15min",
      file_path: "/tmp/test.mt.md",
      content: "# Test content"
    }
    TestScenario.new(**defaults.merge(overrides))
  end
end
