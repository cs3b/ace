# frozen_string_literal: true

require_relative "../molecules/idea_loader"
require_relative "../molecules/sort_value_calculator"
require_relative "../atoms/yaml_parser"

module Ace
  module Taskflow
    module Organisms
      # Manages idea rescheduling with sort-based positioning
      class IdeaScheduler
        def initialize(root_path = nil)
          @root_path = root_path || Molecules::ConfigLoader.find_root
          @idea_loader = Molecules::IdeaLoader.new(@root_path)
          @sort_calculator = Molecules::SortValueCalculator.new
        end

        # Reschedule an idea with new position
        # @param reference [String] Idea reference (partial name)
        # @param options [Hash] Rescheduling options
        # @option options [Boolean] :add_next Place before other pending ideas
        # @option options [Boolean] :add_at_end Place after all ideas
        # @option options [String] :after Place after specific idea reference
        # @option options [String] :before Place before specific idea reference
        # @return [Hash] Result with :success and :message
        def reschedule(reference, options = {})
          # Find the idea
          idea = @idea_loader.find_by_partial_name(reference, context: "current")
          unless idea
            return { success: false, message: "Idea '#{reference}' not found" }
          end

          # Load all ideas to calculate new sort position
          all_ideas = @idea_loader.load_all(context: "current")

          # Filter to only pending ideas for positioning
          pending_ideas = all_ideas.select { |i| i[:status] != "done" }

          # Calculate new sort value based on options
          new_sort = calculate_new_sort_value(idea, pending_ideas, options)

          # Update the idea file with new sort value
          if update_idea_sort(idea[:path], new_sort)
            {
              success: true,
              message: "Idea '#{reference}' rescheduled successfully (sort: #{new_sort})"
            }
          else
            { success: false, message: "Failed to update idea sort value" }
          end
        end

        private

        def calculate_new_sort_value(idea, ideas, options)
          # Remove the idea itself from the list for positioning
          other_ideas = ideas.reject { |i| i[:path] == idea[:path] }

          if options[:add_next]
            @sort_calculator.calculate_first_position(other_ideas)
          elsif options[:add_at_end]
            @sort_calculator.calculate_last_position(other_ideas)
          elsif options[:after]
            after_idea = @idea_loader.find_by_partial_name(options[:after], context: "current")
            return idea[:sort] || 50.0 unless after_idea
            @sort_calculator.calculate_after_position(other_ideas, after_idea)
          elsif options[:before]
            before_idea = @idea_loader.find_by_partial_name(options[:before], context: "current")
            return idea[:sort] || 50.0 unless before_idea
            @sort_calculator.calculate_before_position(other_ideas, before_idea)
          else
            # Default: keep current position
            idea[:sort] || 50.0
          end
        end

        def update_idea_sort(idea_path, new_sort)
          return false unless File.exist?(idea_path)

          content = File.read(idea_path)
          parsed = Atoms::YamlParser.parse(content)

          frontmatter = parsed[:frontmatter]
          body = parsed[:content]

          # Update sort value
          frontmatter["sort"] = new_sort

          # Reconstruct file content
          yaml_lines = []
          frontmatter.each do |key, value|
            if value.is_a?(Array)
              yaml_lines << "#{key}: [#{value.join(", ")}]"
            elsif value.is_a?(String) && value.include?("\n")
              # Multi-line string
              yaml_lines << "#{key}: |"
              value.lines.each { |line| yaml_lines << "  #{line.chomp}" }
            else
              yaml_lines << "#{key}: #{value}"
            end
          end

          new_content = "---\n#{yaml_lines.join("\n")}\n---\n\n#{body}"
          File.write(idea_path, new_content)
          true
        rescue StandardError => e
          false
        end
      end
    end
  end
end