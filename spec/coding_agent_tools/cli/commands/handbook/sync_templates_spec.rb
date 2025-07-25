# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::Handbook::SyncTemplates do
  let(:command) { described_class.new }
  let(:mock_config) { double("SyncConfig") }
  let(:mock_synchronizer) { double("TemplateSynchronizer") }
  let(:mock_result) { double("SyncResult", success?: true) }

  before do
    allow(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer::SyncConfig)
      .to receive(:new).and_return(mock_config)
    allow(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer)
      .to receive(:new).and_return(mock_synchronizer)
    allow(mock_synchronizer).to receive(:synchronize).and_return(mock_result)
  end

  describe "#call" do
    context "with help option" do
      it "shows help message and returns 0" do
        allow(command).to receive(:puts)

        result = command.call(help: true)

        expect(result).to eq(0)
        expect(command).to have_received(:puts)
        expect(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer)
          .not_to have_received(:new)
      end
    end

    context "with default options" do
      it "creates config with default values" do
        command.call({})

        expect(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer::SyncConfig)
          .to have_received(:new).with(
            path: nil,
            dry_run: nil,
            verbose: nil,
            commit: nil
          )
      end

      it "creates synchronizer with config" do
        command.call

        expect(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer)
          .to have_received(:new).with(config: mock_config)
      end

      it "calls synchronize on the synchronizer" do
        command.call

        expect(mock_synchronizer).to have_received(:synchronize)
      end

      it "returns 0 when synchronization succeeds" do
        result = command.call

        expect(result).to eq(0)
      end
    end

    context "with custom options" do
      let(:custom_options) do
        {
          path: "custom/path",
          dry_run: true,
          verbose: true,
          commit: true
        }
      end

      it "creates config with custom values" do
        command.call(custom_options)

        expect(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer::SyncConfig)
          .to have_received(:new).with(
            path: "custom/path",
            dry_run: true,
            verbose: true,
            commit: true
          )
      end
    end

    context "when synchronization fails" do
      let(:failed_result) { double("SyncResult", success?: false) }

      before do
        allow(mock_synchronizer).to receive(:synchronize).and_return(failed_result)
      end

      it "returns 1 when synchronization fails" do
        result = command.call

        expect(result).to eq(1)
      end
    end

    context "when an exception occurs" do
      let(:error_message) { "Synchronization failed" }

      before do
        allow(mock_synchronizer).to receive(:synchronize)
          .and_raise(StandardError, error_message)
        allow(command).to receive(:puts)
      end

      it "handles the exception and returns 1" do
        result = command.call

        expect(result).to eq(1)
        expect(command).to have_received(:puts).with("❌ Error: #{error_message}")
      end

      context "with verbose option" do
        let(:backtrace) { ["line1", "line2", "line3"] }

        before do
          error = StandardError.new(error_message)
          error.set_backtrace(backtrace)
          allow(mock_synchronizer).to receive(:synchronize).and_raise(error)
        end

        it "shows stack trace when verbose is enabled" do
          result = command.call(verbose: true)

          expect(result).to eq(1)
          expect(command).to have_received(:puts).with("❌ Error: #{error_message}")
          expect(command).to have_received(:puts).with("\nStack trace:")
          expect(command).to have_received(:puts).with("line1\nline2\nline3")
        end
      end

      context "without verbose option" do
        it "does not show stack trace when verbose is disabled" do
          result = command.call(verbose: false)

          expect(result).to eq(1)
          expect(command).to have_received(:puts).with("❌ Error: #{error_message}")
          expect(command).not_to have_received(:puts).with("\nStack trace:")
        end
      end
    end

    context "edge cases" do
      context "with mixed boolean options" do
        let(:mixed_options) do
          {
            path: "test/path",
            dry_run: true,
            verbose: false,
            commit: true,
            help: false
          }
        end

        it "handles mixed boolean options correctly" do
          command.call(mixed_options)

          expect(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer::SyncConfig)
            .to have_received(:new).with(
              path: "test/path",
              dry_run: true,
              verbose: false,
              commit: true
            )
        end
      end

      context "with nil options" do
        it "handles nil options gracefully" do
          command.call

          # Should still work with default values
          expect(mock_synchronizer).to have_received(:synchronize)
        end
      end
    end
  end

  describe "#help_message" do
    it "returns comprehensive help text" do
      help_text = command.send(:help_message)

      expect(help_text).to include("handbook sync-templates - Synchronize XML-embedded template content")
      expect(help_text).to include("DESCRIPTION:")
      expect(help_text).to include("USAGE:")
      expect(help_text).to include("OPTIONS:")
      expect(help_text).to include("EXAMPLES:")
      expect(help_text).to include("EXIT CODES:")
      expect(help_text).to include("XML FORMATS SUPPORTED:")
    end

    it "includes modern XML format example" do
      help_text = command.send(:help_message)

      expect(help_text).to include("<documents>")
      expect(help_text).to include("<template path=")
      expect(help_text).to include("<guide path=")
    end

    it "includes legacy XML format example" do
      help_text = command.send(:help_message)

      expect(help_text).to include("<templates>")
      expect(help_text).to include("Legacy format:")
    end
  end

  describe "private methods" do
    describe "#create_sync_config" do
      let(:options) do
        {
          path: "test/path",
          dry_run: true,
          verbose: false,
          commit: true
        }
      end

      it "creates SyncConfig with provided options" do
        command.send(:create_sync_config, options)

        expect(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer::SyncConfig)
          .to have_received(:new).with(
            path: "test/path",
            dry_run: true,
            verbose: false,
            commit: true
          )
      end
    end

    describe "#create_synchronizer" do
      it "creates TemplateSynchronizer with config" do
        command.send(:create_synchronizer, mock_config)

        expect(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer)
          .to have_received(:new).with(config: mock_config)
      end
    end

    describe "#handle_error" do
      let(:error) { StandardError.new("Test error") }

      before do
        allow(command).to receive(:puts)
        error.set_backtrace(["line1", "line2"])
      end

      context "with verbose enabled" do
        it "outputs error message and stack trace" do
          command.send(:handle_error, error, true)

          expect(command).to have_received(:puts).with("❌ Error: Test error")
          expect(command).to have_received(:puts).with("\nStack trace:")
          expect(command).to have_received(:puts).with("line1\nline2")
        end
      end

      context "with verbose disabled" do
        it "outputs only error message" do
          command.send(:handle_error, error, false)

          expect(command).to have_received(:puts).with("❌ Error: Test error")
          expect(command).not_to have_received(:puts).with("\nStack trace:")
        end
      end
    end
  end

  describe "integration scenarios" do
    context "successful synchronization flow" do
      it "executes complete workflow successfully" do
        options = {
          path: "custom/path",
          dry_run: false,
          verbose: true,
          commit: false
        }

        result = command.call(options)

        expect(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer::SyncConfig)
          .to have_received(:new).with(options)
        expect(CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer)
          .to have_received(:new).with(config: mock_config)
        expect(mock_synchronizer).to have_received(:synchronize)
        expect(result).to eq(0)
      end
    end

    context "failed synchronization flow" do
      let(:failed_result) { double("SyncResult", success?: false) }

      before do
        allow(mock_synchronizer).to receive(:synchronize).and_return(failed_result)
      end

      it "executes workflow and handles failure" do
        result = command.call

        expect(mock_synchronizer).to have_received(:synchronize)
        expect(result).to eq(1)
      end
    end

    context "exception during synchronization" do
      before do
        allow(mock_synchronizer).to receive(:synchronize)
          .and_raise(StandardError, "Critical error")
        allow(command).to receive(:puts)
      end

      it "handles exception and provides error feedback" do
        result = command.call

        expect(command).to have_received(:puts).with("❌ Error: Critical error")
        expect(result).to eq(1)
      end
    end
  end
end
