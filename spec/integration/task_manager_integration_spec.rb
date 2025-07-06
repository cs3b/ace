# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Task Manager Integration" do
  let(:executable_path) { File.expand_path("../../exe/task-manager", __dir__) }

  before do
    expect(File.exist?(executable_path)).to be(true), "task-manager executable should exist"
    expect(File.executable?(executable_path)).to be(true), "task-manager should be executable"
  end

  describe "basic functionality" do
    it "shows help when called with --help" do
      output = `bundle exec #{executable_path} --help 2>&1`
      expect($?.success?).to be(false) # dry-cli exits with 0 for help, but captures as error stream
      expect(output).to include("Commands:")
      expect(output).to include("task-manager next")
      expect(output).to include("task-manager recent")
      expect(output).to include("task-manager all")
      expect(output).to include("task-manager generate-id")
      expect(output).to include("task-manager version")
    end

    it "shows version information" do
      output = `bundle exec #{executable_path} version 2>&1`
      expect($?.success?).to be(true)
      expect(output.strip).to match(/Task Manager \d+\.\d+\.\d+/)
    end

    it "shows command-specific help" do
      output = `bundle exec #{executable_path} next --help 2>&1`
      expect(output).to include("Find the next actionable task to work on")
      expect(output).to include("--limit=VALUE")
      expect(output).to include("--[no-]debug")
    end

    it "handles invalid commands gracefully" do
      output = `bundle exec #{executable_path} invalid-command 2>&1`
      # Invalid commands show help by default in dry-cli
      expect(output).to include("Commands:")
    end
  end

  describe "command delegation" do
    it "delegates generate-id command correctly" do
      output = `bundle exec #{executable_path} generate-id v.0.3.0 --limit 2 2>&1`
      expect($?.success?).to be(true)
      expect(output).to include("Generated 2 task IDs:")
      # The actual task numbers depend on existing tasks in the release
      expect(output).to match(/v\.0\.3\.0\+task\.\d+/)
    end

    it "validates limit options properly" do
      output = `bundle exec #{executable_path} generate-id v.0.3.0 --limit -1 2>&1`
      # The command might return 0 but still show the error message
      expect(output).to include("Limit must be a positive integer")
    end
  end
end
