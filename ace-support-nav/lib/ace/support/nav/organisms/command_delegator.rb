# frozen_string_literal: true

require "shellwords"
require_relative "../molecules/config_loader"

module Ace
  module Support
    module Nav
      module Organisms
        # Handles command delegation for cmd-type protocols
        # Executes external commands based on protocol configuration templates
        class CommandDelegator
          def initialize(config_loader: nil)
            @config_loader = config_loader || Molecules::ConfigLoader.new
          end

          # Delegate a URI to an external command
          # @param uri_string [String] The URI to delegate (e.g., "task://083")
          # @param options [Hash] Options from CLI (e.g., {path: true, content: true})
          # @return [Integer] Exit code from the delegated command
          def delegate(uri_string, options = {})
            # Parse the URI to extract protocol and reference
            protocol, reference = parse_uri(uri_string)

            # Load protocol configuration
            protocol_config = @config_loader.load_protocol_config(protocol)

            # Verify this is a cmd-type protocol
            unless protocol_config["type"] == "cmd"
              raise ArgumentError, "Protocol #{protocol} is not a cmd-type protocol"
            end

            # Get command template
            command_template = protocol_config["command_template"]
            unless command_template
              raise ArgumentError, "Protocol #{protocol} missing command_template"
            end

            # Build the command
            command_parts = build_command(command_template, reference, options, protocol_config)

            # Execute the command
            execute_command(command_parts)
          end

          private

          # Parse a URI into protocol and reference
          # @param uri_string [String] URI like "task://083" or "task://v.0.9.0+task.083"
          # @return [Array<String, String>] [protocol, reference]
          def parse_uri(uri_string)
            unless uri_string.include?("://")
              raise ArgumentError, "Invalid URI format: #{uri_string}"
            end

            parts = uri_string.split("://", 2)
            protocol = parts[0]
            reference = parts[1] || ""

            [protocol, reference]
          end

          # Build command array from template and options
          # @param template [String] Command template with %{ref} placeholder
          # @param reference [String] The resource reference to substitute
          # @param options [Hash] CLI options to pass through
          # @param protocol_config [Hash] Protocol configuration
          # @return [Array<String>] Command parts as array for safe execution
          #
          # @note Template parsing uses Shellwords.split() for robust parsing of command
          #   templates, properly handling quoted strings and complex argument patterns.
          def build_command(template, reference, options, protocol_config)
            # Substitute reference in template
            command_string = template.gsub("%{ref}", reference)

            # Parse command using Shellwords for robust handling of quotes and spaces
            command_parts = Shellwords.split(command_string)

            # Add pass-through options
            pass_through_options = protocol_config["pass_through_options"] || []

            options.each do |key, value|
              option_flag = "--#{key.to_s.tr("_", "-")}"

              # Only add if it's in pass_through list or if we don't have a list
              if pass_through_options.empty? || pass_through_options.include?(option_flag)
                if value == true
                  command_parts << option_flag
                elsif value.is_a?(String)
                  command_parts << option_flag
                  command_parts << value
                end
              end
            end

            command_parts
          end

          # Execute command using system and return exit code
          # @param command_parts [Array<String>] Command parts for safe execution
          # @return [Integer] Exit code (0 for success, 1 for failure)
          def execute_command(command_parts)
            # Use system with array argument for safety (no shell interpolation)
            success = system(*command_parts)

            # Return exit code
            if success.nil?
              # Command not found
              warn "Error: Command not found: #{command_parts[0]}"
              warn "Please install the required gem or ensure it's in your PATH"
              1
            elsif success
              0
            else
              $?.exitstatus || 1
            end
          end
        end
      end
    end
  end
end
