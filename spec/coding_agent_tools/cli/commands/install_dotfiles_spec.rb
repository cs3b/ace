# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::InstallDotfiles do
  let(:command) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:project_root) { temp_dir }
  let(:template_dir) { File.join(project_root, "dev-handbook", ".meta", "tpl", "dotfiles") }
  let(:target_dir) { File.join(project_root, ".coding-agent") }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
      .and_return(project_root)

    # Create template directory and files for testing
    FileUtils.mkdir_p(template_dir)
    create_template_file("lint.yml", "# Lint configuration")
    create_template_file("config.yml", "# General configuration")
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  def create_template_file(filename, content)
    File.write(File.join(template_dir, filename), content)
  end

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  def capture_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end

  describe "#call" do
    context "with default options" do
      it "creates target directory if it doesn't exist" do
        expect(Dir.exist?(target_dir)).to be(false)

        capture_stdout { command.call }

        expect(Dir.exist?(target_dir)).to be(true)
      end

      it "copies template files to target directory" do
        output = capture_stdout { command.call }

        expect(File.exist?(File.join(target_dir, "lint.yml"))).to be(true)
        expect(File.exist?(File.join(target_dir, "config.yml"))).to be(true)
        expect(output).to include("Created directory: #{target_dir}")
        expect(output).to include("Copied: lint.yml")
        expect(output).to include("Copied: config.yml")
      end

      it "shows summary of copied files" do
        output = capture_stdout { command.call }

        expect(output).to include("Installation complete:")
        expect(output).to include("Copied: 2 files")
        expect(output).to include("Skipped: 0 files")
        expect(output).to include("Configuration files are now available in .coding-agent/")
      end

      it "returns 0 on success" do
        result = nil
        capture_stdout { result = command.call }

        expect(result).to eq(0)
      end
    end

    context "with dry_run option" do
      it "shows what would be done without actually copying" do
        output = capture_stdout { command.call(dry_run: true) }

        expect(output).to include("Would create directory: #{target_dir}")
        expect(output).to include("Would copy: lint.yml")
        expect(output).to include("Would copy: config.yml")
        expect(Dir.exist?(target_dir)).to be(false)
      end

      it "shows dry run summary" do
        output = capture_stdout { command.call(dry_run: true) }

        expect(output).to include("Dry run complete:")
        expect(output).to include("Would copy: 2 files")
        expect(output).to include("Would skip: 0 files")
      end
    end

    context "with debug option" do
      it "shows debug information" do
        output = capture_stdout { command.call(debug: true) }

        expect(output).to include("Debug: Project root: #{project_root}")
        expect(output).to include("Debug: Template directory: #{template_dir}")
        expect(output).to include("Debug: Target directory: #{target_dir}")
      end
    end

    context "when target directory already exists" do
      before do
        FileUtils.mkdir_p(target_dir)
      end

      it "does not try to create the directory again" do
        output = capture_stdout { command.call }

        expect(output).not_to include("Created directory: #{target_dir}")
        expect(output).to include("Copied: lint.yml")
      end
    end

    context "when target files already exist" do
      before do
        FileUtils.mkdir_p(target_dir)
        File.write(File.join(target_dir, "lint.yml"), "# Existing content")
      end

      context "without force option" do
        it "skips existing files" do
          output = capture_stdout { command.call }

          expect(output).to include("Skipping existing file: lint.yml (use --force to overwrite)")
          expect(output).to include("Copied: config.yml")
          expect(output).to include("Copied: 1 files")
          expect(output).to include("Skipped: 1 files")
        end

        it "preserves existing file content" do
          capture_stdout { command.call }

          existing_content = File.read(File.join(target_dir, "lint.yml"))
          expect(existing_content).to eq("# Existing content")
        end
      end

      context "with force option" do
        it "overwrites existing files" do
          output = capture_stdout { command.call(force: true) }

          expect(output).to include("Copied: lint.yml")
          expect(output).to include("Copied: config.yml")
          expect(output).to include("Copied: 2 files")
          expect(output).to include("Skipped: 0 files")
        end

        it "replaces existing file content" do
          capture_stdout { command.call(force: true) }

          new_content = File.read(File.join(target_dir, "lint.yml"))
          expect(new_content).to eq("# Lint configuration")
        end
      end

      context "with dry_run and existing files" do
        it "shows what would be skipped" do
          output = capture_stdout { command.call(dry_run: true) }

          expect(output).to include("Would skip existing file: lint.yml")
          expect(output).to include("Would copy: config.yml")
        end
      end
    end

    context "when template directory is missing" do
      before do
        FileUtils.rm_rf(template_dir)
      end

      it "returns error and exits with code 1" do
        error_output = capture_stderr { command.call }

        expect(error_output).to include("Error: Could not find dotfiles templates.")
        expect(error_output).to include("Expected location: dev-handbook/.meta/tpl/dotfiles/")
        
        result = nil
        capture_stderr { result = command.call }
        expect(result).to eq(1)
      end
    end

    context "when template directory exists but is empty" do
      before do
        FileUtils.rm_rf(Dir.glob(File.join(template_dir, "*")))
      end

      it "returns error about no template files" do
        error_output = capture_stderr { command.call }

        expect(error_output).to include("Error: Could not find dotfiles templates.")
        
        result = nil
        capture_stderr { result = command.call }
        expect(result).to eq(1)
      end
    end

    context "when an exception occurs during file operations" do
      before do
        allow(FileUtils).to receive(:cp).and_raise(StandardError, "Permission denied")
      end

      context "without debug option" do
        it "handles the exception and shows basic error" do
          stdout_output = nil
          error_output = nil
          
          # Capture both stdout and stderr to prevent output leakage
          stdout_output = capture_stdout do
            error_output = capture_stderr { command.call }
          end

          expect(error_output).to include("Error: Permission denied")
          expect(error_output).to include("Use --debug flag for more information")
          
          result = nil
          capture_stderr { result = command.call }
          expect(result).to eq(1)
        end
      end

      context "with debug option" do
        it "shows detailed error information including backtrace" do
          stdout_output = nil
          error_output = nil
          
          # Capture both stdout (for debug output) and stderr (for error messages)
          stdout_output = capture_stdout do
            error_output = capture_stderr { command.call(debug: true) }
          end

          expect(error_output).to include("Error: StandardError: Permission denied")
          expect(error_output).to include("Backtrace:")
          expect(stdout_output).to include("Debug: Project root:")
          
          result = nil
          capture_stderr { result = command.call }
          expect(result).to eq(1)
        end
      end
    end

    context "with alternative template directory locations" do
      let(:alt_template_dir) { File.join(project_root, ".meta", "tpl", "dotfiles") }

      before do
        FileUtils.rm_rf(template_dir)
        FileUtils.mkdir_p(alt_template_dir)
        File.write(File.join(alt_template_dir, "alt.yml"), "# Alternative config")
      end

      it "finds template directory in alternative location" do
        output = capture_stdout { command.call }

        expect(output).to include("Copied: alt.yml")
        expect(File.exist?(File.join(target_dir, "alt.yml"))).to be(true)
      end
    end

    context "with third fallback template directory" do
      let(:fallback_template_dir) { File.join(project_root, "templates", "dotfiles") }

      before do
        FileUtils.rm_rf(template_dir)
        FileUtils.mkdir_p(fallback_template_dir)
        File.write(File.join(fallback_template_dir, "fallback.yml"), "# Fallback config")
      end

      it "finds template directory in fallback location" do
        output = capture_stdout { command.call }

        expect(output).to include("Copied: fallback.yml")
        expect(File.exist?(File.join(target_dir, "fallback.yml"))).to be(true)
      end
    end

    context "edge cases" do
      it "handles empty options hash" do
        result = nil
        capture_stdout { result = command.call }

        expect(result).to eq(0)
      end

      it "handles mixed boolean options" do
        output = capture_stdout do
          command.call(force: true, dry_run: false, debug: true)
        end

        expect(output).to include("Debug: Project root:")
        expect(File.exist?(File.join(target_dir, "lint.yml"))).to be(true)
      end

      it "handles nil project root gracefully" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
          .and_return(nil)

        result = nil
        capture_stderr { result = command.call }
        expect(result).to eq(1)
      end
    end
  end

  describe "private methods" do
    describe "#find_template_directory" do
      context "with multiple candidate paths" do
        let(:first_candidate) { File.join(project_root, "dev-handbook", ".meta", "tpl", "dotfiles") }
        let(:second_candidate) { File.join(project_root, ".meta", "tpl", "dotfiles") }

        before do
          FileUtils.mkdir_p(first_candidate)
          FileUtils.mkdir_p(second_candidate)
          File.write(File.join(first_candidate, "first.yml"), "# First")
          File.write(File.join(second_candidate, "second.yml"), "# Second")
        end

        it "returns the first valid directory with template files" do
          result = command.send(:find_template_directory, project_root)

          expect(result).to eq(first_candidate)
        end
      end

      context "when directories exist but contain no yml files" do
        before do
          FileUtils.mkdir_p(File.join(project_root, "dev-handbook", ".meta", "tpl", "dotfiles"))
        end

        it "returns nil if directory exists but has no yml files" do
          # Remove all yml files from the template directory
          Dir.glob(File.join(template_dir, "*.yml")).each { |f| File.delete(f) }

          result = command.send(:find_template_directory, project_root)

          expect(result).to be_nil
        end
      end
    end

    describe "#handle_error" do
      let(:error) { StandardError.new("Test error") }

      before do
        allow(command).to receive(:warn)
        error.set_backtrace(["line1", "line2", "line3"])
      end

      context "with debug enabled" do
        it "outputs detailed error information" do
          command.send(:handle_error, error, true)

          expect(command).to have_received(:warn).with("Error: StandardError: Test error")
          expect(command).to have_received(:warn).with("\nBacktrace:")
          expect(command).to have_received(:warn).with("  line1")
          expect(command).to have_received(:warn).with("  line2")
          expect(command).to have_received(:warn).with("  line3")
        end
      end

      context "with debug disabled" do
        it "outputs basic error information" do
          command.send(:handle_error, error, false)

          expect(command).to have_received(:warn).with("Error: Test error")
          expect(command).to have_received(:warn).with("Use --debug flag for more information")
        end
      end
    end

    describe "#error_output" do
      it "delegates to warn" do
        allow(command).to receive(:warn)

        command.send(:error_output, "Test message")

        expect(command).to have_received(:warn).with("Test message")
      end
    end
  end
end
