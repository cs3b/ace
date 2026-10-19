# frozen_string_literal: true

require_relative "../test_helper"
require "shellwords"

module Organisms
  # Task 8xg.t.sbz.7.3 (L8.4): the installer must RECOGNIZE its own
  # interrupted installation — derived from the real artifacts the steps
  # read/write, no journal — and FINISH it: steps already done report
  # exists/converged without destructive rework, missing steps complete,
  # and foreign content is still refused at every step (a foreign lab is
  # never taken over or cleaned). These tests simulate mid-crash states
  # at each step boundary with REAL molecules (only the trusted-read
  # verification seam is stubbed, as in install_test) and assert the
  # convergence, the no-rework invariants (inode stability, preserved
  # content) and the refusal gates.
  class InstallResumeTest < Minitest::Test
    class StubResolver
      def initialize(documents)
        @documents = documents
      end

      def read_verified(path)
        @documents[path]
      end
    end

    # One full lab fixture: an account (reported exists through the
    # passwd seam — the "accounts phase already done" cut), one declared
    # directory, one key pair, one role, two projects cloned from a real
    # local origin, and manifest grants for both projects.
    def with_lab
      Dir.mktmpdir do |dir|
        origin = File.join(dir, "origin.git")
        `git init --bare #{origin.shellescape} >/dev/null 2>&1`
        skip "git unavailable" unless File.directory?(origin)

        home = File.join(dir, "home", "ace-worker")
        labs = File.join(dir, "labs")
        key_path = File.join(home, ".ssh", "id_ed25519")
        instructions = File.join(dir, "instructions.md")
        File.write(instructions, "# worker instructions\n")
        manifest_path = File.join(dir, "install.yml")
        auth_path = File.join(dir, "authorization.yml")

        File.write(manifest_path, <<~YAML)
          ---
          schema_version: 1
          machine: lab01
          accounts:
            - username: ace-worker
              role: worker
              home: #{home}
          directories:
            - path: #{labs}
              mode: "0750"
          keys:
            - account: ace-worker
              path: #{key_path}
          roles:
            - id: worker
              account: ace-worker
              instructions: #{instructions}
          projects:
            - id: atlas
              path: #{labs}/atlas
              remote: #{origin}
            - id: borealis
              path: #{labs}/borealis
              remote: #{origin}
          grants:
            ace-overseer: [atlas, borealis]
        YAML

        fixture = {
          "dir" => dir, "origin" => origin, "home" => home, "labs" => labs,
          "key" => key_path, "manifest" => manifest_path, "auth" => auth_path
        }
        yield fixture
      end
    end

    # A fresh Install organism per run (like a fresh CLI invocation),
    # with real molecules; only the trusted-read verification is stubbed
    # for the tmpdir paths and the passwd seam pins the account as
    # existing with the installer's own uid.
    def resume_run(fixture, dry_run: false)
      entry = FakeEntry.new(name: "ace-worker", uid: Process.uid, gid: Process.gid,
        dir: fixture["home"])
      lookup = ->(name) { name == "ace-worker" ? entry : nil }
      # Pre-run snapshot for the grants molecule (convergence decides
      # against the state it found); the class-method seam reads the
      # manifest from the snapshot and everything else from DISK, so
      # install's final verify stage reads the grants document the run
      # just wrote.
      snapshot = {fixture["manifest"] => File.read(fixture["manifest"])}
      snapshot[fixture["auth"]] = File.read(fixture["auth"]) if File.exist?(fixture["auth"])
      resolver = StubResolver.new(snapshot)
      Ace::Lab::Molecules::GrantResolver.stub :read_verified,
        ->(path) do
          path == fixture["manifest"] ? snapshot[path] : (File.file?(path) ? File.read(path) : nil)
        end do
        Ace::Lab::Organisms::Install.new(
          manifest_path: fixture["manifest"], account_lookup: lookup, platform: "linux",
          grants: Ace::Lab::Molecules::GrantProvisioner.new(
            resolver: resolver, authorization_path: fixture["auth"]
          )
        ).call(dry_run: dry_run)
      end
    end

    # Crash cut helpers — build exactly the artifacts a step boundary
    # leaves behind, nothing more.

    def done_directories(fixture)
      FileUtils.mkdir_p(fixture["labs"])
      File.chmod(0o750, fixture["labs"])
    end

    def done_keys(fixture)
      ssh_dir = File.dirname(fixture["key"])
      FileUtils.mkdir_p(ssh_dir)
      File.chmod(0o700, ssh_dir)
      system("ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-C", "ace-worker@lab01",
        "-f", fixture["key"], out: File::NULL, err: File::NULL)
      skip "ssh-keygen unavailable" unless File.file?(fixture["key"])
    end

    def done_repository(fixture, id)
      `git clone -q #{fixture['origin'].shellescape} #{File.join(fixture['labs'], id).shellescape} >/dev/null 2>&1`
      skip "git clone failed" unless File.directory?(File.join(fixture["labs"], id, ".git"))
    end

    def key_fingerprint(path)
      out = `ssh-keygen -lf #{path.shellescape} 2>/dev/null`
      out[/SHA256:[A-Za-z0-9+\/=]+/]
    end

    def project_report(report, id)
      report["projects"].find { |entry| entry["project"] == id }
    end

    # --- Resume at each step boundary ---------------------------------

    def test_interrupted_before_directories_completes_the_same_install
      with_lab do |fixture|
        report = resume_run(fixture)

        assert_equal true, report["ok"], report.inspect
        # accounts phase already done (passwd seam): recognized, not reworked
        assert_equal "exists", report["prepare"]["accounts"].first["status"]
        # everything after the cut completes
        assert_equal "created", report["prepare"]["directories"].first["status"]
        assert_equal "created", report["prepare"]["keys"].first["status"]
        assert_equal "verified", report["prepare"]["roles"].first["status"]
        assert_equal "created", project_report(report, "atlas")["repository"]["status"]
        assert_equal "created", project_report(report, "borealis")["repository"]["status"]
        assert_equal "created", report["grants"]["status"]
        assert File.directory?(File.join(fixture["labs"], "atlas", ".ace-tasks", "_overseer"))
        assert File.file?(File.join(fixture["labs"], "borealis", ".ace", "lab", "config.yml"))
        assert_equal({"ace-overseer" => {"projects" => %w[atlas borealis]}},
          YAML.load_file(fixture["auth"])["principals"])
      end
    end

    def test_interrupted_after_directories_reports_exists_without_rework
      with_lab do |fixture|
        done_directories(fixture)
        inode = File.stat(fixture["labs"]).ino

        report = resume_run(fixture)

        assert_equal true, report["ok"], report.inspect
        assert_equal "exists", report["prepare"]["directories"].first["status"]
        # no destructive rework: the converged directory is the same inode
        assert_equal inode, File.stat(fixture["labs"]).ino
        assert_equal 0o750, File.stat(fixture["labs"]).mode & 0o7777
        assert_equal "created", report["prepare"]["keys"].first["status"]
      end
    end

    def test_interrupted_after_keys_reports_exists_with_stable_fingerprint
      with_lab do |fixture|
        done_directories(fixture)
        done_keys(fixture)
        inode = File.stat(fixture["key"]).ino
        fingerprint = key_fingerprint("#{fixture["key"]}.pub")

        report = resume_run(fixture)

        assert_equal true, report["ok"], report.inspect
        key = report["prepare"]["keys"].first
        assert_equal "exists", key["status"]
        assert_equal fingerprint, key["fingerprint"]
        # the own key pair is not regenerated
        assert_equal inode, File.stat(fixture["key"]).ino
      end
    end

    def test_interrupted_mid_key_pair_regenerates_only_the_public_half
      with_lab do |fixture|
        done_directories(fixture)
        done_keys(fixture)
        private_inode = File.stat(fixture["key"]).ino
        # crash between writing the private and the public half
        File.delete("#{fixture["key"]}.pub")

        report = resume_run(fixture)

        assert_equal true, report["ok"], report.inspect
        assert_equal "exists", report["prepare"]["keys"].first["status"]
        assert File.file?("#{fixture["key"]}.pub")
        # the private half survives the repair untouched
        assert_equal private_inode, File.stat(fixture["key"]).ino
      end
    end

    def test_interrupted_after_first_project_finishes_the_second_without_rework
      with_lab do |fixture|
        done_directories(fixture)
        done_keys(fixture)
        done_repository(fixture, "atlas")
        marker = File.join(fixture["labs"], "atlas", "untracked-keep")
        File.write(marker, "worker content\n")

        report = resume_run(fixture)

        assert_equal true, report["ok"], report.inspect
        atlas = project_report(report, "atlas")
        borealis = project_report(report, "borealis")
        # own repository recognized: converged, worktree content kept
        assert_equal "exists", atlas["repository"]["status"]
        assert_equal "created", atlas["registry"]["status"]
        assert_equal "worker content", File.read(marker).strip
        # the missing project completes
        assert_equal "created", borealis["repository"]["status"]
        assert_equal "created", report["grants"]["status"]
      end
    end

    def test_interrupted_before_grants_only_writes_the_grants
      with_lab do |fixture|
        first = resume_run(fixture)
        assert_equal true, first["ok"]
        # crash before the grants step: everything else already converged
        File.delete(fixture["auth"])

        report = resume_run(fixture)

        assert_equal true, report["ok"], report.inspect
        assert_equal "exists", report["prepare"]["accounts"].first["status"]
        assert_equal "exists", report["prepare"]["directories"].first["status"]
        assert_equal "exists", report["prepare"]["keys"].first["status"]
        assert_equal "exists", project_report(report, "atlas")["repository"]["status"]
        assert_equal "exists", project_report(report, "borealis")["repository"]["status"]
        assert_equal "created", report["grants"]["status"]
        assert_equal({"ace-overseer" => {"projects" => %w[atlas borealis]}},
          YAML.load_file(fixture["auth"])["principals"])
      end
    end

    def test_partially_written_own_grants_converge_and_keep_foreign_sections
      with_lab do |fixture|
        first = resume_run(fixture)
        assert_equal true, first["ok"]
        # crash mid-grants: only one of the two projects got granted,
        # and the document carries an admin-owned adapter section
        File.write(fixture["auth"], <<~YAML)
          ---
          hitl:
            adapters:
              hermes: enabled
          principals:
            ace-overseer:
              projects:
              - atlas
        YAML

        report = resume_run(fixture)

        assert_equal true, report["ok"], report.inspect
        assert_equal "updated", report["grants"]["status"]
        assert_equal({"ace-overseer" => "updated"}, report["grants"]["principals"])
        document = YAML.load_file(fixture["auth"])
        assert_equal %w[atlas borealis], document["principals"]["ace-overseer"]["projects"]
        assert_equal({"adapters" => {"hermes" => "enabled"}}, document["hitl"])
      end
    end

    def test_ready_own_lab_re_run_is_a_converged_no_op
      with_lab do |fixture|
        first = resume_run(fixture)
        assert_equal true, first["ok"]
        auth_stat = File.stat(fixture["auth"])
        key_inode = File.stat(fixture["key"]).ino

        report = resume_run(fixture)

        assert_equal true, report["ok"], report.inspect
        assert_equal "exists", report["prepare"]["accounts"].first["status"]
        assert_equal "exists", report["prepare"]["directories"].first["status"]
        assert_equal "exists", report["prepare"]["keys"].first["status"]
        assert_equal "exists", project_report(report, "atlas")["repository"]["status"]
        assert_equal "exists", report["grants"]["status"]
        # no rework of the ready lab's artifacts
        assert_equal auth_stat.ino, File.stat(fixture["auth"]).ino
        assert_equal auth_stat.mtime, File.stat(fixture["auth"]).mtime
        assert_equal key_inode, File.stat(fixture["key"]).ino
        config = YAML.load_file(File.join(fixture["labs"], "atlas", ".ace", "lab", "config.yml"))
        assert_equal %w[atlas], config["topology"]["projects"].map { |project| project["id"] }
      end
    end

    # --- Foreign content is refused at every step ---------------------

    def test_foreign_project_directory_is_refused_without_cleanup
      with_lab do |fixture|
        done_directories(fixture)
        done_keys(fixture)
        foreign = File.join(fixture["labs"], "atlas")
        FileUtils.mkdir_p(foreign)
        File.write(File.join(foreign, "foreign.txt"), "someone else's data\n")

        report = resume_run(fixture)

        assert_equal false, report["ok"]
        atlas = project_report(report, "atlas")
        assert_equal "failed", atlas["repository"]["status"]
        assert_match(/refusing to take over a foreign location/, atlas["repository"]["message"])
        # not taken over, not cleaned
        assert_equal "someone else's data\n", File.read(File.join(foreign, "foreign.txt"))
        # isolation: the other project still completes…
        assert_equal true, project_report(report, "borealis")["ok"]
        # …but grants are gated over the failed install (no pretend success)
        assert_equal "failed", report["grants"]["status"]
        refute File.exist?(fixture["auth"])
      end
    end

    def test_foreign_repository_origin_is_refused_not_overwritten
      with_lab do |fixture|
        done_directories(fixture)
        done_keys(fixture)
        done_repository(fixture, "atlas")
        other_origin = File.join(fixture["dir"], "other.git")
        `git init --bare #{other_origin.shellescape} >/dev/null 2>&1`
        `git -C #{File.join(fixture['labs'], 'atlas').shellescape} remote set-url origin #{other_origin.shellescape} >/dev/null 2>&1`

        report = resume_run(fixture)

        assert_equal false, report["ok"]
        atlas = project_report(report, "atlas")
        assert_equal "failed", atlas["repository"]["status"]
        assert_match(/refusing to overwrite an existing registration/, atlas["repository"]["message"])
        # the foreign origin is untouched
        current = `git -C #{File.join(fixture['labs'], 'atlas').shellescape} remote get-url origin`.strip
        assert_equal other_origin, current
        assert_equal "failed", report["grants"]["status"]
      end
    end

    def test_foreign_declared_directory_gates_the_install_concretely
      with_lab do |fixture|
        target = File.join(fixture["dir"], "elsewhere")
        FileUtils.mkdir_p(target)
        File.symlink(target, fixture["labs"])

        report = resume_run(fixture)

        assert_equal false, report["ok"]
        directory = report["prepare"]["directories"].first
        assert_equal "failed", directory["status"]
        assert_match(/symbolic link; refusing/, directory["message"])
        # resume is not possible: the message says so concretely and the
        # dependents are named as dependency failures
        atlas = project_report(report, "atlas")
        assert_equal "failed", atlas["repository"]["status"]
        assert_match(/fix the prepare phase first/, atlas["repository"]["message"])
        assert_equal "failed", report["grants"]["status"]
        # nothing was taken over or cleaned
        assert File.symlink?(fixture["labs"])
        assert_empty Dir.children(target)
        refute File.exist?(fixture["auth"])
      end
    end

    def test_foreign_grants_document_refuses_even_over_own_partial_state
      with_lab do |fixture|
        done_directories(fixture)
        done_keys(fixture)
        foreign = YAML.dump({"principals" => {"operator" => {"projects" => %w[zephyr]}}})
        File.write(fixture["auth"], foreign)

        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          resume_run(fixture)
        end

        assert_match(/refusing to install over a foreign lab/, error.message)
        assert_match(/zephyr/, error.message)
        # refusal happens before any mutation: own partial state and the
        # foreign document both stay byte-identical
        assert_equal foreign, File.read(fixture["auth"])
        refute File.exist?(File.join(fixture["labs"], "atlas"))
      end
    end

    def test_dry_run_with_a_foreign_grants_document_refuses_identically
      with_lab do |fixture|
        done_directories(fixture)
        foreign = YAML.dump({"principals" => {"operator" => {"projects" => %w[zephyr]}}})
        File.write(fixture["auth"], foreign)

        # The guard runs before any dry_run branching: the prediction is
        # the same hard refusal, not a would_* preview.
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          resume_run(fixture, dry_run: true)
        end

        assert_match(/refusing to install over a foreign lab/, error.message)
        assert_equal foreign, File.read(fixture["auth"])
      end
    end

    # --- Dry-run parity on a partial state -----------------------------

    def test_dry_run_on_own_partial_state_predicts_the_exact_resume
      with_lab do |fixture|
        done_directories(fixture)
        done_keys(fixture)
        done_repository(fixture, "atlas")

        preview = resume_run(fixture, dry_run: true)

        assert_equal true, preview["ok"], preview.inspect
        assert_equal true, preview["dry_run"]
        assert_equal "exists", preview["prepare"]["accounts"].first["status"]
        assert_equal "exists", preview["prepare"]["directories"].first["status"]
        assert_equal "exists", preview["prepare"]["keys"].first["status"]
        assert_equal "exists", project_report(preview, "atlas")["repository"]["status"]
        assert_equal "would_create", project_report(preview, "borealis")["repository"]["status"]
        assert_equal "would_create", preview["grants"]["status"]
        # zero mutations in the preview
        refute File.exist?(File.join(fixture["labs"], "borealis"))
        refute File.exist?(fixture["auth"])

        # the wet resume lands exactly on the prediction
        wet = resume_run(fixture)
        assert_equal true, wet["ok"], wet.inspect
        assert_equal "exists", wet["prepare"]["directories"].first["status"]
        assert_equal "exists", project_report(wet, "atlas")["repository"]["status"]
        assert_equal "created", project_report(wet, "borealis")["repository"]["status"]
        assert_equal "created", wet["grants"]["status"]
      end
    end

    def test_dry_run_predicts_the_foreign_directory_refusal
      with_lab do |fixture|
        foreign = File.join(fixture["labs"], "atlas")
        FileUtils.mkdir_p(foreign)
        File.write(File.join(foreign, "foreign.txt"), "data\n")

        preview = resume_run(fixture, dry_run: true)

        assert_equal false, preview["ok"]
        assert_equal true, preview["dry_run"]
        atlas = project_report(preview, "atlas")
        assert_equal "failed", atlas["repository"]["status"]
        assert_match(/refusing to take over a foreign location/, atlas["repository"]["message"])
        assert_equal "failed", preview["grants"]["status"]
        # the preview itself mutates nothing
        assert_equal "data\n", File.read(File.join(foreign, "foreign.txt"))
        refute File.exist?(fixture["auth"])
      end
    end
  end
end
