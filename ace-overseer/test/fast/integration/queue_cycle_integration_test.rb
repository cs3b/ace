# frozen_string_literal: true

require_relative "../../test_helper"
require "fileutils"
require "open3"
require "json"

module Ace
  module Overseer
    module CLI
      module Commands
        # One REAL end-to-end queue cycle (PR #393 audit follow-up):
        # prepare -> execute role -> report -> next role prepared ->
        # continuation resumed, driven entirely through real sibling
        # CLIs against a real temporary git project with a linked
        # worktree. Per queue.wf.md section 4 nothing launches
        # automatically: the test acts as the overseer agent and RUNS
        # each printed `ace-coworker start --config ...` command. The
        # crash-between-persist-and-dispatch cut is covered too: a
        # report that was recorded on its step without its continuation
        # ever running is re-dispatched on the next process-reports run
        # through the duplicate-with-recorded-success recovery path.
        class QueueCycleIntegrationTest < AceOverseerTestCase
          REPO_ROOT = File.expand_path("../../../..", __dir__)
          COWORKER_BIN = File.join(REPO_ROOT, "bin", "ace-coworker")
          OVERSEER_BIN = File.join(REPO_ROOT, "bin", "ace-overseer")
          HITL_BIN = File.join(REPO_ROOT, "bin", "ace-hitl")
          TASK_BIN = File.join(REPO_ROOT, "bin", "ace-task")
          ASSIGN_BIN = File.join(REPO_ROOT, "bin", "ace-assign")
          TASK_REF = "8xh.t.cyc"

          def setup
            super
            @dir = Dir.mktmpdir("overseer-queue-cycle")
            @rt_dir = Dir.mktmpdir("overseer-queue-cycle-rt")
            write_stub_runtime_adapter
            build_project
          end

          def teardown
            FileUtils.remove_entry(@dir)
            FileUtils.remove_entry(@rt_dir)
          end

          def test_one_real_prepare_execute_report_next_role_resume_cycle
            prepare_result, worktree, manager = prepare_sequence

            # Run 1: the readiness report binds ONLY to the preparation
            # step, records it done, and the continuation hands the
            # worktree to the worker with the actionable start command.
            out = process_reports
            prep_step = "#{manager}.0"
            assert_includes out, "recorded success on #{prep_step}"
            assert_includes out, "run there: ace-coworker start --config .ace-local/coworker/prepare/worker.yml",
              "run 1 must print the actionable first-role start command:\n#{out}"
            assert_equal "done", step_status(prep_step)
            assert_equal prepare_result["report"]["event"], step_metadata(prep_step)["processed_report"],
              "the readiness report is recorded on the preparation step"

            # The agent (no automatic launcher) executes the printed
            # start command: the config prepare wrote really starts.
            worker_assignment = prepare_result["assignments"][0]["assignment"]
            out, err, status = run_cli(COWORKER_BIN, "start",
              "--config", ".ace-local/coworker/prepare/worker.yml", chdir: worktree)
            assert status.success?, "worker start command failed: #{out}#{err}"
            assert_includes out, "role:              worker"
            assert_includes out, worker_assignment

            # Role execution: drive the real assignment to completion.
            drive_assignment_to_completion(worktree, worker_assignment)

            # Deliver the real completion report via ace-hitl create.
            worker_event = deliver_report(title: "Worker done", assignment: worker_assignment)

            # Crash cut: the run died between persisting the report on
            # its step and dispatching the continuation — exactly the
            # state a process death leaves on disk.
            impl_step = "#{manager}.1"
            run_cli(TASK_BIN, "update", impl_step, "--set",
              "status=done,processed_report=#{worker_event},report_result=success")

            # Run 2: the persisted report is a duplicate with recorded
            # success whose continuation never ran — it must be
            # re-dispatched, not suppressed.
            out = process_reports
            assert_includes out,
              "duplicate - report #{worker_event} already recorded on #{impl_step} (result: success); " \
              "continuation re-checked", "run 2 must resume the never-dispatched continuation:\n#{out}"
            assert_includes out, "run there: ace-coworker start --config .ace-local/coworker/prepare/reviewer.yml",
              "run 2 must print the next role's start command:\n#{out}"
            assert_equal prepare_result["report"]["event"], step_metadata(prep_step)["processed_report"],
              "the worker report never touches the preparation step (no misattribution)"
            assert_equal worker_event, step_metadata(impl_step)["processed_report"]

            # The agent executes the next role's printed start command.
            reviewer_assignment = prepare_result["assignments"][1]["assignment"]
            out, err, status = run_cli(COWORKER_BIN, "start",
              "--config", ".ace-local/coworker/prepare/reviewer.yml", chdir: worktree)
            assert status.success?, "reviewer start command failed: #{out}#{err}"
            assert_includes out, "role:              reviewer"
            assert_includes out, reviewer_assignment
            drive_assignment_to_completion(worktree, reviewer_assignment)

            # A report naming an allocation that fits no open step stays
            # unmatched — never attributed to whichever step remains.
            stray_event = deliver_report(title: "Stray report", assignment: "noexist1")
            review_step = "#{manager}.2"

            reviewer_event = deliver_report(title: "Review done", assignment: reviewer_assignment)

            # Run 3: the reviewer report binds to the review step, the
            # sequence is complete, and no step was misattributed.
            out = process_reports
            assert_includes out, "recorded success on #{review_step}"
            assert_includes out, "sequence complete - the worktree has no next role"
            assert_includes out, "unmatched - kept for clarification"
            assert_equal reviewer_event, step_metadata(review_step)["processed_report"]
            assert_equal worker_event, step_metadata(impl_step)["processed_report"],
              "the reviewer report never rewrites the implement step's recorded report"
            assert_nil step_metadata(review_step)["processed_report"][stray_event],
              "the stray report is recorded nowhere"
          end

          private

          def prepare_sequence
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", TASK_REF, "--roles", "worker,reviewer", "--to", "overseer", "--format", "json")
            assert status.success?, "prepare failed: #{out}#{err}"
            payload = JSON.parse(out)
            worktree = payload["worktree"]["path"]
            assert File.directory?(worktree), "linked worktree created on disk"

            manager = create_task("Manage: cycle", nil)
            prep = create_task("Prepare cycle", manager)
            impl = create_task("Implement cycle", manager)
            review = create_task("Review cycle", manager)
            update_task(manager, "project_task=#{TASK_REF}")
            update_task(impl, "dependencies=#{prep}")
            update_task(review, "dependencies=#{impl}")

            # The overseer agent records the allocations the preparation
            # really produced (queue.wf.md section 2: never fabricate
            # references ahead of preparation).
            worker_assignment = payload["assignments"][0]["assignment"]
            reviewer_assignment = payload["assignments"][1]["assignment"]
            update_task(impl, "assignment=#{worker_assignment},worktree=#{worktree_rel(worktree)}")
            update_task(review, "assignment=#{reviewer_assignment}")

            [payload, worktree, manager]
          end

          def worktree_rel(worktree)
            Pathname.new(worktree).relative_path_from(Pathname.new(@dir)).to_s
          end

          def process_reports
            out, err, status = run_cli(OVERSEER_BIN, "process-reports")
            assert status.success?, "process-reports failed: #{out}#{err}"
            out
          end

          def deliver_report(title:, assignment:)
            out, err, status = run_cli(HITL_BIN, "create", title,
              "--type", "report", "--result", "success", "--to", "overseer",
              "--task", TASK_REF, "--assignment", assignment, "-b", "#{title} body")
            assert status.success?, "ace-hitl create failed: #{out}#{err}"
            event_id = out[/HITL event created: (\S+)/, 1]
            refute_nil event_id, "ace-hitl create returned no event id: #{out}#{err}"
            event_id
          end

          def drive_assignment_to_completion(worktree, assignment_id)
            loop do
              out, err, status = run_cli(ASSIGN_BIN, "status", "--assignment", assignment_id, chdir: worktree)
              assert status.success?, "ace-assign status failed: #{out}#{err}"
              break if out.include?("Status: completed")

              out, err, status = run_cli(ASSIGN_BIN, "start", "--assignment", assignment_id, chdir: worktree)
              assert status.success?, "ace-assign start failed: #{out}#{err}"
              out, err, status = run_cli(ASSIGN_BIN, "finish", "--assignment", assignment_id,
                "-m", "step done", chdir: worktree)
              assert status.success?, "ace-assign finish failed: #{out}#{err}"
            end
            assert true
          end

          def create_task(title, parent)
            argv = ["create", title, "--in", "_overseer"]
            argv += ["--child-of", parent] if parent
            out, err, status = run_cli(TASK_BIN, *argv)
            assert status.success?, "ace-task create failed: #{out}#{err}"
            ref = out[/Created task (\S+)/, 1]
            refute_nil ref, "ace-task create returned no ref: #{out}#{err}"
            ref
          end

          def update_task(ref, sets)
            out, err, status = run_cli(TASK_BIN, "update", ref, "--set", sets)
            assert status.success?, "ace-task update failed: #{out}#{err}"
          end

          def step_file(ref)
            files = Dir.glob(File.join(@dir, ".ace-tasks", "_overseer", "**", "#{ref}-*.s.md"))
            refute_empty files, "no task file for #{ref}"
            files.first
          end

          def step_metadata(ref)
            YAML.safe_load_file(step_file(ref))
          end

          def step_status(ref)
            step_metadata(ref)["status"]
          end

          # A side-effect-free terminal runtime so the real handoff
          # continuation (which opens the next role's window through the
          # runtime contract) stays deterministic in tests.
          def write_stub_runtime_adapter
            adapter = File.join(@rt_dir, "ace", "runtime", "adapters", "stubrt.rb")
            FileUtils.mkdir_p(File.dirname(adapter))
            File.write(adapter, <<~RUBY)
              # frozen_string_literal: true
              require "ace/runtime"
              class StubQueueCycleRuntime
                def send_profile = :plain_pane
                def ensure_window(name:, root:, preset: nil) = "stub:\#{name}"
              end
              Ace::Runtime.register(:stubrt, -> { StubQueueCycleRuntime.new })
            RUBY
          end

          def build_project
            FileUtils.mkdir_p(File.join(@dir, ".ace-tasks", "_overseer"))
            run_git("init", "-q", "-b", "main", @dir)
            File.write(File.join(@dir, ".gitignore"), ".ace-local/\n/.ace-tasks/_overseer/\n")

            folder = File.join(@dir, ".ace-tasks", "#{TASK_REF}-fixture-task")
            FileUtils.mkdir_p(folder)
            File.write(File.join(folder, "#{TASK_REF}-fixture-task.s.md"), <<~SPEC)
              ---
              id: #{TASK_REF}
              status: pending
              priority: medium
              created_at: "2026-10-19 00:00:00"
              title: "Cycle fixture task"
              ---

              # Cycle fixture task

              Fixture body.
            SPEC

            git_dir = File.join(@dir, ".ace", "git")
            FileUtils.mkdir_p(git_dir)
            File.write(File.join(git_dir, "worktree.yml"), <<~YAML)
              git:
                worktree:
                  task:
                    auto_mark_in_progress: false
                    auto_commit_task: false
                    add_worktree_metadata: false
                    auto_push_task: false
                    auto_setup_upstream: false
                    auto_create_pr: false
                  hooks:
                    after_create: []
            YAML

            hitl_dir = File.join(@dir, ".ace", "hitl")
            FileUtils.mkdir_p(hitl_dir)
            File.write(File.join(hitl_dir, "config.yml"), YAML.dump(
              "hitl" => {
                "machine" => "lab01",
                "recipients" => {"overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"}}
              }
            ))

            overseer_dir = File.join(@dir, ".ace", "overseer")
            FileUtils.mkdir_p(overseer_dir)
            File.write(File.join(overseer_dir, "config.yml"), "runtime: stubrt\n")

            copy_binstubs
            commit_all("fixture")
          end

          # Project-root binstubs delegating to the repo's pinned
          # binstubs, so subprocesses (prepare's executor/HITL probes)
          # never resolve stale installed gems through mise shims.
          def copy_binstubs
            bin_dir = File.join(@dir, "bin")
            FileUtils.mkdir_p(bin_dir)
            %w[ace-assign ace-hitl ace-task].each do |name|
              wrapper = File.join(bin_dir, name)
              File.write(wrapper, <<~SH)
                #!/bin/sh
                exec "#{File.join(REPO_ROOT, 'bin', name)}" "$@"
              SH
              FileUtils.chmod(0o755, wrapper)
            end
          end

          def commit_all(message)
            run_git("-C", @dir, "add", "-A")
            run_git("-C", @dir, "-c", "user.email=t@t", "-c", "user.name=t",
              "commit", "-q", "-m", message)
          end

          def run_cli(*argv, chdir: @dir)
            previous_gemfile = ENV["BUNDLE_GEMFILE"]
            previous_rubylib = ENV["RUBYLIB"]
            ENV["BUNDLE_GEMFILE"] = File.join(REPO_ROOT, "Gemfile")
            ENV["RUBYLIB"] = @rt_dir
            Open3.capture3(*argv, chdir: chdir)
          ensure
            ENV["BUNDLE_GEMFILE"] = previous_gemfile
            ENV["RUBYLIB"] = previous_rubylib
          end

          def run_git(*argv)
            out, err, status = Open3.capture3("git", *argv)
            assert status.success?, "git #{argv.join(' ')} failed: #{err}"
            [out, err, status]
          end
        end
      end
    end
  end
end
