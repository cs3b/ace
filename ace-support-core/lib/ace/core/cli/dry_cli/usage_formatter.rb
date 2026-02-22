# frozen_string_literal: true

require "dry/cli"

module Dry
  class CLI
    # Monkey-patch Usage to produce ALL-CAPS section headers for registry-level help.
    #
    # Key behavioral changes:
    # - `description(command)` returns first line only of multiline desc
    #   (fixes verbose top-level help in ace-docs, ace-nav, ace-bundle)
    # - `call(result)` uses "COMMANDS" header instead of "Commands:"
    # - `call_concise(result)` provides compact variant for -h
    # - Supports grouped commands via COMMAND_GROUPS constant on the registry
    #
    # @since ace-support-core 0.12.0
    module Usage
      # Column width for command alignment
      COLUMN_WIDTH = 34

      # Full registry-level help with ALL-CAPS COMMANDS header.
      # Supports grouped commands if the registry defines COMMAND_GROUPS.
      # Appends EXAMPLES section if the registry defines HELP_EXAMPLES.
      #
      # @param result [Dry::CLI::CommandRegistry::LookupResult] registry lookup result
      # @param registry [Module, nil] the CLI registry (for group and examples support)
      # @return [String] formatted command listing
      def self.call(result, registry: nil)
        max_length, commands, node_names = commands_and_arguments(result)

        # Check for command groups
        groups = resolve_groups(registry)

        output = if groups && !groups.empty?
                   format_grouped(commands, groups, max_length, node_names)
                 else
                   format_flat(commands, max_length)
                 end

        # Append EXAMPLES section if defined
        examples = resolve_examples(registry)
        output += "\n\n#{format_examples(examples)}" if examples

        output
      end

      # Concise registry-level help for -h flag.
      # Always flat (no groups), compact, with footer hint.
      #
      # @param result [Dry::CLI::CommandRegistry::LookupResult] registry lookup result
      # @param registry [Module, nil] the CLI registry (for program name detection)
      # @return [String] compact command listing
      def self.call_concise(result, registry: nil)
        max_length, commands, _node_names = commands_and_arguments(result)
        output = format_flat(commands, max_length, header: "Commands:")
        output += "\n\n#{concise_footer(registry)}" if registry
        output
      end

      # Override: return ONLY the first line of a multiline description.
      # This fixes verbose top-level help where multiline `desc` blocks leak.
      #
      # @param command [Dry::CLI::Command] the command
      # @return [String, nil] first line of description, prefixed with "  # "
      def self.description(command)
        return unless CLI.command?(command)
        return if command.description.nil?

        first_line = command.description.to_s.strip.split("\n").first&.strip
        return if first_line.nil? || first_line.empty?

        " # #{first_line}"
      end

      # --- Unchanged from dry-cli (needed because we replaced the module methods) ---

      def self.commands_and_arguments(result)
        max_length = 0
        node_names = {} # Map node object_id to registered name (avoids setting ivars on external objects)
        ret = commands(result).each_with_object({}) do |(name, node), memo|
          args = if node.command && node.leaf? && node.children?
                   ROOT_COMMAND_WITH_SUBCOMMANDS_BANNER
                 elsif node.leaf?
                   arguments(node.command)
                 else
                   SUBCOMMAND_BANNER
                 end

          partial = "  #{command_name(result, name)}#{args}"
          max_length = partial.bytesize if max_length < partial.bytesize
          node_names[node.object_id] = name
          memo[partial] = node
        end

        [max_length, ret, node_names]
      end

      def self.arguments(command)
        return unless CLI.command?(command)

        required_arguments = command.required_arguments
        optional_arguments = command.optional_arguments

        required = required_arguments.map { |arg| arg.name.upcase }.join(" ") if required_arguments.any?
        optional = optional_arguments.map { |arg| "[#{arg.name.upcase}]" }.join(" ") if optional_arguments.any?
        result = [required, optional].compact

        " #{result.join(" ")}" unless result.empty?
      end

      def self.justify(string, padding, usage)
        return string.chomp(" ") if usage.nil?

        string.ljust(padding + padding / 2)
      end

      def self.commands(result)
        result.children.sort_by { |name, _| name }
      end

      def self.command_name(result, name)
        ProgramName.call([result.names, name])
      end

      private

      # Format commands as a flat list.
      def self.format_flat(commands, max_length, header: "COMMANDS")
        lines = commands.filter_map do |banner, node|
          next if node.respond_to?(:hidden) && node.hidden

          usage = description(node.command) if node.leaf?
          "#{justify(banner, max_length, usage)}#{usage}"
        end

        lines.unshift(header).join("\n")
      end

      # Format commands in groups based on COMMAND_GROUPS.
      def self.format_grouped(commands, groups, max_length, node_names)
        output = ["COMMANDS"]
        grouped_names = groups.values.flatten
        commands_by_name = {}

        # Index commands by their registered name (via node_names hash)
        commands.each do |banner, node|
          cmd_name = node_names[node.object_id]
          commands_by_name[cmd_name] = [banner, node] if cmd_name
        end

        # Render each group
        groups.each do |group_name, cmd_names|
          group_lines = []
          cmd_names.each do |cmd_name|
            entry = commands_by_name[cmd_name]
            next unless entry

            banner, node = entry
            next if node.respond_to?(:hidden) && node.hidden

            usage = description(node.command) if node.leaf?
            group_lines << "  #{justify(banner.strip, max_length, usage)}#{usage}"
          end

          next if group_lines.empty?

          output << ""
          output << "  #{group_name}"
          output.concat(group_lines)
        end

        # Render ungrouped commands
        ungrouped = commands.filter_map do |banner, node|
          cmd_name = node_names[node.object_id]
          next if cmd_name && grouped_names.include?(cmd_name)
          next if node.respond_to?(:hidden) && node.hidden

          usage = description(node.command) if node.leaf?
          "#{justify(banner, max_length, usage)}#{usage}"
        end

        unless ungrouped.empty?
          output << ""
          output.concat(ungrouped)
        end

        output.join("\n")
      end

      # Resolve COMMAND_GROUPS from a registry module, if defined.
      def self.resolve_groups(registry)
        return nil unless registry
        return nil unless registry.respond_to?(:const_defined?) && registry.const_defined?(:COMMAND_GROUPS)

        registry.const_get(:COMMAND_GROUPS)
      end

      # Resolve HELP_EXAMPLES from a registry module, if defined.
      #
      # @param registry [Module, nil] the CLI registry
      # @return [Array<Array(String, String)>, nil] array of [description, command] pairs
      def self.resolve_examples(registry)
        return nil unless registry
        return nil unless registry.respond_to?(:const_defined?) && registry.const_defined?(:HELP_EXAMPLES)

        registry.const_get(:HELP_EXAMPLES)
      end

      # Format HELP_EXAMPLES into an EXAMPLES section.
      #
      # @param examples [Array<Array(String, String)>] [description, command] pairs
      # @return [String] formatted EXAMPLES block
      def self.format_examples(examples)
        lines = examples.map do |desc, cmd|
          "  $ #{cmd}  # #{desc}"
        end

        "EXAMPLES\n#{lines.join("\n")}"
      end

      # Generate footer hint for concise help.
      #
      # @param registry [Module] the CLI registry
      # @return [String] footer text
      def self.concise_footer(registry)
        name = resolve_program_name(registry)
        "Run '#{name} --help' for more info. Each command has its own --help."
      end

      # Derive program name from registry module.
      #
      # @param registry [Module] the CLI registry
      # @return [String] the program name (e.g., "ace-task")
      def self.resolve_program_name(registry)
        return $PROGRAM_NAME.split("/").last if registry.nil?

        if registry.respond_to?(:const_defined?) && registry.const_defined?(:PROGRAM_NAME)
          return registry.const_get(:PROGRAM_NAME)
        end

        # Derive from $0 as fallback
        $PROGRAM_NAME.split("/").last
      end
    end
  end
end
