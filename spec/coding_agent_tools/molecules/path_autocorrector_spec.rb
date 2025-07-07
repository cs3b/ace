# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe CodingAgentTools::Molecules::PathAutocorrector do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_loader) { instance_double(CodingAgentTools::Molecules::PathConfigLoader) }
  let(:sandbox) { instance_double(CodingAgentTools::Molecules::ProjectSandbox) }
  let(:config) do
    {
      "repositories" => {
        "scan_order" => [
          { "name" => "tools-meta", "path" => ".", "priority" => 1 }
        ]
      },
      "resolution" => {
        "fuzzy" => {
          "min_similarity" => 0.5,
          "use_fzf" => true
        },
        "file_preferences" => {
          "preferred_extensions" => [".md", ".rb", ".yml"],
          "important_directories" => ["bin", "lib"]
        }
      },
      "integration" => {
        "tools" => {
          "fzf" => {
            "enabled" => true,
            "options" => "--height 40% --reverse"
          }
        }
      },
      "performance" => {
        "limits" => {
          "max_files_scan" => 100
        }
      }
    }
  end

  before do
    # Setup test directory structure
    FileUtils.mkdir_p(File.join(temp_dir, "lib"))
    FileUtils.mkdir_p(File.join(temp_dir, "bin"))
    FileUtils.mkdir_p(File.join(temp_dir, "docs"))
    
    # Create test files
    FileUtils.touch(File.join(temp_dir, "README.md"))
    FileUtils.touch(File.join(temp_dir, "lib", "test_module.rb"))
    FileUtils.touch(File.join(temp_dir, "lib", "testing_utils.rb"))
    FileUtils.touch(File.join(temp_dir, "bin", "test_script"))
    FileUtils.touch(File.join(temp_dir, "docs", "test_guide.md"))

    # Setup mocks
    allow(config_loader).to receive(:load).and_return(config)
    allow(sandbox).to receive(:project_root).and_return(temp_dir)
    allow(sandbox).to receive(:validate_path).and_return({ success: true, path: "/valid/path" })
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe "#initialize" do
    it "uses provided config loader and sandbox" do
      autocorrector = described_class.new(config_loader, sandbox)
      expect(autocorrector).to be_a(described_class)
    end

    it "creates default dependencies when not provided" do
      autocorrector = described_class.new
      expect(autocorrector).to be_a(described_class)
    end
  end

  describe "#autocorrect" do
    let(:autocorrector) { described_class.new(config_loader, sandbox) }

    context "with nil input" do
      it "returns failure" do
        result = autocorrector.autocorrect(nil)
        expect(result[:success]).to be false
        expect(result[:error]).to include("cannot be nil")
      end
    end

    context "with empty input" do
      it "returns failure" do
        result = autocorrector.autocorrect("")
        expect(result[:success]).to be false
        expect(result[:error]).to include("cannot be empty")
      end
    end

    context "with exact match" do
      it "returns exact match immediately" do
        exact_path = File.join(temp_dir, "README.md")
        allow(autocorrector).to receive(:find_exact_matches).and_return([exact_path])
        
        result = autocorrector.autocorrect("README.md")
        expect(result[:success]).to be true
        expect(result[:path]).to eq(exact_path)
      end
    end

    context "with fuzzy match needed" do
      it "finds similar files" do
        allow(autocorrector).to receive(:find_exact_matches).and_return([])
        allow(autocorrector).to receive(:find_candidates).and_return([File.join(temp_dir, "lib", "test_module.rb")])
        allow(autocorrector).to receive(:fzf_enabled?).and_return(false)
        
        result = autocorrector.autocorrect("test")
        expect(result[:success]).to be true
      end

      it "returns multiple suggestions when multiple good matches" do
        candidates = [
          File.join(temp_dir, "lib", "test_module.rb"),
          File.join(temp_dir, "lib", "testing_utils.rb")
        ]
        
        allow(autocorrector).to receive(:find_exact_matches).and_return([])
        allow(autocorrector).to receive(:find_candidates).and_return(candidates)
        allow(autocorrector).to receive(:fzf_enabled?).and_return(false)
        
        result = autocorrector.autocorrect("test")
        expect(result[:success]).to be true
        expect(result[:type]).to eq(:multiple)
      end
    end

    context "with no matches found" do
      it "returns failure" do
        allow(autocorrector).to receive(:find_exact_matches).and_return([])
        allow(autocorrector).to receive(:find_candidates).and_return([])
        
        result = autocorrector.autocorrect("nonexistent")
        expect(result[:success]).to be false
        expect(result[:error]).to include("No similar paths found")
      end
    end
  end

  describe "#suggest_corrections" do
    let(:autocorrector) { described_class.new(config_loader, sandbox) }

    it "returns scored suggestions" do
      candidates = [File.join(temp_dir, "lib", "test_module.rb")]
      allow(autocorrector).to receive(:find_candidates).and_return(candidates)
      
      suggestions = autocorrector.suggest_corrections("test", 3)
      expect(suggestions).to be_an(Array)
      
      if suggestions.any?
        suggestion = suggestions.first
        expect(suggestion).to have_key(:path)
        expect(suggestion).to have_key(:score)
        expect(suggestion).to have_key(:explanation)
      end
    end

    it "returns empty array for nil input" do
      suggestions = autocorrector.suggest_corrections(nil)
      expect(suggestions).to eq([])
    end
  end

  describe "#interactive_select" do
    let(:autocorrector) { described_class.new(config_loader, sandbox) }

    context "when FZF is available" do
      it "uses FZF for selection" do
        candidates = [File.join(temp_dir, "lib", "test_module.rb")]
        
        allow(autocorrector).to receive(:fzf_available?).and_return(true)
        allow(autocorrector).to receive(:fzf_enabled?).and_return(true)
        allow(autocorrector).to receive(:use_fzf_selection).with(candidates, "test").and_return({ success: true, path: candidates.first })

        result = autocorrector.interactive_select("test", candidates)
        expect(result[:success]).to be true
      end
    end

    context "when FZF is not available" do
      it "falls back to numbered selection" do
        candidates = [File.join(temp_dir, "lib", "test_module.rb")]
        
        allow(autocorrector).to receive(:fzf_available?).and_return(false)

        result = autocorrector.interactive_select("test", candidates)
        expect(result[:success]).to be true
        expect(result[:type]).to eq(:multiple)
      end
    end

    context "with no candidates" do
      it "returns failure" do
        result = autocorrector.interactive_select("test", [])
        expect(result[:success]).to be false
        expect(result[:error]).to include("No candidates found")
      end
    end
  end

  describe "similarity scoring" do
    let(:autocorrector) { described_class.new(config_loader, sandbox) }

    describe "#calculate_similarity_score" do
      it "gives exact matches highest score" do
        score = autocorrector.send(:calculate_similarity_score, "test", "test")
        expect(score).to eq(1.0)
      end

      it "gives substring matches high score" do
        score = autocorrector.send(:calculate_similarity_score, "test", "testing")
        expect(score).to eq(0.9)
      end

      it "calculates reasonable scores for partial matches" do
        score = autocorrector.send(:calculate_similarity_score, "test", "best")
        expect(score).to be > 0.0
        expect(score).to be < 0.9
      end
    end

    describe "#levenshtein_distance" do
      it "calculates edit distance correctly" do
        distance = autocorrector.send(:levenshtein_distance, "kitten", "sitting")
        expect(distance).to eq(3)
      end

      it "handles empty strings" do
        distance = autocorrector.send(:levenshtein_distance, "", "test")
        expect(distance).to eq(4)
      end

      it "handles identical strings" do
        distance = autocorrector.send(:levenshtein_distance, "test", "test")
        expect(distance).to eq(0)
      end
    end
  end

  describe "path generation and validation" do
    let(:autocorrector) { described_class.new(config_loader, sandbox) }

    describe "#generate_search_paths" do
      it "generates multiple search path variants" do
        paths = autocorrector.send(:generate_search_paths, "test")
        expect(paths).to be_an(Array)
        expect(paths).to include("test")
      end

      it "adds extensions for files without extensions" do
        paths = autocorrector.send(:generate_search_paths, "test")
        expect(paths).to include("test.md")
        expect(paths).to include("test.rb")
      end

      it "searches in important directories" do
        paths = autocorrector.send(:generate_search_paths, "test")
        bin_path = File.join(temp_dir, "bin", "test")
        lib_path = File.join(temp_dir, "lib", "test")
        
        expect(paths).to include(bin_path)
        expect(paths).to include(lib_path)
      end
    end

    describe "#matches_preferred_extensions?" do
      it "matches preferred file extensions" do
        expect(autocorrector.send(:matches_preferred_extensions?, "test.md")).to be true
        expect(autocorrector.send(:matches_preferred_extensions?, "test.rb")).to be true
        expect(autocorrector.send(:matches_preferred_extensions?, "test.yml")).to be true
      end

      it "rejects non-preferred extensions" do
        expect(autocorrector.send(:matches_preferred_extensions?, "test.exe")).to be false
        expect(autocorrector.send(:matches_preferred_extensions?, "test.bin")).to be false
      end
    end
  end

  describe "FZF integration" do
    let(:autocorrector) { described_class.new(config_loader, sandbox) }

    describe "#fzf_available?" do
      it "checks if fzf command is available" do
        allow(autocorrector).to receive(:system).with("which fzf > /dev/null 2>&1").and_return(true)
        expect(autocorrector.send(:fzf_available?)).to be true
      end

      it "caches the availability check" do
        allow(autocorrector).to receive(:system).with("which fzf > /dev/null 2>&1").and_return(true)
        
        # First call
        autocorrector.send(:fzf_available?)
        # Second call should use cached value
        autocorrector.send(:fzf_available?)
        
        expect(autocorrector).to have_received(:system).once
      end
    end

    describe "#fzf_enabled?" do
      it "returns false when fzf is not available" do
        allow(autocorrector).to receive(:fzf_available?).and_return(false)
        expect(autocorrector.send(:fzf_enabled?)).to be false
      end

      it "respects configuration settings" do
        allow(autocorrector).to receive(:fzf_available?).and_return(true)
        
        # Should be enabled by default based on config
        expect(autocorrector.send(:fzf_enabled?)).to be true
      end
    end
  end

  describe "relative path display" do
    let(:autocorrector) { described_class.new(config_loader, sandbox) }

    describe "#relative_path_for_display" do
      it "converts absolute paths to relative for display" do
        absolute_path = File.join(temp_dir, "lib", "test.rb")
        relative = autocorrector.send(:relative_path_for_display, absolute_path)
        expect(relative).to eq("lib/test.rb")
      end

      it "handles paths outside project gracefully" do
        outside_path = "/tmp/outside.rb"
        result = autocorrector.send(:relative_path_for_display, outside_path)
        # Should return the original path when it can't be made relative
        expect(result).to eq(outside_path)
      end
    end
  end
end