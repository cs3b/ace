# frozen_string_literal: true

require_relative "../test_helper"

class SectionWorkflowIntegrationTest < AceTestCase
  def setup
    @env = Ace::TestSupport::TestEnvironment.new("section_workflow")
    @env.setup
    create_complex_section_preset
    create_base_presets
    create_test_files
  end

  def teardown
    @env.teardown
  end

  def test_complex_section_workflow_end_to_end
    Dir.chdir(@env.project_dir) do
      # Load the complex section preset through full pipeline
      context = Ace::Context.load_preset("comprehensive-review")

      # Verify section-based structure was detected
      refute_empty context.sections
      assert context.sections.key?(:comprehensive) || context.sections.key?('comprehensive')

      # Verify content was processed
      assert context.content.include?("README.md")
      assert context.content.include?("package.json")

      # Verify commands were executed
      assert context.commands
      assert context.commands.any? { |c| c[:command] == "npm test" }
      assert context.commands.any? { |c| c[:command] == "npm run lint" }

      # Verify section content is present
      assert context.content.include?("This comprehensive review includes:")
      assert context.content.include?("Focus on security and performance aspects.")
    end
  end

  def test_section_xml_output_format
    Dir.chdir(@env.project_dir) do
      # Test with markdown-xml format for sections
      context = Ace::Context.load_preset("comprehensive-review", format: "markdown-xml")

      # Should contain XML-style tags when using markdown-xml format
      assert context.content.include?("<file path=")
      assert context.content.include?("<output command=")
      assert context.content.include?("</file>")
      assert context.content.include?("</output>")

      # Should preserve section structure
      assert context.content.include?("Complete Review")
      assert context.content.include?("Files, commands, diffs, and analysis")
    end
  end

  def test_section_organize_by_sections_output
    Dir.chdir(@env.project_dir) do
      # Test that sections are processed correctly
      context = Ace::Context.load_preset("comprehensive-review")

      # Should have sections
      refute_empty context.sections
      assert context.sections.key?(:comprehensive) || context.sections.key?('comprehensive')

      # The section processor should preserve section ordering and content
      assert context.content.include?("Complete Review")
      assert context.content.include?("Files, commands, diffs, and analysis")
    end
  end

  private

  def create_complex_section_preset
    FileUtils.mkdir_p(File.join(@env.project_dir, ".ace/context/presets"))
    File.write(File.join(@env.project_dir, ".ace/context/presets/comprehensive-review.md"), <<~PRESET
      ---
      description: "Comprehensive review with mixed content"
      context:
        params:
          output: stdio
          format: markdown-xml
          timeout: 30

        sections:
          comprehensive:
            title: "Complete Review"
            description: "Files, commands, diffs, and analysis"
            files:
              - "*.md"
              - "package.json"
              - "src/**/*.js"
            commands:
              - "npm test"
              - "npm run lint"
              - "npm audit"
            diffs:
              - "origin/main...HEAD"
            content: |
              This comprehensive review includes:

              1. **Code Quality**: Style, patterns, maintainability
              2. **Security**: Vulnerabilities and dependencies
              3. **Testing**: Coverage and test results
              4. **Performance**: Potential bottlenecks

              Focus on security and performance aspects.
      ---
      # Comprehensive Review Preset

      This preset demonstrates mixed content within sections, combining files,
      commands, diffs, and analysis content in a single structured section.
    PRESET
    )
  end

  def create_base_presets
    # Create base presets that could be referenced
    File.write(File.join(@env.project_dir, ".ace/context/presets/security-scanning.md"), <<~PRESET
      ---
      description: "Security scanning tools"
      context:
        commands:
          - "npm audit"
          - "snyk test"
        files:
          - "**/*.js"
          - "package*.json"
      ---
      Security scanning preset
    PRESET
    )

    File.write(File.join(@env.project_dir, ".ace/context/presets/code-quality.md"), <<~PRESET
      ---
      description: "Code quality analysis"
      context:
        commands:
          - "npm run lint"
          - "npm run test"
        files:
          - "src/**/*.js"
          - "test/**/*.js"
      ---
      Code quality preset
    PRESET
    )
  end

  def create_test_files
    # Create realistic project structure
    FileUtils.mkdir_p(File.join(@env.project_dir, "src"))
    FileUtils.mkdir_p(File.join(@env.project_dir, "test"))

    File.write(File.join(@env.project_dir, "src/main.js"), "// Main application code\nconsole.log('Hello World');")
    File.write(File.join(@env.project_dir, "src/utils.js"), "// Utility functions\nexport function helper() { return true; }")
    File.write(File.join(@env.project_dir, "test/main.test.js"), "// Test file\ndescribe('Main', () => { it('should work', () => { expect(true).toBe(true); }); });")
    File.write(File.join(@env.project_dir, "package.json"), "{\n  \"name\": \"test-app\",\n  \"scripts\": { \"test\": \"jest\", \"lint\": \"eslint src/\" },\n  \"devDependencies\": { \"jest\": \"^29.0.0\", \"eslint\": \"^8.0.0\" }\n}")
    File.write(File.join(@env.project_dir, "README.md"), "# Test Application\n\nThis is a test application for section workflow integration testing.")

    # Initialize git repo for diffs
    Dir.chdir(@env.project_dir) do
      system("git init -q")
      system("git config user.email 'test@example.com'")
      system("git config user.name 'Test User'")
      system("git add .")
      system("git commit -m 'Initial commit' -q")

      # Make some changes for diff testing
      File.write(File.join(@env.project_dir, "src/main.js"), "// Updated main application code\nconsole.log('Updated Hello World');")
      system("git add .")
      system("git commit -m 'Update main.js' -q")
    end
  end
end