# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::CodeQuality::MarkdownLintingPipeline do
  let(:mock_path_resolver) do
    double("PathResolver").tap do |resolver|
      allow(resolver).to receive(:project_root).and_return("/project/root")
      allow(resolver).to receive(:resolve).with(".").and_return("/project/root")
      allow(resolver).to receive(:resolve).with("docs").and_return("/project/root/docs")
      allow(resolver).to receive(:resolve).with("README.md").and_return("/project/root/README.md")
      allow(resolver).to receive(:resolve).with("script.rb").and_return("/project/root/script.rb")
      allow(resolver).to receive(:resolve).with("/outside/file.md").and_return("/outside/file.md")
      # Default stub for any other paths
      allow(resolver).to receive(:resolve) do |path|
        if path.start_with?("/")
          path  # Return absolute paths as-is
        elsif path == "."
          "/project/root"
        else
          "/project/root/#{path}"  # Make relative paths absolute
        end
      end
    end
  end

  let(:mock_task_validator) { instance_double(CodingAgentTools::Atoms::CodeQuality::TaskMetadataValidator) }
  let(:mock_link_validator) { instance_double(CodingAgentTools::Atoms::CodeQuality::MarkdownLinkValidator) }
  let(:mock_template_validator) { instance_double(CodingAgentTools::Atoms::CodeQuality::TemplateEmbeddingValidator) }
  let(:mock_kramdown_formatter) { instance_double(CodingAgentTools::Atoms::CodeQuality::KramdownFormatter) }

  let(:basic_config) do
    {
      "markdown" => {
        "enabled" => true,
        "linters" => {
          "task_metadata" => {"enabled" => true},
          "link_validation" => {"enabled" => true},
          "template_embedding" => {"enabled" => true},
          "styleguide" => {"enabled" => true}
        },
        "order" => ["task_metadata", "link_validation", "template_embedding", "styleguide"]
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
    context "when markdown linting is disabled" do
      let(:disabled_config) do
        {"markdown" => {"enabled" => false}}
      end
      let(:disabled_pipeline) { described_class.new(config: disabled_config, path_resolver: mock_path_resolver) }

      it "returns success without running any linters" do
        result = disabled_pipeline.run

        expect(result[:success]).to be true
        expect(result[:linters]).to eq({})
        expect(result[:total_issues]).to eq(0)
      end
    end

    context "when markdown linting is enabled but no markdown config" do
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
        allow(CodingAgentTools::Atoms::CodeQuality::TaskMetadataValidator).to receive(:new).and_return(mock_task_validator)
        allow(CodingAgentTools::Atoms::CodeQuality::MarkdownLinkValidator).to receive(:new).and_return(mock_link_validator)
        allow(CodingAgentTools::Atoms::CodeQuality::TemplateEmbeddingValidator).to receive(:new).and_return(mock_template_validator)
        allow(CodingAgentTools::Atoms::CodeQuality::KramdownFormatter).to receive(:new).and_return(mock_kramdown_formatter)

        # Mock successful validator results
        allow(mock_task_validator).to receive(:validate).and_return({
          success: true,
          errors: []
        })

        allow(mock_link_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        allow(mock_template_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        # Mock file system operations for styleguide
        allow(File).to receive(:directory?).and_return(false)
        allow(Dir).to receive(:glob).and_return([])
        allow(mock_kramdown_formatter).to receive(:format_file).and_return({changed: false})
      end

      it "runs all enabled linters in specified order" do
        result = pipeline.run

        expect(result[:success]).to be true
        expect(result[:linters]).to have_key(:task_metadata)
        expect(result[:linters]).to have_key(:link_validation)
        expect(result[:linters]).to have_key(:template_embedding)
        expect(result[:linters]).to have_key(:styleguide)
        expect(result[:total_issues]).to eq(0)
      end

      it "passes resolved paths to validators" do
        paths = ["docs", "README.md"]
        expected_resolved_paths = ["/project/root/docs", "/project/root/README.md"]

        # Since we're calling run with paths, it will resolve each path
        expect(mock_task_validator).to receive(:validate).with(expected_resolved_paths)
        expect(mock_link_validator).to receive(:validate).with(expected_resolved_paths)
        expect(mock_template_validator).to receive(:validate).with(expected_resolved_paths)

        pipeline.run(paths: paths)
      end

      it "counts total issues from all linters" do
        allow(mock_task_validator).to receive(:validate).and_return({
          success: true,
          errors: [{message: "Invalid metadata"}]
        })

        allow(mock_link_validator).to receive(:validate).and_return({
          success: true,
          findings: [{message: "Broken link"}, {message: "Another broken link"}]
        })

        allow(mock_template_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        result = pipeline.run

        expect(result[:total_issues]).to eq(3) # 1 + 2 + 0 + 0
      end
    end

    context "with selective linter enablement" do
      let(:selective_config) do
        {
          "markdown" => {
            "enabled" => true,
            "linters" => {
              "task_metadata" => {"enabled" => true},
              "link_validation" => {"enabled" => false},
              "template_embedding" => {"enabled" => true},
              "styleguide" => {"enabled" => false}
            }
          }
        }
      end

      let(:selective_pipeline) { described_class.new(config: selective_config, path_resolver: mock_path_resolver) }

      before do
        allow(CodingAgentTools::Atoms::CodeQuality::TaskMetadataValidator).to receive(:new).and_return(mock_task_validator)
        allow(CodingAgentTools::Atoms::CodeQuality::TemplateEmbeddingValidator).to receive(:new).and_return(mock_template_validator)

        allow(mock_task_validator).to receive(:validate).and_return({success: true, errors: []})
        allow(mock_template_validator).to receive(:validate).and_return({success: true, findings: []})
      end

      it "only runs enabled linters" do
        result = selective_pipeline.run

        expect(result[:linters]).to have_key(:task_metadata)
        expect(result[:linters]).to have_key(:template_embedding)
        expect(result[:linters]).not_to have_key(:link_validation)
        expect(result[:linters]).not_to have_key(:styleguide)
      end
    end

    context "with custom linter order" do
      let(:custom_order_config) do
        basic_config.merge(
          "markdown" => basic_config["markdown"].merge(
            "order" => ["styleguide", "task_metadata"]
          )
        )
      end

      let(:custom_pipeline) { described_class.new(config: custom_order_config, path_resolver: mock_path_resolver) }

      before do
        allow(CodingAgentTools::Atoms::CodeQuality::TaskMetadataValidator).to receive(:new).and_return(mock_task_validator)
        allow(CodingAgentTools::Atoms::CodeQuality::KramdownFormatter).to receive(:new).and_return(mock_kramdown_formatter)

        allow(mock_task_validator).to receive(:validate).and_return({success: true, errors: []})
        allow(File).to receive(:directory?).and_return(false)
        allow(Dir).to receive(:glob).and_return([])
      end

      it "respects custom linter order" do
        # We can verify order by checking the order of keys in results
        result = custom_pipeline.run

        linter_keys = result[:linters].keys
        expect(linter_keys.index(:styleguide)).to be < linter_keys.index(:task_metadata)
      end
    end
  end

  describe "individual linter methods" do
    context "#run_task_metadata" do
      before do
        allow(CodingAgentTools::Atoms::CodeQuality::TaskMetadataValidator).to receive(:new)
          .with(project_root: "/project/root")
          .and_return(mock_task_validator)
      end

      it "runs task metadata validation successfully" do
        allow(mock_task_validator).to receive(:validate).and_return({
          success: true,
          errors: []
        })

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_task_metadata, ["."], results)

        expect(results[:linters][:task_metadata]).to eq({success: true, errors: []})
        expect(results[:success]).to be true
        expect(results[:total_issues]).to eq(0)
      end

      it "handles validation errors" do
        allow(mock_task_validator).to receive(:validate).and_return({
          success: false,
          errors: [{message: "Invalid task metadata"}]
        })

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_task_metadata, ["."], results)

        expect(results[:linters][:task_metadata][:success]).to be false
        expect(results[:success]).to be false
        expect(results[:total_issues]).to eq(1)
      end

      it "handles validator exceptions" do
        allow(mock_task_validator).to receive(:validate).and_raise(StandardError.new("Validator crashed"))

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_task_metadata, ["."], results)

        expect(results[:linters][:task_metadata][:success]).to be false
        expect(results[:linters][:task_metadata][:error]).to eq("Validator crashed")
        expect(results[:success]).to be false
      end
    end

    context "#run_link_validation" do
      before do
        allow(CodingAgentTools::Atoms::CodeQuality::MarkdownLinkValidator).to receive(:new)
          .with(root: "/project/root")
          .and_return(mock_link_validator)
      end

      it "runs link validation successfully" do
        allow(mock_link_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_link_validation, ["."], results)

        expect(results[:linters][:link_validation]).to eq({success: true, findings: []})
        expect(results[:success]).to be true
        expect(results[:total_issues]).to eq(0)
      end

      it "counts findings as issues" do
        allow(mock_link_validator).to receive(:validate).and_return({
          success: true,
          findings: [
            {message: "Broken link 1"},
            {message: "Broken link 2"}
          ]
        })

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_link_validation, ["."], results)

        expect(results[:total_issues]).to eq(2)
      end

      it "handles validator exceptions" do
        allow(mock_link_validator).to receive(:validate).and_raise(StandardError.new("Link validation failed"))

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_link_validation, ["."], results)

        expect(results[:linters][:link_validation][:success]).to be false
        expect(results[:linters][:link_validation][:error]).to eq("Link validation failed")
        expect(results[:success]).to be false
      end
    end

    context "#run_template_embedding" do
      before do
        allow(CodingAgentTools::Atoms::CodeQuality::TemplateEmbeddingValidator).to receive(:new)
          .and_return(mock_template_validator)
      end

      it "runs template embedding validation successfully" do
        allow(mock_template_validator).to receive(:validate).and_return({
          success: true,
          findings: []
        })

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_template_embedding, ["."], results)

        expect(results[:linters][:template_embedding]).to eq({success: true, findings: []})
        expect(results[:success]).to be true
        expect(results[:total_issues]).to eq(0)
      end

      it "counts findings as issues" do
        allow(mock_template_validator).to receive(:validate).and_return({
          success: true,
          findings: [{message: "Template issue"}]
        })

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_template_embedding, ["."], results)

        expect(results[:total_issues]).to eq(1)
      end

      it "handles validator exceptions" do
        allow(mock_template_validator).to receive(:validate).and_raise(StandardError.new("Template validation failed"))

        results = {success: true, linters: {}, total_issues: 0}
        pipeline.send(:run_template_embedding, ["."], results)

        expect(results[:linters][:template_embedding][:success]).to be false
        expect(results[:linters][:template_embedding][:error]).to eq("Template validation failed")
        expect(results[:success]).to be false
      end
    end

    context "#run_styleguide" do
      let(:styleguide_config) do
        {
          "markdown" => {
            "enabled" => true,
            "linters" => {
              "styleguide" => {
                "enabled" => true,
                "line_width" => 120,
                "hard_wrap" => true
              }
            }
          }
        }
      end

      let(:configured_pipeline) { described_class.new(config: styleguide_config, path_resolver: mock_path_resolver) }

      before do
        allow(CodingAgentTools::Atoms::CodeQuality::KramdownFormatter).to receive(:new).and_return(mock_kramdown_formatter)
      end

      context "with directory paths" do
        it "finds and processes markdown files in directories" do
          allow(File).to receive(:directory?).with("/project/root").and_return(true)
          allow(Dir).to receive(:glob).with("/project/root/**/*.md").and_return([
            "/project/root/README.md",
            "/project/root/docs/guide.md"
          ])

          allow(mock_kramdown_formatter).to receive(:format_file).and_return({changed: false})

          results = {success: true, linters: {}, total_issues: 0}
          configured_pipeline.send(:run_styleguide, ["."], false, results)

          expect(mock_kramdown_formatter).to have_received(:format_file).with("/project/root/README.md")
          expect(mock_kramdown_formatter).to have_received(:format_file).with("/project/root/docs/guide.md")
        end
      end

      context "with file paths" do
        it "processes markdown files directly" do
          allow(File).to receive(:directory?).with("/project/root/README.md").and_return(false)
          allow(mock_kramdown_formatter).to receive(:format_file).with("/project/root/README.md").and_return({changed: false})

          results = {success: true, linters: {}, total_issues: 0}
          configured_pipeline.send(:run_styleguide, ["README.md"], false, results)

          expect(mock_kramdown_formatter).to have_received(:format_file).with("/project/root/README.md")
        end

        it "ignores non-markdown files" do
          allow(File).to receive(:directory?).with("/project/root/script.rb").and_return(false)
          allow(mock_kramdown_formatter).to receive(:format_file).and_return({changed: false})

          results = {success: true, linters: {}, total_issues: 0}
          configured_pipeline.send(:run_styleguide, ["script.rb"], false, results)

          expect(mock_kramdown_formatter).not_to have_received(:format_file)
          expect(results[:linters][:styleguide][:total_files]).to eq(0)
        end
      end

      context "with autofix disabled (dry run)" do
        it "reports formatting changes needed without fixing" do
          allow(File).to receive(:directory?).with("/project/root/README.md").and_return(false)
          allow(mock_kramdown_formatter).to receive(:format_file).with("/project/root/README.md").and_return({
            changed: true,
            file_updated: false
          })

          results = {success: true, linters: {}, total_issues: 0}
          configured_pipeline.send(:run_styleguide, ["README.md"], false, results)

          expect(results[:linters][:styleguide][:findings]).to contain_exactly({
            file: "README.md",
            message: "Formatting changes needed",
            fixed: false
          })
          expect(results[:total_issues]).to eq(1)
        end
      end

      context "with autofix enabled" do
        it "applies formatting fixes" do
          allow(File).to receive(:directory?).with("/project/root/README.md").and_return(false)
          allow(mock_kramdown_formatter).to receive(:format_file).with("/project/root/README.md").and_return({
            changed: true,
            file_updated: true
          })

          results = {success: true, linters: {}, total_issues: 0}
          configured_pipeline.send(:run_styleguide, ["README.md"], true, results)

          expect(results[:linters][:styleguide][:findings]).to contain_exactly({
            file: "README.md",
            message: "Formatting changes needed",
            fixed: true
          })
          expect(results[:total_issues]).to eq(1)
        end
      end

      context "with styleguide configuration options" do
        it "passes configuration options to KramdownFormatter" do
          expected_options = {
            dry_run: true,
            line_width: 120,
            hard_wrap: true
          }

          expect(CodingAgentTools::Atoms::CodeQuality::KramdownFormatter).to receive(:new)
            .with(expected_options)
            .and_return(mock_kramdown_formatter)

          allow(File).to receive(:directory?).and_return(false)
          allow(mock_kramdown_formatter).to receive(:format_file).and_return({changed: false})

          results = {success: true, linters: {}, total_issues: 0}
          configured_pipeline.send(:run_styleguide, ["README.md"], false, results)
        end
      end

      it "handles relative path conversion" do
        allow(File).to receive(:directory?).with("/project/root/README.md").and_return(false)
        allow(mock_kramdown_formatter).to receive(:format_file).with("/project/root/README.md").and_return({
          changed: true,
          file_updated: false
        })

        results = {success: true, linters: {}, total_issues: 0}
        configured_pipeline.send(:run_styleguide, ["README.md"], false, results)

        finding = results[:linters][:styleguide][:findings].first
        expect(finding[:file]).to eq("README.md") # Should be relative to project root
      end

      it "handles files outside project root" do
        # Mock a file outside project root
        allow(mock_path_resolver).to receive(:resolve).with("/outside/file.md").and_return("/outside/file.md")
        allow(File).to receive(:directory?).and_return(false)
        allow(mock_kramdown_formatter).to receive(:format_file).with("/outside/file.md").and_return({
          changed: true,
          file_updated: false
        })

        results = {success: true, linters: {}, total_issues: 0}
        configured_pipeline.send(:run_styleguide, ["/outside/file.md"], false, results)

        finding = results[:linters][:styleguide][:findings].first
        expect(finding[:file]).to eq("/outside/file.md") # Should keep absolute path
      end

      it "handles formatter exceptions" do
        allow(File).to receive(:directory?).with("/project/root/README.md").and_return(false)
        allow(mock_kramdown_formatter).to receive(:format_file).with("/project/root/README.md").and_raise(StandardError.new("Formatter error"))

        results = {success: true, linters: {}, total_issues: 0}
        configured_pipeline.send(:run_styleguide, ["README.md"], false, results)

        expect(results[:linters][:styleguide][:success]).to be false
        expect(results[:linters][:styleguide][:error]).to eq("Formatter error")
        expect(results[:success]).to be false
      end
    end
  end

  describe "error handling and edge cases" do
    context "when linters fail" do
      before do
        allow(CodingAgentTools::Atoms::CodeQuality::TaskMetadataValidator).to receive(:new).and_return(mock_task_validator)
        allow(CodingAgentTools::Atoms::CodeQuality::MarkdownLinkValidator).to receive(:new).and_return(mock_link_validator)

        # Task metadata succeeds
        allow(mock_task_validator).to receive(:validate).and_return({success: true, errors: []})
        # Link validation fails
        allow(mock_link_validator).to receive(:validate).and_return({success: false, findings: []})
      end

      it "continues running other linters when one fails" do
        result = pipeline.run

        expect(result[:linters]).to have_key(:task_metadata)
        expect(result[:linters]).to have_key(:link_validation)
        expect(result[:linters][:task_metadata][:success]).to be true
        expect(result[:linters][:link_validation][:success]).to be false
        expect(result[:success]).to be false # Overall success is false due to one failure
      end
    end

    context "with missing configuration sections" do
      let(:minimal_config) do
        {
          "markdown" => {
            "enabled" => true
            # No linters or order specified
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

    context "with empty order configuration" do
      let(:empty_order_config) do
        {
          "markdown" => {
            "enabled" => true,
            "linters" => {
              "task_metadata" => {"enabled" => true}
            },
            "order" => []
          }
        }
      end

      let(:empty_order_pipeline) { described_class.new(config: empty_order_config, path_resolver: mock_path_resolver) }

      it "runs no linters when order is explicitly empty" do
        result = empty_order_pipeline.run

        expect(result[:linters]).to eq({})
        expect(result[:success]).to be true
        expect(result[:total_issues]).to eq(0)
      end
    end

    context "with no order configuration" do
      let(:no_order_config) do
        {
          "markdown" => {
            "enabled" => true,
            "linters" => {
              "task_metadata" => {"enabled" => true}
            }
            # No order specified - should default to linters.keys
          }
        }
      end

      let(:no_order_pipeline) { described_class.new(config: no_order_config, path_resolver: mock_path_resolver) }

      it "uses linter keys as default order when order is not specified" do
        allow(CodingAgentTools::Atoms::CodeQuality::TaskMetadataValidator).to receive(:new).and_return(mock_task_validator)
        allow(mock_task_validator).to receive(:validate).and_return({success: true, errors: []})

        result = no_order_pipeline.run

        expect(result[:linters]).to have_key(:task_metadata)
      end
    end
  end
end
