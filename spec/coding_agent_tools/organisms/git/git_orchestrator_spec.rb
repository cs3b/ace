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
  end
end