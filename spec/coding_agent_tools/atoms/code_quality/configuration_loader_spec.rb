# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/code_quality/configuration_loader"
require "tempfile"
require "yaml"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_path) { File.join(temp_dir, "lint.yml") }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    context "with explicit config path" do
      let(:config_content) do
        {
          "ruby" => {
            "enabled" => true,
            "linters" => {
              "standardrb" => {"enabled" => true}
            }
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(config_content))
      end

      it "uses the provided config path" do
        loader = described_class.new(config_path: config_path)
        expect(loader.config_path).to eq(config_path)
      end
    end

    context "with no explicit config path" do
      before do
        # Mock the project root finding
        allow_any_instance_of(described_class).to receive(:find_project_root).and_return(temp_dir)

        # Create .coding-agent directory with lint.yml
        coding_agent_dir = File.join(temp_dir, ".coding-agent")
        Dir.mkdir(coding_agent_dir)
        default_config_path = File.join(coding_agent_dir, "lint.yml")
        File.write(default_config_path, YAML.dump({"ruby" => {"enabled" => true}}))
      end

      it "finds default config path" do
        loader = described_class.new
        expect(loader.config_path).to end_with(".coding-agent/lint.yml")
      end
    end

    context "with explicit project root" do
      it "uses the provided project root" do
        loader = described_class.new(project_root: temp_dir)
        expect(loader.project_root).to eq(temp_dir)
      end
    end
  end

  describe "#load" do
    subject { described_class.new(config_path: config_path) }

    context "with no config file" do
      let(:config_path) { "/nonexistent/path/lint.yml" }

      it "returns default configuration" do
        config = subject.load

        expect(config["ruby"]["enabled"]).to be true
        expect(config["ruby"]["linters"]["standardrb"]["enabled"]).to be true
        expect(config["markdown"]["enabled"]).to be true
        expect(config["error_distribution"]["enabled"]).to be true
      end
    end

    context "with valid config file" do
      let(:custom_config) do
        {
          "ruby" => {
            "enabled" => false,
            "linters" => {
              "standardrb" => {"enabled" => false, "autofix" => false}
            }
          },
          "custom_section" => {
            "enabled" => true
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(custom_config))
      end

      it "merges custom config with defaults" do
        config = subject.load

        # Should override defaults
        expect(config["ruby"]["enabled"]).to be false
        expect(config["ruby"]["linters"]["standardrb"]["enabled"]).to be false
        expect(config["ruby"]["linters"]["standardrb"]["autofix"]).to be false

        # Should keep defaults for unspecified values
        expect(config["ruby"]["linters"]["security"]["enabled"]).to be true
        expect(config["markdown"]["enabled"]).to be true

        # Should add custom sections
        expect(config["custom_section"]["enabled"]).to be true
      end
    end

    context "with invalid YAML syntax" do
      before do
        File.write(config_path, "invalid: yaml: content: [")
      end

      it "raises error with descriptive message" do
        expect { subject.load }.to raise_error(/Invalid YAML syntax/)
      end
    end

    context "with empty config file" do
      before do
        File.write(config_path, "")
      end

      it "returns default configuration" do
        config = subject.load
        expect(config).to include("ruby", "markdown", "error_distribution")
      end
    end

    context "with nil config content" do
      before do
        File.write(config_path, "---\n")
      end

      it "returns default configuration" do
        config = subject.load
        expect(config).to include("ruby", "markdown", "error_distribution")
      end
    end
  end

  describe "#validate" do
    subject { described_class.new(config_path: config_path) }

    context "with no config file" do
      let(:config_path) { "/nonexistent/path/lint.yml" }

      it "returns invalid with error message" do
        result = subject.validate
        expect(result[:valid]).to be false
        expect(result[:error]).to eq("Config file not found")
      end
    end

    context "with valid configuration" do
      let(:valid_config) do
        {
          "ruby" => {
            "enabled" => true,
            "linters" => {
              "standardrb" => {"enabled" => true, "autofix" => true},
              "security" => {"enabled" => false}
            }
          },
          "markdown" => {
            "enabled" => true,
            "linters" => {
              "styleguide" => {"enabled" => true}
            }
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(valid_config))
      end

      it "returns valid result" do
        result = subject.validate
        expect(result[:valid]).to be true
        expect(result[:error]).to be_nil
      end
    end

    context "with invalid top-level structure" do
      let(:invalid_config) do
        {
          "ruby" => "not a hash",
          "markdown" => {"linters" => ["not", "a", "hash"]}
        }
      end

      before do
        File.write(config_path, YAML.dump(invalid_config))
      end

      it "returns invalid with structure errors" do
        result = subject.validate
        expect(result[:valid]).to be false
        expect(result[:errors]).to include("ruby must be a hash")
      end
    end

    context "with invalid linter structure" do
      let(:invalid_config) do
        {
          "ruby" => {
            "linters" => "not a hash"
          },
          "markdown" => {
            "linters" => {
              "styleguide" => "not a hash"
            }
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(invalid_config))
      end

      it "returns invalid with linter errors" do
        result = subject.validate
        expect(result[:valid]).to be false
        expect(result[:errors]).to include("ruby.linters must be a hash")
        expect(result[:errors]).to include("markdown.linters.styleguide must be a hash")
      end
    end

    context "with YAML syntax error" do
      before do
        File.write(config_path, "invalid: yaml: [")
      end

      it "returns invalid with YAML error" do
        result = subject.validate
        expect(result[:valid]).to be false
        expect(result[:error]).to match(/Invalid YAML syntax/)
      end
    end
  end

  describe "#find_project_root" do
    let(:nested_dir) { File.join(temp_dir, "nested", "deeply", "nested") }

    before do
      FileUtils.mkdir_p(nested_dir)
    end

    context "with .git marker" do
      before do
        FileUtils.touch(File.join(temp_dir, ".git"))
        Dir.chdir(nested_dir)
      end

      after do
        Dir.chdir("/")
      end

      it "finds project root with .git marker" do
        loader = described_class.new
        expect(File.realpath(loader.project_root)).to eq(File.realpath(temp_dir))
      end
    end

    context "with Gemfile marker" do
      before do
        FileUtils.touch(File.join(temp_dir, "Gemfile"))
        Dir.chdir(nested_dir)
      end

      after do
        Dir.chdir("/")
      end

      it "finds project root with Gemfile marker" do
        loader = described_class.new
        expect(File.realpath(loader.project_root)).to eq(File.realpath(temp_dir))
      end
    end

    context "with .coding-agent marker" do
      before do
        FileUtils.mkdir(File.join(temp_dir, ".coding-agent"))
        Dir.chdir(nested_dir)
      end

      after do
        Dir.chdir("/")
      end

      it "finds project root with .coding-agent marker" do
        loader = described_class.new
        expect(File.realpath(loader.project_root)).to eq(File.realpath(temp_dir))
      end
    end

    context "with no markers found" do
      before do
        Dir.chdir(nested_dir)
      end

      after do
        Dir.chdir("/")
      end

      it "returns current working directory" do
        loader = described_class.new
        expect(File.realpath(loader.project_root)).to eq(File.realpath(nested_dir))
      end
    end

    context "with multiple markers" do
      before do
        FileUtils.touch(File.join(temp_dir, ".git"))
        FileUtils.touch(File.join(temp_dir, "Gemfile"))
        Dir.chdir(nested_dir)
      end

      after do
        Dir.chdir("/")
      end

      it "finds project root with first matching marker" do
        loader = described_class.new
        expect(File.realpath(loader.project_root)).to eq(File.realpath(temp_dir))
      end
    end
  end

  describe "#deep_merge" do
    let(:loader) { described_class.new }

    it "merges nested hashes deeply" do
      hash1 = {
        "a" => {"b" => {"c" => 1, "d" => 2}},
        "e" => 5
      }
      hash2 = {
        "a" => {"b" => {"c" => 10, "f" => 3}},
        "g" => 6
      }

      result = loader.send(:deep_merge, hash1, hash2)

      expect(result).to eq({
        "a" => {"b" => {"c" => 10, "d" => 2, "f" => 3}},
        "e" => 5,
        "g" => 6
      })
    end

    it "overwrites non-hash values" do
      hash1 = {"a" => {"b" => "old_value"}}
      hash2 = {"a" => {"b" => "new_value"}}

      result = loader.send(:deep_merge, hash1, hash2)
      expect(result["a"]["b"]).to eq("new_value")
    end

    it "handles mixed hash and non-hash values" do
      hash1 = {"a" => {"b" => 1}}
      hash2 = {"a" => "not_a_hash"}

      result = loader.send(:deep_merge, hash1, hash2)
      expect(result["a"]).to eq("not_a_hash")
    end
  end

  describe "DEFAULT_CONFIG" do
    it "contains expected sections" do
      expect(described_class::DEFAULT_CONFIG).to include("ruby", "markdown", "error_distribution")
    end

    it "has proper ruby configuration" do
      ruby_config = described_class::DEFAULT_CONFIG["ruby"]
      expect(ruby_config["enabled"]).to be true
      expect(ruby_config["linters"]).to include("standardrb", "security", "cassettes")
    end

    it "has proper markdown configuration" do
      markdown_config = described_class::DEFAULT_CONFIG["markdown"]
      expect(markdown_config["enabled"]).to be true
      expect(markdown_config["linters"]).to include("styleguide", "link_validation", "template_embedding", "task_metadata")
      expect(markdown_config["order"]).to be_an(Array)
    end

    it "has proper error distribution configuration" do
      error_config = described_class::DEFAULT_CONFIG["error_distribution"]
      expect(error_config["enabled"]).to be true
      expect(error_config["max_files"]).to be > 0
      expect(error_config["one_issue_per_file"]).to be true
    end

    it "is frozen to prevent modification" do
      expect(described_class::DEFAULT_CONFIG).to be_frozen
    end
  end

  describe "edge cases and error conditions" do
    subject { described_class.new(config_path: config_path) }

    context "with config file permission error" do
      before do
        File.write(config_path, YAML.dump({"ruby" => {"enabled" => true}}))
        File.chmod(0o000, config_path)
      end

      after do
        File.chmod(0o644, config_path)
      end

      it "handles permission errors gracefully" do
        expect { subject.load }.to raise_error(Errno::EACCES)
      end
    end

    context "with extremely large config file" do
      let(:large_config) do
        config = {"ruby" => {"linters" => {}}}
        1000.times do |i|
          config["ruby"]["linters"]["linter#{i}"] = {"enabled" => true, "options" => {"key" => "value"}}
        end
        config
      end

      before do
        File.write(config_path, YAML.dump(large_config))
      end

      it "handles large config files" do
        result = subject.load
        expect(result["ruby"]["linters"].keys.length).to eq(1003) # 3 defaults + 1000 custom
      end
    end

    context "with config containing special characters" do
      let(:special_config) do
        {
          "ruby" => {
            "linters" => {
              "special-linter_name.with@symbols" => {"enabled" => true}
            }
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(special_config))
      end

      it "handles special characters in keys" do
        result = subject.load
        expect(result["ruby"]["linters"]).to have_key("special-linter_name.with@symbols")
      end
    end

    context "with circular references in YAML" do
      let(:circular_yaml) do
        <<~YAML
          ruby: &ruby_ref
            enabled: true
            linters:
              standardrb:
                enabled: true
                circular_ref: *ruby_ref
        YAML
      end

      before do
        File.write(config_path, circular_yaml)
      end

      it "handles circular references in YAML by raising error" do
        # Psych doesn't allow circular references by default, which is actually good security
        expect { subject.load }.to raise_error(Psych::AliasesNotEnabled)
      end
    end
  end
end
