# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

module Organisms
  class ProjectAddTest < Minitest::Test
    def setup
      @tmp = Dir.mktmpdir("project-add")
      @source = File.join(@tmp, "atlas.git")
      Open3.capture3("git", "init", "--bare", "-q", @source)
      @path = File.join(@tmp, "atlas")
    end

    def teardown
      FileUtils.remove_entry(@tmp)
    end

    def organism(dry_run: false)
      Ace::Lab::Organisms::ProjectAdd.new(dry_run: dry_run)
    end

    def add(remote: @source, dry_run: false, id: "atlas")
      organism.call(id: id, path: @path, remote: remote, label: "Atlas", dry_run: dry_run)
    end

    def test_full_flow_makes_the_project_ready_for_team_work
      report = add

      assert report["ok"]
      assert_equal "created", report["repository"]["status"]
      assert_equal "created", report["overseer"]["status"]
      assert_equal "created", report["registry"]["status"]

      # Planner needs no manual directory fixing: the repository is a
      # real clone, the private overseer folder exists and is ignored.
      assert File.directory?(File.join(@path, ".git"))
      assert File.directory?(File.join(@path, ".ace-tasks", "_overseer"))
      _out, _err, status = Open3.capture3("git", "-C", @path, "check-ignore",
        ".ace-tasks/_overseer")
      assert status.success?, "_overseer must be git-ignored for the planner"

      # The registry is the project-tier lab config: the same cascade
      # document ace-lab status classifies.
      registry = File.join(@path, ".ace", "lab", "config.yml")
      assert File.file?(registry)
      classified = Ace::Lab::Molecules::ConfigStateClassifier.classify(
        documents: [{path: registry, document: YAML.safe_load_file(registry), defaults: false}],
        root: @path
      )
      assert_equal :configured, classified[:state]
      assert_equal 1, classified[:topology][:projects]
    end

    def test_registered_project_is_listed_by_the_topology_query_surface
      add

      document = YAML.safe_load_file(File.join(@path, ".ace", "lab", "config.yml"))
      document["authorization"] = {"principals" => {}}
      config = authorized_for_local(document)
      result = Ace::Lab::Organisms::TopologyService.new(config: config).projects

      assert result.ok?
      assert_equal ["atlas"], result.envelope.fetch("data").fetch("projects").map { |p| p["id"] }
    end

    def test_re_add_revalidates_without_destroying_anything
      add
      registry = File.join(@path, ".ace", "lab", "config.yml")
      gitignore = File.join(@path, ".gitignore")
      File.write(File.join(@path, ".ace-tasks", "_overseer", "note.md"), "overseer's own\n")
      File.write(gitignore, "#{File.read(gitignore)}# team addition\n")
      overseer_content = File.read(File.join(@path, ".ace-tasks", "_overseer", "note.md"))

      report = add

      assert report["ok"]
      assert_equal "exists", report["repository"]["status"]
      assert_equal "exists", report["overseer"]["status"]
      assert_equal "exists", report["registry"]["status"]
      assert_includes File.read(gitignore), "# team addition\n"
      assert_equal overseer_content, File.read(File.join(@path, ".ace-tasks", "_overseer", "note.md"))
    end

    def test_contradictory_remote_is_refused_and_nothing_changes
      add
      other = File.join(@tmp, "other.git")
      Open3.capture3("git", "init", "--bare", "-q", other)

      report = add(remote: other)

      refute report["ok"]
      assert_equal "failed", report["repository"]["status"]
      assert_includes report["repository"]["message"], "refusing to overwrite"
      # The registry still declares the original remote.
      document = YAML.safe_load_file(File.join(@path, ".ace", "lab", "config.yml"))
      assert_equal @source, document.dig("topology", "projects").first["remote"]
    end

    def test_dry_run_writes_nothing
      report = add(dry_run: true)

      assert report["ok"]
      assert report["dry_run"]
      assert_equal "would_create", report["repository"]["status"]
      assert_equal "would_create", report["overseer"]["status"]
      assert_equal "would_create", report["registry"]["status"]
      refute File.exist?(@path)
    end

    def test_failed_repository_fails_dependent_steps_instead_of_attempting_them
      FileUtils.mkdir_p(File.join(@path, "payload"))

      report = add

      refute report["ok"]
      assert_equal "failed", report["repository"]["status"]
      assert_equal "failed", report["overseer"]["status"]
      assert_includes report["overseer"]["message"], "repository not ready"
      assert_equal "failed", report["registry"]["status"]
      refute File.exist?(File.join(@path, ".ace"))
    end
  end
end
