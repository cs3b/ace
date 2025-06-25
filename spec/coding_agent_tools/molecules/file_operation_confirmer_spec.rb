# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "tempfile"

RSpec.describe CodingAgentTools::Molecules::FileOperationConfirmer do
  let(:security_logger) { instance_double(CodingAgentTools::Atoms::SecurityLogger) }
  let(:input_io) { StringIO.new }
  let(:output_io) { StringIO.new }
  let(:confirmer) do
    described_class.new(
      security_logger: security_logger,
      input: input_io,
      output: output_io
    )
  end

  before do
    allow(security_logger).to receive(:log_event)
    allow(security_logger).to receive(:log_error)
  end

  describe "#initialize" do
    it "creates instance with default logger when none provided" do
      confirmer = described_class.new
      expect(confirmer.security_logger).to be_a(CodingAgentTools::Atoms::SecurityLogger)
    end

    it "uses provided security logger" do
      expect(confirmer.security_logger).to eq(security_logger)
    end
  end

  describe "#confirm_overwrite" do
    let(:test_file) { Tempfile.new("test") }

    after do
      test_file.close
      test_file.unlink
    end

    context "with force flag" do
      it "auto-confirms when force is true" do
        result = confirmer.confirm_overwrite(test_file.path, force: true)

        expect(result.confirmed?).to be true
        expect(result.auto_decision?).to be true
        expect(result.reason).to eq("Force flag provided")

        expect(security_logger).to have_received(:log_event).with(:overwrite_confirmed, anything)
      end

      it "logs forced overwrite with metadata" do
        confirmer.confirm_overwrite(test_file.path, force: true)

        expect(security_logger).to have_received(:log_event).with(
          :overwrite_confirmed,
          hash_including(metadata: hash_including(forced: true))
        )
      end
    end

    context "with non-existent file" do
      it "auto-confirms when file doesn't exist" do
        non_existent_file = "/tmp/does_not_exist_#{Time.now.to_i}.txt"

        result = confirmer.confirm_overwrite(non_existent_file)

        expect(result.confirmed?).to be true
        expect(result.auto_decision?).to be true
        expect(result.reason).to eq("File does not exist")
      end
    end

    context "in non-interactive environment" do
      before do
        # Mock non-interactive environment
        allow(confirmer).to receive(:interactive_environment?).and_return(false)
      end

      it "denies overwrite by default" do
        result = confirmer.confirm_overwrite(test_file.path)

        expect(result.denied?).to be true
        expect(result.auto_decision?).to be true
        expect(result.reason).to include("Non-interactive environment")

        expect(security_logger).to have_received(:log_event).with(:overwrite_denied, anything)
      end

      it "logs denial with auto-decision metadata" do
        confirmer.confirm_overwrite(test_file.path)

        expect(security_logger).to have_received(:log_event).with(
          :overwrite_denied,
          hash_including(metadata: hash_including(auto_decision: true))
        )
      end
    end

    context "in interactive environment" do
      before do
        # Mock interactive environment
        allow(confirmer).to receive(:interactive_environment?).and_return(true)
      end

      it "confirms when user responds with 'y'" do
        input_io.string = "y\n"
        input_io.rewind

        result = confirmer.confirm_overwrite(test_file.path)

        expect(result.confirmed?).to be true
        expect(result.auto_decision?).to be false
        expect(result.reason).to eq("User confirmed")

        expect(security_logger).to have_received(:log_event).with(:overwrite_confirmed, anything)
      end

      it "confirms when user responds with 'yes'" do
        input_io.string = "yes\n"
        input_io.rewind

        result = confirmer.confirm_overwrite(test_file.path)

        expect(result.confirmed?).to be true
        expect(result.reason).to eq("User confirmed")
      end

      it "denies when user responds with 'n'" do
        input_io.string = "n\n"
        input_io.rewind

        result = confirmer.confirm_overwrite(test_file.path)

        expect(result.denied?).to be true
        expect(result.reason).to eq("User declined")

        expect(security_logger).to have_received(:log_event).with(:overwrite_denied, anything)
      end

      it "denies when user responds with 'no'" do
        input_io.string = "no\n"
        input_io.rewind

        result = confirmer.confirm_overwrite(test_file.path)

        expect(result.denied?).to be true
        expect(result.reason).to eq("User declined")
      end

      it "denies when user responds with empty string" do
        input_io.string = "\n"
        input_io.rewind

        result = confirmer.confirm_overwrite(test_file.path)

        expect(result.denied?).to be true
        expect(result.reason).to eq("User declined")
      end

      it "denies when user responds with invalid input" do
        input_io.string = "maybe\n"
        input_io.rewind

        result = confirmer.confirm_overwrite(test_file.path)

        expect(result.denied?).to be true
        expect(result.reason).to eq("Invalid response (treated as decline)")
      end

      it "displays appropriate prompt" do
        input_io.string = "n\n"
        input_io.rewind

        confirmer.confirm_overwrite(test_file.path)

        output_io.rewind
        prompt = output_io.read
        expect(prompt).to include("already exists")
        expect(prompt).to include("Overwrite?")
        expect(prompt).to include("[y/N]")
      end

      it "handles prompt errors gracefully" do
        # Simulate an error during input reading
        allow(input_io).to receive(:gets).and_raise(StandardError.new("Input error"))

        result = confirmer.confirm_overwrite(test_file.path)

        expect(result.denied?).to be true
        expect(result.auto_decision?).to be true
        expect(result.reason).to include("Prompt error")

        expect(security_logger).to have_received(:log_error)
      end
    end

    context "interactive confirmation metadata" do
      before do
        allow(confirmer).to receive(:interactive_environment?).and_return(true)
      end

      it "logs confirmation with interactive metadata" do
        input_io.string = "y\n"
        input_io.rewind

        confirmer.confirm_overwrite(test_file.path)

        expect(security_logger).to have_received(:log_event).with(
          :overwrite_confirmed,
          hash_including(metadata: hash_including(interactive: true))
        )
      end

      it "logs denial with interactive metadata" do
        input_io.string = "n\n"
        input_io.rewind

        confirmer.confirm_overwrite(test_file.path)

        expect(security_logger).to have_received(:log_event).with(
          :overwrite_denied,
          hash_including(metadata: hash_including(interactive: true))
        )
      end
    end
  end

  describe "#interactive_environment?" do
    let(:real_confirmer) { described_class.new(security_logger: security_logger) }

    context "with TTY" do
      before do
        allow($stdin).to receive(:tty?).and_return(true)
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "returns true when no CI environment detected" do
        # Clear CI environment variables
        ci_vars = ["CI", "GITHUB_ACTIONS", "GITLAB_CI", "TRAVIS", "CIRCLECI"]
        ci_vars.each { |var| allow(ENV).to receive(:[]).with(var).and_return(nil) }
        allow(ENV).to receive(:[]).with("CONTINUOUS_INTEGRATION").and_return(nil)
        allow(ENV).to receive(:[]).with("JENKINS_URL").and_return(nil)
        allow(ENV).to receive(:[]).with("BUILDKITE").and_return(nil)
        allow(ENV).to receive(:[]).with("DRONE").and_return(nil)

        expect(real_confirmer.interactive_environment?).to be true
      end

      it "returns false when CI environment detected" do
        allow(ENV).to receive(:[]).with("CI").and_return("true")

        expect(real_confirmer.interactive_environment?).to be false
      end

      it "detects various CI environments" do
        ci_environments = {
          "CI" => "true",
          "CONTINUOUS_INTEGRATION" => "true",
          "GITHUB_ACTIONS" => "true",
          "GITLAB_CI" => "true",
          "TRAVIS" => "true",
          "CIRCLECI" => "true",
          "JENKINS_URL" => "http://jenkins.example.com",
          "BUILDKITE" => "true",
          "DRONE" => "true"
        }

        ci_environments.each do |env_var, value|
          # Clear all other CI vars
          ci_environments.keys.each do |var|
            allow(ENV).to receive(:[]).with(var).and_return((var == env_var) ? value : nil)
          end

          expect(real_confirmer.interactive_environment?).to be(false),
            "Expected #{env_var}=#{value} to be detected as CI environment"
        end
      end
    end

    context "without TTY" do
      before do
        allow($stdin).to receive(:tty?).and_return(false)
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "returns false when not in TTY" do
        expect(real_confirmer.interactive_environment?).to be false
      end
    end

    context "with partial TTY" do
      it "returns false when only stdin is TTY" do
        allow($stdin).to receive(:tty?).and_return(true)
        allow($stdout).to receive(:tty?).and_return(false)

        expect(real_confirmer.interactive_environment?).to be false
      end

      it "returns false when only stdout is TTY" do
        allow($stdin).to receive(:tty?).and_return(false)
        allow($stdout).to receive(:tty?).and_return(true)

        expect(real_confirmer.interactive_environment?).to be false
      end
    end
  end

  describe "ConfirmationResult" do
    it "provides convenience methods" do
      confirmed_result = described_class::ConfirmationResult.new(true, "reason", false)
      expect(confirmed_result.confirmed?).to be true
      expect(confirmed_result.denied?).to be false

      denied_result = described_class::ConfirmationResult.new(false, "reason", true)
      expect(denied_result.confirmed?).to be false
      expect(denied_result.denied?).to be true
      expect(denied_result.auto_decision?).to be true
    end
  end
end
