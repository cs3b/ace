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
