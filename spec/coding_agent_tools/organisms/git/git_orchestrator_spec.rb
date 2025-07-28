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
      expect(result).to include("oneline")
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
        expect(commands["main"]).to include("add")
        expect(commands["main"].first).to include("file1.txt")
        expect(commands["main"].first).to include("file2.txt")
      end

      context "with add options" do
        it "includes --all flag when specified" do
          commands = orchestrator.send(:build_add_commands, mock_dispatch_info, {all: true})
          expect(commands["main"].first).to include("--all")
        end

        it "includes --update flag when specified" do
          commands = orchestrator.send(:build_add_commands, mock_dispatch_info, {update: true})
          expect(commands["main"].first).to include("--update")
        end

        it "includes --force flag when specified" do
          commands = orchestrator.send(:build_add_commands, mock_dispatch_info, {force: true})
          expect(commands["main"].first).to include("--force")
        end

        it "includes --patch flag when specified" do
          commands = orchestrator.send(:build_add_commands, mock_dispatch_info, {patch: true})
          expect(commands["main"].first).to include("--patch")
        end
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
        allow(Dir).to receive(:pwd).and_return(File.join(project_root, "submodule1"))
        result = debug_orchestrator.send(:detect_current_repository)
        expect(result).to eq("submodule1")
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
        allow(mock_executor).to receive(:execute).and_raise(CodingAgentTools::Atoms::Git::GitCommandError)

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
        expect(result).to include("%h %s (%ci)")
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
  end
end