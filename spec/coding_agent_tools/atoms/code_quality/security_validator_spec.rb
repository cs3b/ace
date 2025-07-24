# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/code_quality/security_validator"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::SecurityValidator do
  subject { described_class.new(options) }
  let(:options) { {} }

  describe "#initialize" do
    context "with default options" do
      it "sets default options" do
        validator = described_class.new
        expect(validator.options[:full_scan]).to be false
        expect(validator.options[:git_history]).to be false
        expect(validator.options[:verbose]).to be false
      end
    end

    context "with custom options" do
      let(:options) { {full_scan: true, git_history: true, verbose: true} }

      it "merges custom options with defaults" do
        expect(subject.options[:full_scan]).to be true
        expect(subject.options[:git_history]).to be true
        expect(subject.options[:verbose]).to be true
      end
    end
  end

  describe "#validate" do
    let(:gitleaks_output) { "" }
    let(:exit_code) { 0 }

    before do
      # Mock gitleaks availability check
      allow(subject).to receive(:system).with("which gitleaks > /dev/null 2>&1").and_return(true)
      
      # Mock command execution
      allow(Open3).to receive(:capture3).and_return([gitleaks_output, "", double(exitstatus: exit_code)])
      
      # Mock config file existence
      allow(File).to receive(:exist?).with(".gitleaks.toml").and_return(false)
    end

    context "when gitleaks is available" do
      context "with no security issues found" do
        let(:gitleaks_output) { "INFO[0000] No leaks found" }
        let(:exit_code) { 0 }

        it "returns success result" do
          result = subject.validate
          
          expect(result[:success]).to be true
          expect(result[:findings]).to be_empty
          expect(result[:exit_code]).to eq(0)
          expect(result[:output]).to include("No leaks found")
        end

        it "executes gitleaks with correct default command" do
          expect(Open3).to receive(:capture3).with("gitleaks detect --no-git")
          subject.validate
        end
      end

      context "with security issues found" do
        let(:gitleaks_output) do
          <<~OUTPUT
            Finding: API key detected in file.rb
            Finding: Password found in config.yml
            ERROR[0001] leaks found
          OUTPUT
        end
        let(:exit_code) { 1 }

        it "returns failure result with findings" do
          result = subject.validate

          expect(result[:success]).to be false
          expect(result[:findings]).to include("API key detected in file.rb")
          expect(result[:findings]).to include("Password found in config.yml")
          expect(result[:exit_code]).to eq(1)
        end
      end

      context "with verbose option enabled" do
        let(:options) { {verbose: true} }

        it "includes verbose flag in command" do
          expect(Open3).to receive(:capture3).with("gitleaks detect --verbose --no-git")
          subject.validate
        end
      end

      context "with git history enabled" do
        let(:options) { {git_history: true} }

        it "omits --no-git flag from command" do
          expect(Open3).to receive(:capture3).with("gitleaks detect")
          subject.validate
        end
      end

      context "with gitleaks config file present" do
        before do
          allow(File).to receive(:exist?).with(".gitleaks.toml").and_return(true)
        end

        it "includes config file in command" do
          expect(Open3).to receive(:capture3).with("gitleaks detect --no-git --config .gitleaks.toml")
          subject.validate
        end
      end

      context "with combined options" do
        let(:options) { {verbose: true, git_history: true} }

        before do
          allow(File).to receive(:exist?).with(".gitleaks.toml").and_return(true)
        end

        it "builds complex command correctly" do
          expect(Open3).to receive(:capture3).with("gitleaks detect --verbose --config .gitleaks.toml")
          subject.validate
        end
      end
    end

    context "when gitleaks is not available" do
      before do
        allow(subject).to receive(:system).with("which gitleaks > /dev/null 2>&1").and_return(false)
      end

      it "raises an error with installation instructions" do
        expect { subject.validate }.to raise_error(/Gitleaks is not installed/)
      end

      it "includes installation instructions in error message" do
        expect { subject.validate }.to raise_error(/brew install gitleaks/)
      end
    end

    context "when command execution fails" do
      before do
        allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT, "gitleaks: command not found")
      end

      it "propagates the execution error" do
        expect { subject.validate }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe "#build_command" do
    let(:validator) { described_class.new(options) }

    before do
      allow(File).to receive(:exist?).with(".gitleaks.toml").and_return(config_file_exists)
    end

    let(:config_file_exists) { false }

    context "with default options" do
      let(:options) { {} }

      it "builds basic command" do
        expect(validator.send(:build_command)).to eq("gitleaks detect --no-git")
      end
    end

    context "with verbose enabled" do
      let(:options) { {verbose: true} }

      it "includes verbose flag" do
        expect(validator.send(:build_command)).to eq("gitleaks detect --verbose --no-git")
      end
    end

    context "with git history enabled" do
      let(:options) { {git_history: true} }

      it "omits --no-git flag" do
        expect(validator.send(:build_command)).to eq("gitleaks detect")
      end
    end

    context "with config file present" do
      let(:config_file_exists) { true }

      it "includes config file option" do
        expect(validator.send(:build_command)).to eq("gitleaks detect --no-git --config .gitleaks.toml")
      end
    end

    context "with all options and config file" do
      let(:options) { {verbose: true, git_history: true} }
      let(:config_file_exists) { true }

      it "builds complete command" do
        expect(validator.send(:build_command)).to eq("gitleaks detect --verbose --config .gitleaks.toml")
      end
    end
  end

  describe "#parse_results" do
    let(:validator) { described_class.new }

    context "with successful execution" do
      let(:output) { "INFO[0000] No leaks found" }
      let(:exit_code) { 0 }

      it "returns success result" do
        result = validator.send(:parse_results, output, exit_code)
        
        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
        expect(result[:exit_code]).to eq(0)
        expect(result[:output]).to eq(output)
      end
    end

    context "with findings in output" do
      let(:output) do
        <<~OUTPUT
          Finding: Potential API key in secrets.rb line 15
          Finding: Hardcoded password in config/database.yml line 8
          Finding: AWS access key in .env line 3
          ERROR[0003] leaks found
        OUTPUT
      end
      let(:exit_code) { 1 }

      it "extracts all findings" do
        result = validator.send(:parse_results, output, exit_code)
        
        expect(result[:success]).to be false
        expect(result[:findings]).to contain_exactly(
          "Potential API key in secrets.rb line 15",
          "Hardcoded password in config/database.yml line 8",
          "AWS access key in .env line 3"
        )
        expect(result[:exit_code]).to eq(1)
      end
    end

    context "with malformed output" do
      let(:output) { "Random output without findings format\nSome other text" }
      let(:exit_code) { 1 }

      it "handles malformed output gracefully" do
        result = validator.send(:parse_results, output, exit_code)
        
        expect(result[:success]).to be false
        expect(result[:findings]).to be_empty
        expect(result[:output]).to eq(output)
      end
    end

    context "with empty output" do
      let(:output) { "" }
      let(:exit_code) { 0 }

      it "handles empty output" do
        result = validator.send(:parse_results, output, exit_code)
        
        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
        expect(result[:output]).to be_empty
      end
    end
  end

  describe "edge cases and error conditions" do
    before do
      allow(subject).to receive(:system).with("which gitleaks > /dev/null 2>&1").and_return(true)
      allow(File).to receive(:exist?).with(".gitleaks.toml").and_return(false)
    end

    context "when gitleaks command times out" do
      before do
        allow(Open3).to receive(:capture3).and_raise(Timeout::Error, "execution expired")
      end

      it "propagates timeout error" do
        expect { subject.validate }.to raise_error(Timeout::Error)
      end
    end

    context "when gitleaks returns unexpected exit code" do
      let(:exit_code) { 2 }
      let(:output) { "ERROR[0000] Unexpected gitleaks error" }

      before do
        allow(Open3).to receive(:capture3).and_return([output, "", double(exitstatus: exit_code)])
      end

      it "returns failure result with unexpected exit code" do
        result = subject.validate
        
        expect(result[:success]).to be false
        expect(result[:exit_code]).to eq(2)
        expect(result[:output]).to include("Unexpected gitleaks error")
      end
    end

    context "with extremely large output" do
      let(:large_output) do
        (1..1000).map { |i| "Finding: Test finding #{i}" }.join("\n")
      end
      let(:exit_code) { 1 }

      before do
        allow(Open3).to receive(:capture3).and_return([large_output, "", double(exitstatus: exit_code)])
      end

      it "handles large number of findings" do
        result = subject.validate
        
        expect(result[:findings].length).to eq(1000)
        expect(result[:findings].first).to eq("Test finding 1")
        expect(result[:findings].last).to eq("Test finding 1000")
      end
    end
  end

  describe "integration with file system" do
    before do
      allow(subject).to receive(:system).with("which gitleaks > /dev/null 2>&1").and_return(true)
    end

    context "when config file path contains special characters" do
      before do
        allow(File).to receive(:exist?).with(".gitleaks.toml").and_return(false)
        # Test with a hypothetical config file with special characters
        allow(subject).to receive(:build_command).and_return("gitleaks detect --config 'special file.toml' --no-git")
        allow(Open3).to receive(:capture3).and_return(["INFO: scan complete", "", double(exitstatus: 0)])
      end

      it "handles special characters in file paths" do
        expect { subject.validate }.not_to raise_error
      end
    end
  end
end