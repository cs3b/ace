# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"
require "open3"
require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        # End-to-end fixture: a real ace-assign assignment in a temp project,
        # driven through the repo binstub. Covers the leaf .2.0 acceptance
        # (start in a prepared worktree with the right role and assignment)
        # and the leaf .2.1 drive/verdict behavior with a real added step.
        class IntegrationTest < AceCoworkerTestCase
          REPO_ROOT = File.expand_path("../../..", __dir__)
          ASSIGN_BIN = File.join(REPO_ROOT, "bin", "ace-assign")
          COWORKER_BIN = File.join(REPO_ROOT, "bin", "ace-coworker")

          def setup
            super
            @dir = Dir.mktmpdir("coworker-e2e")
            FileUtils.mkdir_p(File.join(@dir, ".ace-tasks"))
            run_git("init", "-q", @dir)
            @task_ref = "8xh.t.aaa"
            CoworkerFixture.build_task(@dir, id: @task_ref)
            run_git("-C", @dir, "add", ".ace-tasks")
            run_git("-C", @dir, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "-m", "tasks")

            @job = File.join(@dir, "job.yaml")
            File.write(@job, <<~YAML)
              assignment:
                name: fixture-work
                description: Drive a fixture assignment
                task_id: #{@task_ref}
              steps:
                - name: first-check
                  instructions: |
                    Verify the fixture.
            YAML
            out, err, _status = run_cli(ASSIGN_BIN, "create", "--yaml", @job)
            @assignment_id = out[/Assignment: .* \((\w+)\)/, 1]
            refute_nil @assignment_id, "ace-assign create returned no id: #{err}#{out}"

            CoworkerFixture.build_config(@dir, assignment: @assignment_id, task: @task_ref)
          end

          def teardown
            FileUtils.remove_entry(@dir)
          end

          def test_start_and_status_against_real_assignment
            out, err, status = run_cli(COWORKER_BIN, "start")
            assert status.success?, "start failed: #{err}#{out}"
            assert_includes out, "role:              worker"
            assert_includes out, "--assignment #{@assignment_id}"

            out, _err, status = run_cli(COWORKER_BIN, "status", "--format", "json")
            assert status.success?
            payload = JSON.parse(out)
            assert_equal true, payload["ready"]
            assert_equal false, payload["assignment_status"]["complete"]
          end

          def test_drive_to_completion_and_verdict_complete
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "fixture step done")
            # Added check stays part of the same plan and is visible via ace-assign.
            add_yaml = File.join(@dir, "add.yaml")
            File.write(add_yaml, <<~YAML)
              steps:
                - name: extra-check
                  instructions: |
                    Additional verification added mid-run.
            YAML
            run_cli(ASSIGN_BIN, "add", "--yaml", add_yaml, "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "extra check done")

            out, _err, _status = run_cli(COWORKER_BIN, "status", "--format", "json")
            payload = JSON.parse(out)
            assert_equal true, payload["assignment_status"]["complete"], payload.inspect
            assert_equal 2, payload["assignment_status"]["steps"].size
            assert payload["assignment_status"]["steps"].any? { |s| s["name"] == "extra-check" }
          end

          def test_missing_config_start_fails_with_specific_error
            File.delete(File.join(@dir, ".ace-local", "coworker", "config.yml"))
            _out, err, status = run_cli(COWORKER_BIN, "start")
            refute status.success?
            assert_equal "not ready: .ace-local/coworker/config.yml not found", err.strip
          end

          private

          def run_cli(*argv)
            previous = ENV["BUNDLE_GEMFILE"]
            ENV["BUNDLE_GEMFILE"] = File.join(REPO_ROOT, "Gemfile")
            Open3.capture3(*argv, chdir: @dir)
          ensure
            ENV["BUNDLE_GEMFILE"] = previous
          end

          def run_git(*argv)
            Open3.capture3("git", *argv)
          end
        end
      end
    end
  end
end
