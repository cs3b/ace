# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::CodeLint::All do
  let(:command) { described_class.new }
  let(:mock_manager) { instance_double("CodingAgentTools::Organisms::CodeQuality::MultiPhaseQualityManager") }
  let(:mock_result) { { success: true, details: "All checks passed" } }

  before do
    allow(CodingAgentTools::Organisms::CodeQuality::MultiPhaseQualityManager).to receive(:new)
      .and_return(mock_manager)
    allow(mock_manager).to receive(:run).and_return(mock_result)
    allow(mock_manager).to receive(:validate_configuration).and_return(true)
  end

  describe "#call" do
    context "with default options" do
      it "creates manager with default configuration" do
        allow(command).to receive(:exit).and_raise(SystemExit)
        
        expect { command.call }.to raise_error(SystemExit)

        expect(CodingAgentTools::Organisms::CodeQuality::MultiPhaseQualityManager)
          .to have_received(:new).with(
            config_path: nil,
            dry_run: nil
          )
      end

      it "runs quality check with default parameters" do
        allow(command).to receive(:exit).and_raise(SystemExit)
        
        expect { command.call }.to raise_error(SystemExit)

        expect(mock_manager).to have_received(:run).with(
          target: "all",
          paths: ["."],
          autofix: nil,
          review_diff: nil,
          show_details: true
        )
      end

      it "exits with success code when result is successful" do
        allow(command).to receive(:exit).and_raise(SystemExit).and_raise(SystemExit)
        
        expect { command.call }.to raise_error(SystemExit)

        expect(command).to have_received(:exit).with(0)
      end
    end

    context "with custom paths" do
      let(:custom_paths) { ["src/", "lib/"] }

      it "passes custom paths to manager" do
        allow(command).to receive(:exit).and_raise(SystemExit)
        
        expect { command.call(paths: custom_paths) }.to raise_error(SystemExit)

        expect(mock_manager).to have_received(:run).with(
          target: "all",
          paths: custom_paths,
          autofix: nil,
          review_diff: nil,
          show_details: true
        )
      end
    end

    context "with autofix option" do
      it "enables autofix in manager" do
        allow(command).to receive(:exit).and_raise(SystemExit)
        
        expect { command.call(autofix: true) }.to raise_error(SystemExit)

        expect(mock_manager).to have_received(:run).with(
          target: "all",
          paths: ["."],
          autofix: true,
          review_diff: nil,
          show_details: true
        )
      end
    end

    context "with config option" do
      let(:config_path) { "custom-config.yml" }

      it "creates manager with custom config path" do
        allow(command).to receive(:exit).and_raise(SystemExit)
        
        expect { command.call(config: config_path) }.to raise_error(SystemExit)

        expect(CodingAgentTools::Organisms::CodeQuality::MultiPhaseQualityManager)
          .to have_received(:new).with(
            config_path: config_path,
            dry_run: nil
          )
      end
    end

    context "with dry_run option" do
      it "enables dry run in manager" do
        allow(command).to receive(:exit).and_raise(SystemExit)
        
        expect { command.call(dry_run: true) }.to raise_error(SystemExit)

        expect(CodingAgentTools::Organisms::CodeQuality::MultiPhaseQualityManager)
          .to have_received(:new).with(
            config_path: nil,
            dry_run: true
          )
      end
    end

    context "with review_diff option" do
      it "enables review diff in manager" do
        allow(command).to receive(:exit).and_raise(SystemExit)
        
        expect { command.call(review_diff: true) }.to raise_error(SystemExit)

        expect(mock_manager).to have_received(:run).with(
          target: "all",
          paths: ["."],
          autofix: nil,
          review_diff: true,
          show_details: true
        )
      end
    end

    context "with validate_config option" do
      it "validates configuration and exits with success" do
        allow(command).to receive(:puts)
        allow(command).to receive(:exit).and_raise(SystemExit).and_raise(SystemExit)
        
        expect { command.call(validate_config: true) }.to raise_error(SystemExit)

        expect(mock_manager).to have_received(:validate_configuration)
        expect(command).to have_received(:puts).with("Configuration is valid")
        expect(command).to have_received(:exit).with(0)
      end

      context "when configuration is invalid" do
        before do
          allow(mock_manager).to receive(:validate_configuration).and_return(false)
        end

        it "validates configuration and exits with error" do
          allow(command).to receive(:puts)
          allow(command).to receive(:exit).and_raise(SystemExit).and_raise(SystemExit)
          
          expect { command.call(validate_config: true) }.to raise_error(SystemExit)

          expect(command).to have_received(:puts).with("Configuration is invalid")
          expect(command).to have_received(:exit).with(1)
        end
      end
    end

    context "with custom target" do
      it "passes custom target to manager" do
        allow(command).to receive(:exit).and_raise(SystemExit)
        
        expect { command.call(target: "ruby") }.to raise_error(SystemExit)

        expect(mock_manager).to have_received(:run).with(
          target: "ruby",
          paths: ["."],
          autofix: nil,
          review_diff: nil,
          show_details: true
        )
      end
    end

    context "when manager returns failure" do
      let(:failure_result) { { success: false, details: "Linting errors found" } }

      before do
        allow(mock_manager).to receive(:run).and_return(failure_result)
      end

      it "exits with error code" do
        allow(command).to receive(:exit).and_raise(SystemExit).and_raise(SystemExit)
        
        expect { command.call }.to raise_error(SystemExit)

        expect(command).to have_received(:exit).with(1)
      end
    end

    context "when an exception occurs" do
      let(:error_message) { "Something went wrong" }

      before do
        allow(mock_manager).to receive(:run).and_raise(StandardError, error_message)
      end

      it "handles the exception and exits with error" do
        allow(command).to receive(:warn)
        allow(command).to receive(:exit).and_raise(SystemExit).and_raise(SystemExit)
        
        expect { command.call }.to raise_error(SystemExit)

        expect(command).to have_received(:warn).with("Error: #{error_message}")
        expect(command).to have_received(:exit).with(1)
      end
    end

    context "with multiple options combined" do
      it "passes all options correctly" do
        allow(command).to receive(:exit).and_raise(SystemExit)
        
        expect { command.call(
          target: "markdown",
          paths: ["docs/"],
          autofix: true,
          config: "custom.yml",
          dry_run: true,
          review_diff: true
        ) }.to raise_error(SystemExit)

        expect(CodingAgentTools::Organisms::CodeQuality::MultiPhaseQualityManager)
          .to have_received(:new).with(
            config_path: "custom.yml",
            dry_run: true
          )
        
        expect(mock_manager).to have_received(:run).with(
          target: "markdown",
          paths: ["docs/"],
          autofix: true,
          review_diff: true,
          show_details: true
        )
      end
    end
  end
end