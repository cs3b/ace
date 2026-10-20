# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"
require "open3"
require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        # End-to-end preparation of multi-level (third/fourth level) task
        # ids: the whole subtask segment chain must survive into the
        # worktree directory and branch names (deterministic, reversible),
        # two distinct deep leaves never collide, re-preparation is a
        # zero-write reuse, and dry-run agrees with the real execution.
        class PrepareNestedTaskIntegrationTest < AceCoworkerTestCase
          REPO_ROOT = File.expand_path("../../..", __dir__)
          COWORKER_BIN = File.join(REPO_ROOT, "bin", "ace-coworker")

          def setup
            super
            @dir = Dir.mktmpdir("coworker-prepare-nested")
            @root = File.realpath(@dir)
            FileUtils.mkdir_p(File.join(@dir, ".ace-tasks"))
            run_git("init", "-q", "-b", "main", @dir)
            File.write(File.join(@dir, ".gitignore"), ".ace-local/\n")
            build_nested_task(root_id: "8xh.t.eee", title: "nested fixture")
            build_nested_task(root_id: "8xh.t.fff", title: "other nested fixture")
            write_worktree_config
            copy_binstubs
            commit_all("tasks")
          end

          def teardown
            FileUtils.remove_entry(@dir)
          end

          def test_third_level_prepare_creates_identity_preserving_worktree_and_reuses
            leaf = "8xh.t.eee.0.0"
            worktree = prepare_leaf(leaf)

            # The full subtask chain survives in directory and branch names.
            assert_equal File.join(@root, ".ace-wt", "t.eee.0.0"), worktree
            branch = current_branch(worktree)
            assert_match(/\Aeee\.0\.0-/, branch)

            # A second identical prepare is a zero-write reuse, never a
            # mismatched_worktree conflict.
            status_before = run_git("-C", worktree, "status", "--porcelain")[0]
            task_file = Dir.glob(File.join(@dir, ".ace-tasks", "**", "*.s.md")).first
            bytes_before = File.read(task_file)

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", leaf, "--roles", "worker", "--to", "overseer", "--format", "json")
            assert status.success?, "re-prepare failed: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "reused", payload["worktree"]["disposition"]
            assert_equal worktree, payload["worktree"]["path"]
            assert_nil payload["conflict"]

            assert_equal status_before, run_git("-C", worktree, "status", "--porcelain")[0]
            assert_equal bytes_before, File.read(task_file)
          end

          def test_distinct_deep_leaves_get_separate_correctly_named_worktrees
            third = prepare_leaf("8xh.t.eee.0.0")
            fourth = prepare_leaf("8xh.t.fff.0.0.0")

            assert_equal File.join(@root, ".ace-wt", "t.eee.0.0"), third
            assert_equal File.join(@root, ".ace-wt", "t.fff.0.0.0"), fourth
            assert_match(/\Afff\.0\.0\.0-/, current_branch(fourth))
            assert_equal %w[t.eee.0.0 t.fff.0.0.0].sort, worktrees_on_disk.sort
          end

          def test_dry_run_agrees_with_execution_for_deep_leaves
            leaf = "8xh.t.eee.0.0"

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", leaf, "--roles", "worker", "--dry-run", "--format", "json")
            assert status.success?, "dry-run failed: #{out}#{err}"
            assert_equal "would_create", JSON.parse(out)["worktree"]["disposition"]
            assert_empty worktrees_on_disk

            worktree = prepare_leaf(leaf)
            assert_equal File.join(@root, ".ace-wt", "t.eee.0.0"), worktree

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", leaf, "--roles", "worker", "--to", "overseer", "--dry-run", "--format", "json")
            assert status.success?, "second dry-run failed: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "reused", payload["worktree"]["disposition"]
            assert_equal worktree, payload["worktree"]["path"]
            assert_nil payload["conflict"]
          end

          private

          def prepare_leaf(task_ref)
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", task_ref, "--roles", "worker", "--to", "overseer", "--format", "json")
            assert status.success?, "prepare of #{task_ref} failed: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "created", payload["worktree"]["disposition"]
            worktree = payload["worktree"]["path"]
            assert File.directory?(worktree), "worktree created on disk"
            worktree
          end

          def current_branch(worktree)
            out, = run_git("-C", worktree, "rev-parse", "--abbrev-ref", "HEAD")
            out.strip
          end

          def worktrees_on_disk
            root = File.join(@dir, ".ace-wt")
            Dir.exist?(root) ? Dir.children(root) : []
          end

          # Mirrors the real nested `.ace-tasks/` tree: root spec, child
          # spec under `0-child/`, leaf specs under `0-leaf/` and one more
          # level below, each spec carrying its full hierarchical id.
          def build_nested_task(root_id:, title:)
            root_dir = File.join(@dir, ".ace-tasks", "#{root_id}-root")
            child_dir = File.join(root_dir, "0-child")
            leaf_dir = File.join(child_dir, "0-leaf")
            FileUtils.mkdir_p(leaf_dir)

            write_spec(root_dir, id: root_id, title: title)
            write_spec(child_dir, id: "#{root_id}.0", title: "#{title} child")
            write_spec(leaf_dir, id: "#{root_id}.0.0", title: "#{title} leaf")

            deep_dir = File.join(leaf_dir, "0-deep")
            FileUtils.mkdir_p(deep_dir)
            write_spec(deep_dir, id: "#{root_id}.0.0.0", title: "#{title} deep leaf")
          end

          def write_spec(dir, id:, title:)
            File.write(File.join(dir, "#{id}-fixture.s.md"), <<~SPEC)
              ---
              id: #{id}
              status: pending
              priority: medium
              created_at: "2026-10-18 00:00:00"
              title: "#{title}"
              ---

              # #{title}

              Fixture body.
            SPEC
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

          # The executor probe prefers a project-root binstub; provide a
          # wrapper delegating to the repo's pinned binstub so subprocesses
          # never resolve stale installed gems through mise shims.
          def copy_binstubs
            bin_dir = File.join(@dir, "bin")
            FileUtils.mkdir_p(bin_dir)
            %w[ace-assign].each do |name|
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
