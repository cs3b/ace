# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"
require "open3"
require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        # End-to-end reporting fixture: a real ace-assign assignment in a
        # temp project with a real ace-hitl config (folder-form recipient,
        # no adapter routes so send fails deterministically). Covers the
        # leaf .2.2 acceptance: outcome recorded + report through HITL,
        # outcome/delivery separation, error cause, refusal of false success.
        class ReportIntegrationTest < AceCoworkerTestCase
          REPO_ROOT = File.expand_path("../../..", __dir__)
          ASSIGN_BIN = File.join(REPO_ROOT, "bin", "ace-assign")
          COWORKER_BIN = File.join(REPO_ROOT, "bin", "ace-coworker")

          def setup
            super
            @dir = Dir.mktmpdir("coworker-report-e2e")
            FileUtils.mkdir_p(File.join(@dir, ".ace-tasks"))
            run_git("init", "-q", @dir)
            @task_ref = "8xh.t.aaa"
            CoworkerFixture.build_task(@dir, id: @task_ref)
            run_git("-C", @dir, "add", ".ace-tasks")
            run_git("-C", @dir, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "-m", "tasks")

            job = File.join(@dir, "job.yaml")
            File.write(job, <<~YAML)
              assignment:
                name: fixture-report
                description: Drive a fixture assignment for reporting
                task_id: #{@task_ref}
              steps:
                - name: first-check
                  instructions: |
                    Verify the fixture.
            YAML
            out, err, _status = run_cli(ASSIGN_BIN, "create", "--yaml", job)
            @assignment_id = out[/Assignment: .* \((\w+)\)/, 1]
            refute_nil @assignment_id, "ace-assign create returned no id: #{err}#{out}"

            CoworkerFixture.build_config(@dir, assignment: @assignment_id, task: @task_ref, overseer: "overseer")
            write_hitl_config
          end

          def teardown
            FileUtils.remove_entry(@dir)
          end

          def write_hitl_config(routes: nil)
            hitl_dir = File.join(@dir, ".ace", "hitl")
            FileUtils.mkdir_p(hitl_dir)
            config = {"hitl" => {"machine" => "lab01",
              "recipients" => {"overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"}}}}
            config["hitl"]["adapters"] = {"routes" => routes} if routes
            File.write(File.join(hitl_dir, "config.yml"), YAML.dump(config))
          end

          def hitl_events
            Dir.glob(File.join(@dir, ".ace-local", "hitl", "**", "*.hitl.s.md"))
          end

          def test_completed_assignment_creates_success_report_event
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "step done")

            out, err, status = run_cli(COWORKER_BIN, "report", "--no-send")
            assert status.success?, "success with --no-send exits 0: #{out}#{err}"
            assert_includes out, "outcome recorded: success"
            assert_includes out, "delivery not attempted"

            assert_equal 1, hitl_events.size
            content = File.read(hitl_events.first)
            assert_includes content, "type: report"
            assert_includes content, "result: success"
            assert_includes content, "task: #{@task_ref}"
            assert_includes content, "assignment: #{@assignment_id}"

            record = File.join(@dir, ".ace-tasks", "#{@task_ref}-fixture-task", "coworker", "#{@assignment_id}.md")
            assert File.file?(record), "durable record in the task folder"
            assert_includes File.read(record), "result: success"
          end

          def test_pending_assignment_with_forced_success_is_refused
            out, err, status = run_cli(COWORKER_BIN, "report", "--result", "success")
            refute status.success?
            assert_includes err, "refusing to record work done"
            assert_empty hitl_events
          end

          def test_failed_step_reports_error_with_cause
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "fail", "--assignment", @assignment_id, "--message", "verifier crashed with exit 1")

            out, err, status = run_cli(COWORKER_BIN, "report", "--no-send")
            refute status.success?, "error outcome never exits success"
            assert_includes err, "outcome recorded: error"

            assert_equal 1, hitl_events.size
            content = File.read(hitl_events.first)
            assert_includes content, "result: error"
            body = content.split("## Report", 2).last.to_s
            assert_includes body, "verifier crashed"

            record = File.join(@dir, ".ace-tasks", "#{@task_ref}-fixture-task", "coworker", "#{@assignment_id}.md")
            assert_includes File.read(record), "verifier crashed"
          end

          def test_delivery_failure_preserves_outcome_and_rerun_resends
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "step done")

            run_cli(COWORKER_BIN, "report")
            assert_equal 1, hitl_events.size
            event_path = hitl_events.first

            # Rerun (still no routes): no duplicate event; the outcome record
            # keeps the success.
            out, err, status = run_cli(COWORKER_BIN, "report")
            refute status.success?
            assert_includes err, "outcome recorded: success"
            assert_includes err, "delivery failed"
            assert_equal 1, hitl_events.size, "rerun must not duplicate the event"
            assert_includes File.read(event_path), "result: success"
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
