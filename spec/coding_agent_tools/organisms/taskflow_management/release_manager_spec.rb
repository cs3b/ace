# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/taskflow_management/release_manager"

RSpec.describe CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager do
  let(:base_path) { "/tmp/test_release_manager" }
  let(:manager) { described_class.new(base_path: base_path) }

  before do
    # Create test directory structure
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/current")
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/done")
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog")
  end

  after do
    # Clean up test directories
    FileUtils.rm_rf(base_path) if File.exist?(base_path)
  end

  describe "#current" do
    context "when current release exists" do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks")
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks/task1.md", "# Task 1")
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks/task2.md", "# Task 2")
      end

      it "returns current release information" do
        result = manager.current

        expect(result.success?).to be true
        expect(result.data).to be_a(described_class::ReleaseInfo)
        expect(result.data.type).to eq(:current)
        expect(result.data.current?).to be true
      end
    end

    context "when no current release exists" do
      it "returns an error" do
        result = manager.current

        expect(result.success?).to be false
        expect(result.error_message).to include("No current release directory found")
      end
    end
  end

  describe "#next" do
    context "when backlog has versioned releases" do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/v.0.4.0-future")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/v.0.5.0-later")
      end

      it "returns the lowest version release" do
        result = manager.next

        expect(result.success?).to be true
        expect(result.data).to be_a(described_class::ReleaseInfo)
        expect(result.data.version).to eq("v.0.4.0")
        expect(result.data.type).to eq(:backlog)
      end
    end

    context "when backlog has no versioned releases" do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/ideas")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/future-considerations")
      end

      it "returns success with no releases message" do
        result = manager.next

        expect(result.success?).to be true
        expect(result.error_message).to include("No versioned releases found in backlog")
      end
    end

    context "when backlog directory doesn't exist" do
      before do
        FileUtils.rm_rf("#{base_path}/dev-taskflow/backlog")
      end

      it "returns an error" do
        result = manager.next

        expect(result.success?).to be false
        expect(result.error_message).to include("Backlog directory not found")
      end
    end
  end

  describe "#generate_id" do
    context "when releases exist" do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-foundation")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.2.0-synapse")
      end

      it "generates next task ID with minor version bump" do
        result = manager.generate_id

        expect(result.success?).to be true
        expect(result.data).to eq("v.0.4.0+task.1")
      end
    end

    context "when no releases exist" do
      it "generates first task ID" do
        result = manager.generate_id

        expect(result.success?).to be true
        expect(result.data).to eq("v.0.1.0+task.1")
      end
    end
  end

  describe "#all" do
    context "when multiple releases exist across directories" do
      before do
        # Create done releases
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-foundation/tasks")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.2.0-synapse/tasks")
        File.write("#{base_path}/dev-taskflow/done/v.0.1.0-foundation/tasks/task1.md", "# Task 1")
        File.write("#{base_path}/dev-taskflow/done/v.0.2.0-synapse/tasks/task1.md", "# Task 1")
        File.write("#{base_path}/dev-taskflow/done/v.0.2.0-synapse/tasks/task2.md", "# Task 2")

        # Create current release
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks")
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks/task1.md", "# Task 1")

        # Create backlog release
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/v.0.4.0-future/tasks")
      end

      it "returns all releases sorted by version" do
        result = manager.all

        expect(result.success?).to be true
        expect(result.data).to be_an(Array)
        expect(result.data.length).to eq(4)

        # Check sorting by version
        versions = result.data.map(&:version)
        expect(versions).to eq(["v.0.1.0", "v.0.2.0", "v.0.3.0", "v.0.4.0"])

        # Check types
        types = result.data.map(&:type)
        expect(types).to contain_exactly(:done, :done, :current, :backlog)

        # Check task counts
        foundation_release = result.data.find { |r| r.name.include?("foundation") }
        synapse_release = result.data.find { |r| r.name.include?("synapse") }
        migration_release = result.data.find { |r| r.name.include?("migration") }

        expect(foundation_release.task_count).to eq(1)
        expect(synapse_release.task_count).to eq(2)
        expect(migration_release.task_count).to eq(1)
      end

      it "includes metadata for each release" do
        result = manager.all

        expect(result.success?).to be true

        result.data.each do |release|
          expect(release.path).to be_a(String)
          expect(release.version).to be_a(String)
          expect(release.name).to be_a(String)
          expect(release.type).to be_a(Symbol)
          expect(release.status).to be_a(String)
          expect(release.task_count).to be_a(Integer)
          expect(release.created_at).to be_a(Time) if release.created_at
          expect(release.modified_at).to be_a(Time) if release.modified_at
        end
      end
    end

    context "when no releases exist" do
      it "returns empty array" do
        result = manager.all

        expect(result.success?).to be true
        expect(result.data).to eq([])
      end
    end
  end

  describe "ReleaseInfo" do
    let(:release_info) do
      described_class::ReleaseInfo.new(
        "/path/to/release",
        "v.0.3.0",
        "v.0.3.0-migration",
        :current,
        "active",
        5,
        Time.now,
        Time.now
      )
    end

    describe "#current?" do
      it "returns true for current releases" do
        expect(release_info.current?).to be true
      end

      it "returns false for non-current releases" do
        release_info.type = :done
        expect(release_info.current?).to be false
      end
    end

    describe "#completed?" do
      it "returns true for done releases" do
        release_info.type = :done
        expect(release_info.completed?).to be true
      end

      it "returns false for non-done releases" do
        expect(release_info.completed?).to be false
      end
    end

    describe "#backlog?" do
      it "returns true for backlog releases" do
        release_info.type = :backlog
        expect(release_info.backlog?).to be true
      end

      it "returns false for non-backlog releases" do
        expect(release_info.backlog?).to be false
      end
    end
  end

  describe "ManagerResult" do
    describe "#success?" do
      it "returns true when success is true" do
        result = described_class::ManagerResult.new("data", true, nil)
        expect(result.success?).to be true
      end

      it "returns false when success is false" do
        result = described_class::ManagerResult.new(nil, false, "error")
        expect(result.success?).to be false
      end
    end

    describe "#failed?" do
      it "returns false when success is true" do
        result = described_class::ManagerResult.new("data", true, nil)
        expect(result.failed?).to be false
      end

      it "returns true when success is false" do
        result = described_class::ManagerResult.new(nil, false, "error")
        expect(result.failed?).to be true
      end
    end
  end

  describe "version parsing and sorting" do
    before do
      FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-foundation")
      FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.10.0-major")
      FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.2.0-synapse")
      FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")
    end

    it "sorts versions correctly using semantic versioning" do
      result = manager.all

      expect(result.success?).to be true
      versions = result.data.map(&:version)
      expect(versions).to eq(["v.0.1.0", "v.0.2.0", "v.0.3.0", "v.0.10.0"])
    end
  end
end
