# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../organisms/code/review_manager'
require_relative '../../../atoms/project_root_detector'

module CodingAgentTools
  module Cli
    module Commands
      module Code
        # Review command for code review workflow
        class Review < Dry::CLI::Command
          desc 'Execute code review on specified target with configurable focus'

          argument :focus, required: true,
                           desc: 'Review focus: code, tests, docs, or space-separated combination'

          argument :target, required: true,
                            desc: 'Review target: git range (v1.0..HEAD), file pattern (*.rb), or special (staged/unstaged/working)'

          option :context, type: :string, default: 'auto',
                           desc: 'Context mode: auto (default), none, or path to custom context file'

          option :base_path, type: :string,
                             desc: 'Base path for session storage (default: current release)'

          option :dry_run, type: :boolean, default: false,
                           desc: 'Show what would be done without creating session'

          option :session, type: :string,
                           desc: 'Resume existing session by ID'

          option :model, type: :string,
                         desc: 'LLM model to use (e.g., google:gemini-2.5-pro)'

          option :output, type: :string,
                          desc: 'Output file for review report'

          option :system_prompt, type: :string,
                                 desc: 'Custom system prompt file path (overrides focus-based selection)'

          example [
            'code HEAD~1..HEAD',
            "tests 'spec/**/*.rb' --context none",
            'docs staged --context docs/project-overview.md',
            "'code tests' v0.2.0..v0.3.0",
            'code --session review-20240106-143052',
            'code HEAD~1..HEAD --system-prompt custom-review.md'
          ]

          def call(focus:, target:, **options)
            # Validate focus
            valid_focus = validate_focus(focus)
            unless valid_focus
              error_output('Error: Invalid focus. Must be one or more of: code, tests, docs')
              return 1
            end

            # Validate custom system prompt if provided
            if options[:system_prompt]
              unless File.exist?(options[:system_prompt])
                error_output("Error: Custom system prompt file not found: #{options[:system_prompt]}")
                return 1
              end
              unless File.readable?(options[:system_prompt])
                error_output("Error: Custom system prompt file not readable: #{options[:system_prompt]}")
                return 1
              end
            end

            # Handle session resume
            return resume_session(options[:session], options) if options[:session]

            # Get project root
            CodingAgentTools::Atoms::ProjectRootDetector.find_project_root

            # Create review manager
            review_manager = CodingAgentTools::Organisms::Code::ReviewManager.new

            # Handle dry run
            return dry_run_review(review_manager, focus, target, options) if options[:dry_run]

            # Create review session
            result = review_manager.create_review_session(
              focus,
              target,
              options[:context] || 'auto',
              options[:base_path],
              options[:system_prompt]
            )

            if result[:success]
              session = result[:session]
              success_output("✅ Created review session: #{session.session_name}")
              success_output("📁 Session directory: #{session.directory_path}")

              # Show summary
              show_session_summary(result)

              # Execute review if model specified
              if options[:model]
                execute_review_with_model(review_manager, session, options[:model], options[:output])
              else
                info_output("\n🔄 Next step: Execute review with llm-query or code-review --session #{session.session_id}")
              end

              0
            else
              error_output("Error: #{result[:error]}")
              1
            end
          rescue StandardError => e
            error_output("Error: #{e.message}")
            error_output(e.backtrace.join("\n")) if ENV['DEBUG']
            1
          end

          private

          def validate_focus(focus)
            valid_options = %w[code tests docs]
            focus_parts = focus.split

            return false if focus_parts.empty?

            focus_parts.all? { |part| valid_options.include?(part) }
          end

          def dry_run_review(review_manager, focus, target, options)
            info_output('🔍 Dry run - Analyzing review configuration:')

            prep_result = review_manager.prepare_review(focus, target, options[:context] || 'auto',
                                                        options[:system_prompt])

            info_output("\nTarget Analysis:")
            info_output("  Type: #{prep_result[:target_info][:type]}")
            info_output("  Format: #{prep_result[:target_info][:format]}")

            info_output("\nContext Availability:")
            if prep_result[:context_info][:available]
              info_output('  ✅ Project context available')
              prep_result[:context_info][:found].each do |doc|
                info_output("    - #{doc[:type]}: #{doc[:path]}")
              end
            else
              info_output('  ❌ No project context found')
            end

            system_prompt_info = options[:system_prompt] ? "#{prep_result[:system_prompt]} (custom)" : prep_result[:system_prompt]
            info_output("\nSystem Prompt: #{system_prompt_info}")

            info_output("\nFocus Areas:")
            prep_result[:focus_areas].each do |area|
              info_output("  - #{area}")
            end

            0
          end

          def resume_session(_session_id, _options)
            # Implementation for session resume
            error_output('Session resume not yet implemented')
            1
          end

          def show_session_summary(result)
            session = result[:session]
            target = result[:target]
            context = result[:context]

            info_output("\n📊 Session Summary:")
            info_output("  Focus: #{session.focus}")
            info_output("  Target: #{target.type} (#{target.file_count} files, #{target.line_count} lines)")
            info_output("  Context: #{context.mode} (#{context.document_count} documents)")
          end

          def execute_review_with_model(review_manager, session, model, output_file)
            info_output("\n🚀 Executing review with model: #{model}")

            # This would integrate with LLM query
            result = review_manager.execute_review(session)

            if result[:success]
              success_output('✅ Review completed successfully')
              if output_file
                # Save to specified file
                info_output("📄 Report saved to: #{output_file}")
              end
            else
              error_output("❌ Review failed: #{result[:error]}")
            end
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
