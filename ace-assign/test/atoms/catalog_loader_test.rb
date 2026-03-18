# frozen_string_literal: true

require_relative "../test_helper"

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
      assert step["description"], "Step '#{step["name"]}' missing description"
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
    assert_includes names, "review-pr"
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
    assert_includes names, "work-on-task"
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
    selected = ["onboard", "work-on-task", "create-pr"]
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(selected, @steps)

    # onboard has no prerequisites, work-on-task has no explicit prerequisite
    # entries, create-pr requires work-on-task (present)
    assert_empty issues
  end

  def test_validate_prerequisites_missing_required
    selected = ["create-pr"]
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(selected, @steps)

    assert issues.length >= 1
    prereq_names = issues.map { |i| i[:prerequisite] }
    assert_includes prereq_names, "work-on-task"
  end

  def test_validate_prerequisites_no_recommended_missing
    selected = ["work-on-task"]
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(selected, @steps)

    assert_empty issues
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
    gem_root = File.expand_path("../..", __dir__)
    File.join(gem_root, ".ace-defaults", "assign", "catalog", "steps")
  end
end
