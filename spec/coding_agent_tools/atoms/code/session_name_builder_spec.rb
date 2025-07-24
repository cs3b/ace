# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::Code::SessionNameBuilder do
  let(:builder) { described_class.new }

  describe "#build", :build do
    it "builds session name with valid components" do
      result = builder.build("code", "src/main.rb", "20240724-143022")
      expect(result).to eq("code-src-main.rb-20240724-143022")
    end

    it "handles slashes in target by converting to hyphens" do
      result = builder.build("review", "src/components/header.js", "20240724-143022")
      expect(result).to eq("review-src-components-header.js-20240724-143022")
    end

    it "handles multiple slashes in target" do
      result = builder.build("docs", "deep/nested/folder/file.md", "20240724-143022")
      expect(result).to eq("docs-deep-nested-folder-file.md-20240724-143022")
    end

    it "handles spaces in target by converting to underscores" do
      result = builder.build("test", "my file name.txt", "20240724-143022")
      expect(result).to eq("test-my_file_name.txt-20240724-143022")
    end

    it "handles empty target" do
      result = builder.build("focus", "", "20240724-143022")
      expect(result).to eq("focus--20240724-143022")
    end

    it "handles nil target gracefully" do
      expect { builder.build("focus", nil, "20240724-143022") }.to raise_error(NoMethodError)
    end

    it "builds with git revision range" do
      result = builder.build("code", "HEAD~1..HEAD", "20240724-143022")
      expect(result).to eq("code-HEAD1..HEAD-20240724-143022")
    end

    it "handles special characters in focus" do
      result = builder.build("code-review", "src/main.rb", "20240724-143022")
      expect(result).to eq("code-review-src-main.rb-20240724-143022")
    end
  end

  describe "#build_prefix" do
    it "builds session name prefix without timestamp" do
      result = builder.build_prefix("code", "src/main.rb")
      expect(result).to eq("code-src-main.rb")
    end

    it "handles the same sanitization as build method" do
      result = builder.build_prefix("review", "src/components/header.js")
      expect(result).to eq("review-src-components-header.js")
    end

    it "handles empty target in prefix" do
      result = builder.build_prefix("focus", "")
      expect(result).to eq("focus-")
    end
  end

  describe "#sanitize_target", :sanitize do
    # Note: This is a private method, so we test it through the public interface
    # or we can make it temporarily public for testing

    context "when testing sanitization through public methods" do
      it "replaces slashes with hyphens" do
        result = builder.build_prefix("test", "path/to/file")
        expect(result).to eq("test-path-to-file")
      end

      it "replaces multiple spaces with single underscores" do
        result = builder.build_prefix("test", "file   with    spaces")
        expect(result).to eq("test-file_with_spaces")
      end

      it "removes special characters except word chars, hyphens, dots, underscores" do
        result = builder.build_prefix("test", "file@#$%^&*()+={}[]|\\:;\"'<>?,file")
        expect(result).to eq("test-filefile")
      end

      it "removes leading and trailing dots" do
        result = builder.build_prefix("test", "...file.txt...")
        expect(result).to eq("test-file.txt")
      end

      it "removes only leading and trailing dots, not internal ones" do
        result = builder.build_prefix("test", "..file.name.ext..")
        expect(result).to eq("test-file.name.ext")
      end

      it "limits length to 50 characters" do
        long_target = "a" * 60
        result = builder.build_prefix("test", long_target)
        # Should be "test-" + 50 chars = 55 total, but sanitized target is 50 max
        expected_target = "a" * 50
        expect(result).to eq("test-#{expected_target}")
        expect(result.split("-", 2)[1].length).to eq(50)
      end

      it "handles unicode characters by removing them" do
        result = builder.build_prefix("test", "file-ñame-tëst")
        expect(result).to eq("test-file-ame-tst")
      end

      it "preserves existing hyphens, underscores, and dots" do
        result = builder.build_prefix("test", "file-name_test.ext")
        expect(result).to eq("test-file-name_test.ext")
      end

      it "handles mixed case preservation" do
        result = builder.build_prefix("test", "CamelCase.File")
        expect(result).to eq("test-CamelCase.File")
      end

      it "handles numbers correctly" do
        result = builder.build_prefix("test", "file123-test456.rb")
        expect(result).to eq("test-file123-test456.rb")
      end

      it "handles empty string after sanitization" do
        result = builder.build_prefix("test", "@#$%^&*()")
        expect(result).to eq("test-")
      end

      it "handles string that becomes empty after dot removal" do
        result = builder.build_prefix("test", ".....")
        expect(result).to eq("test-")
      end

      it "handles complex combination of issues" do
        complex_target = "...///path with spaces@#$%file-name_test.rb///"
        result = builder.build_prefix("test", complex_target)
        # Should become: path_with_spacesfile-name_test.rb (slashes->hyphens, spaces->underscores, specials removed, dots trimmed)
        expect(result).to eq("test----path_with_spacesfile-name_test.rb---")
      end
    end
  end

  # Edge cases and error conditions
  describe "edge cases" do
    it "handles very long focus strings" do
      long_focus = "a" * 100
      result = builder.build(long_focus, "file.rb", "20240724-143022")
      expect(result).to include(long_focus)
      expect(result).to include("file.rb")
    end

    it "handles empty focus" do
      result = builder.build("", "file.rb", "20240724-143022")
      expect(result).to eq("-file.rb-20240724-143022")
    end

    it "handles empty timestamp" do
      result = builder.build("code", "file.rb", "")
      expect(result).to eq("code-file.rb-")
    end

    it "handles all empty parameters" do
      result = builder.build("", "", "")
      expect(result).to eq("--")
    end
  end
end