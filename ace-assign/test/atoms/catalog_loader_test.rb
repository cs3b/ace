# frozen_string_literal: true

require_relative "../test_helper"

class CatalogLoaderTest < AceAssignTestCase
  def setup
    @catalog_dir = gem_catalog_phases_dir
    @phases = Ace::Assign::Atoms::CatalogLoader.load_all(@catalog_dir)
  end

  # load_all tests

  def test_load_all_returns_array
    assert_kind_of Array, @phases
  end

  def test_load_all_loads_all_phase_files
    assert @phases.length >= 14, "Expected at least 14 phases, got #{@phases.length}"
  end

  def test_load_all_each_phase_has_name
    @phases.each do |phase|
      assert phase["name"], "Phase missing name: #{phase.inspect}"
    end
  end

  def test_load_all_each_phase_has_description
    @phases.each do |phase|
      assert phase["description"], "Phase '#{phase["name"]}' missing description"
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
    phase = Ace::Assign::Atoms::CatalogLoader.find_by_name(@phases, "work-on-task")

    refute_nil phase
    assert_equal "work-on-task", phase["name"]
    assert_equal "ace-task-work", phase["skill"]
  end

  def test_find_by_name_onboard
    phase = Ace::Assign::Atoms::CatalogLoader.find_by_name(@phases, "onboard")

    refute_nil phase
    assert_equal "ace-onboard", phase["skill"]
  end

  def test_find_by_name_not_found
    result = Ace::Assign::Atoms::CatalogLoader.find_by_name(@phases, "nonexistent-phase")

    assert_nil result
  end

  # filter_by_tag tests

  def test_filter_by_tag_implementation
    result = Ace::Assign::Atoms::CatalogLoader.filter_by_tag(@phases, "implementation")

    assert result.length >= 1
    result.each do |phase|
      assert_includes phase["tags"], "implementation"
    end
  end

  def test_filter_by_tag_review
    result = Ace::Assign::Atoms::CatalogLoader.filter_by_tag(@phases, "review")

    assert result.length >= 1
    names = result.map { |p| p["name"] }
    assert_includes names, "review-pr"
  end

  def test_filter_by_tag_no_match
    result = Ace::Assign::Atoms::CatalogLoader.filter_by_tag(@phases, "nonexistent-tag")

    assert_equal [], result
  end

  # producers_of tests

  def test_producers_of_code_changes
    result = Ace::Assign::Atoms::CatalogLoader.producers_of(@phases, "code-changes")

    assert result.length >= 1
    names = result.map { |p| p["name"] }
    assert_includes names, "work-on-task"
  end

  def test_producers_of_pull_request
    result = Ace::Assign::Atoms::CatalogLoader.producers_of(@phases, "pull-request")

    names = result.map { |p| p["name"] }
    assert_includes names, "create-pr"
  end

  def test_producers_of_nonexistent
    result = Ace::Assign::Atoms::CatalogLoader.producers_of(@phases, "nonexistent-artifact")

    assert_equal [], result
  end

  # validate_prerequisites tests

  def test_validate_prerequisites_all_satisfied
    selected = ["onboard", "work-on-task", "create-pr"]
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(selected, @phases)

    # onboard has no prerequisites, work-on-task has no explicit prerequisite
    # entries, create-pr requires work-on-task (present)
    assert_empty issues
  end

  def test_validate_prerequisites_missing_required
    selected = ["create-pr"]
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(selected, @phases)

    assert issues.length >= 1
    prereq_names = issues.map { |i| i[:prerequisite] }
    assert_includes prereq_names, "work-on-task"
  end

  def test_validate_prerequisites_no_recommended_missing
    selected = ["work-on-task"]
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(selected, @phases)

    assert_empty issues
  end

  def test_validate_prerequisites_empty_selection
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites([], @phases)

    assert_empty issues
  end

  def test_validate_prerequisites_unknown_phase
    issues = Ace::Assign::Atoms::CatalogLoader.validate_prerequisites(["nonexistent"], @phases)

    assert_empty issues
  end

  private

  def gem_catalog_phases_dir
    gem_root = File.expand_path("../..", __dir__)
    File.join(gem_root, ".ace-defaults", "assign", "catalog", "phases")
  end
end
