# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class List < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "List available demo tapes"

          def call(**)
            tapes = Molecules::TapeScanner.new.list
            return puts("No demo tapes found.") if tapes.empty?

            puts "Available demo tapes:"
            width = tapes.map { |item| item[:name].length }.max

            tapes.each do |item|
              description = item[:description].to_s.strip
              description = "(no description)" if description.empty?
              format_label = (item[:format] == "yaml") ? "yaml" : "tape"
              puts format("  %-#{width}s  %-5s  %-40s  (%s)", item[:name], format_label, description, item[:source])
            end
          rescue => e
            raise Ace::Support::Cli::Error, e.message
          end
        end
      end
    end
  end
end
