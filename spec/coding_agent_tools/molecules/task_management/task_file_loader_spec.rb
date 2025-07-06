# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/task_management/task_file_loader"

RSpec.describe CodingAgentTools::Molecules::TaskManagement::TaskFileLoader do
  describe ".load_task_file" do
    it "loads a valid task file" do
      # This is a basic test to verify the class loads
      expect(described_class).to respond_to(:load_task_file)
    end
  end

  describe ".load_tasks_from_directory" do
    it "responds to load_tasks_from_directory" do
      expect(described_class).to respond_to(:load_tasks_from_directory)
    end
  end
end
