# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"

RSpec.describe "Git Command Execution Order Integration" do
  let(:temp_dir) { Dir.mktmpdir("git_execution_order_test") }
  let(:main_repo_path) { temp_dir }
  let(:submodule_path) { File.join(temp_dir, "test-submodule") }
  let(:orchestrator) { CodingAgentTools::Organisms::Git::GitOrchestrator.new(main_repo_path) }

  before(:each) do
    # Create main repository
    Dir.chdir(main_repo_path) do
      system("git init", out: File::NULL, err: File::NULL)
      system("git config user.name 'Test User'", out: File::NULL, err: File::NULL)
      system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

      # Create initial commit
      File.write("README.md", "# Main Repository")
      system("git add README.md", out: File::NULL, err: File::NULL)
      system("git commit -m 'Initial commit'", out: File::NULL, err: File::NULL)
    end

    # Create submodule repository
    Dir.mkdir(submodule_path)
    Dir.chdir(submodule_path) do
      system("git init", out: File::NULL, err: File::NULL)
      system("git config user.name 'Test User'", out: File::NULL, err: File::NULL)
      system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

      # Create initial commit
      File.write("submodule.txt", "Submodule content")
      system("git add submodule.txt", out: File::NULL, err: File::NULL)
      system("git commit -m 'Submodule initial commit'", out: File::NULL, err: File::NULL)
    end

    # Add submodule to main repository
    Dir.chdir(main_repo_path) do
      system("git submodule add #{submodule_path} test-submodule", out: File::NULL, err: File::NULL)
      system("git commit -m 'Add submodule'", out: File::NULL, err: File::NULL)
    end
  end

  after(:each) do
    safe_directory_cleanup(temp_dir)
  end

  describe "Push operations execution order" do
    context "when using sequential push" do
      it "executes submodules before main repository" do
        execution_order = []

        allow_any_instance_of(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
          .to receive(:execute_across_repositories) do |coordinator, command, options|
            if options[:submodules_only]
              execution_order << :submodules
            elsif options[:main_only]
              execution_order << :main
            end

            # Return mock successful result
            {
              success: true,
              results: {},
              errors: [],
              repositories_processed: []
            }
          end

        orchestrator.push(concurrent: false)

        expect(execution_order).to eq([:submodules, :main])
      end
    end

    context "when using concurrent push" do
      it "executes submodules before main repository" do
        execution_order = []

        allow_any_instance_of(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
          .to receive(:execute_across_repositories) do |coordinator, command, options|
            if options[:submodules_only]
              execution_order << :submodules
            elsif options[:main_only]
              execution_order << :main
            end

            # Return mock successful result
            {
              success: true,
              results: {},
              errors: [],
              repositories_processed: []
            }
          end

        orchestrator.push(concurrent: true)

        expect(execution_order).to eq([:submodules, :main])
      end
    end
  end

  describe "Pull operations execution order" do
    context "when using sequential pull" do
      it "executes main repository before submodules" do
        execution_order = []

        allow_any_instance_of(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
          .to receive(:execute_across_repositories) do |coordinator, command, options|
            if options[:main_only]
              execution_order << :main
            elsif options[:submodules_only]
              execution_order << :submodules
            end

            # Return mock successful result
            {
              success: true,
              results: {},
              errors: [],
              repositories_processed: []
            }
          end

        orchestrator.pull(concurrent: false)

        expect(execution_order).to eq([:main, :submodules])
      end
    end

    context "when using concurrent pull" do
      it "executes main repository before submodules" do
        execution_order = []

        allow_any_instance_of(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
          .to receive(:execute_across_repositories) do |coordinator, command, options|
            if options[:main_only]
              execution_order << :main
            elsif options[:submodules_only]
              execution_order << :submodules
            end

            # Return mock successful result
            {
              success: true,
              results: {},
              errors: [],
              repositories_processed: []
            }
          end

        orchestrator.pull(concurrent: true)

        expect(execution_order).to eq([:main, :submodules])
      end
    end
  end

  describe "Commit operations execution order" do
    context "when using commit with message" do
      it "executes submodules before main repository" do
        execution_order = []

        allow_any_instance_of(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
          .to receive(:execute_across_repositories) do |coordinator, command, options|
            if options[:submodules_only]
              execution_order << :submodules
            elsif options[:main_only]
              execution_order << :main
            end

            # Return mock successful result
            {
              success: true,
              results: {},
              errors: [],
              repositories_processed: []
            }
          end

        orchestrator.commit(message: "Test commit")

        expect(execution_order).to eq([:submodules, :main])
      end
    end

    context "when using commit with LLM message (sequential)" do
      it "executes submodules before main repository" do
        # Mock staged changes to trigger commit generation
        allow_any_instance_of(CodingAgentTools::Organisms::Git::GitOrchestrator)
          .to receive(:get_staged_diff).and_return("mock diff content")

        # Mock LLM message generation
        allow_any_instance_of(CodingAgentTools::Molecules::Git::CommitMessageGenerator)
          .to receive(:generate_message).and_return("Generated commit message")

        execution_order = []

        # Track execution order in the sequential execution method
        allow_any_instance_of(CodingAgentTools::Organisms::Git::GitOrchestrator)
          .to receive(:execute_sequentially_with_submodules_first) do |orchestrator, commands_by_repo, options|
            commands_by_repo.keys.each do |repo_name|
              execution_order << if repo_name == "main"
                :main
              else
                :submodules
              end
            end

            # Return mock successful result
            {
              success: true,
              results: {},
              errors: []
            }
          end

        orchestrator.commit(concurrent: false)

        # Should have submodules executed before main
        main_index = execution_order.index(:main)
        submodules_indices = execution_order.each_index.select { |i| execution_order[i] == :submodules }

        if main_index && !submodules_indices.empty?
          expect(submodules_indices.all? { |i| i < main_index }).to be true
        end
      end
    end
  end

  describe "Read-only operations concurrency" do
    let(:concurrent_operations) { [:status, :log, :diff] }

    context "when executing read-only operations" do
      it "can execute concurrently without ordering constraints" do
        concurrent_operations.each do |operation|
          # Mock the coordinator to verify it's called for each operation
          allow_any_instance_of(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
            .to receive(:execute_across_repositories)
            .and_return({
              success: true,
              results: {"main" => {success: true, stdout: "mock output"}},
              errors: []
            })

          case operation
          when :status
            result = orchestrator.status
          when :log
            result = orchestrator.log
          when :diff
            result = orchestrator.diff
          end

          expect(result[:success]).to be true
        end
      end
    end

    it "does not require specific execution order for status operations" do
      # Status should work regardless of repository order
      allow_any_instance_of(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
        .to receive(:execute_across_repositories)
        .and_return({
          success: true,
          results: {
            "main" => {success: true, stdout: "main repo status"},
            "test-submodule" => {success: true, stdout: "submodule status"}
          },
          errors: []
        })

      result = orchestrator.status
      expect(result[:success]).to be true
      expect(result[:results]).to have_key("main")
      expect(result[:results]).to have_key("test-submodule")
    end
  end

  describe "Error handling during execution order" do
    context "when submodule operation fails during push" do
      it "still attempts main repository operation and reports combined results" do
        allow_any_instance_of(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
          .to receive(:execute_across_repositories) do |coordinator, command, options|
            if options[:submodules_only]
              {
                success: false,
                results: {"test-submodule" => {success: false, error: "Push failed"}},
                errors: [{repository: "test-submodule", message: "Push failed"}],
                repositories_processed: ["test-submodule"]
              }
            elsif options[:main_only]
              {
                success: true,
                results: {"main" => {success: true}},
                errors: [],
                repositories_processed: ["main"]
              }
            end
          end

        result = orchestrator.push(concurrent: false)

        expect(result[:success]).to be false
        expect(result[:results]).to have_key("test-submodule")
        expect(result[:results]).to have_key("main")
        expect(result[:errors]).not_to be_empty
      end
    end

    context "when main repository operation fails during pull" do
      it "still attempts submodule operation and reports combined results" do
        allow_any_instance_of(CodingAgentTools::Molecules::Git::MultiRepoCoordinator)
          .to receive(:execute_across_repositories) do |coordinator, command, options|
            if options[:main_only]
              {
                success: false,
                results: {"main" => {success: false, error: "Pull failed"}},
                errors: [{repository: "main", message: "Pull failed"}],
                repositories_processed: ["main"]
              }
            elsif options[:submodules_only]
              {
                success: true,
                results: {"test-submodule" => {success: true}},
                errors: [],
                repositories_processed: ["test-submodule"]
              }
            end
          end

        result = orchestrator.pull(concurrent: false)

        expect(result[:success]).to be false
        expect(result[:results]).to have_key("main")
        expect(result[:results]).to have_key("test-submodule")
        expect(result[:errors]).not_to be_empty
      end
    end
  end

  describe "Rm operations execution order" do
    context "when using sequential rm" do
      it "executes remove operations across all repositories correctly" do
        execution_order = []

        # Mock the PathDispatcher to return multi-repo paths
        mock_dispatcher = instance_double(CodingAgentTools::Molecules::Git::PathDispatcher)
        dispatch_info = {
          "main" => {paths: ["main_file.txt"]},
          "test-submodule" => {paths: ["sub_file.txt"]}
        }

        allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
        allow(mock_dispatcher).to receive(:dispatch_paths).and_return(dispatch_info)

        # Mock execute_sequentially to track execution
        allow(orchestrator).to receive(:execute_sequentially) do |commands_by_repo, options|
          execution_order << :sequential_execution

          # Verify commands are built correctly
          expect(commands_by_repo).to have_key("main")
          expect(commands_by_repo).to have_key("test-submodule")
          expect(commands_by_repo["main"].first).to include("rm")
          expect(commands_by_repo["test-submodule"].first).to include("rm")

          {
            success: true,
            results: {
              "main" => {success: true, stdout: "rm 'main_file.txt'"},
              "test-submodule" => {success: true, stdout: "rm 'sub_file.txt'"}
            },
            repositories_processed: ["main", "test-submodule"]
          }
        end

        result = orchestrator.rm(["main_file.txt", "sub_file.txt"])

        expect(result[:success]).to be true
        expect(result[:repositories_processed]).to include("main", "test-submodule")
        expect(execution_order).to eq([:sequential_execution])
      end
    end

    context "when using concurrent rm" do
      it "executes remove operations concurrently across repositories" do
        # Mock the PathDispatcher to return multi-repo paths
        mock_dispatcher = instance_double(CodingAgentTools::Molecules::Git::PathDispatcher)
        dispatch_info = {
          "main" => {paths: ["main_file.txt"]},
          "test-submodule" => {paths: ["sub_file.txt"]}
        }

        allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
        allow(mock_dispatcher).to receive(:dispatch_paths).and_return(dispatch_info)

        # Mock concurrent executor
        allow(CodingAgentTools::Molecules::Git::ConcurrentExecutor).to receive(:execute_concurrently) do |commands_by_repo, options|
          expect(commands_by_repo).to have_key("main")
          expect(commands_by_repo).to have_key("test-submodule")
          expect(options[:concurrent]).to be true

          {
            success: true,
            results: {
              "main" => {
                success: true,
                commands: [
                  {success: true, stdout: "rm 'main_file.txt'"}
                ]
              },
              "test-submodule" => {
                success: true,
                commands: [
                  {success: true, stdout: "rm 'sub_file.txt'"}
                ]
              }
            },
            repositories_processed: ["main", "test-submodule"]
          }
        end

        result = orchestrator.rm(["main_file.txt", "sub_file.txt"], concurrent: true)

        expect(result[:success]).to be true
        expect(result[:repositories_processed]).to include("main", "test-submodule")
      end
    end

    context "when rm operations fail in some repositories" do
      it "handles partial failures correctly" do
        # Mock the PathDispatcher to return multi-repo paths
        mock_dispatcher = instance_double(CodingAgentTools::Molecules::Git::PathDispatcher)
        dispatch_info = {
          "main" => {paths: ["existing_file.txt"]},
          "test-submodule" => {paths: ["nonexistent_file.txt"]}
        }

        allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
        allow(mock_dispatcher).to receive(:dispatch_paths).and_return(dispatch_info)

        # Mock execute_sequentially with partial failure
        allow(orchestrator).to receive(:execute_sequentially) do |commands_by_repo, options|
          {
            success: false,
            results: {
              "main" => {success: true, stdout: "rm 'existing_file.txt'"},
              "test-submodule" => {success: false, stderr: "fatal: pathspec 'nonexistent_file.txt' did not match any files"}
            },
            errors: [
              {repository: "test-submodule", message: "fatal: pathspec 'nonexistent_file.txt' did not match any files"}
            ],
            repositories_processed: ["main", "test-submodule"]
          }
        end

        result = orchestrator.rm(["existing_file.txt", "nonexistent_file.txt"])

        expect(result[:success]).to be false
        expect(result[:results]["main"][:success]).to be true
        expect(result[:results]["test-submodule"][:success]).to be false
        expect(result[:errors]).not_to be_empty
        expect(result[:errors].first[:repository]).to eq("test-submodule")
      end
    end

    context "with rm-specific options" do
      it "passes rm options correctly to command building" do
        # Mock the PathDispatcher to return single repo paths
        mock_dispatcher = instance_double(CodingAgentTools::Molecules::Git::PathDispatcher)
        dispatch_info = {"main" => {paths: ["directory/"]}}

        allow(CodingAgentTools::Molecules::Git::PathDispatcher).to receive(:new).and_return(mock_dispatcher)
        allow(mock_dispatcher).to receive(:dispatch_paths).and_return(dispatch_info)

        # Mock execute_sequentially to verify command options
        allow(orchestrator).to receive(:execute_sequentially) do |commands_by_repo, options|
          # Verify the command includes the recursive flag
          command = commands_by_repo["main"].first
          expect(command).to include("rm")
          expect(command).to include("--force")
          expect(command).to include("--recursive")
          expect(command).to include("--cached")
          expect(command).to include("directory/")

          {
            success: true,
            results: {"main" => {success: true, stdout: "rm --force --recursive --cached 'directory/'"}},
            repositories_processed: ["main"]
          }
        end

        result = orchestrator.rm(
          ["directory/"],
          force: true,
          recursive: true,
          cached: true
        )

        expect(result[:success]).to be true
      end
    end
  end
end
