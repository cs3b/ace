# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "yaml"

RSpec.describe CodingAgentTools::Atoms::DocsDependenciesConfigLoader do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_path) { File.join(temp_dir, ".coding-agent", "lint.yml") }
  let(:loader) { described_class.new(config_path) }
  let(:default_loader) { described_class.new }

  before do
    FileUtils.mkdir_p(File.dirname(config_path))
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "DEFAULT_CONFIG" do
    it "defines comprehensive default configuration" do
      expect(described_class::DEFAULT_CONFIG).to be_frozen
      expect(described_class::DEFAULT_CONFIG[:enabled]).to be true
      expect(described_class::DEFAULT_CONFIG[:file_patterns]).to be_a(Hash)
      expect(described_class::DEFAULT_CONFIG[:exclude_patterns]).to be_a(Array)
      expect(described_class::DEFAULT_CONFIG[:skip_folders]).to be_a(Array)
      expect(described_class::DEFAULT_CONFIG[:include_external_links]).to be false
      expect(described_class::DEFAULT_CONFIG[:include_anchor_links]).to be false
    end

    it "defines expected file patterns" do
      patterns = described_class::DEFAULT_CONFIG[:file_patterns]
      expect(patterns[:workflows]).to eq("dev-handbook/workflow-instructions/**/*.wf.md")
      expect(patterns[:guides]).to eq("dev-handbook/guides/**/*.g.md")
      expect(patterns[:tasks]).to eq("dev-taskflow/**/tasks/*.md")
      expect(patterns[:docs]).to eq("docs/*.md")
      expect(patterns[:taskflow_docs]).to eq("dev-taskflow/*.md")
    end

    it "defines expected exclude patterns" do
      excludes = described_class::DEFAULT_CONFIG[:exclude_patterns]
      expect(excludes).to include("dev-taskflow/done/**/*")
      expect(excludes).to include("dev-taskflow/sessions/**/*")
      expect(excludes).to include("**/.*")
    end

    it "defines empty skip_folders by default" do
      expect(described_class::DEFAULT_CONFIG[:skip_folders]).to eq([])
    end
  end

  describe "#initialize" do
    it "initializes with default config path" do
      loader = described_class.new
      expect(loader.instance_variable_get(:@config_path)).to eq(".coding-agent/lint.yml")
    end

    it "initializes with custom config path" do
      custom_path = "/custom/path/config.yml"
      loader = described_class.new(custom_path)
      expect(loader.instance_variable_get(:@config_path)).to eq(custom_path)
    end

    it "accepts nil config path" do
      loader = described_class.new(nil)
      expect(loader.instance_variable_get(:@config_path)).to be_nil
    end
  end

  describe "#load_config" do
    context "when config file does not exist" do
      it "returns DEFAULT_CONFIG" do
        result = loader.load_config
        expect(result).to eq(described_class::DEFAULT_CONFIG)
      end
    end

    context "when config_path is nil" do
      let(:nil_loader) { described_class.new(nil) }

      it "returns DEFAULT_CONFIG" do
        result = nil_loader.load_config
        expect(result).to eq(described_class::DEFAULT_CONFIG)
      end
    end

    context "with valid YAML config file" do
      let(:config_data) do
        {
          "docs_dependencies" => {
            "enabled" => false,
            "file_patterns" => {
              "custom" => "custom/**/*.md"
            },
            "exclude_patterns" => ["custom_exclude/**/*"],
            "include_external_links" => true
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(config_data))
      end

      it "loads and merges configuration with defaults" do
        result = loader.load_config

        expect(result[:enabled]).to be false
        expect(result[:include_external_links]).to be true
        expect(result[:file_patterns][:custom]).to eq("custom/**/*.md")
        expect(result[:file_patterns][:workflows]).to eq("dev-handbook/workflow-instructions/**/*.wf.md") # From defaults
        expect(result[:exclude_patterns]).to eq(["custom_exclude/**/*"])
      end

      it "preserves original default structure for unspecified keys" do
        result = loader.load_config

        # Should preserve default file patterns not overridden
        expect(result[:file_patterns][:guides]).to eq("dev-handbook/guides/**/*.g.md")
        expect(result[:file_patterns][:tasks]).to eq("dev-taskflow/**/tasks/*.md")
      end

      it "validates the merged configuration" do
        expect { loader.load_config }.not_to raise_error
      end
    end

    context "with partial configuration" do
      let(:partial_config) do
        {
          "docs_dependencies" => {
            "file_patterns" => {
              "custom" => "new/**/*.md"
            }
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(partial_config))
      end

      it "merges partial config with defaults" do
        result = loader.load_config

        expect(result[:enabled]).to be true # Default value
        expect(result[:file_patterns][:custom]).to eq("new/**/*.md") # Override
        expect(result[:file_patterns][:workflows]).to eq("dev-handbook/workflow-instructions/**/*.wf.md") # Default
        expect(result[:exclude_patterns]).to eq(described_class::DEFAULT_CONFIG[:exclude_patterns]) # Default
      end
    end

    context "with empty docs_dependencies section" do
      let(:empty_config) do
        {"docs_dependencies" => {}}
      end

      before do
        File.write(config_path, YAML.dump(empty_config))
      end

      it "uses all default values" do
        result = loader.load_config
        expect(result).to eq(described_class::DEFAULT_CONFIG)
      end
    end

    context "with missing docs_dependencies section" do
      let(:no_docs_config) do
        {"other_config" => {"value" => "test"}}
      end

      before do
        File.write(config_path, YAML.dump(no_docs_config))
      end

      it "uses all default values" do
        result = loader.load_config
        expect(result).to eq(described_class::DEFAULT_CONFIG)
      end
    end

    context "with invalid YAML file" do
      before do
        File.write(config_path, "invalid: yaml: content: [")
      end

      it "returns DEFAULT_CONFIG and suppresses warnings in test environment" do
        expect { loader.load_config }.to output("").to_stderr
        result = loader.load_config
        expect(result).to eq(described_class::DEFAULT_CONFIG)
      end
    end

    context "with file read permission error" do
      before do
        File.write(config_path, YAML.dump({"docs_dependencies" => {}}))
        FileUtils.chmod(0o000, config_path) # Remove all permissions
      end

      after do
        FileUtils.chmod(0o644, config_path)
      rescue
        nil
        # Restore permissions for cleanup
      end

      it "returns DEFAULT_CONFIG and suppresses warnings in test environment" do
        expect { loader.load_config }.to output("").to_stderr
        result = loader.load_config
        expect(result).to eq(described_class::DEFAULT_CONFIG)
      end
    end

    context "with invalid configuration structure" do
      let(:invalid_config) do
        {
          "docs_dependencies" => {
            "file_patterns" => "not_a_hash",
            "exclude_patterns" => "not_an_array"
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(invalid_config))
      end

      it "returns DEFAULT_CONFIG and suppresses warnings in test environment" do
        expect { loader.load_config }.to output("").to_stderr
        result = loader.load_config
        expect(result).to eq(described_class::DEFAULT_CONFIG)
      end
    end
  end

  describe "#get_file_patterns" do
    it "returns file patterns from provided config" do
      config = {file_patterns: {custom: "test/**/*.md"}}
      result = loader.get_file_patterns(config)
      expect(result).to eq({custom: "test/**/*.md"})
    end

    it "loads config when no config provided" do
      allow(loader).to receive(:load_config).and_return({file_patterns: {loaded: "loaded/**/*.md"}})
      result = loader.get_file_patterns
      expect(result).to eq({loaded: "loaded/**/*.md"})
    end

    it "returns default patterns when config has no file_patterns" do
      config = {other_key: "value"}
      result = loader.get_file_patterns(config)
      expect(result).to eq(described_class::DEFAULT_CONFIG[:file_patterns])
    end

    it "returns default patterns when file_patterns is nil" do
      config = {file_patterns: nil}
      result = loader.get_file_patterns(config)
      expect(result).to eq(described_class::DEFAULT_CONFIG[:file_patterns])
    end
  end

  describe "#get_exclude_patterns" do
    it "returns exclude patterns from provided config" do
      config = {exclude_patterns: ["custom/**/*"]}
      result = loader.get_exclude_patterns(config)
      expect(result).to eq(["custom/**/*"])
    end

    it "loads config when no config provided" do
      allow(loader).to receive(:load_config).and_return({exclude_patterns: ["loaded/**/*"]})
      result = loader.get_exclude_patterns
      expect(result).to eq(["loaded/**/*"])
    end

    it "returns default patterns when config has no exclude_patterns" do
      config = {other_key: "value"}
      result = loader.get_exclude_patterns(config)
      expect(result).to eq(described_class::DEFAULT_CONFIG[:exclude_patterns])
    end

    it "returns default patterns when exclude_patterns is nil" do
      config = {exclude_patterns: nil}
      result = loader.get_exclude_patterns(config)
      expect(result).to eq(described_class::DEFAULT_CONFIG[:exclude_patterns])
    end
  end

  describe "#get_skip_folders" do
    it "returns skip folders from provided config" do
      config = {skip_folders: ["folder1", "folder2"]}
      result = loader.get_skip_folders(config)
      expect(result).to eq(["folder1", "folder2"])
    end

    it "loads config when no config provided" do
      allow(loader).to receive(:load_config).and_return({skip_folders: ["loaded_folder"]})
      result = loader.get_skip_folders
      expect(result).to eq(["loaded_folder"])
    end

    it "returns default folders when config has no skip_folders" do
      config = {other_key: "value"}
      result = loader.get_skip_folders(config)
      expect(result).to eq(described_class::DEFAULT_CONFIG[:skip_folders])
    end

    it "returns default folders when skip_folders is nil" do
      config = {skip_folders: nil}
      result = loader.get_skip_folders(config)
      expect(result).to eq(described_class::DEFAULT_CONFIG[:skip_folders])
    end
  end

  describe "#include_external_links?" do
    it "returns true when external links are enabled in config" do
      config = {include_external_links: true}
      result = loader.include_external_links?(config)
      expect(result).to be true
    end

    it "returns false when external links are disabled in config" do
      config = {include_external_links: false}
      result = loader.include_external_links?(config)
      expect(result).to be false
    end

    it "loads config when no config provided" do
      allow(loader).to receive(:load_config).and_return({include_external_links: true})
      result = loader.include_external_links?
      expect(result).to be true
    end

    it "returns default value when config has no include_external_links" do
      config = {other_key: "value"}
      result = loader.include_external_links?(config)
      expect(result).to eq(described_class::DEFAULT_CONFIG[:include_external_links])
    end

    it "returns default value when include_external_links is nil" do
      config = {include_external_links: nil}
      result = loader.include_external_links?(config)
      expect(result).to eq(described_class::DEFAULT_CONFIG[:include_external_links])
    end
  end

  describe "#include_anchor_links?" do
    it "returns true when anchor links are enabled in config" do
      config = {include_anchor_links: true}
      result = loader.include_anchor_links?(config)
      expect(result).to be true
    end

    it "returns false when anchor links are disabled in config" do
      config = {include_anchor_links: false}
      result = loader.include_anchor_links?(config)
      expect(result).to be false
    end

    it "loads config when no config provided" do
      allow(loader).to receive(:load_config).and_return({include_anchor_links: true})
      result = loader.include_anchor_links?
      expect(result).to be true
    end

    it "returns default value when config has no include_anchor_links" do
      config = {other_key: "value"}
      result = loader.include_anchor_links?(config)
      expect(result).to eq(described_class::DEFAULT_CONFIG[:include_anchor_links])
    end

    it "returns default value when include_anchor_links is nil" do
      config = {include_anchor_links: nil}
      result = loader.include_anchor_links?(config)
      expect(result).to eq(described_class::DEFAULT_CONFIG[:include_anchor_links])
    end
  end

  describe "#enabled?" do
    it "returns true when enabled is true in config" do
      config = {enabled: true}
      result = loader.enabled?(config)
      expect(result).to be true
    end

    it "returns false when enabled is false in config" do
      config = {enabled: false}
      result = loader.enabled?(config)
      expect(result).to be false
    end

    it "returns true when enabled is nil (defaults to true)" do
      config = {enabled: nil}
      result = loader.enabled?(config)
      expect(result).to be true
    end

    it "loads config when no config provided" do
      allow(loader).to receive(:load_config).and_return({enabled: false})
      result = loader.enabled?
      expect(result).to be false
    end

    it "returns true when config has no enabled key (default behavior)" do
      config = {other_key: "value"}
      result = loader.enabled?(config)
      expect(result).to be true
    end

    it "treats only explicit false as disabled" do
      test_cases = [true, nil, "false", 0, "", []]
      test_cases.each do |value|
        config = {enabled: value}
        result = loader.enabled?(config)
        expect(result).to be true
      end
    end
  end

  describe "private methods" do
    describe "#deep_merge" do
      it "merges nested hashes correctly" do
        base = {
          level1: {
            level2: {
              key1: "base_value1",
              key2: "base_value2"
            },
            other_key: "base_other"
          }
        }

        override = {
          level1: {
            level2: {
              key1: "override_value1",
              key3: "override_value3"
            }
          }
        }

        result = loader.send(:deep_merge, base, override)

        expect(result[:level1][:level2][:key1]).to eq("override_value1")
        expect(result[:level1][:level2][:key2]).to eq("base_value2")
        expect(result[:level1][:level2][:key3]).to eq("override_value3")
        expect(result[:level1][:other_key]).to eq("base_other")
      end

      it "handles non-hash values correctly" do
        base = {key: "base_value", nested: {inner: "base_inner"}}
        override = {key: "override_value", nested: "override_non_hash"}

        result = loader.send(:deep_merge, base, override)

        expect(result[:key]).to eq("override_value")
        expect(result[:nested]).to eq("override_non_hash")
      end

      it "does not modify original base hash" do
        base = {nested: {key: "original"}}
        override = {nested: {key: "modified"}}

        original_base = base.dup
        result = loader.send(:deep_merge, base, override)

        expect(base).to eq(original_base)
        expect(result[:nested][:key]).to eq("modified")
      end
    end

    describe "#symbolize_keys" do
      it "converts string keys to symbols" do
        hash = {"string_key" => "value", "nested" => {"inner_key" => "inner_value"}}
        result = loader.send(:symbolize_keys, hash)

        expect(result).to eq({
          string_key: "value",
          nested: {inner_key: "inner_value"}
        })
      end

      it "handles non-hash input" do
        expect(loader.send(:symbolize_keys, "string")).to eq("string")
        expect(loader.send(:symbolize_keys, 123)).to eq(123)
        expect(loader.send(:symbolize_keys, nil)).to be_nil
        expect(loader.send(:symbolize_keys, [])).to eq([])
      end

      it "preserves symbol keys" do
        hash = {:already_symbol => "value", "string_key" => "value2"}
        result = loader.send(:symbolize_keys, hash)

        expect(result).to eq({
          already_symbol: "value",
          string_key: "value2"
        })
      end

      it "handles deeply nested structures" do
        hash = {
          "level1" => {
            "level2" => {
              "level3" => {"deep_key" => "deep_value"}
            }
          }
        }

        result = loader.send(:symbolize_keys, hash)

        expect(result).to eq({
          level1: {
            level2: {
              level3: {deep_key: "deep_value"}
            }
          }
        })
      end
    end

    describe "#validate_config" do
      it "accepts valid configuration" do
        valid_config = {
          file_patterns: {pattern: "**/*.md"},
          exclude_patterns: ["exclude/**/*"],
          skip_folders: ["folder1"]
        }

        expect { loader.send(:validate_config, valid_config) }.not_to raise_error
      end

      it "raises error when file_patterns is not a hash" do
        invalid_config = {
          file_patterns: "not_a_hash",
          exclude_patterns: [],
          skip_folders: []
        }

        expect { loader.send(:validate_config, invalid_config) }.to raise_error("file_patterns must be a hash")
      end

      it "raises error when exclude_patterns is not an array" do
        invalid_config = {
          file_patterns: {},
          exclude_patterns: "not_an_array",
          skip_folders: []
        }

        expect { loader.send(:validate_config, invalid_config) }.to raise_error("exclude_patterns must be an array")
      end

      it "raises error when skip_folders is not an array" do
        invalid_config = {
          file_patterns: {},
          exclude_patterns: [],
          skip_folders: "not_an_array"
        }

        expect { loader.send(:validate_config, invalid_config) }.to raise_error("skip_folders must be an array")
      end

      it "handles missing keys gracefully" do
        incomplete_config = {file_patterns: {}}

        expect { loader.send(:validate_config, incomplete_config) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "comprehensive edge cases and error handling" do
    context "with complex YAML structures" do
      let(:complex_config) do
        {
          "docs_dependencies" => {
            "file_patterns" => {
              "custom1" => "path1/**/*.md",
              "custom2" => "path2/**/*.md"
            },
            "exclude_patterns" => [
              "temp/**/*",
              "build/**/*",
              "**/node_modules/**/*"
            ],
            "skip_folders" => ["temp", "cache"],
            "include_external_links" => true,
            "include_anchor_links" => false,
            "enabled" => true
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(complex_config))
      end

      it "handles complex configurations correctly" do
        result = loader.load_config

        expect(result[:file_patterns][:custom1]).to eq("path1/**/*.md")
        expect(result[:file_patterns][:custom2]).to eq("path2/**/*.md")
        expect(result[:exclude_patterns]).to include("temp/**/*", "build/**/*", "**/node_modules/**/*")
        expect(result[:skip_folders]).to eq(["temp", "cache"])
        expect(result[:include_external_links]).to be true
        expect(result[:include_anchor_links]).to be false
        expect(result[:enabled]).to be true
      end
    end

    context "with Unicode and special characters" do
      let(:unicode_config) do
        {
          "docs_dependencies" => {
            "file_patterns" => {
              "unicode" => "文档/**/*.md",
              "special" => "docs with spaces/**/*.md"
            },
            "exclude_patterns" => ["тест/**/*", "émojis 🚀/**/*"]
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(unicode_config))
      end

      it "handles Unicode and special characters in configuration" do
        result = loader.load_config

        expect(result[:file_patterns][:unicode]).to eq("文档/**/*.md")
        expect(result[:file_patterns][:special]).to eq("docs with spaces/**/*.md")
        expect(result[:exclude_patterns]).to include("тест/**/*", "émojis 🚀/**/*")
      end
    end

    context "with very large configuration" do
      let(:large_config) do
        patterns = {}
        excludes = []

        100.times do |i|
          patterns["pattern_#{i}"] = "path_#{i}/**/*.md"
          excludes << "exclude_#{i}/**/*"
        end

        {
          "docs_dependencies" => {
            "file_patterns" => patterns,
            "exclude_patterns" => excludes
          }
        }
      end

      before do
        File.write(config_path, YAML.dump(large_config))
      end

      it "handles large configurations efficiently" do
        start_time = Time.now
        result = loader.load_config
        end_time = Time.now

        expect(result[:file_patterns].keys.length).to eq(105) # 100 custom + 5 defaults
        expect(result[:exclude_patterns].length).to eq(100)
        expect(end_time - start_time).to be < 1.0 # Should be fast
      end
    end

    context "with file system edge cases" do
      it "handles directory instead of file" do
        FileUtils.mkdir_p(config_path) # Create directory with same name as expected file

        expect { loader.load_config }.to output("").to_stderr
        result = loader.load_config
        expect(result).to eq(described_class::DEFAULT_CONFIG)
      end

      it "handles empty file" do
        File.write(config_path, "")

        result = loader.load_config
        expect(result).to eq(described_class::DEFAULT_CONFIG)
      end

      it "handles file with only whitespace" do
        File.write(config_path, "   \n\t\n   ")

        result = loader.load_config
        expect(result).to eq(described_class::DEFAULT_CONFIG)
      end
    end

    context "with YAML edge cases" do
      it "handles YAML with comments and formatting" do
        yaml_content = <<~YAML
          # Configuration for docs dependencies
          docs_dependencies:
            # Enable the feature
            enabled: true
            
            file_patterns:
              # Custom patterns
              custom: "custom/**/*.md"
            
            # Exclusions
            exclude_patterns:
              - "temp/**/*"
        YAML

        File.write(config_path, yaml_content)

        result = loader.load_config
        expect(result[:enabled]).to be true
        expect(result[:file_patterns][:custom]).to eq("custom/**/*.md")
        expect(result[:exclude_patterns]).to eq(["temp/**/*"])
      end

      it "handles YAML anchors and references" do
        yaml_content = <<~YAML
          common_exclude: &common_exclude
            - "temp/**/*"
            - "build/**/*"
          
          docs_dependencies:
            exclude_patterns: *common_exclude
        YAML

        File.write(config_path, yaml_content)

        # Note: This test may fail with newer Psych versions that disable aliases by default
        # In production, the loader will fall back to default config with a warning
        expect { loader.load_config }.to output("").to_stderr
        result = loader.load_config
        expect(result[:exclude_patterns]).to eq(described_class::DEFAULT_CONFIG[:exclude_patterns])
      end
    end
  end

  describe "algorithm correctness verification" do
    context "deep merge accuracy" do
      it "properly merges nested configurations without losing data" do
        base_config = described_class::DEFAULT_CONFIG
        override_config = {
          file_patterns: {custom: "custom/**/*.md"},
          enabled: false
        }

        result = loader.send(:deep_merge, base_config, override_config)

        # Should have override values
        expect(result[:enabled]).to be false
        expect(result[:file_patterns][:custom]).to eq("custom/**/*.md")

        # Should preserve all original patterns
        expect(result[:file_patterns][:workflows]).to eq("dev-handbook/workflow-instructions/**/*.wf.md")
        expect(result[:file_patterns][:guides]).to eq("dev-handbook/guides/**/*.g.md")
        expect(result[:file_patterns][:tasks]).to eq("dev-taskflow/**/tasks/*.md")
        expect(result[:file_patterns][:docs]).to eq("docs/*.md")
        expect(result[:file_patterns][:taskflow_docs]).to eq("dev-taskflow/*.md")

        # Should preserve other default values
        expect(result[:exclude_patterns]).to eq(described_class::DEFAULT_CONFIG[:exclude_patterns])
        expect(result[:skip_folders]).to eq(described_class::DEFAULT_CONFIG[:skip_folders])
      end
    end

    context "configuration validation accuracy" do
      it "correctly identifies valid configurations" do
        valid_configs = [
          {
            file_patterns: {},
            exclude_patterns: [],
            skip_folders: []
          },
          {
            file_patterns: {test: "**/*.md"},
            exclude_patterns: ["exclude/**/*"],
            skip_folders: ["skip"]
          }
        ]

        valid_configs.each do |config|
          expect { loader.send(:validate_config, config) }.not_to raise_error
        end
      end

      it "correctly identifies invalid configurations" do
        invalid_configs = [
          {
            file_patterns: "not_hash",
            exclude_patterns: [],
            skip_folders: []
          },
          {
            file_patterns: {},
            exclude_patterns: "not_array",
            skip_folders: []
          },
          {
            file_patterns: {},
            exclude_patterns: [],
            skip_folders: "not_array"
          }
        ]

        invalid_configs.each do |config|
          expect { loader.send(:validate_config, config) }.to raise_error(RuntimeError)
        end
      end
    end

    context "key symbolization accuracy" do
      it "correctly converts all string keys to symbols recursively" do
        input = {
          "level1" => {
            "level2" => {
              "level3" => "value"
            },
            "other" => ["array", "values"]
          }
        }

        result = loader.send(:symbolize_keys, input)

        expect(result.keys).to all(be_a(Symbol))
        expect(result[:level1].keys).to all(be_a(Symbol))
        expect(result[:level1][:level2].keys).to all(be_a(Symbol))
        expect(result[:level1][:level2][:level3]).to eq("value")
        expect(result[:level1][:other]).to eq(["array", "values"])
      end
    end
  end

  describe "performance considerations" do
    it "loads configuration efficiently for repeated calls" do
      File.write(config_path, YAML.dump({"docs_dependencies" => {"enabled" => true}}))

      start_time = Time.now

      100.times do
        loader.load_config
      end

      end_time = Time.now
      expect(end_time - start_time).to be < 1.0 # Should be reasonably fast
    end

    it "handles large configuration files efficiently" do
      large_config = {
        "docs_dependencies" => {
          "file_patterns" => (1..1000).each_with_object({}) { |i, h| h["pattern_#{i}"] = "path_#{i}/**/*.md" },
          "exclude_patterns" => (1..1000).map { |i| "exclude_#{i}/**/*" }
        }
      }

      File.write(config_path, YAML.dump(large_config))

      start_time = Time.now
      result = loader.load_config
      end_time = Time.now

      expect(result[:file_patterns].keys.length).to eq(1005) # 1000 custom + 5 defaults
      expect(end_time - start_time).to be < 2.0 # Should handle large configs reasonably
    end
  end
end
