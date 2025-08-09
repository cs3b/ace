# frozen_string_literal: true

require_relative '../system_command_executor'

module CodingAgentTools
  module Atoms
    module Search
      # ToolAvailabilityChecker provides detection of required external tools
      # This is an atom - it has no internal dependencies and provides basic functionality
      class ToolAvailabilityChecker
        # Required external tools for search functionality
        REQUIRED_TOOLS = %w[rg fd].freeze
        OPTIONAL_TOOLS = %w[fzf git].freeze

        def initialize
          @executor = CodingAgentTools::Atoms::SystemCommandExecutor.new
        end

        # Check if all required tools are available
        # @return [Hash] Status and missing tools information
        def check_all_tools
          missing_required = check_required_tools
          missing_optional = check_optional_tools

          {
            success: missing_required.empty?,
            missing_required: missing_required,
            missing_optional: missing_optional,
            available_tools: available_tools,
            install_instructions: generate_install_instructions(missing_required + missing_optional)
          }
        end

        # Check if a specific tool is available
        # @param tool [String] Tool name to check
        # @return [Boolean] True if tool is available
        def tool_available?(tool)
          @executor.command_available?(tool)
        end

        # Get installation instructions for a tool
        # @param tool [String] Tool name
        # @return [String] Installation instructions
        def install_instruction(tool)
          case tool
          when 'rg', 'ripgrep'
            install_ripgrep_instruction
          when 'fd'
            install_fd_instruction
          when 'fzf'
            install_fzf_instruction
          when 'git'
            install_git_instruction
          else
            "Tool '#{tool}' is not recognized. Please install manually."
          end
        end

        # Get all available tools from the required and optional lists
        # @return [Array<String>] List of available tools
        def available_tools
          (REQUIRED_TOOLS + OPTIONAL_TOOLS).select { |tool| tool_available?(tool) }
        end

        # Get missing required tools
        # @return [Array<String>] List of missing required tools
        def check_required_tools
          REQUIRED_TOOLS.reject { |tool| tool_available?(tool) }
        end

        # Get missing optional tools
        # @return [Array<String>] List of missing optional tools
        def check_optional_tools
          OPTIONAL_TOOLS.reject { |tool| tool_available?(tool) }
        end

        private

        def generate_install_instructions(missing_tools)
          return {} if missing_tools.empty?

          instructions = {}
          missing_tools.each do |tool|
            instructions[tool] = install_instruction(tool)
          end
          instructions
        end

        def install_ripgrep_instruction
          <<~INSTRUCTION
            Install ripgrep (rg):
            - macOS: brew install ripgrep
            - Ubuntu/Debian: apt install ripgrep
            - Arch Linux: pacman -S ripgrep
            - Windows: cargo install ripgrep
            - From source: https://github.com/BurntSushi/ripgrep
          INSTRUCTION
        end

        def install_fd_instruction
          <<~INSTRUCTION
            Install fd:
            - macOS: brew install fd
            - Ubuntu/Debian: apt install fd-find
            - Arch Linux: pacman -S fd
            - Windows: cargo install fd-find
            - From source: https://github.com/sharkdp/fd
          INSTRUCTION
        end

        def install_fzf_instruction
          <<~INSTRUCTION
            Install fzf:
            - macOS: brew install fzf
            - Ubuntu/Debian: apt install fzf
            - Arch Linux: pacman -S fzf
            - Windows: choco install fzf
            - From source: https://github.com/junegunn/fzf
          INSTRUCTION
        end

        def install_git_instruction
          <<~INSTRUCTION
            Install git:
            - macOS: brew install git (or use Xcode Command Line Tools)
            - Ubuntu/Debian: apt install git
            - Arch Linux: pacman -S git
            - Windows: Download from https://git-scm.com/
            - Most systems have git pre-installed
          INSTRUCTION
        end
      end
    end
  end
end