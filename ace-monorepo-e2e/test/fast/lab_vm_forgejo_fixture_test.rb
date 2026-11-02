# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../lab-vm/forgejo/fixture"
require "yaml"

class LabVmForgejoFixtureTest < AceMonorepoE2eTestCase
  def issues
    YAML.safe_load_file(File.expand_path("../../lab-vm/fixtures/forgejo-issues.yml", __dir__), permitted_classes: [], aliases: false).fetch("issues")
  end

  def test_real_fixture_has_explicitly_ordered_dependencies
    assert_equal %w[base cli docs release], LabVmForgejoFixture.validate_issues!(issues).map { |issue| issue.fetch("key") }
  end

  def test_rejects_dependency_that_would_not_resolve
    input = issues
    input[1]["depends_on"] = ["release"]
    assert_raises(ArgumentError) { LabVmForgejoFixture.validate_issues!(input) }
  end

  def test_rejects_duplicate_issue_and_mismatched_references
    input = issues
    input[2]["key"] = "base"
    assert_raises(ArgumentError) { LabVmForgejoFixture.validate_issues!(input) }
    input = issues
    input[1]["depends_on"] = []
    assert_raises(ArgumentError) { LabVmForgejoFixture.validate_issues!(input) }
  end

  def test_rejects_a_real_forge_url_in_the_test_input
    input = issues
    input[0]["body"] += " https://example.com/production"
    assert_raises(ArgumentError) { LabVmForgejoFixture.validate_issues!(input) }
  end
end
