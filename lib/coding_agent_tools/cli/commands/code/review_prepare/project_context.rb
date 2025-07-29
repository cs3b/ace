# frozen_string_literal: true

require "dry/cli"
require_relative "../../../../organisms/code/context_loader"
require_relative "../../../../models/code/review_session"
require "time"

module CodingAgentTools
  module Cli
    module Commands
      module Code
        module ReviewPrepare
          # ProjectContext sub-command
          class ProjectContext < Dry::CLI::Command
            desc "Extract and save project context"

            option :mode, type: :string, default: "auto",
              desc: "Context mode: auto, none, or custom file path"

            option :session_dir, type: :string, required: true,
              desc: "Session directory path"

            example [
              "--session_dir /path/to/session",
              "--mode none --session_dir /path/to/session",
              "--mode /docs/context.md --session_dir /path/to/session"
            ]

            def call(**options)
              context_loader = CodingAgentTools::Organisms::Code::ContextLoader.new

              begin
                # Check for required options (Dry::CLI doesn't validate for direct method calls)
                raise ArgumentError, "session_dir is required" unless options[:session_dir]

                # Apply default values that Dry::CLI doesn't apply for direct method calls
                mode = options[:mode] || "auto"

                # Create minimal session for context loading
                session = CodingAgentTools::Models::Code::ReviewSession.new(
                  session_id: "temp",
                  session_name: File.basename(options[:session_dir]),
                  timestamp: Time.now.iso8601,
                  directory_path: options[:session_dir],
                  focus: "unknown",
                  target: "unknown",
                  context_mode: mode
                )

                context = context_loader.load_context(mode, session)
                result = context_loader.save_context(context, options[:session_dir])

                if result[:success]
                  puts "✅ Loaded context: #{context.mode}"
                  puts "📄 Documents: #{context.document_count}"
                  puts context_loader.get_context_summary(context)
                  0
                else
                  $stderr.write("Error: #{result[:error]}\n")
                  1
                end
              rescue => e
                $stderr.write("Error: #{e.message}\n")
                1
              end
            end
          end
        end
      end
    end
  end
end
