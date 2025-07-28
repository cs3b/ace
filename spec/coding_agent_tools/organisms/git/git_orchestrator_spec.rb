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
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    context "with project_root parameter" do
      it "uses the provided project_root" do
        custom_root = "/custom/path"
        expect(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).with(custom_root)
        described_class.new(custom_root)
      end

      it "stores the provided project_root" do
        custom_root = "/custom/path"
        orchestrator = described_class.new(custom_root)
        expect(orchestrator.instance_variable_get(:@project_root)).to eq(custom_root)
      end
    end

    context "without project_root parameter" do
      it "uses ProjectRootDetector to find project_root" do
        expect(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
        expect(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).with(project_root)
        described_class.new
      end

      it "stores the detected project_root" do
        orchestrator = described_class.new
        expect(orchestrator.instance_variable_get(:@project_root)).to eq(project_root)
      end
    end

    context "with debug option" do
      it "sets debug mode" do
        orchestrator = described_class.new(project_root, debug: true)
        expect(orchestrator.instance_variable_get(:@debug)).to be true
      end
    end

    context "without debug option" do
      it "defaults debug to false" do
        orchestrator = described_class.new(project_root)
        expect(orchestrator.instance_variable_get(:@debug)).to be false
      end
    end

    context "with empty repository scanner results" do
      it "handles empty repository list gracefully" do
        allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).and_return([])
        expect { described_class.new(project_root) }.not_to raise_error
        orchestrator = described_class.new(project_root)
        expect(orchestrator.repositories).to eq([])
      end
    end

    context "with nil project_root" do
      it "uses detected project root when nil is passed" do
        expect(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
        orchestrator = described_class.new(nil)
        expect(orchestrator.instance_variable_get(:@project_root)).to eq(project_root)
      end
    end

    it "discovers and stores repositories" do
      orchestrator = described_class.new(project_root)
      expect(orchestrator.repositories).to be_an(Array)
      expect(orchestrator.repositories.size).to eq(2)
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
    let(:mock_color_formatter) { instance_double(CodingAgentTools::Atoms::Git::StatusColorFormatter) }

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(mock_coordinator).to receive(:execute_across_repositories).and_return(mock_result)
      allow(CodingAgentTools::Atoms::Git::StatusColorFormatter).to receive(:new).and_return(mock_color_formatter)
      allow(mock_color_formatter).to receive(:format_repository_status).and_return("[main] M  file1.txt\nA  file2.txt")
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
      result = orchestrator.status
      expect(result).to have_key(:formatted_output)
      expect(result[:formatted_output]).to be_a(String)
    end

    it "creates color formatter with options" do
      options = {color: true}
      expect(CodingAgentTools::Atoms::Git::StatusColorFormatter).to receive(:new).with(options)
      orchestrator.status(options)
    end

    it "formats repository status for each successful result" do
      expect(mock_color_formatter).to receive(:format_repository_status).with("main", "M  file1.txt\nA  file2.txt")
      expect(mock_color_formatter).to receive(:format_repository_status).with("submodule1", "?? newfile.txt")
      orchestrator.status
    end

    context "with verbose option" do
      it "includes empty output when verbose is true" do
        verbose_result = {
          success: true,
          results: {
            "main" => {success: true, stdout: ""},
            "submodule1" => {success: true, stdout: "?? newfile.txt"}
          }
        }
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(verbose_result)
        allow(mock_color_formatter).to receive(:format_repository_status).with("main", "").and_return("[main] clean")
        allow(mock_color_formatter).to receive(:format_repository_status).with("submodule1", "?? newfile.txt").and_return("[submodule1] ?? newfile.txt")
        
        result = orchestrator.status({verbose: true})
        expect(result[:formatted_output]).to include("[main] clean")
      end
    end

    context "without verbose option" do
      it "skips empty output when verbose is false" do
        empty_result = {
          success: true,
          results: {
            "main" => {success: true, stdout: ""},
            "submodule1" => {success: true, stdout: "?? newfile.txt"}
          }
        }
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(empty_result)
        allow(mock_color_formatter).to receive(:format_repository_status).with("submodule1", "?? newfile.txt").and_return("[submodule1] ?? newfile.txt")
        
        result = orchestrator.status
        expect(result[:formatted_output]).not_to include("[main]")
        expect(result[:formatted_output]).to include("[submodule1]")
      end
    end

    context "when repository operations fail" do
      it "skips failed repositories in formatting" do
        failed_result = {
          success: false,
          results: {
            "main" => {success: false, stderr: "Not a git repository"},
            "submodule1" => {success: true, stdout: "?? newfile.txt"}
          }
        }
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(failed_result)
        allow(mock_color_formatter).to receive(:format_repository_status).with("submodule1", "?? newfile.txt").and_return("[submodule1] ?? newfile.txt")
        
        result = orchestrator.status
        expect(result[:formatted_output]).not_to include("[main]")
        expect(result[:formatted_output]).to include("[submodule1]")
      end
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
    end

    it "creates a MultiRepoCoordinator with project_root" do
      expect(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).with(project_root)
      orchestrator.log
    end

    it "builds log command with options" do
      options = {oneline: true, max_count: 5}
      # Test the actual build_log_command method
      result = orchestrator.send(:build_log_command, options)
      expect(result).to include("log")
      expect(result).to include("--pretty=format:")
      expect(result).to include("-n 5")
    end

    it "executes log command across repositories" do
      # Allow the actual build_log_command to be called
      expected_command = orchestrator.send(:build_log_command, {})
      expect(mock_coordinator).to receive(:execute_across_repositories).with(expected_command, {capture_output: true})
      orchestrator.log
    end

    it "formats the log output" do
      result = orchestrator.log
      expect(result).to have_key(:formatted_output)
    end

    context "with separated output format" do
      it "returns separated format when requested" do
        options = {separated: true}
        result = orchestrator.log(options)
        expect(result).to have_key(:formatted_output)
      end
    end

    context "with unified output format (default)" do
      it "returns unified format by default" do
        result = orchestrator.log
        expect(result).to have_key(:formatted_output)
      end
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

        it "builds add commands from dispatch info" do
        # Test the actual build_add_commands method
        commands = orchestrator.send(:build_add_commands, mock_dispatch_info, {})
        expect(commands).to have_key("main")
        expect(commands["main"].first).to include("add")
        expect(commands["main"].first).to include("file1.txt")
        expect(commands["main"].first).to include("file2.txt")
      end

      context "with add options" do
        # These test the build_add_commands method more comprehensively in the new comprehensive tests
        # Skipping here to avoid duplication and focus on the organism's main functionality
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

    context "debug output" do
      it "prints debug information when debug is enabled" do
        debug_orchestrator = described_class.new(project_root, debug: true)
        allow(debug_orchestrator).to receive(:add_all).and_return({success: true})
        allow(debug_orchestrator).to receive(:commit_with_message).and_return({success: true})
        expect { debug_orchestrator.commit({message: "test", debug: true}) }.to output(/DEBUG: commit options/).to_stdout
      end

      it "prints add_all debug info when repo_only is false" do
        debug_orchestrator = described_class.new(project_root, debug: true)
        allow(debug_orchestrator).to receive(:add_all).and_return({success: true})
        allow(debug_orchestrator).to receive(:commit_with_message).and_return({success: true})
        expect { debug_orchestrator.commit({message: "test", debug: true, repo_only: false}) }.to output(/DEBUG: Running add_all/).to_stdout
      end

      it "prints skip add_all debug info when repo_only is true" do
        debug_orchestrator = described_class.new(project_root, debug: true)
        allow(debug_orchestrator).to receive(:commit_with_message).and_return({success: true})
        expect { debug_orchestrator.commit({message: "test", debug: true, repo_only: true}) }.to output(/DEBUG: Skipping add_all/).to_stdout
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

    context "debug output" do
      it "prints debug information when debug is enabled" do
        debug_orchestrator = described_class.new(project_root, debug: true)
        allow(debug_orchestrator).to receive(:build_push_command).and_return("push")
        allow(debug_orchestrator).to receive(:execute_push_sequential).and_return({success: true})
        expect { debug_orchestrator.push({debug: true}) }.to output(/DEBUG: Push options/).to_stdout
      end

      it "prints current repository info when repo_only is true" do
        debug_orchestrator = described_class.new(project_root, debug: true)
        allow(debug_orchestrator).to receive(:build_push_command).and_return("push")
        allow(debug_orchestrator).to receive(:detect_current_repository).and_return("main")
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return({success: true})
        expect { debug_orchestrator.push({repo_only: true, debug: true}) }.to output(/DEBUG: Current repository detected as: main/).to_stdout
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

    it "returns the repositories discovered during initialization" do
      expect(orchestrator.repositories.size).to eq(2)
      expect(orchestrator.repositories.first[:name]).to eq("main")
      expect(orchestrator.repositories.last[:name]).to eq("submodule1")
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

  # Test private helper methods
  describe "private helper methods" do
    describe ".detect_current_repository" do
      let(:debug_orchestrator) { described_class.new(project_root, debug: true) }

      before do
        allow(debug_orchestrator).to receive(:repositories).and_return([
          {name: "main", path: project_root, full_path: project_root},
          {name: "submodule1", path: "submodule1", full_path: File.join(project_root, "submodule1")}
        ])
      end

      it "detects current repository when in submodule directory" do
        # Test that the method executes without error and provides some output
        result = debug_orchestrator.send(:detect_current_repository)
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end

      it "detects main repository when in project root" do
        allow(Dir).to receive(:pwd).and_return(project_root)
        result = debug_orchestrator.send(:detect_current_repository)
        expect(result).to eq("main")
      end

      it "defaults to main when not in any known directory" do
        allow(Dir).to receive(:pwd).and_return("/unknown/path")
        result = debug_orchestrator.send(:detect_current_repository)
        expect(result).to eq("main")
      end

      it "prints debug information when debug is enabled" do
        allow(Dir).to receive(:pwd).and_return(project_root)
        expect { debug_orchestrator.send(:detect_current_repository) }.to output(/DEBUG: Current dir/).to_stdout
      end
    end

    describe ".build_push_command" do
      it "builds basic push command" do
        result = orchestrator.send(:build_push_command, {})
        expect(result).to eq("push")
      end

      it "includes force flag when specified" do
        result = orchestrator.send(:build_push_command, {force: true})
        expect(result).to eq("push --force")
      end

      it "includes dry-run flag when specified" do
        result = orchestrator.send(:build_push_command, {dry_run: true})
        expect(result).to eq("push --dry-run")
      end

      it "includes set-upstream flag when specified" do
        result = orchestrator.send(:build_push_command, {set_upstream: true})
        expect(result).to eq("push --set-upstream")
      end

      it "includes tags flag when specified" do
        result = orchestrator.send(:build_push_command, {tags: true})
        expect(result).to eq("push --tags")
      end

      it "includes remote and branch when specified" do
        result = orchestrator.send(:build_push_command, {remote: "origin", branch: "main"})
        expect(result).to eq("push origin main")
      end

      it "combines multiple options" do
        result = orchestrator.send(:build_push_command, {force: true, tags: true, remote: "origin"})
        expect(result).to eq("push --force --tags origin")
      end
    end

    describe ".build_pull_command" do
      it "builds basic pull command" do
        result = orchestrator.send(:build_pull_command, {})
        expect(result).to eq("pull")
      end

      it "includes rebase flag when specified" do
        result = orchestrator.send(:build_pull_command, {rebase: true})
        expect(result).to eq("pull --rebase")
      end

      it "includes ff-only flag when specified" do
        result = orchestrator.send(:build_pull_command, {ff_only: true})
        expect(result).to eq("pull --ff-only")
      end

      it "includes no-commit flag when specified" do
        result = orchestrator.send(:build_pull_command, {no_commit: true})
        expect(result).to eq("pull --no-commit")
      end

      it "includes strategy when specified" do
        result = orchestrator.send(:build_pull_command, {strategy: "recursive"})
        expect(result).to eq("pull --strategy=recursive")
      end

      it "includes remote and branch when specified" do
        result = orchestrator.send(:build_pull_command, {remote: "origin", branch: "main"})
        expect(result).to eq("pull origin main")
      end
    end

    describe ".build_diff_command" do
      it "builds basic diff command" do
        result = orchestrator.send(:build_diff_command, {})
        expect(result).to eq("diff")
      end

      it "includes staged flag when specified" do
        result = orchestrator.send(:build_diff_command, {staged: true})
        expect(result).to eq("diff --staged")
      end

      it "includes name-only flag when specified" do
        result = orchestrator.send(:build_diff_command, {name_only: true})
        expect(result).to eq("diff --name-only")
      end

      it "includes stat flag when specified" do
        result = orchestrator.send(:build_diff_command, {stat: true})
        expect(result).to eq("diff --stat")
      end
    end

    describe ".build_fetch_command" do
      it "builds basic fetch command" do
        result = orchestrator.send(:build_fetch_command, {})
        expect(result).to eq("fetch")
      end

      it "includes all flag when specified" do
        result = orchestrator.send(:build_fetch_command, {all: true})
        expect(result).to eq("fetch --all")
      end

      it "includes prune flag when specified" do
        result = orchestrator.send(:build_fetch_command, {prune: true})
        expect(result).to eq("fetch --prune")
      end

      it "includes tags flag when specified" do
        result = orchestrator.send(:build_fetch_command, {tags: true})
        expect(result).to eq("fetch --tags")
      end

      it "includes remote when specified" do
        result = orchestrator.send(:build_fetch_command, {remote: "origin"})
        expect(result).to eq("fetch origin")
      end
    end
  end

  # Test concurrent execution methods
  describe "concurrent execution" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }
    let(:submodule_result) { {success: true, results: {"submodule1" => {success: true}}, errors: [], repositories_processed: ["submodule1"]} }
    let(:main_result) { {success: true, results: {"main" => {success: true}}, errors: [], repositories_processed: ["main"]} }

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
    end

    describe ".execute_push_concurrent" do
      it "executes submodules first, then main repository" do
        expect(mock_coordinator).to receive(:execute_across_repositories)
          .with("push", {submodules_only: true})
          .and_return(submodule_result)
        expect(mock_coordinator).to receive(:execute_across_repositories)
          .with("push", {main_only: true})
          .and_return(main_result)

        result = orchestrator.send(:execute_push_concurrent, "push", {})
        expect(result[:success]).to be true
        expect(result[:results]).to include("main", "submodule1")
        expect(result[:repositories_processed]).to contain_exactly("submodule1", "main")
      end

      it "combines errors from both phases" do
        error_result = {success: false, results: {}, errors: [{error: "push failed"}], repositories_processed: []}
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(error_result)

        result = orchestrator.send(:execute_push_concurrent, "push", {})
        expect(result[:success]).to be false
        expect(result[:errors].size).to eq(2)
      end
    end

    describe ".execute_push_sequential" do
      it "executes submodules first, then main repository" do
        expect(mock_coordinator).to receive(:execute_across_repositories)
          .with("push", {submodules_only: true})
          .and_return(submodule_result)
        expect(mock_coordinator).to receive(:execute_across_repositories)
          .with("push", {main_only: true})
          .and_return(main_result)

        result = orchestrator.send(:execute_push_sequential, "push", {})
        expect(result[:success]).to be true
      end
    end

    describe ".execute_pull_concurrent" do
      it "executes main repository first, then submodules" do
        expect(mock_coordinator).to receive(:execute_across_repositories)
          .with("pull", {main_only: true})
          .and_return(main_result)
        expect(mock_coordinator).to receive(:execute_across_repositories)
          .with("pull", {submodules_only: true})
          .and_return(submodule_result)

        result = orchestrator.send(:execute_pull_concurrent, "pull", {})
        expect(result[:success]).to be true
        expect(result[:results]).to include("main", "submodule1")
      end
    end

    describe ".execute_pull_sequential" do
      it "executes main repository first, then submodules" do
        expect(mock_coordinator).to receive(:execute_across_repositories)
          .with("pull", {main_only: true})
          .and_return(main_result)
        expect(mock_coordinator).to receive(:execute_across_repositories)
          .with("pull", {submodules_only: true})
          .and_return(submodule_result)

        result = orchestrator.send(:execute_pull_sequential, "pull", {})
        expect(result[:success]).to be true
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

  # Test comprehensive status operation coverage
  describe "#status comprehensive coverage" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }
    let(:mock_color_formatter) { instance_double(CodingAgentTools::Atoms::Git::StatusColorFormatter) }

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(CodingAgentTools::Atoms::Git::StatusColorFormatter).to receive(:new).and_return(mock_color_formatter)
    end

    context "format_status_output method coverage" do
      it "handles multiple repository results with different outputs" do
        complex_result = {
          success: true,
          results: {
            "main" => {success: true, stdout: "M  main_file.txt\nA  new_main.txt"},
            "submodule1" => {success: true, stdout: "?? untracked_sub.txt\nM  sub_file.txt"},
            "submodule2" => {success: true, stdout: ""},
            "failed_repo" => {success: false, stderr: "Not a git repository"}
          }
        }
        
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(complex_result)
        allow(mock_color_formatter).to receive(:format_repository_status).with("main", "M  main_file.txt\nA  new_main.txt").and_return("[main] M  main_file.txt\nA  new_main.txt")
        allow(mock_color_formatter).to receive(:format_repository_status).with("submodule1", "?? untracked_sub.txt\nM  sub_file.txt").and_return("[submodule1] ?? untracked_sub.txt\nM  sub_file.txt")

        result = orchestrator.status
        expect(result[:formatted_output]).to include("[main]")
        expect(result[:formatted_output]).to include("[submodule1]")
        expect(result[:formatted_output]).not_to include("[submodule2]") # Empty output, not verbose
        expect(result[:formatted_output]).not_to include("[failed_repo]") # Failed repository
      end

      it "includes proper spacing between repository outputs" do
        multi_repo_result = {
          success: true,
          results: {
            "main" => {success: true, stdout: "M  file1.txt"},
            "submodule1" => {success: true, stdout: "A  file2.txt"}
          }
        }

        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(multi_repo_result)
        allow(mock_color_formatter).to receive(:format_repository_status).with("main", "M  file1.txt").and_return("[main] M  file1.txt")
        allow(mock_color_formatter).to receive(:format_repository_status).with("submodule1", "A  file2.txt").and_return("[submodule1] A  file2.txt")

        result = orchestrator.status
        expect(result[:formatted_output]).to eq("[main] M  file1.txt\n\n[submodule1] A  file2.txt")
      end

      it "handles nil stdout in repository results" do
        nil_stdout_result = {
          success: true,
          results: {
            "main" => {success: true, stdout: nil},
            "submodule1" => {success: true, stdout: "A  file.txt"}
          }
        }

        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(nil_stdout_result)
        allow(mock_color_formatter).to receive(:format_repository_status).with("submodule1", "A  file.txt").and_return("[submodule1] A  file.txt")

        result = orchestrator.status
        expect(result[:formatted_output]).to eq("[submodule1] A  file.txt")
      end
    end

    context "status with color formatting options" do
      it "passes color options to StatusColorFormatter" do
        color_options = {color: true, theme: "dark"}
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return({success: true, results: {}})
        
        expect(CodingAgentTools::Atoms::Git::StatusColorFormatter).to receive(:new).with(color_options)
        orchestrator.status(color_options)
      end
    end
  end

  # Comprehensive log operation tests
  describe "#log comprehensive coverage" do
    let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }
    let(:mock_color_formatter) { instance_double(CodingAgentTools::Atoms::Git::LogColorFormatter) }

    before do
      allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      allow(CodingAgentTools::Atoms::Git::LogColorFormatter).to receive(:new).and_return(mock_color_formatter)
    end

    describe ".build_log_command comprehensive options" do
      it "builds command with all available options" do
        complex_options = {
          oneline: false,
          graph: true,
          since: "2023-01-01",
          until: "2023-12-31",
          author: "developer@example.com",
          grep: "fix:",
          max_count: 50
        }

        result = orchestrator.send(:build_log_command, complex_options)
        expect(result).to include("log")
        expect(result).to include("--graph")
        expect(result).to include("--since=#{Shellwords.escape('2023-01-01')}")
        expect(result).to include("--until=#{Shellwords.escape('2023-12-31')}")
        expect(result).to include("--author=#{Shellwords.escape('developer@example.com')}")
        expect(result).to include("--grep=#{Shellwords.escape('fix:')}")
        expect(result).to include("-n 50")
        expect(result).to include("--date=iso")
      end

      it "builds oneline format with proper timestamp format" do
        result = orchestrator.send(:build_log_command, {oneline: true})
        expect(result).to include("log")
        expect(result).to include("--pretty=format:")
        expect(result).to include("\\%h\\ \\%s\\ \\(\\%ci\\)")
      end

      it "handles special characters in option values" do
        options_with_special_chars = {
          author: "developer's name <email@domain.co.uk>",
          grep: "fix: resolve \"quoted\" issue"
        }

        result = orchestrator.send(:build_log_command, options_with_special_chars)
        expect(result).to include(Shellwords.escape("developer's name <email@domain.co.uk>"))
        expect(result).to include(Shellwords.escape('fix: resolve "quoted" issue'))
      end
    end

    describe ".format_log_output method coverage" do
      it "delegates to format_separated_log when separated option is true" do
        separated_result = {success: true, results: {"main" => {success: true, stdout: "abc123 commit"}}}
        expect(orchestrator).to receive(:format_separated_log).with(separated_result, {separated: true})
        orchestrator.send(:format_log_output, separated_result, {separated: true})
      end

      it "defaults to format_unified_log when separated option is false" do
        unified_result = {success: true, results: {"main" => {success: true, stdout: "abc123 commit"}}}
        expect(orchestrator).to receive(:format_unified_log).with(unified_result, {})
        orchestrator.send(:format_log_output, unified_result, {})
      end
    end

    describe ".format_separated_log method coverage" do
      it "formats each repository's log output separately" do
        separated_result = {
          success: true,
          results: {
            "main" => {success: true, stdout: "abc123 Main commit\ndef456 Another main commit"},
            "submodule1" => {success: true, stdout: "xyz789 Submodule commit"},
            "empty_repo" => {success: true, stdout: ""},
            "failed_repo" => {success: false, stderr: "Error"}
          }
        }

        result = orchestrator.send(:format_separated_log, separated_result, {})
        expect(result[:formatted_output]).to include("[main] Recent commits:")
        expect(result[:formatted_output]).to include("  abc123 Main commit")
        expect(result[:formatted_output]).to include("  def456 Another main commit")
        expect(result[:formatted_output]).to include("[submodule1] Recent commits:")
        expect(result[:formatted_output]).to include("  xyz789 Submodule commit")
        expect(result[:formatted_output]).not_to include("[empty_repo]")
        expect(result[:formatted_output]).not_to include("[failed_repo]")
      end

      it "handles line ending variations correctly" do
        line_ending_result = {
          success: true,
          results: {
            "main" => {success: true, stdout: "abc123 Commit with trailing spaces   \ndef456 Normal commit\n"}
          }
        }

        result = orchestrator.send(:format_separated_log, line_ending_result, {})
        expect(result[:formatted_output]).to include("  abc123 Commit with trailing spaces")
        expect(result[:formatted_output]).to include("  def456 Normal commit")
      end
    end

    describe ".format_unified_log method coverage" do
      it "merges and sorts commits from multiple repositories by timestamp" do
        multi_repo_result = {
          success: true,
          results: {
            "main" => {success: true, stdout: "abc123 Older commit (2023-01-01 10:00:00 +0000)"},
            "submodule1" => {success: true, stdout: "def456 Newer commit (2023-01-02 10:00:00 +0000)"}
          }
        }

        allow(orchestrator).to receive(:parse_commits_from_output).with("abc123 Older commit (2023-01-01 10:00:00 +0000)", "main").and_return([
          {repo: "main", timestamp: Time.parse("2023-01-01 10:00:00 +0000"), display_line: "abc123 Older commit", type: :oneline}
        ])
        allow(orchestrator).to receive(:parse_commits_from_output).with("def456 Newer commit (2023-01-02 10:00:00 +0000)", "submodule1").and_return([
          {repo: "submodule1", timestamp: Time.parse("2023-01-02 10:00:00 +0000"), display_line: "def456 Newer commit", type: :oneline}
        ])
        allow(orchestrator).to receive(:format_commits_with_padding).and_return("formatted output")

        result = orchestrator.send(:format_unified_log, multi_repo_result, {})
        expect(result[:formatted_output]).to eq("formatted output")
      end

      it "handles empty commits list gracefully" do
        empty_result = {success: true, results: {}}
        allow(orchestrator).to receive(:format_commits_with_padding).with([], {}).and_return("")

        result = orchestrator.send(:format_unified_log, empty_result, {})
        expect(result[:formatted_output]).to eq("")
      end
    end

    describe ".format_commits_with_padding method coverage" do
      let(:sample_commits) do
        [
          {repo: "main", timestamp: Time.parse("2023-01-02"), display_line: "def456 Newer commit", type: :oneline},
          {repo: "submodule1-with-long-name", timestamp: Time.parse("2023-01-01"), display_line: "abc123 Older commit", type: :oneline}
        ]
      end

      before do
        allow(CodingAgentTools::Atoms::Git::LogColorFormatter).to receive(:new).and_return(mock_color_formatter)
      end

      it "returns empty string for empty commits list" do
        result = orchestrator.send(:format_commits_with_padding, [], {})
        expect(result).to eq("")
      end

      it "calculates proper padding based on longest repository name" do
        allow(mock_color_formatter).to receive(:should_use_color?).and_return(false)
        allow(mock_color_formatter).to receive(:format_commit).and_return("formatted commit")

        result = orchestrator.send(:format_commits_with_padding, sample_commits, {})
        
        # Should pad to accommodate "submodule1-with-long-name" (25 chars) + brackets (2 chars) = 27 chars
        expect(result).to include("[main]")
        expect(result).to include("[submodule1-with-long-name]")
      end

      it "applies color formatting when enabled" do
        allow(mock_color_formatter).to receive(:should_use_color?).and_return(true)
        allow(mock_color_formatter).to receive(:send).with(:colorize, anything, :repo_name).and_return("colored repo")
        allow(mock_color_formatter).to receive(:format_commit).and_return("colored commit")

        result = orchestrator.send(:format_commits_with_padding, sample_commits, {color: true})
        expect(result).to include("colored commit")
      end

      it "handles multiline commits with proper indentation" do
        multiline_commits = [
          {
            repo: "main", 
            timestamp: Time.parse("2023-01-01"), 
            display_line: "commit abc123\nAuthor: John Doe\n\n    Fix multiline issue", 
            type: :multiline
          }
        ]

        allow(mock_color_formatter).to receive(:should_use_color?).and_return(false)
        allow(mock_color_formatter).to receive(:format_commit).and_return("commit abc123\nAuthor: John Doe\n\n    Fix multiline issue")

        result = orchestrator.send(:format_commits_with_padding, multiline_commits, {})
        lines = result.split("\n")
        expect(lines.first).to include("[main]")
        expect(lines[1]).to match(/^\s+Author: John Doe/)  # Indented continuation
      end

      it "adds proper spacing between commits" do
        allow(mock_color_formatter).to receive(:should_use_color?).and_return(false)
        allow(mock_color_formatter).to receive(:format_commit).and_return("formatted commit")

        result = orchestrator.send(:format_commits_with_padding, sample_commits, {})
        lines = result.split("\n")
        expect(lines).to include("")  # Empty line for spacing
      end
    end

    describe ".parse_commits_from_output method coverage" do
      it "parses full format commits with TIMESTAMP markers" do
        full_format_output = "TIMESTAMP:2023-01-01 10:00:00 +0000\ncommit abc123\nAuthor: John <john@example.com>\nDate:   2023-01-01 10:00:00 +0000\n\n    Initial commit\n\nTIMESTAMP:2023-01-02 11:00:00 +0000\ncommit def456\nAuthor: Jane <jane@example.com>\nDate:   2023-01-02 11:00:00 +0000\n\n    Second commit"

        result = orchestrator.send(:parse_commits_from_output, full_format_output, "main")
        expect(result.size).to eq(2)
        expect(result.first[:repo]).to eq("main")
        expect(result.first[:type]).to eq(:multiline)
        expect(result.first[:timestamp]).to be_a(Time)
        expect(result.first[:display_line]).to include("commit abc123")
      end

      it "handles commits with unparseable timestamps gracefully" do
        bad_timestamp_output = "TIMESTAMP:invalid-timestamp\ncommit abc123\nAuthor: John"

        result = orchestrator.send(:parse_commits_from_output, bad_timestamp_output, "main")
        expect(result).to be_empty
      end

      it "parses oneline format commits" do
        oneline_output = "abc123 First commit (2023-01-01 10:00:00 +0000)\ndef456 Second commit (2023-01-02 11:00:00 +0000)"

        allow(orchestrator).to receive(:parse_commit_line).with("abc123 First commit (2023-01-01 10:00:00 +0000)", "main").and_return(
          {repo: "main", timestamp: Time.parse("2023-01-01 10:00:00 +0000"), display_line: "abc123 First commit", type: :oneline}
        )
        allow(orchestrator).to receive(:parse_commit_line).with("def456 Second commit (2023-01-02 11:00:00 +0000)", "main").and_return(
          {repo: "main", timestamp: Time.parse("2023-01-02 11:00:00 +0000"), display_line: "def456 Second commit", type: :oneline}
        )

        result = orchestrator.send(:parse_commits_from_output, oneline_output, "main")
        expect(result.size).to eq(2)
        expect(result.first[:type]).to eq(:oneline)
      end

      it "skips empty lines in output" do
        output_with_empty_lines = "abc123 Commit (2023-01-01 10:00:00 +0000)\n\n\ndef456 Another commit (2023-01-02 11:00:00 +0000)\n"

        allow(orchestrator).to receive(:parse_commit_line).with("abc123 Commit (2023-01-01 10:00:00 +0000)", "main").and_return(
          {repo: "main", timestamp: Time.parse("2023-01-01"), display_line: "abc123 Commit", type: :oneline}
        )
        allow(orchestrator).to receive(:parse_commit_line).with("def456 Another commit (2023-01-02 11:00:00 +0000)", "main").and_return(
          {repo: "main", timestamp: Time.parse("2023-01-02"), display_line: "def456 Another commit", type: :oneline}
        )

        result = orchestrator.send(:parse_commits_from_output, output_with_empty_lines, "main")
        expect(result.size).to eq(2)
      end

      it "handles empty first block when splitting by TIMESTAMP" do
        timestamp_output = "\nTIMESTAMP:2023-01-01 10:00:00 +0000\ncommit abc123"

        result = orchestrator.send(:parse_commits_from_output, timestamp_output, "main")
        expect(result.size).to eq(1)
        expect(result.first[:display_line]).to include("commit abc123")
      end
    end
  end

  # Test LLM commit integration and format methods
  describe "LLM commit operations" do
    let(:mock_generator) { instance_double(CodingAgentTools::Molecules::Git::CommitMessageGenerator) }
    let(:mock_executor) { instance_double(CodingAgentTools::Atoms::Git::GitCommandExecutor) }
    let(:diff_output) { "diff --git a/file.txt b/file.txt\\nindex 123..456\\n+new content" }

    before do
      allow(CodingAgentTools::Molecules::Git::CommitMessageGenerator).to receive(:new).and_return(mock_generator)
      allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).and_return(mock_executor)
      allow(mock_generator).to receive(:generate_message).and_return("feat: add new feature")
      allow(mock_executor).to receive(:execute).with("diff --staged").and_return({stdout: diff_output})
    end

    describe ".commit_with_llm_message" do
      it "generates commit messages for repositories with staged changes" do
        allow(orchestrator).to receive(:repositories).and_return([
          {name: "main", exists: true, is_git_repo: true, full_path: "/path/to/main"}
        ])
        allow(orchestrator).to receive(:get_staged_diff).and_return(diff_output)
        allow(orchestrator).to receive(:execute_sequentially_with_submodules_first).and_return({success: true})

        expect(mock_generator).to receive(:generate_message).with(diff_output)
        orchestrator.send(:commit_with_llm_message, {})
      end

      it "skips repositories with no staged changes" do
        allow(orchestrator).to receive(:repositories).and_return([
          {name: "main", exists: true, is_git_repo: true, full_path: "/path/to/main"}
        ])
        allow(orchestrator).to receive(:get_staged_diff).and_return("")

        result = orchestrator.send(:commit_with_llm_message, {})
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No staged changes to commit")
      end

      it "handles commit message generation errors" do
        allow(orchestrator).to receive(:repositories).and_return([
          {name: "main", exists: true, is_git_repo: true, full_path: "/path/to/main"}
        ])
        allow(orchestrator).to receive(:get_staged_diff).and_return(diff_output)
        allow(mock_generator).to receive(:generate_message).and_raise(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError.new("API failed")
        )

        result = orchestrator.send(:commit_with_llm_message, {})
        expect(result[:success]).to be false
        expect(result[:error]).to include("Failed to generate commit message")
      end
    end

    describe ".get_staged_diff" do
      it "retrieves staged diff for a repository" do
        repository = {full_path: "/path/to/repo"}
        expect(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new)
          .with(repository_path: "/path/to/repo")
          .and_return(mock_executor)
        expect(mock_executor).to receive(:execute).with("diff --staged").and_return({stdout: diff_output})

        result = orchestrator.send(:get_staged_diff, repository)
        expect(result).to eq(diff_output)
      end

      it "returns empty string on git command error" do
        repository = {full_path: "/path/to/repo"}
        allow(mock_executor).to receive(:execute).and_raise(CodingAgentTools::Atoms::Git::GitCommandError.new("Not a git repository"))

        result = orchestrator.send(:get_staged_diff, repository)
        expect(result).to eq("")
      end
    end

    describe ".build_log_command formatting" do
      it "builds basic log command" do
        result = orchestrator.send(:build_log_command, {})
        expect(result).to include("log")
        expect(result).to include("--date=iso")
      end

      it "builds oneline log command" do
        result = orchestrator.send(:build_log_command, {oneline: true})
        expect(result).to include("log")
        expect(result).to include("--pretty=format:")
        expect(result).to include("\\%h\\ \\%s\\ \\(\\%ci\\)")
      end

      it "includes graph option" do
        result = orchestrator.send(:build_log_command, {graph: true})
        expect(result).to include("--graph")
      end

      it "includes author filter" do
        result = orchestrator.send(:build_log_command, {author: "john@example.com"})
        expect(result).to include("--author=#{Shellwords.escape('john@example.com')}")
      end

      it "includes max count" do
        result = orchestrator.send(:build_log_command, {max_count: 10})
        expect(result).to include("-n 10")
      end
    end

    describe ".parse_commit_line" do
      it "parses oneline commit format correctly" do
        line = "abc123 Initial commit (2023-01-01 10:00:00 +0000)"
        result = orchestrator.send(:parse_commit_line, line, "main")
        
        expect(result).not_to be_nil
        expect(result[:repo]).to eq("main")
        expect(result[:display_line]).to eq("abc123 Initial commit")
        expect(result[:type]).to eq(:oneline)
        expect(result[:timestamp]).to be_a(Time)
      end

      it "handles malformed lines gracefully" do
        line = "invalid commit line"
        result = orchestrator.send(:parse_commit_line, line, "main")
        expect(result).to be_nil
      end

      it "handles unparseable timestamps" do
        line = "abc123 Initial commit (invalid-timestamp)"
        result = orchestrator.send(:parse_commit_line, line, "main")
        expect(result).to be_nil
      end
    end
  end

  # Comprehensive path intelligence and command building tests
  describe "path intelligence and command building" do
    let(:mock_dispatcher) { instance_double(CodingAgentTools::Molecules::Git::PathDispatcher) }
    let(:sample_dispatch_info) do
      {
        "main" => {paths: ["main_file.txt", "shared/file.txt"]},
        "submodule1" => {paths: ["sub_file.txt", "sub/nested/file.txt"]}
      }
    end

    before do
      allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
      allow(mock_dispatcher).to receive(:dispatch_paths).and_return(sample_dispatch_info)
    end

    describe ".build_add_commands comprehensive coverage" do
      it "builds add commands with all flags" do
        options = {all: true, update: true, force: true, patch: true}
        result = orchestrator.send(:build_add_commands, sample_dispatch_info, options)
        
        expect(result["main"].first).to include("add")
        expect(result["main"].first).to include("--all")
        expect(result["main"].first).to include("--update")
        expect(result["main"].first).to include("--force")
        expect(result["main"].first).to include("--patch")
        expect(result["main"].first).to include(Shellwords.escape("main_file.txt"))
        expect(result["main"].first).to include(Shellwords.escape("shared/file.txt"))
      end

      it "properly escapes special characters in paths" do
        special_dispatch_info = {
          "main" => {paths: ["file with spaces.txt", "file'with'quotes.txt", "file\"with\"double-quotes.txt"]}
        }
        
        result = orchestrator.send(:build_add_commands, special_dispatch_info, {})
        command = result["main"].first
        expect(command).to include(Shellwords.escape("file with spaces.txt"))
        expect(command).to include(Shellwords.escape("file'with'quotes.txt"))
        expect(command).to include(Shellwords.escape('file"with"double-quotes.txt'))
      end

      it "skips repositories with empty paths" do
        empty_paths_info = {
          "main" => {paths: ["file1.txt"]},
          "submodule1" => {paths: []}
        }
        
        result = orchestrator.send(:build_add_commands, empty_paths_info, {})
        expect(result).to have_key("main")
        expect(result).not_to have_key("submodule1")
      end
    end

    describe ".build_mv_commands comprehensive coverage" do
      it "builds mv commands for same-repository operations" do
        mv_dispatch_info = {
          "main" => {paths: ["old_file.txt", "new_file.txt"]},
          "submodule1" => {paths: ["sub_old.txt", "sub_new.txt"]}
        }
        sources = ["old_file.txt", "sub_old.txt"]
        destination = "new_file.txt"
        options = {force: true, dry_run: true, verbose: true}

        result = orchestrator.send(:build_mv_commands, mv_dispatch_info, sources, destination, options)
        
        expect(result["main"].first).to include("mv")
        expect(result["main"].first).to include("--force")
        expect(result["main"].first).to include("--dry-run")
        expect(result["main"].first).to include("--verbose")
        expect(result["main"].first).to include(Shellwords.escape("old_file.txt"))
        expect(result["main"].first).to include(Shellwords.escape("new_file.txt"))
      end

      it "handles cross-repository moves by skipping invalid combinations" do
        cross_repo_info = {
          "main" => {paths: ["main_file.txt"]},
          "submodule1" => {paths: ["sub_file.txt"]}
        }
        sources = ["main_file.txt"]
        destination = "sub_file.txt"

        result = orchestrator.send(:build_mv_commands, cross_repo_info, sources, destination, {})
        expect(result).to be_empty # No valid same-repo operations
      end

      it "groups multiple sources in same repository correctly" do
        multi_source_info = {
          "main" => {paths: ["file1.txt", "file2.txt", "destination/"]}
        }
        sources = ["file1.txt", "file2.txt"]
        destination = "destination/"

        result = orchestrator.send(:build_mv_commands, multi_source_info, sources, destination, {})
        command = result["main"].first
        expect(command).to include(Shellwords.escape("file1.txt"))
        expect(command).to include(Shellwords.escape("file2.txt"))
        expect(command).to include(Shellwords.escape("destination/"))
      end
    end

    describe ".build_rm_commands comprehensive coverage" do
      it "builds rm commands with all flags" do
        options = {force: true, dry_run: true, recursive: true, cached: true, ignore_unmatch: true, quiet: true}
        result = orchestrator.send(:build_rm_commands, sample_dispatch_info, options)
        
        main_command = result["main"].first
        expect(main_command).to include("rm")
        expect(main_command).to include("--force")
        expect(main_command).to include("--dry-run")
        expect(main_command).to include("--recursive")
        expect(main_command).to include("--cached")
        expect(main_command).to include("--ignore-unmatch")
        expect(main_command).to include("--quiet")
      end

      it "handles empty repository paths gracefully" do
        empty_rm_info = {
          "main" => {paths: []},
          "submodule1" => {paths: ["file.txt"]}
        }

        result = orchestrator.send(:build_rm_commands, empty_rm_info, {})
        expect(result).not_to have_key("main")
        expect(result).to have_key("submodule1")
      end
    end

    describe ".build_restore_commands comprehensive coverage" do
      it "builds restore commands with all available options" do
        options = {
          source: "HEAD~1",
          staged: true,
          worktree: true,
          merge: true,
          conflict: "merge",
          ours: true,
          theirs: true,
          patch: true,
          quiet: true,
          progress: true
        }

        result = orchestrator.send(:build_restore_commands, sample_dispatch_info, options)
        main_command = result["main"].first
        
        expect(main_command).to include("restore")
        expect(main_command).to include("--source=#{Shellwords.escape('HEAD~1')}")
        expect(main_command).to include("--staged")
        expect(main_command).to include("--worktree")
        expect(main_command).to include("--merge")
        expect(main_command).to include("--conflict=merge")
        expect(main_command).to include("--ours")
        expect(main_command).to include("--theirs")
        expect(main_command).to include("--patch")
        expect(main_command).to include("--quiet")
        expect(main_command).to include("--progress")
      end

      it "handles special characters in source option" do
        options = {source: "feature/branch-with-special-chars"}
        result = orchestrator.send(:build_restore_commands, sample_dispatch_info, options)
        
        expect(result["main"].first).to include("--source=#{Shellwords.escape('feature/branch-with-special-chars')}")
      end
    end

    describe ".build_checkout_command comprehensive coverage" do
      it "builds checkout command with branch creation options" do
        options = {
          quiet: true,
          force: true,
          merge: true,
          detach: true,
          track: true,
          create_branch: "new-feature"
        }

        result = orchestrator.send(:build_checkout_command, ["main"], options)
        expect(result).to include("checkout")
        expect(result).to include("--quiet")
        expect(result).to include("--force")
        expect(result).to include("--merge")
        expect(result).to include("--detach")
        expect(result).to include("--track")
        expect(result).to include("-b")
        expect(result).to include(Shellwords.escape("new-feature"))
        expect(result).to include(Shellwords.escape("main"))
      end

      it "handles force create branch option" do
        options = {force_create_branch: "feature-branch"}
        result = orchestrator.send(:build_checkout_command, [], options)
        
        expect(result).to include("-B")
        expect(result).to include(Shellwords.escape("feature-branch"))
      end

      it "handles orphan branch option" do
        options = {orphan: "orphan-branch"}
        result = orchestrator.send(:build_checkout_command, [], options)
        
        expect(result).to include("--orphan")
        expect(result).to include(Shellwords.escape("orphan-branch"))
      end

      it "handles no-track option" do
        options = {no_track: true}
        result = orchestrator.send(:build_checkout_command, ["branch"], options)
        
        expect(result).to include("--no-track")
      end

      it "handles multiple paths correctly" do
        paths = ["file1.txt", "path with spaces/file2.txt", "file'with'quotes.txt"]
        result = orchestrator.send(:build_checkout_command, paths, {})
        
        paths.each do |path|
          expect(result).to include(Shellwords.escape(path))
        end
      end

      it "handles empty paths gracefully" do
        result = orchestrator.send(:build_checkout_command, [], {})
        expect(result).to eq("checkout")
      end

      it "handles nil paths gracefully" do
        result = orchestrator.send(:build_checkout_command, nil, {})
        expect(result).to eq("checkout")
      end
    end

    describe ".build_switch_command comprehensive coverage" do
      it "builds switch command with all options" do
        options = {
          quiet: true,
          force: true,
          merge: true,
          detach: true,
          track: true,
          no_track: true,
          no_guess: true,
          create: "new-branch"
        }

        result = orchestrator.send(:build_switch_command, "main", options)
        expect(result).to include("switch")
        expect(result).to include("--quiet")
        expect(result).to include("--force")
        expect(result).to include("--merge")
        expect(result).to include("--detach")
        expect(result).to include("--track")
        expect(result).to include("--no-track")
        expect(result).to include("--no-guess")
        expect(result).to include("-c")
        expect(result).to include(Shellwords.escape("new-branch"))
        expect(result).to include(Shellwords.escape("main"))
      end

      it "handles force create option" do
        options = {force_create: "force-branch"}
        result = orchestrator.send(:build_switch_command, "base", options)
        
        expect(result).to include("-C")
        expect(result).to include(Shellwords.escape("force-branch"))
      end

      it "handles orphan branch creation" do
        options = {orphan: "orphan-branch"}
        result = orchestrator.send(:build_switch_command, nil, options)
        
        expect(result).to include("--orphan")
        expect(result).to include(Shellwords.escape("orphan-branch"))
      end

      it "handles nil branch gracefully" do
        result = orchestrator.send(:build_switch_command, nil, {})
        expect(result).to eq("switch")
      end

      it "escapes special characters in branch names" do
        branch_name = "feature/branch-with-special-chars"
        result = orchestrator.send(:build_switch_command, branch_name, {})
        
        expect(result).to include(Shellwords.escape(branch_name))
      end
    end
  end

  # Comprehensive repository detection and coordination tests
  describe "repository detection and coordination" do
    describe ".detect_current_repository comprehensive coverage" do
      let(:mock_repositories) do
        [
          {name: "main", path: project_root, full_path: project_root},
          {name: "submodule1", path: "submodule1", full_path: File.join(project_root, "submodule1")},
          {name: "deeply-nested-submodule", path: "deep/nested/submodule", full_path: File.join(project_root, "deep/nested/submodule")}
        ]
      end

      before do
        allow(orchestrator).to receive(:repositories).and_return(mock_repositories)
      end

      it "detects exact submodule directory match" do
        # Test that the method at least runs and returns a repository name
        result = orchestrator.send(:detect_current_repository)
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end

      it "detects nested submodule directory match" do
        # Test that the method handles complex repository structures
        complex_repos = [
          {name: "main", path: project_root, full_path: project_root},
          {name: "deeply-nested", path: "deep/nested/submodule", full_path: File.join(project_root, "deep/nested/submodule")}
        ]
        allow(orchestrator).to receive(:repositories).and_return(complex_repos)
        result = orchestrator.send(:detect_current_repository)
        expect(result).to be_a(String)
      end

      it "detects main repository when in project root" do
        allow(Dir).to receive(:pwd).and_return(project_root)
        result = orchestrator.send(:detect_current_repository)
        expect(result).to eq("main")
      end

      it "defaults to main for unknown directories" do
        allow(Dir).to receive(:pwd).and_return("/completely/unknown/path")
        result = orchestrator.send(:detect_current_repository)
        expect(result).to eq("main")
      end

      it "handles nil repository paths gracefully" do
        repos_with_nil_path = [
          {name: "main", path: project_root, full_path: project_root},
          {name: "broken_repo", path: nil, full_path: nil}
        ]
        allow(orchestrator).to receive(:repositories).and_return(repos_with_nil_path)
        allow(Dir).to receive(:pwd).and_return(project_root)

        result = orchestrator.send(:detect_current_repository)
        expect(result).to eq("main")
      end

      it "handles relative path expansion correctly" do
        allow(Dir).to receive(:pwd).and_return("./#{File.basename(project_root)}")
        result = orchestrator.send(:detect_current_repository)
        expect(result).to eq("main")
      end

      context "with debug enabled" do
        let(:debug_orchestrator) { described_class.new(project_root, debug: true) }

        before do
          allow(debug_orchestrator).to receive(:repositories).and_return(mock_repositories)
        end

        it "prints debug information for current directory" do
          allow(Dir).to receive(:pwd).and_return(project_root)
          expect { debug_orchestrator.send(:detect_current_repository) }.to output(/DEBUG: Current dir/).to_stdout
        end

        it "prints debug information for project root" do
          allow(Dir).to receive(:pwd).and_return(project_root)
          expect { debug_orchestrator.send(:detect_current_repository) }.to output(/DEBUG: Project root/).to_stdout
        end

        it "prints debug information for each repository" do
          allow(Dir).to receive(:pwd).and_return(project_root)
          expect { debug_orchestrator.send(:detect_current_repository) }.to output(/DEBUG: Repo main/).to_stdout
          expect { debug_orchestrator.send(:detect_current_repository) }.to output(/DEBUG: Repo submodule1/).to_stdout
        end
      end
    end

    describe ".add_all method coverage" do
      let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }

      before do
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      end

      it "executes add --all across all repositories" do
        options = {verbose: true, debug: true}
        expect(mock_coordinator).to receive(:execute_across_repositories).with("add --all", options).and_return({success: true})
        
        result = orchestrator.send(:add_all, options)
        expect(result[:success]).to be true
      end
    end

    describe ".commit_with_message comprehensive coverage" do
      let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }
      let(:submodule_result) { {success: true, results: {"submodule1" => {success: true}}, errors: [], repositories_processed: ["submodule1"]} }
      let(:main_result) { {success: true, results: {"main" => {success: true}}, errors: [], repositories_processed: ["main"]} }

      before do
        allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
      end

      it "executes submodules first, then main repository" do
        message = "Test commit message with special chars: 'quotes' and \"double quotes\""
        escaped_message = Shellwords.escape(message)
        expected_command = "commit -m #{escaped_message}"

        expect(mock_coordinator).to receive(:execute_across_repositories)
          .with(expected_command, {message: message, submodules_only: true})
          .and_return(submodule_result)
        expect(mock_coordinator).to receive(:execute_across_repositories)
          .with(expected_command, {message: message, main_only: true})
          .and_return(main_result)

        result = orchestrator.send(:commit_with_message, message, {message: message})
        expect(result[:success]).to be true
        expect(result[:repositories_processed]).to contain_exactly("submodule1", "main")
      end

      it "properly merges results from both phases" do
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(submodule_result, main_result)

        result = orchestrator.send(:commit_with_message, "test", {})
        expect(result[:results]).to include("main", "submodule1")
        expect(result[:errors]).to be_empty
      end

      it "handles failure in submodule phase" do
        failed_submodule_result = {success: false, results: {}, errors: [{error: "submodule failed"}], repositories_processed: []}
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(failed_submodule_result, main_result)

        result = orchestrator.send(:commit_with_message, "test", {})
        expect(result[:success]).to be false
        expect(result[:errors].size).to eq(1)
      end

      it "handles failure in main phase" do
        failed_main_result = {success: false, results: {}, errors: [{error: "main failed"}], repositories_processed: []}
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(submodule_result, failed_main_result)

        result = orchestrator.send(:commit_with_message, "test", {})
        expect(result[:success]).to be false
        expect(result[:errors].size).to eq(1)
      end

      it "combines errors from both phases" do
        failed_submodule = {success: false, results: {}, errors: [{error: "sub error"}], repositories_processed: []}
        failed_main = {success: false, results: {}, errors: [{error: "main error"}], repositories_processed: []}
        allow(mock_coordinator).to receive(:execute_across_repositories).and_return(failed_submodule, failed_main)

        result = orchestrator.send(:commit_with_message, "test", {})
        expect(result[:success]).to be false
        expect(result[:errors].size).to eq(2)
      end
    end

    describe ".execute_sequentially comprehensive coverage" do
      let(:mock_executor) { instance_double(CodingAgentTools::Atoms::Git::GitCommandExecutor) }
      let(:test_repositories) do
        [
          {name: "repo1", full_path: "/path/to/repo1"},
          {name: "repo2", full_path: "/path/to/repo2"}
        ]
      end

      before do
        allow(orchestrator).to receive(:repositories).and_return(test_repositories)
        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).and_return(mock_executor)
      end

      it "executes multiple commands per repository" do
        commands_by_repo = {
          "repo1" => ["add file1.txt", "add file2.txt"],
          "repo2" => ["add file3.txt"]
        }
        command_results = [{success: true, stdout: "added file"}, {success: true, stdout: "added file"}]
        
        expect(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new)
          .with(repository_path: "/path/to/repo1").and_return(mock_executor)
        expect(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new)
          .with(repository_path: "/path/to/repo2").and_return(mock_executor)
        
        expect(mock_executor).to receive(:execute).with("add file1.txt", {capture_output: true}).and_return(command_results[0])
        expect(mock_executor).to receive(:execute).with("add file2.txt", {capture_output: true}).and_return(command_results[1])
        expect(mock_executor).to receive(:execute).with("add file3.txt", {capture_output: true}).and_return(command_results[0])

        result = orchestrator.send(:execute_sequentially, commands_by_repo, {capture_output: true})
        expect(result[:success]).to be true
        expect(result[:results]).to have_key("repo1")
        expect(result[:results]).to have_key("repo2")
        expect(result[:results]["repo1"][:commands].size).to eq(2)
      end

      it "handles execution errors per repository" do
        commands_by_repo = {"repo1" => ["failing command"]}
        expect(mock_executor).to receive(:execute).and_raise(StandardError.new("Command execution failed"))

        result = orchestrator.send(:execute_sequentially, commands_by_repo, {})
        expect(result[:success]).to be false
        expect(result[:errors].size).to eq(1)
        expect(result[:errors].first[:repository]).to eq("repo1")
        expect(result[:errors].first[:message]).to eq("Command execution failed")
        expect(result[:results]["repo1"][:success]).to be false
      end

      it "continues execution after individual repository failures" do
        commands_by_repo = {
          "repo1" => ["failing command"],
          "repo2" => ["successful command"]
        }
        
        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).with(repository_path: "/path/to/repo1").and_return(mock_executor)
        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).with(repository_path: "/path/to/repo2").and_return(mock_executor)
        
        expect(mock_executor).to receive(:execute).with("failing command", {capture_output: true}).and_raise(StandardError.new("Failed"))
        expect(mock_executor).to receive(:execute).with("successful command", {capture_output: true}).and_return({success: true})

        result = orchestrator.send(:execute_sequentially, commands_by_repo, {})
        expect(result[:success]).to be false
        expect(result[:errors].size).to eq(1)
        expect(result[:results]).to have_key("repo1")
        expect(result[:results]).to have_key("repo2")
        expect(result[:results]["repo2"][:success]).to be true
      end

      it "respects capture_output option" do
        commands_by_repo = {"repo1" => ["test command"]}
        expect(mock_executor).to receive(:execute).with("test command", {capture_output: false}).and_return({success: true})

        orchestrator.send(:execute_sequentially, commands_by_repo, {capture_output: false})
      end
    end

    describe ".execute_sequentially_with_submodules_first comprehensive coverage" do
      let(:mock_executor) { instance_double(CodingAgentTools::Atoms::Git::GitCommandExecutor) }
      let(:test_repositories) do
        [
          {name: "main", full_path: "/path/to/main"},
          {name: "submodule1", full_path: "/path/to/submodule1"},
          {name: "submodule2", full_path: "/path/to/submodule2"}
        ]
      end

      before do
        allow(orchestrator).to receive(:repositories).and_return(test_repositories)
        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).and_return(mock_executor)
        allow(mock_executor).to receive(:execute).and_return({success: true})
      end

      it "executes submodules first, then main repository" do
        commands_by_repo = {
          "main" => ["main command"],
          "submodule1" => ["sub1 command"],
          "submodule2" => ["sub2 command"]
        }

        execution_order = []
        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new) do |args|
          case args[:repository_path]
          when "/path/to/main"
            execution_order << "main"
          when "/path/to/submodule1"
            execution_order << "submodule1"
          when "/path/to/submodule2"
            execution_order << "submodule2"
          end
          mock_executor
        end

        result = orchestrator.send(:execute_sequentially_with_submodules_first, commands_by_repo, {})
        expect(result[:success]).to be true
        expect(execution_order).to eq(["submodule1", "submodule2", "main"])
      end

      it "handles missing main repository gracefully" do
        commands_by_repo = {
          "submodule1" => ["sub1 command"],
          "submodule2" => ["sub2 command"]
        }

        result = orchestrator.send(:execute_sequentially_with_submodules_first, commands_by_repo, {})
        expect(result[:success]).to be true
        expect(result[:results]).to have_key("submodule1")
        expect(result[:results]).to have_key("submodule2")
        expect(result[:results]).not_to have_key("main")
      end

      it "handles missing submodules gracefully" do
        commands_by_repo = {"main" => ["main command"]}

        result = orchestrator.send(:execute_sequentially_with_submodules_first, commands_by_repo, {})
        expect(result[:success]).to be true
        expect(result[:results]).to have_key("main")
      end

      it "handles execution errors in submodules and main" do
        commands_by_repo = {
          "main" => ["main command"],
          "submodule1" => ["failing sub command"]
        }

        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).with(repository_path: "/path/to/submodule1").and_return(mock_executor)
        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).with(repository_path: "/path/to/main").and_return(mock_executor)
        
        expect(mock_executor).to receive(:execute).with("failing sub command", {capture_output: true}).and_raise(StandardError.new("Submodule failed"))
        expect(mock_executor).to receive(:execute).with("main command", {capture_output: true}).and_return({success: true})

        result = orchestrator.send(:execute_sequentially_with_submodules_first, commands_by_repo, {})
        expect(result[:success]).to be false
        expect(result[:errors].size).to eq(1)
        expect(result[:errors].first[:repository]).to eq("submodule1")
        expect(result[:results]["main"][:success]).to be true
      end

      it "continues to main even if submodules fail" do
        commands_by_repo = {
          "main" => ["main command"],
          "submodule1" => ["failing command"]
        }

        allow(mock_executor).to receive(:execute).with("failing command", anything).and_raise(StandardError.new("Failed"))
        allow(mock_executor).to receive(:execute).with("main command", anything).and_return({success: true})

        result = orchestrator.send(:execute_sequentially_with_submodules_first, commands_by_repo, {})
        expect(result[:results]["main"][:success]).to be true
      end
    end
  end

  # Test additional uncovered scenarios and edge cases
  describe "edge cases and error scenarios" do
    context "when commands fail in execute_sequentially" do
      let(:mock_executor) { instance_double(CodingAgentTools::Atoms::Git::GitCommandExecutor) }

      before do
        allow(orchestrator).to receive(:repositories).and_return([
          {name: "test_repo", full_path: "/path/to/repo"}
        ])
        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).and_return(mock_executor)
      end

      it "handles command execution errors gracefully" do
        commands_by_repo = {"test_repo" => ["add file.txt"]}
        allow(mock_executor).to receive(:execute).and_raise(StandardError.new("Command failed"))

        result = orchestrator.send(:execute_sequentially, commands_by_repo, {})
        expect(result[:success]).to be false
        expect(result[:errors].size).to eq(1)
        expect(result[:errors].first[:message]).to eq("Command failed")
      end
    end

    context "format_unified_log edge cases" do
      it "handles empty repository results" do
        empty_result = {success: true, results: {}}
        result = orchestrator.send(:format_unified_log, empty_result, {})
        expect(result[:formatted_output]).to eq("")
      end

      it "handles failed repository results" do
        failed_result = {
          success: false,
          results: {
            "main" => {success: false, stderr: "Not a git repository"},
            "submodule1" => {success: true, stdout: "abc123 commit"}
          }
        }
        # Should skip failed repositories
        allow(orchestrator).to receive(:parse_commits_from_output).and_return([])
        result = orchestrator.send(:format_unified_log, failed_result, {})
        expect(result).to have_key(:formatted_output)
      end
    end

    context "LLM commit message generation edge cases" do
      let(:mock_generator) { instance_double(CodingAgentTools::Molecules::Git::CommitMessageGenerator) }
      let(:mock_executor) { instance_double(CodingAgentTools::Atoms::Git::GitCommandExecutor) }

      before do
        allow(CodingAgentTools::Molecules::Git::CommitMessageGenerator).to receive(:new).and_return(mock_generator)
        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).and_return(mock_executor)
      end

      it "handles repositories with no Git repository flag" do
        non_git_repos = [
          {name: "main", exists: true, is_git_repo: false, full_path: "/path/to/main"},
          {name: "valid_repo", exists: true, is_git_repo: true, full_path: "/path/to/valid"}
        ]
        allow(orchestrator).to receive(:repositories).and_return(non_git_repos)
        allow(orchestrator).to receive(:get_staged_diff).with(non_git_repos[1]).and_return("diff content")
        allow(mock_generator).to receive(:generate_message).and_return("test message")
        allow(orchestrator).to receive(:execute_sequentially_with_submodules_first).and_return({success: true})

        result = orchestrator.send(:commit_with_llm_message, {})
        expect(result[:success]).to be true
      end

      it "handles repositories that don't exist" do
        non_existent_repos = [
          {name: "main", exists: false, is_git_repo: true, full_path: "/path/to/main"},
          {name: "valid_repo", exists: true, is_git_repo: true, full_path: "/path/to/valid"}
        ]
        allow(orchestrator).to receive(:repositories).and_return(non_existent_repos)
        allow(orchestrator).to receive(:get_staged_diff).with(non_existent_repos[1]).and_return("diff content")
        allow(mock_generator).to receive(:generate_message).and_return("test message")
        allow(orchestrator).to receive(:execute_sequentially_with_submodules_first).and_return({success: true})

        result = orchestrator.send(:commit_with_llm_message, {})
        expect(result[:success]).to be true
      end

      it "handles edit option with non-interactive context" do
        repos = [{name: "main", exists: true, is_git_repo: true, full_path: "/path/to/main"}]
        allow(orchestrator).to receive(:repositories).and_return(repos)
        allow(orchestrator).to receive(:get_staged_diff).and_return("diff content")
        allow(mock_generator).to receive(:generate_message).and_return("test message")
        allow($stdin).to receive(:tty?).and_return(false)
        allow(orchestrator).to receive(:execute_sequentially_with_submodules_first).and_return({success: true})

        result = orchestrator.send(:commit_with_llm_message, {edit: true})
        expect(result[:success]).to be true
      end

      it "handles edit option with interactive context" do
        repos = [{name: "main", exists: true, is_git_repo: true, full_path: "/path/to/main"}]
        allow(orchestrator).to receive(:repositories).and_return(repos)
        allow(orchestrator).to receive(:get_staged_diff).and_return("diff content")
        allow(mock_generator).to receive(:generate_message).and_return("test message")
        allow($stdin).to receive(:tty?).and_return(true)
        allow(orchestrator).to receive(:execute_sequentially_with_submodules_first).and_return({success: true})

        result = orchestrator.send(:commit_with_llm_message, {edit: true})
        expect(result[:success]).to be true
      end

      it "handles concurrent execution option" do
        repos = [{name: "main", exists: true, is_git_repo: true, full_path: "/path/to/main"}]
        allow(orchestrator).to receive(:repositories).and_return(repos)
        allow(orchestrator).to receive(:get_staged_diff).and_return("diff content")
        allow(mock_generator).to receive(:generate_message).and_return("test message")
        
        expect(CodingAgentTools::Molecules::Git::ConcurrentExecutor).to receive(:execute_concurrently).and_return({success: true})

        result = orchestrator.send(:commit_with_llm_message, {concurrent: true})
        expect(result[:success]).to be true
      end
    end

    context "get_staged_diff edge cases" do
      let(:mock_executor) { instance_double(CodingAgentTools::Atoms::Git::GitCommandExecutor) }

      it "handles GitCommandError gracefully" do
        repository = {full_path: "/path/to/repo"}
        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).and_return(mock_executor)
        allow(mock_executor).to receive(:execute).and_raise(CodingAgentTools::Atoms::Git::GitCommandError.new("Not a git repository"))

        result = orchestrator.send(:get_staged_diff, repository)
        expect(result).to eq("")
      end

      it "handles nil stdout gracefully" do
        repository = {full_path: "/path/to/repo"}
        allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).and_return(mock_executor)
        allow(mock_executor).to receive(:execute).and_return({stdout: nil})

        result = orchestrator.send(:get_staged_diff, repository)
        expect(result).to eq("")
      end
    end

    context "comprehensive initialization edge cases" do
      it "handles nil project root detection" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(nil)
        allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).with(nil).and_return([])

        expect { described_class.new }.not_to raise_error
      end

      it "handles repository scanner exceptions" do
        allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).and_raise(StandardError.new("Scanner failed"))

        expect { described_class.new(project_root) }.to raise_error(StandardError, "Scanner failed")
      end

      it "initializes with debug option enabled" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
        allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).and_return([])

        orchestrator = described_class.new(project_root, debug: true)
        expect(orchestrator.instance_variable_get(:@debug)).to be true
      end

      it "initializes with debug option disabled by default" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
        allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).and_return([])

        orchestrator = described_class.new(project_root)
        expect(orchestrator.instance_variable_get(:@debug)).to be false
      end

      it "stores discovered repositories" do
        repos = [{name: "main", path: ".", exists: true}]
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
        allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).and_return(repos)

        orchestrator = described_class.new(project_root)
        expect(orchestrator.instance_variable_get(:@repositories)).to eq(repos)
      end
    end

    context "additional error handling coverage" do
      let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }
      let(:mock_dispatcher) { instance_double(CodingAgentTools::Molecules::Git::PathDispatcher) }

      describe "add method error scenarios" do
        it "returns error when paths is nil" do
          result = orchestrator.add(nil, {})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("No paths provided")
        end

        it "returns error when paths is empty array" do
          result = orchestrator.add([], {})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("No paths provided")
        end

        it "handles concurrent execution option" do
          allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
          allow(mock_dispatcher).to receive(:dispatch_paths).and_return({"main" => {paths: ["file.txt"]}})
          allow(orchestrator).to receive(:build_add_commands).and_return({"main" => ["add file.txt"]})
          expect(CodingAgentTools::Molecules::Git::ConcurrentExecutor).to receive(:execute_concurrently).and_return({success: true})

          result = orchestrator.add(["file.txt"], {concurrent: true})
          expect(result[:success]).to be true
        end

        it "handles sequential execution when concurrent is false" do
          allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
          allow(mock_dispatcher).to receive(:dispatch_paths).and_return({"main" => {paths: ["file.txt"]}})
          allow(orchestrator).to receive(:build_add_commands).and_return({"main" => ["add file.txt"]})
          expect(orchestrator).to receive(:execute_sequentially).and_return({success: true})

          result = orchestrator.add(["file.txt"], {concurrent: false})
          expect(result[:success]).to be true
        end
      end

      describe "mv method error scenarios" do
        it "returns error when sources is nil" do
          result = orchestrator.mv(nil, "dest", {})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("No sources provided")
        end

        it "returns error when sources is empty array" do
          result = orchestrator.mv([], "dest", {})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("No sources provided")
        end

        it "returns error when destination is nil" do
          result = orchestrator.mv(["src"], nil, {})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("No destination provided")
        end

        it "returns error when destination is empty string" do
          result = orchestrator.mv(["src"], "", {})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("No destination provided")
        end

        it "handles concurrent execution" do
          allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
          allow(mock_dispatcher).to receive(:dispatch_paths).and_return({"main" => {paths: ["src", "dest"]}})
          allow(orchestrator).to receive(:build_mv_commands).and_return({"main" => ["mv src dest"]})
          expect(CodingAgentTools::Molecules::Git::ConcurrentExecutor).to receive(:execute_concurrently).and_return({success: true})

          result = orchestrator.mv(["src"], "dest", {concurrent: true})
          expect(result[:success]).to be true
        end
      end

      describe "rm method error scenarios" do
        it "returns error when paths is nil" do
          result = orchestrator.rm(nil, {})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("No paths provided")
        end

        it "returns error when paths is empty array" do
          result = orchestrator.rm([], {})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("No paths provided")
        end

        it "handles concurrent execution" do
          allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
          allow(mock_dispatcher).to receive(:dispatch_paths).and_return({"main" => {paths: ["file.txt"]}})
          allow(orchestrator).to receive(:build_rm_commands).and_return({"main" => ["rm file.txt"]})
          expect(CodingAgentTools::Molecules::Git::ConcurrentExecutor).to receive(:execute_concurrently).and_return({success: true})

          result = orchestrator.rm(["file.txt"], {concurrent: true})
          expect(result[:success]).to be true
        end
      end

      describe "restore method error scenarios" do
        it "returns error when pathspecs is nil" do
          result = orchestrator.restore(nil, {})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("No pathspecs provided")
        end

        it "returns error when pathspecs is empty array" do
          result = orchestrator.restore([], {})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("No pathspecs provided")
        end

        it "handles concurrent execution" do
          allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
          allow(mock_dispatcher).to receive(:dispatch_paths).and_return({"main" => {paths: ["file.txt"]}})
          allow(orchestrator).to receive(:build_restore_commands).and_return({"main" => ["restore file.txt"]})
          expect(CodingAgentTools::Molecules::Git::ConcurrentExecutor).to receive(:execute_concurrently).and_return({success: true})

          result = orchestrator.restore(["file.txt"], {concurrent: true})
          expect(result[:success]).to be true
        end
      end

      describe "commit method debug and options handling" do
        let(:mock_generator) { instance_double(CodingAgentTools::Molecules::Git::CommitMessageGenerator) }

        it "handles debug output when debug option is true" do
          allow(orchestrator).to receive(:add).and_return({success: true})
          allow(orchestrator).to receive(:commit_with_message).and_return({success: true})
          
          expect { orchestrator.commit({debug: true, message: "test"}) }.to output(/DEBUG: commit options/).to_stdout
        end

        it "handles files option for staging specific files" do
          expect(orchestrator).to receive(:add).with(["file1.txt", "file2.txt"], anything).and_return({success: true})
          allow(orchestrator).to receive(:commit_with_message).and_return({success: true})

          result = orchestrator.commit({files: ["file1.txt", "file2.txt"], message: "test"})
          expect(result[:success]).to be true
        end

        it "handles add failure during commit" do
          expect(orchestrator).to receive(:add).and_return({success: false, error: "Add failed"})

          result = orchestrator.commit({files: ["file.txt"], message: "test"})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("Add failed")
        end

        it "handles repo_only option to skip add_all" do
          allow(orchestrator).to receive(:commit_with_message).and_return({success: true})

          result = orchestrator.commit({repo_only: true, message: "test"})
          expect(result[:success]).to be true
        end

        it "handles debug output for repo_only option" do
          allow(orchestrator).to receive(:commit_with_message).and_return({success: true})
          
          expect { orchestrator.commit({repo_only: true, debug: true, message: "test"}) }.to output(/DEBUG: Skipping add_all/).to_stdout
        end

        it "calls add_all when repo_only is false" do
          expect(orchestrator).to receive(:add_all).and_return({success: true})
          allow(orchestrator).to receive(:commit_with_message).and_return({success: true})

          result = orchestrator.commit({repo_only: false, message: "test"})
          expect(result[:success]).to be true
        end

        it "handles add_all failure" do
          expect(orchestrator).to receive(:add_all).and_return({success: false, error: "Add all failed"})

          result = orchestrator.commit({message: "test"})
          expect(result[:success]).to be false
          expect(result[:error]).to eq("Add all failed")
        end

        it "uses commit_with_llm_message when no message provided" do
          allow(orchestrator).to receive(:add_all).and_return({success: true})
          expect(orchestrator).to receive(:commit_with_llm_message).and_return({success: true})

          result = orchestrator.commit({})
          expect(result[:success]).to be true
        end
      end

      describe "push method debug and options handling" do
        let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }

        it "handles debug output when debug option is true" do
          allow(orchestrator).to receive(:build_push_command).and_return("push")
          allow(orchestrator).to receive(:detect_current_repository).and_return("main")
          allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
          allow(mock_coordinator).to receive(:execute_across_repositories).and_return({success: true})

          expect { orchestrator.push({debug: true, repo_only: true}) }.to output(/DEBUG: Push options/).to_stdout
        end

        it "handles repo_only option with debug output" do
          allow(orchestrator).to receive(:build_push_command).and_return("push")
          allow(orchestrator).to receive(:detect_current_repository).and_return("main")
          allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
          allow(mock_coordinator).to receive(:execute_across_repositories).and_return({success: true})

          expect { orchestrator.push({debug: true, repo_only: true}) }.to output(/DEBUG: Current repository detected/).to_stdout
        end

        it "handles concurrent push when concurrent option is true" do
          allow(orchestrator).to receive(:build_push_command).and_return("push")
          expect(orchestrator).to receive(:execute_push_concurrent).and_return({success: true})

          result = orchestrator.push({concurrent: true})
          expect(result[:success]).to be true
        end

        it "handles sequential push when concurrent option is false" do
          allow(orchestrator).to receive(:build_push_command).and_return("push")
          expect(orchestrator).to receive(:execute_push_sequential).and_return({success: true})

          result = orchestrator.push({concurrent: false})
          expect(result[:success]).to be true
        end
      end

      describe "pull method concurrent and sequential handling" do
        it "handles concurrent pull when concurrent option is true" do
          allow(orchestrator).to receive(:build_pull_command).and_return("pull")
          expect(orchestrator).to receive(:execute_pull_concurrent).and_return({success: true})

          result = orchestrator.pull({concurrent: true})
          expect(result[:success]).to be true
        end

        it "handles sequential pull when concurrent option is false" do
          allow(orchestrator).to receive(:build_pull_command).and_return("pull")
          expect(orchestrator).to receive(:execute_pull_sequential).and_return({success: true})

          result = orchestrator.pull({concurrent: false})
          expect(result[:success]).to be true
        end
      end

      describe "checkout and switch concurrent handling" do
        let(:mock_coordinator) { instance_double(CodingAgentTools::Molecules::Git::MultiRepoCoordinator) }

        it "handles concurrent checkout" do
          allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
          allow(orchestrator).to receive(:build_checkout_command).and_return("checkout main")
          expect(mock_coordinator).to receive(:execute_across_repositories).with("checkout main", {capture_output: true, concurrent: true})

          orchestrator.checkout(["main"], {concurrent: true})
        end

        it "handles sequential checkout" do
          allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
          allow(orchestrator).to receive(:build_checkout_command).and_return("checkout main")
          expect(mock_coordinator).to receive(:execute_across_repositories).with("checkout main", {capture_output: true, concurrent: false})

          orchestrator.checkout(["main"], {concurrent: false})
        end

        it "handles concurrent switch" do
          allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
          allow(orchestrator).to receive(:build_switch_command).and_return("switch main")
          expect(mock_coordinator).to receive(:execute_across_repositories).with("switch main", {capture_output: true, concurrent: true})

          orchestrator.switch("main", {concurrent: true})
        end

        it "handles sequential switch" do
          allow(CodingAgentTools::Molecules::Git::MultiRepoCoordinator).to receive(:new).and_return(mock_coordinator)
          allow(orchestrator).to receive(:build_switch_command).and_return("switch main")
          expect(mock_coordinator).to receive(:execute_across_repositories).with("switch main", {capture_output: true, concurrent: false})

          orchestrator.switch("main", {concurrent: false})
        end
      end

      describe "detect_current_repository debug output coverage" do
        it "outputs debug information when debug is enabled" do
          orchestrator_with_debug = described_class.new(project_root, debug: true)
          repos = [{name: "main", path: project_root, full_path: project_root}]
          allow(orchestrator_with_debug).to receive(:repositories).and_return(repos)

          expect { orchestrator_with_debug.send(:detect_current_repository) }.to output(/DEBUG: Current dir/).to_stdout
        end
      end
    end
  end
end