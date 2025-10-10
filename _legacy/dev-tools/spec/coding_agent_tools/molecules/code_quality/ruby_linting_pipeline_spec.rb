# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::CodeQuality::RubyLintingPipeline do
  let(:mock_path_resolver) do
    double("PathResolver").tap do |resolver|
      allow(resolver).to receive(:resolve).with(".").and_return("/project/root")
      allow(resolver).to receive(:resolve).with("lib").and_return("/project/root/lib")
      allow(resolver).to receive(:resolve).with("spec").and_return("/project/root/spec")
      # Default stub for any other paths
      allow(resolver).to receive(:resolve) do |path|
        if path.start_with?("/")
          path  # Return absolute paths as-is
        else
          "/project/root/#{path}"  # Make relative paths absolute
        end
      end
    end
  end

  let(:mock_standard_validator) { instance_double(CodingAgentTools::Atoms::CodeQuality::StandardRbValidator) }
  let(:mock_security_validator) { instance_double(CodingAgentTools::Atoms::CodeQuality::SecurityValidator) }
  let(:mock_cassettes_validator) { instance_double(CodingAgentTools::Atoms::CodeQuality::CassettesValidator) }

  let(:basic_config) do
    {
      "ruby" => {
        "enabled" => true,
        "linters" => {
          "standardrb" => {"enabled" => true, "autofix" => false},
          "security" => {"enabled" => true, "full_scan" => false, "git_history" => false},
          "cassettes" => {"enabled" => true, "threshold" => 51_200}
        }
      }
    }
  end

  subject(:pipeline) { described_class.new(config: basic_config, path_resolver: mock_path_resolver) }

  describe "#initialize" do
    it "sets config and path_resolver" do
      expect(pipeline.config).to eq(basic_config)
      expect(pipeline.path_resolver).to eq(mock_path_resolver)
    end
  end

  describe "#run" do
    context "when ruby linting is disabled" do
      let(:disabled_config) do
        {"ruby" => {"enabled" => false}}
      end
      let(:disabled_pipeline) { described_class.new(config: disabled_config, path_resolver: mock_path_resolver) }

      it "returns success without running any linters" do
        result = disabled_pipeline.run

        expect(result[:success]).to be true
        expect(result[:linters]).to eq({})
        expect(result[:total_issues]).to eq(0)
      end
    end

    context "when ruby linting is enabled but no ruby config" do
      let(:empty_config) { {} }
      let(:empty_pipeline) { described_class.new(config: empty_config, path_resolver: mock_path_resolver) }

      it "returns success without running any linters" do
        result = empty_pipeline.run

        expect(result[:success]).to be true
        expect(result[:linters]).to eq({})
        expect(result[:total_issues]).to eq(0)
      end
    end

    context "with all linters enabled" do
      before do
        # Mock all atom validators
        allow(CodingAgentTools::Atoms::CodeQuality::StandardRbValidator).to receive(:new).and_return(mock_standard_validator)
        allow(CodingAgentTools::Atoms::CodeQuality::SecurityValidator).to receive(:new).and_return(mock_security_validator)
        allow(CodingAgentTools::Atoms::CodeQuality::CassettesValidator).to receive(:new).and_return(mock_cassettes_validator)

        # Mock successful validator results
        allow(mock_standard_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        allow(mock_security_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        allow(mock_cassettes_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })
      end

      it "runs all enabled linters" do
        result = pipeline.run

        expect(result[:success]).to be true
        expect(result[:linters]).to have_key(:standardrb)
        expect(result[:linters]).to have_key(:security)
        expect(result[:linters]).to have_key(:cassettes)
        expect(result[:total_issues]).to eq(0)
      end

      it "passes resolved paths to standardrb validator" do
        paths = ["lib", "spec"]
        expected_resolved_paths = ["/project/root/lib", "/project/root/spec"]

        expect(mock_standard_validator).to receive(:validate).with(expected_resolved_paths)

        pipeline.run(paths: paths)
      end

      it "counts total issues from all linters" do
        allow(mock_standard_validator).to receive(:validate).and_return({
          success: true,
          findings: [{message: "Style violation"}]
        })

        allow(mock_security_validator).to receive(:validate).and_return({
          success: true,
          findings: [{message: "Secret detected"}, {message: "Another secret"}]
        })

        allow(mock_cassettes_validator).to receive(:validate).and_return({
          success: true,
          findings: [{message: "Large cassette"}]
        })

        result = pipeline.run

        expect(result[:total_issues]).to eq(4) # 1 + 2 + 1
      end
    end

    context "with selective linter enablement" do
      let(:selective_config) do
        {
          "ruby" => {
            "enabled" => true,
            "linters" => {
              "standardrb" => {"enabled" => true},
              "security" => {"enabled" => false},
              "cassettes" => {"enabled" => true}
            }
          }
        }
      end

      let(:selective_pipeline) { described_class.new(config: selective_config, path_resolver: mock_path_resolver) }

      before do
        allow(CodingAgentTools::Atoms::CodeQuality::StandardRbValidator).to receive(:new).and_return(mock_standard_validator)
        allow(CodingAgentTools::Atoms::CodeQuality::CassettesValidator).to receive(:new).and_return(mock_cassettes_validator)

        allow(mock_standard_validator).to receive(:validate).and_return({success: true, findings: []})
        allow(mock_cassettes_validator).to receive(:validate).and_return({success: true, findings: []})
      end

      it "only runs enabled linters" do
        result = selective_pipeline.run

        expect(result[:linters]).to have_key(:standardrb)
        expect(result[:linters]).to have_key(:cassettes)
        expect(result[:linters]).not_to have_key(:security)
      end
    end

    context "with autofix enabled" do
      let(:autofix_config) do
        {
          "ruby" => {
            "enabled" => true,
            "linters" => {
              "standardrb" => {"enabled" => true, "autofix" => true}
            }
          }
        }
      end

      let(:autofix_pipeline) { described_class.new(config: autofix_config, path_resolver: mock_path_resolver) }

      before do
        allow(CodingAgentTools::Atoms::CodeQuality::StandardRbValidator).to receive(:new).and_return(mock_standard_validator)
      end

      it "calls autofix when enabled and autofix flag is true" do
        allow(mock_standard_validator).to receive(:autofix).and_return({success: true, findings: []})
        allow(mock_standard_validator).to receive(:validate).and_return({success: true, findings: []})

        autofix_pipeline.run(autofix: true)

        expect(mock_standard_validator).to have_received(:autofix)
      end

      it "calls validate when autofix is enabled but autofix flag is false" do
        allow(mock_standard_validator).to receive(:validate).and_return({success: true, findings: []})
        allow(mock_standard_validator).to receive(:autofix).and_return({success: true, findings: []})

        autofix_pipeline.run(autofix: false)

        expect(mock_standard_validator).to have_received(:validate)
      end
    end
  end

  describe "individual linter methods" do
    context "#run_standardrb" do
      let(:autofix_enabled_config) do
        {
          "ruby" => {
            "enabled" => true,
            "linters" => {
              "standardrb" => {"enabled" => true, "autofix" => true}
            }
          }
        }
      end

      let(:autofix_disabled_config) do
        {
          "ruby" => {
            "enabled" => true,
            "linters" => {
              "standardrb" => {"enabled" => true, "autofix" => false}
            }
          }
        }
      end

      before do
        allow(CodingAgentTools::Atoms::CodeQuality::StandardRbValidator).to receive(:new).and_return(mock_standard_validator)
      end

      it "runs StandardRB validation successfully" do
        allow(mock_standard_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_standardrb, ["."], false, results)

        expect(results[:linters][:standardrb]).to eq({success: true, findings: []})
        expect(results[:success]).to be true
        expect(results[:total_issues]).to eq(0)
      end

      it "runs StandardRB autofix when enabled" do
        autofix_pipeline = described_class.new(config: autofix_enabled_config, path_resolver: mock_path_resolver)

        allow(mock_standard_validator).to receive(:autofix).and_return({
          success: true,
          findings: []
        })
        allow(mock_standard_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        results = {success: true, linters: {}, total_issues: 0}
        autofix_pipeline.send(:run_standardrb, ["."], true, results)

        expect(mock_standard_validator).to have_received(:autofix)
        expect(results[:linters][:standardrb]).to eq({success: true, findings: []})
      end

      it "uses validate when autofix is disabled in config" do
        autofix_disabled_pipeline = described_class.new(config: autofix_disabled_config, path_resolver: mock_path_resolver)

        allow(mock_standard_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        results = {success: true, linters: {}, total_issues: 0}
        autofix_disabled_pipeline.send(:run_standardrb, ["."], true, results)

        expect(mock_standard_validator).to have_received(:validate)
        expect(results[:linters][:standardrb]).to eq({success: true, findings: []})
      end

      it "handles validation errors" do
        allow(mock_standard_validator).to receive(:validate).and_return({
          success: false,
          findings: [{message: "Style violation"}]
        })

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_standardrb, ["."], false, results)

        expect(results[:linters][:standardrb][:success]).to be false
        expect(results[:success]).to be false
        expect(results[:total_issues]).to eq(1)
      end

      it "handles validator exceptions" do
        allow(mock_standard_validator).to receive(:validate).and_raise(StandardError.new("StandardRB crashed"))

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_standardrb, ["."], false, results)

        expect(results[:linters][:standardrb][:success]).to be false
        expect(results[:linters][:standardrb][:error]).to eq("StandardRB crashed")
        expect(results[:success]).to be false
      end

      it "resolves paths correctly" do
        paths = ["lib", "spec"]
        expected_resolved_paths = ["/project/root/lib", "/project/root/spec"]

        allow(mock_standard_validator).to receive(:validate).with(expected_resolved_paths).and_return({
          success: true,
          findings: []
        })

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_standardrb, paths, false, results)

        expect(mock_standard_validator).to have_received(:validate).with(expected_resolved_paths)
      end
    end

    context "#run_security" do
      let(:security_options) do
        {
          full_scan: false,
          git_history: false
        }
      end

      before do
        allow(CodingAgentTools::Atoms::CodeQuality::SecurityValidator).to receive(:new)
          .with(security_options)
          .and_return(mock_security_validator)
      end

      it "runs security validation successfully" do
        allow(mock_security_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        results = {success: true, linters: {}, total_issues: 0}
        security_config = {"full_scan" => false, "git_history" => false}
        pipeline.send(:run_security, ["."], security_config, results)

        expect(results[:linters][:security]).to eq({success: true, findings: []})
        expect(results[:success]).to be true
        expect(results[:total_issues]).to eq(0)
      end

      it "passes security configuration options" do
        custom_security_config = {"full_scan" => true, "git_history" => true}
        custom_options = {full_scan: true, git_history: true}

        expect(CodingAgentTools::Atoms::CodeQuality::SecurityValidator).to receive(:new)
          .with(custom_options)
          .and_return(mock_security_validator)

        allow(mock_security_validator).to receive(:validate).and_return({success: true, findings: []})

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_security, ["."], custom_security_config, results)
      end

      it "counts findings as issues" do
        allow(mock_security_validator).to receive(:validate).and_return({
          success: true,
          findings: [
            {message: "Secret 1"},
            {message: "Secret 2"}
          ]
        })

        results = {success: true, linters: {}, total_issues: 0}
        security_config = {"full_scan" => false, "git_history" => false}
        pipeline.send(:run_security, ["."], security_config, results)

        expect(results[:total_issues]).to eq(2)
      end

      it "handles validator exceptions" do
        allow(mock_security_validator).to receive(:validate).and_raise(StandardError.new("Security scan failed"))

        results = {success: true, linters: {}, total_issues: 0}
        security_config = {"full_scan" => false, "git_history" => false}
        pipeline.send(:run_security, ["."], security_config, results)

        expect(results[:linters][:security][:success]).to be false
        expect(results[:linters][:security][:error]).to eq("Security scan failed")
        expect(results[:success]).to be false
      end
    end

    context "#run_cassettes" do
      let(:cassettes_options) do
        {
          threshold: 51_200
        }
      end

      before do
        allow(CodingAgentTools::Atoms::CodeQuality::CassettesValidator).to receive(:new)
          .with(cassettes_options)
          .and_return(mock_cassettes_validator)
      end

      it "runs cassettes validation successfully" do
        allow(mock_cassettes_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        results = {success: true, linters: {}, total_issues: 0}
        cassettes_config = {"threshold" => 51_200}
        pipeline.send(:run_cassettes, cassettes_config, results)

        expect(results[:linters][:cassettes]).to eq({success: true, findings: []})
        expect(results[:success]).to be true  # Cassettes doesn't affect overall success
        expect(results[:total_issues]).to eq(0)
      end

      it "uses default threshold when not specified" do
        default_options = {threshold: 51_200}

        expect(CodingAgentTools::Atoms::CodeQuality::CassettesValidator).to receive(:new)
          .with(default_options)
          .and_return(mock_cassettes_validator)

        allow(mock_cassettes_validator).to receive(:validate).and_return({success: true, findings: []})

        results = {success: true, linters: {}, total_issues: 0}
        cassettes_config = {}
        pipeline.send(:run_cassettes, cassettes_config, results)
      end

      it "uses custom threshold when specified" do
        custom_threshold = 102_400
        custom_options = {threshold: custom_threshold}

        expect(CodingAgentTools::Atoms::CodeQuality::CassettesValidator).to receive(:new)
          .with(custom_options)
          .and_return(mock_cassettes_validator)

        allow(mock_cassettes_validator).to receive(:validate).and_return({success: true, findings: []})

        results = {success: true, linters: {}, total_issues: 0}
        cassettes_config = {"threshold" => custom_threshold}
        pipeline.send(:run_cassettes, cassettes_config, results)
      end

      it "counts findings as issues but doesn't affect overall success" do
        allow(mock_cassettes_validator).to receive(:validate).and_return({
          success: true,
          findings: [{message: "Large cassette found"}]
        })

        results = {success: true, linters: {}, total_issues: 0}
        cassettes_config = {"threshold" => 51_200}
        pipeline.send(:run_cassettes, cassettes_config, results)

        expect(results[:total_issues]).to eq(1)
        expect(results[:success]).to be true  # Cassettes validator only warns
      end

      it "handles validator exceptions" do
        allow(mock_cassettes_validator).to receive(:validate).and_raise(StandardError.new("Cassettes validation failed"))

        results = {success: true, linters: {}, total_issues: 0}
        cassettes_config = {"threshold" => 51_200}
        pipeline.send(:run_cassettes, cassettes_config, results)

        expect(results[:linters][:cassettes][:success]).to be false
        expect(results[:linters][:cassettes][:error]).to eq("Cassettes validation failed")
        expect(results[:success]).to be true  # Cassettes errors don't affect overall success
      end
    end
  end

  describe "error handling and edge cases" do
    context "when linters fail" do
      before do
        allow(CodingAgentTools::Atoms::CodeQuality::StandardRbValidator).to receive(:new).and_return(mock_standard_validator)
        allow(CodingAgentTools::Atoms::CodeQuality::SecurityValidator).to receive(:new).and_return(mock_security_validator)

        # StandardRB succeeds
        allow(mock_standard_validator).to receive(:validate).and_return({success: true, findings: []})
        # Security fails
        allow(mock_security_validator).to receive(:validate).and_return({success: false, findings: []})
      end

      it "continues running other linters when one fails" do
        result = pipeline.run

        expect(result[:linters]).to have_key(:standardrb)
        expect(result[:linters]).to have_key(:security)
        expect(result[:linters][:standardrb][:success]).to be true
        expect(result[:linters][:security][:success]).to be false
        expect(result[:success]).to be false # Overall success is false due to one failure
      end
    end

    context "with missing configuration sections" do
      let(:minimal_config) do
        {
          "ruby" => {
            "enabled" => true
            # No linters specified
          }
        }
      end

      let(:minimal_pipeline) { described_class.new(config: minimal_config, path_resolver: mock_path_resolver) }

      it "handles missing linters configuration gracefully" do
        result = minimal_pipeline.run

        expect(result[:success]).to be true
        expect(result[:linters]).to eq({})
        expect(result[:total_issues]).to eq(0)
      end
    end

    context "with partial linter configuration" do
      let(:partial_config) do
        {
          "ruby" => {
            "enabled" => true,
            "linters" => {
              "standardrb" => {"enabled" => true}
              # Only standardrb specified, others should use defaults
            }
          }
        }
      end

      let(:partial_pipeline) { described_class.new(config: partial_config, path_resolver: mock_path_resolver) }

      before do
        allow(CodingAgentTools::Atoms::CodeQuality::StandardRbValidator).to receive(:new).and_return(mock_standard_validator)
        allow(mock_standard_validator).to receive(:validate).and_return({success: true, findings: []})
      end

      it "only runs explicitly enabled linters" do
        result = partial_pipeline.run

        expect(result[:linters]).to have_key(:standardrb)
        expect(result[:linters]).not_to have_key(:security)
        expect(result[:linters]).not_to have_key(:cassettes)
      end
    end
  end

  describe "result structure" do
    before do
      allow(CodingAgentTools::Atoms::CodeQuality::StandardRbValidator).to receive(:new).and_return(mock_standard_validator)
      allow(mock_standard_validator).to receive(:validate).and_return({success: true, findings: []})
    end

    it "returns expected result structure" do
      result = pipeline.run

      expect(result).to have_key(:success)
      expect(result).to have_key(:linters)
      expect(result).to have_key(:total_issues)

      expect(result[:success]).to be_a(TrueClass).or be_a(FalseClass)
      expect(result[:linters]).to be_a(Hash)
      expect(result[:total_issues]).to be_a(Integer)
    end

    it "includes linter-specific results" do
      result = pipeline.run

      result[:linters].each_value do |linter_result|
        expect(linter_result).to have_key(:success)
        expect(linter_result).to have_key(:findings)
      end
    end
  end
end
