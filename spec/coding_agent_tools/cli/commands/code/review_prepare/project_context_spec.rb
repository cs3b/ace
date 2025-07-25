# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::Code::ReviewPrepare::ProjectContext do
  let(:command) { described_class.new }
  let(:mock_context_loader) { instance_double("CodingAgentTools::Organisms::Code::ContextLoader") }
  let(:mock_context) { double("context", mode: "auto", document_count: 3) }
  let(:temp_dir) { Dir.mktmpdir }
  let(:session_dir) { File.join(temp_dir, "session") }

  before do
    FileUtils.mkdir_p(session_dir)
    allow(CodingAgentTools::Organisms::Code::ContextLoader).to receive(:new).and_return(mock_context_loader)
    allow(CodingAgentTools::Models::Code::ReviewSession).to receive(:new).and_return(double("session"))
    
    # Capture output
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#call" do
    context "with successful context loading" do
      before do
        allow(mock_context_loader).to receive(:load_context).and_return(mock_context)
        allow(mock_context_loader).to receive(:save_context).and_return({ success: true })
        allow(mock_context_loader).to receive(:get_context_summary).and_return("Context summary")
      end

      it "loads and saves context successfully" do
        result = command.call(session_dir: session_dir)

        expect(result).to eq(0)
        expect(mock_context_loader).to have_received(:load_context).with("auto", anything)
        expect(mock_context_loader).to have_received(:save_context).with(mock_context, session_dir)
      end

      it "displays success information" do
        command.call(session_dir: session_dir)

        expect($stdout).to have_received(:puts).with("✅ Loaded context: auto")
        expect($stdout).to have_received(:puts).with("📄 Documents: 3")
        expect($stdout).to have_received(:puts).with("Context summary")
      end

      it "handles custom mode" do
        command.call(session_dir: session_dir, mode: "custom")

        expect(mock_context_loader).to have_received(:load_context).with("custom", anything)
      end

      it "handles none mode" do
        command.call(session_dir: session_dir, mode: "none")

        expect(mock_context_loader).to have_received(:load_context).with("none", anything)
      end

      it "handles custom file path mode" do
        command.call(session_dir: session_dir, mode: "/docs/context.md")

        expect(mock_context_loader).to have_received(:load_context).with("/docs/context.md", anything)
      end

      it "creates minimal session for context loading" do
        expect(CodingAgentTools::Models::Code::ReviewSession).to receive(:new).with(
          hash_including(
            session_id: "temp",
            session_name: "session",
            directory_path: session_dir,
            focus: "unknown",
            target: "unknown",
            context_mode: "auto"
          )
        )

        command.call(session_dir: session_dir)
      end

      it "uses session directory basename as session name" do
        nested_session_dir = File.join(temp_dir, "nested", "review-session")
        FileUtils.mkdir_p(nested_session_dir)

        expect(CodingAgentTools::Models::Code::ReviewSession).to receive(:new).with(
          hash_including(session_name: "review-session")
        )

        command.call(session_dir: nested_session_dir)
      end

      it "passes context mode to session" do
        expect(CodingAgentTools::Models::Code::ReviewSession).to receive(:new).with(
          hash_including(context_mode: "custom")
        )

        command.call(session_dir: session_dir, mode: "custom")
      end
    end

    context "with context save failure" do
      before do
        allow(mock_context_loader).to receive(:load_context).and_return(mock_context)
        allow(mock_context_loader).to receive(:save_context).and_return({
          success: false,
          error: "Failed to save context"
        })
      end

      it "returns error code and shows error message" do
        result = command.call(session_dir: session_dir)

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Failed to save context\n")
      end
    end

    context "with context loading exceptions" do
      before do
        allow(mock_context_loader).to receive(:load_context).and_raise(StandardError, "Context load failed")
      end

      it "handles exceptions gracefully" do
        result = command.call(session_dir: session_dir)

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Context load failed\n")
      end
    end

    context "with context save exceptions" do
      before do
        allow(mock_context_loader).to receive(:load_context).and_return(mock_context)
        allow(mock_context_loader).to receive(:save_context).and_raise(IOError, "File write failed")
      end

      it "handles save exceptions gracefully" do
        result = command.call(session_dir: session_dir)

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: File write failed\n")
      end
    end

    context "with missing session directory" do
      it "handles missing session directory" do
        # Context loader should handle this, but let's test the command doesn't crash
        result = command.call(session_dir: "/nonexistent/session")

        # The result depends on how the underlying components handle missing directories
        expect(result).to be_a(Integer)
      end
    end

    context "with different context types" do
      let(:context_types) do
        [
          { mode: "auto", doc_count: 5, summary: "Auto-detected context" },
          { mode: "none", doc_count: 0, summary: "No context loaded" },
          { mode: "custom", doc_count: 2, summary: "Custom context files" }
        ]
      end

      it "handles different context types correctly" do
        context_types.each do |ctx|
          mock_ctx = double("context", mode: ctx[:mode], document_count: ctx[:doc_count])
          allow(mock_context_loader).to receive(:load_context).and_return(mock_ctx)
          allow(mock_context_loader).to receive(:save_context).and_return({ success: true })
          allow(mock_context_loader).to receive(:get_context_summary).and_return(ctx[:summary])

          result = command.call(session_dir: session_dir, mode: ctx[:mode])

          expect(result).to eq(0)
          expect($stdout).to have_received(:puts).with("✅ Loaded context: #{ctx[:mode]}")
          expect($stdout).to have_received(:puts).with("📄 Documents: #{ctx[:doc_count]}")
          expect($stdout).to have_received(:puts).with(ctx[:summary])
        end
      end
    end

    context "with timestamp handling" do
      it "uses current time for session timestamp" do
        freeze_time = Time.parse("2024-01-01 12:00:00 UTC")
        allow(Time).to receive(:now).and_return(freeze_time)

        expect(CodingAgentTools::Models::Code::ReviewSession).to receive(:new).with(
          hash_including(timestamp: freeze_time.iso8601)
        )

        command.call(session_dir: session_dir)
      end
    end

    context "with complex session directory paths" do
      it "handles paths with special characters" do
        special_session_dir = File.join(temp_dir, "session with spaces & symbols!")
        FileUtils.mkdir_p(special_session_dir)

        expect(CodingAgentTools::Models::Code::ReviewSession).to receive(:new).with(
          hash_including(
            session_name: "session with spaces & symbols!",
            directory_path: special_session_dir
          )
        )

        result = command.call(session_dir: special_session_dir)
        expect(result).to be_a(Integer)
      end

      it "handles relative paths" do
        relative_path = "./relative/session"
        
        expect(CodingAgentTools::Models::Code::ReviewSession).to receive(:new).with(
          hash_including(
            session_name: "session",
            directory_path: relative_path
          )
        )

        result = command.call(session_dir: relative_path)
        expect(result).to be_a(Integer)
      end
    end
  end

  describe "command configuration" do
    it "has correct description" do
      expect(described_class.desc).to eq("Extract and save project context")
    end

    it "requires session_dir option" do
      # This tests the required option configuration
      expect { command.call }.to raise_error(ArgumentError)
    end

    it "has default mode option" do
      # Test that mode defaults to 'auto' when not specified
      allow(mock_context_loader).to receive(:load_context).and_return(mock_context)
      allow(mock_context_loader).to receive(:save_context).and_return({ success: true })
      allow(mock_context_loader).to receive(:get_context_summary).and_return("summary")

      command.call(session_dir: session_dir)

      expect(mock_context_loader).to have_received(:load_context).with("auto", anything)
    end

    it "has usage examples defined" do
      expect(described_class).to respond_to(:example)
    end
  end

  describe "integration with dependencies" do
    it "creates context loader instance" do
      expect(CodingAgentTools::Organisms::Code::ContextLoader).to receive(:new)

      command.call(session_dir: session_dir) rescue nil
    end

    it "creates minimal review session" do
      expect(CodingAgentTools::Models::Code::ReviewSession).to receive(:new)

      command.call(session_dir: session_dir) rescue nil
    end

    it "follows expected workflow" do
      # This test ensures the command follows the expected sequence
      expect(mock_context_loader).to receive(:load_context).ordered
      expect(mock_context_loader).to receive(:save_context).ordered
      expect(mock_context_loader).to receive(:get_context_summary).ordered

      allow(mock_context_loader).to receive(:load_context).and_return(mock_context)
      allow(mock_context_loader).to receive(:save_context).and_return({ success: true })
      allow(mock_context_loader).to receive(:get_context_summary).and_return("summary")

      command.call(session_dir: session_dir)
    end
  end
end