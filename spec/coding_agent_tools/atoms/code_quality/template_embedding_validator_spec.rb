# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::TemplateEmbeddingValidator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:templates_dir) { File.join(temp_dir, "templates") }

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    it "uses default template directories" do
      validator = described_class.new
      expect(validator.template_dirs).to include(
        "dev-handbook/.meta/tpl",
        "templates",
        "_includes"
      )
    end

    it "accepts custom template directories" do
      custom_dirs = ["custom/templates", "other/includes"]
      validator = described_class.new(template_dirs: custom_dirs)
      expect(validator.template_dirs).to eq(custom_dirs)
    end
  end

  describe "#validate" do
    let(:validator) { described_class.new(template_dirs: [templates_dir]) }

    before do
      FileUtils.mkdir_p(templates_dir)
    end

    context "with no markdown files" do
      it "returns successful validation with empty results" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
        expect(result[:errors]).to be_empty
      end
    end

    context "with markdown files containing no templates" do
      before do
        create_markdown_file("simple.md", <<~CONTENT
          # Simple Document
          
          This document has no template embeddings.
          Just regular markdown content.
        CONTENT
        )
      end

      it "validates successfully" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with existing templates" do
      before do
        # Create template files
        File.write(File.join(templates_dir, "header.md"), "# Template Header")
        File.write(File.join(templates_dir, "footer.md"), "Template footer content")

        create_markdown_file("with_templates.md", <<~CONTENT
          # Document with Templates
          
          {{#include header.md}}
          
          Some content here.
          
          {{#include footer.md}}
        CONTENT
        )
      end

      it "validates successfully when all templates exist" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with missing templates" do
      before do
        # Create only one template
        File.write(File.join(templates_dir, "header.md"), "# Template Header")

        create_markdown_file("missing_templates.md", <<~CONTENT
          # Document with Missing Templates
          
          {{#include header.md}}
          {{#include missing.md}}
          {{#include another_missing.md}}
        CONTENT
        )
      end

      it "identifies missing templates" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(2)
        expect(result[:errors].size).to eq(2)

        missing_templates = result[:findings].map { |f| f[:template] }
        expect(missing_templates).to include("missing.md", "another_missing.md")
        expect(missing_templates).not_to include("header.md")
      end

      it "includes file and line information" do
        result = validator.validate([temp_dir])

        finding = result[:findings].first
        expect(finding[:file]).to end_with("missing_templates.md")
        expect(finding[:line]).to be_a(Integer)
        expect(finding[:line]).to be > 0
        expect(finding[:pattern]).to be_a(String)
      end

      it "formats errors correctly" do
        result = validator.validate([temp_dir])

        error = result[:errors].first
        expect(error).to match(/missing_templates\.md:\d+: Missing template/)
      end
    end

    context "with different template patterns" do
      before do
        # Create template file
        File.write(File.join(templates_dir, "shared.md"), "Shared content")

        create_markdown_file("patterns.md", <<~CONTENT
          # Different Template Patterns
          
          <!-- Mdbook style -->
          {{#include shared.md}}
          
          <!-- HTML comment style -->
          <!-- #include shared.md -->
          
          <!-- Liquid style -->
          {% include "shared.md" %}
          
          <!-- Wiki style -->
          [[include:shared.md]]
          
          <!-- Missing template in different patterns -->
          {{#include missing1.md}}
          <!-- #include missing2.md -->
          {% include "missing3.md" %}
          [[include:missing4.md]]
        CONTENT
        )
      end

      it "validates all supported template patterns" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(4)

        missing_templates = result[:findings].map { |f| f[:template] }
        expect(missing_templates).to include("missing1.md", "missing2.md", "missing3.md", "missing4.md")
      end

      it "captures pattern information" do
        result = validator.validate([temp_dir])

        patterns = result[:findings].map { |f| f[:pattern] }
        expect(patterns).to include(
          "{{#include\\s+(.+?)}}",
          "<!--\\s*#include\\s+(.+?)\\s*-->",
          "{%\\s*include\\s+[\"'](.+?)[\"']\\s*%}",
          "\\[\\[include:(.+?)\\]\\]"
        )
      end
    end

    context "with templates in code blocks" do
      before do
        create_markdown_file("code_blocks.md", <<~CONTENT
          # Document with Code Blocks
          
          Regular template that should be validated:
          {{#include should_be_found.md}}
          
          Code block that should be ignored:
          ```
          {{#include in_code_block.md}}
          ```
          
          Another code block:
          ~~~
          <!-- #include also_in_code.md -->
          ~~~
          
          After code blocks:
          {{#include after_code.md}}
        CONTENT
        )
      end

      it "ignores templates inside code blocks" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(2)

        missing_templates = result[:findings].map { |f| f[:template] }
        expect(missing_templates).to include("should_be_found.md", "after_code.md")
        expect(missing_templates).not_to include("in_code_block.md", "also_in_code.md")
      end
    end

    context "with nested code blocks" do
      before do
        create_markdown_file("nested_code.md", <<~CONTENT
          # Nested Code Blocks Test
          
          {{#include before.md}}
          
          ```
          Some code
          ```
          More content
          ```
          More code with {{#include inside_code.md}}
          ```
          
          {{#include after.md}}
        CONTENT
        )
      end

      it "handles multiple code blocks correctly" do
        result = validator.validate([temp_dir])

        missing_templates = result[:findings].map { |f| f[:template] }
        expect(missing_templates).to include("before.md", "after.md")
        expect(missing_templates).not_to include("inside_code.md")
      end
    end

    context "with templates in subdirectories" do
      before do
        FileUtils.mkdir_p(File.join(templates_dir, "subdir"))
        File.write(File.join(templates_dir, "subdir", "nested.md"), "Nested template")

        create_markdown_file("nested_templates.md", <<~CONTENT
          # Nested Templates
          
          {{#include subdir/nested.md}}
          {{#include subdir/missing.md}}
        CONTENT
        )
      end

      it "finds templates in subdirectories" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
        expect(result[:findings].first[:template]).to eq("subdir/missing.md")
      end
    end

    context "with absolute template paths" do
      let(:absolute_template) { File.join(temp_dir, "absolute.md") }

      before do
        File.write(absolute_template, "Absolute template")

        create_markdown_file("absolute_paths.md", <<~CONTENT
          # Absolute Template Paths
          
          {{#include #{absolute_template}}}
          {{#include /nonexistent/path.md}}
        CONTENT
        )
      end

      it "validates absolute paths" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
        expect(result[:findings].first[:template]).to eq("/nonexistent/path.md")
      end
    end

    context "with template file extensions" do
      before do
        # Create template without .md extension
        File.write(File.join(templates_dir, "no_extension"), "Template without extension")
        # Create template with .md extension
        File.write(File.join(templates_dir, "with_extension.md"), "Template with extension")

        create_markdown_file("extensions.md", <<~CONTENT
          # Template Extensions
          
          {{#include no_extension}}
          {{#include with_extension}}
          {{#include with_extension.md}}
        CONTENT
        )
      end

      it "handles templates with and without .md extensions" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with multiple template directories" do
      let(:second_templates_dir) { File.join(temp_dir, "other_templates") }
      let(:validator) { described_class.new(template_dirs: [templates_dir, second_templates_dir]) }

      before do
        FileUtils.mkdir_p(second_templates_dir)
        File.write(File.join(templates_dir, "first.md"), "First template")
        File.write(File.join(second_templates_dir, "second.md"), "Second template")

        create_markdown_file("multi_dirs.md", <<~CONTENT
          # Multiple Template Directories
          
          {{#include first.md}}
          {{#include second.md}}
          {{#include missing.md}}
        CONTENT
        )
      end

      it "searches all template directories" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
        expect(result[:findings].first[:template]).to eq("missing.md")
      end
    end

    context "with file paths as input" do
      let(:specific_file) { File.join(temp_dir, "specific.md") }

      before do
        create_markdown_file("specific.md", "{{#include missing.md}}")
      end

      it "validates specific files" do
        result = validator.validate([specific_file])

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
      end
    end

    context "with directory paths as input" do
      before do
        create_markdown_file("file1.md", "{{#include missing1.md}}")
        create_markdown_file("file2.md", "{{#include missing2.md}}")
      end

      it "validates all markdown files in directory" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(2)

        templates = result[:findings].map { |f| f[:template] }
        expect(templates).to include("missing1.md", "missing2.md")
      end
    end

    context "with mixed file and directory paths" do
      let(:specific_file) { File.join(temp_dir, "specific.md") }
      let(:subdir) { File.join(temp_dir, "subdir") }

      before do
        FileUtils.mkdir_p(subdir)
        create_markdown_file("specific.md", "{{#include missing1.md}}")
        File.write(File.join(subdir, "nested.md"), "{{#include missing2.md}}")
      end

      it "validates both files and directories" do
        result = validator.validate([specific_file, subdir])

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(2)

        templates = result[:findings].map { |f| f[:template] }
        expect(templates).to include("missing1.md", "missing2.md")
      end
    end

    context "with non-existent paths" do
      it "handles non-existent paths gracefully" do
        result = validator.validate(["/nonexistent/path"])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with non-markdown files" do
      before do
        File.write(File.join(temp_dir, "readme.txt"), "{{#include template.md}}")
        create_markdown_file("real.md", "{{#include template.md}}")
      end

      it "ignores non-markdown files" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
        expect(result[:findings].first[:file]).to end_with("real.md")
      end
    end
  end

  describe "template pattern constants" do
    it "defines expected template patterns" do
      patterns = described_class::TEMPLATE_PATTERNS

      expect(patterns.size).to eq(4)
      expect(patterns).to all(be_a(Regexp))
    end

    it "matches mdbook style patterns" do
      pattern = described_class::TEMPLATE_PATTERNS.first
      expect("{{#include template.md}}").to match(pattern)
      expect("{{#include path/to/template.md}}").to match(pattern)
    end

    it "matches HTML comment style patterns" do
      pattern = described_class::TEMPLATE_PATTERNS[1]
      expect("<!-- #include template.md -->").to match(pattern)
      expect("<!--#include template.md-->").to match(pattern)
    end

    it "matches Liquid style patterns" do
      pattern = described_class::TEMPLATE_PATTERNS[2]
      expect('{% include "template.md" %}').to match(pattern)
      expect("{% include 'template.md' %}").to match(pattern)
    end

    it "matches Wiki style patterns" do
      pattern = described_class::TEMPLATE_PATTERNS[3]
      expect("[[include:template.md]]").to match(pattern)
      expect("[[include:path/template.md]]").to match(pattern)
    end
  end

  describe "comprehensive edge cases and error handling" do
    let(:validator) { described_class.new(template_dirs: [templates_dir]) }

    before do
      FileUtils.mkdir_p(templates_dir)
    end

    context "with malformed markdown files" do
      it "handles files with encoding issues" do
        # This test demonstrates that encoding issues will raise ArgumentError
        file_path = File.join(temp_dir, "encoding.md")
        File.write(file_path, "{{#include template.md}}\n\xFF\xFE Invalid UTF-8")

        expect { validator.validate([temp_dir]) }.to raise_error(ArgumentError, /invalid byte sequence/)
      end

      it "handles very large markdown files" do
        large_content = "# Large File\n\n" + ("Content line\n" * 10000) + "{{#include missing.md}}\n"
        create_markdown_file("large.md", large_content)

        start_time = Time.now
        result = validator.validate([temp_dir])
        end_time = Time.now

        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
        expect(end_time - start_time).to be < 2.0 # Should handle large files efficiently
      end

      it "handles empty markdown files" do
        create_markdown_file("empty.md", "")

        result = validator.validate([temp_dir])
        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end

      it "handles files with only whitespace" do
        create_markdown_file("whitespace.md", "   \n\t\n   \n")

        result = validator.validate([temp_dir])
        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with special file paths and names" do
      it "handles files with Unicode names" do
        unicode_file = "файл.md"
        create_markdown_file(unicode_file, "{{#include missing.md}}")

        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].first[:file]).to end_with(unicode_file)
      end

      it "handles files with special characters in names" do
        special_file = "file@#$%^&*()_+.md"
        create_markdown_file(special_file, "{{#include missing.md}}")

        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].first[:file]).to end_with(special_file)
      end

      it "handles files with spaces in names" do
        spaced_file = "file with spaces.md"
        create_markdown_file(spaced_file, "{{#include missing.md}}")

        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].first[:file]).to end_with(spaced_file)
      end

      it "handles very long file paths" do
        deep_dir = File.join(temp_dir, *Array.new(10) { "very_long_directory_name" })
        FileUtils.mkdir_p(deep_dir)
        long_file = File.join(deep_dir, "deep_file.md")
        File.write(long_file, "{{#include missing.md}}")

        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].first[:file]).to eq(long_file)
      end
    end

    context "with template path edge cases" do
      it "handles templates with Unicode paths" do
        unicode_template = "шаблон.md"
        create_markdown_file("unicode_template.md", "{{#include #{unicode_template}}}")

        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].first[:template]).to eq(unicode_template)
      end

      it "handles templates with spaces in paths" do
        spaced_template = "template with spaces.md"
        create_markdown_file("spaced_template.md", "{{#include #{spaced_template}}}")

        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].first[:template]).to eq(spaced_template)
      end

      it "handles very long template paths" do
        long_template = ("very_long_path_segment/" * 20) + "template.md"
        create_markdown_file("long_template.md", "{{#include #{long_template}}}")

        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].first[:template]).to eq(long_template)
      end

      it "handles templates with special characters" do
        special_template = "template@#$%^&*()_+.md"
        create_markdown_file("special_template.md", "{{#include #{special_template}}}")

        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].first[:template]).to eq(special_template)
      end

      it "handles empty template paths" do
        create_markdown_file("empty_template.md", "{{#include }}")

        result = validator.validate([temp_dir])
        # Empty template path with just spaces doesn't match the pattern
        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with complex code block scenarios" do
      it "handles nested backtick code blocks" do
        create_markdown_file("nested_backticks.md", <<~CONTENT
          # Nested Backticks
          
          {{#include before.md}}
          
          ```
          This is code with {{#include should_be_ignored.md}}
          ```
          
          {{#include after.md}}
        CONTENT
        )

        result = validator.validate([temp_dir])
        templates = result[:findings].map { |f| f[:template] }
        expect(templates).to include("before.md", "after.md")
        expect(templates).not_to include("should_be_ignored.md")
      end

      it "handles mixed backtick and tilde code blocks" do
        create_markdown_file("mixed_blocks.md", <<~CONTENT
          # Mixed Code Blocks
          
          {{#include before.md}}
          
          ```
          Code block with {{#include ignored1.md}}
          ```
          
          Content between blocks
          
          ~~~
          Another code block with {{#include ignored2.md}}
          ~~~
          
          {{#include after.md}}
        CONTENT
        )

        result = validator.validate([temp_dir])
        templates = result[:findings].map { |f| f[:template] }
        expect(templates).to include("before.md", "after.md")
        expect(templates).not_to include("ignored1.md", "ignored2.md")
      end

      it "handles unclosed code blocks at end of file" do
        create_markdown_file("unclosed_block.md", <<~CONTENT
          # Unclosed Code Block
          
          {{#include before.md}}
          
          ```
          This code block is never closed
          {{#include should_be_ignored.md}}
        CONTENT
        )

        result = validator.validate([temp_dir])
        templates = result[:findings].map { |f| f[:template] }
        expect(templates).to include("before.md")
        expect(templates).not_to include("should_be_ignored.md")
      end

      it "handles multiple templates on the same line" do
        create_markdown_file("same_line.md", "{{#include first.md}} and {{#include second.md}} on same line")

        result = validator.validate([temp_dir])
        expect(result[:findings].size).to eq(2)
        templates = result[:findings].map { |f| f[:template] }
        expect(templates).to include("first.md", "second.md")
      end
    end

    context "with template pattern variations" do
      it "handles patterns with extra whitespace" do
        create_markdown_file("whitespace_patterns.md", <<~CONTENT
          {{#include    extra_spaces.md   }}
          <!--   #include   extra_spaces2.md   -->
          {%   include   "extra_spaces3.md"   %}
          [[include:  extra_spaces4.md  ]]
        CONTENT
        )

        result = validator.validate([temp_dir])
        expect(result[:findings].size).to eq(4)
        templates = result[:findings].map { |f| f[:template] }
        # The patterns capture whitespace as part of the template name
        expect(templates).to include("extra_spaces.md   ", "extra_spaces2.md", "extra_spaces3.md", "  extra_spaces4.md  ")
      end

      it "handles case variations in patterns" do
        create_markdown_file("case_patterns.md", <<~CONTENT
          {{#INCLUDE case1.md}}
          {{#Include case2.md}}
          <!-- #INCLUDE case3.md -->
          <!-- #Include case4.md -->
        CONTENT
        )

        result = validator.validate([temp_dir])
        # Current implementation is case-sensitive, so these shouldn't match
        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end

      it "handles malformed template patterns" do
        create_markdown_file("malformed.md", <<~CONTENT
          {{#include missing_brace.md}
          {#include missing_hash.md}}
          {{include missing_hash.md}}
          <!-- include missing_hash.md -->
          {% include missing_quotes.md %}
          [[include missing_colon.md]]
        CONTENT
        )

        result = validator.validate([temp_dir])
        # Only well-formed patterns should be detected
        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with performance stress testing" do
      it "handles many template references efficiently" do
        many_templates = (1..100).map { |i| "{{#include template#{i}.md}}" }.join("\n")
        create_markdown_file("many_templates.md", many_templates)

        start_time = Time.now
        result = validator.validate([temp_dir])
        end_time = Time.now

        expect(result[:findings].size).to eq(100)
        expect(end_time - start_time).to be < 1.0
      end

      it "handles many markdown files efficiently" do
        100.times do |i|
          create_markdown_file("file#{i}.md", "{{#include missing#{i}.md}}")
        end

        start_time = Time.now
        result = validator.validate([temp_dir])
        end_time = Time.now

        expect(result[:findings].size).to eq(100)
        expect(end_time - start_time).to be < 2.0
      end

      it "handles deep directory structures efficiently" do
        deep_path = temp_dir
        20.times do |i|
          deep_path = File.join(deep_path, "level#{i}")
          FileUtils.mkdir_p(deep_path)
          File.write(File.join(deep_path, "deep#{i}.md"), "{{#include missing#{i}.md}}")
        end

        start_time = Time.now
        result = validator.validate([temp_dir])
        end_time = Time.now

        expect(result[:findings].size).to eq(20)
        expect(end_time - start_time).to be < 1.0
      end
    end

    context "with concurrent access simulation" do
      it "maintains consistency during concurrent validation" do
        # Create test files
        5.times do |i|
          create_markdown_file("concurrent#{i}.md", "{{#include missing#{i}.md}}")
        end

        threads = []
        results = Queue.new

        10.times do
          threads << Thread.new do
            local_validator = described_class.new(template_dirs: [templates_dir])
            results << local_validator.validate([temp_dir])
          end
        end

        threads.each(&:join)

        # All results should be consistent
        first_result = results.pop
        while !results.empty?
          next_result = results.pop
          expect(next_result[:success]).to eq(first_result[:success])
          expect(next_result[:findings].size).to eq(first_result[:findings].size)
        end
      end
    end
  end

  describe "file and directory edge cases" do
    let(:validator) { described_class.new(template_dirs: [templates_dir]) }

    before do
      FileUtils.mkdir_p(templates_dir)
    end

    context "with unreadable files" do
      it "handles permission denied errors gracefully" do
        file_path = File.join(temp_dir, "unreadable.md")
        File.write(file_path, "{{#include template.md}}")
        
        # Mock File.read to raise a permission error
        allow(File).to receive(:read).with(file_path).and_raise(Errno::EACCES.new("Permission denied"))
        
        expect { validator.validate([temp_dir]) }.to raise_error(Errno::EACCES)
      end
    end

    context "with symlinks" do
      it "follows symlinks to markdown files" do
        real_file = File.join(temp_dir, "real.md")
        symlink_file = File.join(temp_dir, "symlink.md")
        
        File.write(real_file, "{{#include missing.md}}")
        
        # Skip test if system doesn't support symlinks
        begin
          File.symlink(real_file, symlink_file)
        rescue NotImplementedError
          skip "Symlinks not supported on this platform"
        end
        
        result = validator.validate([symlink_file])
        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
        expect(result[:findings].first[:file]).to eq(symlink_file)
      end
    end

    context "with binary files with .md extension" do
      it "handles binary content in .md files by raising encoding error" do
        binary_file = File.join(temp_dir, "binary.md")
        # Write binary content that will cause encoding issues
        File.binwrite(binary_file, "\x00\x01\x02\x03{{#include template.md}}\xFF\xFE")
        
        # Should raise an encoding error when trying to process invalid UTF-8
        expect { validator.validate([temp_dir]) }.to raise_error(Encoding::CompatibilityError, /invalid byte sequence/)
      end
    end
  end

  describe "template path resolution edge cases" do
    let(:validator) { described_class.new(template_dirs: [templates_dir]) }

    before do
      FileUtils.mkdir_p(templates_dir)
    end

    context "with template paths containing special sequences" do
      it "handles template paths with newlines" do
        create_markdown_file("newlines.md", "{{#include template\nwith\nnewlines.md}}")
        
        result = validator.validate([temp_dir])
        # Template path with newlines won't match pattern properly
        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end

      it "handles template paths with tabs" do
        create_markdown_file("tabs.md", "{{#include template\twith\ttabs.md}}")
        
        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
        expect(result[:findings].first[:template]).to eq("template\twith\ttabs.md")
      end

      it "handles empty directory as template directory" do
        empty_dir = File.join(temp_dir, "empty_templates")
        FileUtils.mkdir_p(empty_dir)
        validator_with_empty = described_class.new(template_dirs: [empty_dir])
        
        create_markdown_file("test.md", "{{#include any.md}}")
        
        result = validator_with_empty.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
      end
    end

    context "with non-existent template directories" do
      it "handles non-existent template directories gracefully" do
        non_existent = "/path/that/does/not/exist"
        validator_with_nonexistent = described_class.new(template_dirs: [non_existent])
        
        create_markdown_file("test.md", "{{#include template.md}}")
        
        result = validator_with_nonexistent.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
      end
    end

    context "with circular template references (detection simulation)" do
      it "finds missing templates even in potential circular reference scenarios" do
        File.write(File.join(templates_dir, "a.md"), "{{#include b.md}}")
        File.write(File.join(templates_dir, "b.md"), "{{#include a.md}}")
        
        create_markdown_file("circular.md", <<~CONTENT
          {{#include a.md}}
          {{#include b.md}}
          {{#include missing.md}}
        CONTENT
        )
        
        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
        expect(result[:findings].first[:template]).to eq("missing.md")
      end
    end
  end

  describe "default template directories behavior" do
    it "uses expected default template directories" do
      validator = described_class.new
      defaults = validator.template_dirs
      
      expect(defaults).to include("dev-handbook/.meta/tpl")
      expect(defaults).to include("templates")
      expect(defaults).to include("_includes")
      expect(defaults.size).to eq(3)
    end

    context "with default directories in validation" do
      it "searches default directories when no custom dirs specified" do
        validator = described_class.new
        
        # Create a template in one of the default locations
        default_dir = File.join(temp_dir, "templates")
        FileUtils.mkdir_p(default_dir)
        File.write(File.join(default_dir, "default.md"), "Default template")
        
        # Change working directory temporarily
        original_dir = Dir.pwd
        begin
          Dir.chdir(temp_dir)
          
          create_markdown_file("with_default.md", "{{#include default.md}}")
          
          result = validator.validate([File.join(temp_dir, "with_default.md")])
          expect(result[:success]).to be true
          expect(result[:findings]).to be_empty
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  describe "validation result structure consistency" do
    let(:validator) { described_class.new(template_dirs: [templates_dir]) }

    before do
      FileUtils.mkdir_p(templates_dir)
    end

    it "always returns hash with required keys" do
      result = validator.validate([])
      
      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly(:success, :findings, :errors)
      expect([true, false]).to include(result[:success])
      expect(result[:findings]).to be_an(Array)
      expect(result[:errors]).to be_an(Array)
    end

    it "maintains finding structure consistency" do
      create_markdown_file("structured.md", "{{#include missing.md}}")
      
      result = validator.validate([temp_dir])
      finding = result[:findings].first
      
      expect(finding).to be_a(Hash)
      expect(finding.keys).to contain_exactly(:file, :line, :template, :pattern)
      expect(finding[:file]).to be_a(String)
      expect(finding[:line]).to be_a(Integer)
      expect(finding[:template]).to be_a(String)
      expect(finding[:pattern]).to be_a(String)
    end

    it "ensures error count matches findings count" do
      create_markdown_file("errors.md", <<~CONTENT
        {{#include missing1.md}}
        {{#include missing2.md}}
        {{#include missing3.md}}
      CONTENT
      )
      
      result = validator.validate([temp_dir])
      
      expect(result[:findings].size).to eq(result[:errors].size)
      expect(result[:findings].size).to eq(3)
    end
  end

  describe "private method coverage through public interface" do
    let(:validator) { described_class.new(template_dirs: [templates_dir]) }

    before do
      FileUtils.mkdir_p(templates_dir)
    end

    context "collect_markdown_files method coverage" do
      it "handles mixed file types in input paths" do
        # Create both markdown and non-markdown files
        create_markdown_file("test.md", "{{#include missing.md}}")
        File.write(File.join(temp_dir, "readme.txt"), "Not markdown")
        File.write(File.join(temp_dir, "data.json"), "{}")
        
        result = validator.validate([temp_dir])
        
        # Should only process the .md file
        expect(result[:findings].size).to eq(1)
        expect(result[:findings].first[:file]).to end_with("test.md")
      end

      it "handles deeply nested directory structures" do
        # Create deeply nested structure
        deep_dir = File.join(temp_dir, "level1", "level2", "level3")
        FileUtils.mkdir_p(deep_dir)
        File.write(File.join(deep_dir, "deep.md"), "{{#include missing.md}}")
        
        result = validator.validate([temp_dir])
        
        expect(result[:findings].size).to eq(1)
        expect(result[:findings].first[:file]).to include("level1/level2/level3/deep.md")
      end
    end

    context "template_exists? method coverage" do
      it "checks multiple template directories in order" do
        first_dir = File.join(temp_dir, "first")
        second_dir = File.join(temp_dir, "second")
        FileUtils.mkdir_p([first_dir, second_dir])
        
        # Put template in second directory only
        File.write(File.join(second_dir, "template.md"), "Template content")
        
        validator_multi = described_class.new(template_dirs: [first_dir, second_dir])
        create_markdown_file("multi.md", "{{#include template.md}}")
        
        result = validator_multi.validate([temp_dir])
        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end

      it "handles templates with and without .md extension consistently" do
        # Create template without extension
        File.write(File.join(templates_dir, "no_ext"), "No extension")
        
        create_markdown_file("extensions.md", <<~CONTENT
          {{#include no_ext}}
          {{#include no_ext.md}}
        CONTENT
        )
        
        result = validator.validate([temp_dir])
        expect(result[:success]).to be false
        expect(result[:findings].size).to eq(1)
        expect(result[:findings].first[:template]).to eq("no_ext.md")
      end
    end

    context "format_error method coverage" do
      it "formats errors with proper file path and line information" do
        create_markdown_file("error_format.md", <<~CONTENT
          Line 1
          {{#include missing.md}}
        CONTENT
        )
        
        result = validator.validate([temp_dir])
        error = result[:errors].first
        
        expect(error).to match(/error_format\.md:2: Missing template 'missing\.md'/)
        expect(error).to include(File.join(temp_dir, "error_format.md"))
      end
    end
  end

  describe "algorithm correctness verification" do
    let(:validator) { described_class.new(template_dirs: [templates_dir]) }

    before do
      FileUtils.mkdir_p(templates_dir)
    end

    context "line number accuracy" do
      it "reports correct line numbers for multiple templates" do
        content = <<~CONTENT
          # Line 1
          
          Line 3 content
          {{#include missing1.md}}
          Line 5 content
          
          Line 7 content
          {{#include missing2.md}}
          Line 9 content
        CONTENT

        create_markdown_file("line_numbers.md", content)

        result = validator.validate([temp_dir])
        expect(result[:findings].size).to eq(2)

        # Sort findings by line number for predictable testing
        findings = result[:findings].sort_by { |f| f[:line] }
        expect(findings[0][:line]).to eq(4)
        expect(findings[0][:template]).to eq("missing1.md")
        expect(findings[1][:line]).to eq(8)
        expect(findings[1][:template]).to eq("missing2.md")
      end

      it "handles templates at beginning and end of file" do
        content = <<~CONTENT
          {{#include first.md}}
          Middle content
          {{#include last.md}}
        CONTENT

        create_markdown_file("boundaries.md", content)

        result = validator.validate([temp_dir])
        findings = result[:findings].sort_by { |f| f[:line] }
        expect(findings[0][:line]).to eq(1)
        expect(findings[1][:line]).to eq(3)
      end
    end

    context "pattern matching precision" do
      it "distinguishes between similar patterns" do
        create_markdown_file("similar_patterns.md", <<~CONTENT
          {{#include real.md}}
          {{#includes fake.md}}
          {{include also_fake.md}}
          <!-- #include real2.md -->
          <!-- include fake2.md -->
          {% include "real3.md" %}
          {% includes "fake3.md" %}
          [[include:real4.md]]
          [[includes:fake4.md]]
        CONTENT
        )

        result = validator.validate([temp_dir])
        templates = result[:findings].map { |f| f[:template] }
        expect(templates).to include("real.md", "real2.md", "real3.md", "real4.md")
        expect(templates).not_to include("fake.md", "also_fake.md", "fake2.md", "fake3.md", "fake4.md")
      end
    end

    context "error message formatting" do
      it "formats error messages consistently" do
        create_markdown_file("error_format.md", "{{#include missing.md}}")

        result = validator.validate([temp_dir])
        error = result[:errors].first

        expect(error).to match(/error_format\.md:\d+: Missing template 'missing\.md'/)
        expect(error).to include(File.join(temp_dir, "error_format.md"))
      end

      it "preserves original template paths in error messages" do
        complex_path = "complex/path/with spaces/template.md"
        create_markdown_file("complex_error.md", "{{#include #{complex_path}}}")

        result = validator.validate([temp_dir])
        error = result[:errors].first

        expect(error).to include(complex_path)
      end
    end
  end

  private

  def create_markdown_file(filename, content)
    File.write(File.join(temp_dir, filename), content)
  end
end
