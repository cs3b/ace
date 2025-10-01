# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for parsing idea command arguments
      # Unit testable - no I/O
      class IdeaArgParser
        # Parse idea capture options
        # @param args [Array<String>] Command arguments
        # @return [Hash] Parsed options with :content, :location, :git_commit, :llm_enhance
        def self.parse_capture_options(args)
          options = {
            content: "",
            location: nil,
            git_commit: nil,
            llm_enhance: nil
          }

          content_parts = []
          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--backlog"
              options[:location] = "backlog"
              i += 1
            when "--release", "-r"
              options[:location] = args[i + 1]
              i += 2
            when "--current"
              options[:location] = "current"
              i += 1
            when "--git-commit", "-gc"
              options[:git_commit] = true
              i += 1
            when "--no-git-commit"
              options[:git_commit] = false
              i += 1
            when "--llm-enhance", "-llm"
              options[:llm_enhance] = true
              i += 1
            when "--no-llm-enhance"
              options[:llm_enhance] = false
              i += 1
            else
              content_parts << arg unless arg.start_with?("-")
              i += 1
            end
          end

          options[:content] = content_parts.join(" ")
          options
        end

        # Parse context from arguments
        # @param args [Array<String>] Command arguments
        # @return [String] Context (current, backlog, or release name)
        def self.parse_context(args)
          args.each_with_index do |arg, index|
            case arg
            when "--backlog"
              return "backlog"
            when "--release", "-r"
              return args[index + 1] if index + 1 < args.length
            when "--current"
              return "current"
            end
          end
          "current"
        end

        # Parse reschedule options
        # @param args [Array<String>] Command arguments (first element should be reference)
        # @return [Hash] Parsed options with :reference and reschedule options
        def self.parse_reschedule_options(args)
          reference = args.first&.start_with?("-") ? nil : args.first
          options = {}

          i = reference ? 1 : 0
          while i < args.length
            case args[i]
            when "--add-next"
              options[:add_next] = true
              i += 1
            when "--add-at-end"
              options[:add_at_end] = true
              i += 1
            when "--after"
              options[:after] = args[i + 1]
              i += 2
            when "--before"
              options[:before] = args[i + 1]
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

        # Determine idea location from options and config
        # @param options [Hash] Parsed options with :location
        # @param config [Hash] Configuration with defaults
        # @return [String] Determined location
        def self.determine_location(options, config = {})
          # Explicit location from flags
          return options[:location] if options[:location]

          # Default based on configuration
          default_location = config.dig("defaults", "idea_location") || "active"

          case default_location
          when "active", "current"
            "current"
          when "backlog"
            "backlog"
          else
            default_location
          end
        end
      end
    end
  end
end
