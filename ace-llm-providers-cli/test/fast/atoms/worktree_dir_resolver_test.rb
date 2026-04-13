# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/atoms/worktree_dir_resolver"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          class WorktreeDirResolverTest < Minitest::Test
            def setup
              @resolver = WorktreeDirResolver.new
            end

            def test_returns_nil_for_regular_git_repo
              Dir.mktmpdir do |tmpdir|
                # Regular repo: .git is a directory
                FileUtils.mkdir_p(File.join(tmpdir, ".git"))

                result = @resolver.call(working_dir: tmpdir)
                assert_nil result
              end
            end

            def test_returns_nil_for_non_git_directory
              Dir.mktmpdir do |tmpdir|
                # No .git at all
                result = @resolver.call(working_dir: tmpdir)
                assert_nil result
              end
            end

            def test_returns_common_git_dir_for_worktree
              Dir.mktmpdir do |tmpdir|
                # Simulate worktree structure:
                # tmpdir/repo/.git/          (common git dir with refs/)
                # tmpdir/repo/.git/worktrees/my-worktree/  (worktree metadata)
                # tmpdir/worktree/.git       (file pointing to worktree metadata)

                common_git = File.join(tmpdir, "repo", ".git")
                worktree_meta = File.join(common_git, "worktrees", "my-worktree")
                worktree_dir = File.join(tmpdir, "worktree")

                FileUtils.mkdir_p(File.join(common_git, "refs"))
                FileUtils.mkdir_p(worktree_meta)
                FileUtils.mkdir_p(worktree_dir)

                File.write(File.join(worktree_dir, ".git"), "gitdir: #{worktree_meta}\n")

                result = @resolver.call(working_dir: worktree_dir)
                assert_equal common_git, result
              end
            end

            def test_handles_relative_gitdir_path
              Dir.mktmpdir do |tmpdir|
                # Simulate worktree with relative gitdir path
                common_git = File.join(tmpdir, "repo", ".git")
                worktree_meta = File.join(common_git, "worktrees", "my-worktree")
                worktree_dir = File.join(tmpdir, "repo", "my-worktree")

                FileUtils.mkdir_p(File.join(common_git, "refs"))
                FileUtils.mkdir_p(worktree_meta)
                FileUtils.mkdir_p(worktree_dir)

                # Relative path from worktree to gitdir
                File.write(File.join(worktree_dir, ".git"), "gitdir: ../.git/worktrees/my-worktree\n")

                result = @resolver.call(working_dir: worktree_dir)
                assert_equal common_git, result
              end
            end

            def test_returns_nil_for_git_file_without_gitdir_prefix
              Dir.mktmpdir do |tmpdir|
                # .git file but not a gitdir: reference
                File.write(File.join(tmpdir, ".git"), "some random content\n")

                result = @resolver.call(working_dir: tmpdir)
                assert_nil result
              end
            end

            def test_class_method_delegates_to_instance
              Dir.mktmpdir do |tmpdir|
                FileUtils.mkdir_p(File.join(tmpdir, ".git"))

                result = WorktreeDirResolver.call(working_dir: tmpdir)
                assert_nil result
              end
            end
          end
        end
      end
    end
  end
end
