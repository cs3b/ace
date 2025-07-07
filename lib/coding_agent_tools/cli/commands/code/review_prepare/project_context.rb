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
                # Create minimal session for context loading
                session = CodingAgentTools::Models::Code::ReviewSession.new(
                  session_id: "temp",
                  session_name: File.basename(options[:session_dir]),
                  timestamp: Time.now.iso8601,
                  directory_path: options[:session_dir],
                  focus: "unknown",
                  target: "unknown",
                  context_mode: options[:mode]
                )
                
                context = context_loader.load_context(options[:mode], session)
                result = context_loader.save_context(context, options[:session_dir])
                
                if result[:success]
                  puts "✅ Loaded context: #{context.mode}"
                  puts "📄 Documents: #{context.document_count}"
                  puts context_loader.get_context_summary(context)
                  0
                else
                  warn "Error: #{result[:error]}"
                  1
                end
              rescue => e
                warn "Error: #{e.message}"
                1
              end
            end
          end
        end
      end
    end
  end
end