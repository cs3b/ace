# frozen_string_literal: true

require "dry/cli"
require "ace/support/items"

module Ace
  module Idea
    module CLI
      module Commands
        # dry-cli Command class for ace-idea update
        class Update < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Update idea metadata

            Updates frontmatter fields using set, add, or remove operations.
            Use --set for scalar fields, --add/--remove for array fields like tags.

          DESC

          example [
            'q7w --set status=done',
            'q7w --set status=in-progress --set title="Refined title"',
            'q7w --add tags=implemented --remove tags=pending-review',
            'q7w --set status=done --add tags=shipped'
          ]

          argument :ref, required: true, desc: "Idea reference (6-char ID or 3-char shortcut)"

          option :set,    type: :string, repeat: true, desc: "Set field: key=value (can repeat)"
          option :add,    type: :string, repeat: true, desc: "Add to array field: key=value (can repeat)"
          option :remove, type: :string, repeat: true, desc: "Remove from array field: key=value (can repeat)"

          option :git_commit, type: :boolean, aliases: %w[--gc], desc: "Auto-commit changes"

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
              warn "Usage: ace-idea update REF [--set K=V]... [--add K=V]... [--remove K=V]..."
              raise Ace::Core::CLI::Error.new("No update operations specified")
            end

            set_hash    = parse_kv_pairs(set_args)
            add_hash    = parse_kv_pairs(add_args)
            remove_hash = parse_kv_pairs(remove_args)

            manager = Ace::Idea::Organisms::IdeaManager.new
            idea = manager.update(ref, set: set_hash, add: add_hash, remove: remove_hash)

            unless idea
              raise Ace::Core::CLI::Error.new("Idea '#{ref}' not found")
            end

            puts "Idea updated: #{idea.id} #{idea.title}"

            if options[:git_commit]
              Ace::Support::Items::Molecules::GitCommitter.commit(
                paths: [idea.path],
                intention: "update idea #{idea.id}"
              )
            end
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

              # parse([arg]) returns {key => typed_value}
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
