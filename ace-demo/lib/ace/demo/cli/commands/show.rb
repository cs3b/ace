# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class Show < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Show metadata and contents for a demo tape"

          argument :tape, required: true, desc: "Tape name or .tape file path"

          def call(tape:, **)
            entry = Molecules::TapeScanner.new.find(tape)

            puts "Tape: #{entry[:name]}"
            puts "Source: #{entry[:display_path]}"
            puts "Format: #{entry[:format]}"
            puts "Description: #{entry[:description]}" if entry[:description]

            print_yaml_metadata(entry[:metadata]) if entry[:format] == "yaml"
            print_tape_metadata(entry[:metadata]) if entry[:format] != "yaml"

            puts
            puts "--- Contents ---"
            print entry[:content]
          rescue TapeNotFoundError, ArgumentError => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def titleize_key(key)
            key.split("_").map(&:capitalize).join(" ")
          end

          def print_tape_metadata(metadata)
            extra_fields = metadata.reject { |key, _| key == "description" }
            extra_fields.keys.sort.each do |key|
              puts "#{titleize_key(key)}: #{extra_fields[key]}"
            end
          end

          def print_yaml_metadata(metadata)
            tags = Array(metadata["tags"])
            puts "Tags: #{tags.join(', ')}" unless tags.empty?

            settings = metadata["settings"] || {}
            unless settings.empty?
              puts "Settings:"
              settings.each do |key, value|
                puts "  #{titleize_key(key.to_s)}: #{value}" unless value.nil?
              end
            end

            scene_names = Array(metadata["scene_names"])
            unless scene_names.empty?
              puts "Scenes:"
              scene_names.each { |name| puts "  - #{name}" }
            end

            puts "Parse Error: #{metadata["parse_error"]}" if metadata["parse_error"]
          end
        end
      end
    end
  end
end
