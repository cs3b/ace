# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class Show < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc "Show metadata and contents for a demo tape"

          argument :tape, required: true, desc: "Tape name or .tape file path"

          def call(tape:, **)
            entry = Molecules::TapeScanner.new.find(tape)

            puts "Tape: #{entry[:name]}"
            puts "Source: #{entry[:display_path]}"
            puts "Description: #{entry[:description]}" if entry[:description]

            extra_fields = entry[:metadata].reject { |key, _| key == "description" }
            extra_fields.keys.sort.each do |key|
              puts "#{titleize_key(key)}: #{extra_fields[key]}"
            end

            puts
            puts "--- Contents ---"
            print entry[:content]
          rescue TapeNotFoundError, ArgumentError => e
            raise Ace::Core::CLI::Error, e.message
          end

          private

          def titleize_key(key)
            key.split("_").map(&:capitalize).join(" ")
          end
        end
      end
    end
  end
end
