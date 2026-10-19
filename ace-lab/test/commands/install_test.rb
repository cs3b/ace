# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class InstallCommandTest < Minitest::Test
          OK_PREPARE = {
            "ok" => true, "dry_run" => false, "machine" => "lab01",
            "accounts" => [], "directories" => [], "keys" => [], "roles" => []
          }.freeze

          def ok_project(id)
            {"ok" => true, "dry_run" => false, "project" => id, "path" => "/lab/#{id}",
             "remote" => nil,
             "repository" => {"path" => "/lab/#{id}", "status" => "created", "message" => nil},
             "overseer" => {"dir" => "/lab/#{id}/_overseer", "status" => "created", "message" => nil},
             "registry" => {"path" => "/lab/#{id}/.ace/lab/config.yml", "status" => "created",
                            "message" => nil}}
          end

          def manifest_yaml
            <<~YAML
              ---
              schema_version: 1
              machine: lab01
              accounts: []
              directories: []
              keys: []
              roles: []
              projects:
                - id: atlas
                  path: /lab/atlas
              grants:
                ace-overseer: [atlas]
            YAML
          end

          # Minimal trusted-read seam shared by the manifest and grants.
          class StubResolver
            def initialize(documents)
              @documents = documents
            end

            def read_verified(path)
              @documents[path]
            end
          end

          # A prepare organism that always reports one failed account.
          class FailedPrepare
            def call(dry_run:)
              InstallCommandTest::OK_PREPARE.merge("ok" => false, "accounts" => [
                {"username" => "ace-worker", "status" => "failed",
                 "uid" => nil, "message" => "account does not exist"}
              ])
            end
          end

          # The organism is stubbed at the read_verified seam: both the
          # manifest and the trusted authorization document resolve to
          # paths under the tmpdir, with a real GrantProvisioner write.
          # A project-add organism that succeeds without touching git.
          class FakeProjectAdd
            def call(id:, path:, remote:, label:, dry_run:)
              {"ok" => true, "dry_run" => dry_run, "project" => id, "path" => path,
               "remote" => remote,
               "repository" => {"path" => path, "status" => "created", "message" => nil},
               "overseer" => {"dir" => "#{path}/_overseer", "status" => "created", "message" => nil},
               "registry" => {"path" => "#{path}/.ace/lab/config.yml", "status" => "created",
                              "message" => nil}}
            end
          end

          def with_command(authorization: nil)
            Dir.mktmpdir do |dir|
              manifest_path = "/etc/lab/ace-lab/install.yml"
              auth_path = File.join(dir, "authorization.yml")
              File.write(auth_path, authorization) if authorization
              documents = {manifest_path => manifest_yaml, auth_path => authorization}
              resolver = StubResolver.new(documents)
              organism = Organisms::Install.new(
                manifest_path: manifest_path, platform: "linux",
                project_add: FakeProjectAdd.new,
                grants: Molecules::GrantProvisioner.new(
                  resolver: resolver, authorization_path: auth_path
                )
              )
              Ace::Lab::Molecules::GrantResolver.stub :read_verified,
                ->(path) { documents[path] } do
                yield Install.new(install: organism), auth_path
              end
            end
          end

          def test_json_output_matches_report_schema
            with_command do |cmd, _path|
              out, = capture_io { cmd.call(format: "json", dry_run: nil, quiet: nil) }

              parsed = JSON.parse(out)
              assert_equal true, parsed["ok"]
              assert_equal "lab01", parsed["machine"]
              assert_equal %w[prepare projects grants],
                parsed.keys - %w[ok dry_run machine manifest]
              assert_equal "atlas", parsed["projects"].first["project"]
              assert_equal "created", parsed["grants"]["status"]
            end
          end

          def test_table_output_renders_each_phase
            with_command do |cmd, _path|
              out, = capture_io { cmd.call(format: nil, dry_run: nil, quiet: nil) }

              assert_includes out, "Machine: lab01"
              assert_includes out, "manifest: /etc/lab/ace-lab/install.yml"
              assert_includes out, "Prepare: ok"
              assert_includes out, "Projects:"
              assert_includes out, "atlas"
              assert_includes out, "(repository: created, overseer: created, registry: created)"
              assert_includes out, "Grants"
              assert_includes out, "ace-overseer"
              assert_includes out, "Result: ok"
            end
          end

          def test_dry_run_previews_with_exit_zero
            with_command do |cmd, auth_path|
              out, = capture_io { cmd.call(format: nil, dry_run: true, quiet: nil) }

              assert_includes out, "(dry run)"
              assert_includes out, "would_create"
              refute File.exist?(auth_path)
            end
          end

          def test_foreign_lab_is_refused_before_any_mutation
            with_command(authorization: YAML.dump({"principals" =>
              {"operator" => {"projects" => %w[zephyr]}}})) do |cmd, auth_path|
              error = assert_raises(Ace::Support::Cli::Error) do
                capture_io { cmd.call(format: nil, dry_run: nil, quiet: nil) }
              end

              assert_match(/refusing to install over a foreign lab/, error.message)
              assert_match(/zephyr/, error.message)
              # the dry-run prediction refuses identically (parity)
              preview = assert_raises(Ace::Support::Cli::Error) do
                capture_io { cmd.call(format: nil, dry_run: true, quiet: nil) }
              end
              assert_equal error.message, preview.message
            end
          end

          def test_failed_steps_render_report_then_raise_with_step_list
            Dir.mktmpdir do |dir|
              manifest_path = "/etc/lab/ace-lab/install.yml"
              auth_path = File.join(dir, "authorization.yml")
              resolver = StubResolver.new(manifest_path => manifest_yaml)
              organism = Organisms::Install.new(
                manifest_path: manifest_path, platform: "linux", prepare: FailedPrepare.new,
                grants: Molecules::GrantProvisioner.new(
                  resolver: resolver, authorization_path: auth_path
                )
              )
              cmd = Install.new(install: organism)

              Ace::Lab::Molecules::GrantResolver.stub :read_verified,
                ->(path) { path == manifest_path ? manifest_yaml : nil } do
                out, = capture_io do
                  error = assert_raises(Ace::Support::Cli::Error) do
                    cmd.call(format: nil, dry_run: nil, quiet: nil)
                  end
                  # 1 failed prepare item + 3 dependency-failed project
                  # steps + 1 dependency-failed grants step
                  assert_match(/install failed \(5 step\(s\)\)/, error.message)
                  assert_match(%r{accounts/ace-worker: }, error.message)
                  assert_match(%r{projects/atlas/repository: }, error.message)
                  assert_match(/grants: /, error.message)
                end

                assert_includes out, "Prepare: FAILED"
                assert_includes out, "Result: FAILED"
              end
            end
          end

          def test_unsupported_format_is_rejected
            with_command do |cmd, _path|
              error = assert_raises(Ace::Support::Cli::Error) do
                cmd.call(format: "yaml", dry_run: nil, quiet: nil)
              end

              assert_match(/--format "yaml" is not supported/, error.message)
            end
          end
        end
      end
    end
  end
end
