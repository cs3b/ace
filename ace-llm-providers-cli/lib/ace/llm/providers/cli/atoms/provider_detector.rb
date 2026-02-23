# frozen_string_literal: true

require "open3"

module Ace
  module Llm
    module Providers
      module Cli
        module Atoms
          # Detects whether a CLI tool is installed and retrieves its version
          class ProviderDetector
            # Check if a CLI tool is available on the system
            # @param cli_name [String] Name of the CLI tool
            # @return [Boolean] true if the tool is found in PATH
            def self.available?(cli_name)
              system("which", cli_name, out: File::NULL, err: File::NULL)
            end

            # Get the version of a CLI tool
            # @param check_cmd [Array<String>] Command to run for version check
            # @return [String] Version string or "Unknown"
            def self.version(check_cmd)
              stdout, _, status = Open3.capture3(*check_cmd)
              return "Unknown" unless status.success?

              extract_version(stdout)
            rescue Errno::ENOENT, Errno::EACCES
              "Unknown"
            end

            # Extract version number from command output
            # @param output [String] Raw command output
            # @return [String] Extracted version or first line
            def self.extract_version(output)
              if output =~ /(\d+\.\d+\.\d+)/
                $1
              elsif output =~ /v(\d+\.\d+)/
                $1
              else
                output.lines.first&.strip || "Unknown"
              end
            end
          end
        end
      end
    end
  end
end
