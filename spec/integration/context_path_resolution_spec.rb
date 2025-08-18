# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"
require "fileutils"
require_relative "../../lib/coding_agent_tools/molecules/context/context_aggregator"

RSpec.describe "Context Path Resolution Integration" do
  let(:temp_dir) { Dir.mktmpdir("context_test") }
  let(:project_root) { temp_dir }
  let(:subdirectory) { File.join(temp_dir, "subdir") }
  let(:nested_subdirectory) { File.join(temp_dir, "subdir", "nested") }
  let(:test_file) { File.join(temp_dir, "test.txt") }
  let(:nested_test_file) { File.join(temp_dir, "subdir", "nested_test.txt") }

  before do
    # Create test directory structure
    FileUtils.mkdir_p(subdirectory)
    FileUtils.mkdir_p(nested_subdirectory)
    
    # Create test files
    File.write(test_file, "Content from project root file\n")
    File.write(nested_test_file, "Content from nested file\n")
    
    # Create a .git directory to mark as project root
    FileUtils.mkdir_p(File.join(temp_dir, ".git"))
    
    # Set up environment variable for project root
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PROJECT_ROOT").and_return(project_root)
    
    # Reset ProjectRootDetector cache
    CodingAgentTools::Atoms::ProjectRootDetector.reset_cache!
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "running context tool from project root" do
    it "resolves relative file paths correctly" do
      Dir.chdir(project_root) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: ["test.txt"],
          commands: []
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:files].size).to eq(1)
        expect(result[:files].first[:path]).to eq(test_file)
        expect(result[:files].first[:content]).to include("Content from project root file")
        expect(result[:errors]).to be_empty
      end
    end

    it "resolves glob patterns correctly" do
      Dir.chdir(project_root) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: ["*.txt"],
          commands: []
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:files].size).to eq(1)
        expect(result[:files].first[:path]).to eq(test_file)
        expect(result[:errors]).to be_empty
      end
    end

    it "executes commands from project root" do
      Dir.chdir(project_root) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: [],
          commands: ["pwd"]
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:commands].size).to eq(1)
        expect(result[:commands].first[:success]).to be true
        expect(File.realpath(result[:commands].first[:output].strip)).to eq(File.realpath(project_root))
        expect(result[:errors]).to be_empty
      end
    end
  end

  describe "running context tool from subdirectory" do
    it "resolves relative file paths correctly from subdirectory" do
      Dir.chdir(subdirectory) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: ["test.txt"],
          commands: []
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:files].size).to eq(1)
        expect(result[:files].first[:path]).to eq(test_file)
        expect(result[:files].first[:content]).to include("Content from project root file")
        expect(result[:errors]).to be_empty
      end
    end

    it "resolves nested file paths correctly from subdirectory" do
      Dir.chdir(subdirectory) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: ["subdir/nested_test.txt"],
          commands: []
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:files].size).to eq(1)
        expect(result[:files].first[:path]).to eq(nested_test_file)
        expect(result[:files].first[:content]).to include("Content from nested file")
        expect(result[:errors]).to be_empty
      end
    end

    it "resolves glob patterns correctly from subdirectory" do
      Dir.chdir(subdirectory) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: ["*.txt"],
          commands: []
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:files].size).to eq(1)
        expect(result[:files].first[:path]).to eq(test_file)
        expect(result[:errors]).to be_empty
      end
    end

    it "executes commands from project root even when called from subdirectory" do
      Dir.chdir(subdirectory) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: [],
          commands: ["pwd"]
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:commands].size).to eq(1)
        expect(result[:commands].first[:success]).to be true
        expect(File.realpath(result[:commands].first[:output].strip)).to eq(File.realpath(project_root))
        expect(result[:errors]).to be_empty
      end
    end
  end

  describe "running context tool from nested subdirectory" do
    it "resolves relative file paths correctly from nested subdirectory" do
      Dir.chdir(nested_subdirectory) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: ["test.txt"],
          commands: []
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:files].size).to eq(1)
        expect(result[:files].first[:path]).to eq(test_file)
        expect(result[:files].first[:content]).to include("Content from project root file")
        expect(result[:errors]).to be_empty
      end
    end

    it "executes commands from project root even when called from nested subdirectory" do
      Dir.chdir(nested_subdirectory) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: [],
          commands: ["pwd"]
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:commands].size).to eq(1)
        expect(result[:commands].first[:success]).to be true
        expect(File.realpath(result[:commands].first[:output].strip)).to eq(File.realpath(project_root))
        expect(result[:errors]).to be_empty
      end
    end
  end

  describe "absolute paths handling" do
    it "handles absolute file paths correctly" do
      Dir.chdir(subdirectory) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: [test_file],  # absolute path
          commands: []
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:files].size).to eq(1)
        expect(result[:files].first[:path]).to eq(test_file)
        expect(result[:files].first[:content]).to include("Content from project root file")
        expect(result[:errors]).to be_empty
      end
    end
  end

  describe "command execution independence" do
    it "executes each command independently from project root" do
      # Create a subdirectory-specific file
      subdir_file = File.join(subdirectory, "subdir_only.txt")
      File.write(subdir_file, "Only in subdir\n")
      
      Dir.chdir(nested_subdirectory) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: [],
          commands: [
            "pwd",
            "ls -la test.txt 2>/dev/null || echo 'test.txt not found in current dir'",
            "cd subdir && pwd"
          ]
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:commands].size).to eq(3)
        
        # First command: pwd should show project root
        expect(result[:commands][0][:success]).to be true
        expect(File.realpath(result[:commands][0][:output].strip)).to eq(File.realpath(project_root))
        
        # Second command: should find test.txt because we're running from project root
        expect(result[:commands][1][:success]).to be true
        expect(result[:commands][1][:output]).not_to include("not found")
        
        # Third command: should show that cd still works within the command context
        expect(result[:commands][2][:success]).to be true
        expect(File.realpath(result[:commands][2][:output].strip)).to eq(File.realpath(subdirectory))
        
        expect(result[:errors]).to be_empty
      end
    end
  end

  describe "error handling" do
    it "handles non-existent files gracefully" do
      Dir.chdir(subdirectory) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: ["nonexistent.txt"],
          commands: []
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:files]).to be_empty
        expect(result[:errors]).to include("No files found matching pattern: nonexistent.txt")
      end
    end

    it "handles command failures gracefully" do
      Dir.chdir(subdirectory) do
        aggregator = CodingAgentTools::Molecules::Context::ContextAggregator.new
        
        template = {
          files: [],
          commands: ["false"]  # command that always fails
        }
        
        result = aggregator.aggregate(template)
        
        expect(result[:commands].size).to eq(1)
        expect(result[:commands].first[:success]).to be false
        expect(result[:errors]).to include(match(/Command failed: false/))
      end
    end
  end
end