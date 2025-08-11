# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe CodingAgentTools::Cli::Commands::Search do
  let(:command) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    # Create test directory structure
    FileUtils.mkdir_p("#{temp_dir}/src")

    # Create test files
    File.write("#{temp_dir}/src/test.rb", <<~RUBY)
      class Test
        def method_with_todo
          # TODO: Implement this
          nil
        end
      end
    RUBY

    File.write("#{temp_dir}/README.md", <<~MD)
      # Test Project
      
      This is a test project for search functionality testing.
    MD
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#call" do
    context "with valid pattern" do
      it "executes content search successfully" do
        expect {
          command.call(
            pattern: "TODO",
            content: true,
            search_root: temp_dir
          )
        }.not_to raise_error
      end

      it "executes file search successfully" do
        expect {
          command.call(
            pattern: "*.rb",
            files: true,
            search_root: temp_dir
          )
        }.not_to raise_error
      end

      it "executes auto search successfully" do
        expect {
          command.call(
            pattern: "Test",
            type: "auto",
            search_root: temp_dir
          )
        }.not_to raise_error
      end
    end

    context "with search options" do
      it "respects case insensitive option" do
        expect {
          command.call(
            pattern: "test",
            content: true,
            case_insensitive: true,
            search_root: temp_dir
          )
        }.not_to raise_error
      end

      it "respects context option" do
        expect {
          command.call(
            pattern: "TODO",
            content: true,
            context: 2,
            search_root: temp_dir
          )
        }.not_to raise_error
      end

      it "respects max results option" do
        expect {
          command.call(
            pattern: "class",
            content: true,
            max_results: 1,
            search_root: temp_dir
          )
        }.not_to raise_error
      end
    end

    context "with output format options" do
      it "handles JSON output format" do
        expect {
          command.call(
            pattern: "Test",
            content: true,
            json: true,
            search_root: temp_dir
          )
        }.not_to raise_error
      end

      it "handles YAML output format" do
        expect {
          command.call(
            pattern: "Test",
            content: true,
            yaml: true,
            search_root: temp_dir
          )
        }.not_to raise_error
      end

      it "handles files-only output" do
        expect {
          command.call(
            pattern: "*.rb",
            files: true,
            files_with_matches: true,
            search_root: temp_dir
          )
        }.not_to raise_error
      end
    end

    context "with file filtering options" do
      it "respects glob option" do
        expect {
          command.call(
            pattern: "class",
            content: true,
            glob: "*.rb",
            search_root: temp_dir
          )
        }.not_to raise_error
      end

      it "respects include paths option" do
        expect {
          command.call(
            pattern: "TODO",
            content: true,
            include: "src/**",
            search_root: temp_dir
          )
        }.not_to raise_error
      end

      it "respects exclude paths option" do
        expect {
          command.call(
            pattern: "Test",
            content: true,
            exclude: "README.*",
            search_root: temp_dir
          )
        }.not_to raise_error
      end
    end

    context "with git scope options" do
      # These tests assume we're in a git repository
      # They test the option handling, not the actual git functionality

      it "handles staged option" do
        expect {
          command.call(
            pattern: "TODO",
            content: true,
            staged: true,
            search_root: temp_dir
          )
        }.not_to raise_error
      end

      it "handles tracked option" do
        expect {
          command.call(
            pattern: "TODO",
            content: true,
            tracked: true,
            search_root: temp_dir
          )
        }.not_to raise_error
      end

      it "handles changed option" do
        expect {
          command.call(
            pattern: "TODO",
            content: true,
            changed: true,
            search_root: temp_dir
          )
        }.not_to raise_error
      end
    end

    context "with preset functionality" do
      it "handles list presets option" do
        expect {
          command.call(list_presets: true)
        }.not_to raise_error
      end

      # Note: Actual preset testing would require preset files to exist
      # This tests the option handling structure
      it "handles preset option structure" do
        expect {
          command.call(
            pattern: "TODO",
            content: true,
            preset: "nonexistent", # Will error, but tests option handling
            search_root: temp_dir
          )
        }.to raise_error(SystemExit)
      end
    end

    context "with error conditions" do
      it "raises error for missing pattern" do
        expect {
          command.call(pattern: nil)
        }.to raise_error(SystemExit)
      end

      it "raises error for empty pattern" do
        expect {
          command.call(pattern: "")
        }.to raise_error(SystemExit)
      end

      it "raises error for nonexistent preset" do
        expect {
          command.call(
            pattern: "test",
            content: true,
            preset: "definitely_nonexistent_preset",
            search_root: temp_dir
          )
        }.to raise_error(SystemExit)
      end
    end

    context "option processing" do
      describe "#determine_search_type" do
        it "returns :file for files option" do
          options = {files: true}
          result = command.send(:determine_search_type, options)
          expect(result).to eq(:file)
        end

        it "returns :content for content option" do
          options = {content: true}
          result = command.send(:determine_search_type, options)
          expect(result).to eq(:content)
        end

        it "returns :auto by default" do
          options = {}
          result = command.send(:determine_search_type, options)
          expect(result).to eq(:auto)
        end

        it "returns specified type" do
          options = {type: "hybrid"}
          result = command.send(:determine_search_type, options)
          expect(result).to eq(:hybrid)
        end
      end

      describe "#determine_format" do
        it "returns :json for json option" do
          options = {json: true}
          result = command.send(:determine_format, options)
          expect(result).to eq(:json)
        end

        it "returns :yaml for yaml option" do
          options = {yaml: true}
          result = command.send(:determine_format, options)
          expect(result).to eq(:yaml)
        end

        it "returns :text by default" do
          options = {}
          result = command.send(:determine_format, options)
          expect(result).to eq(:text)
        end
      end

      describe "#determine_git_scope" do
        it "returns :staged for staged option" do
          options = {staged: true}
          result = command.send(:determine_git_scope, options)
          expect(result).to eq(:staged)
        end

        it "returns :tracked for tracked option" do
          options = {tracked: true}
          result = command.send(:determine_git_scope, options)
          expect(result).to eq(:tracked)
        end

        it "returns :changed for changed option" do
          options = {changed: true}
          result = command.send(:determine_git_scope, options)
          expect(result).to eq(:changed)
        end

        it "returns nil by default" do
          options = {}
          result = command.send(:determine_git_scope, options)
          expect(result).to be_nil
        end
      end

      describe "#parse_path_list" do
        it "parses comma-separated paths" do
          result = command.send(:parse_path_list, "path1,path2,path3")
          expect(result).to eq(["path1", "path2", "path3"])
        end

        it "trims whitespace" do
          result = command.send(:parse_path_list, "path1, path2 , path3")
          expect(result).to eq(["path1", "path2", "path3"])
        end

        it "returns empty array for nil" do
          result = command.send(:parse_path_list, nil)
          expect(result).to eq([])
        end

        it "returns empty array for empty string" do
          result = command.send(:parse_path_list, "")
          expect(result).to eq([])
        end
      end

      describe "#determine_exclude_paths" do
        let(:default_excludes) { ["exclude1", "exclude2"] }

        it "clears excludes for include_archived option" do
          options = {include_archived: true}
          result = command.send(:determine_exclude_paths, options, default_excludes)
          expect(result).to eq([])
        end

        it 'clears excludes for "none" exclude option' do
          options = {exclude: "none"}
          result = command.send(:determine_exclude_paths, options, default_excludes)
          expect(result).to eq([])
        end

        it "adds to default excludes for other exclude options" do
          options = {exclude: "exclude3,exclude4"}
          result = command.send(:determine_exclude_paths, options, default_excludes)
          expect(result).to eq(["exclude1", "exclude2", "exclude3", "exclude4"])
        end

        it "returns default excludes by default" do
          options = {}
          result = command.send(:determine_exclude_paths, options, default_excludes)
          expect(result).to eq(["exclude1", "exclude2"])
        end
      end
    end
  end

  # Integration test for the search mode determination logic
  describe "search mode determination" do
    let(:sample_results) do
      {
        results: [
          {file: "test.rb", line: 5, text: "def method"},
          {file: "README.md", line: 1, text: "# Test"}
        ],
        total_results: 2,
        metadata: {
          search_mode: :content,
          pattern: "test"
        }
      }
    end

    it "determines search mode from results metadata" do
      result = command.send(:determine_search_mode, sample_results)
      expect(result).to eq(:content)
    end

    it "falls back to content mode for flat results" do
      results_without_metadata = {results: [{file: "test.rb"}]}
      result = command.send(:determine_search_mode, results_without_metadata)
      expect(result).to eq(:content)
    end
  end

  # Test the result output formatting
  describe "result output formatting" do
    let(:sample_result) do
      {file: "test.rb", line: 5, column: 10, text: "def method"}
    end

    let(:file_only_result) do
      {file: "test.rb"}
    end

    it "formats single result with line and column" do
      options = {files_only: false}
      expect {
        command.send(:output_single_result, sample_result, options)
      }.to output(/test\.rb:5:10: def method/).to_stdout
    end

    it "formats file-only result" do
      options = {files_only: true}
      expect {
        command.send(:output_single_result, sample_result, options)
      }.to output(/test\.rb/).to_stdout
    end

    it "handles result without line number" do
      options = {files_only: false}
      expect {
        command.send(:output_single_result, file_only_result, options)
      }.to output(/test\.rb/).to_stdout
    end
  end
end
