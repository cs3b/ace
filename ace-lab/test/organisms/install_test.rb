# frozen_string_literal: true

require_relative "../test_helper"
require "shellwords"

module Organisms
  class InstallTest < Minitest::Test
    # Records every call so orchestration order, argument threading and
    # the before-any-mutation guarantee are observable.
    class FakePrepare
      attr_reader :calls

      def initialize(report)
        @report = report
        @calls = []
      end

      def call(dry_run:)
        @calls << dry_run
        @report
      end
    end

    class FakeProjectAdd
      attr_reader :calls

      def initialize(reports_by_id)
        @reports_by_id = reports_by_id
        @calls = []
      end

      def call(id:, path:, remote:, label:, owner:, dry_run:)
        @calls << {id: id, path: path, remote: remote, label: label, owner: owner, dry_run: dry_run}
        @reports_by_id.fetch(id)
      end
    end

    # Final-verify stage stub: the real Verify organism is exercised in
    # verify_test / install_resume_test; orchestration tests inject a
    # converged verdict so the fakes' fictional paths are not probed.
    class FakeVerify
      attr_reader :calls

      def initialize(report = {"ready" => true, "counts" => {"pass" => 1, "fail" => 0, "unknown" => 0}})
        @report = report
        @calls = 0
      end

      def call
        @calls += 1
        @report
      end
    end

    class StubResolver
      def initialize(documents)
        @documents = documents
      end

      def read_verified(path)
        @documents[path]
      end
    end

    OK_PREPARE = {
      "ok" => true, "dry_run" => false, "machine" => "lab01",
      "accounts" => [], "directories" => [], "keys" => [], "roles" => []
    }.freeze

    def ok_project(id)
      {"ok" => true, "dry_run" => false, "project" => id, "path" => "/lab/#{id}",
       "remote" => nil,
       "repository" => {"path" => "/lab/#{id}", "status" => "created", "message" => nil},
       "overseer" => {"dir" => "/lab/#{id}/.ace-tasks/_overseer", "status" => "created", "message" => nil},
       "registry" => {"path" => "/lab/#{id}/.ace/lab/config.yml", "status" => "created", "message" => nil}}
    end

    def manifest_yaml(dir, projects: true, grants: true)
      <<~YAML.gsub("/INSTALL-ROOT", dir)
        ---
        schema_version: 1
        machine: lab01
        accounts: []
        directories: []
        keys: []
        roles: []
        #{"projects:" if projects}
        - id: atlas
          path: /INSTALL-ROOT/atlas
          remote: /INSTALL-ROOT/origin.git
          label: Atlas platform
        - id: borealis
          path: /INSTALL-ROOT/borealis
          remote: /INSTALL-ROOT/origin.git
        #{"grants:" if grants}#{"\n  ace-overseer: [atlas, borealis]" if grants}
      YAML
    end

    # Serves the manifest AND the trusted authorization document through
    # one read_verified stub keyed by path: the manifest loader goes
    # through the real GrantResolver class method, the grants molecule
    # through an injected resolver.
    def with_install(authorization: nil, manifest: nil, prepare: nil, project_add: nil,
      verify: FakeVerify.new, platform: "linux", dry_run: nil, &block)
      Dir.mktmpdir do |dir|
        manifest ||= manifest_yaml(dir)
        manifest_path = "/etc/lab/ace-lab/install.yml"
        auth_path = File.join(dir, "authorization.yml")
        File.write(auth_path, authorization) if authorization
        documents = {manifest_path => manifest, auth_path => authorization}
        resolver = StubResolver.new(documents)
        grants = Ace::Lab::Molecules::GrantProvisioner.new(
          resolver: resolver, authorization_path: auth_path
        )
        lookup = ->(name) { FakeEntry.new(name: name, uid: Process.uid, gid: Process.gid,
          dir: File.join(dir, "home", name)) }
        Ace::Lab::Molecules::GrantResolver.stub :read_verified,
          ->(path) { documents[path] } do
          organism = Ace::Lab::Organisms::Install.new(
            manifest_path: manifest_path, account_lookup: lookup, platform: platform,
            prepare: prepare, project_add: project_add, grants: grants, verify: verify
          )
          block.call(organism, dir, auth_path)
        end
      end
    end

    def test_happy_path_orchestrates_prepare_projects_and_grants
      prepare = FakePrepare.new(OK_PREPARE.merge("ok" => true))
      project_add = FakeProjectAdd.new("atlas" => ok_project("atlas"),
        "borealis" => ok_project("borealis"))

      with_install(prepare: prepare, project_add: project_add) do |organism, dir, auth_path|
        report = organism.call

        assert_equal true, report["ok"]
        assert_equal false, report["dry_run"]
        assert_equal "lab01", report["machine"]
        assert_equal %w[ok dry_run machine manifest prepare projects grants adapters tools verify],
          report.keys
        assert_equal [false], prepare.calls
        assert_equal [{id: "atlas", path: File.join(dir, "atlas"),
                       remote: File.join(dir, "origin.git"), label: "Atlas platform", owner: nil,
                       dry_run: false},
                      {id: "borealis", path: File.join(dir, "borealis"),
                       remote: File.join(dir, "origin.git"), label: nil, owner: nil, dry_run: false}],
          project_add.calls
        assert_equal true, report["verify"]["ready"]
        assert_empty report["adapters"]
        assert_empty report["tools"]
        assert_equal "created", report["grants"]["status"]
        assert_equal({"ace-overseer" => "created"}, report["grants"]["principals"])
        assert_equal({"ace-overseer" => {"projects" => %w[atlas borealis]}},
          YAML.load_file(auth_path)["principals"])
      end
    end

    def test_dry_run_propagates_to_every_molecule_and_writes_nothing
      prepare = FakePrepare.new(OK_PREPARE.merge("ok" => true, "dry_run" => true))
      project_add = FakeProjectAdd.new("atlas" => ok_project("atlas").merge("dry_run" => true),
        "borealis" => ok_project("borealis").merge("dry_run" => true))

      with_install(prepare: prepare, project_add: project_add) do |organism, _dir, auth_path|
        report = organism.call(dry_run: true)

        assert_equal true, report["ok"]
        assert_equal true, report["dry_run"]
        assert_equal [true], prepare.calls
        assert project_add.calls.all? { |call| call[:dry_run] == true }
        assert_equal "would_create", report["grants"]["status"]
        refute File.exist?(auth_path)
      end
    end

    def test_foreign_labs_are_refused_before_any_mutation
      prepare = FakePrepare.new(OK_PREPARE)
      authorization = YAML.dump({"principals" => {"operator" => {"projects" => %w[zephyr]}}})

      with_install(authorization: authorization, prepare: prepare,
        project_add: FakeProjectAdd.new({})) do |organism, _dir, auth_path|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          organism.call
        end

        assert_match(/refusing to install over a foreign lab/, error.message)
        assert_match(/zephyr/, error.message)
        # before ANY mutation: prepare never ran and the trusted
        # document is byte-identical
        assert_empty prepare.calls
        assert_equal authorization, File.read(auth_path)
      end
    end

    def test_failed_prepare_fails_projects_and_grants_as_dependencies
      failed_prepare = OK_PREPARE.merge("ok" => false)
      project_add = FakeProjectAdd.new({})

      with_install(prepare: FakePrepare.new(failed_prepare), project_add: project_add) do |organism, _dir, auth_path|
        report = organism.call

        assert_equal false, report["ok"]
        assert_empty project_add.calls
        %w[atlas borealis].each do |id|
          project = report["projects"].find { |entry| entry["project"] == id }
          assert_equal false, project["ok"]
          assert_match(/fix the prepare phase first/, project["repository"]["message"])
          assert_equal "failed", project["registry"]["status"]
        end
        assert_equal "failed", report["grants"]["status"]
        assert_match(/fix the failing steps first/, report["grants"]["message"])
        refute File.exist?(auth_path)
      end
    end

    def test_one_failing_project_does_not_block_the_others_but_gates_grants
      prepare = FakePrepare.new(OK_PREPARE)
      project_add = FakeProjectAdd.new("atlas" => ok_project("atlas"),
        "borealis" => ok_project("borealis").merge("ok" => false))

      with_install(prepare: prepare, project_add: project_add) do |organism, _dir, auth_path|
        report = organism.call

        assert_equal false, report["ok"]
        # isolation: both projects were attempted
        assert_equal 2, project_add.calls.size
        assert_equal true, report["projects"].first["ok"]
        assert_equal false, report["projects"].last["ok"]
        # grants are configured only for a converged install
        assert_equal "failed", report["grants"]["status"]
        refute File.exist?(auth_path)
      end
    end

    def test_dry_run_with_failed_prepare_marks_every_dependency_failed_project
      prepare = FakePrepare.new(OK_PREPARE.merge("ok" => false))
      project_add = FakeProjectAdd.new({})

      with_install(prepare: prepare, project_add: project_add) do |organism, _dir, auth_path|
        report = organism.call(dry_run: true)

        assert_equal false, report["ok"]
        assert_equal true, report["dry_run"]
        assert_empty project_add.calls
        report["projects"].each do |project|
          assert_equal true, project["dry_run"],
            "dependency-failed projects must carry the effective dry-run value"
          assert_equal "failed", project["repository"]["status"]
        end
        gated = report["grants"]
        assert_equal "failed", gated["status"]
        assert_equal true, gated["dry_run"]
        assert_empty gated["kept"]
        refute File.exist?(auth_path)
      end
    end

    def test_manifest_without_grants_never_creates_the_authorization_document
      prepare = FakePrepare.new(OK_PREPARE)
      project_add = FakeProjectAdd.new("atlas" => ok_project("atlas"),
        "borealis" => ok_project("borealis"))

      Dir.mktmpdir do |dir|
        manifest = manifest_yaml(dir, grants: false)
        auth_path = File.join(dir, "authorization.yml")
        manifest_path = "/etc/lab/ace-lab/install.yml"
        grants = Ace::Lab::Molecules::GrantProvisioner.new(
          resolver: StubResolver.new({}), authorization_path: auth_path
        )
        Ace::Lab::Molecules::GrantResolver.stub :read_verified,
          ->(path) { path == manifest_path ? manifest : nil } do
          organism = Ace::Lab::Organisms::Install.new(
            manifest_path: manifest_path, platform: "linux",
            prepare: prepare, project_add: project_add, grants: grants, verify: FakeVerify.new
          )
          report = organism.call

          assert_equal true, report["ok"], report.inspect
          assert_equal "skipped", report["grants"]["status"]
          assert_empty report["grants"]["kept"]
          refute File.exist?(auth_path)
        end
      end
    end

    def test_re_run_over_own_converged_lab_converges_without_rewriting
      # The fixture carries an admin comment and is NOT byte-identical to
      # what YAML.dump would emit, so a rewrite would be observable in
      # the inode/mtime and the content — a converged re-run changes
      # neither.
      authorization = <<~YAML
        # managed by ops — do not reformat
        ---
        principals:
          ace-overseer:
            projects:
            - atlas
            - borealis
      YAML
      prepare = FakePrepare.new(OK_PREPARE)
      project_add = FakeProjectAdd.new("atlas" => ok_project("atlas"),
        "borealis" => ok_project("borealis"))

      with_install(authorization: authorization, prepare: prepare,
        project_add: project_add) do |organism, _dir, auth_path|
        before = File.stat(auth_path)
        report = organism.call

        assert_equal true, report["ok"]
        assert_equal "exists", report["grants"]["status"]
        assert_equal({"ace-overseer" => "exists"}, report["grants"]["principals"])
        after = File.stat(auth_path)
        assert_equal before.ino, after.ino
        assert_equal before.mtime, after.mtime
        assert_equal authorization, File.read(auth_path)
      end
    end

    def test_invalid_manifest_is_a_classified_error
      with_install(manifest: "---\nschema_version: 2\nmachine: lab01\n") do |organism|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          organism.call
        end

        assert_match(/invalid lab install manifest/, error.message)
      end
    end

    # Real molecules end-to-end (no orchestration fakes): a fresh
    # environment converges — prepare creates the declared directory,
    # both projects clone from a real local origin, and the trusted
    # grants document is written — proving the wiring, not just the
    # fakes' contracts.
    def test_full_flow_with_real_molecules_on_a_fresh_environment
      Dir.mktmpdir do |dir|
        origin = File.join(dir, "origin.git")
        `git init --bare #{origin.shellescape} >/dev/null 2>&1`
        skip "git unavailable" unless File.directory?(origin)

        manifest_path = File.join(dir, "install.yml")
        File.write(manifest_path, <<~YAML)
          ---
          schema_version: 1
          machine: lab01
          accounts: []
          directories:
            - path: #{dir}/labs
              mode: "0750"
          keys: []
          roles: []
          projects:
            - id: atlas
              path: #{dir}/labs/atlas
              remote: #{origin}
          grants:
            ace-overseer: [atlas]
        YAML
        auth_path = File.join(dir, "authorization.yml")
        grants = Ace::Lab::Molecules::GrantProvisioner.new(
          resolver: StubResolver.new(manifest_path => File.read(manifest_path)),
          authorization_path: auth_path
        )
        # The manifest's trusted-ownership verification is stubbed only
        # for reading (the tmpdir file is not root-owned); every
        # downstream molecule runs for real.
        Ace::Lab::Molecules::GrantResolver.stub :read_verified,
          ->(path) { File.file?(path) ? File.read(path) : nil } do
          organism = Ace::Lab::Organisms::Install.new(
            manifest_path: manifest_path, platform: "linux", grants: grants,
            verify: Ace::Lab::Organisms::Verify.new(
              manifest_path: manifest_path, platform: "linux", authorization_path: auth_path
            )
          )

          report = organism.call

          assert_equal true, report["ok"], report.inspect
          assert File.directory?(File.join(dir, "labs", "atlas", ".ace-tasks", "_overseer"))
          assert File.file?(File.join(dir, "labs", "atlas", ".ace", "lab", "config.yml"))
          assert_equal({"ace-overseer" => {"projects" => %w[atlas]}},
            YAML.load_file(auth_path)["principals"])
          # re-run converges without duplicates
          documents = {manifest_path => File.read(manifest_path), auth_path => File.read(auth_path)}
          grants = Ace::Lab::Molecules::GrantProvisioner.new(
            resolver: StubResolver.new(documents), authorization_path: auth_path
          )
          second = Ace::Lab::Organisms::Install.new(
            manifest_path: manifest_path, platform: "linux", grants: grants,
            verify: Ace::Lab::Organisms::Verify.new(
              manifest_path: manifest_path, platform: "linux",
              authorization_path: auth_path
            )
          ).call
          assert_equal true, second["ok"]
          assert_equal "exists", second["grants"]["status"]
          config = YAML.load_file(File.join(dir, "labs", "atlas", ".ace", "lab", "config.yml"))
          assert_equal 1, config["topology"]["projects"].size
        end
      end
    end
  end
end

  # --- review round 2: verify stage never crashes the install ----------

  class CrashingVerify
    def call
      raise "boom from verify internals"
    end
  end

  def test_unexpected_verify_crash_is_a_classified_failed_stage_not_a_raw_error
    with_install(verify: CrashingVerify.new) do |organism, _dir, _auth|
      report = organism.call

      refute report["ok"]
      assert_equal false, report["verify"]["ready"]
      assert_equal "failed", report["verify"]["status"]
      assert_match(/RuntimeError: boom from verify internals/, report["verify"]["message"])
    end
  end
