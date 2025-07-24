# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::LanguageFileFilter do
  let(:filter) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#initialize" do
    it "creates filter with default configuration" do
      filter = described_class.new
      expect(filter).to be_a(described_class)
    end

    it "creates filter with custom configuration" do
      config = { file_patterns: { ruby: ["*.rb"] } }
      filter = described_class.new(config: config)
      expect(filter).to be_a(described_class)
    end
  end

  describe "#filter_by_language" do
    let(:file_paths) do
      [
        "app/models/user.rb",
        "README.md",
        "docs/guide.markdown",
        "Gemfile",
        "config.json",
        "script.py",
        "exe/console"
      ]
    end

    context "with Ruby language" do
      it "filters to include only Ruby files" do
        result = filter.filter_by_language(file_paths, :ruby)
        expect(result).to contain_exactly(
          "app/models/user.rb",
          "Gemfile",
          "exe/console"
        )
      end

      it "accepts string language parameter" do
        result = filter.filter_by_language(file_paths, "ruby")
        expect(result).to contain_exactly(
          "app/models/user.rb",
          "Gemfile",
          "exe/console"
        )
      end
    end

    context "with Markdown language" do
      it "filters to include only Markdown files" do
        result = filter.filter_by_language(file_paths, :markdown)
        expect(result).to contain_exactly(
          "README.md",
          "docs/guide.markdown"
        )
      end
    end

    context "with unknown language" do
      it "returns empty array" do
        result = filter.filter_by_language(file_paths, :unknown)
        expect(result).to eq([])
      end
    end

    context "with edge cases" do
      it "handles nil file paths" do
        result = filter.filter_by_language(nil, :ruby)
        expect(result).to eq([])
      end

      it "handles empty file paths array" do
        result = filter.filter_by_language([], :ruby)
        expect(result).to eq([])
      end

      it "handles empty strings in file paths" do
        paths_with_empty = ["file.rb", "", "another.rb"]
        result = filter.filter_by_language(paths_with_empty, :ruby)
        expect(result).to contain_exactly("file.rb", "another.rb")
      end
    end
  end

  describe "#expand_paths_for_language" do
    before do
      # Create test directory structure
      FileUtils.mkdir_p(File.join(temp_dir, "lib"))
      FileUtils.mkdir_p(File.join(temp_dir, "spec"))
      FileUtils.mkdir_p(File.join(temp_dir, "docs"))
      FileUtils.mkdir_p(File.join(temp_dir, "exe"))
      FileUtils.mkdir_p(File.join(temp_dir, "nested", "deep"))

      # Create test files
      File.write(File.join(temp_dir, "lib", "main.rb"), "# Ruby file")
      File.write(File.join(temp_dir, "lib", "helper.rb"), "# Another Ruby file")
      File.write(File.join(temp_dir, "spec", "main_spec.rb"), "# Spec file")
      File.write(File.join(temp_dir, "Gemfile"), "# Gemfile")
      File.write(File.join(temp_dir, "Rakefile"), "# Rakefile")
      File.write(File.join(temp_dir, "README.md"), "# README")
      File.write(File.join(temp_dir, "docs", "guide.md"), "# Guide")
      File.write(File.join(temp_dir, "exe", "console"), "#!/usr/bin/env ruby")
      File.write(File.join(temp_dir, "config.json"), "{}")
      File.write(File.join(temp_dir, "nested", "deep", "file.rb"), "# Deep Ruby file")
    end

    context "with directory paths" do
      it "expands directory to find Ruby files" do
        paths = [File.join(temp_dir, "lib")]
        result = filter.expand_paths_for_language(paths, :ruby)
        
        expect(result).to include(
          File.join(temp_dir, "lib", "main.rb"),
          File.join(temp_dir, "lib", "helper.rb")
        )
        expect(result.size).to eq(2)
      end

      it "expands multiple directories" do
        paths = [
          File.join(temp_dir, "lib"),
          File.join(temp_dir, "spec")
        ]
        result = filter.expand_paths_for_language(paths, :ruby)
        
        expect(result).to include(
          File.join(temp_dir, "lib", "main.rb"),
          File.join(temp_dir, "lib", "helper.rb"),
          File.join(temp_dir, "spec", "main_spec.rb")
        )
        expect(result.size).to eq(3)
      end

      it "finds files recursively in nested directories" do
        paths = [temp_dir]
        result = filter.expand_paths_for_language(paths, :ruby)
        
        expect(result).to include(
          File.join(temp_dir, "nested", "deep", "file.rb")
        )
      end

      it "finds special Ruby files like Gemfile and Rakefile" do
        paths = [temp_dir]
        result = filter.expand_paths_for_language(paths, :ruby)
        
        expect(result).to include(
          File.join(temp_dir, "Gemfile"),
          File.join(temp_dir, "Rakefile")
        )
      end

      it "finds files in exe directory" do
        paths = [temp_dir]
        result = filter.expand_paths_for_language(paths, :ruby)
        
        expect(result).to include(
          File.join(temp_dir, "exe", "console")
        )
      end
    end

    context "with file paths" do
      it "includes matching files directly" do
        paths = [
          File.join(temp_dir, "lib", "main.rb"),
          File.join(temp_dir, "README.md")
        ]
        result = filter.expand_paths_for_language(paths, :ruby)
        
        expect(result).to contain_exactly(
          File.join(temp_dir, "lib", "main.rb")
        )
      end

      it "excludes non-matching files" do
        paths = [
          File.join(temp_dir, "README.md"),
          File.join(temp_dir, "config.json")
        ]
        result = filter.expand_paths_for_language(paths, :ruby)
        
        expect(result).to be_empty
      end
    end

    context "with mixed paths" do
      it "handles both directories and files" do
        paths = [
          File.join(temp_dir, "lib"),
          File.join(temp_dir, "Gemfile"),
          File.join(temp_dir, "README.md")
        ]
        result = filter.expand_paths_for_language(paths, :ruby)
        
        expect(result).to include(
          File.join(temp_dir, "lib", "main.rb"),
          File.join(temp_dir, "lib", "helper.rb"),
          File.join(temp_dir, "Gemfile")
        )
        expect(result).not_to include(File.join(temp_dir, "README.md"))
      end
    end

    context "with edge cases" do
      it "handles nil paths" do
        result = filter.expand_paths_for_language(nil, :ruby)
        expect(result).to eq([])
      end

      it "handles empty paths array" do
        result = filter.expand_paths_for_language([], :ruby)
        expect(result).to eq([])
      end

      it "handles non-existent paths" do
        paths = ["/non/existent/path"]
        result = filter.expand_paths_for_language(paths, :ruby)
        expect(result).to eq([])
      end

      it "removes duplicate files" do
        paths = [
          File.join(temp_dir, "lib"),
          File.join(temp_dir, "lib", "main.rb") # This file is also in the lib directory
        ]
        result = filter.expand_paths_for_language(paths, :ruby)
        
        main_rb_count = result.count { |f| f.end_with?("main.rb") }
        expect(main_rb_count).to eq(1)
      end
    end
  end

  describe "#patterns_for" do
    it "delegates to file type detector" do
      patterns = filter.patterns_for(:ruby)
      expect(patterns).to be_an(Array)
      expect(patterns).to include("*.rb")
    end

    it "returns empty array for unknown language" do
      patterns = filter.patterns_for(:unknown)
      expect(patterns).to eq([])
    end
  end

  describe "#matches_language?" do
    it "delegates to file type detector" do
      expect(filter.matches_language?("file.rb", :ruby)).to be true
      expect(filter.matches_language?("file.md", :ruby)).to be false
    end
  end

  describe "integration with custom configuration" do
    let(:custom_config) do
      {
        file_patterns: {
          ruby: ["*.rb", "*.rake"],
          javascript: ["*.js", "*.jsx"]
        }
      }
    end
    let(:custom_filter) { described_class.new(config: custom_config) }

    it "uses custom patterns for filtering" do
      file_paths = ["app.rb", "tasks.rake", "script.js", "component.jsx", "README.md"]
      
      ruby_files = custom_filter.filter_by_language(file_paths, :ruby)
      expect(ruby_files).to contain_exactly("app.rb", "tasks.rake")
      
      js_files = custom_filter.filter_by_language(file_paths, :javascript)
      expect(js_files).to contain_exactly("script.js", "component.jsx")
    end

    it "expands directories using custom patterns" do
      # Create custom test files
      FileUtils.mkdir_p(File.join(temp_dir, "tasks"))
      File.write(File.join(temp_dir, "tasks", "deploy.rake"), "# Rake file")
      File.write(File.join(temp_dir, "app.js"), "// JavaScript file")

      paths = [temp_dir]
      ruby_files = custom_filter.expand_paths_for_language(paths, :ruby)
      js_files = custom_filter.expand_paths_for_language(paths, :javascript)
      
      expect(ruby_files).to include(File.join(temp_dir, "tasks", "deploy.rake"))
      expect(js_files).to include(File.join(temp_dir, "app.js"))
    end
  end
end