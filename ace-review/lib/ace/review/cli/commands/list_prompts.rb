# frozen_string_literal: true

module Ace
  module Review
    module CLI
      module Commands
      # dry-cli Command class for the list-prompts command
      #
      # Lists all available prompt modules by category.
      class ListPrompts < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "List all available prompt modules by category"

        example [
          '# List all prompt modules'
        ]

        def call(**options)
          manager = Organisms::ReviewManager.new

          prompts = manager.list_prompts
          if prompts.empty?
            puts "No prompt modules found"
            return 0
          end

          puts "Available Prompt Modules:"
          puts

          prompts.each do |category, items|
            puts "  #{category}/"
            format_prompt_items(items, "    ")
          end

          0
        end

        private

        def format_prompt_items(items, indent)
          case items
          when Hash
            items.each do |name, value|
              if value.is_a?(Array)
                puts "#{indent}#{name}/"
                value.each do |item|
                  source = item.is_a?(Hash) ? " (#{item[:source]})" : ""
                  item_name = item.is_a?(Hash) ? item[:name] : item
                  puts "#{indent}  #{item_name}#{source}"
                end
              else
                source = value.is_a?(String) ? " (#{value})" : ""
                puts "#{indent}#{name}#{source}"
              end
            end
          when Array
            items.each { |item| puts "#{indent}#{item}" }
          when String
            puts "#{indent}#{items}"
          end
        end
      end
    end
  end
end
end
