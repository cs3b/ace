# frozen_string_literal: true

require_relative "../test_helper"
require "shellwords"

module Ace
  module Lab
    module CLI
      module Commands
        # Task 8xg.t.sbz.7.3 (L8.4), CLI surface: re-running
        # `ace-lab install` over the installer's OWN partial state
        # renders the resume per-step statuses (exists for the done
        # parts, created for the finished ones) and succeeds; foreign
        # content is refused with the concrete step named, and
        # --dry-run predicts the same resume/refusal without mutating.
        # Real molecules throughout; only the trusted-read verification
        # seam is stubbed for tmpdir paths (as in install_test).
        class InstallResumeCommandTest < Minitest::Test
          class StubResolver
            def initialize(documents)
              @documents = documents
            end

            def read_verified(path)
              @documents[path]
            end
          end

          def with_command
            Dir.mktmpdir do |dir|
              origin = File.join(dir, "origin.git")
              `git init --bare #{origin.shellescape} >/dev/null 2>&1`
              skip "git unavailable" unless File.directory?(origin)

              home = File.join(dir, "home", "ace-worker")
              labs = File.join(dir, "labs")
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
                keys: []
                roles: []
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

              fixture = {"labs" => labs, "manifest" => manifest_path, "auth" => auth_path,
                "home" => home}
              build = -> {
                entry = FakeEntry.new(name: "ace-worker", uid: Process.uid, gid: Process.gid,
                  dir: fixture["home"])
                lookup = ->(name) { name == "ace-worker" ? entry : nil }
                documents = {manifest_path => File.read(manifest_path)}
                documents[auth_path] = File.read(auth_path) if File.exist?(auth_path)
                Organisms::Install.new(
                  manifest_path: manifest_path, account_lookup: lookup, platform: "linux",
                  grants: Molecules::GrantProvisioner.new(
                    resolver: StubResolver.new(documents), authorization_path: auth_path
                  )
                )
              }
              Molecules::GrantResolver.stub :read_verified,
                ->(path) { File.file?(path) ? File.read(path) : nil } do
                yield build, fixture, origin
              end
            end
          end

          def test_resume_of_own_partial_state_renders_exists_and_created
            with_command do |build, fixture, origin|
              # crash after the first project's repository step
              FileUtils.mkdir_p(fixture["labs"])
              File.chmod(0o750, fixture["labs"])
              `git clone -q #{origin.shellescape} #{File.join(fixture['labs'], 'atlas').shellescape} >/dev/null 2>&1`
              organism = build.call
              cmd = Install.new(install: organism)

              out, = capture_io { cmd.call(format: nil, dry_run: nil, quiet: nil) }

              assert_includes out, "Prepare: ok"
              assert_includes out, "atlas"
              assert_includes out, "(repository: exists"
              assert_includes out, "borealis"
              assert_includes out, "(repository: created"
              assert_includes out, "Grants (#{fixture['auth']}): created"
              assert_includes out, "Result: ok"
              assert File.file?(File.join(fixture["labs"], "borealis", ".ace", "lab", "config.yml"))
            end
          end

          def test_foreign_project_directory_failure_names_the_step
            with_command do |build, fixture, _origin|
              foreign = File.join(fixture["labs"], "atlas")
              FileUtils.mkdir_p(foreign)
              File.write(File.join(foreign, "foreign.txt"), "not ours\n")
              cmd = Install.new(install: build.call)

              out, = capture_io do
                error = assert_raises(Ace::Support::Cli::Error) do
                  cmd.call(format: nil, dry_run: nil, quiet: nil)
                end
                assert_match(%r{projects/atlas/repository: }, error.message)
                assert_match(/refusing to take over a foreign location/, error.message)
              end

              assert_includes out, "Result: FAILED"
              # refused, not taken over or cleaned
              assert_equal "not ours\n", File.read(File.join(foreign, "foreign.txt"))
              refute File.exist?(fixture["auth"])
            end
          end

          def test_dry_run_previews_the_resume_with_zero_mutations
            with_command do |build, fixture, origin|
              FileUtils.mkdir_p(fixture["labs"])
              File.chmod(0o750, fixture["labs"])
              `git clone -q #{origin.shellescape} #{File.join(fixture['labs'], 'atlas').shellescape} >/dev/null 2>&1`
              cmd = Install.new(install: build.call)

              out, = capture_io { cmd.call(format: nil, dry_run: true, quiet: nil) }

              assert_includes out, "(dry run)"
              assert_includes out, "(repository: exists"
              assert_includes out, "(repository: would_create"
              assert_includes out, "would_create"
              assert_includes out, "Result: ok"
              refute File.exist?(File.join(fixture["labs"], "borealis"))
              refute File.exist?(fixture["auth"])
            end
          end
        end
      end
    end
  end
end
