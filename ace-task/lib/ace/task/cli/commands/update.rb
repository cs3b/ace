# frozen_string_literal: true

require "ace/support/cli"
require "ace/support/items"

module Ace
  module Task
    module CLI
      module Commands
        # ace-support-cli Command class for ace-task update
        class Update < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Update task metadata and/or move to a folder

            Updates frontmatter fields using set, add, or remove operations.
            Use --set for scalar fields, --add/--remove for array fields like tags.
            Use --move-to to relocate to a special folder or back to root.
          DESC

          example [
            'q7w --set status=done',
            'q7w --set status=done,priority=high',
            'q7w --add tags=shipped --remove tags=pending-review',
            'q7w --set worktree.branch=my-branch',
            'q7w --set status=done --move-to archive',
            'q7w --move-to next',
            'q7w.a --move-as-child-of none    # Promote subtask to standalone',
            'q7w --move-as-child-of self      # Convert to orchestrator',
            'q7w --move-as-child-of abc       # Demote to subtask of abc',
            'q7w --position first             # Pin to sort before all tasks',
            'q7w --position last              # Pin to sort after existing tasks',
            'q7w --position after:abc         # Pin to sort after task abc',
            'q7w --remove position            # Remove pin, return to auto-sort'
          ]

          argument :ref, required: true, desc: "Task reference (full ID, short ref, or suffix)"

          option :set,    type: :array, desc: "Set field: key=value (comma-separated for multiple)"
          option :add,    type: :array, desc: "Add to array field: key=value (comma-separated for multiple)"
          option :remove, type: :array, desc: "Remove from array field: key=value (comma-separated for multiple)"
          option :move_to, type: :string, aliases: %w[-m], desc: "Move to folder (archive, maybe, anytime, next)"
          option :move_as_child_of, type: :string, desc: "Reparent: <parent_ref>, 'none' (promote), 'self' (orchestrator)"
          option :position, type: :string, aliases: %w[-p], desc: "Set position: first, last, after:<ref>, before:<ref>"

          option :git_commit, type: :boolean, aliases: %w[--gc], desc: "Auto-commit changes"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            set_args        = Array(options[:set])
            add_args        = Array(options[:add])
            remove_args     = Array(options[:remove])
            move_to         = options[:move_to]
            move_as_child   = options[:move_as_child_of]
            position_arg    = options[:position]

            has_any_op = !set_args.empty? || !add_args.empty? || !remove_args.empty? ||
                         move_to || move_as_child || position_arg
            unless has_any_op
              warn "Error: at least one of --set, --add, --remove, --move-to, --move-as-child-of, or --position is required"
              warn ""
              warn "Usage: ace-task update REF [--set K=V]... [--move-to FOLDER] [--position first|last|after:REF|before:REF]"
              raise Ace::Support::Cli::Error.new("No update operations specified")
            end

            if move_to && move_as_child
              raise Ace::Support::Cli::Error.new("Cannot use --move-to and --move-as-child-of together")
            end

            set_hash    = parse_kv_pairs(set_args)
            add_hash    = parse_kv_pairs(add_args)
            remove_hash = parse_kv_pairs(remove_args)

            manager = Ace::Task::Organisms::TaskManager.new

            # Resolve --position into a set or remove operation
            if position_arg
              pos_value = resolve_position(position_arg, manager)
              set_hash["position"] = pos_value
            end

            task = manager.update(ref, set: set_hash, add: add_hash, remove: remove_hash,
                                  move_to: move_to, move_as_child_of: move_as_child)

            unless task
              raise Ace::Support::Cli::Error.new("Task '#{ref}' not found")
            end

            if move_as_child
              puts "Task reparented: #{task.id} #{task.title}"
            elsif move_to
              folder_info = task.special_folder || "root"
              puts "Task updated: #{task.id} #{task.title} → #{folder_info}"
            else
              puts "Task updated: #{task.id} #{task.title}"
            end
            puts "Info: #{manager.last_update_note}" if manager.last_update_note

            if options[:git_commit]
              commit_paths = (move_to || move_as_child) ? [manager.root_dir] : [task.path]
              intention = if move_as_child
                "reparent task #{task.id}"
              elsif move_to
                "update task #{task.id} and move to #{task.special_folder || "root"}"
              else
                "update task #{task.id}"
              end
              Ace::Support::Items::Molecules::GitCommitter.commit(
                paths: commit_paths,
                intention: intention
              )
            end
          end

          private

          # Resolve a --position argument into a B36TS value.
          # Supports: first, last, after:<ref>, before:<ref>
          def resolve_position(arg, manager)
            pg = Ace::Support::Items::Atoms::PositionGenerator

            case arg
            when "first"
              pg.first
            when "last"
              pg.last
            when /\Aafter:(.+)\z/
              target = manager.show($1)
              raise Ace::Support::Cli::Error.new("Task '#{$1}' not found for position reference") unless target

              target_pos = target.metadata&.dig("position")
              if target_pos
                pg.after(target_pos)
              else
                # Target has no position — generate a current timestamp
                pg.last
              end
            when /\Abefore:(.+)\z/
              target = manager.show($1)
              raise Ace::Support::Cli::Error.new("Task '#{$1}' not found for position reference") unless target

              target_pos = target.metadata&.dig("position")
              if target_pos
                pg.before(target_pos)
              else
                # Target has no position — generate a very early timestamp
                pg.first
              end
            else
              raise Ace::Support::Cli::Error.new("Invalid --position value '#{arg}': expected first, last, after:<ref>, or before:<ref>")
            end
          end

          # Parse ["key=value", "key=value2"] into {"key" => typed_value, ...}
          def parse_kv_pairs(args)
            result = {}
            args.each do |arg|
              unless arg.include?("=")
                raise Ace::Support::Cli::Error.new("Invalid format '#{arg}': expected key=value")
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
              raise Ace::Support::Cli::Error.new("Invalid argument '#{arg}': #{e.message}")
            end
            result
          end
        end
      end
    end
  end
end
