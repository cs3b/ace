# frozen_string_literal: true

require "json"
require "ace/core/cli/base"

module Ace
  module Git
    module CLI
      module Commands
      # ace-support-cli command for showing branch information
      class Branch < Ace::Support::Cli::Command
        include Ace::Core::CLI::Base

        desc "Show current branch information"

        option :format, type: :string, aliases: ["f"], default: "text",
                       desc: "Output format: text, json"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

        def call(**options)
          # Get branch info
          branch_info = Molecules::BranchReader.full_info

          if branch_info[:error]
            raise Ace::Core::CLI::Error.new(branch_info[:error])
          end

          # Output based on format
          case options[:format]
          when "json"
            puts JSON.pretty_generate(branch_info)
          else
            output_text(branch_info)
          end

        rescue Ace::Git::Error => e
          raise Ace::Core::CLI::Error.new(e.message)
        end

        private

        def output_text(info)
          output = info[:name]

          if info[:detached]
            output += " (detached HEAD)"
          elsif info[:tracking]
            output += " (tracking: #{info[:tracking]}"
            output += ", #{info[:status_description]}" unless info[:up_to_date]
            output += ")"
          end

          puts output
        end
      end
    end
  end
end
end
