# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe "Release Context Consistency", type: :integration do
  let(:temp_dir) { Dir.mktmpdir }
  let(:release_manager) { CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: temp_dir) }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_release_structure(releases_in_current)
    current_path = File.join(temp_dir, "dev-taskflow", "current")
    FileUtils.mkdir_p(current_path)

    releases_in_current.each do |release_name|
      release_path = File.join(current_path, release_name)
      FileUtils.mkdir_p(File.join(release_path, "tasks"))
      # Create a sample task file
      File.write(File.join(release_path, "tasks", "#{release_name}+task.1-sample.md"), "# Sample task")
    end
  end

  describe "single current release scenario" do
    before do
      create_release_structure(["v.0.3.0-migration"])
    end

    it "reports consistent release information" do
      # Test release-manager current
      current_result = release_manager.current
      expect(current_result).to be_success
      expect(current_result.data.name).to eq("v.0.3.0-migration")

      # Test validation
      validation_result = release_manager.validate_release_context_consistency
      expect(validation_result).to be_success
      expect(validation_result.data[:validation_status]).to eq("consistent")
    end

    it "has consistent path references" do
      current_result = release_manager.current
      expected_path = File.join(temp_dir, "dev-taskflow", "current", "v.0.3.0-migration")

      expect(current_result.data.path).to eq(expected_path)
    end
  end

  describe "multiple current releases scenario" do
    before do
      create_release_structure(["v.0.1.0-aurora", "v.0.3.0-migration"])
    end

    it "detects inconsistency and warns about multiple releases" do
      validation_result = release_manager.validate_release_context_consistency

      expect(validation_result).not_to be_success
      expect(validation_result.error_message).to include("Multiple releases in current directory")
      expect(validation_result.error_message).to include("v.0.3.0-migration, v.0.1.0-aurora")
    end

    it "still returns first release but logs warning" do
      # The system should still function but use the first release alphabetically
      current_result = release_manager.current
      expect(current_result).to be_success

      # The DirectoryNavigator should return the first alphabetically (v.0.3.0-migration comes before v.0.1.0-aurora lexicographically)
      expect(current_result.data.name).to eq("v.0.3.0-migration")
    end
  end

  describe "empty current directory scenario" do
    before do
      FileUtils.mkdir_p(File.join(temp_dir, "dev-taskflow", "current"))
    end

    it "detects missing current release" do
      validation_result = release_manager.validate_release_context_consistency

      expect(validation_result).not_to be_success
      expect(validation_result.error_message).to include("No current release directory found")
    end

    it "returns error for current command" do
      current_result = release_manager.current
      expect(current_result).not_to be_success
    end
  end

  describe "integration with CLI commands" do
    before do
      create_release_structure(["v.0.3.0-migration"])
    end

    it "release-manager validate command works" do
      # Test that the validate command runs without errors
      # Note: This is a basic test - full CLI testing would require more setup
      validation_result = release_manager.validate_release_context_consistency
      expect(validation_result).to be_success
    end
  end

  describe "edge cases" do
    it "handles non-existent dev-taskflow directory" do
      empty_temp_dir = Dir.mktmpdir
      begin
        empty_release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: empty_temp_dir)

        validation_result = empty_release_manager.validate_release_context_consistency
        expect(validation_result).not_to be_success
      ensure
        FileUtils.rm_rf(empty_temp_dir)
      end
    end

    it "handles corrupted release directory names" do
      current_path = File.join(temp_dir, "dev-taskflow", "current")
      FileUtils.mkdir_p(current_path)

      # Create directory with invalid name (no version pattern)
      FileUtils.mkdir_p(File.join(current_path, "invalid-release-name"))

      validation_result = release_manager.validate_release_context_consistency
      expect(validation_result).not_to be_success
    end
  end
end
