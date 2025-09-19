# frozen_string_literal: true

require "dry/cli"
require_relative "../../organisms/tool_lister"

module CodingAgentTools
  module Cli
    module Commands
      # All command for listing available tools
      # Provides comprehensive discovery of all CLI tools with categorization
      class All < Dry::CLI::Command
        desc "List all available coding agent tools with descriptions and categories"

        option :format, type: :string, values: ["table", "json", "plain", "names"], default: "table",
          desc: "Output format (table, json, plain, names)"

        option :category, type: :string,
          desc: "Show tools from specific category only"

        option :no_descriptions, type: :boolean, default: false,
          desc: "Hide tool descriptions (faster output)"

        option :no_categories, type: :boolean, default: false,
          desc: "Don't group tools by category"

        example [
          "",
          "--format json",
          "--category 'Git Operations'",
          "--format names",
          "--no-descriptions",
          "--no-categories"
        ]

        def call(format: nil, category: nil, no_descriptions: false, no_categories: false, **)
          tool_lister = CodingAgentTools::Organisms::ToolLister.new

          # Handle names format separately for efficiency
          if format == "names"
            tool_names = tool_lister.list_tool_names
            puts tool_names.join("\n")
            return
          end

          # Get tool data
          list_options = {
            categorized: !no_categories,
            descriptions: !no_descriptions
          }

          tool_data = tool_lister.list_all_tools(list_options)

          # Filter by category if specified
          if category && tool_data[:categories]
            unless tool_data[:categories].key?(category)
              available_categories = tool_data[:categories].keys.join(", ")
              puts "Error: Category '#{category}' not found."
              puts "Available categories: #{available_categories}"
              return 1
            end

            # Convert to single category format
            category_data = tool_data[:categories][category]
            tool_data = {
              categories: {category => category_data},
              total: category_data[:count]
            }
          end

          # Output based on format
          case format
          when "json"
            output_json(tool_data)
          when "plain"
            output_plain(tool_data)
          else # "table" (default)
            output_table(tool_data)
          end

          0
        rescue CodingAgentTools::Error => e
          puts "Error: #{e.message}"
          1
        rescue => e
          puts "Unexpected error: #{e.message}"
          puts "Use --debug flag for more information" if respond_to?(:debug_enabled) && !debug_enabled
          1
        end

        private

        def output_table(tool_data)
          if tool_data[:categories]
            output_categorized_table(tool_data)
          else
            output_simple_table(tool_data)
          end
        end

        def output_categorized_table(tool_data)
          puts "Available Coding Agent Tools:\n\n"

          tool_data[:categories].each do |category_name, category_data|
            puts "#{category_name}:"
            puts "  #{category_data[:description]}" if category_data[:description]
            puts

            category_data[:tools].each do |tool|
              name_part = "  #{tool[:name]}"
              if tool[:description]
                # Align descriptions
                puts "#{name_part.ljust(28)} - #{tool[:description]}"
              else
                puts name_part
              end
            end
            puts
          end

          puts "Total: #{tool_data[:total]} tools available"
        end

        def output_simple_table(tool_data)
          puts "Available Coding Agent Tools:\n\n"

          tool_data[:tools].each do |tool|
            name_part = tool[:name]
            if tool[:description]
              puts "#{name_part.ljust(24)} - #{tool[:description]}"
            else
              puts name_part
            end
          end

          puts "\nTotal: #{tool_data[:total]} tools available"
        end

        def output_json(tool_data)
          require "json"
          puts JSON.pretty_generate(tool_data)
        end

        def output_plain(tool_data)
          if tool_data[:categories]
            tool_data[:categories].each do |category_name, category_data|
              puts "=== #{category_name} ==="
              category_data[:tools].each do |tool|
                if tool[:description]
                  puts "#{tool[:name]}: #{tool[:description]}"
                else
                  puts tool[:name]
                end
              end
              puts
            end
          else
            tool_data[:tools].each do |tool|
              if tool[:description]
                puts "#{tool[:name]}: #{tool[:description]}"
              else
                puts tool[:name]
              end
            end
          end

          puts "Total: #{tool_data[:total]} tools"
        end
      end
    end
  end
end
