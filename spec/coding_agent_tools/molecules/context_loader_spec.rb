# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Molecules::ContextLoader do
  let(:temp_dir) { Dir.mktmpdir }
  let(:project_root) { temp_dir }
  let(:docs_dir) { File.join(temp_dir, "docs") }
  let(:mock_sandbox) { instance_double(CodingAgentTools::Molecules::ProjectSandbox) }

  before do
    # Set up basic project structure
    FileUtils.mkdir_p(docs_dir)

    # Mock sandbox to return our temp directory as project root
    allow(mock_sandbox).to receive(:project_root).and_return(project_root)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    it "accepts a custom sandbox" do
      context_loader = described_class.new(mock_sandbox)
      expect(context_loader.instance_variable_get(:@sandbox)).to eq(mock_sandbox)
    end

    it "creates a default ProjectSandbox when none provided" do
      context_loader = described_class.new
      sandbox = context_loader.instance_variable_get(:@sandbox)
      expect(sandbox).to be_a(CodingAgentTools::Molecules::ProjectSandbox)
    end
  end

  describe "#load_docs_context" do
    let(:context_loader) { described_class.new(mock_sandbox) }

    context "when docs directory does not exist" do
      before do
        FileUtils.rmdir(docs_dir)
      end

      it "returns failure result with error message" do
        result = context_loader.load_docs_context

        expect(result[:success]).to be false
        expect(result[:error]).to include("Docs directory not found")
        expect(result[:error]).to include(docs_dir)
      end
    end

    context "when docs directory exists but is empty" do
      it "returns success with empty context" do
        result = context_loader.load_docs_context

        expect(result[:success]).to be true
        expect(result[:context]).to eq("")
        expect(result[:files_loaded]).to eq(0)
        expect(result[:files_failed]).to eq(0)
        expect(result[:failed_files]).to be_nil
      end
    end

    context "when docs directory contains markdown files" do
      before do
        # Create test markdown files
        File.write(File.join(docs_dir, "README.md"), "# Main Documentation\n\nThis is the main docs.")
        File.write(File.join(docs_dir, "guide.md"), "# User Guide\n\nStep-by-step instructions.")

        # Create subdirectory with markdown file
        subdir = File.join(docs_dir, "api")
        FileUtils.mkdir_p(subdir)
        File.write(File.join(subdir, "endpoints.md"), "# API Endpoints\n\nREST API documentation.")

        # Create non-markdown file (should be ignored)
        File.write(File.join(docs_dir, "config.txt"), "Some config content")
      end

      it "loads all markdown files successfully" do
        result = context_loader.load_docs_context

        expect(result[:success]).to be true
        expect(result[:files_loaded]).to eq(3)
        expect(result[:files_failed]).to eq(0)
        expect(result[:failed_files]).to be_nil
      end

      it "generates proper XML embedded context format" do
        result = context_loader.load_docs_context
        context = result[:context]

        expect(context).to start_with("<context>\n")
        expect(context).to end_with("</context>")

        # Should contain all three markdown files
        expect(context).to include('path="docs/README.md"')
        expect(context).to include('path="docs/guide.md"')
        expect(context).to include('path="docs/api/endpoints.md"')

        # Should contain file contents
        expect(context).to include("# Main Documentation")
        expect(context).to include("# User Guide")
        expect(context).to include("# API Endpoints")

        # Should not contain non-markdown files
        expect(context).not_to include("config.txt")
        expect(context).not_to include("Some config content")
      end

      it "indents content properly for XML structure" do
        result = context_loader.load_docs_context
        context = result[:context]

        # Check that content is properly indented (8 spaces)
        lines = context.split("\n")
        content_lines = lines.select { |line| line.start_with?("        ") && !line.strip.empty? }
        expect(content_lines).not_to be_empty

        # Verify document structure
        expect(context).to match(/    <document path="[^"]+">/)
        expect(context).to match(/        # .+/)
        expect(context).to match(/    <\/document>/)
      end

      it "sorts files alphabetically" do
        result = context_loader.load_docs_context
        context = result[:context]

        # Extract the order of file paths from the context
        path_matches = context.scan(/path="([^"]+)"/)
        paths = path_matches.flatten

        expect(paths).to eq(paths.sort)
      end
    end

    context "when some files are unreadable" do
      before do
        File.write(File.join(docs_dir, "readable.md"), "# Readable File\n\nContent here.")

        # Create an unreadable file by making it write-only
        unreadable_file = File.join(docs_dir, "unreadable.md")
        File.write(unreadable_file, "# Unreadable File")
        File.chmod(0o000, unreadable_file)
      end

      after do
        # Restore permissions for cleanup
        unreadable_file = File.join(docs_dir, "unreadable.md")
        File.chmod(0o644, unreadable_file) if File.exist?(unreadable_file)
      end

      it "loads readable files and reports failed files" do
        result = context_loader.load_docs_context

        expect(result[:success]).to be true
        expect(result[:files_loaded]).to eq(1)
        expect(result[:files_failed]).to eq(1)
        expect(result[:failed_files]).to be_an(Array)
        expect(result[:failed_files].length).to eq(1)

        failed_file = result[:failed_files].first
        expect(failed_file[:path]).to eq("docs/unreadable.md")
        expect(failed_file[:error]).to be_a(String)
      end

      it "includes readable file content in context" do
        result = context_loader.load_docs_context
        context = result[:context]

        expect(context).to include("# Readable File")
        expect(context).to include('path="docs/readable.md"')
      end
    end

    context "when an exception occurs during processing" do
      before do
        # Create a file to ensure docs directory exists
        File.write(File.join(docs_dir, "test.md"), "# Test")
      end

      it "returns failure result with error message" do
        # Mock Dir.glob to raise an exception
        allow(Dir).to receive(:glob).and_raise(StandardError.new("Filesystem error"))

        result = context_loader.load_docs_context

        expect(result[:success]).to be false
        expect(result[:error]).to include("Context loading failed")
        expect(result[:error]).to include("Filesystem error")
      end
    end

    context "with complex file content" do
      before do
        # Test file with various content types
        complex_content = <<~MARKDOWN
          # Complex Document
          
          This document contains various elements:
          
          ## Code Block
          ```ruby
          def hello_world
            puts "Hello, World!"
          end
          ```
          
          ## Special Characters
          - Quotes: "double" and 'single'
          - Ampersands: A & B
          - Less than: <script>
          - Greater than: >
          
          ## Unicode
          Emoji: 🚀 📝 ✅
          Accents: café, naïve, résumé
        MARKDOWN

        File.write(File.join(docs_dir, "complex.md"), complex_content)
      end

      it "preserves all content including special characters" do
        result = context_loader.load_docs_context
        context = result[:context]

        expect(context).to include("def hello_world")
        expect(context).to include("puts \"Hello, World!\"")
        expect(context).to include("\"double\" and 'single'")
        expect(context).to include("A & B")
        expect(context).to include("<script>")
        expect(context).to include("🚀 📝 ✅")
        expect(context).to include("café, naïve, résumé")
      end
    end
  end

  describe "#format_embedded_context" do
    let(:context_loader) { described_class.new(mock_sandbox) }

    context "with empty documents array" do
      it "returns empty context tags" do
        result = context_loader.send(:format_embedded_context, [])
        expect(result).to eq("")
      end
    end

    context "with single document" do
      let(:documents) do
        [{
          path: "docs/single.md",
          content: "# Single Document\n\nSimple content."
        }]
      end

      it "formats single document correctly" do
        result = context_loader.send(:format_embedded_context, documents)

        expect(result).to start_with("<context>\n")
        expect(result).to end_with("</context>")
        expect(result).to include('    <document path="docs/single.md">')
        expect(result).to include("        # Single Document")
        expect(result).to include("        Simple content.")
        expect(result).to include("    </document>")
      end
    end

    context "with multiple documents" do
      let(:documents) do
        [
          {
            path: "docs/first.md",
            content: "# First\nContent 1"
          },
          {
            path: "docs/second.md",
            content: "# Second\nContent 2"
          }
        ]
      end

      it "formats multiple documents correctly" do
        result = context_loader.send(:format_embedded_context, documents)

        expect(result).to include('    <document path="docs/first.md">')
        expect(result).to include("        # First")
        expect(result).to include("        Content 1")
        expect(result).to include('    <document path="docs/second.md">')
        expect(result).to include("        # Second")
        expect(result).to include("        Content 2")

        # Verify proper document separation
        first_doc_end = result.index("    </document>")
        second_doc_start = result.index('    <document path="docs/second.md">')
        expect(second_doc_start).to be > first_doc_end
      end
    end

    context "with document containing no newlines" do
      let(:documents) do
        [{
          path: "docs/oneline.md",
          content: "Single line content without newline"
        }]
      end

      it "handles content without trailing newlines" do
        result = context_loader.send(:format_embedded_context, documents)

        expect(result).to include("        Single line content without newline")
        expect(result).to include("    </document>")
      end
    end

    context "with document containing multiple newlines" do
      let(:documents) do
        [{
          path: "docs/multiline.md",
          content: "Line 1\n\nLine 3\n\n\nLine 6\n"
        }]
      end

      it "preserves all newlines and indentation" do
        result = context_loader.send(:format_embedded_context, documents)

        lines = result.split("\n")
        content_lines = lines.select { |line| line.start_with?("        ") }

        expect(content_lines[0]).to eq("        Line 1")
        expect(content_lines[1]).to eq("        ")  # Empty line with indentation
        expect(content_lines[2]).to eq("        Line 3")
        expect(content_lines[3]).to eq("        ")  # Empty line with indentation
        expect(content_lines[4]).to eq("        ")  # Empty line with indentation
        expect(content_lines[5]).to eq("        Line 6")
        # The final trailing newline creates an empty indented line, but the join doesn't add extra content
        expect(content_lines.length).to eq(6)
      end
    end

    context "with document containing XML-like content" do
      let(:documents) do
        [{
          path: "docs/xml.md",
          content: "# XML Example\n\n<tag attribute=\"value\">Content</tag>"
        }]
      end

      it "preserves XML-like content as-is" do
        result = context_loader.send(:format_embedded_context, documents)

        expect(result).to include("        <tag attribute=\"value\">Content</tag>")
      end
    end
  end

  describe "integration with ProjectSandbox" do
    context "when using real ProjectSandbox" do
      let(:real_sandbox) { CodingAgentTools::Molecules::ProjectSandbox.new(project_root) }
      let(:context_loader) { described_class.new(real_sandbox) }

      before do
        File.write(File.join(docs_dir, "integration.md"), "# Integration Test\n\nReal sandbox test.")
      end

      it "works with real ProjectSandbox instance" do
        result = context_loader.load_docs_context

        expect(result[:success]).to be true
        expect(result[:files_loaded]).to eq(1)
        expect(result[:context]).to include("# Integration Test")
      end
    end
  end

  describe "error handling and edge cases" do
    let(:context_loader) { described_class.new(mock_sandbox) }

    context "when project_root is nil" do
      before do
        allow(mock_sandbox).to receive(:project_root).and_return(nil)
      end

      it "handles nil project root gracefully" do
        result = context_loader.load_docs_context

        expect(result[:success]).to be false
        expect(result[:error]).to be_a(String)
      end
    end

    context "when docs directory path is invalid" do
      before do
        allow(mock_sandbox).to receive(:project_root).and_return("/nonexistent/path")
      end

      it "returns failure for nonexistent project root" do
        result = context_loader.load_docs_context

        expect(result[:success]).to be false
        expect(result[:error]).to include("Docs directory not found")
      end
    end

    context "when file reading raises unexpected error" do
      before do
        File.write(File.join(docs_dir, "test.md"), "# Test")

        # Mock File.read to raise an unexpected error for this specific file
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(File.join(docs_dir, "test.md")).and_raise(Errno::EIO.new("I/O error"))
      end

      it "captures and reports the error" do
        result = context_loader.load_docs_context

        expect(result[:success]).to be true
        expect(result[:files_loaded]).to eq(0)
        expect(result[:files_failed]).to eq(1)
        expect(result[:failed_files].first[:error]).to include("I/O error")
      end
    end
  end

  describe "performance considerations" do
    let(:context_loader) { described_class.new(mock_sandbox) }

    context "with many files" do
      before do
        # Create 50 small files to test performance
        50.times do |i|
          File.write(File.join(docs_dir, "file_#{i.to_s.rjust(2, "0")}.md"), "# File #{i}\n\nContent for file #{i}.")
        end
      end

      it "processes all files efficiently" do
        start_time = Time.now
        result = context_loader.load_docs_context
        end_time = Time.now

        expect(result[:success]).to be true
        expect(result[:files_loaded]).to eq(50)
        expect(end_time - start_time).to be < 5.0  # Should complete within 5 seconds
      end
    end

    context "with large files" do
      before do
        # Create a large file (approximately 100KB)
        large_content = "# Large File\n\n" + ("Lorem ipsum dolor sit amet. " * 4000)
        File.write(File.join(docs_dir, "large.md"), large_content)
      end

      it "handles large files correctly" do
        result = context_loader.load_docs_context

        expect(result[:success]).to be true
        expect(result[:files_loaded]).to eq(1)
        expect(result[:context].length).to be > 100_000
        expect(result[:context]).to include("# Large File")
      end
    end
  end
end
