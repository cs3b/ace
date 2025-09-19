# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/taskflow_management/git_log_formatter"
require "coding_agent_tools/atoms/taskflow_management/shell_command_executor"

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::GitLogFormatter do
  let(:repo_config) { {path: "/path/to/repo", label: "test-repo"} }
  let(:since_time) { "2023-01-01" }
  let(:sample_git_output) do
    "1672531200|abc123|John Doe|Initial commit\n\nAdded basic functionality<<END>>" \
    "1672617600|def456|Jane Smith|Fix bug in formatter\n\nResolve issue with timestamp formatting<<END>>"
  end
  let(:successful_command_result) do
    CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor::CommandResult.new(
      true, sample_git_output, "", 0, 0.5
    )
  end
  let(:failed_command_result) do
    CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor::CommandResult.new(
      false, "", "fatal: not a git repository", 128, 0.1
    )
  end

  describe "LogEntry struct" do
    let(:log_entry) do
      described_class::LogEntry.new(
        "test-repo", 1_672_531_200, "abc123def", "John Doe",
        "Initial commit\n\nAdded basic functionality", "1672531200"
      )
    end

    describe "#formatted_timestamp" do
      it "formats timestamp with default format" do
        expected = Time.at(1_672_531_200).strftime("%Y-%m-%d %H:%M")
        expect(log_entry.formatted_timestamp).to eq(expected)
      end

      it "formats timestamp with custom format" do
        expect(log_entry.formatted_timestamp(format: "%Y-%m-%d")).to eq("2023-01-01")
      end

      it "returns raw timestamp when formatting fails" do
        log_entry = described_class::LogEntry.new("repo", nil, "sha", "author", "msg", "1672531200")
        expect(log_entry.formatted_timestamp).to eq("1672531200")
      end

      it "returns 'unknown' when both timestamp and raw_timestamp are nil" do
        log_entry = described_class::LogEntry.new("repo", nil, "sha", "author", "msg", nil)
        expect(log_entry.formatted_timestamp).to eq("unknown")
      end
    end

    describe "#short_sha" do
      it "returns short SHA with default length" do
        expect(log_entry.short_sha).to eq("abc123d")
      end

      it "returns short SHA with custom length" do
        expect(log_entry.short_sha(length: 5)).to eq("abc12")
      end

      it "returns full SHA when requested length exceeds SHA length" do
        short_sha_entry = described_class::LogEntry.new("repo", 123, "abc", "author", "msg", "123")
        expect(short_sha_entry.short_sha(length: 10)).to eq("abc")
      end

      it "returns 'unknown' for nil SHA" do
        log_entry = described_class::LogEntry.new("repo", 123, nil, "author", "msg", "123")
        expect(log_entry.short_sha).to eq("unknown")
      end

      it "returns 'unknown' for empty SHA" do
        log_entry = described_class::LogEntry.new("repo", 123, "", "author", "msg", "123")
        expect(log_entry.short_sha).to eq("unknown")
      end
    end

    describe "#single_line_message" do
      it "returns first line of multiline message" do
        expect(log_entry.single_line_message).to eq("Initial commit")
      end

      it "returns empty string for nil message" do
        log_entry = described_class::LogEntry.new("repo", 123, "sha", "author", nil, "123")
        expect(log_entry.single_line_message).to eq("")
      end

      it "returns empty string for empty message" do
        log_entry = described_class::LogEntry.new("repo", 123, "sha", "author", "", "123")
        expect(log_entry.single_line_message).to eq("")
      end

      it "strips whitespace from single line" do
        log_entry = described_class::LogEntry.new("repo", 123, "sha", "author", "  Spaced message  ", "123")
        expect(log_entry.single_line_message).to eq("Spaced message")
      end
    end
  end

  describe "LogResult struct" do
    let(:entries) do
      [
        described_class::LogEntry.new("repo1", 1_672_531_200, "abc", "John", "msg1", "1672531200"),
        described_class::LogEntry.new("repo2", 1_672_617_600, "def", "Jane", "msg2", "1672617600")
      ]
    end
    let(:repositories) { [{path: "/repo1", label: "repo1"}, {path: "/repo2", label: "repo2"}] }
    let(:log_result) { described_class::LogResult.new(entries, repositories, since_time, 2, []) }

    describe "#success?" do
      it "returns true when entries exist and no errors" do
        expect(log_result.success?).to be true
      end

      it "returns false when entries are nil" do
        result = described_class::LogResult.new(nil, repositories, since_time, 0, [])
        expect(result.success?).to be false
      end

      it "returns false when errors exist" do
        result = described_class::LogResult.new(entries, repositories, since_time, 2, ["error"])
        expect(result.success?).to be false
      end
    end

    describe "#empty?" do
      it "returns false when entries exist" do
        expect(log_result.empty?).to be false
      end

      it "returns true when entries are nil" do
        result = described_class::LogResult.new(nil, repositories, since_time, 0, [])
        expect(result.empty?).to be true
      end

      it "returns true when entries are empty array" do
        result = described_class::LogResult.new([], repositories, since_time, 0, [])
        expect(result.empty?).to be true
      end
    end
  end

  describe ".get_multi_repo_log" do
    let(:repositories) { [repo_config] }

    before do
      allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
        .to receive(:execute).and_return(successful_command_result)
    end

    it "returns LogResult with parsed entries" do
      result = described_class.get_multi_repo_log(repositories, since_time: since_time)

      expect(result).to be_a(described_class::LogResult)
      expect(result.entries.length).to eq(2)
      expect(result.success?).to be true
      expect(result.errors).to be_empty
    end

    it "sorts entries by timestamp descending" do
      result = described_class.get_multi_repo_log(repositories, since_time: since_time)

      timestamps = result.entries.map(&:timestamp)
      expect(timestamps).to eq(timestamps.sort.reverse)
    end

    it "handles repository errors gracefully" do
      allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
        .to receive(:execute).and_return(failed_command_result)

      result = described_class.get_multi_repo_log(repositories, since_time: since_time)

      expect(result.entries).to be_empty
      expect(result.errors).not_to be_empty
      expect(result.errors.first).to include("Error getting log for test-repo")
    end

    it "handles mixed success and failure repositories" do
      repos = [
        {path: "/success", label: "success-repo"},
        {path: "/failure", label: "failure-repo"}
      ]

      allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
        .to receive(:execute).with(anything, working_directory: "/success", timeout: 30)
        .and_return(successful_command_result)
      allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
        .to receive(:execute).with(anything, working_directory: "/failure", timeout: 30)
        .and_return(failed_command_result)

      result = described_class.get_multi_repo_log(repos, since_time: since_time)

      expect(result.entries.length).to eq(2)
      expect(result.errors.length).to eq(1)
    end

    it "passes correct parameters to git command" do
      expect(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
        .to receive(:execute)
        .with(
          "git log --since=2023-01-01 --no-merges --max-count=100 --pretty=format:%ct|%h|%an|%B<<END>>",
          working_directory: "/path/to/repo",
          timeout: 30
        )
        .and_return(successful_command_result)

      described_class.get_multi_repo_log(repositories, since_time: since_time)
    end

    it "includes merge commits when include_merges is true" do
      expect(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
        .to receive(:execute)
        .with(
          "git log --since=2023-01-01 --max-count=100 --pretty=format:%ct|%h|%an|%B<<END>>",
          working_directory: "/path/to/repo",
          timeout: 30
        )
        .and_return(successful_command_result)

      described_class.get_multi_repo_log(repositories, since_time: since_time, include_merges: true)
    end

    it "respects max_commits parameter" do
      expect(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
        .to receive(:execute)
        .with(
          "git log --since=2023-01-01 --no-merges --max-count=50 --pretty=format:%ct|%h|%an|%B<<END>>",
          working_directory: "/path/to/repo",
          timeout: 30
        )
        .and_return(successful_command_result)

      described_class.get_multi_repo_log(repositories, since_time: since_time, max_commits: 50)
    end

    it "handles Time objects for since_time" do
      time_obj = Time.at(1_672_531_200)
      expected_time_str = time_obj.strftime("%Y-%m-%dT%H:%M:%S")

      expect(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
        .to receive(:execute)
        .with(
          "git log --since=#{expected_time_str} --no-merges --max-count=100 --pretty=format:%ct|%h|%an|%B<<END>>",
          working_directory: "/path/to/repo",
          timeout: 30
        )
        .and_return(successful_command_result)

      described_class.get_multi_repo_log(repositories, since_time: time_obj)
    end

    it "raises error for invalid time format" do
      expect do
        described_class.get_multi_repo_log(repositories, since_time: 12_345)
      end.to raise_error(ArgumentError, "Invalid time format: Integer")
    end
  end

  describe ".format_log_output" do
    let(:entries) do
      [
        described_class::LogEntry.new("repo1", 1_672_531_200, "abc123", "John Doe", "Initial commit\n\nAdded functionality", "1672531200"),
        described_class::LogEntry.new("repo2", 1_672_617_600, "def456", "Jane Smith", "Fix bug", "1672617600")
      ]
    end
    let(:log_result) { described_class::LogResult.new(entries, [], since_time, 2, []) }
    let(:empty_result) { described_class::LogResult.new([], [], since_time, 0, []) }

    it "returns message for empty results" do
      output = described_class.format_log_output(empty_result)
      expect(output).to eq("No commits found.")
    end

    context "compact format" do
      it "formats entries in compact format with repository names" do
        output = described_class.format_log_output(log_result, format: :compact)

        expect(output).to include("[repo1]")
        expect(output).to include("abc123")  # short_sha method with default 7 chars for "abc123" returns "abc123"
        expect(output).to include("John Doe")
        expect(output).to include("Initial commit")
        expect(output).to include("---")
      end

      it "formats entries without repository names when show_repository is false" do
        output = described_class.format_log_output(log_result, format: :compact, show_repository: false)

        expect(output).not_to include("[repo1]")
        expect(output).to include("abc123")  # short_sha method with default 7 chars for "abc123" returns "abc123"
        expect(output).to include("John Doe")
      end
    end

    context "detailed format" do
      it "formats entries in detailed format with full message" do
        output = described_class.format_log_output(log_result, format: :detailed)

        expect(output).to include("[repo1]")
        expect(output).to include("abc123")  # Full SHA in detailed
        expect(output).to include("John Doe")
        expect(output).to include("    Initial commit")
        expect(output).to include("    Added functionality")
        expect(output).to include("=" * 70)
      end
    end

    context "oneline format" do
      it "formats entries in oneline format" do
        output = described_class.format_log_output(log_result, format: :oneline)

        expect(output).to include("[repo1] abc123 Initial commit")  # short_sha for "abc123" returns "abc123"
        expect(output).to include("[repo2] def456 Fix bug")
      end
    end

    it "raises error for unknown format" do
      expect do
        described_class.format_log_output(log_result, format: :invalid)
      end.to raise_error(ArgumentError, "Unknown format: invalid")
    end
  end

  describe "private methods integration" do
    describe "git log parsing" do
      it "handles empty git output" do
        empty_result = CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor::CommandResult.new(
          true, "", "", 0, 0.1
        )

        allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
          .to receive(:execute).and_return(empty_result)

        result = described_class.get_multi_repo_log([repo_config], since_time: since_time)
        expect(result.entries).to be_empty
      end

      it "handles malformed git output gracefully" do
        malformed_output = "invalid|format<<END>>missing_parts<<END>>"
        malformed_result = CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor::CommandResult.new(
          true, malformed_output, "", 0, 0.1
        )

        allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
          .to receive(:execute).and_return(malformed_result)

        result = described_class.get_multi_repo_log([repo_config], since_time: since_time)
        expect(result.entries).to be_empty
      end

      it "handles git output with special characters" do
        # Note: Due to split("|", 3), the author field gets "User Name|message"
        special_output = "1672531200|abc123|User Name with special chars: äöü & <script>\nSecond line<<END>>"
        special_result = CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor::CommandResult.new(
          true, special_output, "", 0, 0.1
        )

        allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
          .to receive(:execute).and_return(special_result)

        result = described_class.get_multi_repo_log([repo_config], since_time: since_time)
        expect(result.entries.length).to eq(1)
        # The author field contains everything after the second |
        expect(result.entries.first.author).to include("äöü & <script>")
        expect(result.entries.first.message).to eq("Second line")
      end
    end

    describe "repository label handling" do
      it "uses basename when label is not provided" do
        repo_without_label = {path: "/path/to/my-project"}

        allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
          .to receive(:execute).and_return(successful_command_result)

        result = described_class.get_multi_repo_log([repo_without_label], since_time: since_time)
        expect(result.entries.first.repository).to eq("my-project")
      end
    end
  end
end
