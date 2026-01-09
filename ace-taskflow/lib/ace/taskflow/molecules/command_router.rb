# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Routes CLI arguments with default command support and subcommand disambiguation.
      #
      # This molecule handles:
      # 1. Default command routing (e.g., "150" -> "task 150")
      # 2. Task subcommand disambiguation (e.g., "task create" vs "task 114")
      #
      # Extracted from CLI.start to improve testability and separation of concerns.
      #
      # @example Basic usage
      #   args = CommandRouter.route(["150"], default: "task", known_commands: KNOWN)
      #   # => ["task", "150"]
      #
      # @example Task subcommand routing
      #   args = CommandRouter.route(["task", "create"], task_subcommands: ["create"])
      #   # => ["task", "create"] (passes through for nested command)
      class CommandRouter
        # Route CLI arguments with default command and subcommand handling
        #
        # @param args [Array<String>] Command-line arguments
        # @param default [String] Default command to prepend when first arg is unknown
        # @param known_commands [Set<String>] Set of recognized top-level commands
        # @param task_subcommands [Array<String>] List of valid task subcommands
        # @return [Array<String>] Routed arguments
        def self.route(args, default:, known_commands:, task_subcommands: [])
          args = apply_default_command(args, default: default, known_commands: known_commands)
          args = route_task_subcommand(args, task_subcommands: task_subcommands)
          args
        end

        # Prepend default command when first argument is not a known command
        #
        # @param args [Array<String>] Command-line arguments
        # @param default [String] Default command to prepend
        # @param known_commands [Set<String>] Set of recognized commands
        # @return [Array<String>] Arguments with default command prepended if needed
        def self.apply_default_command(args, default:, known_commands:)
          if args.empty? || !known_commands.include?(args.first)
            [default] + args
          else
            args
          end
        end

        # Route task commands to disambiguate between subcommands and task references
        #
        # Handles the collision between:
        # - Nested subcommands: "task create --title X"
        # - Direct references: "task 114" or "task task.114"
        #
        # @param args [Array<String>] Command-line arguments
        # @param task_subcommands [Array<String>] List of valid task subcommands
        # @return [Array<String>] Arguments (unmodified, routing is handled by dry-cli)
        def self.route_task_subcommand(args, task_subcommands:)
          # Only handle "task" prefix
          return args if args.first != "task"

          # Need at least 2 args to have "task <something>"
          return args if args.length < 2

          # If second arg is a known subcommand, dry-cli will handle routing
          # Otherwise, it's a task reference - pass through to legacy task wrapper
          # Either way, we return args unchanged; dry-cli registry handles dispatch
          args
        end
      end
    end
  end
end
