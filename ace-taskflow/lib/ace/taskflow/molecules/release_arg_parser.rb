# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for parsing release command arguments
      # Unit testable - no I/O
      class ReleaseArgParser
        # Parse display mode flags from arguments
        # Modifies args array by removing matched flags and optional subfolder
        # @param args [Array<String>] Command arguments (modified in place)
        # @return [Hash] Display mode hash with :mode and :subfolder keys
        #   mode: "path", "content", or "formatted"
        #   subfolder: optional subfolder path (only for --path mode)
        def self.parse_display_mode(args)
          if index = args.index("--path")
            args.delete_at(index)
            # Check if next argument is a subfolder (not a flag)
            subfolder = nil
            if index < args.length && !args[index].start_with?("-")
              subfolder = args.delete_at(index)
            end
            return { mode: "path", subfolder: subfolder }
          elsif index = args.index("--content")
            args.delete_at(index)
            return { mode: "content", subfolder: nil }
          end
          { mode: "formatted", subfolder: nil }
        end

        # Parse create subcommand arguments
        # @param args [Array<String>] Command arguments
        # @return [Hash] Parsed create options
        def self.parse_create_args(args)
          codename = nil
          version = nil
          location = "backlog"

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--release", "-r"
              version = args[i + 1]
              i += 2
            when "--current", "-c"
              location = "active"
              i += 1
            when "--backlog", "-b"
              location = "backlog"
              i += 1
            else
              codename = arg unless arg.start_with?("-")
              i += 1
            end
          end

          {
            codename: codename,
            version: version,
            location: location
          }
        end

        # Parse reschedule subcommand arguments
        # @param args [Array<String>] Command arguments
        # @return [Hash] Parsed reschedule options with :reference and :options
        def self.parse_reschedule_args(args)
          reference = args.first&.start_with?("-") ? nil : args.first
          options = {}

          i = reference ? 1 : 0
          while i < args.length
            case args[i]
            when "--status"
              options[:status] = args[i + 1]
              i += 2
            when "--target-date"
              options[:target_date] = args[i + 1]
              i += 2
            else
              i += 1
            end
          end

          {
            reference: reference,
            options: options
          }
        end

        # Parse demote subcommand arguments
        # @param args [Array<String>] Command arguments
        # @return [Hash] Parsed demote options with :name and :to
        def self.parse_demote_args(args)
          name = nil
          to = "done"

          args.each_with_index do |arg, index|
            if arg == "--to"
              to = args[index + 1]
            elsif !arg.start_with?("--")
              name = arg
            end
          end

          {
            name: name,
            to: to
          }
        end
      end
    end
  end
end
