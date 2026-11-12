# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"
require "json"
require "tmpdir"
require "fileutils"
require "ace/support/config"

class LabVmRoutingTest < AceMonorepoE2eTestCase
  def test_fixture_model_policy_overrides_all_inherited_roles_without_inference
    fixture = File.expand_path("../../lab-vm/fixtures/llm-config.yml", __dir__)
    Dir.mktmpdir("ace-fixture-models-") do |root|
      FileUtils.mkdir_p(File.join(root, ".ace/llm"))
      FileUtils.cp(fixture, File.join(root, ".ace/llm/config.yml"))
      config = Ace::Support::Config.create(
        test_mode: false,
        start_path: root,
        gem_path: Gem::Specification.find_by_name("ace-llm").full_gem_path
      ).resolve_namespace("llm")
      assert_equal ["pi"], config.get("llm", "providers", "active")
      assert_equal false, config.get("llm", "fallback", "enabled")
      assert_equal [], config.get("llm", "fallback", "providers")
      roles = config.get("llm", "roles")
      refute_empty roles
      roles.each do |name, candidates|
        assert_equal 1, candidates.length, name
        assert_match(/\Api:zai\/glm-5\.3-flash:high(?:@ro|@yolo)?\z/, candidates.first, name)
      end
      assert_equal ["pi:zai/glm-5.3-flash:high@ro"], roles.fetch("review-default")
    end
  end

  def test_bootstrap_reports_and_project_reports_have_distinct_coordinators
    fixtures = File.expand_path("../../lab-vm/fixtures", __dir__)
    lab = YAML.safe_load_file(File.join(fixtures, "lab/.ace/hitl/config.yml")).fetch("hitl")
    project = YAML.safe_load_file(File.join(fixtures, "ace/.ace/hitl/config.yml")).fetch("hitl")
    eyes = JSON.parse(File.read(File.join(fixtures, "lab/.ace-local/overseer/eyes.json")))
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
