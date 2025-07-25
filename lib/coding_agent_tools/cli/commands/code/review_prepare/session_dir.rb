# frozen_string_literal: true

require "dry/cli"
require_relative "../../../../organisms/code/session_manager"

module CodingAgentTools
  module Cli
    module Commands
      module Code
        module ReviewPrepare
          # SessionDir sub-command
          class SessionDir < Dry::CLI::Command
            desc "Create session directory structure"

            option :focus, type: :string, required: true,
              desc: "Review focus: code, tests, docs, or combination"

            option :target, type: :string, required: true,
              desc: "Review target specification"

            option :base_path, type: :string,
              desc: "Base path for session storage"

            example [
              "--focus code --target HEAD~1..HEAD",
              "--focus 'code tests' --target 'lib/**/*.rb'"
            ]

            def call(**options)
              # Check for required options (Dry::CLI doesn't validate for direct method calls)
              raise ArgumentError, "focus is required" unless options[:focus]
              raise ArgumentError, "target is required" unless options[:target]

              session_manager = CodingAgentTools::Organisms::Code::SessionManager.new

              begin
                session = session_manager.create_session(
                  focus: options[:focus],
                  target: options[:target],
                  context_mode: "auto",
                  base_path: options[:base_path]
                )

                puts "✅ Created session directory: #{session.directory_path}"
                puts "📁 Session ID: #{session.session_id}"
                0
              rescue => e
                $stderr.write "Error: #{e.message}\n"
                1
              end
            end
          end
        end
      end
    end
  end
end
