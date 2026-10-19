# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "etc"

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

    # --- LAB-2: executor ownership propagation -------------------------

    def test_non_root_installer_reports_ownership_skipped_but_still_ok
      entry = LabTestHelper::FakeEntry.new(name: "ace-worker", uid: Process.uid,
        gid: Process.gid, dir: File.join(@tmp, "home"), shell: "/bin/zsh")
      organism = Ace::Lab::Organisms::ProjectAdd.new(account_lookup: ->(_) { entry })

      report = organism.call(id: "atlas", path: @path, remote: @source, owner: "ace-worker")

      assert report["ok"], report.inspect
      assert_equal "skipped", report["owner"]["status"]
      assert_match(/not root/, report["owner"]["message"])
      assert_equal Process.uid, File.stat(@path).uid
    end

    def test_unknown_owner_account_fails_the_owner_step
      organism = Ace::Lab::Organisms::ProjectAdd.new(account_lookup: ->(_) { nil })

      report = organism.call(id: "atlas", path: @path, remote: @source, owner: "ghost")

      refute report["ok"]
      assert_equal "failed", report["owner"]["status"]
      assert_match(/account 'ghost' does not exist/, report["owner"]["message"])
    end

    def test_root_installer_propagates_ownership_with_correct_chown_arguments
      entry = LabTestHelper::FakeEntry.new(name: "ace-worker", uid: 4242,
        gid: 1042, dir: File.join(@tmp, "home"), shell: "/bin/zsh")
      chowned = []
      organism = Ace::Lab::Organisms::ProjectAdd.new(
        account_lookup: ->(_) { entry },
        chown: ->(uid, gid, path) { chowned << [uid, gid, path] }
      )

      report = nil
      Process.stub :uid, 0 do
        report = organism.call(id: "atlas", path: @path, remote: @source, owner: "ace-worker")
      end

      assert report["ok"], report.inspect
      assert_equal "propagated", report["owner"]["status"]
      assert_equal [[4242, 1042, @path]], chowned
    end

    # FINAL-LAB1: the production constructor must resolve a declared
    # owner through the REAL system passwd — a nil default lookup
    # classified every existing owner account as nonexistent. Reproduce
    # with the actual current OS account (no injected lookup seam).
    def test_production_constructor_resolves_the_real_declared_owner
      owner = Etc.getpwuid(Process.uid).name

      report = Ace::Lab::Organisms::ProjectAdd.new.call(
        id: "atlas", path: @path, remote: @source, owner: owner
      )

      assert report["ok"], report.inspect
      refute_equal "failed", report["owner"]["status"]
    end

    # A root uid match on the project root proves nothing about the
    # generated children (root may have created `.ace/lab/config.yml`
    # mode 0600 inside with its own uid): propagation must always
    # converge the tree, never skip on a matching root uid.
    def test_root_installer_repropagates_even_when_the_root_already_has_the_target_uid
      entry = LabTestHelper::FakeEntry.new(name: "ace-worker", uid: Process.uid,
        gid: Process.gid, dir: File.join(@tmp, "home"), shell: "/bin/zsh")
      chowned = []
      organism = Ace::Lab::Organisms::ProjectAdd.new(
        account_lookup: ->(_) { entry },
        chown: ->(uid, gid, path) { chowned << [uid, gid, path] }
      )

      report = nil
      Process.stub :uid, 0 do
        report = organism.call(id: "atlas", path: @path, remote: @source, owner: "ace-worker")
      end

      assert report["ok"], report.inspect
      assert_equal "propagated", report["owner"]["status"]
      assert_equal [[Process.uid, Process.gid, @path]], chowned
    end

    # --- FINAL-LAB2: hitl declarations become runtime routes ----------

    def test_hitl_adapter_declarations_install_runtime_routes
      adapters = [{"id" => "console", "kind" => "hitl", "command" => nil,
                   "config" => {"runtime" => "tmux"}}]

      report = organism.call(id: "atlas", path: @path, remote: @source, hitl_adapters: adapters)

      assert report["ok"], report.inspect
      assert_equal "created", report["hitl"]["status"]
      document = YAML.safe_load_file(File.join(@path, ".ace", "hitl", "config.yml"))
      assert_equal [{"adapter" => "console", "runtime" => "tmux"}],
        document.dig("hitl", "adapters", "routes")
    end

    def test_re_add_keeps_converged_hitl_routes_and_preserves_foreign_settings
      adapters = [{"id" => "console", "kind" => "hitl", "command" => nil, "config" => {}}]
      organism.call(id: "atlas", path: @path, remote: @source, hitl_adapters: adapters)
      path = File.join(@path, ".ace", "hitl", "config.yml")
      document = YAML.safe_load_file(path)
      document["hitl"]["root_dir"] = ".ace-local/hitl"
      File.write(path, YAML.dump(document))

      report = organism.call(id: "atlas", path: @path, remote: @source, hitl_adapters: adapters)

      assert report["ok"], report.inspect
      assert_equal "exists", report["hitl"]["status"]
      document = YAML.safe_load_file(path)
      assert_equal [{"adapter" => "console"}], document.dig("hitl", "adapters", "routes")
      assert_equal ".ace-local/hitl", document.dig("hitl", "root_dir")
    end

    def test_unparseable_hitl_config_is_refused_not_overwritten
      adapters = [{"id" => "console", "kind" => "hitl", "command" => nil, "config" => {}}]
      path = File.join(@path, ".ace", "hitl", "config.yml")
      organism.call(id: "atlas", path: @path, remote: @source)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "::not yaml::\n\t- broken")

      report = organism.call(id: "atlas", path: @path, remote: @source, hitl_adapters: adapters)

      refute report["ok"], report.inspect
      assert_equal "failed", report["hitl"]["status"]
      assert_match(/could not be parsed as YAML/, report["hitl"]["message"])
    end

    def test_without_hitl_adapters_the_step_is_skipped
      report = add

      assert report["ok"]
      assert_equal "skipped", report["hitl"]["status"]
      assert_nil report["hitl"]["message"]
    end

    def test_dry_run_predicts_hitl_routes_without_writing
      adapters = [{"id" => "console", "kind" => "hitl", "command" => nil, "config" => {}}]

      report = organism.call(id: "atlas", path: @path, remote: @source,
        hitl_adapters: adapters, dry_run: true)

      assert report["ok"]
      assert_equal "would_create", report["hitl"]["status"]
      refute File.exist?(File.join(@path, ".ace", "hitl", "config.yml"))
    end

    def test_no_declared_owner_leaves_ownership_untouched
      report = add

      assert report["ok"]
      assert_equal "skipped", report["owner"]["status"]
      assert_nil report["owner"]["message"]
    end

    def test_gitignore_symlink_is_refused_without_escaping_the_project
      Dir.mktmpdir do |dir|
        repo = File.join(dir, "repo")
        Open3.capture3("git", "clone", "-q", @source, repo)
        victim = File.join(dir, "outside")
        File.write(victim, "outside file\n")
        File.symlink(victim, File.join(repo, ".gitignore"))

        report = Ace::Lab::Organisms::ProjectAdd.new.call(id: "example", path: repo, remote: @source)

        refute report["ok"], report["overseer"].inspect
        assert_equal "failed", report["overseer"]["status"]
        assert_equal "outside file\n", File.read(victim)
      end
    end
  end
end
