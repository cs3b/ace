# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::Git::StatusColorFormatter do
  let(:formatter) { described_class.new }

  describe "#format" do
    context "with git status output" do
      it "formats modified files with colors" do
        status_output = <<~OUTPUT
           M lib/example.rb
           M docs/readme.md
        OUTPUT
        
        result = formatter.format(status_output)
        
        expect(result).to include("\e[33m")  # Yellow for modified
        expect(result).to include("lib/example.rb")
        expect(result).to include("docs/readme.md")
      end

      it "formats added files with green color" do
        status_output = <<~OUTPUT
          A  new_file.rb
          A  docs/new.md
        OUTPUT
        
        result = formatter.format(status_output)
        
        expect(result).to include("\e[32m")  # Green for added
        expect(result).to include("new_file.rb")
      end

      it "formats deleted files with red color" do
        status_output = <<~OUTPUT
           D old_file.rb
           D docs/old.md
        OUTPUT
        
        result = formatter.format(status_output)
        
        expect(result).to include("\e[31m")  # Red for deleted
        expect(result).to include("old_file.rb")
      end

      it "formats renamed files" do
        status_output = <<~OUTPUT
          R  old_name.rb -> new_name.rb
        OUTPUT
        
        result = formatter.format(status_output)
        
        expect(result).to include("\e[36m")  # Cyan for renamed
        expect(result).to include("old_name.rb -> new_name.rb")
      end

      it "formats untracked files" do
        status_output = <<~OUTPUT
          ?? untracked.rb
          ?? temp/
        OUTPUT
        
        result = formatter.format(status_output)
        
        expect(result).to include("\e[91m")  # Bright red for untracked
        expect(result).to include("untracked.rb")
      end
    end

    context "with complex status combinations" do
      it "handles mixed file states" do
        status_output = <<~OUTPUT
           M modified.rb
          A  added.rb
           D deleted.rb
          ?? untracked.rb
          R  old.rb -> new.rb
        OUTPUT
        
        result = formatter.format(status_output)
        
        expect(result).to include("\e[33m")  # Yellow for modified
        expect(result).to include("\e[32m")  # Green for added
        expect(result).to include("\e[31m")  # Red for deleted
        expect(result).to include("\e[91m")  # Bright red for untracked
        expect(result).to include("\e[36m")  # Cyan for renamed
      end

      it "handles staged and unstaged changes" do
        status_output = <<~OUTPUT
          MM file_both_staged_modified.rb
          AM file_added_then_modified.rb
        OUTPUT
        
        result = formatter.format(status_output)
        
        expect(result).to include("file_both_staged_modified.rb")
        expect(result).to include("file_added_then_modified.rb")
      end
    end

    context "with special filenames" do
      it "handles files with spaces" do
        status_output = ' M "file with spaces.rb"'
        
        result = formatter.format(status_output)
        
        expect(result).to include("file with spaces.rb")
        expect(result).not_to include('""')
      end

      it "handles files with special characters" do
        status_output = ' M "file_with_émojis_🎉.rb"'
        
        result = formatter.format(status_output)
        
        expect(result).to include("file_with_émojis_🎉.rb")
      end
    end

    context "with empty or invalid input" do
      it "handles empty status output" do
        result = formatter.format("")
        expect(result).to eq("")
      end

      it "handles nil input" do
        result = formatter.format(nil)
        expect(result).to eq("")
      end

      it "handles clean repository status" do
        status_output = "On branch main\nnothing to commit, working tree clean\n"
        
        result = formatter.format(status_output)
        
        expect(result).to include("nothing to commit")
      end
    end

    context "with performance considerations" do
      it "handles large status outputs efficiently" do
        # Generate large status output
        large_output = (1..1000).map { |i| " M file#{i}.rb" }.join("\n")
        
        start_time = Time.now
        result = formatter.format(large_output)
        end_time = Time.now
        
        expect(result).to include("file1.rb")
        expect(result).to include("file1000.rb")
        expect(end_time - start_time).to be < 1.0  # Should complete in under 1 second
      end
    end
  end

  describe "#color_for_status" do
    it "returns correct colors for each status" do
      expect(formatter.send(:color_for_status, "M")).to eq("\e[33m")  # Yellow
      expect(formatter.send(:color_for_status, "A")).to eq("\e[32m")  # Green
      expect(formatter.send(:color_for_status, "D")).to eq("\e[31m")  # Red
      expect(formatter.send(:color_for_status, "R")).to eq("\e[36m")  # Cyan
      expect(formatter.send(:color_for_status, "??")).to eq("\e[91m") # Bright red
    end

    it "returns default color for unknown status" do
      expect(formatter.send(:color_for_status, "X")).to eq("\e[0m")  # Reset
    end
  end

  describe "#strip_quotes" do
    it "removes surrounding quotes from filenames" do
      expect(formatter.send(:strip_quotes, '"filename.rb"')).to eq("filename.rb")
      expect(formatter.send(:strip_quotes, "filename.rb")).to eq("filename.rb")
    end
  end
end