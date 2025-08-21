# frozen_string_literal: true

require "dry/cli"
require "tempfile"
require "fileutils"
require_relative "../../../molecules/code/review_preset_manager"
require_relative "../../../molecules/code/context_integrator"
require_relative "../../../molecules/code/prompt_enhancer"
require_relative "../../../molecules/code/review_assembler"
require_relative "../../../atoms/project_root_detector"
require_relative "../../../organisms/system/command_executor"

module CodingAgentTools
  module Cli
    module Commands
      module Code
        # Simplified review command with preset-based configuration
        class Review < Dry::CLI::Command
          desc "Execute code review using presets or custom configuration"

          option :preset, type: :string,
            desc: "Review preset from code-review.yml"

          option :context, type: :string,
            desc: "Background information (docs, architecture) - preset name or YAML"

          option :subject, type: :string,
            desc: "What to review (diffs, files, commits) - YAML or git range"

          option :system_prompt, type: :string,
            desc: "System prompt file path (overrides preset)"

          option :model, type: :string,
            desc: "LLM model to use (e.g., google:gemini-2.0-flash-exp)"

          option :output, type: :string,
            desc: "Output file for review report"

          option :list_presets, type: :boolean, default: false,
            desc: "List available review presets"

          option :dry_run, type: :boolean, default: false,
            desc: "Show what would be done without executing"

          option :debug, type: :boolean, default: false,
            desc: "Enable debug output"

          example [
            "--preset pr --model google:gemini-2.0-flash-exp",
            "--context project --subject 'commands: [\"git diff HEAD~1\"]'",
            "--context 'files: [docs/api.md]' --subject 'files: [lib/api/**/*.rb]' --system-prompt templates/api-review.md",
            "--preset code --subject HEAD~1..HEAD --output review.md",
            "--list-presets"
          ]

          def call(**options)
            # Handle listing presets
            return list_presets if options[:list_presets]

            # Validate inputs
            validation_result = validate_inputs(options)
            return validation_result unless validation_result == 0

            # Load preset if specified
            preset_config = load_preset_config(options)
            return 1 unless preset_config

            # Merge options with preset
            final_config = merge_configurations(preset_config, options)

            # Handle dry run
            return show_dry_run(final_config) if options[:dry_run]

            # Execute the review
            execute_review(final_config, options)
          rescue => e
            error_output("Error: #{e.message}")
            error_output(e.backtrace.join("\n")) if options[:debug]
            1
          end

          private

          def list_presets
            manager = CodingAgentTools::Molecules::Code::ReviewPresetManager.new
            presets = manager.available_presets

            if presets.empty?
              info_output("No presets found. Create .coding-agent/code-review.yml to define presets.")
              info_output("\nRun 'install-dotfiles' to get a sample configuration file.")
            else
              info_output("Available review presets:")
              presets.each do |name|
                preset = manager.load_preset(name)
                desc = preset["description"] if preset
                info_output("  #{name}: #{desc || '(no description)'}")
              end
            end

            0
          end

          def validate_inputs(options)
            # Must have either preset or both context and subject
            if !options[:preset] && !options[:context] && !options[:subject]
              error_output("Error: Must specify either --preset or both --context and --subject")
              error_output("\nUse --list-presets to see available presets")
              return 1
            end

            # Validate system prompt file if provided
            if options[:system_prompt] && !File.exist?(options[:system_prompt])
              error_output("Error: System prompt file not found: #{options[:system_prompt]}")
              return 1
            end

            0
          end

          def load_preset_config(options)
            manager = CodingAgentTools::Molecules::Code::ReviewPresetManager.new

            if options[:preset]
              unless manager.preset_exists?(options[:preset])
                error_output("Error: Preset '#{options[:preset]}' not found")
                error_output("\nAvailable presets: #{manager.available_presets.join(', ')}")
                return nil
              end

              manager.resolve_preset(options[:preset], options)
            else
              # Build config from individual options
              {
                context: options[:context],
                subject: options[:subject],
                system_prompt: options[:system_prompt],
                model: options[:model] || manager.default_model || "google:gemini-2.0-flash-exp"
              }
            end
          end

          def merge_configurations(preset_config, options)
            {
              context: options[:context] || preset_config[:context],
              subject: options[:subject] || preset_config[:subject],
              system_prompt: options[:system_prompt] || preset_config[:system_prompt],
              model: options[:model] || preset_config[:model],
              output: options[:output]
            }
          end

          def show_dry_run(config)
            info_output("🔍 Dry run - Review configuration:")
            info_output("\nContext (background information):")
            info_output("  #{format_config_value(config[:context])}")
            info_output("\nSubject (what to review):")
            info_output("  #{format_config_value(config[:subject])}")
            info_output("\nSystem prompt:")
            info_output("  #{config[:system_prompt] || '(default review prompt)'}")
            info_output("\nModel:")
            info_output("  #{config[:model]}")
            info_output("\nOutput:")
            info_output("  #{config[:output] || '(stdout)'}")

            0
          end

          def format_config_value(value)
            case value
            when String
              value
            when Hash
              value.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
            when nil
              "(not specified)"
            else
              value.inspect
            end
          end

          def execute_review(config, options)
            debug_output("Starting review execution...", options[:debug])

            # Initialize components
            context_integrator = CodingAgentTools::Molecules::Code::ContextIntegrator.new
            prompt_enhancer = CodingAgentTools::Molecules::Code::PromptEnhancer.new
            review_assembler = CodingAgentTools::Molecules::Code::ReviewAssembler.new

            # Step 1: Generate context (background information)
            debug_output("Generating context...", options[:debug])
            context_content = context_integrator.generate_context(config[:context])
            
            # Step 2: Load and enhance system prompt with context
            debug_output("Enhancing system prompt...", options[:debug])
            system_prompt = load_system_prompt(config[:system_prompt])
            enhanced_prompt = prompt_enhancer.enhance_prompt(system_prompt, context_content)

            # Step 3: Generate subject (what to review)
            debug_output("Generating subject...", options[:debug])
            subject_content = context_integrator.generate_subject(config[:subject])

            # Step 4: Assemble final review prompt
            debug_output("Assembling final prompt...", options[:debug])
            final_prompt = review_assembler.assemble(enhanced_prompt, subject_content)

            # Step 5: Send to LLM
            debug_output("Sending to LLM...", options[:debug])
            review_result = send_to_llm(final_prompt, config[:model])

            # Step 6: Handle output
            handle_output(review_result, config[:output])

            success_output("✅ Review completed successfully")
            0
          rescue => e
            error_output("Error during review: #{e.message}")
            debug_output(e.backtrace.join("\n"), options[:debug])
            1
          end

          def load_system_prompt(prompt_path)
            return nil unless prompt_path
            
            if File.exist?(prompt_path)
              File.read(prompt_path)
            else
              # Try with project root
              project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
              full_path = File.join(project_root, prompt_path)
              File.exist?(full_path) ? File.read(full_path) : nil
            end
          end

          def send_to_llm(prompt, model)
            # Create temporary file with prompt
            Tempfile.create(["review-prompt-", ".md"]) do |tmpfile|
              tmpfile.write(prompt)
              tmpfile.flush

              # Execute llm-query command
              executor = CodingAgentTools::Organisms::System::CommandExecutor.new
              result = executor.execute("llm-query", model, "--file", tmpfile.path)

              if result.success?
                result.stdout
              else
                raise "LLM query failed: #{result.stderr}"
              end
            end
          end

          def handle_output(content, output_file)
            if output_file
              File.write(output_file, content)
              info_output("📄 Review saved to: #{output_file}")
            else
              puts content
            end
          end

          def debug_output(message, enabled)
            puts "[DEBUG] #{message}" if enabled
          end

          def success_output(message)
            puts message
          end

          def error_output(message)
            $stderr.write("#{message}\n")
          end

          def info_output(message)
            puts message
          end
        end
      end
    end
  end
end