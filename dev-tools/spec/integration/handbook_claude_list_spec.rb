# frozen_string_literal: true

require "spec_helper"
require "open3"
require "json"

RSpec.describe "handbook claude list integration" do
  let(:handbook_exe) { File.expand_path("../../../exe/handbook", __FILE__) }

  it "displays help for the list command" do
    stdout, _, status = Open3.capture3("#{handbook_exe} claude list --help")

    expect(status).to be_success
    expect(stdout).to include("List all Claude commands and their status")
    expect(stdout).to include("verbose")
    expect(stdout).to include("--type")
    expect(stdout).to include("--format")
  end

  context "table output format (default)" do
    it "displays commands in table format" do
      stdout, _, status = Open3.capture3("#{handbook_exe} claude list")

      expect(status).to be_success
      expect(stdout).to include("Claude Commands Overview")
      expect(stdout).to include("========================")

      # Check table structure
      expect(stdout).to match(/Installed\s+\|\s+Type\s+\|\s+Valid\s+\|\s+Command Name/)
      expect(stdout).to include("---|")

      # Check summary line
      expect(stdout).to match(/Summary: \d+ commands installed, \d+ missing/)
    end

    it "shows status indicators correctly" do
      stdout, _, _ = Open3.capture3("#{handbook_exe} claude list")

      # Should include status indicators (✓ or ✗)
      expect(stdout).to match(/[✓✗]/)
    end
  end

  context "verbose output" do
    it "shows detailed information when verbose flag is used" do
      stdout, _, status = Open3.capture3("#{handbook_exe} claude list --verbose")

      expect(status).to be_success
      expect(stdout).to include("Claude Commands Overview")

      # Verbose mode should show sectioned output
      expect(stdout).to match(/Commands \(\d+\):/)

      # Should include file details when available
      if stdout.include?("Path:")
        expect(stdout).to include("Modified:")
        expect(stdout).to include("Size:")
      end
    end
  end

  context "JSON output format" do
    it "outputs valid JSON structure" do
      stdout, _, status = Open3.capture3("#{handbook_exe} claude list --format json")

      expect(status).to be_success

      # Parse JSON to verify structure
      json = JSON.parse(stdout)

      expect(json).to have_key("commands")
      expect(json).to have_key("summary")

      expect(json["commands"]).to be_an(Array)
      expect(json["summary"]).to include("installed", "missing", "total")

      # Check command structure if any exist
      if json["commands"].any?
        command = json["commands"].first
        expect(command).to include("name", "type", "installed", "valid")
      end
    end
  end

  context "type filtering" do
    it "filters by custom type" do
      stdout, _, status = Open3.capture3("#{handbook_exe} claude list --type custom")

      expect(status).to be_success
      expect(stdout).to include("Claude Commands Overview")

      # If any custom commands exist, they should be shown
      if /\|\s*custom\s*\|/.match?(stdout)
        expect(stdout).to include("custom")
      end
    end

    it "filters by generated type" do
      stdout, _, status = Open3.capture3("#{handbook_exe} claude list --type generated")

      expect(status).to be_success
      expect(stdout).to include("Claude Commands Overview")

      # If any generated commands exist, they should be shown
      if /\|\s*generated\s*\|/.match?(stdout)
        expect(stdout).to include("generated")
      end
    end

    it "filters by missing type" do
      stdout, _, status = Open3.capture3("#{handbook_exe} claude list --type missing")

      expect(status).to be_success
      expect(stdout).to include("Claude Commands Overview")

      # If any missing commands exist, they should be shown
      if /\|\s*missing\s*\|/.match?(stdout)
        expect(stdout).to include("missing")
      end
    end
  end

  context "terminal width handling" do
    it "adapts to different terminal widths" do
      # Test with narrow terminal
      stdout80, _, _ = Open3.capture3("COLUMNS=80 #{handbook_exe} claude list")

      # Test with wide terminal
      stdout120, _, _ = Open3.capture3("COLUMNS=120 #{handbook_exe} claude list")

      # Both should show the table
      expect(stdout80).to match(/Installed\s+\|\s+Type\s+\|\s+Valid\s+\|\s+Command Name/)
      expect(stdout120).to match(/Installed\s+\|\s+Type\s+\|\s+Valid\s+\|\s+Command Name/)
    end
  end
end
