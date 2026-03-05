# frozen_string_literal: true

require "dry/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class List < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "List available demo tapes"

          def call(**)
            tapes = Molecules::TapeScanner.new.list
            return puts("No demo tapes found.") if tapes.empty?

            puts "Available demo tapes:"
            width = tapes.map { |item| item[:name].length }.max

            tapes.each do |item|
              description = item[:description].to_s.strip
              description = "(no description)" if description.empty?
              puts format("  %-#{width}s  %-40s  (%s)", item[:name], description, item[:source])
            end
          rescue StandardError => e
            raise Ace::Core::CLI::Error, e.message
          end
        end
      end
    end
  end
end
