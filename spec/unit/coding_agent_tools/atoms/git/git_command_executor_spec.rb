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
  end
end