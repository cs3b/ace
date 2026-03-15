# frozen_string_literal: true

require "ace/support/cli"
require "ace/support/items"

module Ace
  module Retro
    module CLI
      module Commands
        # ace-support-cli Command class for ace-retro update
        class Update < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc <<~DESC.strip
            Update retro metadata and/or move to a folder

            Updates frontmatter fields using set, add, or remove operations.
            Use --set for scalar fields, --add/--remove for array fields like tags.
            Use --move-to to relocate to a special folder or back to root.
          DESC

          example [
            'q7w --set status=done',
            'q7w --set status=done --set title="Refined title"',
            'q7w --add tags=reviewed --remove tags=in-progress',
            'q7w --set status=done --add tags=shipped',
            'q7w --set status=done --move-to archive',
            'q7w --move-to next'
          ]

          argument :ref, required: true, desc: "Retro reference (6-char ID or 3-char shortcut)"

          option :set,    type: :string, repeat: true, desc: "Set field: key=value (can repeat)"
          option :add,    type: :string, repeat: true, desc: "Add to array field: key=value (can repeat)"
          option :remove, type: :string, repeat: true, desc: "Remove from array field: key=value (can repeat)"
          option :move_to, type: :string, aliases: %w[-m], desc: "Move to folder (archive, next)"

          option :git_commit, type: :boolean, aliases: %w[--gc], desc: "Auto-commit changes"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            set_args    = Array(options[:set])
            add_args    = Array(options[:add])
            remove_args = Array(options[:remove])
            move_to     = options[:move_to]

            if set_args.empty? && add_args.empty? && remove_args.empty? && move_to.nil?
              warn "Error: at least one of --set, --add, --remove, or --move-to is required"
              warn ""
              warn "Usage: ace-retro update REF [--set K=V]... [--add K=V]... [--remove K=V]... [--move-to FOLDER]"
              raise Ace::Core::CLI::Error.new("No update operations specified")
            end

            set_hash    = parse_kv_pairs(set_args)
            add_hash    = parse_kv_pairs(add_args)
            remove_hash = parse_kv_pairs(remove_args)

            manager = Ace::Retro::Organisms::RetroManager.new
            retro = manager.update(ref, set: set_hash, add: add_hash, remove: remove_hash, move_to: move_to)

            unless retro
              raise Ace::Core::CLI::Error.new("Retro '#{ref}' not found")
            end

            if move_to
              folder_info = retro.special_folder || "root"
              puts "Retro updated: #{retro.id} #{retro.title} → #{folder_info}"
            else
              puts "Retro updated: #{retro.id} #{retro.title}"
            end

            if options[:git_commit]
              commit_paths = move_to ? [manager.root_dir] : [retro.path]
              intention = if move_to
                "update retro #{retro.id} and move to #{retro.special_folder || "root"}"
              else
                "update retro #{retro.id}"
              end
              Ace::Support::Items::Molecules::GitCommitter.commit(
                paths: commit_paths,
                intention: intention
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
