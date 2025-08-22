# frozen_string_literal: true

require "dry/cli"
require "tempfile"
require "fileutils"
require "open3"
require_relative "../../../molecules/code/review_preset_manager"
require_relative "../../../molecules/code/context_integrator"
require_relative "../../../molecules/code/prompt_enhancer"
require_relative "../../../molecules/code/llm_executor"
require_relative "../../../molecules/code/config_extractor"
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

          option :prompt_base, type: :string,
            desc: "Base prompt module for composition (e.g., 'system')"

          option :prompt_format, type: :string,
            desc: "Format module (standard, detailed, compact)"

          option :prompt_focus, type: :string,
            desc: "Focus modules (comma-separated, e.g., 'architecture/atom,languages/ruby')"

          option :add_focus, type: :string,
            desc: "Add focus modules to preset (comma-separated)"

          option :prompt_guidelines, type: :string,
            desc: "Guideline modules (comma-separated, e.g., 'tone,icons')"

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

          option :auto_execute, type: :boolean, default: false,
            desc: "Automatically execute LLM query after preparation"

          option :save_session, type: :boolean, default: true,
            desc: "Save session files for debugging (default: true)"

          option :session_dir, type: :string,
            desc: "Custom session directory path"

          option :config_file, type: :string,
            desc: "Path to configuration file with YAML front matter"

          example [
            "--preset pr --auto-execute",
            "--preset pr --model google:gemini-2.0-flash-exp",
            "--context project --subject 'commands: [\"git diff HEAD~1\"]' --auto-execute",
            "--context 'files: [docs/api.md]' --subject 'files: [lib/api/**/*.rb]' --system-prompt templates/api-review.md",
            "--preset code --subject HEAD~1..HEAD --output review.md --auto-execute",
            "--prompt-base system --prompt-format standard --prompt-focus 'architecture/atom,languages/ruby'",
            "--preset ruby-atom-full --add-focus 'quality/security'",
            "--preset pr --save-session --session-dir ./review-session",
            "--list-presets"
          ]

          def call(**options)
            # Handle listing presets
            return list_presets if options[:list_presets]

            # Load configuration from file if specified
            if options[:config_file]
              file_config = load_config_file(options[:config_file])
              return 1 unless file_config
              # Merge file config with command-line options
              options = file_config.merge(options)
            end

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

          def load_config_file(file_path)
            unless File.exist?(file_path)
              error_output("Error: Config file not found: #{file_path}")
              return nil
            end

            begin
              extractor = CodingAgentTools::Molecules::Code::ConfigExtractor.new
              config = extractor.extract_from_file(file_path)
              
              if config.nil?
                error_output("Error: No valid configuration found in #{file_path}")
                return nil
              end

              # Convert string keys to symbols for options
              symbolized_config = {}
              config.each do |key, value|
                symbolized_config[key.to_sym] = value
              end
              
              symbolized_config
            rescue => e
              error_output("Error loading config file: #{e.message}")
              nil
            end
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
              prompt_options = {
                prompt_base: options[:prompt_base],
                prompt_format: options[:prompt_format],
                prompt_focus: options[:prompt_focus],
                prompt_guidelines: options[:prompt_guidelines]
              }.compact
              
              prompt_composition = prompt_options.empty? ? nil : 
                                  manager.send(:resolve_prompt_composition, nil, prompt_options)
              
              {
                context: options[:context],
                subject: options[:subject],
                system_prompt: options[:system_prompt],
                prompt_composition: prompt_composition,
                model: options[:model] || manager.default_model || "google:gemini-2.0-flash-exp",
                output: options[:output]
              }
            end
          end

          def merge_configurations(preset_config, options)
            # Build prompt composition from CLI options
            prompt_options = {
              prompt_base: options[:prompt_base],
              prompt_format: options[:prompt_format],
              prompt_focus: options[:prompt_focus],
              add_focus: options[:add_focus],
              prompt_guidelines: options[:prompt_guidelines]
            }.compact
            
            # Use ReviewPresetManager to resolve composition
            manager = CodingAgentTools::Molecules::Code::ReviewPresetManager.new
            prompt_composition = manager.send(:resolve_prompt_composition, 
                                              preset_config[:prompt_composition], 
                                              prompt_options)
            
            {
              context: options[:context] || preset_config[:context],
              subject: options[:subject] || preset_config[:subject],
              system_prompt: options[:system_prompt] || preset_config[:system_prompt],
              prompt_composition: prompt_composition,
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
            if config[:prompt_composition]
              modules = []
              modules << "base: #{config[:prompt_composition]['base']}" if config[:prompt_composition]['base']
              modules << "format: #{config[:prompt_composition]['format']}" if config[:prompt_composition]['format']
              modules << "focus: #{config[:prompt_composition]['focus'].join(', ')}" if config[:prompt_composition]['focus']
              modules << "guidelines: #{config[:prompt_composition]['guidelines'].join(', ')}" if config[:prompt_composition]['guidelines']
              info_output("  (composed from modules: #{modules.join('; ')})")
            else
              info_output("  #{config[:system_prompt] || '(default review prompt)'}")
            end
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
            debug_output("Starting review preparation...", options[:debug])

            # Create session directory only if saving session
            session_dir = if options[:save_session]
              options[:session_dir] || create_session_directory
            else
              nil
            end
            debug_output("Session directory: #{session_dir || 'in-memory'}", options[:debug])

            # Initialize components
            context_integrator = CodingAgentTools::Molecules::Code::ContextIntegrator.new
            prompt_enhancer = CodingAgentTools::Molecules::Code::PromptEnhancer.new

            # Step 1: Generate context (background information)
            debug_output("Generating context...", options[:debug])
            context_content = context_integrator.generate_context(config[:context])
            
            # Save context file only if session directory exists
            if session_dir
              context_file = File.join(session_dir, "in-context.md")
              File.write(context_file, context_content)
            end
            
            # Step 2: Load or compose system prompt
            debug_output("Loading system prompt...", options[:debug])
            system_prompt = if config[:prompt_composition]
              debug_output("Composing prompt from modules...", options[:debug])
              prompt_enhancer.compose_prompt(config[:prompt_composition])
            else
              load_system_prompt(config[:system_prompt])
            end
            
            # Save base prompt only if session directory exists
            if session_dir
              base_prompt_file = File.join(session_dir, "in-system.base.prompt.md")
              File.write(base_prompt_file, system_prompt || prompt_enhancer.default_prompt)
            end
            
            # Step 3: Enhance system prompt with context
            debug_output("Enhancing system prompt with context...", options[:debug])
            enhanced_prompt = prompt_enhancer.enhance_prompt(system_prompt, context_content)
            
            # Save enhanced prompt only if session directory exists
            system_prompt_file = nil
            if session_dir
              system_prompt_file = File.join(session_dir, "in-system.prompt.md")
              File.write(system_prompt_file, enhanced_prompt)
            end

            # Step 4: Generate subject (what to review)
            debug_output("Generating subject...", options[:debug])
            subject_content = context_integrator.generate_subject(config[:subject])
            
            # Save subject file only if session directory exists
            subject_file = nil
            if session_dir
              subject_file = File.join(session_dir, "in-subject.prompt.md")
              File.write(subject_file, subject_content)
            end

            # Step 5: Execute or prepare llm-query
            model_name = config[:model].gsub(":", "-").gsub("/", "-")
            
            if options[:auto_execute]
              # Execute the LLM query directly
              debug_output("Auto-executing LLM query...", options[:debug])
              
              llm_executor = CodingAgentTools::Molecules::Code::LLMExecutor.new
              output_file = config[:output] || "cr-#{model_name}.md"
              
              begin
                # Execute with output file
                info_output("\n🤖 Executing code review with #{config[:model]}...")
                info_output("Output will be saved to: #{output_file}")
                
                result = llm_executor.execute_query(
                  config[:model],
                  subject_content,
                  enhanced_prompt,
                  output_file: output_file,
                  timeout: 600
                )
                
                success_output("\n✅ Review completed successfully!")
                info_output("📄 Review saved to: #{output_file}")
                
                # Display session info if saved
                if session_dir
                  info_output("\n📁 Session files saved in: #{session_dir}")
                end
                
                0
              rescue => e
                error_output("\nError executing LLM query: #{e.message}")
                1
              end
            else
              # Prepare command for manual execution
              output_file = config[:output] || (session_dir ? File.join(session_dir, "report-#{model_name}.md") : "review-#{model_name}.md")
              
              if session_dir
                # Traditional workflow with files
                llm_command = [
                  "llm-query #{config[:model]}",
                  subject_file,
                  "--system #{system_prompt_file}",
                  "--timeout 600",
                  "--output #{output_file}"
                ].join(" \\\n  ")
                
                success_output("✅ Review session prepared: #{session_dir}")
                info_output("\n📁 Session files:")
                info_output("  - in-context.md (project context)")
                info_output("  - in-system.base.prompt.md (base system prompt)")
                info_output("  - in-system.prompt.md (enhanced system prompt with context)")
                info_output("  - in-subject.prompt.md (content to review)")
                info_output("  - report-#{model_name}.md (will contain review output)")
                
                info_output("\n🔄 Next step - run this command:")
                info_output(llm_command)
              else
                # In-memory mode without auto-execute
                info_output("\n✅ Review prepared in memory")
                info_output("\n💡 To execute the review, use --auto-execute flag")
                info_output("   Or use --save-session to save prompts to files")
              end
              
              0
            end
          rescue => e
            error_output("Error during review preparation: #{e.message}")
            debug_output(e.backtrace.join("\n"), options[:debug])
            1
          end

          def create_session_directory
            # Find current release directory
            current_release = find_current_release_dir
            
            # Create code-review directory under current release
            review_base = File.join(current_release, "code-review")
            FileUtils.mkdir_p(review_base) unless Dir.exist?(review_base)
            
            # Create timestamped session directory
            timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
            session_name = "review-#{timestamp}"
            session_dir = File.join(review_base, session_name)
            FileUtils.mkdir_p(session_dir)
            
            session_dir
          end

          def find_current_release_dir
            # Look for dev-taskflow/current directory
            taskflow_current = "dev-taskflow/current"
            if Dir.exist?(taskflow_current)
              # Find the release directory (e.g., v.0.5.0-insights)
              release_dirs = Dir.glob(File.join(taskflow_current, "v.*")).select { |d| File.directory?(d) }
              return release_dirs.first if release_dirs.any?
            end
            
            # Fallback to temp directory if no current release
            Dir.mktmpdir("code-review-")
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

              # Execute llm-query command using Open3 directly
              stdout, stderr, status = Open3.capture3("llm-query", model, "--file", tmpfile.path)

              if status.success?
                stdout
              else
                raise "LLM query failed: #{stderr}"
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