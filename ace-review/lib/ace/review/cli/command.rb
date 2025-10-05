# frozen_string_literal: true

require "dry/cli"
require "tty-spinner"
require "tty-table"
require "rainbow"

module Ace
  module Review
    module CLI
      # Main review command
      class Command < Dry::CLI::Command
        desc "Execute review using presets or custom configuration"

          option :preset, type: :string, default: "pr",
                          desc: "Review preset from configuration"

          option :output_dir, type: :string,
                              desc: "Custom output directory for review"

          option :output, type: :string,
                          desc: "Specific output file path"

          option :context, type: :string,
                           desc: "Context configuration (preset name or YAML)"

          option :subject, type: :string,
                           desc: "Subject configuration (git range or YAML)"

          option :prompt_base, type: :string,
                               desc: "Base prompt module"

          option :prompt_format, type: :string,
                                 desc: "Format module"

          option :prompt_focus, type: :string,
                                desc: "Focus modules (comma-separated)"

          option :add_focus, type: :string,
                             desc: "Add focus modules to preset"

          option :prompt_guidelines, type: :string,
                                     desc: "Guideline modules (comma-separated)"

          option :model, type: :string,
                         desc: "LLM model to use"

          option :list_presets, type: :boolean, default: false,
                                desc: "List available presets"

          option :list_prompts, type: :boolean, default: false,
                                desc: "List available prompt modules"

          option :dry_run, type: :boolean, default: false,
                           desc: "Prepare review without executing"

          option :verbose, type: :boolean, default: false,
                           desc: "Verbose output"

          option :auto_execute, type: :boolean, default: false,
                                desc: "Execute LLM query automatically"

          option :save_session, type: :boolean, default: true,
                                desc: "Save session files"

          option :session_dir, type: :string,
                               desc: "Custom session directory"

          example [
            "--preset pr",
            "--preset security --auto-execute",
            "--preset docs --output-dir ./reviews",
            "--list-presets",
            "--list-prompts"
          ]

          def call(**options)
            # Handle list commands
            return list_presets if options[:list_presets]
            return list_prompts if options[:list_prompts]

            # Execute review
            execute_review(options)
          end

          private

          def list_presets
            require_relative "../../organisms/review_manager"
            manager = Organisms::ReviewManager.new

            presets = manager.list_presets
            if presets.empty?
              puts Rainbow("No presets found").yellow
              puts "Create presets in .ace/review/code.yml or .ace/review/presets/"
              return
            end

            puts Rainbow("Available Review Presets:").cyan.bright
            puts

            table = TTY::Table.new(
              header: [
                Rainbow("Preset").cyan,
                Rainbow("Description").cyan,
                Rainbow("Source").cyan
              ]
            )

            # Load preset manager to get descriptions
            preset_manager = Molecules::PresetManager.new

            presets.each do |name|
              preset = preset_manager.load_preset(name)
              description = preset&.dig("description") || "-"

              # Determine source
              source = if preset_manager.send(:load_preset_from_file, name)
                         "file"
                       elsif preset_manager.send(:load_preset_from_config, name)
                         "config"
                       else
                         "default"
                       end

              table << [name, description, source]
            end

            puts table.render(:unicode, padding: [0, 1])
          end

          def list_prompts
            require_relative "../../organisms/review_manager"
            manager = Organisms::ReviewManager.new

            prompts = manager.list_prompts
            if prompts.empty?
              puts Rainbow("No prompt modules found").yellow
              return
            end

            puts Rainbow("Available Prompt Modules:").cyan.bright
            puts

            prompts.each do |category, items|
              puts Rainbow("  #{category}/").green
              format_prompt_items(items, "    ")
            end
          end

          def format_prompt_items(items, indent)
            case items
            when Hash
              items.each do |name, value|
                if value.is_a?(Array)
                  puts "#{indent}#{Rainbow(name).yellow}/"
                  value.each do |item|
                    source = item.is_a?(Hash) ? " (#{item[:source]})" : ""
                    item_name = item.is_a?(Hash) ? item[:name] : item
                    puts "#{indent}  #{item_name}#{Rainbow(source).dim}"
                  end
                else
                  source = value.is_a?(String) ? " (#{value})" : ""
                  puts "#{indent}#{name}#{Rainbow(source).dim}"
                end
              end
            when Array
              items.each { |item| puts "#{indent}#{item}" }
            when String
              puts "#{indent}#{items}"
            end
          end

          def execute_review(options)
            require_relative "../../organisms/review_manager"

            spinner = TTY::Spinner.new(
              "[:spinner] Analyzing code with preset '#{options[:preset]}'...",
              format: :dots
            )
            spinner.auto_spin if options[:verbose]

            manager = Organisms::ReviewManager.new
            result = manager.execute_review(options)

            spinner.stop if options[:verbose]

            if result[:success]
              handle_success(result, options)
            else
              handle_error(result)
            end
          end

          def handle_success(result, options)
            if result[:output_file]
              puts Rainbow("✓").green + " Review saved: #{result[:output_file]}"
            elsif result[:session_dir]
              puts Rainbow("✓").green + " Review session prepared: #{result[:session_dir]}"
              puts "  Prompt: #{result[:prompt_file]}"
              unless options[:dry_run]
                puts
                puts "To execute with LLM:"
                puts "  ace-llm query --file #{result[:prompt_file]}"
              end
            end
          end

          def handle_error(result)
            puts Rainbow("✗ Error:").red + " #{result[:error]}"
            exit 1
          end
        end
      end
    end
  end