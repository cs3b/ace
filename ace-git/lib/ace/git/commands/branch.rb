# frozen_string_literal: true

require "json"
require "ace/core/cli/dry_cli/base"

module Ace
  module Git
    module Commands
      # dry-cli command for showing branch information
      class Branch < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Show current branch information"

        option :format, type: :string, aliases: ["f"], default: "text",
                       desc: "Output format: text, json"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"

        def call(**options)
          # Get branch info
          branch_info = Molecules::BranchReader.full_info

          if branch_info[:error]
            warn "Error: #{branch_info[:error]}"
            return 1
          end

          # Output based on format
          case options[:format]
          when "json"
            puts JSON.pretty_generate(branch_info)
          else
            output_text(branch_info)
          end

          0
        rescue Ace::Git::Error => e
          warn "Error: #{e.message}"
          1
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
