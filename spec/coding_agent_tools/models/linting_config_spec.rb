# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/linting_config"

RSpec.describe CodingAgentTools::Models::LintingConfig do
  let(:custom_ruby_config) do
    {
      enabled: true,
      linters: {
        standardrb: {enabled: true, autofix: false},
        security: {enabled: false},
        cassettes: {enabled: true}
      }
    }
  end

  let(:custom_markdown_config) do
    {
      enabled: false,
      linters: {
        styleguide: {enabled: false, autofix: false},
        link_validation: {enabled: true},
        template_embedding: {enabled: false},
        task_metadata: {enabled: true}
      }
    }
  end

  let(:custom_error_distribution) do
    {
      enabled: false,
      max_files: 10,
      one_issue_per_file: false
    }
  end

  let(:custom_global_settings) do
    {timeout: 30, verbose: true}
  end

  describe "#initialize" do
    it "creates a new linting config with default values" do
      config = described_class.new

      expect(config.ruby).to be_a(Hash)
      expect(config.markdown).to be_a(Hash)
      expect(config.error_distribution).to be_a(Hash)
      expect(config.global_settings).to eq({})
    end

    it "creates a new linting config with custom values" do
      config = described_class.new(
        ruby: custom_ruby_config,
        markdown: custom_markdown_config,
        error_distribution: custom_error_distribution,
        global_settings: custom_global_settings
      )

      expect(config.ruby).to eq(custom_ruby_config)
      expect(config.markdown).to eq(custom_markdown_config)
      expect(config.error_distribution).to eq(custom_error_distribution)
      expect(config.global_settings).to eq(custom_global_settings)
    end

    it "uses default ruby config when not provided" do
      config = described_class.new

      expect(config.ruby[:enabled]).to be(true)
      expect(config.ruby[:linters]).to be_a(Hash)
      expect(config.ruby[:linters]).to have_key(:standardrb)
      expect(config.ruby[:linters]).to have_key(:security)
      expect(config.ruby[:linters]).to have_key(:cassettes)
    end

    it "uses default markdown config when not provided" do
      config = described_class.new

      expect(config.markdown[:enabled]).to be(true)
      expect(config.markdown[:linters]).to be_a(Hash)
      expect(config.markdown[:linters]).to have_key(:styleguide)
      expect(config.markdown[:linters]).to have_key(:link_validation)
      expect(config.markdown[:linters]).to have_key(:template_embedding)
      expect(config.markdown[:linters]).to have_key(:task_metadata)
    end

    it "uses default error distribution when not provided" do
      config = described_class.new

      expect(config.error_distribution[:enabled]).to be(true)
      expect(config.error_distribution[:max_files]).to eq(4)
      expect(config.error_distribution[:one_issue_per_file]).to be(true)
    end
  end

  describe "default ruby configuration" do
    let(:config) { described_class.new }

    it "enables ruby linting by default" do
      expect(config.ruby[:enabled]).to be(true)
    end

    it "configures standardrb linter correctly" do
      standardrb = config.ruby[:linters][:standardrb]
      expect(standardrb[:enabled]).to be(true)
      expect(standardrb[:autofix]).to be(true)
    end

    it "configures security linter correctly" do
      security = config.ruby[:linters][:security]
      expect(security[:enabled]).to be(true)
      expect(security).not_to have_key(:autofix)
    end

    it "configures cassettes linter correctly" do
      cassettes = config.ruby[:linters][:cassettes]
      expect(cassettes[:enabled]).to be(true)
      expect(cassettes).not_to have_key(:autofix)
    end
  end

  describe "default markdown configuration" do
    let(:config) { described_class.new }

    it "enables markdown linting by default" do
      expect(config.markdown[:enabled]).to be(true)
    end

    it "configures styleguide linter correctly" do
      styleguide = config.markdown[:linters][:styleguide]
      expect(styleguide[:enabled]).to be(true)
      expect(styleguide[:autofix]).to be(true)
    end

    it "configures link_validation linter correctly" do
      link_validation = config.markdown[:linters][:link_validation]
      expect(link_validation[:enabled]).to be(true)
      expect(link_validation).not_to have_key(:autofix)
    end

    it "configures template_embedding linter correctly" do
      template_embedding = config.markdown[:linters][:template_embedding]
      expect(template_embedding[:enabled]).to be(true)
      expect(template_embedding).not_to have_key(:autofix)
    end

    it "configures task_metadata linter correctly" do
      task_metadata = config.markdown[:linters][:task_metadata]
      expect(task_metadata[:enabled]).to be(true)
      expect(task_metadata).not_to have_key(:autofix)
    end
  end

  describe "default error distribution configuration" do
    let(:config) { described_class.new }

    it "enables error distribution by default" do
      expect(config.error_distribution[:enabled]).to be(true)
    end

    it "sets max_files to 4 by default" do
      expect(config.error_distribution[:max_files]).to eq(4)
    end

    it "enables one_issue_per_file by default" do
      expect(config.error_distribution[:one_issue_per_file]).to be(true)
    end
  end

  describe "#enabled_linters" do
    it "returns all enabled linters with default configuration" do
      config = described_class.new
      enabled = config.enabled_linters

      expect(enabled).to include("ruby_standardrb")
      expect(enabled).to include("ruby_security")
      expect(enabled).to include("ruby_cassettes")
      expect(enabled).to include("markdown_styleguide")
      expect(enabled).to include("markdown_link_validation")
      expect(enabled).to include("markdown_template_embedding")
      expect(enabled).to include("markdown_task_metadata")
    end

    it "returns only enabled ruby linters when markdown is disabled" do
      config = described_class.new(markdown: {enabled: false, linters: {}})
      enabled = config.enabled_linters

      expect(enabled).to include("ruby_standardrb")
      expect(enabled).to include("ruby_security")
      expect(enabled).to include("ruby_cassettes")
      expect(enabled).not_to include("markdown_styleguide")
    end

    it "returns only enabled markdown linters when ruby is disabled" do
      config = described_class.new(ruby: {enabled: false, linters: {}})
      enabled = config.enabled_linters

      expect(enabled).to include("markdown_styleguide")
      expect(enabled).to include("markdown_link_validation")
      expect(enabled).to include("markdown_template_embedding")
      expect(enabled).to include("markdown_task_metadata")
      expect(enabled).not_to include("ruby_standardrb")
    end

    it "returns empty array when all linting is disabled" do
      config = described_class.new(
        ruby: {enabled: false, linters: {}},
        markdown: {enabled: false, linters: {}}
      )
      enabled = config.enabled_linters

      expect(enabled).to eq([])
    end

    it "respects individual linter enabled settings" do
      custom_ruby = {
        enabled: true,
        linters: {
          standardrb: {enabled: false, autofix: true},
          security: {enabled: true},
          cassettes: {enabled: false}
        }
      }

      config = described_class.new(ruby: custom_ruby)
      enabled = config.enabled_linters

      expect(enabled).not_to include("ruby_standardrb")
      expect(enabled).to include("ruby_security")
      expect(enabled).not_to include("ruby_cassettes")
    end
  end

  describe "configuration validation" do
    it "handles missing linters hash gracefully" do
      config = described_class.new(ruby: {enabled: true})

      # Should fail when linters hash is missing
      expect { config.enabled_linters }.to raise_error(NoMethodError)
    end

    it "handles nil enabled values gracefully" do
      ruby_config = {
        enabled: true,
        linters: {
          standardrb: {enabled: nil, autofix: true},
          security: {enabled: true}
        }
      }

      config = described_class.new(ruby: ruby_config)
      enabled = config.enabled_linters

      expect(enabled).not_to include("ruby_standardrb")
      expect(enabled).to include("ruby_security")
    end
  end

  describe "configuration merging" do
    it "preserves custom settings while using defaults for missing keys" do
      partial_ruby_config = {
        enabled: true,
        linters: {
          standardrb: {enabled: false, autofix: false}
          # Missing security and cassettes - defaults are NOT merged
        }
      }

      config = described_class.new(ruby: partial_ruby_config)

      expect(config.ruby[:linters][:standardrb][:enabled]).to be(false)
      expect(config.ruby[:linters][:standardrb][:autofix]).to be(false)
      # Only the provided linters are included
      expect(config.ruby[:linters]).not_to have_key(:security)
      expect(config.ruby[:linters]).not_to have_key(:cassettes)
    end
  end

  describe "edge cases", :edge_cases do
    it "handles completely empty configuration" do
      config = described_class.new({})

      expect(config.ruby).to be_a(Hash)
      expect(config.markdown).to be_a(Hash)
      expect(config.error_distribution).to be_a(Hash)
      expect(config.global_settings).to eq({})
    end

    it "handles nil values for all configuration sections" do
      config = described_class.new(
        ruby: nil,
        markdown: nil,
        error_distribution: nil,
        global_settings: nil
      )

      expect(config.ruby).to be_a(Hash)
      expect(config.markdown).to be_a(Hash)
      expect(config.error_distribution).to be_a(Hash)
      expect(config.global_settings).to eq({})
    end

    it "handles very large global_settings" do
      large_settings = {}
      1000.times { |i| large_settings[:"setting_#{i}"] = "value_#{i}" }

      config = described_class.new(global_settings: large_settings)

      expect(config.global_settings.size).to eq(1000)
      expect(config.global_settings[:setting_0]).to eq("value_0")
      expect(config.global_settings[:setting_999]).to eq("value_999")
    end

    it "handles complex nested configuration structures" do
      complex_config = {
        enabled: true,
        linters: {
          custom_linter: {
            enabled: true,
            autofix: false,
            options: {
              level: "strict",
              ignore_patterns: ["*.tmp", "*.log"],
              custom_rules: {
                rule1: {severity: "error", pattern: /test/},
                rule2: {severity: "warning", threshold: 10}
              }
            }
          }
        }
      }

      config = described_class.new(ruby: complex_config)

      expect(config.ruby[:linters][:custom_linter][:options][:custom_rules][:rule1][:pattern]).to eq(/test/)
      expect(config.ruby[:linters][:custom_linter][:options][:ignore_patterns]).to include("*.tmp")
    end

    it "handles unicode characters in configuration" do
      unicode_config = {
        enabled: true,
        linters: {
          :émojis🚀 => {enabled: true, description: "Linter with émojis 🚀"},
          :ñéẅ_linter => {enabled: false, path: "/path/with/ñéẅ/chars"}
        }
      }

      config = described_class.new(ruby: unicode_config)

      expect(config.ruby[:linters][:émojis🚀][:description]).to include("🚀")
      expect(config.ruby[:linters][:ñéẅ_linter][:path]).to include("ñéẅ")
    end

    it "handles zero and negative numeric values" do
      edge_error_distribution = {
        enabled: true,
        max_files: 0,
        one_issue_per_file: true,
        negative_value: -1
      }

      config = described_class.new(error_distribution: edge_error_distribution)

      expect(config.error_distribution[:max_files]).to eq(0)
      expect(config.error_distribution[:negative_value]).to eq(-1)
    end
  end
end
