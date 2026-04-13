# frozen_string_literal: true

require_relative "../../test_helper"

class CatalogLoaderTest < AceAssignTestCase
  def setup
    @catalog_dir = gem_catalog_steps_dir
    @steps = Ace::Assign::Atoms::CatalogLoader.load_all(@catalog_dir)
  end

  # load_all tests

  def test_load_all_returns_array
    assert_kind_of Array, @steps
  end

  def test_load_all_loads_all_step_files
    assert @steps.length >= 14, "Expected at least 14 steps, got #{@steps.length}"
  end

  def test_load_all_each_step_has_name
    @steps.each do |step|
      assert step["name"], "Step missing name: #{step.inspect}"
    end
  end

  def test_load_all_each_step_has_description
    @steps.each do |step|
      assert step["description"], "Step missing description after canonical merge: #{step.inspect}"
    end
  end

  def test_load_all_returns_empty_for_missing_directory
    result = Ace::Assign::Atoms::CatalogLoader.load_all("/nonexistent/path")

    assert_equal [], result
  end

  def test_load_all_returns_empty_for_empty_directory
    Dir.mktmpdir("catalog-test") do |dir|
      result = Ace::Assign::Atoms::CatalogLoader.load_all(dir)

      assert_equal [], result
    end
  end

  # find_by_name tests

  def test_find_by_name_existing
    step = Ace::Assign::Atoms::CatalogLoader.find_by_name(@steps, "work-on-task")

    refute_nil step
    assert_equal "work-on-task", step["name"]
    assert_equal "as-task-work", step["skill"]
  end

  def test_find_by_name_onboard
    step = Ace::Assign::Atoms::CatalogLoader.find_by_name(@steps, "onboard")

    refute_nil step
    assert_equal "as-onboard", step["skill"]
  end

  def test_find_by_name_not_found
    result = Ace::Assign::Atoms::CatalogLoader.find_by_name(@steps, "nonexistent-step")

    assert_nil result
  end

  # filter_by_tag tests

  def test_filter_by_tag_implementation
    result = Ace::Assign::Atoms::CatalogLoader.filter_by_tag(@steps, "implementation")

    assert result.length >= 1
    result.each do |step|
      assert_includes step["tags"], "implementation"
    end
  end

  def test_filter_by_tag_review
    result = Ace::Assign::Atoms::CatalogLoader.filter_by_tag(@steps, "review")

    assert result.length >= 1
    names = result.map { |p| p["name"] }
    assert_includes names, "pre-commit-review"
  end

  def test_filter_by_tag_no_match
    result = Ace::Assign::Atoms::CatalogLoader.filter_by_tag(@steps, "nonexistent-tag")

    assert_equal [], result
  end

  # producers_of tests

  def test_producers_of_code_changes
    result = Ace::Assign::Atoms::CatalogLoader.producers_of(@steps, "code-changes")

    assert result.length >= 1
    names = result.map { |p| p["name"] }
    assert_includes names, "apply-feedback"
  end

  def test_producers_of_pull_request
    result = Ace::Assign::Atoms::CatalogLoader.producers_of(@steps, "pull-request")

    names = result.map { |p| p["name"] }
    assert_includes names, "create-pr"
  end

  def test_producers_of_nonexistent
    result = Ace::Assign::Atoms::CatalogLoader.producers_of(@steps, "nonexistent-artifact")

    assert_equal [], result
  end

  # validate_prerequisites tests

  def test_validate_prerequisites_all_satisfied
    selected = ["work-on-task", "create-pr", "review-pr", "apply-feedback"]
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(selected, @steps)

    # apply-feedback requires review-pr, review-pr requires create-pr, and create-pr requires work-on-task.
    assert_empty issues
  end

  def test_validate_prerequisites_missing_required
    selected = ["apply-feedback"]
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(selected, @steps)

    assert issues.length >= 1
    prereq_names = issues.map { |i| i[:prerequisite] }
    assert_includes prereq_names, "review-pr"
  end

  def test_validate_prerequisites_no_recommended_missing
    selected = ["work-on-task"]
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(selected, @steps)

    assert_empty issues
  end

  def test_load_all_can_return_raw_yaml_without_canonical_merge
    raw_steps = Ace::Assign::Atoms::CatalogLoader.load_all(@catalog_dir, canonical_steps: false)
    work_on_task = Ace::Assign::Atoms::CatalogLoader.find_by_name(raw_steps, "work-on-task")
    create_pr = Ace::Assign::Atoms::CatalogLoader.find_by_name(raw_steps, "create-pr")

    assert_equal "as-task-work", work_on_task["skill"]
    assert_nil work_on_task["description"]
    assert_nil create_pr["produces"]
  end

  def test_load_all_preserves_local_runtime_binding_when_canonical_metadata_exists
    Dir.mktmpdir("catalog-runtime-binding") do |dir|
      File.write(File.join(dir, "verify-test-suite.step.yml"), <<~YAML)
        name: verify-test-suite
        workflow: wfi://assign/verify-test-suite
        description: Local contract
      YAML

      canonical_steps = [
        {
          "name" => "verify-test-suite",
          "source" => "skill://as-test-verify-suite",
          "skill" => "as-test-verify-suite",
          "source_skill" => "as-test-verify-suite",
          "workflow" => "wfi://test/verify-suite",
          "description" => "Canonical suite"
        }
      ]

      merged = Ace::Assign::Atoms::CatalogLoader.load_all(dir, canonical_steps: canonical_steps)
      verify_suite = Ace::Assign::Atoms::CatalogLoader.find_by_name(merged, "verify-test-suite")

      assert_equal "Canonical suite", verify_suite["description"]
      assert_equal "wfi://assign/verify-test-suite", verify_suite["workflow"]
      assert_nil verify_suite["source"]
      assert_nil verify_suite["skill"]
      assert_nil verify_suite["source_skill"]
    end
  end

  def test_validate_prerequisites_empty_selection
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites([], @steps)

    assert_empty issues
  end

  def test_validate_prerequisites_unknown_step
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(["nonexistent"], @steps)

    assert_empty issues
  end

  private

  def gem_catalog_steps_dir
    gem_root = File.expand_path("../../..", __dir__)
    File.join(gem_root, ".ace-defaults", "assign", "catalog", "steps")
  end
end
