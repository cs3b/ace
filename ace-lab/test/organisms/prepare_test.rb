# frozen_string_literal: true

require_relative "../test_helper"

module Organisms
  class PrepareTest < Minitest::Test
    def self_entry(username, dir = "/home/#{username}")
      FakeEntry.new(name: username, uid: Process.uid, gid: Process.gid, dir: dir)
    end

    MANIFEST = <<~YAML
      ---
      schema_version: 1
      machine: lab01
      accounts:
        - username: ace-worker
          role: worker
          create: false
          home: /srv/nonexistent-labs-root/home/ace-worker
      directories:
        - path: /srv/nonexistent-labs-root/labs
          owner: ace-worker
          mode: "0750"
      keys:
        - account: ace-worker
      roles:
        - id: worker
          account: ace-worker
          instructions: wfi://assign/work
    YAML

    # The trusted-read seam is stubbed at the GrantResolver boundary: the
    # loader's fail-closed behavior has its own tests. Directories point
    # under a nonexistent root so the real filesystem tests exercise the
    # tmpdir paths created per test below. The passwd entry matches the
    # gsub'd manifest home so existing accounts report no home drift.
    def with_manifest(yaml = MANIFEST, lookup: nil, **options, &block)
      Dir.mktmpdir do |dir|
        manifest = yaml.gsub("/srv/nonexistent-labs-root", dir)
        lookup ||= ->(name) { self_entry(name, File.join(dir, "home", name)) }
        Ace::Lab::Molecules::GrantResolver.stub :read_verified, manifest do
          organism = Ace::Lab::Organisms::Prepare.new(
            manifest_path: "/etc/lab/ace-lab/install.yml",
            account_lookup: lookup,
            platform: "linux",
            **options
          )
          block.call(organism, dir)
        end
      end
    end

    def test_full_manifest_aggregates_ok_in_fixed_section_order
      with_manifest do |organism, dir|
        report = organism.call

        assert_equal true, report["ok"]
        assert_equal false, report["dry_run"]
        assert_equal "lab01", report["machine"]
        assert_equal "/etc/lab/ace-lab/install.yml", report["manifest"]
        assert_equal ["ok", "dry_run", "machine", "manifest", "accounts", "directories", "keys", "roles"],
          report.keys
        assert_equal [{"username" => "ace-worker", "status" => "exists",
                       "uid" => Process.uid, "message" => nil}], report["accounts"]
        assert_equal "created", report["directories"].first["status"]
        assert_equal "created", report["keys"].first["status"]
        assert_match(/\ASHA256:/, report["keys"].first["fingerprint"])
        assert_equal "verified", report["roles"].first["status"]
        assert File.directory?(File.join(dir, "labs"))
      end
    end

    def test_account_failure_fails_dependent_keys_and_roles_not_ok
      with_manifest(lookup: ->(_name) { nil }) do |organism, dir|
        report = organism.call

        assert_equal false, report["ok"]
        assert_equal "failed", report["accounts"].first["status"]
        assert_match(/does not exist/, report["accounts"].first["message"])
        key = report["keys"].first
        assert_equal "failed", key["status"]
        assert_match(/account 'ace-worker' is not available; fix the account phase first/, key["message"])
        role = report["roles"].first
        assert_equal "failed", role["status"]
        assert_match(/fix the account phase first/, role["message"])
        # no key material was created for a failed account
        refute File.exist?(File.join(dir, "home", "ace-worker", ".ssh"))
      end
    end

    def test_dry_run_predicts_all_sections_without_filesystem_mutation
      with_manifest(dry_run: true) do |organism, dir|
        report = organism.call

        assert_equal "would_create", report["directories"].first["status"]
        assert_equal "would_create", report["keys"].first["status"]
        assert_equal true, report["dry_run"]
        # dry run reports protocol roles as verified (read-only check)
        assert_equal "verified", report["roles"].first["status"]
        refute File.exist?(File.join(dir, "labs"))
        refute File.exist?(File.join(dir, "home"))
      end
    end

    # Round-3 MEDIUM: a permanently-failed owner account must turn the
    # missing-directory prediction into the wet run's owner_unavailable
    # failure — dry-run stays a faithful prediction (QA 4).
    def test_dry_run_failed_owner_account_predicts_directory_failure_not_would_create
      with_manifest(lookup: ->(_name) { nil }, dry_run: true) do |organism, dir|
        report = organism.call

        assert_equal "failed", report["accounts"].first["status"]
        directory = report["directories"].first
        assert_equal "failed", directory["status"]
        assert_match(/owner account 'ace-worker' is not available/, directory["message"])
        assert_match(/fix the account phase first/, directory["message"])
        refute File.exist?(File.join(dir, "labs"))
      end
    end

    # Round-3 LOW: linux uid-lag edge — an account created whose uid is
    # not yet resolvable did NOT fail the account phase, so its keys
    # must not claim "fix the account phase first" (QA wording).
    def test_created_but_unresolved_account_fails_keys_with_rerun_message
      with_manifest(
        MANIFEST.gsub("create: false", "create: true"),
        lookup: ->(_name) { nil },
        privileged: -> { true },
        runner: ->(_argv) { {"status" => "ok", "out" => "", "err" => ""} }
      ) do |organism, _dir|
        report = organism.call

        account = report["accounts"].first
        assert_equal "created", account["status"]
        assert_nil account["uid"]
        key = report["keys"].first
        assert_equal "failed", key["status"]
        assert_match(/was created but its uid is not yet resolvable; rerun ace-lab prepare/,
          key["message"])
        refute_match(/fix the account phase first/, key["message"])
      end
    end

    # The fresh-machine flow dry-run exists to predict: the account does
    # not exist in passwd yet (lookup nil, exactly what production's
    # Etc.getpwnam returns), the account phase would create it, and the
    # downstream sections must predict would_* instead of failing their
    # dependencies.
    def test_dry_run_on_fresh_machine_predicts_would_create_keys_and_verified_roles
      with_manifest(
        MANIFEST.gsub("create: false", "create: true"),
        lookup: ->(_name) { nil }, privileged: -> { true }, dry_run: true
      ) do |organism, dir|
        report = organism.call

        assert_equal true, report["ok"]
        assert_equal "would_create", report["accounts"].first["status"]
        assert_equal "would_create", report["directories"].first["status"]
        assert_equal "would_create", report["keys"].first["status"]
        assert_nil report["keys"].first["message"]
        assert_equal "verified", report["roles"].first["status"]
        refute File.exist?(File.join(dir, "labs"))
        refute File.exist?(File.join(dir, "home"))
      end
    end

    def test_missing_manifest_raises_invalid_configuration_with_path
      Ace::Lab::Molecules::GrantResolver.stub :read_verified, nil do
        organism = Ace::Lab::Organisms::Prepare.new(
          manifest_path: "/etc/lab/ace-lab/install.yml", platform: "linux"
        )

        error = assert_raises(Ace::Lab::InvalidConfigurationError) { organism.call }

        assert_match(%r{/etc/lab/ace-lab/install\.yml not found}, error.message)
      end
    end

    def test_schema_invalid_manifest_raises_value_free
      Ace::Lab::Molecules::GrantResolver.stub :read_verified, YAML.dump("schema_version" => 9) do
        organism = Ace::Lab::Organisms::Prepare.new(platform: "linux")

        error = assert_raises(Ace::Lab::InvalidConfigurationError) { organism.call }

        assert_match(/schema_version must be 1/, error.message)
      end
    end

    def test_report_carries_fingerprint_but_never_private_key_material
      with_manifest do |organism, dir| # rubocop:disable Lint/UnusedBlockArgument
        report = organism.call

        rendered = JSON.generate(report)
        assert_match(/SHA256:/, rendered)
        refute_includes rendered, "OPENSSH PRIVATE KEY"
        private_path = File.join(dir, "home", "ace-worker", ".ssh", "id_ed25519")
        File.readlines(private_path).each do |line|
          next if line.strip.empty? || line.start_with?("-----")

          refute_includes rendered, line.strip
        end
      end
    end
  end
end
