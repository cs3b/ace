# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # CommandTemplateRenderer generates Claude command content from templates
    # This is a molecule - it performs template rendering operations
    class CommandTemplateRenderer
      # Default template for workflow commands
      DEFAULT_TEMPLATE = <<~TEMPLATE
        read whole file and follow @dev-handbook/workflow-instructions/%{filename}

        read and run @.claude/commands/commit.md
      TEMPLATE

      # Custom templates for specific workflows
      CUSTOM_TEMPLATES = {
        "commit" => <<~TEMPLATE,
          Read the entire file: @dev-handbook/workflow-instructions/commit.wf.md

          Follow the instructions exactly, including creating the git commit with the specific format shown.
        TEMPLATE
        "load-project-context" => <<~TEMPLATE
          Read the entire file: @dev-handbook/workflow-instructions/load-project-context.wf.md

          Load all the context documents listed in the workflow.
        TEMPLATE
      }.freeze

      # Render command content for a workflow
      # @param workflow_name [String] Name of the workflow
      # @param workflow_filename [String] Filename of the workflow
      # @param custom_template [String, nil] Optional custom template
      # @return [String] Rendered command content
      def render(workflow_name, workflow_filename = nil, custom_template: nil)
        # Use provided custom template if available
        return custom_template if custom_template

        # Check for predefined custom template
        if CUSTOM_TEMPLATES.key?(workflow_name)
          return CUSTOM_TEMPLATES[workflow_name]
        end

        # Use default template with filename substitution
        filename = workflow_filename || "#{workflow_name}.wf.md"
        DEFAULT_TEMPLATE % {filename: filename}
      end

      # Render with variable substitution
      # @param template [String] Template with placeholders
      # @param variables [Hash] Variables to substitute
      # @return [String] Rendered content
      def render_with_variables(template, variables = {})
        result = template.dup

        variables.each do |key, value|
          placeholder = "%{#{key}}"
          result.gsub!(placeholder, value.to_s)
        end

        result
      end

      # Get list of available custom templates
      # @return [Array<String>] List of workflow names with custom templates
      def available_custom_templates
        CUSTOM_TEMPLATES.keys
      end

      # Check if a workflow has a custom template
      # @param workflow_name [String] Name of the workflow
      # @return [Boolean] true if custom template exists
      def has_custom_template?(workflow_name)
        CUSTOM_TEMPLATES.key?(workflow_name)
      end

      # Validate template syntax
      # @param template [String] Template to validate
      # @return [Hash] Validation result
      def validate_template(template)
        placeholders = extract_placeholders(template)

        {
          valid: true,
          placeholders: placeholders,
          warnings: check_template_warnings(template)
        }
      end

      private

      def extract_placeholders(template)
        template.scan(/%{(\w+)}/).flatten.uniq
      end

      def check_template_warnings(template)
        warnings = []

        # Check for missing @ references
        if !/@[\w\-\/]+/.match?(template)
          warnings << "Template contains no @ references to files"
        end

        # Check for very short templates
        if template.strip.lines.count < 2
          warnings << "Template is very short, consider adding more guidance"
        end

        warnings
      end
    end
  end
end
