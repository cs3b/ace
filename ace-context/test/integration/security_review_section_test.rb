# frozen_string_literal: true

require_relative "../test_helper"

class SecurityReviewSectionTest < AceTestCase
  def setup
    @env = Ace::TestSupport::TestEnvironment.new("security_review")
    @env.setup
    create_security_presets
    create_test_files
  end

  def teardown
    @env.teardown
  end

  def test_security_review_section_with_preset_composition
    Dir.chdir(@env.project_dir) do
      # Load security review preset that uses preset-in-section functionality
      context = Ace::Context.load_preset("security-review")

      # Verify section-based structure
      refute_empty context.sections
      assert context.sections.key?(:project_context) || context.sections.key?('project_context')
      assert context.sections.key?(:security_review) || context.sections.key?('security_review')

      # Verify both sections were processed
      assert context.content.include?("Complete Project Context")
      assert context.content.include?("Security Analysis")

      # Verify preset composition worked (sections should be processed)
      assert context.content.include?("Complete Project Context")
      assert context.content.include?("Security Analysis")

      # Verify commands were processed
      assert context.commands
      assert context.commands.any?

      # Verify section content is present
      assert context.content.include?("Project context built from multiple presets")
      assert context.content.include?("Security analysis combining standard scanning tools")
    end
  end

  def test_security_review_xml_output_with_sections
    Dir.chdir(@env.project_dir) do
      # Test XML output format with security sections
      context = Ace::Context.load_preset("security-review", format: "markdown-xml")

      # Should contain multiple section content blocks
      assert context.content.include?("Complete Project Context")
      assert context.content.include?("Security Analysis")

      # Should have XML-style tags for content when using markdown-xml format
      assert context.content.include?("<file path=")
      assert context.content.include?("<output command=")

      # Verify section titles and descriptions are preserved
      assert context.content.include?("Complete Project Context")
      assert context.content.include?("Project context built from multiple presets")
      assert context.content.include?("Security Analysis")
      assert context.content.include?("Security-focused review")
    end
  end

  def test_security_review_with_custom_output_modes
    Dir.chdir(@env.project_dir) do
      # Test cache output mode
      context = Ace::Context.load_preset("security-review", output: "cache")
      assert_equal "stdio", context.metadata[:output]  # Preset config overrides runtime option

      # Test file output mode
      output_file = File.join(@env.project_dir, "security-review-output.md")
      context = Ace::Context.load_preset("security-review", output: "file", output_file: output_file)

      # Write the output
      result = Ace::Context.write_output(context, output_file)
      assert result[:success]
      assert File.exist?(output_file)

      output_content = File.read(output_file)
      assert output_content.include?("Complete Project Context")
      assert output_content.include?("Security Analysis")
      assert output_content.include?("package.json")
    end
  end

  def test_security_section_error_handling_with_missing_preset
    # Create a security preset that references a non-existent preset
    FileUtils.mkdir_p(File.join(@env.project_dir, ".ace/context/presets"))
    File.write(File.join(@env.project_dir, ".ace/context/presets/invalid-security.md"), <<~PRESET
      ---
      description: "Invalid security review preset"
      context:
        params:
          output: stdio
          format: markdown-xml
        sections:
          security_analysis:
            title: "Security Analysis"
            presets:
              - "nonexistent-security-preset"  # This doesn't exist
              - "security-scanning"  # This exists
            commands:
              - "echo 'Security check'"
      ---
      Invalid security review preset
    PRESET
    )

    Dir.chdir(@env.project_dir) do
      # Should handle missing preset gracefully
      error = nil
      begin
        context = Ace::Context.load_preset("invalid-security")
      rescue => e
        error = e
      end

      # Should raise an error with helpful message
      assert error
      assert error.message.include?("nonexistent-security-preset")
    end
  end

  private

  def create_security_presets
    FileUtils.mkdir_p(File.join(@env.project_dir, ".ace/context/presets"))

    # Create the main security review preset with preset-in-section functionality
    File.write(File.join(@env.project_dir, ".ace/context/presets/security-review.md"), <<~PRESET
      ---
      description: "Complete project context using presets"
      context:
        params:
          output: stdio
          format: markdown-xml

        sections:
          project_context:
            title: "Complete Project Context"
            description: "Project context built from multiple presets"
            presets:
              - "base"
              - "development"
              - "testing"
            files:
              - "src/**/*.js"
              - "docs/**/*.md"
            content: |
              This section combines base configuration with development and testing
              setups, plus project-specific files and documentation.

          security_review:
            title: "Security Analysis"
            description: "Security-focused review"
            presets:
              - "security-scanning"
              - "dependency-audit"
            commands:
              - "custom-security-script.sh"
            content: |
              Security analysis combining standard scanning tools with custom validation.
      ---
      # Security Review Preset

      This preset demonstrates preset-in-section functionality for comprehensive
      security analysis, combining multiple security-focused presets with custom
      validation scripts.
    PRESET
    )

    # Create base presets referenced in sections
    File.write(File.join(@env.project_dir, ".ace/context/presets/base.md"), <<~PRESET
      ---
      description: "Base configuration preset"
      context:
        files:
          - "package.json"
          - "README.md"
        exclude:
          - "**/node_modules/**"
      ---
      Base configuration preset
    PRESET
    )

    File.write(File.join(@env.project_dir, ".ace/context/presets/development.md"), <<~PRESET
      ---
      description: "Development configuration preset"
      context:
        files:
          - "src/**/*.js"
          - "config/**/*.js"
        commands:
          - "npm run lint"
      ---
      Development configuration preset
    PRESET
    )

    File.write(File.join(@env.project_dir, ".ace/context/presets/testing.md"), <<~PRESET
      ---
      description: "Testing configuration preset"
      context:
        files:
          - "test/**/*.js"
          - "test/**/*.json"
        commands:
          - "npm test"
      ---
      Testing configuration preset
    PRESET
    )

    File.write(File.join(@env.project_dir, ".ace/context/presets/security-scanning.md"), <<~PRESET
      ---
      description: "Security scanning preset"
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

    File.write(File.join(@env.project_dir, ".ace/context/presets/dependency-audit.md"), <<~PRESET
      ---
      description: "Dependency audit preset"
      context:
        commands:
          - "npm ls --depth=0"
          - "npm outdated"
        files:
          - "package*.json"
          - "yarn.lock"
          - "package-lock.json"
      ---
      Dependency audit preset
    PRESET
    )
  end

  def create_test_files
    # Create realistic project structure
    FileUtils.mkdir_p(File.join(@env.project_dir, "src"))
    FileUtils.mkdir_p(File.join(@env.project_dir, "test"))
    FileUtils.mkdir_p(File.join(@env.project_dir, "config"))
    FileUtils.mkdir_p(File.join(@env.project_dir, "docs"))

    File.write(File.join(@env.project_dir, "package.json"), "{\n  \"name\": \"secure-app\",\n  \"scripts\": { \"test\": \"jest\", \"lint\": \"eslint src/\" },\n  \"dependencies\": { \"express\": \"^4.18.0\" },\n  \"devDependencies\": { \"jest\": \"^29.0.0\", \"eslint\": \"^8.0.0\", \"snyk\": \"^1.1000.0\" }\n}")
    File.write(File.join(@env.project_dir, "package-lock.json"), "{\n  \"name\": \"secure-app\",\n  \"version\": \"1.0.0\",\n  \"lockfileVersion\": 2\n}")

    File.write(File.join(@env.project_dir, "src/server.js"), "// Main server application\nconst express = require('express');\nconst app = express();\napp.listen(3000);")
    File.write(File.join(@env.project_dir, "src/auth.js"), "// Authentication module\nfunction authenticate(token) {\n  // TODO: Implement proper authentication\n  return true;\n}")
    File.write(File.join(@env.project_dir, "test/security.test.js"), "// Security tests\ndescribe('Security', () => { it('should validate authentication', () => { expect(authenticate('valid')).toBe(true); }); });")
    File.write(File.join(@env.project_dir, "config/security.js"), "// Security configuration\nmodule.exports = {\n  jwtSecret: 'change-me-in-production',\n  sessionTimeout: 3600000\n};")
    File.write(File.join(@env.project_dir, "docs/security.md"), "# Security Guide\n\nThis document outlines security practices for the application.")

    # Create custom security script
    File.write(File.join(@env.project_dir, "custom-security-script.sh"), "#!/bin/bash\n# Custom security validation script\necho \"Running custom security checks...\"\necho \"Security analysis complete\"")
    File.chmod(0755, File.join(@env.project_dir, "custom-security-script.sh"))
  end
end