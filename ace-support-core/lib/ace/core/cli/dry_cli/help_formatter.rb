# frozen_string_literal: true

require "dry/cli"

module Dry
  class CLI
    # Monkey-patch Banner to produce ALL-CAPS section headers for --help output.
    #
    # This replaces the default dry-cli Banner format with a modern, gh/kubectl-style
    # format using NAME, USAGE, DESCRIPTION, ARGUMENTS, OPTIONS, EXAMPLES sections.
    #
    # COMPATIBILITY: Tested with dry-cli 1.4.1. This monkey-patch replaces Banner's
    # singleton methods entirely. If dry-cli changes Banner's interface (method signatures,
    # calling conventions), this patch may need updating. Pin dry-cli ~> 1.4 in gemspec.
    #
    # @since ace-support-core 0.23.0
    module Banner
      # Column width for option/argument alignment
      COLUMN_WIDTH = 34

      # Assemble all sections with double-newline separators.
      #
      # @param command [Dry::CLI::Command] the command
      # @param name [String] the program/command name
      # @return [String] formatted help text
      def self.call(command, name)
        [
          section_name(command, name),
          section_usage(command, name),
          section_description(command),
          section_subcommands(command),
          section_arguments(command),
          section_options(command),
          section_examples(command, name)
        ].compact.join("\n\n")
      end

      # NAME section: "NAME\n  command-name - first line of description"
      def self.section_name(command, name)
        summary = first_line(command.description)
        line = summary ? "#{name} - #{summary}" : name.to_s
        "NAME\n  #{line}"
      end

      # USAGE section: "USAGE\n  command-name [ARGS] [OPTIONS]"
      def self.section_usage(command, name)
        usage = "#{name}#{arguments_synopsis(command)}"
        usage += " [OPTIONS]" if command.options.any?

        if command.subcommands.any?
          usage += " | #{name} SUBCOMMAND"
        end

        "USAGE\n  #{usage}"
      end

      # DESCRIPTION section: full description minus the first line (which is in NAME).
      # Returns nil if no description or only one line.
      def self.section_description(command)
        return nil if command.description.nil?

        lines = command.description.to_s.strip.split("\n")
        return nil if lines.size <= 1

        # Drop first line (already shown in NAME), strip leading blank lines
        rest = lines.drop(1)
        rest = rest.drop_while { |l| l.strip.empty? }
        return nil if rest.empty?

        body = rest.map { |l| "  #{l.strip}" }.join("\n")
        "DESCRIPTION\n#{body}"
      end

      # SUBCOMMANDS section (if the command has subcommands)
      def self.section_subcommands(command)
        return nil if command.subcommands.empty?

        lines = command.subcommands.filter_map do |subcommand_name, subcommand|
          next if subcommand.respond_to?(:hidden) && subcommand.hidden

          desc = subcommand.command&.description
          "  #{subcommand_name.ljust(COLUMN_WIDTH)}#{desc}"
        end

        return nil if lines.empty?

        "SUBCOMMANDS\n#{lines.join("\n")}"
      end

      # ARGUMENTS section with consistent column alignment.
      def self.section_arguments(command)
        return nil if command.arguments.empty?

        lines = command.arguments.map do |argument|
          label = argument.name.to_s.upcase
          label = "[#{label}]" unless argument.required?
          desc_parts = []
          desc_parts << argument.desc if argument.desc && !argument.desc.empty?
          desc_parts << "(required)" if argument.required?

          "  #{label.ljust(COLUMN_WIDTH)}#{desc_parts.join(" ")}"
        end

        "ARGUMENTS\n#{lines.join("\n")}"
      end

      # OPTIONS section: --flag, -alias VALUE    Description (default: val)
      def self.section_options(command)
        lines = command.options.map do |option|
          format_option_full(option)
        end

        lines << "  #{"--help, -h".ljust(COLUMN_WIDTH)}Show this help"
        "OPTIONS\n#{lines.join("\n")}"
      end

      # EXAMPLES section: "$ name args    Description"
      # Fixes the duplicate command name bug by stripping the command name prefix
      # from examples that already include it.
      def self.section_examples(command, name)
        return nil if command.examples.empty?

        lines = command.examples.map do |example|
          # Strip command name prefix if the example already starts with it
          cleaned = example.to_s
          cleaned = cleaned.sub(/\A#{Regexp.escape(name)}\s*/, "")
          "  $ #{name} #{cleaned}".rstrip
        end

        "EXAMPLES\n#{lines.join("\n")}"
      end

      # --- Private helpers ---

      # Extract the first line of a multiline description.
      def self.first_line(description)
        return nil if description.nil?

        description.to_s.strip.split("\n").first&.strip
      end

      # Build the arguments synopsis for the USAGE line (e.g., " FILE [OUTPUT]").
      def self.arguments_synopsis(command)
        required = command.required_arguments.map { |a| a.name.upcase }
        optional = command.optional_arguments.map { |a| "[#{a.name.upcase}]" }
        result = (required + optional).compact
        result.empty? ? "" : " #{result.join(" ")}"
      end

      # Format a single option for full --help display.
      def self.format_option_full(option)
        name = Inflector.dasherize(option.name)
        name = if option.boolean?
                 "[no-]#{name}"
               elsif option.flag?
                 name
               elsif option.array?
                 "#{name}=VALUE1,VALUE2,.."
               else
                 "#{name}=VALUE"
               end

        if option.aliases.any?
          name = "#{name}, #{option.alias_names.join(", ")}"
        end

        label = "  --#{name}"
        desc_parts = []
        desc_parts << option.desc.to_s unless option.desc.nil? || option.desc.to_s.empty?
        unless option.default.nil?
          desc_parts << "(default: #{option.default.inspect})"
        end

        desc_str = desc_parts.join(" ")
        if desc_str.empty?
          label
        else
          "#{label.ljust(COLUMN_WIDTH + 2)}#{desc_str}"
        end
      end
    end

  end
end

# Monkey-patch Dry::CLI to support two-tier help at subcommand level.
#
# When dry-cli detects -h or --help in a subcommand's arguments, it calls
# the private `help` method. We prepend a module to override `perform_registry`
# to track the original arguments so the `help` method can distinguish between
# -h (concise) and --help (full).
#
# COMPATIBILITY: Tested with dry-cli 1.4.1. Relies on `perform_registry` private
# method signature and `help(command, prog_name)` method. Pin dry-cli ~> 1.4.
#
# @since ace-support-core 0.23.0
module Dry
  module AceTwoTierHelp
    private

    # Wrap perform_registry to capture original arguments for help detection.
    def perform_registry(arguments)
      @_original_arguments = arguments.dup
      super
    end

    # Override help to support two-tier formatting.
    # Uses @_original_arguments to detect -h vs --help.
    def help(command, prog_name)
      args = @_original_arguments || []
      @_original_arguments = nil # Clear to prevent leakage across calls
      if args.include?("-h") && !args.include?("--help")
        out.puts ::Ace::Core::CLI::DryCli::HelpConcise.call(command, prog_name)
      else
        out.puts Dry::CLI::Banner.call(command, prog_name)
      end
      exit(0)
    end
  end

  CLI.prepend(AceTwoTierHelp)
end
