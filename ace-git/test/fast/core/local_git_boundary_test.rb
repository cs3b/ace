# frozen_string_literal: true

require "test_helper"

module Core
  # Boundary proof: local Git operations succeed with the system scrubbed of
  # any provider CLI. Only `git` itself remains reachable on PATH.
  class LocalGitBoundaryTest < AceGitTestCase
    def setup
      super
      @original_path = ENV["PATH"]
    end

    def teardown
      ENV["PATH"] = @original_path
      super
    end

    def test_local_git_operations_succeed_without_provider_clis_on_path
      Dir.mktmpdir do |scratch|
        Dir.mktmpdir do |bin_dir|
          git_bin = File.join(bin_dir, "git")
          git_real = File.realpath(ResolvedSystem.git_path)
          File.symlink(git_real, git_bin)

          ENV["PATH"] = bin_dir
          assert_nil ResolvedSystem.which("gh"), "gh must be absent from the scrubbed PATH"
          assert_nil ResolvedSystem.which("fj"), "fj must be absent from the scrubbed PATH"

          Dir.chdir(scratch) do
            system(git_bin, "init", "--quiet", "-b", "main", ".") || flunk("git init failed")
            system(git_bin, "config", "user.email", "test@example.com")
            system(git_bin, "config", "user.name", "Test")
            File.write("README.md", "offline\n")
            system(git_bin, "add", "README.md")
            system(git_bin, "commit", "--quiet", "-m", "offline commit")

            # Local-only read operations through the core molecules
            branch = Ace::Git::Molecules::BranchReader.current_branch
            assert_equal "main", branch

            status = Ace::Git::Molecules::GitStatusFetcher.fetch_status_sb
            assert status[:success], "git status -sb must succeed offline"

            commits = Ace::Git::Molecules::RecentCommitsFetcher.fetch(limit: 3)
            assert commits[:success], "git log must succeed offline"
            assert_equal 1, commits[:commits].length

            checker = Ace::Git::Atoms::RepositoryChecker
            assert checker.usable?, "repository must remain usable offline"
          end
        end
      end
    end

    # Minimal PATH-aware lookup helpers (kept local to the test to avoid
    # depending on external gems).
    module ResolvedSystem
      module_function

      def git_path
        which("git") || flunk("git must be installed for the test harness")
      end

      def which(binary)
        ENV["PATH"].to_s.split(File::PATH_SEPARATOR).each do |dir|
          candidate = File.join(dir, binary)
          return candidate if File.file?(candidate) && File.executable?(candidate)
        end
        nil
      end
    end
  end
end
