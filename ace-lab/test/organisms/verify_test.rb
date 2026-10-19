# frozen_string_literal: true

require_relative "../test_helper"
require "shellwords"

module Organisms
  # Task 8xg.t.sbz.7.4 (L8.5): `ace-lab verify` proves the installed
  # lab is ready UNDER THE TARGET ACCOUNTS — accounts/login class,
  # directories, key pairs (fingerprint + modes + ownership), role
  # instruction readability, repository origin access, grant-based
  # project visibility, private+gitignored _overseer — read-only, from
  # the same artifacts install/resume derive truth from. These tests
  # use REAL molecules (install runs for real against a tmpdir lab;
  # only the trusted-read verification seam and the passwd seam are
  # stubbed, mirroring install_resume_test) and prove: a fresh install
  # verifies ready, a RESUMED install verifies with no hidden gaps,
  # and failures sit beside healthy data without hiding it or
  # blocking the remaining checks.
  class VerifyTest < Minitest::Test
    class StubResolver
      def initialize(documents)
        @documents = documents
      end

      def read_verified(path)
        @documents[path]
      end
    end

    # Full lab fixture: one account, one directory, one key pair, one
    # protocol role plus one file-path role, two projects from a real
    # local origin, manifest grants for both projects.
    def with_lab(role_instructions: "wfi://lab/worker")
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
              owner: ace-worker
              mode: "0750"
          keys:
            - account: ace-worker
              path: #{key_path}
          roles:
            - id: worker
              account: ace-worker
              instructions: #{role_instructions}
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
          "key" => key_path, "manifest" => manifest_path, "auth" => auth_path,
          "instructions" => instructions
        }
        yield fixture
      end
    end

    def passwd_entry(fixture, shell: "/bin/zsh")
      FakeEntry.new(name: "ace-worker", uid: Process.uid, gid: Process.gid,
        dir: fixture["home"], shell: shell)
    end

    def lookup_for(fixture, shell: "/bin/zsh")
      entry = passwd_entry(fixture, shell: shell)
      ->(name) { name == "ace-worker" ? entry : nil }
    end

    def install_run(fixture, lookup)
      documents = {fixture["manifest"] => File.read(fixture["manifest"])}
      documents[fixture["auth"]] = File.read(fixture["auth"]) if File.exist?(fixture["auth"])
      Ace::Lab::Molecules::GrantResolver.stub :read_verified, ->(path) { documents[path] } do
        Ace::Lab::Organisms::Install.new(
          manifest_path: fixture["manifest"], account_lookup: lookup, platform: "linux",
          grants: Ace::Lab::Molecules::GrantProvisioner.new(
            resolver: StubResolver.new(documents), authorization_path: fixture["auth"]
          )
        ).call
      end
    end

    def verify_run(fixture, lookup: lookup_for(fixture))
      Ace::Lab::Molecules::GrantResolver.stub :read_verified,
        ->(path) { File.file?(path) ? File.read(path) : nil } do
        Ace::Lab::Organisms::Verify.new(
          manifest_path: fixture["manifest"], account_lookup: lookup,
          authorization_path: fixture["auth"], platform: "linux"
        ).call
      end
    end

    def check(report, section, index = 0)
      report["checks"][section][index]
    end

    def key_fingerprint(path)
      out = `ssh-keygen -lf #{path.shellescape} 2>/dev/null`
      out[/SHA256:[A-Za-z0-9+\/=]+/]
    end

    # --- happy paths --------------------------------------------------

    def test_fresh_install_verifies_ready_under_the_target_account
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))

        report = verify_run(fixture)

        assert_equal true, report["ready"], report.inspect
        assert_equal 0, report["counts"]["fail"]
        assert_equal "pass", check(report, "accounts")["status"]
        assert_equal "pass", check(report, "directories")["status"]
        assert_equal "pass", check(report, "keys")["status"]
        assert_equal key_fingerprint("#{fixture["key"]}.pub"), check(report, "keys")["fingerprint"]
        assert_equal "pass", check(report, "roles")["status"]
        assert_equal "pass", check(report, "repositories")["status"]
        assert_equal fixture["origin"], check(report, "repositories")["origin"]
        assert_equal "pass", check(report, "grants", 1)["status"]
        assert_equal %w[atlas borealis], check(report, "grants", 1)["projects"]
        assert_equal "pass", check(report, "registry")["status"]
        assert_equal "pass", check(report, "overseer")["status"]
      end
    end

    def test_resumed_install_verifies_ready_with_no_hidden_gaps
      with_lab do |fixture|
        # crash cut: directories + keys + only atlas cloned, grants absent
        FileUtils.mkdir_p(fixture["labs"])
        File.chmod(0o750, fixture["labs"])
        ssh_dir = File.dirname(fixture["key"])
        FileUtils.mkdir_p(ssh_dir)
        File.chmod(0o700, ssh_dir)
        system("ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-C", "ace-worker@lab01",
          "-f", fixture["key"], out: File::NULL, err: File::NULL)
        skip "ssh-keygen unavailable" unless File.file?(fixture["key"])
        `git clone -q #{fixture['origin'].shellescape} #{File.join(fixture['labs'], 'atlas').shellescape} >/dev/null 2>&1`

        report = install_run(fixture, lookup_for(fixture))
        assert_equal true, report["ok"]

        verify = verify_run(fixture)
        assert_equal true, verify["ready"], verify.inspect
        assert_equal 0, verify["counts"]["fail"]
      end
    end

    # --- failure beside healthy data ----------------------------------

    def test_wrong_private_key_mode_fails_only_the_key_check
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        File.chmod(0o644, fixture["key"])

        report = verify_run(fixture)

        assert_equal false, report["ready"]
        key = check(report, "keys")
        assert_equal "fail", key["status"]
        assert_match(/mode is 0644 but 0600 is required/, key["reason"])
        # healthy data stays visible and passing
        assert_equal "pass", check(report, "accounts")["status"]
        assert_equal "pass", check(report, "roles")["status"]
        assert_equal "pass", check(report, "repositories")["status"]
        assert_equal "pass", check(report, "grants", 1)["status"]
      end
    end

    def test_swapped_public_key_fails_the_pair_usability_check
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        # generate a different key and swap only the public half
        other = File.join(fixture["dir"], "other")
        system("ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", other,
          out: File::NULL, err: File::NULL)
        FileUtils.cp("#{other}.pub", "#{fixture["key"]}.pub")
        File.chmod(0o644, "#{fixture["key"]}.pub")

        report = verify_run(fixture)

        assert_equal "fail", check(report, "keys")["status"]
        assert_nil check(report, "keys")["fingerprint"]
        assert_match(/not usable/, check(report, "keys")["reason"])
        assert_equal false, report["ready"]
      end
    end

    def test_missing_instructions_file_fails_only_the_role_check
      with_lab do |fixture|
        # switch the role binding to the absolute instructions path
        manifest = File.read(fixture["manifest"]).gsub("wfi://lab/worker", fixture["instructions"])
        File.write(fixture["manifest"], manifest)
        install_run(fixture, lookup_for(fixture))
        File.delete(fixture["instructions"])

        report = verify_run(fixture)

        role = check(report, "roles")
        assert_equal "fail", role["status"]
        assert_match(/does not exist/, role["reason"])
        assert_equal "pass", check(report, "accounts")["status"]
        assert_equal "pass", check(report, "keys")["status"]
        assert_equal false, report["ready"]
      end
    end

    def test_missing_account_fails_account_and_dependent_checks
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        missing = ->(_name) { nil }

        report = verify_run(fixture, lookup: missing)

        assert_equal "fail", check(report, "accounts")["status"]
        assert_match(/does not exist on this machine/, check(report, "accounts")["reason"])
        assert_equal "fail", check(report, "keys")["status"]
        assert_equal "fail", check(report, "roles")["status"]
        # project-level facts are independent of the passwd seam
        assert_equal "pass", check(report, "repositories")["status"]
        assert_equal "pass", check(report, "grants", 1)["status"]
        assert_equal false, report["ready"]
      end
    end

    def test_non_login_shell_blocks_readiness_under_the_target_account
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))

        report = verify_run(fixture, lookup: lookup_for(fixture, shell: "/usr/sbin/nologin"))

        assert_equal "fail", check(report, "accounts")["status"]
        assert_match(/non-login shell/, check(report, "accounts")["reason"])
        assert_equal false, report["ready"]
      end
    end

    def test_missing_grants_document_fails_visibility_without_hiding_health
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        File.delete(fixture["auth"])

        report = verify_run(fixture)

        document_check = report["checks"]["grants"].first
        assert_equal "fail", document_check["status"]
        assert_match(/is missing; no principal can see/, document_check["reason"])
        assert_equal "pass", check(report, "repositories")["status"]
        assert_equal "pass", check(report, "keys")["status"]
        assert_equal false, report["ready"]
      end
    end

    def test_partial_grants_fail_the_principal_with_the_missing_project
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        document = YAML.load_file(fixture["auth"])
        document["principals"]["ace-overseer"]["projects"] = %w[atlas]
        File.write(fixture["auth"], YAML.dump(document))

        report = verify_run(fixture)

        principal = check(report, "grants", 1)
        assert_equal "fail", principal["status"]
        assert_match(/missing: borealis/, principal["reason"])
        assert_equal %w[atlas], principal["projects"]
        assert_equal "pass", check(report, "registry", 1)["status"]
        assert_equal false, report["ready"]
      end
    end

    def test_overseer_folder_not_gitignored_fails_the_overseer_check
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        gitignore = File.join(fixture["labs"], "atlas", ".gitignore")
        File.write(gitignore, File.readlines(gitignore).reject { |l| l.include?("_overseer") }.join)

        report = verify_run(fixture)

        assert_equal "fail", check(report, "overseer")["status"]
        assert_match(/not ignored by Git/, check(report, "overseer")["reason"])
        assert_equal "pass", check(report, "overseer", 1)["status"]
        assert_equal false, report["ready"]
      end
    end

    def test_missing_registry_entry_fails_project_visibility
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        registry = File.join(fixture["labs"], "atlas", ".ace", "lab", "config.yml")
        File.delete(registry)

        report = verify_run(fixture)

        assert_equal "fail", check(report, "registry")["status"]
        assert_match(/is missing; the project is not visible/, check(report, "registry")["reason"])
        assert_equal "pass", check(report, "registry", 1)["status"]
        assert_equal false, report["ready"]
      end
    end

    def test_network_remote_origin_is_reported_unknown_but_not_a_failure
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        network = "git@forge.example:atlas/atlas.git"
        project = File.join(fixture["labs"], "atlas")
        system("git", "-C", project, "remote", "set-url", "origin", network,
          out: File::NULL, err: File::NULL)
        manifest = YAML.load_file(fixture["manifest"])
        manifest["projects"][0]["remote"] = network
        File.write(fixture["manifest"], YAML.dump(manifest))

        report = verify_run(fixture)

        repository = check(report, "repositories")
        assert_equal "unknown", repository["status"]
        assert_match(/requires network; not probed/, repository["reason"])
        assert_equal 1, report["counts"]["unknown"]
        # unknown does not block readiness
        assert_equal true, report["ready"]
      end
    end

    def test_foreign_origin_mismatch_is_a_concrete_failure
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        project = File.join(fixture["labs"], "atlas")
        system("git", "-C", project, "remote", "set-url", "origin",
          File.join(fixture["dir"], "elsewhere.git"), out: File::NULL, err: File::NULL)

        report = verify_run(fixture)

        repository = check(report, "repositories")
        assert_equal "fail", repository["status"]
        assert_match(/origin is '.*elsewhere\.git' but the manifest declares/, repository["reason"])
        assert_equal false, report["ready"]
      end
    end

    def test_unreachable_local_origin_is_a_concrete_failure
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        Dir.children(fixture["origin"]).each { |entry| FileUtils.rm_rf(File.join(fixture["origin"], entry)) }

        report = verify_run(fixture)

        repository = check(report, "repositories")
        assert_equal "fail", repository["status"]
        assert_match(/is not reachable/, repository["reason"])
        assert_equal false, report["ready"]
      end
    end

    def test_read_only_verification_mutates_nothing
      with_lab do |fixture|
        install_run(fixture, lookup_for(fixture))
        key_inode = File.stat(fixture["key"]).ino
        auth_bytes = File.binread(fixture["auth"])
        registry_bytes = File.binread(File.join(fixture["labs"], "atlas", ".ace", "lab", "config.yml"))

        report = verify_run(fixture)

        assert_equal true, report["ready"]
        assert_equal key_inode, File.stat(fixture["key"]).ino
        assert_equal auth_bytes, File.binread(fixture["auth"])
        assert_equal registry_bytes,
          File.binread(File.join(fixture["labs"], "atlas", ".ace", "lab", "config.yml"))
      end
    end
  end
end
