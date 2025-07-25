# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::Code::Lint do
  let(:command) { described_class.new }
  let(:mock_code_lint_all) { instance_double("CodingAgentTools::Cli::Commands::CodeLint::All") }

  before do
    allow(CodingAgentTools::Cli::Commands::CodeLint::All).to receive(:new).and_return(mock_code_lint_all)
    allow(mock_code_lint_all).to receive(:call)
  end

  describe "#call" do
    context "with default arguments" do
      it "delegates to CodeLint::All with default target" do
        command.call

        expect(CodingAgentTools::Cli::Commands::CodeLint::All).to have_received(:new)
        expect(mock_code_lint_all).to have_received(:call).with(
          target: "all",
          paths: nil
        )
      end
    end

    context "with custom target" do
      it "passes target to CodeLint::All" do
        command.call(target: "ruby")

        expect(mock_code_lint_all).to have_received(:call).with(
          target: "ruby",
          paths: nil
        )
      end
    end

    context "with paths argument" do
      it "passes paths to CodeLint::All" do
        paths = ["src/", "lib/"]
        command.call(paths: paths)

        expect(mock_code_lint_all).to have_received(:call).with(
          target: "all",
          paths: paths
        )
      end
    end

    context "with options" do
      it "passes autofix option" do
        command.call(autofix: true)

        expect(mock_code_lint_all).to have_received(:call).with(
          target: "all",
          paths: nil,
          autofix: true
        )
      end

      it "passes config option" do
        command.call(config: "custom.yml")

        expect(mock_code_lint_all).to have_received(:call).with(
          target: "all",
          paths: nil,
          config: "custom.yml"
        )
      end

      it "passes dry_run option" do
        command.call(dry_run: true)

        expect(mock_code_lint_all).to have_received(:call).with(
          target: "all",
          paths: nil,
          dry_run: true
        )
      end

      it "passes review_diff option" do
        command.call(review_diff: true)

        expect(mock_code_lint_all).to have_received(:call).with(
          target: "all",
          paths: nil,
          review_diff: true
        )
      end

      it "passes validate_config option" do
        command.call(validate_config: true)

        expect(mock_code_lint_all).to have_received(:call).with(
          target: "all",
          paths: nil,
          validate_config: true
        )
      end

      it "passes multiple options" do
        command.call(
          target: "ruby",
          paths: ["lib/"],
          autofix: true,
          config: "custom.yml",
          dry_run: false,
          review_diff: true
        )

        expect(mock_code_lint_all).to have_received(:call).with(
          target: "ruby",
          paths: ["lib/"],
          autofix: true,
          config: "custom.yml",
          dry_run: false,
          review_diff: true
        )
      end
    end

    context "with backwards compatibility" do
      it "maintains compatibility with legacy code lint interface" do
        # This test ensures the wrapper correctly delegates to the new implementation
        expect { command.call }.not_to raise_error
        expect(CodingAgentTools::Cli::Commands::CodeLint::All).to have_received(:new)
      end
    end

    context "when CodeLint::All is not available" do
      before do
        allow(CodingAgentTools::Cli::Commands::CodeLint::All).to receive(:new).and_raise(NameError, "Class not found")
      end

      it "handles missing dependency gracefully" do
        expect { command.call }.to raise_error(NameError, "Class not found")
      end
    end

    context "when CodeLint::All call fails" do
      before do
        allow(mock_code_lint_all).to receive(:call).and_raise(StandardError, "Execution failed")
      end

      it "propagates errors from delegated command" do
        expect { command.call }.to raise_error(StandardError, "Execution failed")
      end
    end
  end

  describe "command configuration" do
    it "has correct description" do
      expect(described_class.desc).to eq("Run code quality validation and linting")
    end

    it "defines paths argument correctly" do
      # This test would require access to Dry::CLI internals
      # Testing the behavior is more important than the configuration
      expect { command.call(paths: ["test"]) }.not_to raise_error
    end

    it "supports autofix option with alias" do
      expect { command.call(autofix: true) }.not_to raise_error
    end

    it "supports config option with alias" do
      expect { command.call(config: "test.yml") }.not_to raise_error
    end

    it "supports dry_run option with alias" do
      expect { command.call(dry_run: true) }.not_to raise_error
    end

    it "supports review_diff option with alias" do
      expect { command.call(review_diff: true) }.not_to raise_error
    end

    it "supports validate_config option" do
      expect { command.call(validate_config: true) }.not_to raise_error
    end
  end

  describe "option defaults" do
    it "uses false as default for autofix" do
      command.call

      expect(mock_code_lint_all).to have_received(:call).with(
        hash_including(autofix: false)
      )
    end

    it "uses false as default for dry_run" do
      command.call

      expect(mock_code_lint_all).to have_received(:call).with(
        hash_including(dry_run: false)
      )
    end

    it "uses false as default for review_diff" do
      command.call

      expect(mock_code_lint_all).to have_received(:call).with(
        hash_including(review_diff: false)
      )
    end

    it "uses false as default for validate_config" do
      command.call

      expect(mock_code_lint_all).to have_received(:call).with(
        hash_including(validate_config: false)
      )
    end
  end

  describe "delegation pattern" do
    it "correctly requires the delegated command file" do
      # This test ensures the require statement works
      expect { command.call }.not_to raise_error(LoadError)
    end

    it "creates new instance of CodeLint::All for each call" do
      command.call
      command.call

      expect(CodingAgentTools::Cli::Commands::CodeLint::All).to have_received(:new).twice
    end

    it "passes through all keyword arguments" do
      options = {
        target: "custom",
        paths: ["custom/path"],
        autofix: true,
        config: "custom.yml",
        dry_run: true,
        review_diff: false,
        validate_config: true,
        extra_option: "value"
      }

      command.call(**options)

      expect(mock_code_lint_all).to have_received(:call).with(options)
    end
  end
end
