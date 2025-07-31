---
id: v.0.4.0+task.009
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Add --commit Flag to Ideas Manager

## Behavioral Specification

### User Experience
- **Input**: Users provide idea text and --commit flag
- **Process**: Ideas manager captures idea and automatically commits the generated file
- **Output**: Idea file created and committed in single operation

### Expected Behavior
Ideas manager should automatically commit newly created idea files when --commit flag is provided, eliminating the manual step of committing idea files after capture.

### Interface Contract
```bash
# CLI Interface
ideas-manager capture "some idea" --commit
ideas-manager capture "implement OAuth authentication" --commit
```

### Success Criteria

- [ ] Generated idea files are automatically committed when --commit flag is used
- [ ] Uses existing git-commit tool to perform the commit operation  
- [ ] Test environment detection prevents commits during testing
- [ ] Appropriate commit messages generated for idea file commits
- [ ] User receives feedback about both idea creation and commit status

### Validation Questions

- [ ] How should commit messages be formatted for idea files?
- [ ] What happens if git-commit fails during the auto-commit process?
- [ ] Should --commit work with other ideas-manager flags or be standalone?

## Objective

Streamline idea capture workflow by automatically committing generated idea files when users specify the --commit flag, reducing friction in the idea-to-storage process.

## Scope of Work

- Add --commit flag to ideas-manager CLI tool
- Integrate with existing git-commit functionality
- Handle test environment detection to prevent commits during testing

### Deliverables

#### Create

- No new files required

#### Modify

- ideas-manager CLI tool source code

#### Delete

- No files to delete

## Phases

1. Audit
2. Extract …
3. Refactor …

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Key components and their relationships are identified
  > Command: bin/test --check-analysis-complete
- [ ] Research best practices and design approach
- [ ] Plan detailed implementation strategy

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Step 1: Describe the first implementation action.
- [ ] Step 2: Describe the second action, which produces a verifiable outcome.
  > TEST: Verify Action 2 Outcome
  > Type: Action Validation
  > Assert: The outcome of Step 2 (e.g., file created, content updated) is as expected.
  > Command: bin/test --check-something path/to/relevant_artifact_from_step_2
- [ ] Create comprehensive RSpec tests for --commit flag functionality
  > TEST: RSpec Test Suite Creation  
  > Type: Test Implementation
  > Assert: Complete test coverage for --commit flag behavior and edge cases
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/ideas/capture_spec.rb spec/coding_agent_tools/organisms/idea_capture_spec.rb

## RSpec Test Specifications

### CLI Command Tests (spec/coding_agent_tools/cli/commands/ideas/capture_spec.rb)

```ruby
describe CodingAgentTools::Cli::Commands::Ideas::Capture do
  describe "--commit flag" do
    context "when --commit flag is provided" do
      it "passes commit_after_capture: true to IdeaCapture organism" do
        expect(CodingAgentTools::Organisms::IdeaCapture).to receive(:new)
          .with(hash_including(commit_after_capture: true))
        subject.call(idea_text: "test idea", commit: true)
      end
    end

    context "when --commit flag is not provided" do
      it "passes commit_after_capture: false to IdeaCapture organism" do
        expect(CodingAgentTools::Organisms::IdeaCapture).to receive(:new)
          .with(hash_including(commit_after_capture: false))
        subject.call(idea_text: "test idea")
      end
    end

    context "when --commit flag is used with other options" do
      it "combines --commit with --model flag correctly" do
        expect(CodingAgentTools::Organisms::IdeaCapture).to receive(:new)
          .with(hash_including(
            model: "anthropic:claude-3.5-sonnet",
            commit_after_capture: true
          ))
        subject.call(idea_text: "test idea", commit: true, model: "anthropic:claude-3.5-sonnet")
      end
    end
  end
end
```

### Organism Tests (spec/coding_agent_tools/organisms/idea_capture_spec.rb)

```ruby
describe CodingAgentTools::Organisms::IdeaCapture do
  describe "commit_after_capture functionality" do
    let(:mock_result) { double(success?: true, output_path: "/path/to/idea.md") }
    
    context "when commit_after_capture is true" do
      subject { described_class.new(commit_after_capture: true) }
      
      it "executes git-commit after successful idea creation" do
        allow(subject).to receive(:capture_idea_without_commit).and_return(mock_result)
        expect(subject).to receive(:execute_git_commit).with("/path/to/idea.md")
        
        subject.capture_idea("test idea")
      end

      it "handles git-commit execution errors gracefully" do
        allow(subject).to receive(:capture_idea_without_commit).and_return(mock_result)
        allow(subject).to receive(:execute_git_commit).and_raise(StandardError.new("git failed"))
        
        result = subject.capture_idea("test idea")
        expect(result.success?).to be true  # Idea creation still succeeds
        expect(result.error_message).to include("git failed")
      end

      context "in test environment" do
        before { allow(ENV).to receive(:[]).with('CI').and_return('true') }
        
        it "skips git-commit execution" do
          allow(subject).to receive(:capture_idea_without_commit).and_return(mock_result)
          expect(subject).not_to receive(:execute_git_commit)
          
          result = subject.capture_idea("test idea")
          expect(result.success?).to be true
        end
      end

      context "when TEST environment variable is set" do
        before { allow(ENV).to receive(:[]).with('TEST').and_return('1') }
        
        it "skips git-commit execution" do
          allow(subject).to receive(:capture_idea_without_commit).and_return(mock_result)
          expect(subject).not_to receive(:execute_git_commit)
          
          subject.capture_idea("test idea")
        end
      end
    end

    context "when commit_after_capture is false" do
      subject { described_class.new(commit_after_capture: false) }
      
      it "does not execute git-commit after idea creation" do
        allow(subject).to receive(:capture_idea_without_commit).and_return(mock_result)
        expect(subject).not_to receive(:execute_git_commit)
        
        subject.capture_idea("test idea")
      end
    end

    context "when idea creation fails" do
      let(:failed_result) { double(success?: false, error_message: "creation failed") }
      subject { described_class.new(commit_after_capture: true) }
      
      it "does not attempt git-commit" do
        allow(subject).to receive(:capture_idea_without_commit).and_return(failed_result)
        expect(subject).not_to receive(:execute_git_commit)
        
        subject.capture_idea("test idea")
      end
    end
  end

  describe "#execute_git_commit" do
    subject { described_class.new(commit_after_capture: true) }
    
    it "calls git-commit executable with correct file path" do
      expect(subject).to receive(:system).with(
        File.expand_path("../../../../exe/git-commit", __FILE__),
        "/path/to/idea.md",
        "--intention", "capture idea"
      ).and_return(true)
      
      subject.send(:execute_git_commit, "/path/to/idea.md")
    end

    it "raises error when git-commit fails" do
      allow(subject).to receive(:system).and_return(false)
      
      expect {
        subject.send(:execute_git_commit, "/path/to/idea.md")
      }.to raise_error(/git-commit failed/)
    end
  end

  describe "#test_environment?" do
    subject { described_class.new }
    
    it "returns true when CI environment variable is set" do
      allow(ENV).to receive(:[]).with('CI').and_return('true')
      expect(subject.send(:test_environment?)).to be true
    end

    it "returns true when TEST environment variable is set" do
      allow(ENV).to receive(:[]).with('TEST').and_return('1')
      expect(subject.send(:test_environment?)).to be true
    end

    it "returns false in normal environment" do
      allow(ENV).to receive(:[]).with('CI').and_return(nil)
      allow(ENV).to receive(:[]).with('TEST').and_return(nil)
      expect(subject.send(:test_environment?)).to be false
    end
  end
end
```

### Integration Tests (spec/integration/ideas_manager_commit_spec.rb)

```ruby
describe "ideas-manager with --commit flag", type: :integration do
  let(:temp_dir) { Dir.mktmpdir }
  let(:git_repo_dir) { File.join(temp_dir, "test_repo") }
  
  before do
    # Setup temporary git repository
    Dir.chdir(temp_dir) do
      system("git init #{git_repo_dir}")
      Dir.chdir(git_repo_dir) do
        system("git config user.email 'test@example.com'")
        system("git config user.name 'Test User'")
        File.write("README.md", "# Test Repo")
        system("git add README.md")
        system("git commit -m 'Initial commit'")
      end
    end
  end

  after { FileUtils.rm_rf(temp_dir) }

  context "in normal environment" do
    it "creates and commits idea file successfully" do
      Dir.chdir(git_repo_dir) do
        output = `#{ideas_manager_path} capture "test integration idea" --commit 2>&1`
        
        expect($?.exitstatus).to eq(0)
        expect(output).to include("Created:")
        expect(output).to include("Committed:")
        
        # Verify git commit was created
        git_log = `git log --oneline -1`
        expect(git_log).to include("capture idea")
      end
    end
  end

  context "in CI environment" do
    before { ENV['CI'] = 'true' }
    after { ENV.delete('CI') }
    
    it "creates idea file but skips commit" do
      Dir.chdir(git_repo_dir) do
        output = `#{ideas_manager_path} capture "test ci idea" --commit 2>&1`
        
        expect($?.exitstatus).to eq(0)
        expect(output).to include("Created:")
        expect(output).to include("Skipped commit (test environment)")
        
        # Verify no new git commit was created
        git_log = `git log --oneline -1`
        expect(git_log).to include("Initial commit")
      end
    end
  end

  private

  def ideas_manager_path
    File.expand_path("../../../exe/ideas-manager", __FILE__)
  end
end
```

## Acceptance Criteria

- [ ] AC 1: ideas-manager capture command accepts --commit flag without breaking existing functionality
- [ ] AC 2: When --commit flag is used, generated idea files are automatically committed using git-commit executable
- [ ] AC 3: Test environment detection prevents commits when CI, TEST, or other test environment markers are present
- [ ] AC 4: User receives clear feedback about both idea creation success and commit status (success/failure)
- [ ] AC 5: git-commit failures are handled gracefully - idea file creation succeeds even if commit fails
- [ ] AC 6: All existing ideas-manager functionality continues to work without the --commit flag
- [ ] AC 7: All embedded tests in Implementation Plan pass successfully
- [ ] AC 8: Comprehensive RSpec test suite covers all --commit flag scenarios:
  - CLI command flag parsing and parameter passing
  - Organism commit execution logic and error handling  
  - Environment detection for test scenarios (CI, TEST env vars)
  - Integration tests with real git repository operations
  - Edge cases: commit failures, missing git executable, permission issues
- [ ] AC 9: All RSpec tests pass with 100% coverage for new --commit functionality
- [ ] AC 10: No regression in existing test suite - all current tests continue to pass

## Out of Scope

- ❌ Custom commit message formatting for idea files (use git-commit default behavior)
- ❌ Integration with other ideas-manager flags beyond --commit (keep implementation minimal)
- ❌ Rollback or undo functionality for committed idea files
- ❌ Batch commit operations for multiple ideas
- ❌ Configuration file settings for commit behavior

## References

- Enhanced idea source: dev-taskflow/backlog/ideas/20250730-2327-auto-commit-ideas.md
- git-commit executable: dev-tools/exe/git-commit
- ideas-manager CLI: dev-tools/lib/coding_agent_tools/cli/commands/ideas/capture.rb
- IdeaCapture organism: dev-tools/lib/coding_agent_tools/organisms/idea_capture.rb
