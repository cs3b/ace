# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Task Manager Integration" do
  include CliHelpers

  let(:executable_path) { File.expand_path("../../exe/task-manager", __dir__) }

  before do
    expect(File.exist?(executable_path)).to be(true), "task-manager executable should exist"
    expect(File.executable?(executable_path)).to be(true), "task-manager should be executable"
  end

  describe "basic functionality" do
    it "shows help when called with --help" do
      result = execute_cli_command("task-manager", ["--help"])
      expect(result.exitstatus).to eq(1) # dry-cli exits with 1 for help by design
      expect(result.stdout).to include("Commands:")
      expect(result.stdout).to include("task-manager next")
      expect(result.stdout).to include("task-manager recent")
      expect(result.stdout).to include("task-manager all")
      expect(result.stdout).to include("task-manager generate-id")
      expect(result.stdout).to include("task-manager version")
    end

    it "shows version information" do
      result = execute_cli_command("task-manager", ["version"])
      expect(result).to be_success
      expect(result.stdout.strip).to match(/Task Manager \d+\.\d+\.\d+/)
    end

    it "shows command-specific help" do
      result = execute_cli_command("task-manager", ["next", "--help"])
      expect(result).to be_success
      expect(result.stdout).to include("Find the next actionable task to work on")
      expect(result.stdout).to include("--limit=VALUE")
      expect(result.stdout).to include("--[no-]debug")
    end

    it "handles invalid commands gracefully" do
      result = execute_cli_command("task-manager", ["invalid-command"])
      # Invalid commands show help by default in dry-cli
      expect(result.stdout).to include("Commands:")
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
      result = execute_cli_command("task-manager", ["generate-id", "v.0.3.0", "--limit", "-1"])
      # The command might return 0 but still show the error message
      expect(result.stderr).to include("Limit must be a positive integer")
    end
  end
end
