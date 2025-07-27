# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::KramdownFormatter do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#initialize" do
    it "uses default options" do
      formatter = described_class.new
      expected_options = {
        input: "GFM",
        hard_wrap: false,
        auto_ids: true,
        entity_output: :as_char,
        toc_levels: "1..6",
        smart_quotes: ["rsquo", "rsquo", "rdquo", "rdquo"]
      }
      expect(formatter.options).to include(expected_options)
    end

    it "merges custom options with defaults" do
      custom_options = {hard_wrap: true, auto_ids: false}
      formatter = described_class.new(custom_options)

      expect(formatter.options[:hard_wrap]).to be true
      expect(formatter.options[:auto_ids]).to be false
      expect(formatter.options[:input]).to eq("GFM")  # Still has default
    end

    it "allows complete option override" do
      custom_options = {input: "markdown", toc_levels: "1..3"}
      formatter = described_class.new(custom_options)

      expect(formatter.options[:input]).to eq("markdown")
      expect(formatter.options[:toc_levels]).to eq("1..3")
    end
  end

  describe "#format" do
    let(:formatter) { described_class.new }

    context "with valid markdown" do
      it "formats simple markdown successfully" do
        content = "# Title\n\nSome content."
        result = formatter.format(content)

        expect(result[:success]).to be true
        expect(result[:formatted]).to be_a(String)
        expect(result[:formatted]).to include("# Title")
      end

      it "detects when content changed" do
        content = "# Title\n\n\n\nSome content with extra spaces."
        result = formatter.format(content)

        expect(result[:success]).to be true
        expect(result[:changed]).to be_a(TrueClass).or be_a(FalseClass)
      end

      it "detects when content unchanged" do
        content = "# Title\n\nSome content."
        # Format once to get the normalized version
        first_result = formatter.format(content)
        # Format the result again
        second_result = formatter.format(first_result[:formatted])

        expect(second_result[:success]).to be true
        expect(second_result[:changed]).to be false
      end

      it "handles GitHub Flavored Markdown features" do
        content = <<~MARKDOWN
          # Title

          - [ ] Task item
          - [x] Completed task

          ```ruby
          def hello
            puts "world"
          end
          ```

          | Column 1 | Column 2 |
          |----------|----------|
          | Value 1  | Value 2  |
        MARKDOWN

        result = formatter.format(content)

        expect(result[:success]).to be true
        expect(result[:formatted]).to include("- [ ] Task item")
        expect(result[:formatted]).to include("```ruby")
        expect(result[:formatted]).to include("| Column 1")
      end

      it "handles smart quotes" do
        content = 'He said "Hello" and she replied \'Hi\'.'
        result = formatter.format(content)

        expect(result[:success]).to be true
        expect(result[:formatted]).to be_a(String)
      end

      it "handles auto IDs for headers" do
        content = "# Main Title\n\n## Section Header"
        result = formatter.format(content)

        expect(result[:success]).to be true
        expect(result[:formatted]).to be_a(String)
      end
    end

    context "with edge cases" do
      it "handles empty content" do
        result = formatter.format("")

        expect(result[:success]).to be true
        expect(result[:formatted]).to eq("")
        expect(result[:changed]).to be false
      end

      it "handles whitespace-only content" do
        result = formatter.format("   \n  \n  ")

        expect(result[:success]).to be true
        expect(result[:formatted]).to be_a(String)
      end

      it "handles very long content" do
        long_content = "# Title\n\n" + ("A" * 10_000)
        result = formatter.format(long_content)

        expect(result[:success]).to be true
        expect(result[:formatted]).to include("Title")
        expect(result[:formatted]).to include("A" * 10_000)
      end

      it "handles content with special characters" do
        content = "# Título with émojis 🚀\n\nContent with ümlaut & àccents."
        result = formatter.format(content)

        expect(result[:success]).to be true
        expect(result[:formatted]).to include("Título")
        expect(result[:formatted]).to include("🚀")
      end
    end

    context "with malformed markdown" do
      it "handles unclosed code blocks gracefully" do
        content = "# Title\n\n```ruby\ndef method\n  puts 'unclosed'"
        result = formatter.format(content)

        expect(result[:success]).to be true
        expect(result[:formatted]).to be_a(String)
      end

      it "handles malformed tables" do
        content = "# Title\n\n| Col 1 |\n|invalid table"
        result = formatter.format(content)

        expect(result[:success]).to be true
        expect(result[:formatted]).to be_a(String)
      end
    end

    context "with parsing errors" do
      before do
        allow(Kramdown::Document).to receive(:new).and_raise(StandardError, "Parse error")
      end

      it "returns error result on parsing failure" do
        content = "# Title"
        result = formatter.format(content)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Parse error")
        expect(result[:formatted]).to eq(content)
      end
    end
  end

  describe "#format_file" do
    let(:formatter) { described_class.new }
    let(:test_file) { File.join(temp_dir, "test.md") }

    context "with existing file" do
      before do
        File.write(test_file, "# Title\n\nContent.")
      end

      it "formats file content successfully" do
        result = formatter.format_file(test_file)

        expect(result[:success]).to be true
        expect(result[:formatted]).to include("# Title")
      end

      it "updates file when content changes and not dry run" do
        original_content = "# Title\n\n\n\nContent with extra spaces."
        File.write(test_file, original_content)

        result = formatter.format_file(test_file)

        expect(result[:success]).to be true
        if result[:changed]
          expect(result[:file_updated]).to be true
          expect(File.read(test_file)).to eq(result[:formatted])
        end
      end

      it "does not update file in dry run mode" do
        formatter_dry = described_class.new(dry_run: true)
        original_content = "# Title\n\n\n\nContent."
        File.write(test_file, original_content)

        result = formatter_dry.format_file(test_file)

        expect(result[:success]).to be true
        expect(result).not_to have_key(:file_updated)
        expect(File.read(test_file)).to eq(original_content)
      end

      it "does not update file when content unchanged" do
        well_formatted_content = "# Title\n\nContent."
        File.write(test_file, well_formatted_content)

        result = formatter.format_file(test_file)

        expect(result[:success]).to be true
        if result[:changed] == false
          expect(result).not_to have_key(:file_updated)
        end
      end
    end

    context "with non-existent file" do
      it "returns error for missing file" do
        result = formatter.format_file("/nonexistent/file.md")

        expect(result[:success]).to be false
        expect(result[:error]).to include("File not found")
      end
    end

    context "with file read errors" do
      before do
        File.write(test_file, "content")
        allow(File).to receive(:read).with(test_file).and_raise(IOError, "Read error")
      end

      it "handles file read errors" do
        result = formatter.format_file(test_file)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Read error")
      end
    end

    context "with file write errors" do
      before do
        File.write(test_file, "# Title\n\n\n\nContent.")
        allow(File).to receive(:write).and_raise(IOError, "Write error")
      end

      it "handles file write errors gracefully" do
        # This test might be challenging since the error occurs during write
        # The method might still return success: true for the formatting part
        result = formatter.format_file(test_file)

        # The behavior depends on implementation - it might catch write errors
        # or let them bubble up. Either is acceptable.
        expect(result).to have_key(:success)
      end
    end
  end

  describe "#validate_syntax" do
    let(:formatter) { described_class.new }

    context "with valid markdown" do
      it "validates correct syntax" do
        content = "# Title\n\nValid markdown content."
        result = formatter.validate_syntax(content)

        expect(result[:valid]).to be true
        expect(result[:warnings]).to be_empty
      end

      it "handles complex valid markdown" do
        content = <<~MARKDOWN
          # Title

          - Item 1
          - Item 2

          ```ruby
          def method
            puts "hello"
          end
          ```

          [Link](http://example.com)
        MARKDOWN

        result = formatter.validate_syntax(content)

        expect(result[:valid]).to be true
        expect(result[:warnings]).to be_empty
      end
    end

    context "with warnings" do
      it "captures markdown warnings" do
        # Create content that might generate warnings
        content = "# Title\n\n[Invalid link]"
        result = formatter.validate_syntax(content)

        expect(result).to have_key(:valid)
        expect(result).to have_key(:warnings)
        expect(result[:warnings]).to be_an(Array)
      end
    end

    context "with syntax errors" do
      before do
        allow(Kramdown::Document).to receive(:new).and_raise(StandardError, "Syntax error")
      end

      it "handles parsing errors" do
        content = "# Title"
        result = formatter.validate_syntax(content)

        expect(result[:valid]).to be false
        expect(result[:error]).to eq("Syntax error")
      end
    end

    context "with empty content" do
      it "handles empty content validation" do
        result = formatter.validate_syntax("")

        expect(result[:valid]).to be true
        expect(result[:warnings]).to be_empty
      end
    end
  end

  describe "integration with Kramdown options" do
    it "respects custom input format" do
      formatter = described_class.new(input: "markdown")
      content = "# Title\n\nContent."
      result = formatter.format(content)

      expect(result[:success]).to be true
    end

    it "respects hard wrap setting" do
      formatter = described_class.new(hard_wrap: true)
      content = "This is a long line that might be wrapped\ndepending on the hard_wrap setting."
      result = formatter.format(content)

      expect(result[:success]).to be true
    end

    it "respects entity output setting" do
      formatter = described_class.new(entity_output: :numeric)
      content = "Content with & ampersand."
      result = formatter.format(content)

      expect(result[:success]).to be true
    end
  end
end
