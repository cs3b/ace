# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::Git::StatusColorFormatter do
  let(:formatter) { described_class.new }

  describe "#format_repository_status" do
    context "with git status output" do
      it "formats repository with changes" do
        status_output = <<~OUTPUT
           M lib/example.rb
           M docs/readme.md
        OUTPUT
        
        result = formatter.format_repository_status("test-repo", status_output)
        
        expect(result).to include("test-repo")
        expect(result).to include("lib/example.rb")
        expect(result).to include("docs/readme.md")
      end

      it "formats clean repository" do
        status_output = ""
        
        result = formatter.format_repository_status("clean-repo", status_output)
        
        expect(result).to include("clean-repo")
        expect(result).to include("clean")
      end

      it "formats repository with untracked files" do
        status_output = <<~OUTPUT
          ?? untracked_file.rb
          ?? docs/new.md
        OUTPUT
        
        result = formatter.format_repository_status("repo-with-untracked", status_output)
        
        expect(result).to include("repo-with-untracked")
        expect(result).to include("untracked_file.rb")
        expect(result).to include("docs/new.md")
      end

      it "formats repository with staged files" do
        status_output = <<~OUTPUT
          A  new_file.rb
          M  modified_file.rb
        OUTPUT
        
        result = formatter.format_repository_status("staged-repo", status_output)
        
        expect(result).to include("staged-repo")
        expect(result).to include("new_file.rb")
        expect(result).to include("modified_file.rb")
      end

      it "formats repository with deleted files" do
        status_output = <<~OUTPUT
           D deleted_file.rb
        OUTPUT
        
        result = formatter.format_repository_status("deletion-repo", status_output)
        
        expect(result).to include("deletion-repo")
        expect(result).to include("deleted_file.rb")
      end

      it "formats repository with renamed files" do
        status_output = <<~OUTPUT
          R  old_name.rb -> new_name.rb
        OUTPUT
        
        result = formatter.format_repository_status("rename-repo", status_output)
        
        expect(result).to include("rename-repo")
        expect(result).to include("old_name.rb")
        expect(result).to include("new_name.rb")
      end
    end

    context "with complex status combinations" do
      it "handles mixed file states" do
        status_output = <<~OUTPUT
          A  new_file.rb
           M modified_file.rb
           D deleted_file.rb
          ?? untracked_file.rb
        OUTPUT
        
        result = formatter.format_repository_status("complex-repo", status_output)
        
        expect(result).to include("complex-repo")
        expect(result).to include("new_file.rb")
        expect(result).to include("modified_file.rb")
        expect(result).to include("deleted_file.rb")
        expect(result).to include("untracked_file.rb")
      end

      it "handles staged and unstaged changes" do
        status_output = <<~OUTPUT
          MM both_changed.rb
          AM added_then_modified.rb
        OUTPUT
        
        result = formatter.format_repository_status("mixed-changes", status_output)
        
        expect(result).to include("mixed-changes")
        expect(result).to include("both_changed.rb")
        expect(result).to include("added_then_modified.rb")
      end
    end

    context "with special filenames" do
      it "handles files with spaces" do
        status_output = <<~OUTPUT
           M "file with spaces.rb"
        OUTPUT
        
        result = formatter.format_repository_status("spaces-repo", status_output)
        
        expect(result).to include("spaces-repo")
        expect(result).to include("file with spaces.rb")
      end

      it "handles files with special characters" do
        status_output = <<~OUTPUT
           M "file-with-dashes_and_underscores.rb"
        OUTPUT
        
        result = formatter.format_repository_status("special-repo", status_output)
        
        expect(result).to include("special-repo")
        expect(result).to include("file-with-dashes_and_underscores.rb")
      end
    end

    context "with empty or invalid input" do
      it "handles empty status output" do
        result = formatter.format_repository_status("empty-repo", "")
        
        expect(result).to include("empty-repo")
        expect(result).to include("Clean")
      end

      it "handles nil input" do
        expect { formatter.format_repository_status("nil-repo", nil) }.to raise_error(NoMethodError)
      end

      it "handles clean repository status" do
        status_output = "On branch main\nnothing to commit, working tree clean"
        
        result = formatter.format_repository_status("truly-clean", status_output)
        
        expect(result).to include("truly-clean")
      end
    end

    context "with performance considerations" do
      it "handles large status outputs efficiently" do
        # Create a large status output
        large_status = (1..100).map { |i| "   M file#{i}.rb" }.join("\n")
        
        start_time = Time.now
        result = formatter.format_repository_status("large-repo", large_status)
        end_time = Time.now
        
        expect(result).to include("large-repo")
        expect(end_time - start_time).to be < 1.0  # Should complete quickly
      end
    end
  end

  describe ".format_repository_status" do
    it "works as a class method" do
      status_output = "   M test_file.rb"
      
      result = described_class.format_repository_status("class-method-repo", status_output)
      
      expect(result).to include("class-method-repo")
      expect(result).to include("test_file.rb")
    end

    it "accepts options" do
      status_output = "   M test_file.rb"
      
      result = described_class.format_repository_status("options-repo", status_output, no_color: true)
      
      expect(result).to include("options-repo")
      expect(result).to include("test_file.rb")
    end
  end

  describe "#should_use_color?" do
    it "returns true by default" do
      expect(formatter.should_use_color?).to be true
    end

    it "returns false when no_color option is set" do
      no_color_formatter = described_class.new(no_color: true)
      expect(no_color_formatter.should_use_color?).to be false
    end

    it "returns true when force_color option is set" do
      force_color_formatter = described_class.new(force_color: true)
      expect(force_color_formatter.should_use_color?).to be true
    end
  end

  describe ".should_use_color?" do
    it "works as a class method" do
      expect(described_class.should_use_color?).to be true
    end

    it "accepts options" do
      expect(described_class.should_use_color?(no_color: true)).to be false
    end
  end

  describe "color handling" do
    context "with colors enabled" do
      let(:color_formatter) { described_class.new(no_color: false) }

      it "includes ANSI color codes in output" do
        status_output = "   M colored_file.rb"
        result = color_formatter.format_repository_status("color-repo", status_output)
        
        expect(result).to match(/\e\[\d+m/)  # Contains ANSI color codes
      end
    end

    context "with colors disabled" do
      let(:no_color_formatter) { described_class.new(no_color: true) }

      it "excludes ANSI color codes from output" do
        status_output = "   M plain_file.rb"
        result = no_color_formatter.format_repository_status("plain-repo", status_output)
        
        expect(result).not_to match(/\e\[\d+m/)  # No ANSI color codes
      end
    end
  end
end