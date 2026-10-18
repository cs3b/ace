# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"
require "open3"
require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        # End-to-end resume fixture: a real ace-assign assignment in a real
        # temp git repo, interrupted mid-flight. Covers the leaf .2.3
        # acceptance: restart preserves completed steps + local changes and
        # returns to the remaining work; uncertain effects get
        # check-or-block guidance (never blind replay, no new task/worktree);
        # complete-but-undelivered resends the same HITL event ID.
        class ResumeIntegrationTest < AceCoworkerTestCase
          REPO_ROOT = File.expand_path("../../..", __dir__)
          ASSIGN_BIN = File.join(REPO_ROOT, "bin", "ace-assign")
          COWORKER_BIN = File.join(REPO_ROOT, "bin", "ace-coworker")

          def setup
            super
            @dir = Dir.mktmpdir("coworker-resume-e2e")
            FileUtils.mkdir_p(File.join(@dir, ".ace-tasks"))
            run_git("init", "-q", @dir)
            @task_ref = "8xh.t.aaa"
            CoworkerFixture.build_task(@dir, id: @task_ref)
            run_git("-C", @dir, "add", ".ace-tasks")
            run_git("-C", @dir, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "-m", "tasks")

            job = File.join(@dir, "job.yaml")
            File.write(job, <<~YAML)
              assignment:
                name: fixture-resume
                description: Resume fixture assignment
                task_id: #{@task_ref}
              steps:
                - name: first-check
                  instructions: |
                    Verify the fixture.
                - name: merge-pr
                  instructions: |
                    Merge the PR.
                - name: docs
                  instructions: |
                    Write docs.
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

          def write_hitl_config
            hitl_dir = File.join(@dir, ".ace", "hitl")
            FileUtils.mkdir_p(hitl_dir)
            File.write(File.join(hitl_dir, "config.yml"), YAML.dump(
              "hitl" => {"machine" => "lab01",
                "recipients" => {"overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"}}}))
          end

          def hitl_events
            Dir.glob(File.join(@dir, ".ace-local", "hitl", "**", "*.hitl.s.md"))
          end

          def test_mid_step_interruption_preserves_work_and_returns_to_remaining
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "first done")
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            # "Interruption": local change survives, second step not finished.
            File.write(File.join(@dir, "local-notes.md"), "mid-flight note\n")

            task_dirs_before = Dir.children(File.join(@dir, ".ace-tasks")).size
            assign_entries_before = Dir.children(File.join(@dir, ".ace-local", "assign")).size

            out, err, status = run_cli(COWORKER_BIN, "resume")
            assert status.success?, "resume failed: #{err}#{out}"

            assert_includes out, "preserved steps:"
            assert_includes out, "done: 010 first-check"
            assert_includes out, "remaining work:"
            assert_includes out, "merge-pr (active)"
            assert_includes out, "docs (pending)"
            assert_includes out, "local changes (preserved, never reset)"
            assert_includes out, "local-notes.md"
            assert_includes out, "verify the effect from the current files/Git state"

            # Nothing reset, nothing new created.
            assert File.file?(File.join(@dir, "local-notes.md")), "local change preserved"
            assert_equal task_dirs_before, Dir.children(File.join(@dir, ".ace-tasks")).size
            assert_equal assign_entries_before, Dir.children(File.join(@dir, ".ace-local", "assign")).size
            refute Dir.exist?(File.join(@dir, ".ace-wt")), "no new worktree"
          end

          def test_uncertain_external_effect_gets_check_or_block_guidance
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "first done")
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            File.write(File.join(@dir, "local-notes.md"), "x")

            out, _err, status = run_cli(COWORKER_BIN, "resume")
            assert status.success?

            assert_includes out, "effect caution"
            assert_includes out, "merge-pr"
            assert_includes out, "check the actual state with existing tools"
          end

          def test_failed_step_surfaces_recorded_cause
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "first done")
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "fail", "--assignment", @assignment_id, "--message", "merge conflict in lib/a.rb")

            out, _err, status = run_cli(COWORKER_BIN, "resume")
            assert status.success?
            assert_includes out, "in-flight step:"
            assert_includes out, "recorded cause:"
            assert_includes out, "merge conflict in lib/a.rb"
          end

          def test_complete_but_undelivered_resumes_report_with_same_event_id
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "first done")
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "merge done")
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "docs done")

            # First resume: complete + no routes -> create + failed delivery.
            out, err, status = run_cli(COWORKER_BIN, "resume")
            refute status.success?, "undelivered report keeps exit 1: #{out}#{err}"
            assert_equal 1, hitl_events.size

            # Second resume: same event resent, no duplicate.
            out, err, status = run_cli(COWORKER_BIN, "resume")
            refute status.success?
            assert_equal 1, hitl_events.size, "rerun must resend the same event, not duplicate it"
            assert_includes out, "resend event"
          end

          def test_complete_and_delivered_is_informational
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "first done")
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "merge done")
            run_cli(ASSIGN_BIN, "start", "--assignment", @assignment_id)
            run_cli(ASSIGN_BIN, "finish", "--assignment", @assignment_id, "--message", "docs done")

            # Deliver once by faking the delivered state through report+send
            # with a terminal route that always fails is not possible; use
            # the report state the same way report would write it.
            run_cli(COWORKER_BIN, "report")
            state_path = File.join(@dir, ".ace-local", "coworker", "reports", "#{@assignment_id}.json")
            state = JSON.parse(File.read(state_path))
            state["delivery"] = "delivered (event #{state["event_id"]})"
            File.write(state_path, JSON.generate(state))

            out, _err, status = run_cli(COWORKER_BIN, "resume")
            assert status.success?, out
            assert_includes out, "nothing to resume"
          end

          def test_missing_config_reuses_start_error
            File.delete(File.join(@dir, ".ace-local", "coworker", "config.yml"))
            _out, err, status = run_cli(COWORKER_BIN, "resume")
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
