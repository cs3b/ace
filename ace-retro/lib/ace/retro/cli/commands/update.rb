# frozen_string_literal: true

require "dry/cli"
require "ace/support/items"

module Ace
  module Retro
    module CLI
      module Commands
        # dry-cli Command class for ace-retro update
        class Update < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Update retro metadata

            Updates frontmatter fields using set, add, or remove operations.
            Use --set for scalar fields, --add/--remove for array fields like tags.

          DESC

          example [
            'q7w --set status=done',
            'q7w --set status=done --set title="Refined title"',
            'q7w --add tags=reviewed --remove tags=in-progress',
            'q7w --set status=done --add tags=shipped'
          ]

          argument :ref, required: true, desc: "Retro reference (6-char ID or 3-char shortcut)"

          option :set,    type: :string, repeat: true, desc: "Set field: key=value (can repeat)"
          option :add,    type: :string, repeat: true, desc: "Add to array field: key=value (can repeat)"
          option :remove, type: :string, repeat: true, desc: "Remove from array field: key=value (can repeat)"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            set_args    = Array(options[:set])
            add_args    = Array(options[:add])
            remove_args = Array(options[:remove])

            if set_args.empty? && add_args.empty? && remove_args.empty?
              warn "Error: at least one of --set, --add, or --remove is required"
              warn ""
              warn "Usage: ace-retro update REF [--set K=V]... [--add K=V]... [--remove K=V]..."
              raise Ace::Core::CLI::Error.new("No update operations specified")
            end

            set_hash    = parse_kv_pairs(set_args)
            add_hash    = parse_kv_pairs(add_args)
            remove_hash = parse_kv_pairs(remove_args)

            manager = Ace::Retro::Organisms::RetroManager.new
            retro = manager.update(ref, set: set_hash, add: add_hash, remove: remove_hash)

            unless retro
              raise Ace::Core::CLI::Error.new("Retro '#{ref}' not found")
            end

            puts "Retro updated: #{retro.id} #{retro.title}"
          end

          private

          # Parse ["key=value", "key=value2"] into {"key" => typed_value, ...}
          # Delegates to FieldArgumentParser for type inference (arrays, booleans, numerics).
          def parse_kv_pairs(args)
            result = {}
            args.each do |arg|
              unless arg.include?("=")
                raise Ace::Core::CLI::Error.new("Invalid format '#{arg}': expected key=value")
              end

              parsed = Ace::Support::Items::Atoms::FieldArgumentParser.parse([arg])
              parsed.each do |key, value|
                if result.key?(key)
                  result[key] = Array(result[key]) + Array(value)
                else
                  result[key] = value
                end
              end
            rescue Ace::Support::Items::Atoms::FieldArgumentParser::ParseError => e
              raise Ace::Core::CLI::Error.new("Invalid argument '#{arg}': #{e.message}")
            end
            result
          end
        end
      end
    end
  end
end
