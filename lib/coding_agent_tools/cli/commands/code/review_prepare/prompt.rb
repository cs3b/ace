# frozen_string_literal: true

require "dry/cli"
require_relative "../../../../organisms/code/prompt_builder"
require_relative "../../../../models/code/review_session"
require_relative "../../../../models/code/review_target"
require_relative "../../../../models/code/review_context"
require "time"

module CodingAgentTools
  module Cli
    module Commands
      module Code
        module ReviewPrepare
          # Prompt sub-command
          class Prompt < Dry::CLI::Command
            desc "Build combined review prompt"

            option :session_dir, type: :string, required: true,
              desc: "Session directory path"

            option :focus, type: :string, required: true,
              desc: "Review focus for prompt building"

            option :output, type: :string,
              desc: "Output file for prompt (default: prompt.md in session)"

            example [
              "--session_dir /path/to/session --focus code",
              "--session_dir /path/to/session --focus 'code tests' --output review.md"
            ]

            def call(**options)
              prompt_builder = CodingAgentTools::Organisms::Code::PromptBuilder.new

              begin
                # Load session metadata
                session = load_session_from_dir(options[:session_dir], options[:focus])

                # Detect target and context from session files
                target = detect_target_from_session(options[:session_dir])
                context = detect_context_from_session(options[:session_dir])

                # Build prompt
                prompt = prompt_builder.build_review_prompt(session, target, context)

                # Save to custom output if specified
                if options[:output]
                  File.write(options[:output], prompt.combined_content)
                  puts "✅ Prompt saved to: #{options[:output]}"
                else
                  puts "✅ Prompt saved to: #{File.join(options[:session_dir], "prompt.md")}"
                end

                puts "📊 Prompt size: #{prompt.word_count} words"
                puts "🎯 Focus areas: #{prompt.focus_areas.size}"
                0
              rescue => e
                warn "Error: #{e.message}"
                1
              end
            end

            private

            def load_session_from_dir(dir, focus)
              CodingAgentTools::Models::Code::ReviewSession.new(
                session_id: "prepare",
                session_name: File.basename(dir),
                timestamp: Time.now.iso8601,
                directory_path: dir,
                focus: focus,
                target: "unknown",
                context_mode: "auto"
              )
            end

            def detect_target_from_session(dir)
              # Check for input files
              if File.exist?(File.join(dir, "input.diff"))
                CodingAgentTools::Models::Code::ReviewTarget.new(
                  type: "git_diff",
                  target_spec: "unknown",
                  resolved_paths: [],
                  content_type: "diff",
                  size_info: {}
                )
              elsif File.exist?(File.join(dir, "input.xml"))
                CodingAgentTools::Models::Code::ReviewTarget.new(
                  type: "file_pattern",
                  target_spec: "unknown",
                  resolved_paths: [],
                  content_type: "xml",
                  size_info: {}
                )
              else
                raise "No input files found in session directory"
              end
            end

            def detect_context_from_session(dir)
              # Simple context detection
              CodingAgentTools::Models::Code::ReviewContext.new(
                mode: "auto",
                documents: [],
                loaded_at: Time.now
              )
            end
          end
        end
      end
    end
  end
end
