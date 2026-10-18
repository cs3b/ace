# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"
require "open3"
require "json"
require "digest"
require "ace/git/worktree"

module Ace
  module Coworker
    module CLI
      module Commands
        # End-to-end preparation fixture: a real temp git project, real
        # repo binstubs (ace-coworker, ace-assign, ace-hitl), and a
        # project-level .ace/git/worktree.yml that disables all push/PR/
        # bookkeeping automation for offline determinism. Covers the leaf
        # .3.0 acceptance: idempotent re-preparation reuses the worktree,
        # active-executor and mismatched-worktree conflicts escalate via
        # ace-hitl instead of overwriting work, dry-run and invalid input.
        class PrepareIntegrationTest < AceCoworkerTestCase
          REPO_ROOT = File.expand_path("../../..", __dir__)
          ASSIGN_BIN = File.join(REPO_ROOT, "bin", "ace-assign")
          COWORKER_BIN = File.join(REPO_ROOT, "bin", "ace-coworker")

          def setup
            super
            @dir = Dir.mktmpdir("coworker-prepare-e2e")
            FileUtils.mkdir_p(File.join(@dir, ".ace-tasks"))
            run_git("init", "-q", "-b", "main", @dir)
            @task_ref = "8xh.t.aaa"
            CoworkerFixture.build_task(@dir, id: @task_ref)
            write_worktree_config
            copy_binstubs
            commit_all("tasks")
            write_hitl_config
          end

          def teardown
            FileUtils.remove_entry(@dir)
          end

          def test_prepare_creates_then_reuses_idempotently
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker,reviewer", "--format", "json")
            assert status.success?, "prepare failed: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "created", payload["worktree"]["disposition"]
            worktree = payload["worktree"]["path"]
            assert File.directory?(worktree), "worktree created on disk"
            assert_equal %w[worker reviewer], payload["roles"]

            task_file = Dir.glob(File.join(@dir, ".ace-tasks", "#{@task_ref}-*",
              "#{@task_ref}-*.s.md")).first
            status_before = run_git("-C", worktree, "status", "--porcelain")[0]
            bytes_before = File.read(task_file)

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker,reviewer", "--format", "json")
            assert status.success?, "re-prepare failed: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "reused", payload["worktree"]["disposition"]
            assert_equal worktree, payload["worktree"]["path"]
            assert_nil payload["conflict"]

            # Zero writes on reuse: same worktree state, same task file.
            assert_equal status_before, run_git("-C", worktree, "status", "--porcelain")[0]
            assert_equal bytes_before, File.read(task_file)
          end

          def test_active_executor_conflict_escalates_without_overwriting
            worktree = prepare_worktree(@task_ref)
            assignment_id = create_running_assignment(worktree)

            snapshot = worktree_snapshot(worktree)

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--to", "overseer", "--format", "json")
            refute status.success?, "conflict never exits 0: #{out}#{err}"
            assert_includes err, "active_executor"
            payload = JSON.parse(out)
            assert_equal "active_executor", payload["conflict"]["kind"]
            assert_includes payload["conflict"]["detail"], assignment_id
            assert_nil payload["worktree"]
            assert payload["conflict"]["hitl_event"], "escalation event created"

            assert_equal 1, hitl_events.size
            content = File.read(hitl_events.first)
            assert_includes content, "type: question"
            assert_includes content, "kind: decision"
            assert_includes content, "task: #{@task_ref}"

            # The executor's work is preserved untouched.
            assert_equal snapshot, worktree_snapshot(worktree)
          end

          def test_mismatched_worktree_conflict_escalates
            # The task's expected worktree location is occupied by a foreign
            # (non-empty, non-task) directory, so creation cannot take its
            # slot and preparation must escalate instead of overwriting.
            expected = expected_worktree_path(@task_ref)
            FileUtils.mkdir_p(expected)
            File.write(File.join(expected, "occupant"), "foreign worktree data")

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--to", "overseer", "--format", "json")
            refute status.success?, "mismatch conflict never exits 0: #{out}#{err}"
            assert_includes err, "mismatched_worktree"
            payload = JSON.parse(out)
            assert_equal "mismatched_worktree", payload["conflict"]["kind"]
            assert payload["conflict"]["hitl_event"], "escalation event created"
            assert_equal 1, hitl_events.size
          end

          def test_stale_metadata_dry_run_reports_would_recover_and_real_run_recovers
            worktree = prepare_worktree(@task_ref)
            # Stale metadata: the registration survives, the directory is gone.
            FileUtils.remove_entry(worktree)
            refute File.directory?(worktree)

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--dry-run", "--format", "json")
            assert status.success?, "stale dry-run is a would-be recovery: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "would_recover", payload["worktree"]["disposition"]
            assert_equal worktree, payload["worktree"]["path"]
            refute File.directory?(worktree), "dry-run never materializes the worktree"
            assert_empty hitl_events

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--format", "json")
            assert status.success?, "real prepare recovers stale metadata: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "recovered", payload["worktree"]["disposition"]
            assert_equal worktree, payload["worktree"]["path"]
            assert File.directory?(worktree), "worktree materialized again"
          end

          def test_dry_run_resolves_without_effects
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--dry-run", "--format", "json")
            assert status.success?, "dry-run of a fresh task would create: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "would_create", payload["worktree"]["disposition"]

            assert_empty Dir.glob(File.join(@dir, ".ace-wt", "*")), "no worktree materialized"
            assert_empty hitl_events
          end

          def test_unknown_task_fails_without_events
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", "8xh.t.zzz", "--roles", "worker")
            refute status.success?
            assert_equal "task '8xh.t.zzz' not found in this worktree", err.strip
            assert_empty hitl_events
          end

          private

          def prepare_worktree(task_ref)
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", task_ref, "--roles", "worker", "--format", "json")
            assert status.success?, "fixture prepare failed: #{out}#{err}"
            JSON.parse(out)["worktree"]["path"]
          end

          def expected_worktree_path(task_ref)
            Dir.chdir(@dir) do
              manager = Ace::Git::Worktree::Organisms::WorktreeManager.new(project_root: @dir)
              preview = manager.create_task(task_ref, {dry_run: true})
              assert preview[:success], "dry-run preview failed: #{preview.inspect}"
              preview.dig(:would_create, :worktree_path)
            end
          end

          def create_running_assignment(worktree)
            job = File.join(@dir, "job.yaml")
            File.write(job, <<~YAML)
              assignment:
                name: fixture-executor
                description: Occupy the worktree as a commissioned executor
                task_id: #{@task_ref}
              steps:
                - name: work-step
                  instructions: |
                    Do the work.
            YAML
            out, err, _status = run_cli(ASSIGN_BIN, "create", "--yaml", job, chdir: worktree)
            assignment_id = out[/Assignment: .* \((\w+)\)/, 1]
            refute_nil assignment_id, "ace-assign create returned no id: #{err}#{out}"

            config_dir = File.join(worktree, ".ace-local", "coworker")
            FileUtils.mkdir_p(config_dir)
            File.write(File.join(config_dir, "config.yml"), <<~YAML)
              role: worker
              instructions: roles/worker.md
              start_prompt: "Drive assignment #{assignment_id}."
              task: #{@task_ref}
              assignment: #{assignment_id}
              overseer: overseer
            YAML

            run_cli(ASSIGN_BIN, "start", "--assignment", assignment_id, chdir: worktree)
            assignment_id
          end

          def worktree_snapshot(worktree)
            Dir.glob(File.join(worktree, "**", "*"), File::FNM_DOTMATCH)
              .reject { |p| File.basename(p) == ".git" }
              .sort
              .map { |p| [p, File.file?(p) ? Digest::MD5.file(p).to_s : :dir] }
          end

          def write_worktree_config
            dir = File.join(@dir, ".ace", "git")
            FileUtils.mkdir_p(dir)
            File.write(File.join(dir, "worktree.yml"), <<~YAML)
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
          end

          def write_hitl_config
            hitl_dir = File.join(@dir, ".ace", "hitl")
            FileUtils.mkdir_p(hitl_dir)
            File.write(File.join(hitl_dir, "config.yml"), YAML.dump(
              "hitl" => {
                "machine" => "lab01",
                "recipients" => {"overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"}}
              }
            ))
          end

          def hitl_events
            Dir.glob(File.join(@dir, ".ace-local", "hitl", "**", "*.hitl.s.md"))
          end

          # The executor/HITL probes prefer a project-root binstub; provide
          # wrappers delegating to the repo's pinned binstubs so subprocesses
          # never resolve stale installed gems through mise shims.
          def copy_binstubs
            bin_dir = File.join(@dir, "bin")
            FileUtils.mkdir_p(bin_dir)
            %w[ace-assign ace-hitl].each do |name|
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
            previous = ENV["BUNDLE_GEMFILE"]
            ENV["BUNDLE_GEMFILE"] = File.join(REPO_ROOT, "Gemfile")
            Open3.capture3(*argv, chdir: chdir)
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
