# frozen_string_literal: true

require "test_helper"

class WorkflowValidationTest < Minitest::Test
  WORKFLOW_DIR = File.join(__dir__, "..", "handbook", "workflow-instructions")
  REQUIRED_FIELDS = %w[name description doc-type].freeze

  def test_all_workflows_have_valid_frontmatter
    Dir.glob(File.join(WORKFLOW_DIR, "*.wf.md")).each do |file|
      assert File.exist?(file), "Workflow file exists: #{file}"

      content = File.read(file)
      assert_match(/---\s*\n(.*?)\n---/m, content, "Frontmatter missing in #{file}")

      # Extract frontmatter content
      frontmatter_match = content.match(/---\s*\n(.*?)\n---/m)
      refute_nil frontmatter_match, "Could not extract frontmatter from #{file}"

      # Parse YAML
      frontmatter = YAML.safe_load(frontmatter_match[1])
      assert_kind_of Hash, frontmatter, "Frontmatter must be a hash in #{file}"
    end
  end

  def test_all_workflows_have_required_fields
    Dir.glob(File.join(WORKFLOW_DIR, "*.wf.md")).each do |file|
      content = File.read(file)
      frontmatter_match = content.match(/---\s*\n(.*?)\n---/m)
      next if frontmatter_match.nil?

      frontmatter = YAML.safe_load(frontmatter_match[1])
      next if frontmatter.nil? || !frontmatter.is_a?(Hash)

      REQUIRED_FIELDS.each do |field|
        assert frontmatter[field], "Required field '#{field}' missing in #{file}"
        refute_empty frontmatter[field].to_s.strip, "Required field '#{field}' is empty in #{file}"
      end
    end
  end

  def test_workflow_files_have_proper_formatting
    Dir.glob(File.join(WORKFLOW_DIR, "*.wf.md")).each do |file|
      content = File.read(file)

      # Check for proper YAML delimiters
      assert content.start_with?("---"), "File must start with ---: #{file}"

      # Simple check for YAML frontmatter pattern
      frontmatter_pattern = /^---\s*\n.*?\n---\s*\n/m
      assert content.match?(frontmatter_pattern), "File must have proper YAML frontmatter delimiters: #{file}"
    end
  end
end
