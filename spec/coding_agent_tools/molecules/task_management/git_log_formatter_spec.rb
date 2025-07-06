# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/task_management/git_log_formatter"

RSpec.describe CodingAgentTools::Molecules::TaskManagement::GitLogFormatter do
  describe ".get_multi_repo_log" do
    it "responds to get_multi_repo_log" do
      expect(described_class).to respond_to(:get_multi_repo_log)
    end
  end

  describe ".format_log_output" do
    it "responds to format_log_output" do
      expect(described_class).to respond_to(:format_log_output)
    end
  end
end
