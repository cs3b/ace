# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/molecules/ordinary_worktree_read"

module Ace
  module Lab
    module Molecules
      class OrdinaryWorktreeReadTest < Minitest::Test
        ERROR = Ace::Assign::AttemptErrors::EvidenceUnavailable
        PROCESS = Ace::Herdr::Molecules::BoundedProcess

        def test_real_linked_worktree_reads_worker_head_and_ignores_ambient_git_selection
          with_repository do
            FileUtils.mkdir_p(File.join(@worker, "nested"))
            git(@worker, "commit", "--allow-empty", "-m", "worker")
            worker_head = git(@worker, "rev-parse", "HEAD").strip
            refute_equal git(@repo, "rev-parse", "HEAD").strip, worker_head
            previous = ENV["GIT_DIR"]
            ENV["GIT_DIR"] = File.join(@repo, ".git")
            result = reader.observe(File.join(@worker, "nested"))
            assert_equal worker_head, result.fetch("head")
            assert_equal @worker, result.fetch("worktree")
            assert_equal @common, result.fetch("common_dir")
            assert_equal File.join(@worker, "nested"), result.fetch("cwd")
          ensure
            ENV["GIT_DIR"] = previous
          end
        end

        def test_foreign_checkout_and_symlinked_root_or_git_pointer_are_refused
          with_repository do
            foreign = File.join(@root, "foreign")
            git(@repo, "init", foreign)
            assert_raises(ERROR) { reader.observe(foreign) }
            assert_raises(ERROR) { reader.observe(@repo) }
            alias_path = File.join(@root, "alias")
            File.symlink(@worker, alias_path)
            assert_raises(ERROR) { reader.observe(alias_path) }
            marker = File.join(@worker, ".git")
            original = File.binread(marker)
            File.unlink(marker)
            pointer = File.join(@root, "pointer")
            File.binwrite(pointer, original)
            File.symlink(pointer, marker)
            assert_raises(ERROR) { reader.observe(@worker) }
          end
        end

        def test_redirected_common_directory_backpointer_and_configuration_are_refused
          with_repository do
            selected = reader.observe(@worker).fetch("git_dir")
            {File.join(selected, "commondir") => "/foreign\n",
             File.join(selected, "gitdir") => "/foreign/.git\n",
             File.join(@common, "config") => "[include]\npath=/foreign/config\n"}.each do |path, bad|
              original = File.binread(path)
              File.binwrite(path, bad)
              assert_raises(ERROR) { reader.observe(@worker) }
              File.binwrite(path, original)
            end
            File.write(File.join(@common, "objects/info/alternates"), "/foreign/objects\n")
            assert_raises(ERROR) { reader.observe(@worker) }
          end
        end

        def test_checkout_change_between_reads_is_not_accepted
          with_repository do
            original = PROCESS.method(:call)
            changed = false
            PROCESS.stub(:call, ->(argv, **options) {
              result = original.call(argv, **options)
              if argv.include?("HEAD^{commit}") && !changed
                changed = true
                git(@worker, "commit", "--allow-empty", "-m", "moved")
              end
              result
            }) do
              assert_raises(ERROR) { reader.observe(@worker) }
            end
            assert changed
          end
        end

        def test_regular_checkout_common_redirect_and_inner_storage_symlinks_are_refused
          with_repository do
            regular = OrdinaryWorktreeRead.new(root: @repo, common_dir: @common,
              deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 3)
            assert_equal git(@repo, "rev-parse", "HEAD").strip, regular.observe(@repo).fetch("head")
            redirect = File.join(@common, "commondir")
            File.write(redirect, "/foreign/.git\n")
            assert_raises(ERROR) { regular.observe(@repo) }
            File.unlink(redirect)
            branch = File.join(@common, "refs/heads/worker")
            moved = File.join(@root, "branch")
            File.rename(branch, moved)
            File.symlink(moved, branch)
            assert_raises(ERROR) { reader.observe(@worker) }
            File.unlink(branch)
            File.rename(moved, branch)
            object = Dir.glob(File.join(@common, "objects/??/*")).first
            moved = File.join(@root, "object")
            File.rename(object, moved)
            File.symlink(moved, object)
            assert_raises(ERROR) { reader.observe(@worker) }
          end
        end

        def test_repository_helpers_and_ambient_config_never_execute
          with_repository do
            marker = File.join(@root, "helper-ran")
            helper = File.join(@root, "helper")
            File.write(helper, "#!/bin/sh\ntouch #{marker}\n")
            File.chmod(0700, helper)
            git(@worker, "config", "core.fsmonitor", helper)
            git(@worker, "config", "core.hooksPath", @root)
            git(@worker, "config", "diff.external", helper)
            previous = ENV["GIT_CONFIG_COUNT"]
            ENV["GIT_CONFIG_COUNT"] = "not-an-integer"
            assert_match(/\A[0-9a-f]{40}\z/, reader.observe(@worker).fetch("head"))
            refute File.exist?(marker)
          ensure
            ENV["GIT_CONFIG_COUNT"] = previous
          end
        end

        def test_original_deadline_bounds_git_and_expired_observation
          with_repository do
            assert_raises(ERROR) { reader(timeout: -1).observe(@worker) }
            original = PROCESS.method(:call)
            PROCESS.stub(:call, ->(_argv, **options) {
              original.call([RbConfig.ruby, "-e", "sleep 10"], **options)
            }) do
              before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
              assert_raises(ERROR) { reader(timeout: 0.1).observe(@worker) }
              assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - before, :<, 1.5
            end
          end
        end

        private

        def reader(timeout: 3)
          OrdinaryWorktreeRead.new(root: @root, common_dir: @common,
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout)
        end

        def with_repository
          Dir.mktmpdir("ordinary-worktree-", Etc.getpwuid(Process.uid).dir) do |directory|
            @repo = File.join(directory, "project")
            @root = File.join(directory, "workers")
            @worker = File.join(@root, "worker")
            @common = File.join(@repo, ".git")
            FileUtils.mkdir_p([@repo, @root])
            git(@repo, "init", "-b", "main")
            git(@repo, "config", "user.name", "test")
            git(@repo, "config", "user.email", "test@example.invalid")
            git(@repo, "commit", "--allow-empty", "-m", "initial")
            git(@repo, "worktree", "add", "-b", "worker", @worker)
            yield
          end
        end

        def git(directory, *args)
          output, error, status = Open3.capture3("/usr/bin/git", "-C", directory, *args)
          raise error unless status.success?
          output
        end
      end
    end
  end
end
