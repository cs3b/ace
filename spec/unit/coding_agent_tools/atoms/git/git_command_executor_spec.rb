# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/git/git_command_executor"

RSpec.describe CodingAgentTools::Atoms::Git::GitCommandExecutor do
  describe ".execute" do
    it "can be instantiated" do
      expect { described_class.new }.not_to raise_error
    end
  end

  describe "#execute" do
    subject { described_class.new }

    it "raises GitCommandError for invalid commands" do
      expect {
        subject.execute("invalid-git-command")
      }.to raise_error(CodingAgentTools::Atoms::Git::GitCommandError)
    end

    it "can execute basic git commands" do
      # This test assumes we're in a git repository
      expect {
        result = subject.execute("status")
        expect(result).to be_a(Hash)
        expect(result[:success]).to be true
      }.not_to raise_error
    end

    it "formats error messages properly without shell escaping" do
      # Test that error messages display readable commands without shell escaping
      escaped_command = "commit -m refactor\\(git\\):\\ use\\ direct\\ Ruby\\ calls"

      allow(Open3).to receive(:capture3).with("git #{escaped_command}").and_return([
        "", "error output", double(success?: false, exitstatus: 1)
      ])

      expect {
        subject.execute(escaped_command)
      }.to raise_error(CodingAgentTools::Atoms::Git::GitCommandError) do |error|
        # Error message should show unescaped, readable command
        expect(error.message).to include("commit -m refactor(git): use direct Ruby calls")
        expect(error.message).not_to include("refactor\\(git\\):\\ use\\ direct\\ Ruby\\ calls")
      end
    end
  end

  describe "#format_command_for_display" do
    subject { described_class.new }

    it "unescapes shell-escaped sequences" do
      escaped_command = "git commit -m refactor\\(git\\):\\ use\\ direct\\ Ruby\\ calls"
      formatted = subject.send(:format_command_for_display, escaped_command)

      expect(formatted).to eq("git commit -m refactor(git): use direct Ruby calls")
    end

    it "normalizes whitespace" do
      command_with_extra_spaces = "git  commit   -m  'message'"
      formatted = subject.send(:format_command_for_display, command_with_extra_spaces)

      expect(formatted).to eq("git commit -m 'message'")
    end

    it "handles various escaped characters" do
      escaped_command = "git commit -m fix\\:\\ update\\ \\(version\\)\\ and\\ \\\"quotes\\\""
      formatted = subject.send(:format_command_for_display, escaped_command)

      expect(formatted).to eq('git commit -m fix: update (version) and "quotes"')
    end
  end
end
