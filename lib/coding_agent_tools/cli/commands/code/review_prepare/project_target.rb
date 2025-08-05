# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../../organisms/code/content_extractor'

module CodingAgentTools
  module Cli
    module Commands
      module Code
        module ReviewPrepare
          # ProjectTarget sub-command
          class ProjectTarget < Dry::CLI::Command
            desc 'Extract target content (diff or files)'

            option :target, type: :string, required: true,
              desc: 'Target specification'

            option :session_dir, type: :string, required: true,
              desc: 'Session directory path'

            example [
              '--target HEAD~1..HEAD --session_dir /path/to/session',
              "--target 'lib/**/*.rb' --session_dir /path/to/session",
              '--target staged --session_dir /path/to/session'
            ]

            def call(**options)
              # Check for required options (Dry::CLI doesn't validate for direct method calls)
              raise ArgumentError, 'target is required' unless options[:target]
              raise ArgumentError, 'session_dir is required' unless options[:session_dir]

              content_extractor = CodingAgentTools::Organisms::Code::ContentExtractor.new

              begin
                target = content_extractor.extract_and_save(
                  options[:target],
                  options[:session_dir]
                )

                if target.type != 'error'
                  puts "✅ Extracted target: #{target.type}"
                  puts "📄 Content type: #{target.content_type}"
                  puts "📊 Files: #{target.file_count}, Lines: #{target.line_count}"
                  0
                else
                  $stderr.write "Error: #{target.size_info[:error]}\n"
                  1
                end
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
