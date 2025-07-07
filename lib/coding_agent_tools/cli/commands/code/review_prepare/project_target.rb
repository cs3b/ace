# frozen_string_literal: true

require "dry/cli"
require_relative "../../../../organisms/code/content_extractor"

module CodingAgentTools
  module Cli
    module Commands
      module Code
        module ReviewPrepare
          # ProjectTarget sub-command
          class ProjectTarget < Dry::CLI::Command
            desc "Extract target content (diff or files)"

            option :target, type: :string, required: true,
              desc: "Target specification"

            option :session_dir, type: :string, required: true,
              desc: "Session directory path"

            example [
              "--target HEAD~1..HEAD --session_dir /path/to/session",
              "--target 'lib/**/*.rb' --session_dir /path/to/session",
              "--target staged --session_dir /path/to/session"
            ]

            def call(**options)
              content_extractor = CodingAgentTools::Organisms::Code::ContentExtractor.new
              
              begin
                target = content_extractor.extract_and_save(
                  options[:target],
                  options[:session_dir]
                )
                
                if target.type != "error"
                  puts "✅ Extracted target: #{target.type}"
                  puts "📄 Content type: #{target.content_type}"
                  puts "📊 Files: #{target.file_count}, Lines: #{target.line_count}"
                  0
                else
                  warn "Error: #{target.size_info[:error]}"
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