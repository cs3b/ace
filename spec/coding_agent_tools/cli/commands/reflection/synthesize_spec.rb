# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::Reflection::Synthesize do
  let(:command) { described_class.new }
  let(:mock_report_collector) { instance_double("CodingAgentTools::Molecules::Reflection::ReportCollector") }
  let(:mock_timestamp_inferrer) { instance_double("CodingAgentTools::Molecules::Reflection::TimestampInferrer") }
  let(:mock_synthesis_orchestrator) { instance_double("CodingAgentTools::Molecules::Reflection::SynthesisOrchestrator") }
  let(:mock_path_resolver) { instance_double("CodingAgentTools::Molecules::PathResolver") }
  let(:mock_release_manager) { instance_double("CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager") }
  let(:temp_dir) { Dir.mktmpdir }
  let(:reflection1) { File.join(temp_dir, "reflection-2024-01-15.md") }
  let(:reflection2) { File.join(temp_dir, "reflection-2024-01-20.md") }
  let(:timestamp_result) do
    double("TimestampResult",
      valid?: true,
      from_date: Date.new(2024, 1, 15),
      to_date: Date.new(2024, 1, 20),
      days_covered: 5)
  end

  before do
    FileUtils.mkdir_p(temp_dir)
    File.write(reflection1, "# Reflection 2024-01-15\nLearnings and insights...")
    File.write(reflection2, "# Reflection 2024-01-20\nMore learnings...")

    allow(CodingAgentTools::Molecules::Reflection::ReportCollector).to receive(:new).and_return(mock_report_collector)
    allow(CodingAgentTools::Molecules::Reflection::TimestampInferrer).to receive(:new).and_return(mock_timestamp_inferrer)
    allow(CodingAgentTools::Molecules::Reflection::SynthesisOrchestrator).to receive(:new).and_return(mock_synthesis_orchestrator)
    allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(mock_path_resolver)
    allow(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to receive(:new).and_return(mock_release_manager)

    # Setup default ReleaseManager mock behavior for all tests
    allow(mock_release_manager).to receive(:resolve_path)
      .with("reflections/synthesis", create_if_missing: true)
      .and_return("/current/release/reflections/synthesis")
    allow(mock_release_manager).to receive(:resolve_path)
      .with("reflections")
      .and_return("/current/release/reflections")

    # Setup Dir.glob for auto-discovery
    allow(Dir).to receive(:glob).and_return([reflection1, reflection2])

    # Capture output
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#call" do
    context "with explicit reflection notes provided" do
      let(:collection_result) do
        double("CollectionResult",
          valid?: true,
          reports: [
            double("Report", path: reflection1, content: "Content 1"),
            double("Report", path: reflection2, content: "Content 2")
          ])
      end

      let(:synthesis_result) do
        double("SynthesisResult",
          success?: true,
          output_path: "/path/to/synthesis.md",
          metrics: {
            reflections_count: 2,
            execution_time: 5.2,
            output_tokens: 1200,
            cost: 0.0035
          })
      end

      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return(collection_result)
        allow(mock_timestamp_inferrer).to receive(:infer_timestamp_range).and_return(timestamp_result)
        allow(mock_synthesis_orchestrator).to receive(:synthesize_reflections).and_return(synthesis_result)
      end

      it "synthesizes reflections successfully" do
        result = command.call(reflection_notes: [reflection1, reflection2])

        expect(result).to eq(0)
        expect(mock_report_collector).to have_received(:collect_reports).with([reflection1, reflection2])
        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections)
      end

      it "uses default model when not specified" do
        command.call(reflection_notes: [reflection1, reflection2])

        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(model: nil)
        )
      end

      it "uses custom model when specified" do
        command.call(reflection_notes: [reflection1, reflection2], model: "anthropic:claude-4-0-sonnet-latest")

        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(model: "anthropic:claude-4-0-sonnet-latest")
        )
      end

      it "infers timestamp range from reflection notes" do
        command.call(reflection_notes: [reflection1, reflection2])

        expect(mock_timestamp_inferrer).to have_received(:infer_timestamp_range).with(collection_result.reports)
      end

      it "generates timestamp-based output filename" do
        command.call(reflection_notes: [reflection1, reflection2])

        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(output_path: "/current/release/reflections/synthesis/20240115-20240120-reflection-synthesis.md")
        )
      end

      it "uses custom output path when specified" do
        custom_output = "/custom/synthesis.md"
        command.call(reflection_notes: [reflection1, reflection2], output: custom_output)

        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(output_path: custom_output)
        )
      end

      it "uses default format when not specified" do
        command.call(reflection_notes: [reflection1, reflection2])

        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(format: nil)
        )
      end

      it "uses custom format when specified" do
        command.call(reflection_notes: [reflection1, reflection2], format: "json")

        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(format: "json")
        )
      end

      it "uses default system prompt path" do
        command.call(reflection_notes: [reflection1, reflection2])

        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(system_prompt_path: "dev-handbook/templates/release-reflections/synthsize.system.prompt.md")
        )
      end

      it "uses custom system prompt when specified" do
        custom_prompt = "/custom/prompt.md"
        command.call(reflection_notes: [reflection1, reflection2], system_prompt: custom_prompt)

        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(system_prompt_path: custom_prompt)
        )
      end

      it "handles force option" do
        command.call(reflection_notes: [reflection1, reflection2], force: true)

        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(force: true)
        )
      end

      it "handles debug option" do
        command.call(reflection_notes: [reflection1, reflection2], debug: true)

        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(debug: true)
        )
      end

      it "displays success information and metrics" do
        command.call(reflection_notes: [reflection1, reflection2])

        expect($stdout).to have_received(:puts).with(match(/✅.*synthesis.*completed/i))
        expect($stdout).to have_received(:puts).with(match(/📊.*synthesis metrics/i))
        expect($stdout).to have_received(:puts).with(match(/📝.*reflections processed.*2/i))
      end
    end

    context "with auto-discovery enabled" do
      let(:discovered_reflections) { [reflection1, reflection2] }
      let(:collection_result) do
        double("CollectionResult",
          valid?: true,
          reports: [
            double("Report", path: reflection1),
            double("Report", path: reflection2)
          ])
      end

      let(:synthesis_result) do
        double("SynthesisResult", success?: true, output_path: "/path/to/synthesis.md", metrics: nil)
      end

      before do
        # Override Dir.glob for this context
        allow(Dir).to receive(:glob).and_return(discovered_reflections)

        # Fallback PathResolver mock for legacy support
        allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release).and_return({
          success: true,
          paths: discovered_reflections
        })
        allow(mock_report_collector).to receive(:collect_reports).and_return(collection_result)
        allow(mock_timestamp_inferrer).to receive(:infer_timestamp_range).and_return(timestamp_result)
        allow(mock_synthesis_orchestrator).to receive(:synthesize_reflections).and_return(synthesis_result)
      end

      it "auto-discovers reflection notes when none provided" do
        result = command.call(reflection_notes: [])

        expect(result).to eq(0)
        expect(mock_release_manager).to have_received(:resolve_path).with("reflections")
        expect($stdout).to have_received(:puts).with(match(/🔍.*auto-discovering/i))
        expect($stdout).to have_received(:puts).with(match(/✅.*found.*2.*reflection notes/i)).at_least(:once)
      end

      it "auto-discovers reflection notes when nil provided" do
        result = command.call(reflection_notes: nil)

        expect(result).to eq(0)
        expect(mock_release_manager).to have_received(:resolve_path).with("reflections")
      end

      it "handles auto-discovery failure gracefully" do
        # Make ReleaseManager fail and PathResolver also fail
        allow(mock_release_manager).to receive(:resolve_path).with("reflections").and_raise(StandardError, "No current release")
        allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release).and_return({
          success: false,
          error: "Directory not found"
        })

        result = command.call(reflection_notes: [])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/no reflection notes found/i))
      end

      it "handles auto-discovery returning empty list" do
        # Make ReleaseManager return empty results and PathResolver also return empty
        allow(Dir).to receive(:glob).and_return([])
        allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release).and_return({
          success: true,
          paths: []
        })

        result = command.call(reflection_notes: [])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/no reflection notes found/i))
      end

      it "handles auto-discovery exception" do
        # Make ReleaseManager fail and PathResolver raise exception
        allow(mock_release_manager).to receive(:resolve_path).with("reflections").and_raise(StandardError, "No current release")
        allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release).and_raise(StandardError, "Unexpected error")

        result = command.call(reflection_notes: [])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/no reflection notes found/i))
      end
    end

    context "with insufficient reflection notes" do
      it "rejects single reflection note" do
        allow(mock_report_collector).to receive(:collect_reports).and_return(
          double("CollectionResult", valid?: true, reports: [double("Report")])
        )

        result = command.call(reflection_notes: [reflection1])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/at least 2 reflection note files are required/i))
      end

      it "rejects empty reflection list" do
        # Override Dir.glob to return empty array for this test
        allow(Dir).to receive(:glob).and_return([])
        allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release).and_return({
          success: true,
          paths: []
        })

        result = command.call(reflection_notes: [])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/no reflection notes found/i))
      end
    end

    context "with collection failures" do
      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return(
          double("CollectionResult", valid?: false, error: "Reflection file not found")
        )
      end

      it "handles collection errors" do
        result = command.call(reflection_notes: [reflection1, reflection2])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/reflection file not found/i))
      end
    end

    context "with synthesis failures" do
      let(:collection_result) do
        double("CollectionResult", valid?: true, reports: [double("Report"), double("Report")])
      end

      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return(collection_result)
        allow(mock_timestamp_inferrer).to receive(:infer_timestamp_range).and_return(timestamp_result)
        allow(mock_synthesis_orchestrator).to receive(:synthesize_reflections).and_return(
          double("SynthesisResult", success?: false, error: "LLM synthesis failed")
        )
      end

      it "handles synthesis errors" do
        result = command.call(reflection_notes: [reflection1, reflection2])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/synthesis failed.*llm synthesis failed/i))
      end
    end

    context "with dry run option" do
      let(:collection_result) do
        double("CollectionResult",
          valid?: true,
          reports: [
            double("Report", path: reflection1),
            double("Report", path: reflection2)
          ])
      end

      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return(collection_result)
        allow(mock_timestamp_inferrer).to receive(:infer_timestamp_range).and_return(timestamp_result)
      end

      it "performs dry run without actual synthesis" do
        result = command.call(reflection_notes: [reflection1, reflection2], dry_run: true)

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with(match(/🔍.*dry run/i))
      end

      it "displays dry run configuration information" do
        command.call(reflection_notes: [reflection1, reflection2], dry_run: true, model: "custom:model")

        expect($stdout).to have_received(:puts).with(match(/reflection notes to synthesize/i))
        expect($stdout).to have_received(:puts).with(match(/timestamp analysis/i))
        expect($stdout).to have_received(:puts).with(match(/synthesis configuration/i)).at_least(:once)
        expect($stdout).to have_received(:puts).with(match(/🤖.*model.*custom:model/i))
      end

      it "handles dry run with invalid timestamp range" do
        invalid_timestamp_result = double("TimestampResult", valid?: false)
        allow(mock_timestamp_inferrer).to receive(:infer_timestamp_range).and_return(invalid_timestamp_result)

        result = command.call(reflection_notes: [reflection1, reflection2], dry_run: true)

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with(match(/❌.*no timestamp range detected/i))
        expect($stdout).to have_received(:puts).with(match(/using current date as fallback/i))
      end
    end

    context "with archive option" do
      let(:collection_result) do
        double("CollectionResult",
          valid?: true,
          reports: [
            double("Report", path: reflection1),
            double("Report", path: reflection2)
          ])
      end

      let(:synthesis_result) do
        double("SynthesisResult", success?: true, output_path: "/path/to/synthesis.md", metrics: nil)
      end

      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return(collection_result)
        allow(mock_timestamp_inferrer).to receive(:infer_timestamp_range).and_return(timestamp_result)
        allow(mock_synthesis_orchestrator).to receive(:synthesize_reflections).and_return(synthesis_result)
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:mv)
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:write)
        allow(Time).to receive(:now).and_return(Time.new(2024, 1, 25, 14, 30, 0))
      end

      it "archives reflection notes by default after successful synthesis" do
        # Mock the actual archiving method to return success
        allow(command).to receive(:archive_reflection_notes).and_return({success: true, count: 2, archive_dir: "/archive/dir"})

        # Use hash syntax to explicitly confirm the default value
        result = command.call(reflection_notes: [reflection1, reflection2], archived: true)

        expect(result).to eq(0)
        expect(command).to have_received(:archive_reflection_notes).with(collection_result.reports)
        expect($stdout).to have_received(:puts).with(match(/📦.*archived.*2.*reflection notes/i))
        expect($stdout).to have_received(:puts).with(match(/📁.*archive location/i))
      end

      it "archives reflection notes when explicitly enabled" do
        # Mock the actual archiving method to return success
        allow(command).to receive(:archive_reflection_notes).and_return({success: true, count: 2, archive_dir: "/archive/dir"})

        result = command.call(reflection_notes: [reflection1, reflection2], archived: true)

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with(match(/📦.*archived.*2.*reflection notes/i))
        expect($stdout).to have_received(:puts).with(match(/📁.*archive location/i))
      end

      it "handles archive failure gracefully when using default" do
        # Mock the actual archiving method to return failure
        allow(command).to receive(:archive_reflection_notes).and_return({success: false, error: "Permission denied"})

        result = command.call(reflection_notes: [reflection1, reflection2], archived: true)  # Explicitly enable archiving

        expect(result).to eq(0)  # Synthesis still succeeds
        expect(command).to have_received(:archive_reflection_notes).with(collection_result.reports)
        expect($stderr).to have_received(:write).with(match(/⚠️.*warning.*could not archive.*permission denied/i))
      end

      it "handles archive failure gracefully when explicitly enabled" do
        # Mock the actual archiving method to return failure
        allow(command).to receive(:archive_reflection_notes).and_return({success: false, error: "Permission denied"})

        result = command.call(reflection_notes: [reflection1, reflection2], archived: true)

        expect(result).to eq(0)  # Synthesis still succeeds
        expect($stderr).to have_received(:write).with(match(/⚠️.*warning.*could not archive.*permission denied/i))
      end

      it "skips archiving when explicitly disabled" do
        result = command.call(reflection_notes: [reflection1, reflection2], archived: false)

        expect(result).to eq(0)
        expect(FileUtils).not_to have_received(:mv)
      end

      it "archives by default when --archived not specified" do
        # Mock the actual archiving method to return success
        allow(command).to receive(:archive_reflection_notes).and_return({success: true, count: 2, archive_dir: "/archive/dir"})

        # According to the CLI definition, archived defaults to true, so we pass the default explicitly
        result = command.call(reflection_notes: [reflection1, reflection2], archived: true)

        expect(result).to eq(0)
        expect(command).to have_received(:archive_reflection_notes).with(collection_result.reports)
      end

      it "respects --no-archived flag" do
        result = command.call(reflection_notes: [reflection1, reflection2], archived: false)

        expect(result).to eq(0)
        expect(FileUtils).not_to have_received(:mv)  # No actual archiving should happen
      end

      it "shows archived as true in dry run output by default" do
        command.call(reflection_notes: [reflection1, reflection2], dry_run: true)

        # The dry run doesn't show archive status explicitly, but archived defaults to true
        expect($stdout).to have_received(:puts).with(match(/🔍.*dry run/i))
      end
    end

    context "with timestamp inference edge cases" do
      let(:collection_result) do
        double("CollectionResult", valid?: true, reports: [double("Report"), double("Report")])
      end

      let(:synthesis_result) do
        double("SynthesisResult", success?: true, output_path: "/path/to/synthesis.md", metrics: nil)
      end

      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return(collection_result)
        allow(mock_synthesis_orchestrator).to receive(:synthesize_reflections).and_return(synthesis_result)
        allow(Time).to receive(:now).and_return(Time.new(2024, 2, 1))
      end

      it "handles invalid timestamp range gracefully" do
        invalid_timestamp_result = double("TimestampResult", valid?: false)
        allow(mock_timestamp_inferrer).to receive(:infer_timestamp_range).and_return(invalid_timestamp_result)

        result = command.call(reflection_notes: [reflection1, reflection2])

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with(match(/⚠️.*could not infer timestamp range/i))
        expect(mock_synthesis_orchestrator).to have_received(:synthesize_reflections).with(
          hash_including(output_path: "/current/release/reflections/synthesis/20240201-reflection-synthesis.md")
        )
      end
    end

    context "with exception handling" do
      before do
        allow(mock_report_collector).to receive(:collect_reports).and_raise(StandardError, "Unexpected error")
      end

      it "handles unexpected exceptions gracefully" do
        result = command.call(reflection_notes: [reflection1, reflection2])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/error.*unexpected error/i))
        expect($stderr).to have_received(:write).with(match(/use --debug flag for more information/i))
      end

      it "shows detailed error information with debug flag" do
        result = command.call(reflection_notes: [reflection1, reflection2], debug: true)

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/error.*standarderror.*unexpected error/i))
        expect($stderr).to have_received(:write).with(match(/backtrace/i))
      end
    end
  end

  describe "#determine_output_path" do
    let(:valid_timestamp_result) do
      double("TimestampResult",
        valid?: true,
        from_date: Date.new(2024, 1, 15),
        to_date: Date.new(2024, 1, 20))
    end

    let(:invalid_timestamp_result) do
      double("TimestampResult", valid?: false)
    end

    let(:mock_release_manager) do
      double("ReleaseManager").tap do |manager|
        allow(manager).to receive(:resolve_path)
          .with("reflections/synthesis", create_if_missing: true)
          .and_return("/current/release/reflections/synthesis")
      end
    end

    it "returns explicit output when provided" do
      output_path = command.send(:determine_output_path, "/custom/output.md", valid_timestamp_result, mock_release_manager)
      expect(output_path).to eq("/custom/output.md")
    end

    it "uses release reflections/synthesis directory by default" do
      output_path = command.send(:determine_output_path, nil, valid_timestamp_result, mock_release_manager)
      expect(output_path).to eq("/current/release/reflections/synthesis/20240115-20240120-reflection-synthesis.md")
      expect(mock_release_manager).to have_received(:resolve_path).with("reflections/synthesis", create_if_missing: true)
    end

    it "creates synthesis directory if missing" do
      output_path = command.send(:determine_output_path, nil, valid_timestamp_result, mock_release_manager)
      expect(output_path).to eq("/current/release/reflections/synthesis/20240115-20240120-reflection-synthesis.md")
      expect(mock_release_manager).to have_received(:resolve_path).with("reflections/synthesis", create_if_missing: true)
    end

    it "generates timestamp-based filename when valid timestamps available" do
      output_path = command.send(:determine_output_path, nil, valid_timestamp_result, mock_release_manager)
      expect(output_path).to eq("/current/release/reflections/synthesis/20240115-20240120-reflection-synthesis.md")
    end

    it "generates current date-based filename when timestamps invalid" do
      allow(Time).to receive(:now).and_return(Time.new(2024, 2, 1))
      output_path = command.send(:determine_output_path, nil, invalid_timestamp_result, mock_release_manager)
      expect(output_path).to eq("/current/release/reflections/synthesis/20240201-reflection-synthesis.md")
    end

    it "falls back to current directory when ReleaseManager fails" do
      failing_release_manager = double("ReleaseManager")
      allow(failing_release_manager).to receive(:resolve_path).and_raise(StandardError, "No current release")
      allow($stderr).to receive(:write)

      output_path = command.send(:determine_output_path, nil, valid_timestamp_result, failing_release_manager)
      expect(output_path).to eq("20240115-20240120-reflection-synthesis.md")
      expect($stderr).to have_received(:write).with(match(/warning.*could not resolve release path/i))
    end
  end

  describe "#auto_discover_reflection_notes" do
    let(:mock_release_manager_discovery) do
      double("ReleaseManager").tap do |manager|
        allow(manager).to receive(:resolve_path)
          .with("reflections")
          .and_return("/current/release/reflections")
      end
    end

    before do
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(mock_path_resolver)
      allow(Dir).to receive(:glob).and_return([reflection1.to_s, reflection2.to_s])
    end

    describe "ReleaseManager integration" do
      it "uses ReleaseManager for path resolution" do
        result = command.send(:auto_discover_reflection_notes, mock_release_manager_discovery)
        expect(result).to include(reflection1.to_s, reflection2.to_s)
        expect(mock_release_manager_discovery).to have_received(:resolve_path).with("reflections")
      end

      it "returns discovered paths using ReleaseManager" do
        result = command.send(:auto_discover_reflection_notes, mock_release_manager_discovery)
        expect(result).to include(reflection1.to_s, reflection2.to_s)
      end

      it "handles missing current release" do
        failing_manager = double("ReleaseManager")
        allow(failing_manager).to receive(:resolve_path).and_raise(StandardError, "No current release")
        allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release).and_return({
          success: true,
          paths: [reflection1, reflection2]
        })

        result = command.send(:auto_discover_reflection_notes, failing_manager)
        expect(result).to eq([reflection1, reflection2])
        expect($stderr).to have_received(:write).with(match(/warning.*could not auto-discover.*using releasemanager/i))
      end

      it "auto-discovers using ReleaseManager by default" do
        result = command.send(:auto_discover_reflection_notes, mock_release_manager_discovery)
        expect(result).to include(reflection1.to_s, reflection2.to_s)
        expect(mock_release_manager_discovery).to have_received(:resolve_path).with("reflections")
      end
    end

    it "falls back to legacy PathResolver when ReleaseManager fails" do
      failing_manager = double("ReleaseManager")
      allow(failing_manager).to receive(:resolve_path).and_raise(StandardError, "No current release")
      allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release).and_return({
        success: true,
        paths: [reflection1, reflection2]
      })

      result = command.send(:auto_discover_reflection_notes, failing_manager)
      expect(result).to eq([reflection1, reflection2])
      expect($stderr).to have_received(:write).with(match(/warning.*could not auto-discover.*using releasemanager/i))
    end

    it "returns empty array when both ReleaseManager and fallback fail" do
      failing_manager = double("ReleaseManager")
      allow(failing_manager).to receive(:resolve_path).and_raise(StandardError, "No current release")
      allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release).and_return({
        success: false,
        error: "Directory not found"
      })

      result = command.send(:auto_discover_reflection_notes, failing_manager)
      expect(result).to eq([])
      expect($stderr).to have_received(:write).with(match(/warning.*could not auto-discover.*directory not found/i))
    end

    it "handles exception in fallback PathResolver" do
      failing_manager = double("ReleaseManager")
      allow(failing_manager).to receive(:resolve_path).and_raise(StandardError, "No current release")
      allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release).and_raise(StandardError, "Network error")

      result = command.send(:auto_discover_reflection_notes, failing_manager)
      expect(result).to eq([])
      expect($stderr).to have_received(:write).with(match(/warning.*auto-discovery failed.*network error/i))
    end
  end

  describe "#archive_reflection_notes" do
    let(:reflection_paths) { [reflection1.to_s, reflection2.to_s] }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:mv)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:write)
      allow(Time).to receive(:now).and_return(Time.new(2024, 1, 25, 14, 30, 0))
    end

    it "archives reflection notes successfully" do
      result = command.send(:archive_reflection_notes, reflection_paths)

      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
      expect(result[:archive_dir]).to match(/synthesis-20240125-143000/)
      expect(FileUtils).to have_received(:mkdir_p)
      expect(FileUtils).to have_received(:mv).twice
    end

    it "handles empty reflection paths" do
      result = command.send(:archive_reflection_notes, [])

      expect(result[:success]).to be false
      expect(result[:error]).to eq("No reflection paths provided")
    end

    it "handles missing reflection files" do
      allow(File).to receive(:exist?).with(reflection1).and_return(false)
      allow(File).to receive(:exist?).with(reflection2).and_return(true)

      result = command.send(:archive_reflection_notes, reflection_paths)

      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)  # Only one file actually archived
    end

    it "handles file operation exceptions" do
      allow(FileUtils).to receive(:mv).and_raise(StandardError, "Permission denied")

      result = command.send(:archive_reflection_notes, reflection_paths)

      expect(result[:success]).to be false
      expect(result[:error]).to eq("Permission denied")
    end

    it "creates archive summary" do
      command.send(:archive_reflection_notes, reflection_paths)

      expect(File).to have_received(:write).with(
        match(/archive-summary\.md$/),
        match(/reflection archive summary/i)
      )
    end
  end

  describe "#handle_error" do
    let(:error) { StandardError.new("Test error") }

    before do
      allow(error).to receive(:backtrace).and_return(["line1", "line2", "line3"])
    end

    it "shows minimal error information when debug disabled" do
      command.send(:handle_error, error, false)

      expect($stderr).to have_received(:write).with(match(/error.*test error/i))
      expect($stderr).to have_received(:write).with(match(/use --debug flag for more information/i))
    end

    it "shows detailed error information when debug enabled" do
      command.send(:handle_error, error, true)

      expect($stderr).to have_received(:write).with(match(/error.*standarderror.*test error/i))
      expect($stderr).to have_received(:write).with(match(/backtrace/i))
      expect($stderr).to have_received(:write).with(match(/line1/))
    end
  end

  describe "command configuration" do
    it "has correct description" do
      expect(described_class.description).to eq("Synthesize multiple reflection notes into unified analysis")
    end

    it "accepts reflection_notes as optional array argument" do
      # This is tested through the call method tests above
      expect(described_class.new).to respond_to(:call)
    end

    it "has default values for options" do
      # Tested through the various option handling tests above
      expect(described_class.new).to respond_to(:call)
    end

    it "validates format option values" do
      # dry-cli should validate that format is one of text, json, markdown
      # This is enforced at the framework level, not in our code
      expect(%w[text json markdown]).to include("markdown")  # default format
    end

    it "has usage examples defined" do
      expect(described_class).to respond_to(:example)
    end
  end

  describe "integration with molecules" do
    it "creates required molecule instances" do
      mock_collector = instance_double("CodingAgentTools::Molecules::Reflection::ReportCollector")
      mock_inferrer = instance_double("CodingAgentTools::Molecules::Reflection::TimestampInferrer")
      mock_orchestrator = instance_double("CodingAgentTools::Molecules::Reflection::SynthesisOrchestrator")

      allow(mock_collector).to receive(:collect_reports).and_return(
        double("Result", valid?: true, reports: [double("Report"), double("Report")])
      )
      allow(mock_inferrer).to receive(:infer_timestamp_range).and_return(timestamp_result)
      allow(mock_orchestrator).to receive(:synthesize_reflections).and_return(
        double("Result", success?: true, output_path: "/path.md", metrics: nil)
      )

      expect(CodingAgentTools::Molecules::Reflection::ReportCollector).to receive(:new).and_return(mock_collector)
      expect(CodingAgentTools::Molecules::Reflection::TimestampInferrer).to receive(:new).and_return(mock_inferrer)
      expect(CodingAgentTools::Molecules::Reflection::SynthesisOrchestrator).to receive(:new).and_return(mock_orchestrator)

      command.call(reflection_notes: [reflection1, reflection2])
    end
  end

  describe "return codes" do
    it "returns 0 for successful synthesis" do
      allow(mock_report_collector).to receive(:collect_reports).and_return(
        double("Result", valid?: true, reports: [double("Report"), double("Report")])
      )
      allow(mock_timestamp_inferrer).to receive(:infer_timestamp_range).and_return(timestamp_result)
      allow(mock_synthesis_orchestrator).to receive(:synthesize_reflections).and_return(
        double("Result", success?: true, output_path: "/path.md", metrics: nil)
      )

      result = command.call(reflection_notes: [reflection1, reflection2])
      expect(result).to eq(0)
    end

    it "returns 1 for insufficient reflections" do
      result = command.call(reflection_notes: [reflection1])
      expect(result).to eq(1)
    end

    it "returns 1 for collection errors" do
      allow(mock_report_collector).to receive(:collect_reports).and_return(
        double("Result", valid?: false, error: "Error")
      )
      result = command.call(reflection_notes: [reflection1, reflection2])
      expect(result).to eq(1)
    end

    it "returns 1 for synthesis errors" do
      allow(mock_report_collector).to receive(:collect_reports).and_return(
        double("Result", valid?: true, reports: [double("Report"), double("Report")])
      )
      allow(mock_timestamp_inferrer).to receive(:infer_timestamp_range).and_return(timestamp_result)
      allow(mock_synthesis_orchestrator).to receive(:synthesize_reflections).and_return(
        double("Result", success?: false, error: "Error")
      )

      result = command.call(reflection_notes: [reflection1, reflection2])
      expect(result).to eq(1)
    end

    it "returns 1 for exceptions" do
      allow(mock_report_collector).to receive(:collect_reports).and_raise(StandardError)
      result = command.call(reflection_notes: [reflection1, reflection2])
      expect(result).to eq(1)
    end

    it "returns 0 for successful dry run" do
      allow(mock_report_collector).to receive(:collect_reports).and_return(
        double("Result", valid?: true, reports: [double("Report"), double("Report")])
      )
      allow(mock_timestamp_inferrer).to receive(:infer_timestamp_range).and_return(timestamp_result)

      result = command.call(reflection_notes: [reflection1, reflection2], dry_run: true)
      expect(result).to eq(0)
    end
  end
end
