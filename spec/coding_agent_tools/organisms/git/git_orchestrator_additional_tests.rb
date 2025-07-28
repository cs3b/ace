# Additional tests for GitOrchestrator - to be merged with main test file

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

    it "builds mv commands with options" do
      dispatch_info = {
        "main" => {paths: ["old.txt", "new.txt"]}
      }
      sources = ["old.txt"]
      destination = "new.txt"
      options = {force: true, dry_run: true, verbose: true}
      
      commands = orchestrator.send(:build_mv_commands, dispatch_info, sources, destination, options)
      
      expect(commands["main"].first).to include("--force")
      expect(commands["main"].first).to include("--dry-run")
      expect(commands["main"].first).to include("--verbose")
    end

    it "skips cross-repository moves" do
      dispatch_info = {
        "main" => {paths: ["old.txt"]},
        "submodule1" => {paths: ["new.txt"]}
      }
      sources = ["old.txt"]
      destination = "new.txt"
      
      commands = orchestrator.send(:build_mv_commands, dispatch_info, sources, destination, {})
      
      expect(commands).to be_empty
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

    it "builds rm commands with all options" do
      dispatch_info = {
        "main" => {paths: ["file1.txt"]}
      }
      options = {force: true, dry_run: true, recursive: true, cached: true, ignore_unmatch: true, quiet: true}
      
      commands = orchestrator.send(:build_rm_commands, dispatch_info, options)
      
      command = commands["main"].first
      expect(command).to include("--force")
      expect(command).to include("--dry-run")
      expect(command).to include("--recursive")
      expect(command).to include("--cached")
      expect(command).to include("--ignore-unmatch")
      expect(command).to include("--quiet")
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

    it "builds restore commands with all options" do
      dispatch_info = {
        "main" => {paths: ["file1.txt"]}
      }
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
      
      commands = orchestrator.send(:build_restore_commands, dispatch_info, options)
      
      command = commands["main"].first
      expect(command).to include("--source=HEAD~1")
      expect(command).to include("--staged")
      expect(command).to include("--worktree")
      expect(command).to include("--merge")
      expect(command).to include("--conflict=merge")
      expect(command).to include("--ours")
      expect(command).to include("--theirs")
      expect(command).to include("--patch")
      expect(command).to include("--quiet")
      expect(command).to include("--progress")
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