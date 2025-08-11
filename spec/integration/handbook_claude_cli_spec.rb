# frozen_string_literal: true

require "spec_helper"
require "open3"

RSpec.describe "handbook claude commands" do
  let(:exe_path) { File.expand_path("../../exe/handbook", __dir__) }

  describe "handbook --help" do
    it "displays help including claude commands" do
      output, status = Open3.capture2e("bundle", "exec", exe_path, "--help")

      # dry-cli exits with 1 when showing help for the root command
      expect(status.exitstatus).to eq(1)
      expect(output).to include("claude")
      expect(output).to include("sync-templates")
    end
  end

  describe "handbook claude --help" do
    it "displays help for claude namespace" do
      output, status = Open3.capture2e("bundle", "exec", exe_path, "claude", "--help")

      expect(status.exitstatus).to eq(1)
      expect(output).to include("generate-commands")
      # update-registry command has been removed
      expect(output).to include("integrate")
      expect(output).to include("validate")
      expect(output).to include("list")
    end
  end

  describe "handbook claude integrate --help" do
    it "displays help for integrate subcommand" do
      output, status = Open3.capture2e("bundle", "exec", exe_path, "claude", "integrate", "--help")

      expect(status).to be_success
      expect(output).to include("Install Claude Code commands")
      expect(output).to include("dry-run")
      expect(output).to include("verbose")
    end
  end

  describe "handbook claude generate-commands" do
    it "runs the generate-commands subcommand" do
      output, status = Open3.capture2e("bundle", "exec", exe_path, "claude", "generate-commands", "--dry-run")

      expect(status).to be_success
      expect(output).to include("Scanning workflow instructions")
    end
  end

  # update-registry command has been removed
  # describe "handbook claude update-registry" do
  #   ...
  # end

  describe "handbook claude validate" do
    it "runs validation and displays coverage information" do
      output, _ = Open3.capture2e("bundle", "exec", exe_path, "claude", "validate")

      # Validate command may return non-zero exit code if there are issues
      # This is expected behavior
      expect(output).to include("Validating Claude command coverage")
      expect(output).to match(/Workflows found: \d+/)
      expect(output).to match(/Commands found: \d+/)
    end
  end

  describe "handbook claude list" do
    it "displays command overview" do
      output, status = Open3.capture2e("bundle", "exec", exe_path, "claude", "list")

      expect(status).to be_success
      expect(output).to include("Claude Commands Overview")
      expect(output).to include("========================")
    end
  end

  describe "handbook invalid-command" do
    it "shows error for invalid command" do
      _, status = Open3.capture2e("bundle", "exec", exe_path, "invalid-command")

      # dry-cli returns non-zero status for invalid commands
      expect(status).not_to be_success
    end
  end
end
