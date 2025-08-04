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
      expect(output).to include("update-registry")
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

  describe "handbook claude update-registry" do
    it "displays not implemented message" do
      output, status = Open3.capture2e("bundle", "exec", exe_path, "claude", "update-registry")
      
      expect(status).to be_success
      expect(output).to include("update-registry: Not yet implemented")
      expect(output).to include("commands.json")
    end
  end

  describe "handbook claude validate" do
    it "displays not implemented message" do
      output, status = Open3.capture2e("bundle", "exec", exe_path, "claude", "validate")
      
      expect(status).to be_success
      expect(output).to include("validate: Not yet implemented")
      expect(output).to include("consistency and coverage")
    end
  end

  describe "handbook claude list" do
    it "displays not implemented message" do
      output, status = Open3.capture2e("bundle", "exec", exe_path, "claude", "list")
      
      expect(status).to be_success
      expect(output).to include("list: Not yet implemented")
      expect(output).to include("available Claude commands")
    end
  end

  describe "handbook invalid-command" do
    it "shows error for invalid command" do
      output, status = Open3.capture2e("bundle", "exec", exe_path, "invalid-command")
      
      # dry-cli returns non-zero status for invalid commands
      expect(status).not_to be_success
    end
  end
end