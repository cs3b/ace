# frozen_string_literal: true

require "json"

module Ace
  module Git
    module Commands
      # Command for showing branch information
      class BranchCommand
        def execute(options)
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
