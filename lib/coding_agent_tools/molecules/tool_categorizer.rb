# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # ToolCategorizer - Molecule for categorizing tools by function
    #
    # Responsibilities:
    # - Categorize tools based on name patterns and functionality
    # - Group tools into logical categories
    # - Provide category metadata and descriptions
    class ToolCategorizer
      CATEGORIES = {
        "LLM Integration" => {
          description: "Tools for interacting with language models and AI providers",
          patterns: ["llm-*"],
          tools: []
        },
        "Git Operations" => {
          description: "Enhanced git commands with multi-repo support",
          patterns: ["git-*"],
          tools: []
        },
        "Task Management" => {
          description: "Project task management and navigation tools",
          patterns: ["task-*", "release-*"],
          tools: []
        },
        "Navigation" => {
          description: "File system navigation and project exploration tools",
          patterns: ["nav-*"],
          tools: []
        },
        "Code Review" => {
          description: "Code review and analysis tools",
          patterns: ["code-review*"],
          tools: []
        },
        "Code Quality" => {
          description: "Code linting, formatting, and quality tools",
          patterns: ["code-lint*"],
          tools: []
        },
        "Documentation" => {
          description: "Documentation management and handbook tools",
          patterns: ["handbook*"],
          tools: []
        },
        "Reflection & Analysis" => {
          description: "Session reflection and analysis tools",
          patterns: ["reflection-*"],
          tools: []
        },
        "Development Tools" => {
          description: "General development and automation tools",
          patterns: [],
          tools: []
        }
      }.freeze

      def initialize
        @categories = deep_copy_categories
      end

      # Categorizes a list of tools into functional groups
      #
      # @param tools [Array<Hash>] Array of tool metadata hashes
      # @return [Hash] Categorized tools with metadata
      def categorize_tools(tools)
        # Reset category tools
        @categories.each { |_, category| category[:tools] = [] }

        # Categorize each tool
        tools.each do |tool|
          category_name = determine_category(tool)
          @categories[category_name][:tools] << tool
        end

        # Remove empty categories and sort tools within categories
        result = {}
        @categories.each do |name, category|
          next if category[:tools].empty?

          result[name] = {
            description: category[:description],
            tools: category[:tools].sort_by { |tool| tool[:name] },
            count: category[:tools].length
          }
        end

        result
      end

      private

      def determine_category(tool)
        tool_name = tool[:name]

        # Check each category's patterns
        @categories.each do |category_name, category_data|
          category_data[:patterns].each do |pattern|
            if pattern.include?("*")
              # Convert shell glob to regex
              regex_pattern = pattern.gsub("*", ".*")
              return category_name if tool_name.match?(/^#{regex_pattern}$/)
            else
              return category_name if tool_name == pattern
            end
          end
        end

        # Special case matching for tools that don't fit standard patterns
        case tool_name
        when "handbook"
          "Documentation"
        when /^code-/
          if tool_name.include?("review")
            "Code Review"
          elsif tool_name.include?("lint")
            "Code Quality"
          else
            "Development Tools"
          end
        else
          "Development Tools"
        end
      end

      def deep_copy_categories
        CATEGORIES.each_with_object({}) do |(key, value), result|
          result[key] = {
            description: value[:description],
            patterns: value[:patterns].dup,
            tools: []
          }
        end
      end
    end
  end
end