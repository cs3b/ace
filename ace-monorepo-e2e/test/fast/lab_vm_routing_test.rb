# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"
require "json"

class LabVmRoutingTest < AceMonorepoE2eTestCase
  def test_bootstrap_reports_and_project_reports_have_distinct_coordinators
    fixtures = File.expand_path("../../lab-vm/fixtures", __dir__)
    lab = YAML.safe_load_file(File.join(fixtures, "lab/.ace/hitl/config.yml")).fetch("hitl")
    project = YAML.safe_load_file(File.join(fixtures, "ace/.ace/hitl/config.yml")).fetch("hitl")
    eyes = JSON.parse(File.read(File.join(fixtures, "lab/.ace/overseer/eyes.json")))
    lab_address = lab.fetch("recipients").fetch(eyes.fetch("recipient"))
    assert_equal "/lab/.ace-local/hitl", lab_address.fetch("folder")
    assert_equal lab_address, project.fetch("recipients").fetch("lab-overseer")
    project_address = project.fetch("recipients").fetch("overseer")
    assert_equal "/lab/ace/.ace-local/hitl", project_address.fetch("folder")
    refute_equal lab_address, project_address
    refute_equal lab_address, lab.fetch("recipients").fetch("captain")
    refute_equal project_address, project.fetch("recipients").fetch("captain")
    assert_equal "all", eyes.fetch("scope"), "worker reports remain in their worktrees"
  end
end
