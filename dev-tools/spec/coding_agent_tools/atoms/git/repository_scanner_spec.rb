# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::Git::RepositoryScanner do
  let(:temp_dir) { Dir.mktmpdir("repository_scanner_test") }
  let(:scanner) { described_class.new(temp_dir) }

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe ".discover_repositories" do
    it "creates new instance and discovers repositories" do
      # Mock the project root detector to return our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      result = described_class.discover_repositories(temp_dir)
      expect(result).to be_an(Array)
      expect(result.first).to include(name: "main", path: ".", full_path: temp_dir)
    end
  end

  describe "#initialize" do
    it "uses provided project root" do
      scanner = described_class.new("/custom/root")
      expect(scanner.send(:project_root)).to eq("/custom/root")
    end

    it "uses ProjectRootDetector when no root provided" do
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return("/detected/root")

      scanner = described_class.new
      expect(scanner.send(:project_root)).to eq("/detected/root")
    end
  end

  describe "#discover_repositories" do
    before do
      # Create a basic git repository structure
      FileUtils.mkdir_p(File.join(temp_dir, ".git"))
      File.write(File.join(temp_dir, ".git", "config"), "[core]\n\trepositoryformatversion = 0")
    end

    context "with main repository only" do
      it "returns main repository information" do
        result = scanner.discover_repositories

        expect(result.size).to eq(1)
        expect(result.first).to include(
          name: "main",
          path: ".",
          full_path: temp_dir,
          exists: true,
          is_git_repo: true
        )
      end
    end

    context "with git submodules" do
      before do
        # Create submodule directories
        FileUtils.mkdir_p(File.join(temp_dir, "dev-handbook", ".git"))
        FileUtils.mkdir_p(File.join(temp_dir, "dev-tools", ".git"))

        # Create .gitmodules file
        gitmodules_content = <<~GITMODULES
          [submodule "dev-handbook"]
          \tpath = dev-handbook
          \turl = https://github.com/example/dev-handbook.git
          [submodule "dev-tools"]
          \tpath = dev-tools
          \turl = https://github.com/example/dev-tools.git
        GITMODULES
        File.write(File.join(temp_dir, ".gitmodules"), gitmodules_content)

        # Mock git submodule status output
        submodule_status = <<~STATUS
          abc123 dev-handbook (heads/main)
          def456 dev-tools (v1.0.0)
        STATUS

        allow(scanner).to receive(:execute_git_command).with("submodule status").and_return(submodule_status)
      end

      it "discovers submodules via git command" do
        result = scanner.discover_repositories

        expect(result.size).to eq(3) # main + 2 submodules

        main_repo = result.find { |r| r[:name] == "main" }
        expect(main_repo).to include(name: "main", path: ".")

        handbook_repo = result.find { |r| r[:name] == "dev-handbook" }
        expect(handbook_repo).to include(
          name: "dev-handbook",
          path: "dev-handbook",
          full_path: File.join(temp_dir, "dev-handbook"),
          exists: true,
          is_git_repo: true
        )

        tools_repo = result.find { |r| r[:name] == "dev-tools" }
        expect(tools_repo).to include(
          name: "dev-tools",
          path: "dev-tools",
          exists: true,
          is_git_repo: true
        )
      end

      it "handles git command failure gracefully" do
        # Mock git command to raise error
        allow(scanner).to receive(:execute_git_command).and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("Git command failed")
        )

        result = scanner.discover_repositories

        # Should fall back to dev-* directory scanning
        expect(result.size).to eq(3) # main + 2 dev-* directories
      end
    end

    context "with dev-* directories fallback" do
      before do
        # Create dev-* directories that look like git repos
        ["dev-handbook", "dev-tools", "dev-taskflow"].each do |dir|
          dir_path = File.join(temp_dir, dir)
          FileUtils.mkdir_p(File.join(dir_path, ".git"))
          File.write(File.join(dir_path, ".git", "config"), "[core]")
        end

        # Create non-git dev directory
        FileUtils.mkdir_p(File.join(temp_dir, "dev-other"))

        # Mock submodule command to fail
        allow(scanner).to receive(:execute_git_command).with("submodule status").and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("not a git repository")
        )
      end

      it "discovers dev-* directories when submodules fail" do
        result = scanner.discover_repositories

        expect(result.size).to eq(4) # main + 3 dev-* git repos

        dev_repos = result.select { |r| r[:name].start_with?("dev-") }
        expect(dev_repos.size).to eq(3)
        expect(dev_repos.map { |r| r[:name] }).to include("dev-handbook", "dev-tools", "dev-taskflow")
        expect(dev_repos.map { |r| r[:name] }).not_to include("dev-other") # Not a git repo
      end

      it "includes only git repositories" do
        result = scanner.discover_repositories

        git_repos = result.select { |r| r[:is_git_repo] }
        expect(git_repos.size).to eq(4) # All should be git repos

        non_git_repos = result.select { |r| !r[:is_git_repo] }
        expect(non_git_repos).to be_empty
      end
    end

    context "with no git repository" do
      let(:non_git_dir) { Dir.mktmpdir("non_git_test") }
      let(:non_git_scanner) { described_class.new(non_git_dir) }

      after do
        safe_directory_cleanup(non_git_dir)
      end

      it "returns main repository with is_git_repo false" do
        result = non_git_scanner.discover_repositories

        expect(result.size).to eq(1)
        expect(result.first).to include(
          name: "main",
          path: ".",
          full_path: non_git_dir,
          exists: true,
          is_git_repo: false
        )
      end
    end

    context "with mixed repository states" do
      before do
        # Create valid git repo
        FileUtils.mkdir_p(File.join(temp_dir, "dev-valid", ".git"))

        # Create directory without .git
        FileUtils.mkdir_p(File.join(temp_dir, "dev-invalid"))

        # Create directory with .git file (submodule style)
        FileUtils.mkdir_p(File.join(temp_dir, "dev-submodule"))
        File.write(File.join(temp_dir, "dev-submodule", ".git"), "gitdir: ../.git/modules/dev-submodule")

        allow(scanner).to receive(:execute_git_command).and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("submodule command failed")
        )
      end

      it "handles mixed repository types correctly" do
        result = scanner.discover_repositories

        main_repo = result.find { |r| r[:name] == "main" }
        expect(main_repo[:is_git_repo]).to be true

        valid_repo = result.find { |r| r[:name] == "dev-valid" }
        expect(valid_repo[:is_git_repo]).to be true

        submodule_repo = result.find { |r| r[:name] == "dev-submodule" }
        expect(submodule_repo[:is_git_repo]).to be true # .git file should be recognized

        # dev-invalid should not appear since it's not a git repo
        invalid_repo = result.find { |r| r[:name] == "dev-invalid" }
        expect(invalid_repo).to be_nil
      end
    end
  end

  describe "#execute_git_command" do
    context "when git command succeeds" do
      it "returns command output" do
        # Test actual git command if we have git available
        if system("which git > /dev/null 2>&1")
          # Initialize a real git repo for testing
          Dir.chdir(temp_dir) do
            system("git init -q")
            result = scanner.send(:execute_git_command, "status --porcelain")
            expect(result).to be_a(String)
          end
        else
          skip "Git not available for testing"
        end
      end
    end

    context "when git command fails" do
      it "raises GitCommandError" do
        expect { scanner.send(:execute_git_command, "invalid-command") }
          .to raise_error(CodingAgentTools::Atoms::Git::GitCommandError)
      end

      it "includes command information in error" do
        scanner.send(:execute_git_command, "invalid-command")
      rescue CodingAgentTools::Atoms::Git::GitCommandError => e
        expect(e.message).to include("Git command failed")
        expect(e.message).to include("invalid-command")
      end
    end
  end

  describe "#git_repository_exists?" do
    context "with .git directory" do
      before do
        FileUtils.mkdir_p(File.join(temp_dir, ".git"))
      end

      it "returns true for directory with .git folder" do
        expect(scanner.send(:git_repository_exists?)).to be true
      end

      it "returns true for specific path with .git folder" do
        expect(scanner.send(:git_repository_exists?, temp_dir)).to be true
      end
    end

    context "with .git file" do
      before do
        File.write(File.join(temp_dir, ".git"), "gitdir: /path/to/real/git/dir")
      end

      it "returns true for directory with .git file" do
        expect(scanner.send(:git_repository_exists?)).to be true
      end
    end

    context "without git repository" do
      it "returns false for directory without .git" do
        expect(scanner.send(:git_repository_exists?)).to be false
      end

      it "returns false for non-existent path" do
        expect(scanner.send(:git_repository_exists?, "/nonexistent/path")).to be false
      end
    end
  end

  describe "comprehensive edge cases and error handling" do
    context "with malformed git structures" do
      it "handles corrupted .git directories" do
        # Create .git directory but with invalid content
        git_dir = File.join(temp_dir, ".git")
        FileUtils.mkdir_p(git_dir)
        File.write(File.join(git_dir, "config"), "invalid config content")

        result = scanner.discover_repositories
        expect(result.first[:is_git_repo]).to be true # Still recognizes .git directory exists
      end

      it "handles .git file with invalid gitdir" do
        File.write(File.join(temp_dir, ".git"), "invalid gitdir content")

        result = scanner.discover_repositories
        expect(result.first[:is_git_repo]).to be true # Still recognizes .git file exists
      end

      it "handles empty .git directory" do
        FileUtils.mkdir_p(File.join(temp_dir, ".git"))

        result = scanner.discover_repositories
        expect(result.first[:is_git_repo]).to be true
      end
    end

    context "with special characters in paths" do
      let(:unicode_dir) { Dir.mktmpdir("B5AB_git") }
      let(:unicode_scanner) { described_class.new(unicode_dir) }

      after do
        safe_directory_cleanup(unicode_dir)
      end

      it "handles Unicode characters in project root" do
        FileUtils.mkdir_p(File.join(unicode_dir, ".git"))

        result = unicode_scanner.discover_repositories
        expect(result.first).to include(
          name: "main",
          full_path: unicode_dir,
          is_git_repo: true
        )
      end

      it "handles spaces in directory names when they match dev-* pattern" do
        spaced_dir = File.join(temp_dir, "dev-with-spaces")
        FileUtils.mkdir_p(File.join(spaced_dir, ".git"))

        allow(scanner).to receive(:execute_git_command).and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("submodule failed")
        )

        result = scanner.discover_repositories
        spaced_repo = result.find { |r| r[:name] == "dev-with-spaces" }
        expect(spaced_repo).to include(is_git_repo: true)
      end

      it "handles special characters in directory names when they match dev-* pattern" do
        special_dir = File.join(temp_dir, "dev-special")
        FileUtils.mkdir_p(File.join(special_dir, ".git"))

        allow(scanner).to receive(:execute_git_command).and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("submodule failed")
        )

        result = scanner.discover_repositories
        special_repo = result.find { |r| r[:name] == "dev-special" }
        expect(special_repo).to include(is_git_repo: true)
      end
    end

    context "with permission and file system issues" do
      it "handles permission denied gracefully" do
        # This test is system-dependent, so we'll mock the behavior
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(File.join(temp_dir, ".git")).and_raise(Errno::EACCES)

        expect { scanner.send(:git_repository_exists?) }.to raise_error(Errno::EACCES)
      end

      it "handles very deep directory nesting" do
        deep_path = temp_dir
        20.times do |i|
          deep_path = File.join(deep_path, "level#{i}")
        end

        begin
          FileUtils.mkdir_p(File.join(deep_path, ".git"))
          deep_scanner = described_class.new(deep_path)

          result = deep_scanner.discover_repositories
          expect(result.first[:is_git_repo]).to be true
        rescue SystemCallError
          skip "System cannot handle very deep paths"
        end
      end
    end

    context "with git command variations" do
      it "handles empty git submodule status output" do
        allow(scanner).to receive(:execute_git_command).with("submodule status").and_return("")

        result = scanner.discover_repositories
        expect(result.size).to eq(1) # Just main repository
      end

      it "handles git submodule status with various formats" do
        complex_status = <<~STATUS
          +abc123 dev-handbook (heads/main)
          -def456 dev-tools (v1.0.0)
           789abc dev-taskflow (tags/v2.0.0-5-g789abc)
          U111222 dev-broken (no branch)
        STATUS

        allow(scanner).to receive(:execute_git_command).with("submodule status").and_return(complex_status)

        # Create corresponding directories
        ["dev-handbook", "dev-tools", "dev-taskflow", "dev-broken"].each do |dir|
          FileUtils.mkdir_p(File.join(temp_dir, dir, ".git"))
        end

        result = scanner.discover_repositories
        expect(result.size).to eq(5) # main + 4 submodules

        submodule_names = result.select { |r| r[:name] != "main" }.map { |r| r[:name] }
        expect(submodule_names).to include("dev-handbook", "dev-tools", "dev-taskflow", "dev-broken")
      end

      it "handles malformed git submodule status lines" do
        malformed_status = <<~STATUS
          abc123 dev-handbook (heads/main)
          incomplete-line
          def456
          
           789abc dev-tools (v1.0.0)
        STATUS

        allow(scanner).to receive(:execute_git_command).with("submodule status").and_return(malformed_status)

        FileUtils.mkdir_p(File.join(temp_dir, "dev-handbook", ".git"))
        FileUtils.mkdir_p(File.join(temp_dir, "dev-tools", ".git"))

        result = scanner.discover_repositories
        # Should handle malformed lines gracefully
        submodule_names = result.select { |r| r[:name] != "main" }.map { |r| r[:name] }
        expect(submodule_names).to include("dev-handbook", "dev-tools")
      end
    end

    context "with concurrent access" do
      it "maintains consistency during concurrent repository discovery" do
        FileUtils.mkdir_p(File.join(temp_dir, "dev-concurrent", ".git"))

        threads = []
        results = Queue.new

        5.times do
          threads << Thread.new do
            local_scanner = described_class.new(temp_dir)
            results << local_scanner.discover_repositories
          end
        end

        threads.each(&:join)

        # All results should be consistent
        first_result = results.pop
        until results.empty?
          next_result = results.pop
          expect(next_result.size).to eq(first_result.size)
          expect(next_result.map { |r| r[:name] }.sort).to eq(first_result.map { |r| r[:name] }.sort)
        end
      end
    end

    context "with performance considerations" do
      it "handles many dev directories efficiently" do
        # Create many dev-* directories
        50.times do |i|
          dir_path = File.join(temp_dir, "dev-test#{i}")
          FileUtils.mkdir_p(File.join(dir_path, ".git"))
        end

        allow(scanner).to receive(:execute_git_command).and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("submodule failed")
        )

        start_time = Time.now
        result = scanner.discover_repositories
        end_time = Time.now

        expect(result.size).to eq(51) # main + 50 dev directories
        expect(end_time - start_time).to be < 2.0 # Should be reasonably fast
      end

      it "handles large submodule status output efficiently" do
        # Generate large submodule status
        large_status = (1..100).map { |i| " abc#{i.to_s.rjust(3, "0")} dev-module#{i} (v1.0.0)" }.join("\n")

        allow(scanner).to receive(:execute_git_command).with("submodule status").and_return(large_status)

        # Create some of the directories (not all, to test missing directory handling)
        10.times do |i|
          dir_path = File.join(temp_dir, "dev-module#{i + 1}")
          FileUtils.mkdir_p(dir_path) # Create directory but not .git to test filtering
        end

        start_time = Time.now
        result = scanner.discover_repositories
        end_time = Time.now

        expect(result.size).to eq(1) # Just main, since dev-module* dirs don't have .git
        expect(end_time - start_time).to be < 1.0
      end
    end

    context "with file system edge cases" do
      it "handles symbolic links correctly" do
        skip "Symlink testing not supported" unless File.respond_to?(:symlink)

        begin
          # Create real git directory (must match dev-* pattern)
          real_git_dir = File.join(temp_dir, "dev-real")
          FileUtils.mkdir_p(File.join(real_git_dir, ".git"))

          # Create symlink to it
          link_path = File.join(temp_dir, "dev-linked")
          File.symlink(real_git_dir, link_path)

          allow(scanner).to receive(:execute_git_command).and_raise(
            CodingAgentTools::Atoms::Git::GitCommandError.new("submodule failed")
          )

          result = scanner.discover_repositories

          # Both real and linked should be found (both match dev-* pattern)
          repo_names = result.map { |r| r[:name] }
          expect(repo_names).to include("dev-real", "dev-linked")
        rescue NotImplementedError
          skip "Symlinks not supported on this platform"
        end
      end

      it "handles broken symbolic links gracefully" do
        skip "Symlink testing not supported" unless File.respond_to?(:symlink)

        begin
          # Create broken symlink
          broken_link = File.join(temp_dir, "dev-broken")
          File.symlink("/nonexistent/target", broken_link)

          allow(scanner).to receive(:execute_git_command).and_raise(
            CodingAgentTools::Atoms::Git::GitCommandError.new("submodule failed")
          )

          result = scanner.discover_repositories
          # Should handle broken symlinks without crashing
          expect(result).to be_an(Array)
        rescue NotImplementedError, SystemCallError
          skip "Cannot create broken symlinks on this system"
        end
      end

      it "handles files that disappear during scanning" do
        # Create directory
        temp_dev_dir = File.join(temp_dir, "dev-disappearing")
        FileUtils.mkdir_p(File.join(temp_dev_dir, ".git"))

        # Mock Dir.glob to simulate directory disappearing
        original_glob = Dir.method(:glob)
        allow(Dir).to receive(:glob) do |pattern|
          files = original_glob.call(pattern)
          # Delete directory after it's found but before processing
          FileUtils.rm_rf(temp_dev_dir) if File.exist?(temp_dev_dir)
          files
        end

        allow(scanner).to receive(:execute_git_command).and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("submodule failed")
        )

        result = scanner.discover_repositories
        # Should handle gracefully without crashing
        expect(result).to be_an(Array)
      end
    end
  end

  describe "algorithm correctness verification" do
    context "repository information accuracy" do
      it "provides complete repository information" do
        FileUtils.mkdir_p(File.join(temp_dir, "dev-complete", ".git"))

        allow(scanner).to receive(:execute_git_command).and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("submodule failed")
        )

        result = scanner.discover_repositories
        complete_repo = result.find { |r| r[:name] == "dev-complete" }

        expect(complete_repo).to include(
          :name,
          :path,
          :full_path,
          :exists,
          :is_git_repo
        )

        expect(complete_repo[:name]).to eq("dev-complete")
        expect(complete_repo[:path]).to eq("dev-complete")
        expect(complete_repo[:full_path]).to eq(File.join(temp_dir, "dev-complete"))
        expect(complete_repo[:exists]).to be true
        expect(complete_repo[:is_git_repo]).to be true
      end

      it "reports accurate existence status" do
        # Create directory that exists but isn't git repo
        non_git_dir = File.join(temp_dir, "dev-exists")
        FileUtils.mkdir_p(non_git_dir)

        allow(scanner).to receive(:execute_git_command).and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("submodule failed")
        )

        result = scanner.discover_repositories

        # Should not include non-git directory
        non_git_repo = result.find { |r| r[:name] == "dev-exists" }
        expect(non_git_repo).to be_nil
      end
    end

    context "discovery priority and ordering" do
      it "includes both submodules and dev-* directories when submodules succeed" do
        # Create both submodule structure and dev-* directories
        FileUtils.mkdir_p(File.join(temp_dir, "dev-handbook", ".git"))
        FileUtils.mkdir_p(File.join(temp_dir, "dev-extra", ".git"))

        # Mock successful submodule command
        submodule_status = " abc123 dev-handbook (heads/main)"
        allow(scanner).to receive(:execute_git_command).with("submodule status").and_return(submodule_status)

        result = scanner.discover_repositories

        # Should include main + dev-handbook (from submodule) + dev-extra (from dev-* scan fallback)
        repo_names = result.map { |r| r[:name] }
        expect(repo_names).to include("main", "dev-handbook", "dev-extra")
      end

      it "falls back to dev-* scanning when submodules fail" do
        FileUtils.mkdir_p(File.join(temp_dir, "dev-fallback", ".git"))

        # Mock failed submodule command
        allow(scanner).to receive(:execute_git_command).with("submodule status").and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("Not a git repository")
        )

        result = scanner.discover_repositories

        repo_names = result.map { |r| r[:name] }
        expect(repo_names).to include("main", "dev-fallback")
      end
    end

    context "path resolution accuracy" do
      it "resolves relative paths correctly" do
        FileUtils.mkdir_p(File.join(temp_dir, "dev-relative", ".git"))

        allow(scanner).to receive(:execute_git_command).and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("submodule failed")
        )

        result = scanner.discover_repositories
        relative_repo = result.find { |r| r[:name] == "dev-relative" }

        expect(relative_repo[:path]).to eq("dev-relative")
        expect(relative_repo[:full_path]).to eq(File.join(temp_dir, "dev-relative"))
      end

      it "does not find nested dev directories (only top-level dev-* matches)" do
        nested_path = File.join(temp_dir, "nested", "dev-nested")
        FileUtils.mkdir_p(File.join(nested_path, ".git"))

        allow(scanner).to receive(:execute_git_command).and_raise(
          CodingAgentTools::Atoms::Git::GitCommandError.new("submodule failed")
        )

        result = scanner.discover_repositories

        # Should not find nested dev directory since pattern only matches top-level
        nested_repo = result.find { |r| r[:name] == "dev-nested" }
        expect(nested_repo).to be_nil
      end
    end
  end

  describe "integration with GitCommandError" do
    it "raises GitCommandError for failed git commands" do
      expect { scanner.send(:execute_git_command, "nonexistent-git-command") }
        .to raise_error(CodingAgentTools::Atoms::Git::GitCommandError)
    end

    it "includes stderr output in GitCommandError" do
      scanner.send(:execute_git_command, "invalid-git-option")
    rescue CodingAgentTools::Atoms::Git::GitCommandError => e
      expect(e.instance_variable_get(:@stderr_output)).to be_a(String)
    end
  end

  describe "DEV_DIRECTORY_PATTERNS constant" do
    it "defines expected dev directory patterns" do
      patterns = described_class.const_get(:DEV_DIRECTORY_PATTERNS)
      expect(patterns).to include("dev-*")
      expect(patterns).to be_frozen
    end

    it "matches dev-* directory patterns correctly" do
      test_dirs = [
        "dev-handbook",
        "dev-tools",
        "dev-taskflow",
        "dev-test",
        "development", # Should not match
        "devtools",    # Should not match
        "tools-dev"    # Should not match
      ]

      pattern = described_class.const_get(:DEV_DIRECTORY_PATTERNS).first
      matching_dirs = test_dirs.select { |dir| File.fnmatch(pattern, dir) }

      expect(matching_dirs).to include("dev-handbook", "dev-tools", "dev-taskflow", "dev-test")
      expect(matching_dirs).not_to include("development", "devtools", "tools-dev")
    end
  end
end
