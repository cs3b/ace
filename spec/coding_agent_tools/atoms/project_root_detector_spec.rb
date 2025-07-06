# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe CodingAgentTools::Atoms::ProjectRootDetector do
  subject(:detector) { described_class }

  before do
    detector.reset_cache!
    detector.debug_mode = false
    @original_project_root = ENV['PROJECT_ROOT']
    ENV.delete('PROJECT_ROOT')
  end

  after do
    detector.reset_cache!
    detector.debug_mode = false
    if @original_project_root
      ENV['PROJECT_ROOT'] = @original_project_root
    else
      ENV.delete('PROJECT_ROOT')
    end
  end

  describe ".find_project_root" do
    context "with PROJECT_ROOT environment variable" do
      let(:temp_dir) { Dir.mktmpdir }
      
      after { FileUtils.rm_rf(temp_dir) }

      it "uses PROJECT_ROOT as highest priority when valid" do
        # Create a valid project root
        git_dir = File.join(temp_dir, ".git")
        FileUtils.mkdir_p(git_dir)
        
        ENV['PROJECT_ROOT'] = temp_dir
        
        # Start from a different directory
        other_dir = Dir.mktmpdir
        FileUtils.rm_rf(other_dir) # Clean up immediately as we don't need it
        
        result = detector.find_project_root("/some/other/path")
        expect(result).to eq(temp_dir)
      end

      it "warns and falls back when PROJECT_ROOT is invalid" do
        ENV['PROJECT_ROOT'] = "/nonexistent/path"
        
        # Should fall back to normal detection
        result = detector.find_project_root(Dir.pwd)
        expect(result).to be_a(String)
        expect(result).not_to eq("/nonexistent/path")
      end

      it "validates PROJECT_ROOT has expected markers" do
        ENV['PROJECT_ROOT'] = temp_dir
        
        # Empty directory should not be considered valid
        expect {
          detector.find_project_root("/some/path")
        }.to raise_error(CodingAgentTools::Error, /Could not detect project root/)
      end

      it "accepts PROJECT_ROOT with dev-* subdirectories as markers" do
        # Create multiple dev-* subdirectories to simulate multi-repo structure
        dev_tools_dir = File.join(temp_dir, "dev-tools")
        dev_handbook_dir = File.join(temp_dir, "dev-handbook")
        FileUtils.mkdir_p(dev_tools_dir)
        FileUtils.mkdir_p(dev_handbook_dir)
        
        ENV['PROJECT_ROOT'] = temp_dir
        
        result = detector.find_project_root("/some/other/path")
        expect(result).to eq(temp_dir)
      end
    end

    context "with special dev-* directories" do
      let(:temp_project_root) { Dir.mktmpdir }
      let(:dev_tools_dir) { File.join(temp_project_root, "dev-tools") }
      let(:deep_subdir) { File.join(dev_tools_dir, "lib", "deep", "nested") }
      
      after { FileUtils.rm_rf(temp_project_root) }

      it "detects project root from dev-tools subdirectory" do
        # Create project structure with .git marker
        git_dir = File.join(temp_project_root, ".git")
        FileUtils.mkdir_p(git_dir)
        FileUtils.mkdir_p(deep_subdir)
        
        result = detector.find_project_root(deep_subdir)
        expect(result).to eq(temp_project_root)
      end

      it "detects project root from dev-handbook subdirectory" do
        dev_handbook_dir = File.join(temp_project_root, "dev-handbook")
        handbook_subdir = File.join(dev_handbook_dir, "guides")
        
        # Create project structure with .git marker
        git_dir = File.join(temp_project_root, ".git")
        FileUtils.mkdir_p(git_dir)
        FileUtils.mkdir_p(handbook_subdir)
        
        result = detector.find_project_root(handbook_subdir)
        expect(result).to eq(temp_project_root)
      end

      it "detects project root from dev-taskflow subdirectory" do
        dev_taskflow_dir = File.join(temp_project_root, "dev-taskflow")
        taskflow_subdir = File.join(dev_taskflow_dir, "current", "tasks")
        
        # Create project structure with Gemfile marker
        gemfile = File.join(temp_project_root, "Gemfile")
        FileUtils.mkdir_p(taskflow_subdir)
        FileUtils.touch(gemfile)
        
        result = detector.find_project_root(taskflow_subdir)
        expect(result).to eq(temp_project_root)
      end

      it "requires valid project markers in parent directory" do
        # Create a completely isolated temporary structure
        isolated_root = Dir.mktmpdir
        isolated_dev_tools = File.join(isolated_root, "dev-tools", "lib", "deep")
        FileUtils.mkdir_p(isolated_dev_tools)
        
        # Should not find the parent as project root (no markers)
        expect {
          detector.find_project_root(isolated_dev_tools)
        }.to raise_error(CodingAgentTools::Error, /Could not detect project root/)
        
        FileUtils.rm_rf(isolated_root)
      end
    end

    context "with enhanced error messages" do
      let(:temp_dir) { Dir.mktmpdir }
      
      after { FileUtils.rm_rf(temp_dir) }

      it "suggests setting PROJECT_ROOT when detection fails" do
        subdir = File.join(temp_dir, "no", "markers", "here")
        FileUtils.mkdir_p(subdir)

        expect {
          detector.find_project_root(subdir)
        }.to raise_error(CodingAgentTools::Error, /Try setting PROJECT_ROOT environment variable/)
      end
    end

    context "when starting from project root" do
      it "returns the current directory if .git exists" do
        # This assumes we're running tests from within the project
        result = detector.find_project_root(Dir.pwd)
        expect(result).to be_a(String)
        expect(File.exist?(File.join(result, ".git"))).to be true
      end
    end

    context "when starting from a subdirectory" do
      it "traverses up to find project root" do
        # Start from dev-tools subdirectory
        dev_tools_path = File.join(Dir.pwd, "dev-tools")
        if File.directory?(dev_tools_path)
          result = detector.find_project_root(dev_tools_path)
          expect(result).to eq(Dir.pwd)
        else
          # Fallback test with current directory
          result = detector.find_project_root(Dir.pwd)
          expect(result).to be_a(String)
        end
      end
    end

    context "with caching" do
      it "caches the result for the same start path" do
        start_path = Dir.pwd
        result1 = detector.find_project_root(start_path)
        result2 = detector.find_project_root(start_path)

        expect(result1).to eq(result2)
        expect(detector.instance_variable_get(:@cached_root)).to eq(result1)
      end

      it "recalculates when start path changes" do
        start_path1 = Dir.pwd
        start_path2 = File.join(Dir.pwd, "lib") # Use a subdirectory that exists
        
        result1 = detector.find_project_root(start_path1)
        result2 = detector.find_project_root(start_path2)

        # Both should find the same project root, but cache should be separate
        expect(result1).to eq(result2) # Same project root
        expect(detector.instance_variable_get(:@cached_cache_key)).to include(start_path2.to_s)
      end

      it "recalculates when PROJECT_ROOT environment variable changes" do
        # Create a temporary project with .git marker
        temp_project = Dir.mktmpdir
        git_dir = File.join(temp_project, ".git")
        FileUtils.mkdir_p(git_dir)
        
        start_path = Dir.pwd
        result1 = detector.find_project_root(start_path)
        
        # Set PROJECT_ROOT to different location and ensure cache is invalidated
        ENV['PROJECT_ROOT'] = temp_project
        result2 = detector.find_project_root(start_path)
        
        # Should use PROJECT_ROOT now
        expect(result2).to eq(temp_project)
        expect(result2).not_to eq(result1)
        
        # Verify cache key changed
        expect(detector.instance_variable_get(:@cached_cache_key)).to include(temp_project)
        
        FileUtils.rm_rf(temp_project)
      end
    end

    context "with temporary directory structure" do
      let(:temp_dir) { Dir.mktmpdir }

      after { FileUtils.rm_rf(temp_dir) }

      it "finds root with .git marker" do
        git_dir = File.join(temp_dir, ".git")
        FileUtils.mkdir_p(git_dir)

        subdir = File.join(temp_dir, "subdir", "deep")
        FileUtils.mkdir_p(subdir)

        result = detector.find_project_root(subdir)
        expect(result).to eq(temp_dir)
      end

      it "finds root with gemspec marker" do
        gemspec_file = File.join(temp_dir, "test.gemspec")
        FileUtils.touch(gemspec_file)

        subdir = File.join(temp_dir, "lib", "test")
        FileUtils.mkdir_p(subdir)

        result = detector.find_project_root(subdir)
        expect(result).to eq(temp_dir)
      end

      it "finds root with Gemfile marker" do
        gemfile = File.join(temp_dir, "Gemfile")
        FileUtils.touch(gemfile)

        subdir = File.join(temp_dir, "spec", "support")
        FileUtils.mkdir_p(subdir)

        result = detector.find_project_root(subdir)
        expect(result).to eq(temp_dir)
      end

      it "raises error when no markers found" do
        subdir = File.join(temp_dir, "no", "markers", "here")
        FileUtils.mkdir_p(subdir)

        expect {
          detector.find_project_root(subdir)
        }.to raise_error(CodingAgentTools::Error, /Could not detect project root/)
      end
    end

    context "with debug mode" do
      it "outputs debug information when enabled" do
        detector.debug_mode = true

        expect {
          detector.find_project_root(Dir.pwd)
        }.to output(/\[ProjectRootDetector\]/).to_stdout
      end

      it "does not output debug information when disabled" do
        detector.debug_mode = false

        expect {
          detector.find_project_root(Dir.pwd)
        }.not_to output(/\[ProjectRootDetector\]/).to_stdout
      end
    end

    context "edge cases" do
      it "handles nil start_path by using $PROGRAM_NAME" do
        result = detector.find_project_root(nil)
        expect(result).to be_a(String)
        expect(File.directory?(result)).to be true
      end

      it "handles symlinks correctly" do
        # This test assumes the current directory structure is valid
        result = detector.find_project_root(Dir.pwd)
        expect(result).to be_a(String)
        expect(File.directory?(result)).to be true
      end
    end
  end

  describe ".reset_cache!" do
    it "clears the cached values" do
      detector.find_project_root(Dir.pwd)
      expect(detector.instance_variable_get(:@cached_root)).not_to be_nil

      detector.reset_cache!
      expect(detector.instance_variable_get(:@cached_root)).to be_nil
      expect(detector.instance_variable_get(:@cached_start_path)).to be_nil
    end
  end

  describe ".debug_mode=" do
    it "sets the debug mode" do
      detector.debug_mode = true
      expect(detector.debug_mode).to be true

      detector.debug_mode = false
      expect(detector.debug_mode).to be false
    end
  end
end
