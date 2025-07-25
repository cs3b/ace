# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::CodeLint::Ruby do
  let(:command) { described_class.new }
  let(:mock_config_loader) { instance_double("CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader") }
  let(:mock_path_resolver) { instance_double("CodingAgentTools::Atoms::CodeQuality::PathResolver") }
  let(:mock_runner) { instance_double("RubyRunner") }
  let(:mock_config) { { ruby: { enabled: true } } }
  let(:successful_result) { { success: true, errors: [] } }

  before do
    allow(CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader).to receive(:new)
      .and_return(mock_config_loader)
    allow(CodingAgentTools::Atoms::CodeQuality::PathResolver).to receive(:new)
      .and_return(mock_path_resolver)
    allow(CodingAgentTools::Organisms::CodeQuality::LanguageRunnerFactory).to receive(:create_runner)
      .and_return(mock_runner)
    
    allow(mock_config_loader).to receive(:load).and_return(mock_config)
    allow(mock_runner).to receive(:validate).and_return(successful_result)
    allow(mock_runner).to receive(:autofix).and_return(successful_result)
    allow(mock_runner).to receive(:report)
  end

  describe "#call" do
    context "with default options" do
      it "loads configuration with default path" do
        allow(command).to receive(:exit)
        
        command.call

        expect(CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader)
          .to have_received(:new).with(config_path: nil)
        expect(mock_config_loader).to have_received(:load)
      end

      it "creates path resolver" do
        allow(command).to receive(:exit)
        
        command.call

        expect(CodingAgentTools::Atoms::CodeQuality::PathResolver)
          .to have_received(:new)
      end

      it "creates ruby runner with config and path resolver" do
        allow(command).to receive(:exit)
        
        command.call

        expect(CodingAgentTools::Organisms::CodeQuality::LanguageRunnerFactory)
          .to have_received(:create_runner).with(
            "ruby",
            config: mock_config,
            path_resolver: mock_path_resolver
          )
      end

      it "runs validation with default paths" do
        allow(command).to receive(:exit)
        
        command.call

        expect(mock_runner).to have_received(:validate).with(paths: ["."])
      end

      it "reports results" do
        allow(command).to receive(:exit)
        
        command.call

        expect(mock_runner).to have_received(:report).with(successful_result)
      end

      it "exits with success code when validation succeeds" do
        allow(command).to receive(:exit)
        
        command.call

        expect(command).to have_received(:exit).with(0)
      end
    end

    context "with custom paths" do
      let(:custom_paths) { ["lib/", "spec/"] }

      it "runs validation with custom paths" do
        allow(command).to receive(:exit)
        
        command.call(paths: custom_paths)

        expect(mock_runner).to have_received(:validate).with(paths: custom_paths)
      end
    end

    context "with custom config" do
      let(:config_path) { "custom-rubocop.yml" }

      it "loads configuration from custom path" do
        allow(command).to receive(:exit)
        
        command.call(config: config_path)

        expect(CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader)
          .to have_received(:new).with(config_path: config_path)
      end
    end

    context "with autofix option" do
      it "runs autofix instead of validation" do
        allow(command).to receive(:exit)
        
        command.call(autofix: true)

        expect(mock_runner).to have_received(:autofix).with(paths: ["."])
        expect(mock_runner).not_to have_received(:validate)
      end

      it "runs autofix with custom paths" do
        allow(command).to receive(:exit)
        custom_paths = ["lib/"]
        
        command.call(autofix: true, paths: custom_paths)

        expect(mock_runner).to have_received(:autofix).with(paths: custom_paths)
      end
    end

    context "with dry_run option" do
      it "runs validation instead of autofix even when autofix is true" do
        allow(command).to receive(:exit)
        
        command.call(autofix: true, dry_run: true)

        expect(mock_runner).to have_received(:validate).with(paths: ["."])
        expect(mock_runner).not_to have_received(:autofix)
      end
    end

    context "when validation fails" do
      let(:failed_result) { { success: false, errors: ["RuboCop offense"] } }

      before do
        allow(mock_runner).to receive(:validate).and_return(failed_result)
      end

      it "exits with error code" do
        allow(command).to receive(:exit)
        
        command.call

        expect(command).to have_received(:exit).with(1)
      end

      it "still reports the failed result" do
        allow(command).to receive(:exit)
        
        command.call

        expect(mock_runner).to have_received(:report).with(failed_result)
      end
    end

    context "when autofix fails" do
      let(:failed_result) { { success: false, errors: ["Autofix failed"] } }

      before do
        allow(mock_runner).to receive(:autofix).and_return(failed_result)
      end

      it "exits with error code" do
        allow(command).to receive(:exit)
        
        command.call(autofix: true)

        expect(command).to have_received(:exit).with(1)
      end
    end

    context "when runner returns nil result" do
      before do
        allow(mock_runner).to receive(:validate).and_return(nil)
      end

      it "does not report results" do
        allow(command).to receive(:exit)
        
        command.call

        expect(mock_runner).not_to have_received(:report)
      end

      it "handles nil result and exits with error" do
        allow(command).to receive(:warn)
        allow(command).to receive(:exit)
        
        command.call

        expect(command).to have_received(:warn).with(/Error:.*undefined method.*\[\].*nil/)
        expect(command).to have_received(:exit).with(1)
      end
    end

    context "when an exception occurs" do
      let(:error_message) { "Something went wrong" }

      before do
        allow(mock_runner).to receive(:validate).and_raise(StandardError, error_message)
      end

      it "handles the exception and exits with error" do
        allow(command).to receive(:warn)
        allow(command).to receive(:exit)
        
        command.call

        expect(command).to have_received(:warn).with("Error: #{error_message}")
        expect(command).to have_received(:exit).with(1)
      end
    end

    context "with multiple options combined" do
      let(:config_path) { "special-rubocop.yml" }
      let(:custom_paths) { ["app/", "lib/"] }

      it "processes all options correctly for validation" do
        allow(command).to receive(:exit)
        
        command.call(
          paths: custom_paths,
          config: config_path,
          autofix: false,
          dry_run: false
        )

        expect(CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader)
          .to have_received(:new).with(config_path: config_path)
        expect(mock_runner).to have_received(:validate).with(paths: custom_paths)
      end

      it "processes all options correctly for autofix" do
        allow(command).to receive(:exit)
        
        command.call(
          paths: custom_paths,
          config: config_path,
          autofix: true,
          dry_run: false
        )

        expect(CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader)
          .to have_received(:new).with(config_path: config_path)
        expect(mock_runner).to have_received(:autofix).with(paths: custom_paths)
      end
    end

    context "error handling during setup" do
      context "when configuration loading fails" do
        before do
          allow(mock_config_loader).to receive(:load).and_raise(StandardError, "Config error")
        end

        it "handles configuration errors" do
          allow(command).to receive(:warn)
          allow(command).to receive(:exit)
          
          command.call

          expect(command).to have_received(:warn).with("Error: Config error")
          expect(command).to have_received(:exit).with(1)
        end
      end

      context "when runner creation fails" do
        before do
          allow(CodingAgentTools::Organisms::CodeQuality::LanguageRunnerFactory)
            .to receive(:create_runner).and_raise(StandardError, "Runner creation failed")
        end

        it "handles runner creation errors" do
          allow(command).to receive(:warn)
          allow(command).to receive(:exit)
          
          command.call

          expect(command).to have_received(:warn).with("Error: Runner creation failed")
          expect(command).to have_received(:exit).with(1)
        end
      end
    end

    context "edge cases" do
      context "with empty paths array" do
        it "passes empty array when empty array provided" do
          allow(command).to receive(:exit)
          
          command.call(paths: [])

          expect(mock_runner).to have_received(:validate).with(paths: [])
        end
      end

      context "with nil paths" do
        it "uses default paths when nil provided" do
          allow(command).to receive(:exit)
          
          command.call(paths: nil)

          expect(mock_runner).to have_received(:validate).with(paths: ["."])
        end
      end
    end

    context "Ruby-specific scenarios" do
      context "with typical Ruby project structure" do
        let(:ruby_paths) { ["app/", "lib/", "spec/", "config/"] }

        it "handles multiple Ruby directories" do
          allow(command).to receive(:exit)
          
          command.call(paths: ruby_paths)

          expect(mock_runner).to have_received(:validate).with(paths: ruby_paths)
        end
      end

      context "with autofix for Ruby style issues" do
        let(:ruby_autofix_result) do
          {
            success: true,
            errors: [],
            fixed_files: ["lib/example.rb", "spec/example_spec.rb"],
            fixed_offenses: 5
          }
        end

        before do
          allow(mock_runner).to receive(:autofix).and_return(ruby_autofix_result)
        end

        it "reports autofix results for Ruby files" do
          allow(command).to receive(:exit)
          
          command.call(autofix: true)

          expect(mock_runner).to have_received(:report).with(ruby_autofix_result)
        end
      end
    end
  end
end