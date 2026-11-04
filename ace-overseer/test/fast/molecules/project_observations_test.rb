# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/project_observations"

class ProjectObservationsTest < AceOverseerTestCase
  def setup
    @root = File.realpath(Dir.mktmpdir)
    @project = File.join(@root, "ace")
    Dir.mkdir(@project)
    @manifest = File.join(@root, "manifest.yml")
    File.write(@manifest, "fixture")
    @document = {"coordinator" => {"path" => @root}, "projects" => [{"id" => "ace", "path" => @project}]}
    @rows = {"schema" => "ace.hitl.observation/v1", "events" => [
      {"key" => "report-key", "id" => "report-id", "revision" => "rev-1", "type" => "report", "result" => "success"}],
      "settled" => [], "sources" => Ace::Overseer::Atoms::ObservationSources::REQUIRED.to_h { |name| [name, {"status" => "ok"}] }}
    @calls = []
    @now = 0
    @runner = lambda do |argv, **options|
      @calls << [argv, options]
      Struct.new(:stdout, :status, :oversized).new(JSON.generate(@rows), Struct.new(:success?).new(true), false)
    end
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def observe(root: @root)
    Ace::Lab.stub(:install_manifest_path, @manifest) do
      Ace::Overseer::Molecules::ProjectObservations.new(root: root, env: {"ACE_TOOLCHAIN" => "installed"},
        loader: -> { @document }, runner: @runner, clock: -> { @now }).call(owner: "overseer", scope: "all", limit: 500)
    end
  end

  def test_lab_reads_public_project_owner_and_preserves_report_identity
    first = observe
    assert_equal "report-id", first["events"].first["id"]
    assert_equal @project, first["events"].first["project_root"]
    assert_equal "report-key", first["events"].first["owner_key"]
    assert_equal "ok", first.dig("sources", "project:ace:hitl", "status")
    assert_equal first, observe, "unchanged source must not wake again"
    argv, options = @calls.first
    assert_equal ["observe", "--owner", "overseer", "--scope", "all", "--limit", "500"], argv.drop(1)
    assert_equal @project, options[:chdir]
    @rows["events"].first["revision"] = "rev-2"
    refute_equal first, observe
  end

  def test_project_observation_does_not_recurse_into_lab
    assert_equal({"events" => [], "sources" => {}}, observe(root: @project))
    assert_empty @calls
  end

  def test_incomplete_source_health_cannot_report_a_healthy_project
    @rows["sources"] = {}
    result = observe
    assert_equal "degraded", result.dig("sources", "project:ace", "status")
    assert_equal ["source-health"], result["events"].map { |row| row["type"] }
  end

  def test_many_stalled_projects_share_one_budget_and_still_return_health
    %w[b c d].each do |id|
      root = File.join(@root, id)
      Dir.mkdir(root)
      @document["projects"] << {"id" => id, "path" => root}
    end
    @runner = lambda do |argv, **options|
      @calls << [argv, options]
      @now += options.fetch(:timeout_s)
      raise Timeout::Error
    end
    result = observe
    assert_equal 1, @calls.length
    assert_equal 20, @now
    assert_equal 4, result["events"].size
    assert result["sources"].values.all? { |state| state["status"] == "degraded" }
  end

  def test_unavailable_project_is_visible_and_repeat_failure_has_stable_revision
    @runner = ->(*) { raise IOError, "private diagnostic text" }
    first = observe
    assert_equal "degraded", first.dig("sources", "project:ace", "status")
    assert_equal first, observe
    refute_includes JSON.generate(first), "private diagnostic text"
    assert_equal "source-health", first["events"].first["type"]
  end
end
