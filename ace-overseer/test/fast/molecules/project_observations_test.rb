# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/project_observations"

class ProjectObservationsTest < AceOverseerTestCase
  def setup
    @root = File.realpath(Dir.mktmpdir)
    @project = File.join(@root, "ace")
    FileUtils.mkdir_p(File.join(@project, ".ace/hitl"))
    system("git", "init", "--quiet", @project, exception: true)
    @manifest = File.join(@root, "manifest.yml")
    File.write(@manifest, "fixture")
    @document = {"coordinator" => {"path" => @root}, "projects" => [{"id" => "ace", "path" => @project}]}
    @lab_address = {"machine" => "lab", "panel" => "w2:p2"}
    @project_address = {"machine" => "lab", "panel" => "w3:p1"}
    @lab_config = {"hitl" => {"recipients" => {"overseer" => @lab_address}}}
    @project_config = {"hitl" => {"root_dir" => File.join(@project, ".ace-local/hitl"),
      "machine" => "lab", "recipients" => {"overseer" => @project_address, "lab-overseer" => @lab_address}}}
    File.write(File.join(@project, ".ace/hitl/config.yml"), YAML.dump(@project_config))
    @manager = Ace::Hitl::Organisms::HitlManager.new(config: @project_config,
      root_dir: @project_config.dig("hitl", "root_dir"))
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def observe(root: @root)
    Ace::Lab.stub(:install_manifest_path, @manifest) do
      Ace::Overseer::Molecules::ProjectObservations.new(root: root, env: {"ACE_TOOLCHAIN" => "installed"},
        loader: -> { @document }, hitl_config: @lab_config).call(owner: "overseer", scope: "current", limit: 500)
    end
  end

  def messages(result)
    result.fetch("events").reject { |row| row["type"] == "source-health" }
  end

  def test_lab_reads_only_its_messages_despite_same_alias_in_project
    own = @manager.create("Bootstrap ready", type: "report", result: "success", to: "lab-overseer", assignment: "bootstrap1")
    @manager.create("Project worker ready", type: "report", result: "success", to: "overseer", assignment: "worker1")
    escalation = @manager.create("Lab decision needed", type: "question", to: "lab-overseer", questions: ["Choose scope"])
    @manager.create("Worker question", type: "question", to: "overseer", questions: ["Project detail"])
    first = observe
    assert_equal [own.id, escalation.id].sort, messages(first).map { |row| row["id"] }.sort
    assert messages(first).all? { |row| row["project_root"] == @project && row["recipient"] == @lab_address }
    assert_equal "ok", first.dig("sources", "project:ace:hitl", "status")
    assert_equal first, observe
    @manager.create("Unrelated new report", type: "report", result: "success", to: "overseer")
    assert_equal first, observe, "project work must not revise the lab's inbox"
  end

  def test_project_does_not_recurse
    assert_equal({"events" => [], "sources" => {}}, observe(root: @project))
  end

  def test_missing_project_is_degraded_and_does_not_hide_other_reports
    own = @manager.create("Ready", type: "report", result: "success", to: "lab-overseer")
    @document["projects"] << {"id" => "missing", "path" => File.join(@root, "missing")}
    first = observe
    assert_equal [own.id], messages(first).map { |row| row["id"] }
    assert_equal "degraded", first.dig("sources", "project:missing:hitl", "status")
    assert_equal first, observe
    FileUtils.mkdir_p(File.join(@root, "missing"))
    assert_equal "ok", observe.dig("sources", "project:missing:hitl", "status")
  end
end
