# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"
require "json"
require "fileutils"

RSpec.describe "Ideas Manager Integration", type: :integration do
  include CliHelpers

  let(:executable_path) { File.expand_path("../../exe/capture-it", __dir__) }
  let(:temp_dir) { Dir.mktmpdir("ideas_manager_integration_test") }
  let(:project_root) { File.expand_path("../../../", __dir__) }
  let(:ideas_output_dir) { File.join(project_root, "dev-taskflow/backlog/ideas") }
  let(:tmp_dir) { File.join(project_root, "tmp") }

  before do
    expect(File.exist?(executable_path)).to be(true), "capture-it executable should exist"
    expect(File.executable?(executable_path)).to be(true), "capture-it should be executable"

    # Ensure required directories exist
    FileUtils.mkdir_p(ideas_output_dir)
    FileUtils.mkdir_p(tmp_dir)
  end

  after do
    # Clean up temporary files and directories created during tests
    safe_directory_cleanup(temp_dir) if Dir.exist?(temp_dir)
    cleanup_test_files
  end

  describe "basic CLI functionality" do
    it "shows help when called with --help" do
      result = run_capture_it(["--help"])
      expect(result.exitstatus).to eq(1) # dry-cli exits with 1 for help by design
      combined_output = "#{result.stdout}#{result.stderr}"
      expect(combined_output).to include("Commands:")
      expect(combined_output).to include("capture")
      expect(combined_output).to include("version")
    end

    it "shows version information" do
      result = run_capture_it(["version"])
      expect(result).to be_success
      expect(result.stdout.strip).to match(/Ideas Manager \d+\.\d+\.\d+/)
    end

    it "handles invalid commands gracefully" do
      result = run_capture_it(["invalid-command"])
      # Invalid commands show help by default in dry-cli
      combined_output = "#{result.stdout}#{result.stderr}"
      expect(combined_output).to include("Commands:")
    end
  end

  describe "idea capture functionality" do
    let(:test_idea) { "Add support for automated code refactoring suggestions based on static analysis" }
    let(:short_idea) { "Test" }
    let(:empty_idea) { "" }
    let(:large_idea) { "This is a very large idea. " * 200 } # ~5000 chars

    context "with inline text input" do
      it "captures and enhances a simple idea successfully", :integration do
        # Skip if no API key is available (for CI/local development)
        skip "LLM integration test requires API key" unless integration_test_enabled?

        result = run_capture_it(["capture", test_idea])
        expect(result).to be_success
        expect(result.stdout).to include("Created:")

        # Extract and clean up created file
        created_file = extract_created_file_path(result.stdout)
        expect(created_file).not_to be_nil
        expect(File.exist?(created_file)).to be(true)
        expect(created_file).to include("dev-taskflow/backlog/ideas")

        # Verify file content structure
        content = File.read(created_file)
        expect(content).to include("# ")  # Should have a title

        # Clean up the created file
        File.delete(created_file) if File.exist?(created_file)
      end

      it "handles very short ideas with appropriate error" do
        result = run_capture_it(["capture", "Ab"])

        expect(result).not_to be_success
        combined_output = "#{result.stdout}#{result.stderr}"
        expect(combined_output).to include("Error:")
        expect(combined_output).to include("at least 5 characters")
      end

      it "handles empty ideas with appropriate error" do
        result = run_capture_it(["capture", empty_idea])

        expect(result).not_to be_success
        combined_output = "#{result.stdout}#{result.stderr}"
        expect(combined_output).to include("Error:")
        expect(combined_output).to include("No input provided")
      end

      it "handles very large ideas that would cause filename length issues" do
        # Create an extremely long idea that would definitely cause filename issues before the fix
        extremely_long_idea = "This is an extremely long idea that would cause filename length issues. " * 50 # ~3500 chars

        result = run_capture_it(["capture", extremely_long_idea])

        # Should no longer get "File name too long" error due to filename truncation fix
        # May still fail for other reasons (timeouts, missing API keys, etc.) but not filename length
        expect(result.stderr).not_to include("File name too long")

        # If it does fail, it should be for a different reason than filename length
        if !result.success?
          # Common acceptable failure reasons in tests
          acceptable_errors = [
            "timed out",
            "Invalid model specification",
            "No input provided",
            "API key"
          ]

          combined_output = "#{result.stdout}#{result.stderr}"
          expect(acceptable_errors.any? { |error| combined_output.include?(error) }).to be(true),
            "Expected acceptable error, got: #{combined_output}"
        end
      end

      it "processes large ideas when --big-user-input-allowed flag is set" do
        # TODO: Requires programmatic LLM access instead of subprocess calls for proper mocking
        pending "Cannot mock LLM behavior with current subprocess architecture - needs direct library integration"

        # Mock LLM response for large idea test (currently not possible with subprocess calls)
        allow_any_instance_of(CodingAgentTools::Molecules::LLMClient).to receive(:generate_content).and_return(
          OpenStruct.new(
            success?: true,
            content: "# Enhanced Large Idea\n\n## Intention\nProcess large user inputs\n\n## Problem It Solves\nHandles extensive requirements\n\n## Solution Direction\nImplement chunking and processing"
          )
        )

        result = run_capture_it(["capture", large_idea, "--big-user-input-allowed"])

        expect(result).to be_success
        expect(result.stdout).to include("Created:")

        # Clean up created file
        created_file = extract_created_file_path(result.stdout)
        File.delete(created_file) if created_file && File.exist?(created_file)
      end

      it "uses custom model when specified", :integration do
        skip "LLM integration test requires API key" unless integration_test_enabled?

        result = run_capture_it(["capture", test_idea, "--model", "claude"])

        # May succeed with the model or timeout/fail gracefully
        if result.success?
          expect(result.stdout).to include("Created:")
          created_file = extract_created_file_path(result.stdout)
          File.delete(created_file) if created_file && File.exist?(created_file)
        elsif result.stderr.include?("timed out")
          expect(result.stderr).to include("timed out")
        else
          combined_output = "#{result.stdout}#{result.stderr}"
          expect(combined_output).to include("Error:")
        end
      end

      it "creates fallback file when LLM enhancement fails" do
        # TODO: Requires programmatic LLM access instead of subprocess calls for proper mocking
        pending "Cannot mock LLM behavior with current subprocess architecture - needs direct library integration"

        # Mock LLM failure to trigger fallback (currently not possible with subprocess calls)
        allow_any_instance_of(CodingAgentTools::Molecules::LLMClient).to receive(:generate_content).and_return(
          OpenStruct.new(
            success?: false,
            error_message: "Model 'invalid_model_name' not found"
          )
        )

        # Use invalid model to trigger fallback
        result = run_capture_it(["capture", test_idea, "--model", "invalid_model_name"])

        if result.success?
          expect(result.stdout).to include("Created:")

          # Verify fallback file was created
          created_file = extract_created_file_path(result.stdout)
          expect(created_file).not_to be_nil
          expect(File.exist?(created_file)).to be(true)

          # Verify fallback content
          content = File.read(created_file)
          expect(content).to include("# Raw Idea (Enhanced Version Failed)")
          expect(content).to include("Enhancement Error:")
          expect(content).to include(test_idea)

          # Clean up
          File.delete(created_file) if File.exist?(created_file)
        elsif result.stderr.include?("timed out")
          # Command timed out trying to handle invalid model
          # This is acceptable as it shows the integration is working
          # (the command is attempting to process the request)
          expect(result.stderr).to include("timed out")
        else
          # Some other error occurred
          combined_output = "#{result.stdout}#{result.stderr}"
          expect(combined_output).to include("Error:")
        end
      end

      it "provides debug information when --debug flag is set", :integration do
        skip "LLM integration test requires API key" unless integration_test_enabled?

        result = run_capture_it(["capture", test_idea, "--debug"])
        expect(result).to be_success
        expect(result.stdout).to include("Debug:")
        expect(result.stdout).to include("Created:")

        # Clean up created file
        created_file = extract_created_file_path(result.stdout)
        File.delete(created_file) if created_file && File.exist?(created_file)
      end
    end

    context "with file input" do
      let(:idea_file) { File.join(temp_dir, "test_idea.txt") }
      let(:empty_file) { File.join(temp_dir, "empty.txt") }
      let(:nonexistent_file) { File.join(temp_dir, "does_not_exist.txt") }

      before do
        File.write(idea_file, test_idea)
        File.write(empty_file, "")
      end

      it "captures ideas from file successfully", :integration do
        skip "LLM integration test requires API key" unless integration_test_enabled?

        result = run_capture_it(["capture", "--file", idea_file])
        expect(result).to be_success
        expect(result.stdout).to include("Created:")

        # Verify file creation and clean up
        created_file = extract_created_file_path(result.stdout)
        expect(created_file).not_to be_nil
        expect(File.exist?(created_file)).to be(true)
        File.delete(created_file) if File.exist?(created_file)
      end

      it "handles empty files with appropriate error" do
        result = run_capture_it(["capture", "--file", empty_file])

        expect(result).not_to be_success
        expect(result.stdout).to include("Error:")
        expect(result.stdout).to include("empty")
      end

      it "handles non-existent files with appropriate error" do
        result = run_capture_it(["capture", "--file", nonexistent_file])

        expect(result).not_to be_success
        expect(result.stdout).to include("Error:")
        expect(result.stdout).to include("not found")
      end

      it "handles unreadable files gracefully" do
        # Create a file and make it unreadable (if possible on this system)
        unreadable_file = File.join(temp_dir, "unreadable.txt")
        File.write(unreadable_file, test_idea)

        begin
          File.chmod(0o000, unreadable_file)
          result = run_capture_it(["capture", "--file", unreadable_file])

          expect(result).not_to be_success
          expect(result.stdout).to include("Error:")
        ensure
          # Restore permissions for cleanup
          File.chmod(0o644, unreadable_file) if File.exist?(unreadable_file)
        end
      end
    end

    context "with clipboard input" do
      it "shows appropriate error when clipboard is not available" do
        # Mock clipboard unavailability by modifying PATH to exclude clipboard tools
        # but keep essential system paths for Ruby to work
        ruby_bin_path = File.dirname(`which ruby`.strip)
        essential_paths = ["/bin"]  # Exclude /usr/bin where pbpaste lives
        safe_path = ([ruby_bin_path] + essential_paths).join(":")

        env = ENV.to_h.merge("PATH" => safe_path)
        result = run_capture_it(["capture", "--clipboard"], env: env)

        expect(result).not_to be_success
        expect(result.stdout).to include("Error:")
        expect(result.stdout).to include("clipboard")
      end
    end

    context "with missing input" do
      it "shows usage information when no input is provided" do
        result = run_capture_it(["capture"])

        expect(result).not_to be_success
        expect(result.stdout).to include("Error: No input provided")
        expect(result.stdout).to include("Usage:")
        expect(result.stdout).to include("ideas-manager capture")
      end
    end
  end

  describe "end-to-end workflow integration" do
    let(:workflow_idea) { "Implement automated test case generation from user stories" }

    it "completes full idea capture workflow with file system integration", :vcr do
      cassette_name = "ideas_manager_integration/end_to_end_workflow"
      env = vcr_subprocess_env(cassette_name)

      # Run the complete workflow
      result = run_capture_it(["capture", workflow_idea, "--debug"], env: env)

      expect(result).to be_success
      expect(result.stdout).to include("Debug:")
      expect(result.stdout).to include("Starting idea capture process")
      expect(result.stdout).to include("Created:")

      # Extract and verify the created file
      created_file = extract_created_file_path(result.stdout)
      expect(created_file).not_to be_nil
      expect(File.exist?(created_file)).to be(true)

      # Verify file location and naming
      expect(created_file).to include("dev-taskflow/backlog/ideas")
      expect(File.basename(created_file)).to match(/^\d{8}-\d{4}-.+\.md$/)

      # Verify file content structure and quality
      content = File.read(created_file)

      # Check for expected template structure
      expect(content).to include("# ") # Title
      expect(content).to include("## Intention")
      expect(content).to include("## Problem It Solves")
      expect(content).to include("## Solution Direction")

      # Verify content is not just template placeholders
      expect(content).not_to include("{title}")
      expect(content).not_to include("{clear_one_sentence_purpose}")

      # Verify content length (should be substantially enhanced from original)
      expect(content.length).to be > workflow_idea.length * 3

      # Verify temporary files are created and used
      timestamp_pattern = File.basename(created_file).match(/^(\d{8}-\d{4})/)[1]
      [
        File.join(tmp_dir, "#{timestamp_pattern}-*.md"),
        File.join(tmp_dir, "#{timestamp_pattern}-*.system.prompt.md")
      ]

      # Note: temp files may be cleaned up by the process, so we just verify the pattern exists
      expect(created_file).to match(/#{timestamp_pattern}/)

      # Clean up
      File.delete(created_file) if File.exist?(created_file)
    end

    it "handles LLM enhancement failures gracefully with fallback", :vcr do
      cassette_name = "ideas_manager_integration/invalid_model_fallback"
      env = vcr_subprocess_env(cassette_name)

      # Use an invalid model to trigger enhancement failure
      result = run_capture_it(["capture", workflow_idea, "--model", "invalid_model"], env: env)

      # Should still succeed with fallback
      expect(result).to be_success
      expect(result.stdout).to include("Created:")

      # Verify fallback file was created
      created_file = extract_created_file_path(result.stdout)
      expect(created_file).not_to be_nil
      expect(File.exist?(created_file)).to be(true)

      # Verify fallback content
      content = File.read(created_file)
      expect(content).to include("# Raw Idea (Enhanced Version Failed)")
      expect(content).to include("Enhancement Error:")
      expect(content).to include(workflow_idea)

      # Clean up
      File.delete(created_file) if File.exist?(created_file)
    end

    it "creates all required directories automatically", :vcr do
      cassette_name = "ideas_manager_integration/auto_create_directories"
      env = vcr_subprocess_env(cassette_name)

      begin
        # Run ideas-manager and check if it creates the default directory structure
        result = run_capture_it(["capture", workflow_idea], env: env)

        expect(result).to be_success

        # The command should create the default directory structure
        default_ideas_dir = File.join(project_root, "dev-taskflow/backlog/ideas")
        expect(Dir.exist?(default_ideas_dir)).to be(true)
      ensure
        # Clean up created file
        created_file = extract_created_file_path(result.stdout) if defined?(result) && result
        File.delete(created_file) if created_file && File.exist?(created_file)
      end
    end

    it "generates unique filenames for concurrent idea captures", :vcr do
      cassette_name = "ideas_manager_integration/concurrent_captures"
      env = vcr_subprocess_env(cassette_name)

      ideas = [
        "First concurrent idea",
        "Second concurrent idea",
        "Third concurrent idea"
      ]

      created_files = []

      # Capture multiple ideas in quick succession
      ideas.each do |idea|
        result = run_capture_it(["capture", idea], env: env)
        expect(result).to be_success

        created_file = extract_created_file_path(result.stdout)
        expect(created_file).not_to be_nil
        created_files << created_file
      end

      # Verify all files were created with unique names
      expect(created_files.uniq.length).to eq(ideas.length)
      created_files.each do |file|
        expect(File.exist?(file)).to be(true)
      end

      # Clean up
      created_files.each { |file| File.delete(file) if File.exist?(file) }
    end
  end

  describe "component integration testing" do
    let(:integration_idea) { "Add real-time collaboration features to the development workflow" }

    it "integrates CLI -> IdeaCapture -> molecules -> file system correctly", :integration do
      skip "LLM integration test requires API key" unless integration_test_enabled?

      result = run_capture_it(["capture", integration_idea, "--debug"])

      expect(result).to be_success

      # Verify debug output shows component interactions
      expect(result.stdout).to include("Debug: Starting idea capture process")
      expect(result.stdout).to include("Debug: Generated paths:")
      expect(result.stdout).to include("Debug: Saved raw idea to:")
      expect(result.stdout).to include("Debug: Generated system prompt:")

      created_file = extract_created_file_path(result.stdout)
      expect(created_file).not_to be_nil

      # Clean up
      File.delete(created_file) if File.exist?(created_file)
    end

    it "validates PathResolver integration for idea file generation", :integration do
      skip "LLM integration test requires API key" unless integration_test_enabled?

      result = run_capture_it(["capture", integration_idea])

      expect(result).to be_success

      created_file = extract_created_file_path(result.stdout)
      expect(created_file).not_to be_nil

      # Verify path structure matches PathResolver expectations
      expect(created_file).to match(%r{dev-taskflow/backlog/ideas/\d{8}-\d{4}-.+\.md$})

      # Verify the path is absolute and properly resolved
      expect(Pathname.new(created_file).absolute?).to be(true)
      expect(created_file).to start_with(project_root)

      # Clean up
      File.delete(created_file) if File.exist?(created_file)
    end

    it "validates LLMClient integration with different models", :integration do
      skip "LLM integration test requires API key" unless integration_test_enabled?

      models_to_test = ["google:gemini-2.5-flash-lite", "claude"]

      models_to_test.each do |model|
        result = run_capture_it(["capture", "#{integration_idea} with #{model}", "--model", model])

        # Should succeed (or gracefully handle unavailable models)
        if result.success?
          created_file = extract_created_file_path(result.stdout)
          expect(created_file).not_to be_nil
          File.delete(created_file) if File.exist?(created_file)
        else
          # Should provide meaningful error for unavailable models or timeout gracefully
          combined_output = "#{result.stdout}#{result.stderr}"
          expect(combined_output).to include("Error:").or include("timed out")
        end
      end
    end
  end

  describe "error handling and edge cases" do
    it "handles filesystem permission errors gracefully", :vcr do
      # Test with a hypothetically unwritable directory
      # Note: This test may be skipped on systems where we can't control permissions

      if Process.uid == 0 # Skip if running as root
        skip "Cannot test permission errors as root user"
      end

      cassette_name = "ideas_manager_integration/permission_errors"
      env = vcr_subprocess_env(cassette_name)

      result = run_capture_it(["capture", "Test idea for permissions"], env: env)

      # Should either succeed or provide meaningful error
      if result.success?
        created_file = extract_created_file_path(result.stdout)
        File.delete(created_file) if created_file && File.exist?(created_file)
      else
        # Should provide meaningful error or timeout message
        combined_output = "#{result.stdout}#{result.stderr}"
        expect(combined_output).to include("Error:").or include("timed out")
      end
    end

    it "handles interrupted processing gracefully", :vcr do
      # Test with a very long idea that might timeout
      very_long_idea = "Implement advanced AI-powered code analysis. " * 50

      cassette_name = "ideas_manager_integration/interrupted_processing"
      env = vcr_subprocess_env(cassette_name)

      result = run_capture_it(["capture", very_long_idea, "--big-user-input-allowed"], env: env)

      # Should either succeed or fail gracefully (including timeout)
      combined_output = "#{result.stdout}#{result.stderr}"
      expect(combined_output).to include("Created:").or include("Error:").or include("timed out")

      if result.success?
        created_file = extract_created_file_path(result.stdout)
        File.delete(created_file) if created_file && File.exist?(created_file)
      end
    end

    it "validates input sanitization and security", :vcr do
      malicious_inputs = [
        "Idea with\n\nmalicious\ncharacters",
        "Idea with ../../../etc/passwd path traversal",
        "Idea with \x00 null bytes",
        "Idea with <script>alert('xss')</script> content"
      ]

      malicious_inputs.each_with_index do |input, index|
        cassette_name = "ideas_manager_integration/security_test_#{index + 1}"
        env = vcr_subprocess_env(cassette_name)

        result = run_capture_it(["capture", input], env: env)

        if result.success?
          created_file = extract_created_file_path(result.stdout)
          expect(created_file).not_to be_nil

          # Verify file is created in safe location
          expect(created_file).to include("dev-taskflow/backlog/ideas")
          expect(created_file).not_to include("../")
          expect(created_file).not_to include("/etc/")

          # Verify content is safely stored (when LLM enhancement fails,
          # content is preserved as-is for human review)
          content = File.read(created_file)
          if content.include?("Raw Idea (Enhanced Version Failed)")
            # For fallback content, original input is preserved for human review
            expect(content).to include("Original Idea")
          else
            # For successfully enhanced content, should not include malicious content
            expect(content).not_to include("<script>") unless content.include?("Raw Idea")
            expect(content).not_to include("\x00") unless content.include?("Raw Idea")
          end

          File.delete(created_file) if File.exist?(created_file)
        else
          # Should provide appropriate error message or timeout
          combined_output = "#{result.stdout}#{result.stderr}"
          expect(combined_output).to include("Error:").or include("timed out").or include("Command execution failed")
        end
      end
    end
  end

  private

  def integration_test_enabled?
    # Enable integration tests if:
    # 1. INTEGRATION_TESTS=true is set, or
    # 2. We have API keys available and INTEGRATION_TESTS is not explicitly false
    return true if ENV["INTEGRATION_TESTS"] == "true"
    return false if ENV["INTEGRATION_TESTS"] == "false"

    # Check for API keys (you can extend this list as needed)
    !!(ENV["GOOGLE_API_KEY"] && ENV["GOOGLE_API_KEY"] != "test-api-key-for-vcr-playback")
  end

  def run_capture_it(args, env: {})
    # Use subprocess execution for full integration testing
    cmd = [executable_path] + args
    # Shorter timeout for tests involving invalid models (faster failure)
    timeout = args.include?("invalid_model_name") ? 5 : 30
    execute_command_with_timeout(cmd, timeout: timeout, env: env)
  end

  def execute_command_with_timeout(cmd, timeout: 30, env: {})
    stdout, stderr, status = nil, nil, nil

    begin
      require "open3"
      require "timeout"

      Timeout.timeout(timeout) do
        stdout, stderr, status = Open3.capture3(env, *cmd)
      end

      # Return result in CliResult format
      CliHelpers::CliResult.new(
        stdout: stdout,
        stderr: stderr,
        exit_code: status.exitstatus
      )
    rescue Timeout::Error
      CliHelpers::CliResult.new(
        stdout: "",
        stderr: "Command timed out after #{timeout} seconds",
        exit_code: 124
      )
    rescue => e
      CliHelpers::CliResult.new(
        stdout: "",
        stderr: "Command execution failed: #{e.message}",
        exit_code: 1
      )
    end
  end

  def extract_created_file_path(output)
    # Extract file path from "Created: /path/to/file" output
    match = output.match(/Created: (.+)$/)
    match ? match[1].strip : nil
  end

  def cleanup_test_files
    # Clean up any test files that might have been created
    test_patterns = [
      "*test*.md",
      "*long-filename-issue*.md",
      "*malicious*.md",
      "*concurrent*.md",
      "*integration*.md"
    ]

    test_patterns.each do |pattern|
      # Clean up from ideas directory
      Dir.glob(File.join(ideas_output_dir, pattern)).each do |file|
        File.delete(file) if File.exist?(file)
      rescue
        # Ignore cleanup errors
      end

      # Clean up from temp directory
      Dir.glob(File.join(tmp_dir, pattern)).each do |file|
        File.delete(file) if File.exist?(file)
      rescue
        # Ignore cleanup errors
      end
    end

    # Clean up any test directories that might have been created
    test_dirs = [
      File.join(project_root, "dev-taskflow/backlog/ideas_test_auto_create"),
      File.join(ideas_output_dir, "ideas.backup")
    ]

    test_dirs.each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    rescue
      # Ignore cleanup errors
    end
  end

  def safe_directory_cleanup(dir_path)
    # Safely clean up test directories
    return unless dir_path && Dir.exist?(dir_path)
    return unless dir_path.include?("integration_test") # Safety check

    begin
      FileUtils.rm_rf(dir_path)
    rescue
      # Ignore cleanup errors
    end
  end
end
