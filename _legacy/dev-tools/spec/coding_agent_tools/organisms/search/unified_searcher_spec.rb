# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe CodingAgentTools::Organisms::Search::UnifiedSearcher do
  let(:searcher) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    # Create test directory structure
    FileUtils.mkdir_p("#{temp_dir}/src")
    FileUtils.mkdir_p("#{temp_dir}/spec")
    FileUtils.mkdir_p("#{temp_dir}/docs")

    # Create test files with content
    File.write("#{temp_dir}/src/user.rb", <<~RUBY)
      class User
        def initialize(name)
          @name = name
          # TODO: Add email validation
        end

        def greet
          "Hello, \#{@name}!"
        end
      end
    RUBY

    File.write("#{temp_dir}/src/helper.js", <<~JS)
      function helper() {
        // TODO: Implement this function
        return null;
      }
    JS

    File.write("#{temp_dir}/spec/user_spec.rb", <<~RUBY)
      require 'spec_helper'

      RSpec.describe User do
        it "initializes with name" do
          user = User.new("Alice")
          expect(user.greet).to eq("Hello, Alice!")
        end
      end
    RUBY

    File.write("#{temp_dir}/docs/README.md", <<~MD)
      # Project Documentation
      
      This is a sample project for testing search functionality.
      
      ## Features
      
      - User management
      - Helper functions
    MD
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#search" do
    context "with content search" do
      it "finds text in file contents" do
        options = {type: :content, search_root: temp_dir}
        results = searcher.search("TODO", options)

        expect(results[:success]).to be true
        expect(results[:total_results]).to be >= 2
        expect(results[:results]).to be_an(Array)

        # Should find TODO comments in both Ruby and JS files
        files_with_todos = results[:results].map { |r| r[:file] }
        expect(files_with_todos).to include(match(/user\.rb/))
        expect(files_with_todos).to include(match(/helper\.js/))
      end

      it "finds method definitions with regex patterns" do
        options = {type: :content, search_root: temp_dir}
        results = searcher.search('def \w+', options)

        expect(results[:success]).to be true
        expect(results[:total_results]).to be >= 2

        # Should find initialize and greet methods
        method_matches = results[:results].map { |r| r[:text] }
        expect(method_matches).to include(match(/def initialize/))
        expect(method_matches).to include(match(/def greet/))
      end

      it "respects case insensitive option" do
        options = {type: :content, search_root: temp_dir, case_insensitive: true}
        results = searcher.search("USER", options)

        expect(results[:success]).to be true
        expect(results[:total_results]).to be > 0

        # Should find "User" class despite case mismatch
        matches = results[:results].map { |r| r[:text] }
        expect(matches).to include(match(/User/))
      end

      it "provides context lines when requested" do
        options = {type: :content, search_root: temp_dir, show_context: 2}
        results = searcher.search("TODO", options)

        expect(results[:success]).to be true

        # Context should be included in the result structure
        todo_result = results[:results].find { |r| r[:text]&.include?("TODO") }
        expect(todo_result).not_to be_nil
      end
    end

    context "with file search" do
      it "finds files by extension glob patterns" do
        options = {type: :file, search_root: temp_dir}
        results = searcher.search("*.rb", options)

        expect(results[:success]).to be true
        expect(results[:total_results]).to be >= 2

        # Should find both Ruby files
        ruby_files = results[:results].map { |r| r[:file] || r[:path] || r }
        expect(ruby_files).to include(match(/user\.rb/))
        expect(ruby_files).to include(match(/user_spec\.rb/))
      end

      it "finds files with recursive glob patterns" do
        options = {type: :file, search_root: temp_dir}
        results = searcher.search("**/*.rb", options)

        expect(results[:success]).to be true
        expect(results[:total_results]).to be >= 2
      end

      it "finds files by name pattern" do
        options = {type: :file, search_root: temp_dir}
        results = searcher.search("user*", options)

        expect(results[:success]).to be true
        expect(results[:total_results]).to be >= 2

        user_files = results[:results].map { |r| r[:file] || r[:path] || r }
        expect(user_files).to include(match(/user\.rb/))
        expect(user_files).to include(match(/user_spec\.rb/))
      end
    end

    context "with hybrid/auto mode" do
      it "automatically detects file patterns and searches files" do
        options = {type: :auto, search_root: temp_dir}
        results = searcher.search("*.md", options)

        expect(results[:success]).to be true
        expect(results[:total_results]).to be >= 1

        # Should find README.md
        files = results[:results].map { |r| r[:file] || r[:path] || r }
        expect(files).to include(match(/README\.md/))
      end

      it "automatically detects content patterns and searches content" do
        options = {type: :auto, search_root: temp_dir}
        results = searcher.search("Project Documentation", options)

        expect(results[:success]).to be true
        expect(results[:total_results]).to be >= 1

        # Should find the text in README.md
        matches = results[:results].map { |r| r[:text] }
        expect(matches).to include(match(/Project Documentation/))
      end

      it "handles ambiguous patterns appropriately" do
        options = {type: :auto, search_root: temp_dir}
        results = searcher.search("user", options)

        expect(results[:success]).to be true
        expect(results[:total_results]).to be > 0

        # Could find files or content, both are valid
        expect(results[:results]).not_to be_empty
      end
    end

    context "with path filtering" do
      it "includes only specified paths" do
        options = {
          type: :content,
          search_root: temp_dir,
          include_paths: ["src/**"]
        }
        results = searcher.search("TODO", options)

        expect(results[:success]).to be true

        # Should only find TODOs in src directory
        files = results[:results].map { |r| r[:file] }
        files.each do |file|
          expect(file).to include("src/")
        end
      end

      it "excludes specified paths" do
        options = {
          type: :content,
          search_root: temp_dir,
          exclude_paths: ["spec/**"]
        }
        results = searcher.search("User", options)

        expect(results[:success]).to be true

        # Should not find matches in spec directory
        files = results[:results].map { |r| r[:file] }
        spec_files = files.select { |file| file.include?("spec/") }
        expect(spec_files).to be_empty
      end
    end

    context "with glob filtering" do
      it "applies glob patterns to filter files" do
        options = {
          type: :content,
          search_root: temp_dir,
          glob: "*.rb"
        }
        results = searcher.search("function", options)

        expect(results[:success]).to be true

        # Should only search in Ruby files, so shouldn't find JS function
        files = results[:results].map { |r| r[:file] }
        js_files = files.select { |file| file.end_with?(".js") }
        expect(js_files).to be_empty
      end
    end

    context "with result limiting" do
      it "respects max_results limit" do
        options = {
          type: :content,
          search_root: temp_dir,
          max_results: 1
        }
        results = searcher.search("def", options)

        expect(results[:success]).to be true
        expect(results[:results].length).to eq(1)
        expect(results[:total_results]).to eq(1)
      end
    end

    context "with no results" do
      it "handles no matches gracefully" do
        options = {type: :content, search_root: temp_dir}
        results = searcher.search("nonexistent_pattern_12345", options)

        expect(results[:success]).to be true
        expect(results[:total_results]).to eq(0)
        expect(results[:results]).to be_empty
      end
    end

    context "with invalid patterns" do
      it "handles empty pattern gracefully" do
        options = {type: :content, search_root: temp_dir}
        results = searcher.search("", options)

        expect(results[:success]).to be false
        expect(results[:error]).to be_present
        expect(results[:error]).to include("empty")
      end

      it "handles nil pattern gracefully" do
        options = {type: :content, search_root: temp_dir}
        results = searcher.search(nil, options)

        expect(results[:success]).to be false
        expect(results[:error]).to be_present
        expect(results[:error]).to include("nil")
      end

      it "handles invalid regex patterns" do
        options = {type: :content, search_root: temp_dir}
        results = searcher.search("[invalid", options)

        # Should either succeed with literal search or fail gracefully
        if results[:success]
          # Treated as literal pattern
          expect(results[:total_results]).to eq(0)
        else
          # Failed due to invalid regex
          expect(results[:error]).to be_present
        end
      end
    end

    context "with nonexistent directory" do
      it "handles missing search root gracefully" do
        options = {type: :content, search_root: "/nonexistent/path"}
        results = searcher.search("anything", options)

        expect(results[:success]).to be false
        expect(results[:error]).to be_present
      end
    end

    context "with metadata" do
      it "includes search metadata in results" do
        options = {type: :content, search_root: temp_dir}
        results = searcher.search("TODO", options)

        expect(results[:metadata]).to be_present
        expect(results[:metadata][:pattern]).to eq("TODO")
        expect(results[:metadata][:search_mode]).to be_present
        expect(results[:metadata][:options]).to be_present
      end
    end
  end

  describe "#search with edge cases" do
    let(:edge_case_dir) { Dir.mktmpdir }

    before do
      # Create edge case files
      File.write("#{edge_case_dir}/unicode_file.txt", "Héllo Wörld! 🚀\nUnicode content with émojis 😀")
      File.write("#{edge_case_dir}/large_line.txt", "x" * 5000)
      File.write("#{edge_case_dir}/empty_file.txt", "")

      # Create binary-like file
      File.write("#{edge_case_dir}/binary_like.dat", "\x00\x01\x02\x03" * 100)

      # Create file with unusual name
      File.write("#{edge_case_dir}/file with spaces.txt", "content with spaces")
      File.write("#{edge_case_dir}/file-with-dashes.txt", "content with dashes")
      File.write("#{edge_case_dir}/.hidden_file", "hidden content")
    end

    after do
      FileUtils.rm_rf(edge_case_dir)
    end

    it "handles Unicode content properly" do
      options = {type: :content, search_root: edge_case_dir}
      results = searcher.search("Héllo", options)

      expect(results[:success]).to be true
      expect(results[:total_results]).to be >= 1
    end

    it "handles files with spaces in names" do
      options = {type: :content, search_root: edge_case_dir}
      results = searcher.search("spaces", options)

      expect(results[:success]).to be true
      expect(results[:total_results]).to be >= 1
    end

    it "handles empty files gracefully" do
      options = {type: :content, search_root: edge_case_dir}
      results = searcher.search("anything", options)

      expect(results[:success]).to be true
      # Empty files shouldn't cause errors, just no matches
    end

    it "skips binary files" do
      options = {type: :content, search_root: edge_case_dir}
      results = searcher.search("anything", options)

      expect(results[:success]).to be true
      # Binary files should be skipped without causing errors
      files = results[:results].map { |r| r[:file] }
      binary_results = files.select { |f| f.include?("binary_like.dat") }
      expect(binary_results).to be_empty
    end

    it "finds hidden files when appropriate" do
      options = {type: :content, search_root: edge_case_dir}
      results = searcher.search("hidden", options)

      expect(results[:success]).to be true
      if results[:total_results] > 0
        files = results[:results].map { |r| r[:file] }
        hidden_results = files.select { |f| f.include?(".hidden_file") }
        expect(hidden_results).not_to be_empty
      end
    end
  end

  describe "performance considerations" do
    let(:perf_dir) { Dir.mktmpdir }

    before do
      # Create many small files for performance testing
      10.times do |i|
        File.write("#{perf_dir}/file_#{i}.txt", "content #{i}\nTEST content in file #{i}")
      end
    end

    after do
      FileUtils.rm_rf(perf_dir)
    end

    it "completes search within reasonable time" do
      options = {type: :content, search_root: perf_dir}

      start_time = Time.now
      results = searcher.search("TEST", options)
      end_time = Time.now

      expect(results[:success]).to be true
      expect(end_time - start_time).to be < 5.0 # Should complete within 5 seconds
    end

    it "handles max_results efficiently" do
      options = {type: :content, search_root: perf_dir, max_results: 3}

      start_time = Time.now
      results = searcher.search("content", options)
      end_time = Time.now

      expect(results[:success]).to be true
      expect(results[:results].length).to be <= 3
      expect(end_time - start_time).to be < 2.0 # Should be faster with limit
    end
  end
end
