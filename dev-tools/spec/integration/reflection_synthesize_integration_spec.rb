# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"
require "stringio"

RSpec.describe "reflection-synthesize integration", type: :integration do
  describe "reflection-synthesize basic functionality" do
    it "can load without errors" do
      # Test that the tool can at least be loaded
      # Suppress output during loading to prevent test leaks
      # The executable will call the CLI which will exit, so we expect SystemExit
      original_stdout = $stdout
      original_stderr = $stderr
      begin
        $stdout = StringIO.new
        $stderr = StringIO.new
        expect do
          load File.expand_path("../../exe/reflection-synthesize", __dir__)
        end.to raise_error(SystemExit)
      ensure
        $stdout = original_stdout
        $stderr = original_stderr
      end
    end
  end

  describe "component integration" do
    let(:temp_dir) { Dir.mktmpdir("reflection_integration") }
    let(:reflection_path) { File.join(temp_dir, "test-reflection.md") }

    let(:test_reflection) do
      <<~MARKDOWN
        # Test Reflection

        **Date**: 2024-01-15

        ## What Went Well
        - Test completed successfully

        ## Key Learnings
        - Integration tests are valuable
      MARKDOWN
    end

    before do
      File.write(reflection_path, test_reflection)
    end

    after do
      safe_directory_cleanup(temp_dir)
    end

    it "loads reflection files through ReportCollector" do
      # This tests the actual component integration
      require "coding_agent_tools/molecules/reflection/report_collector"

      collector = CodingAgentTools::Molecules::Reflection::ReportCollector.new
      result = collector.collect_reports([reflection_path])

      expect(result).to be_success
      expect(result.reports).to include(reflection_path)
    end

    it "infers timestamps through TimestampInferrer" do
      require "coding_agent_tools/molecules/reflection/timestamp_inferrer"

      inferrer = CodingAgentTools::Molecules::Reflection::TimestampInferrer.new
      result = inferrer.infer_timestamp_range([reflection_path])

      expect(result).to be_success
      expect(result.from_date).to be_a(Date)
      expect(result.to_date).to be_a(Date)
    end

    it "can instantiate SynthesisOrchestrator" do
      require "coding_agent_tools/molecules/reflection/synthesis_orchestrator"

      # Just verify it can be instantiated without errors
      expect do
        CodingAgentTools::Molecules::Reflection::SynthesisOrchestrator.new
      end.not_to raise_error
    end
  end

  describe "Models::Result integration" do
    it "can create successful results" do
      require "coding_agent_tools/models/result"

      result = CodingAgentTools::Models::Result.success(test: "data")
      expect(result).to be_success
      expect(result.valid?).to be true
      expect(result.test).to eq("data")
    end

    it "can create failure results" do
      require "coding_agent_tools/models/result"

      result = CodingAgentTools::Models::Result.failure("test error")
      expect(result).to be_failure
      expect(result.success?).to be false
      expect(result.error).to eq("test error")
    end

    it "supports method_missing for data access" do
      require "coding_agent_tools/models/result"

      result = CodingAgentTools::Models::Result.success(
        reports: ["file1.md", "file2.md"],
        metrics: {count: 2}
      )

      expect(result.reports).to eq(["file1.md", "file2.md"])
      expect(result.metrics).to eq({count: 2})
    end
  end

  describe "reflection-synthesize with release paths" do
    let(:temp_dir) { Dir.mktmpdir("reflection_path_integration") }
    let(:release_name) { "v.0.3.0-workflows" }
    let(:reflections_dir) { File.join(temp_dir, "dev-taskflow", "current", release_name, "reflections") }
    let(:synthesis_dir) { File.join(reflections_dir, "synthesis") }

    before do
      # Create release structure
      FileUtils.mkdir_p(reflections_dir)
      FileUtils.mkdir_p(synthesis_dir)

      # Create sample reflection files
      File.write(File.join(reflections_dir, "reflection-2024-01-15.md"),
        "# Reflection 2024-01-15\n\n**Date**: 2024-01-15\n\n## What Went Well\n- Feature implementation completed\n\n## Key Learnings\n- Path resolution works well")
      File.write(File.join(reflections_dir, "reflection-2024-01-16.md"),
        "# Reflection 2024-01-16\n\n**Date**: 2024-01-16\n\n## What Went Well\n- Tests passing\n\n## Key Learnings\n- Integration tests valuable")
    end

    after do
      safe_directory_cleanup(temp_dir)
    end

    it "saves to correct release directory" do
      require "coding_agent_tools/organisms/taskflow_management/release_manager"
      require "coding_agent_tools/cli/commands/reflection/synthesize"

      # Set up environment to use temp directory
      CodingAgentTools::Atoms::ProjectRootDetector.method(:find_project_root)
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: temp_dir)

        # Test path resolution directly
        resolved_synthesis_path = release_manager.resolve_path("reflections/synthesis", create_if_missing: true)
        expect(resolved_synthesis_path).to eq(File.expand_path(synthesis_dir))
        expect(File.exist?(resolved_synthesis_path)).to be true
        expect(File.directory?(resolved_synthesis_path)).to be true
      ensure
        # Restore original method
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end

    it "creates synthesis subdirectory when needed" do
      require "coding_agent_tools/organisms/taskflow_management/release_manager"

      # Remove synthesis directory to test creation
      FileUtils.rm_rf(synthesis_dir)
      expect(File.exist?(synthesis_dir)).to be false

      # Mock project root detection
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: temp_dir)

        # Test that resolve_path creates the directory
        resolved_path = release_manager.resolve_path("reflections/synthesis", create_if_missing: true)
        expect(File.exist?(resolved_path)).to be true
        expect(File.directory?(resolved_path)).to be true
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end

    it "auto-discovers reflections using release manager" do
      require "coding_agent_tools/organisms/taskflow_management/release_manager"

      # Mock project root detection
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: temp_dir)

        # Test auto-discovery of reflection files
        reflections_path = release_manager.resolve_path("reflections")
        reflection_files = Dir.glob(File.join(reflections_path, "*.md"))

        expect(reflection_files).not_to be_empty
        expect(reflection_files.length).to eq(2)
        expect(reflection_files.map { |f| File.basename(f) }).to include(
          "reflection-2024-01-15.md",
          "reflection-2024-01-16.md"
        )
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end

    it "handles path resolution errors gracefully" do
      require "coding_agent_tools/organisms/taskflow_management/release_manager"

      # Test with no current release (empty current directory)
      empty_temp_dir = Dir.mktmpdir("empty_release")
      begin
        FileUtils.mkdir_p(File.join(empty_temp_dir, "dev-taskflow", "current"))

        release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: empty_temp_dir)

        expect do
          release_manager.resolve_path("reflections")
        end.to raise_error(StandardError, /Cannot resolve path/)
      ensure
        safe_directory_cleanup(empty_temp_dir)
      end
    end

    it "validates path security through release manager" do
      require "coding_agent_tools/organisms/taskflow_management/release_manager"

      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: temp_dir)

        # Test that path traversal is blocked
        expect do
          release_manager.resolve_path("../../../etc/passwd")
        end.to raise_error(SecurityError, /Resolved path failed safety validation/)
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end
  end
end
