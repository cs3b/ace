# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Organisms::Git::GitOrchestrator do
  let(:temp_dir) { Dir.mktmpdir("git_orchestrator_test") }
  let(:project_root) { temp_dir }
  let(:orchestrator) { described_class.new(project_root) }

  before do
    # Mock external dependencies to focus on unit testing
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).and_return([
      {name: "main", path: project_root, full_path: project_root, exists: true, is_git_repo: true},
      {name: "submodule1", path: "submodule1", full_path: File.join(project_root, "submodule1"), exists: true, is_git_repo: true}
    ])
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#initialize" do
    context "with project_root parameter" do
      it "uses the provided project_root" do
        custom_root = "/custom/path"
        expect(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).with(custom_root)
        described_class.new(custom_root)
      end
    end

    context "without project_root parameter" do
      it "uses ProjectRootDetector to find project_root" do
        expect(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
        expect(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).with(project_root)
        described_class.new
      end
    end

    context "with debug option" do
      it "sets debug mode" do
        orchestrator = described_class.new(project_root, debug: true)
        # Access private attribute through instance_variable_get for testing
        expect(orchestrator.instance_variable_get(:@debug)).to be true
      end
    end

    context "without debug option" do
      it "defaults debug to false" do
        orchestrator = described_class.new(project_root)
        expect(orchestrator.instance_variable_get(:@debug)).to be false
      end
    end
  end

  describe "#status" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }
    let(:mock_result) do
      {
        success: true,
        results: {
          "main" => {success: true, stdout: "M  file1.txt\nA  file2.txt"},
          "submodule1" => {success: true, stdout: "?? newfile.txt"}
        }
      }
    end

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(mock_coordinator).to receive(:execute_across_repositories).and_return(mock_result)
    end

    it "creates a MultiRepoCoordinator with project_root" do
      expect(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).with(project_root)
      orchestrator.status
    end

    it "executes status command across repositories" do
      expect(mock_coordinator).to receive(:execute_across_repositories).with("status", {capture_output: true})
      orchestrator.status
    end

    it "formats the status output" do
      allow(orchestrator).to receive(:format_status_output).and_return(mock_result.merge(formatted_output: "formatted"))
      result = orchestrator.status
      expect(result).to have_key(:formatted_output)
    end

    context "with options" do
      it "passes options to the coordinator" do
        options = {verbose: true, debug: true}
        expect(mock_coordinator).to receive(:execute_across_repositories).with("status", options.merge(capture_output: true))
        orchestrator.status(options)
      end
    end
  end

  describe "#log" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }
    let(:mock_result) do
      {
        success: true,
        results: {
          "main" => {success: true, stdout: "abc123 Initial commit (2023-01-01 10:00:00 +0000)"},
          "submodule1" => {success: true, stdout: "def456 Submodule commit (2023-01-02 11:00:00 +0000)"}
        }
      }
    end

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(mock_coordinator).to receive(:execute_across_repositories).and_return(mock_result)
      allow(orchestrator).to receive(:build_log_command).and_return("log --oneline")
      allow(orchestrator).to receive(:format_log_output).and_return(mock_result)
    end

    it "builds log command with options" do
      options = {oneline: true, max_count: 5}
      expect(orchestrator).to receive(:build_log_command).with(options)
      orchestrator.log(options)
    end

    it "executes log command across repositories" do
      expect(mock_coordinator).to receive(:execute_across_repositories).with("log --oneline", {capture_output: true})
      orchestrator.log
    end

    it "formats the log output" do
      expect(orchestrator).to receive(:format_log_output).with(mock_result, {})
      orchestrator.log
    end
  end

  describe "#add" do
    let(:mock_dispatcher) { instance_double(CodingAgentTools::Molecules::Git::PathDispatcher) }
    let(:mock_dispatch_info) do
      {
        "main" => {paths: ["file1.txt", "file2.txt"]},
        "submodule1" => {paths: ["file3.txt"]}
      }
    end

    before do
      allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
      allow(mock_dispatcher).to receive(:dispatch_paths).and_return(mock_dispatch_info)
      allow(orchestrator).to receive(:build_add_commands).and_return({"main" => ["add file1.txt file2.txt"]})
      allow(orchestrator).to receive(:execute_sequentially).and_return({success: true})
    end

    context "with nil paths" do
      it "returns error for nil paths" do
        result = orchestrator.add(nil)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No paths provided")
      end
    end

    context "with empty paths" do
      it "returns error for empty paths" do
        result = orchestrator.add([])
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No paths provided")
      end
    end

    context "with valid paths" do
      let(:paths) { ["file1.txt", "file2.txt", "file3.txt"] }

      it "creates PathDispatcher with project_root" do
        expect(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).with(project_root)
        orchestrator.add(paths)
      end

      it "dispatches paths to repositories" do
        expect(mock_dispatcher).to receive(:dispatch_paths).with(paths)
        orchestrator.add(paths)
      end

      it "builds add commands from dispatch info" do
        expect(orchestrator).to receive(:build_add_commands).with(mock_dispatch_info, {})
        orchestrator.add(paths)
      end

      context "with concurrent option" do
        it "executes concurrently" do
          commands_by_repo = {"main" => ["add file1.txt"]}
          allow(orchestrator).to receive(:build_add_commands).and_return(commands_by_repo)
          expect(CodingAgentTools::Molecules::Git::ConcurrentExecutor).to receive(:execute_concurrently).with(commands_by_repo, {concurrent: true})
          orchestrator.add(paths, {concurrent: true})
        end
      end

      context "without concurrent option" do
        it "executes sequentially" do
          commands_by_repo = {"main" => ["add file1.txt"]}
          allow(orchestrator).to receive(:build_add_commands).and_return(commands_by_repo)
          expect(orchestrator).to receive(:execute_sequentially).with(commands_by_repo, {})
          orchestrator.add(paths)
        end
      end
    end
  end

  describe "#commit" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(orchestrator).to receive(:add).and_return({success: true})
      allow(orchestrator).to receive(:add_all).and_return({success: true})
      allow(orchestrator).to receive(:commit_with_message).and_return({success: true})
      allow(orchestrator).to receive(:commit_with_llm_message).and_return({success: true})
    end

    context "with files option" do
      it "adds specified files before committing" do
        files = ["file1.txt", "file2.txt"]
        expect(orchestrator).to receive(:add).with(files, {files: files})
        orchestrator.commit({files: files})
      end

      context "when add fails" do
        it "returns the add result" do
          files = ["file1.txt"]
          add_result = {success: false, error: "Add failed"}
          allow(orchestrator).to receive(:add).and_return(add_result)
          result = orchestrator.commit({files: files})
          expect(result).to eq(add_result)
        end
      end
    end

    context "without files option and without repo_only" do
      it "runs add_all before committing" do
        expect(orchestrator).to receive(:add_all).with({})
        orchestrator.commit({})
      end

      context "when add_all fails" do
        it "returns the add_all result" do
          add_result = {success: false, error: "Add all failed"}
          allow(orchestrator).to receive(:add_all).and_return(add_result)
          result = orchestrator.commit({})
          expect(result).to eq(add_result)
        end
      end
    end

    context "with repo_only option" do
      it "skips add operations" do
        expect(orchestrator).not_to receive(:add)
        expect(orchestrator).not_to receive(:add_all)
        orchestrator.commit({repo_only: true})
      end
    end

    context "with message option" do
      it "commits with provided message" do
        message = "Test commit message"
        expect(orchestrator).to receive(:commit_with_message).with(message, {message: message})
        orchestrator.commit({message: message})
      end
    end

    context "without message option" do
      it "commits with LLM-generated message" do
        expect(orchestrator).to receive(:commit_with_llm_message).with({})
        orchestrator.commit({})
      end
    end
  end

  describe "#push" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(mock_coordinator).to receive(:execute_across_repositories).and_return({success: true})
      allow(orchestrator).to receive(:build_push_command).and_return("push")
      allow(orchestrator).to receive(:detect_current_repository).and_return("main")
      allow(orchestrator).to receive(:execute_push_concurrent).and_return({success: true})
      allow(orchestrator).to receive(:execute_push_sequential).and_return({success: true})
    end

    it "builds push command with options" do
      options = {force: true, tags: true}
      expect(orchestrator).to receive(:build_push_command).with(options)
      orchestrator.push(options)
    end

    context "with repo_only option" do
      it "pushes only current repository" do
        expect(orchestrator).to receive(:detect_current_repository).and_return("main")
        expect(mock_coordinator).to receive(:execute_across_repositories).with("push", {repo_only: true, repository: "main"})
        orchestrator.push({repo_only: true})
      end
    end

    context "with concurrent option" do
      it "executes push concurrently" do
        expect(orchestrator).to receive(:execute_push_concurrent).with("push", {concurrent: true})
        orchestrator.push({concurrent: true})
      end
    end

    context "without concurrent option" do
      it "executes push sequentially" do
        expect(orchestrator).to receive(:execute_push_sequential).with("push", {})
        orchestrator.push({})
      end
    end
  end

  describe "#pull" do
    before do
      allow(orchestrator).to receive(:build_pull_command).and_return("pull")
      allow(orchestrator).to receive(:execute_pull_concurrent).and_return({success: true})
      allow(orchestrator).to receive(:execute_pull_sequential).and_return({success: true})
    end

    it "builds pull command with options" do
      options = {rebase: true, ff_only: true}
      expect(orchestrator).to receive(:build_pull_command).with(options)
      orchestrator.pull(options)
    end

    context "with concurrent option" do
      it "executes pull concurrently" do
        expect(orchestrator).to receive(:execute_pull_concurrent).with("pull", {concurrent: true})
        orchestrator.pull({concurrent: true})
      end
    end

    context "without concurrent option" do
      it "executes pull sequentially" do
        expect(orchestrator).to receive(:execute_pull_sequential).with("pull", {})
        orchestrator.pull({})
      end
    end
  end

  describe "#diff" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(mock_coordinator).to receive(:execute_across_repositories).and_return({success: true})
      allow(orchestrator).to receive(:build_diff_command).and_return("diff")
    end

    it "builds diff command and executes across repositories" do
      options = {staged: true, name_only: true}
      expect(orchestrator).to receive(:build_diff_command).with(options)
      expect(mock_coordinator).to receive(:execute_across_repositories).with("diff", options.merge(capture_output: true))
      orchestrator.diff(options)
    end
  end

  describe "#fetch" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(mock_coordinator).to receive(:execute_across_repositories).and_return({success: true})
      allow(orchestrator).to receive(:build_fetch_command).and_return("fetch")
    end

    it "builds fetch command and executes across repositories" do
      options = {all: true, prune: true}
      expect(orchestrator).to receive(:build_fetch_command).with(options)
      expect(mock_coordinator).to receive(:execute_across_repositories).with("fetch", options.merge(capture_output: true))
      orchestrator.fetch(options)
    end
  end

  describe "#checkout" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(mock_coordinator).to receive(:execute_across_repositories).and_return({success: true})
      allow(orchestrator).to receive(:build_checkout_command).and_return("checkout main")
    end

    it "builds checkout command and executes across repositories" do
      branch = "main"
      options = {force: true}
      expect(orchestrator).to receive(:build_checkout_command).with(branch, options)
      expect(mock_coordinator).to receive(:execute_across_repositories).with("checkout main", options.merge(capture_output: true))
      orchestrator.checkout(branch, options)
    end

    context "with concurrent option" do
      it "passes concurrent option to coordinator" do
        expect(mock_coordinator).to receive(:execute_across_repositories).with("checkout main", {concurrent: true, capture_output: true})
        orchestrator.checkout("main", {concurrent: true})
      end
    end
  end

  describe "#switch" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(mock_coordinator).to receive(:execute_across_repositories).and_return({success: true})
      allow(orchestrator).to receive(:build_switch_command).and_return("switch feature")
    end

    it "builds switch command and executes across repositories" do
      branch = "feature"
      options = {create: true}
      expect(orchestrator).to receive(:build_switch_command).with(branch, options)
      expect(mock_coordinator).to receive(:execute_across_repositories).with("switch feature", options.merge(capture_output: true))
      orchestrator.switch(branch, options)
    end

    context "with concurrent option" do
      it "passes concurrent option to coordinator" do
        expect(mock_coordinator).to receive(:execute_across_repositories).with("switch feature", {concurrent: true, capture_output: true})
        orchestrator.switch("feature", {concurrent: true})
      end
    end
  end

  describe "#mv" do
    let(:mock_dispatcher) { instance_double(CodingAgentTools::Molecules::Git::PathDispatcher) }
    let(:mock_dispatch_info) { {"main" => {paths: ["old.txt", "new.txt"]}} }

    before do
      allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
      allow(mock_dispatcher).to receive(:dispatch_paths).and_return(mock_dispatch_info)
      allow(orchestrator).to receive(:build_mv_commands).and_return({"main" => ["mv old.txt new.txt"]})
      allow(orchestrator).to receive(:execute_sequentially).and_return({success: true})
    end

    context "with nil sources" do
      it "returns error for nil sources" do
        result = orchestrator.mv(nil, "dest.txt")
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No sources provided")
      end
    end

    context "with empty sources" do
      it "returns error for empty sources" do
        result = orchestrator.mv([], "dest.txt")
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No sources provided")
      end
    end

    context "with nil destination" do
      it "returns error for nil destination" do
        result = orchestrator.mv(["src.txt"], nil)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No destination provided")
      end
    end

    context "with empty destination" do
      it "returns error for empty destination" do
        result = orchestrator.mv(["src.txt"], "")
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No destination provided")
      end
    end

    context "with valid parameters" do
      let(:sources) { ["old.txt"] }
      let(:destination) { "new.txt" }

      it "dispatches all paths including sources and destination" do
        all_paths = sources + [destination]
        expect(mock_dispatcher).to receive(:dispatch_paths).with(all_paths)
        orchestrator.mv(sources, destination)
      end

      it "builds mv commands" do
        expect(orchestrator).to receive(:build_mv_commands).with(mock_dispatch_info, sources, destination, {})
        orchestrator.mv(sources, destination)
      end

      context "with concurrent option" do
        it "executes concurrently" do
          commands_by_repo = {"main" => ["mv old.txt new.txt"]}
          allow(orchestrator).to receive(:build_mv_commands).and_return(commands_by_repo)
          expect(CodingAgentTools::Molecules::Git::ConcurrentExecutor).to receive(:execute_concurrently).with(commands_by_repo, {concurrent: true})
          orchestrator.mv(sources, destination, {concurrent: true})
        end
      end
    end
  end

  describe "#rm" do
    let(:mock_dispatcher) { instance_double(CodingAgentTools::Molecules::Git::PathDispatcher) }
    let(:mock_dispatch_info) { {"main" => {paths: ["file1.txt", "file2.txt"]}} }

    before do
      allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
      allow(mock_dispatcher).to receive(:dispatch_paths).and_return(mock_dispatch_info)
      allow(orchestrator).to receive(:build_rm_commands).and_return({"main" => ["rm file1.txt file2.txt"]})
      allow(orchestrator).to receive(:execute_sequentially).and_return({success: true})
    end

    context "with nil paths" do
      it "returns error for nil paths" do
        result = orchestrator.rm(nil)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No paths provided")
      end
    end

    context "with empty paths" do
      it "returns error for empty paths" do
        result = orchestrator.rm([])
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No paths provided")
      end
    end

    context "with valid paths" do
      let(:paths) { ["file1.txt", "file2.txt"] }

      it "dispatches paths and builds rm commands" do
        expect(mock_dispatcher).to receive(:dispatch_paths).with(paths)
        expect(orchestrator).to receive(:build_rm_commands).with(mock_dispatch_info, {})
        orchestrator.rm(paths)
      end

      context "with concurrent option" do
        it "executes concurrently" do
          commands_by_repo = {"main" => ["rm file1.txt"]}
          allow(orchestrator).to receive(:build_rm_commands).and_return(commands_by_repo)
          expect(CodingAgentTools::Molecules::Git::ConcurrentExecutor).to receive(:execute_concurrently).with(commands_by_repo, {concurrent: true})
          orchestrator.rm(paths, {concurrent: true})
        end
      end
    end
  end

  describe "#restore" do
    let(:mock_dispatcher) { instance_double(CodingAgentTools::Molecules::Git::PathDispatcher) }
    let(:mock_dispatch_info) { {"main" => {paths: ["file1.txt", "file2.txt"]}} }

    before do
      allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
      allow(mock_dispatcher).to receive(:dispatch_paths).and_return(mock_dispatch_info)
      allow(orchestrator).to receive(:build_restore_commands).and_return({"main" => ["restore file1.txt"]})
      allow(orchestrator).to receive(:execute_sequentially).and_return({success: true})
    end

    context "with nil pathspecs" do
      it "returns error for nil pathspecs" do
        result = orchestrator.restore(nil)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No pathspecs provided")
      end
    end

    context "with empty pathspecs" do
      it "returns error for empty pathspecs" do
        result = orchestrator.restore([])
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No pathspecs provided")
      end
    end

    context "with valid pathspecs" do
      let(:pathspecs) { ["file1.txt", "file2.txt"] }

      it "dispatches paths and builds restore commands" do
        expect(mock_dispatcher).to receive(:dispatch_paths).with(pathspecs)
        expect(orchestrator).to receive(:build_restore_commands).with(mock_dispatch_info, {})
        orchestrator.restore(pathspecs)
      end

      context "with concurrent option" do
        it "executes concurrently" do
          commands_by_repo = {"main" => ["restore file1.txt"]}
          allow(orchestrator).to receive(:build_restore_commands).and_return(commands_by_repo)
          expect(CodingAgentTools::Molecules::Git::ConcurrentExecutor).to receive(:execute_concurrently).with(commands_by_repo, {concurrent: true})
          orchestrator.restore(pathspecs, {concurrent: true})
        end
      end
    end
  end

  describe "#repositories" do
    it "exposes repositories as a reader" do
      expect(orchestrator).to respond_to(:repositories)
      expect(orchestrator.repositories).to be_an(Array)
    end
  end

  # Test error conditions and edge cases
  describe "error handling" do
    context "when repository scanner returns empty results" do
      before do
        allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).and_return([])
      end

      it "handles empty repository list gracefully" do
        expect { described_class.new(project_root) }.not_to raise_error
      end
    end

    context "when project_root is invalid" do
      it "handles invalid project_root gracefully" do
        invalid_path = "/nonexistent/path"
        expect { described_class.new(invalid_path) }.not_to raise_error
      end
    end
  end

  # Test command building methods (private methods accessed through public interface)
  describe "command building" do
    describe "#build_log_command" do
      it "builds basic log command" do
        result = orchestrator.log({})
        # The build_log_command is called internally, verify through public interface
        expect(result).to be_a(Hash)
      end

      it "builds log command with oneline option" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        # Expect the command to include oneline formatting
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("log")
          expect(command).to include("pretty=format")
          {success: true, results: {}}
        end
        
        orchestrator.log({oneline: true})
      end

      it "builds log command with graph option" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("--graph")
          {success: true, results: {}}
        end
        
        orchestrator.log({graph: true})
      end

      it "builds log command with date filters" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("--since")
          expect(command).to include("--until")
          {success: true, results: {}}
        end
        
        orchestrator.log({since: "2023-01-01", until: "2023-12-31"})
      end

      it "builds log command with author and grep filters" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("--author")
          expect(command).to include("--grep")
          {success: true, results: {}}
        end
        
        orchestrator.log({author: "john@example.com", grep: "fix"})
      end

      it "builds log command with max_count limit" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("-n 10")
          {success: true, results: {}}
        end
        
        orchestrator.log({max_count: 10})
      end
    end

    describe "#build_push_command" do
      it "builds basic push command" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        allow(orchestrator).to receive(:execute_push_sequential).and_return({success: true})
        
        orchestrator.push({})
      end

      it "builds push command with force option" do
        allow(orchestrator).to receive(:execute_push_sequential) do |command, options|
          expect(command).to include("--force")
          {success: true}
        end
        
        orchestrator.push({force: true})
      end

      it "builds push command with all options" do
        allow(orchestrator).to receive(:execute_push_sequential) do |command, options|
          expect(command).to include("--force")
          expect(command).to include("--dry-run")
          expect(command).to include("--set-upstream")
          expect(command).to include("--tags")
          expect(command).to include("origin")
          expect(command).to include("main")
          {success: true}
        end
        
        orchestrator.push({force: true, dry_run: true, set_upstream: true, tags: true, remote: "origin", branch: "main"})
      end
    end

    describe "#build_pull_command" do
      it "builds basic pull command" do
        allow(orchestrator).to receive(:execute_pull_sequential).and_return({success: true})
        orchestrator.pull({})
      end

      it "builds pull command with rebase option" do
        allow(orchestrator).to receive(:execute_pull_sequential) do |command, options|
          expect(command).to include("--rebase")
          {success: true}
        end
        
        orchestrator.pull({rebase: true})
      end

      it "builds pull command with all options" do
        allow(orchestrator).to receive(:execute_pull_sequential) do |command, options|
          expect(command).to include("--rebase")
          expect(command).to include("--ff-only")
          expect(command).to include("--no-commit")
          expect(command).to include("--strategy=ours")
          expect(command).to include("origin")
          expect(command).to include("main")
          {success: true}
        end
        
        orchestrator.pull({rebase: true, ff_only: true, no_commit: true, strategy: "ours", remote: "origin", branch: "main"})
      end
    end

    describe "#build_diff_command" do
      it "builds basic diff command" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to eq("diff")
          {success: true, results: {}}
        end
        
        orchestrator.diff({})
      end

      it "builds diff command with options" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("--staged")
          expect(command).to include("--name-only")
          expect(command).to include("--stat")
          {success: true, results: {}}
        end
        
        orchestrator.diff({staged: true, name_only: true, stat: true})
      end
    end

    describe "#build_fetch_command" do
      it "builds basic fetch command" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to eq("fetch")
          {success: true, results: {}}
        end
        
        orchestrator.fetch({})
      end

      it "builds fetch command with options" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("--all")
          expect(command).to include("--prune")
          expect(command).to include("--tags")
          expect(command).to include("origin")
          {success: true, results: {}}
        end
        
        orchestrator.fetch({all: true, prune: true, tags: true, remote: "origin"})
      end
    end

    describe "#build_checkout_command" do
      it "builds basic checkout command" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("checkout")
          expect(command).to include("main")
          {success: true, results: {}}
        end
        
        orchestrator.checkout(["main"], {})
      end

      it "builds checkout command with branch creation" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("-b")
          expect(command).to include("feature")
          {success: true, results: {}}
        end
        
        orchestrator.checkout(["main"], {create_branch: "feature"})
      end

      it "builds checkout command with force and options" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("--quiet")
          expect(command).to include("--force")
          expect(command).to include("--merge")
          {success: true, results: {}}
        end
        
        orchestrator.checkout(["main"], {quiet: true, force: true, merge: true})
      end
    end

    describe "#build_switch_command" do
      it "builds basic switch command" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("switch")
          expect(command).to include("feature")
          {success: true, results: {}}
        end
        
        orchestrator.switch("feature", {})
      end

      it "builds switch command with creation" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("-c")
          expect(command).to include("new-feature")
          {success: true, results: {}}
        end
        
        orchestrator.switch("main", {create: "new-feature"})
      end

      it "builds switch command with all options" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories) do |command, options|
          expect(command).to include("--quiet")
          expect(command).to include("--force")
          expect(command).to include("--no-guess")
          {success: true, results: {}}
        end
        
        orchestrator.switch("feature", {quiet: true, force: true, no_guess: true})
      end
    end
  end

  # Test formatting methods
  describe "output formatting" do
    describe "#format_status_output" do
      it "formats status output with color formatter" do
        result = {
          results: {
            "main" => {success: true, stdout: "M  file1.txt\nA  file2.txt"},
            "submodule1" => {success: true, stdout: "?? newfile.txt"}
          }
        }
        
        formatted = orchestrator.send(:format_status_output, result, {})
        expect(formatted).to have_key(:formatted_output)
        expect(formatted[:formatted_output]).to be_a(String)
      end

      it "skips empty output unless verbose" do
        result = {
          results: {
            "main" => {success: true, stdout: ""},
            "submodule1" => {success: true, stdout: "?? newfile.txt"}
          }
        }
        
        formatted = orchestrator.send(:format_status_output, result, {})
        expect(formatted[:formatted_output]).not_to include("main")
      end

      it "includes empty output when verbose" do
        result = {
          results: {
            "main" => {success: true, stdout: ""},
            "submodule1" => {success: true, stdout: "?? newfile.txt"}
          }
        }
        
        formatted = orchestrator.send(:format_status_output, result, {verbose: true})
        expect(formatted).to have_key(:formatted_output)
      end
    end

    describe "#format_log_output" do
      it "formats unified log by default" do
        result = {
          results: {
            "main" => {success: true, stdout: "abc123 Initial commit (2023-01-01 10:00:00 +0000)"},
            "submodule1" => {success: true, stdout: "def456 Sub commit (2023-01-02 11:00:00 +0000)"}
          }
        }
        
        formatted = orchestrator.send(:format_log_output, result, {})
        expect(formatted).to have_key(:formatted_output)
      end

      it "formats separated log when requested" do
        result = {
          results: {
            "main" => {success: true, stdout: "abc123 Initial commit"},
            "submodule1" => {success: true, stdout: "def456 Sub commit"}
          }
        }
        
        formatted = orchestrator.send(:format_log_output, result, {separated: true})
        expect(formatted).to have_key(:formatted_output)
        expect(formatted[:formatted_output]).to include("[main] Recent commits:")
        expect(formatted[:formatted_output]).to include("[submodule1] Recent commits:")
      end
    end

    describe "#parse_commits_from_output" do
      it "parses oneline format commits" do
        output = "abc123 Initial commit (2023-01-01 10:00:00 +0000)\ndef456 Second commit (2023-01-02 11:00:00 +0000)"
        commits = orchestrator.send(:parse_commits_from_output, output, "main")
        
        expect(commits).to have(2).items
        expect(commits.first[:repo]).to eq("main")
        expect(commits.first[:type]).to eq(:oneline)
        expect(commits.first[:display_line]).to include("abc123")
      end

      it "parses timestamp-based format commits" do
        output = "TIMESTAMP:2023-01-01 10:00:00 +0000\ncommit abc123\nAuthor: John Doe\nInitial commit"
        commits = orchestrator.send(:parse_commits_from_output, output, "main")
        
        expect(commits).to have(1).item
        expect(commits.first[:repo]).to eq("main")
        expect(commits.first[:type]).to eq(:multiline)
      end

      it "handles empty output" do
        commits = orchestrator.send(:parse_commits_from_output, "", "main")
        expect(commits).to be_empty
      end

      it "skips unparseable commits" do
        output = "invalid line\nabc123 Valid commit (2023-01-01 10:00:00 +0000)"
        commits = orchestrator.send(:parse_commits_from_output, output, "main")
        
        expect(commits).to have(1).item
        expect(commits.first[:display_line]).to include("abc123")
      end
    end
  end

  # Test add command building
  describe "#build_add_commands" do
    it "builds basic add commands" do
      dispatch_info = {
        "main" => {paths: ["file1.txt", "file2.txt"]},
        "submodule1" => {paths: ["file3.txt"]}
      }
      
      commands = orchestrator.send(:build_add_commands, dispatch_info, {})
      
      expect(commands["main"]).to eq(["add file1.txt file2.txt"])
      expect(commands["submodule1"]).to eq(["add file3.txt"])
    end

    it "builds add commands with options" do
      dispatch_info = {"main" => {paths: ["file1.txt"]}}
      
      commands = orchestrator.send(:build_add_commands, dispatch_info, {all: true, update: true, force: true, patch: true})
      
      expect(commands["main"].first).to include("--all")
      expect(commands["main"].first).to include("--update")
      expect(commands["main"].first).to include("--force")
      expect(commands["main"].first).to include("--patch")
    end

    it "skips repositories with no paths" do
      dispatch_info = {
        "main" => {paths: ["file1.txt"]},
        "empty_repo" => {paths: []}
      }
      
      commands = orchestrator.send(:build_add_commands, dispatch_info, {})
      
      expect(commands).to have_key("main")
      expect(commands).not_to have_key("empty_repo")
    end
  end

  # Test integration scenarios
  describe "integration scenarios" do
    context "cross-component interaction" do
      it "properly coordinates between PathDispatcher and MultiRepoCoordinator" do
        mock_dispatcher = instance_double(CodingAgentTools::Molecules::Git::PathDispatcher)
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)

        allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)

        allow(mock_dispatcher).to receive(:dispatch_paths).and_return({"main" => {paths: ["file.txt"]}})
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return({success: true})
        allow(orchestrator).to receive(:build_add_commands).and_return({"main" => ["add file.txt"]})
        allow(orchestrator).to receive(:execute_sequentially).and_return({success: true})

        result = orchestrator.add(["file.txt"])
        expect(result[:success]).to be true
      end
    end

    context "ATOM architecture compliance" do
      it "properly uses molecules and atoms" do
        # Verify that the organism uses molecules (PathDispatcher, MultiRepoCoordinator)
        # and doesn't directly call atoms
        expect(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).with(project_root)
        
        mock_dispatcher = instance_double(CodingAgentTools::Molecules::Git::PathDispatcher)
        allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
        allow(mock_dispatcher).to receive(:dispatch_paths).and_return({"main" => {paths: []}})
        allow(orchestrator).to receive(:build_add_commands).and_return({})
        allow(orchestrator).to receive(:execute_sequentially).and_return({success: true})

        orchestrator.add(["file.txt"])
      end
    end

  # Test mv/rm/restore command building
  describe "file operation command building" do
    describe "#build_mv_commands" do
      it "builds mv commands for same repository" do
        dispatch_info = {
          "main" => {paths: ["old.txt", "new.txt"]}
        }
        sources = ["old.txt"]
        destination = "new.txt"
        
        commands = orchestrator.send(:build_mv_commands, dispatch_info, sources, destination, {})
        
        expect(commands["main"]).to eq(["mv old.txt new.txt"])
      end
    end

    describe "#build_rm_commands" do
      it "builds basic rm commands" do
        dispatch_info = {
          "main" => {paths: ["file1.txt", "file2.txt"]}
        }
        
        commands = orchestrator.send(:build_rm_commands, dispatch_info, {})
        
        expect(commands["main"]).to eq(["rm file1.txt file2.txt"])
      end
    end

    describe "#build_restore_commands" do
      it "builds basic restore commands" do
        dispatch_info = {
          "main" => {paths: ["file1.txt", "file2.txt"]}
        }
        
        commands = orchestrator.send(:build_restore_commands, dispatch_info, {})
        
        expect(commands["main"]).to eq(["restore file1.txt file2.txt"])
      end
    end
  end

  # Test execution methods
  describe "execution coordination" do
    describe "#detect_current_repository" do
      it "detects main repository when in project root" do
        allow(Dir).to receive(:pwd).and_return(project_root)
        
        current_repo = orchestrator.send(:detect_current_repository)
        expect(current_repo).to eq("main")
      end

      it "detects submodule when in submodule directory" do
        submodule_path = File.join(project_root, "submodule1")
        allow(Dir).to receive(:pwd).and_return(submodule_path)
        
        current_repo = orchestrator.send(:detect_current_repository)
        expect(current_repo).to eq("submodule1")
      end

      it "defaults to main when not found" do
        allow(Dir).to receive(:pwd).and_return("/some/other/path")
        
        current_repo = orchestrator.send(:detect_current_repository)
        expect(current_repo).to eq("main")
      end
    end

    describe "#add_all" do
      it "executes add --all across all repositories" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        
        expect(mock_coordinator).to receive(:execute_across_repositories).with("add --all", {})
        
        orchestrator.send(:add_all, {})
      end
    end
  end

  # Test edge cases and error conditions  
  describe "edge cases and error conditions" do
    context "invalid inputs" do
      it "handles nil project_root gracefully" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(nil)
        allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).and_return([])
        
        expect { described_class.new }.not_to raise_error
      end

      it "handles empty repository discovery" do
        allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).and_return([])
        
        orchestrator = described_class.new(project_root)
        expect(orchestrator.repositories).to be_empty
      end
    end

    context "network failures" do
      it "handles fetch failures gracefully" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        allow(mock_coordinator).to receive(:execute_across_repositories)
          .and_return({success: false, errors: [{error: "Network timeout"}]})
        
        result = orchestrator.fetch({all: true})
        expect(result[:success]).to be false
      end

      it "handles push failures gracefully" do
        allow(orchestrator).to receive(:execute_push_sequential)
          .and_return({success: false, errors: [{error: "Remote rejected"}]})
        
        result = orchestrator.push({})
        expect(result[:success]).to be false
      end
    end

    context "file system errors" do
      it "handles missing files in mv operation" do
        mock_dispatcher = instance_double(CodingAgentTools::Molecules::Git::PathDispatcher)
        allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
        allow(mock_dispatcher).to receive(:dispatch_paths).and_return({})
        allow(orchestrator).to receive(:execute_sequentially).and_return({success: true})
        
        result = orchestrator.mv(["nonexistent.txt"], "dest.txt")
        expect(result[:success]).to be true  # Should handle gracefully
      end

      it "handles permission errors in rm operation" do
        mock_dispatcher = instance_double(CodingAgentTools::Molecules::Git::PathDispatcher)
        allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
        allow(mock_dispatcher).to receive(:dispatch_paths).and_return({"main" => {paths: ["readonly.txt"]}})
        allow(orchestrator).to receive(:execute_sequentially)
          .and_return({success: false, errors: [{error: "Permission denied"}]})
        
        result = orchestrator.rm(["readonly.txt"])
        expect(result[:success]).to be false
      end
    end

    context "repository state inconsistencies" do
      it "handles detached HEAD state" do
        mock_coordinator = instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
        allow(mock_coordinator).to receive(:execute_across_repositories)
          .and_return({success: true, results: {"main" => {success: true, stdout: "HEAD detached"}}})
        
        result = orchestrator.status({})
        expect(result[:success]).to be true
      end

      it "handles merge conflicts during pull" do
        allow(orchestrator).to receive(:execute_pull_sequential)
          .and_return({success: false, errors: [{error: "Merge conflict"}]})
        
        result = orchestrator.pull({})
        expect(result[:success]).to be false
      end
    end
  end
end
EOF < /dev/null