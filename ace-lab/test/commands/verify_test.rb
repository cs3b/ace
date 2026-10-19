# frozen_string_literal: true

require_relative "../test_helper"
require "shellwords"

module Ace
  module Lab
    module CLI
      module Commands
        # Task 8xg.t.sbz.7.4 (L8.5), CLI surface: `ace-lab verify`
        # renders the per-check table (failure beside healthy data) and
        # exits 0 only when the lab is ready under the target accounts;
        # a failed check fails the command with the concrete reason.
        # `--format json` emits the stable machine report (ready /
        # checks / counts) for the overseer or the next tool. Real
        # molecules; only the trusted-read seam and passwd seam are
        # stubbed for tmpdir paths (as in install_resume_test).
        class VerifyCommandTest < Minitest::Test
          class StubResolver
            def initialize(documents)
              @documents = documents
            end

            def read_verified(path)
              @documents[path]
            end
          end

          # ONE class-level trusted-read stub wraps the whole test body
          # (both install and verify load the manifest at call time);
          # the verify organism additionally reads the authorization
          # document through its own injected trusted_read seam.
          def with_command
            Dir.mktmpdir do |dir|
              origin = File.join(dir, "origin.git")
              `git init --bare #{origin.shellescape} >/dev/null 2>&1`
              skip "git unavailable" unless File.directory?(origin)

              home = File.join(dir, "home", "ace-worker")
              labs = File.join(dir, "labs")
              key_path = File.join(home, ".ssh", "id_ed25519")
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
                    instructions: wfi://lab/worker
                projects:
                  - id: atlas
                    path: #{labs}/atlas
                    remote: #{origin}
                grants:
                  ace-overseer: [atlas]
              YAML

              entry = FakeEntry.new(name: "ace-worker", uid: Process.uid, gid: Process.gid,
                dir: home)
              lookup = ->(name) { name == "ace-worker" ? entry : nil }
              documents = {manifest_path => File.read(manifest_path)}
              trusted_read = ->(path) { File.file?(path) ? File.read(path) : nil }
              build_install = -> {
                documents[auth_path] = File.read(auth_path) if File.exist?(auth_path)
                Organisms::Install.new(
                  manifest_path: manifest_path, account_lookup: lookup, platform: "linux",
                  grants: Molecules::GrantProvisioner.new(
                    resolver: StubResolver.new(documents), authorization_path: auth_path
                  )
                )
              }
              build_verify = -> {
                Organisms::Verify.new(manifest_path: manifest_path, account_lookup: lookup,
                  trusted_read: trusted_read, authorization_path: auth_path, platform: "linux")
              }
              fixture = {"labs" => labs, "manifest" => manifest_path, "auth" => auth_path,
                "key" => key_path, "origin" => origin}

              Molecules::GrantResolver.stub :read_verified, trusted_read do
                yield build_install, build_verify, fixture
              end
            end
          end

          def test_ready_lab_renders_table_and_exits_clean
            with_command do |build_install, build_verify, fixture|
              assert_equal true, build_install.call.call(dry_run: false)["ok"]

              out, = capture_io { Verify.new(verifier: build_verify.call).call(format: nil, quiet: nil) }

              assert_includes out, "Machine: lab01"
              assert_includes out, "Accounts:"
              assert_includes out, "ace-worker"
              assert_includes out, "PASS"
              assert_includes out, "fingerprint SHA256:"
              assert_includes out, "Grants:"
              assert_includes out, "ace-overseer"
              assert_includes out, "Overseer:"
              assert_includes out, "Checks: "
              assert_includes out, "Result: ready"
              assert File.file?(fixture["auth"])
            end
          end

          def test_not_ready_lab_renders_report_then_fails_with_the_reason
            with_command do |build_install, build_verify, fixture|
              assert_equal true, build_install.call.call(dry_run: false)["ok"]
              # break one fact: the key pair's mode
              File.chmod(0o644, fixture["key"])

              out, = capture_io do
                error = assert_raises(Ace::Support::Cli::Error) do
                  Verify.new(verifier: build_verify.call).call(format: nil, quiet: nil)
                end
                assert_match(/lab is not ready \(1 failed check/, error.message)
                assert_match(%r{keys/ace-worker: }, error.message)
                assert_match(/mode is 0644 but 0600 is required/, error.message)
              end

              assert_includes out, "Result: NOT READY"
              # the healthy checks are still rendered beside the failure
              assert_includes out, "PASS"
            end
          end

          def test_json_format_is_the_stable_machine_report
            with_command do |build_install, build_verify, _fixture|
              assert_equal true, build_install.call.call(dry_run: false)["ok"]

              out, = capture_io { Verify.new(verifier: build_verify.call).call(format: "json", quiet: nil) }
              report = JSON.parse(out)

              assert_equal true, report["ready"]
              assert_equal "lab01", report["machine"]
              assert_includes report["checks"].keys, "accounts"
              assert_includes report["checks"].keys, "grants"
              assert_equal 0, report["counts"]["fail"]
              assert report["counts"]["pass"] > 0
              key_check = report["checks"]["keys"].first
              assert_match(/\ASHA256:/, key_check["fingerprint"])
              assert_equal "pass", key_check["status"]
            end
          end
        end
      end
    end
  end
end
