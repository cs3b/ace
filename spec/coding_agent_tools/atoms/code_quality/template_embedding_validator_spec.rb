# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::TemplateEmbeddingValidator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:templates_dir) { File.join(temp_dir, "templates") }
  
  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
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

  private

  def create_markdown_file(filename, content)
    File.write(File.join(temp_dir, filename), content)
  end
end