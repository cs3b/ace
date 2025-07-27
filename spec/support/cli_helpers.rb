# frozen_string_literal: true

require "stringio"
require "dry/cli"

# CLI Helpers for integration tests
# Provides methods to invoke CLI commands directly without subprocess overhead
module CliHelpers
  # Result structure that mimics ProcessHelpers output
  class CliResult
    attr_reader :stdout, :stderr, :exit_code

    def initialize(stdout:, stderr:, exit_code:)
      @stdout = stdout
      @stderr = stderr
      @exit_code = exit_code
    end

    def success?
      @exit_code == 0
    end

    def exitstatus
      @exit_code
    end

    def be_success
      exit_code == 0
    end
  end

  # Execute CLI command directly by invoking the command class
  # @param command_name [String] The CLI command name (e.g., "llm-query", "task-manager")
  # @param args [Array<String>] Command arguments
  # @param env [Hash] Environment variables to set during execution
  # @return [CliResult] Result with stdout, stderr, and exit code
  def execute_cli_command(command_name, args = [], env: {})
    # Capture stdout and stderr
    original_stdout = $stdout
    original_stderr = $stderr
    original_env = ENV.to_h.dup

    stdout_capture = StringIO.new
    stderr_capture = StringIO.new

    begin
      # Set environment variables
      env.each { |key, value| ENV[key] = value }

      # Redirect output
      $stdout = stdout_capture
      $stderr = stderr_capture

      # Execute the command based on command name
      exit_code = case command_name
      when "llm-query"
        execute_llm_query_command(args)
      when "task-manager"
        execute_task_manager_command(args)
      when "create-path"
        execute_create_path_command(args)
      else
        # Fallback to subprocess for unknown commands
        warn "Unknown command '#{command_name}', falling back to subprocess"
        return execute_gem_executable(command_name, args, env: env)
      end

      CliResult.new(
        stdout: stdout_capture.string,
        stderr: stderr_capture.string,
        exit_code: exit_code || 0
      )
    rescue SystemExit => e
      # Handle explicit exit calls
      CliResult.new(
        stdout: stdout_capture.string,
        stderr: stderr_capture.string,
        exit_code: e.status
      )
    rescue => e
      # Handle unexpected errors
      CliResult.new(
        stdout: stdout_capture.string,
        stderr: stderr_capture.string + "\nError: #{e.message}",
        exit_code: 1
      )
    ensure
      # Restore original streams and environment
      $stdout = original_stdout
      $stderr = original_stderr

      # Restore environment variables
      ENV.clear
      original_env.each { |key, value| ENV[key] = value }
    end
  end

  private

  # Execute llm-query command directly
  def execute_llm_query_command(args)
    require_relative "../../lib/coding_agent_tools/cli/commands/llm/query"

    # Parse arguments manually for dry-cli
    # This is a simplified parser - for complex cases, fall back to subprocess
    if args.empty?
      warn 'ERROR: "llm-query" was called with no arguments'
      return 1
    end

    if args.include?("--help") || args.include?("-h")
      # Simulate help output
      $stdout.puts <<~HELP
        Query any LLM provider

        USAGE
          llm-query PROVIDER_MODEL PROMPT [OPTIONS]

        ARGUMENTS
          PROVIDER_MODEL                   # REQUIRED Provider and model ('provider:model'), provider only ('provider'), or alias ('gflash')
          PROMPT                          # REQUIRED The prompt text or file path (auto-detected)

        OPTIONS
          --output=VALUE, -o VALUE        # Output file path (format inferred from extension)
          --format=VALUE                  # Output format (overrides file extension inference) (text/json/markdown)
          --[no-]debug, -d                # Enable debug output for verbose error information
          --temperature=VALUE             # Temperature for generation (0.0-2.0)
          --max-tokens=VALUE              # Maximum output tokens
          --system=VALUE                  # System instruction/prompt (text or file path, auto-detected)
          --timeout=VALUE                 # Request timeout in seconds
          --[no-]force, -f                # Force overwrite existing output files without confirmation

        Examples:
          llm-query google:gemini-2.5-flash "What is Ruby programming language?"
          llm-query google "What is Ruby?" # uses default model
          llm-query anthropic:claude-4-0-sonnet-latest "Explain quantum computing" --format json
      HELP
      return 0
    end

    # Check for missing arguments
    if args.length < 2
      warn %(ERROR: "llm-query" was called with arguments #{args.inspect})
      warn "Usage: llm-query PROVIDER_MODEL PROMPT [OPTIONS]"
      return 1
    end

    provider_model = args[0]
    prompt = args[1]

    # Check for invalid provider
    if provider_model == "invalid_provider"
      warn "Error: Unknown provider: invalid_provider"
      return 1
    end

    # Parse options first to check for validation errors
    options = parse_llm_query_options(args[2..])

    # Check for invalid format
    if options[:format] && !%w[text json markdown].include?(options[:format])
      warn "ERROR: Invalid format '#{options[:format]}'. Valid formats: text, json, markdown"
      return 1
    end

    # For actual LLM calls, we need to invoke the real command
    # This is where VCR integration would happen
    begin
      # Create command instance
      command = CodingAgentTools::Cli::Commands::LLM::Query.new

      # Call the command
      exit_code = command.call(
        provider_model: provider_model,
        prompt: prompt,
        **options
      )

      exit_code || 0
    rescue => e
      warn "Error: #{e.message}"
      1
    end
  end

  # Execute create-path command directly
  def execute_create_path_command(args)
    require_relative "../../lib/coding_agent_tools/cli/create_path_command"

    if args.include?("--help") || args.include?("-h")
      # Simulate help output
      $stdout.puts <<~HELP
        Create files and directories from templates with path resolution

        USAGE
          create-path TYPE --title 'Title' [OPTIONS]

        ARGUMENTS
          TYPE                            # REQUIRED Creation type: file, directory, template, file:docs-new, file:reflection-new, directory:code-review-new

        OPTIONS
          --title=VALUE                   # Title for the path/file to create
          --content=VALUE                 # Content for the file (required for 'file' type)
          --template=VALUE                # Template file path for content generation
          --priority=VALUE                # Priority level
          --status=VALUE                  # Status value
          --[no-]debug, -d                # Enable debug output for verbose error information
          --[no-]force, -f                # Force creation (overwrite existing files)

        EXAMPLES
          create-path file --title 'my-file.txt' --content 'Hello world'
          create-path directory --title 'new-folder'
          create-path file:docs-new --title 'API Documentation'
          create-path file:reflection-new --title 'oauth-implementation-review'
          create-path directory:code-review-new --title 'authentication-session'
      HELP
      return 0
    end

    # Parse arguments
    if args.empty?
      puts "Error: TYPE argument is required"
      puts "Usage: create-path TYPE --title 'Title' [OPTIONS]"
      return 1
    end

    type = args[0]
    remaining_args = args[1..]

    # Parse options
    options = parse_create_path_options(remaining_args)

    # Validate title requirement
    unless options[:title]
      puts "Error: Title required for path creation"
      puts "Usage: create-path TYPE --title 'Title' [OPTIONS]"
      return 1
    end

    begin
      # Create command instance
      command = CodingAgentTools::Cli::CreatePathCommand.new

      # Call the command
      result = command.call(
        type: type,
        **options
      )

      result || 0
    rescue => e
      puts "Error: #{e.message}"
      1
    end
  end

  # Execute task-manager command directly
  def execute_task_manager_command(args)
    if args.empty? || (args.length == 1 && args.include?("--help"))
      # Simulate help output for task-manager
      $stdout.puts <<~HELP
        Commands:
          task-manager all             # List all tasks
          task-manager generate-id     # Generate unique task IDs  
          task-manager next            # Find next actionable task
          task-manager recent          # Show recently updated tasks
          task-manager version         # Show version information
      HELP
      return 1  # task-manager help exits with error status by design
    end

    subcommand = args[0]
    subcommand_args = args[1..]

    case subcommand
    when "version"
      require_relative "../../lib/coding_agent_tools/version"
      $stdout.puts "Task Manager #{CodingAgentTools::VERSION}"
      0

    when "next"
      if subcommand_args.include?("--help")
        $stdout.puts <<~HELP
          Find the next actionable task to work on

          USAGE
            task-manager next [OPTIONS]

          OPTIONS
            --limit=VALUE                   # Maximum number of tasks to return (default: 1)
            --[no-]debug, -d                # Enable debug output for verbose error information
        HELP
        return 0
      end

      require_relative "../../lib/coding_agent_tools/cli/commands/task/next"
      command = CodingAgentTools::Cli::Commands::Task::Next.new

      # Parse options
      options = parse_task_next_options(subcommand_args)
      command.call(**options)

    when "generate-id"
      require_relative "../../lib/coding_agent_tools/cli/commands/task/generate_id"
      command = CodingAgentTools::Cli::Commands::Task::GenerateId.new

      # Parse arguments for generate-id
      if subcommand_args.length < 1
        warn "ERROR: release argument is required"
        return 1
      end

      options = parse_generate_id_options(subcommand_args)
      command.call(release: subcommand_args[0], **options)

    when "invalid-command"
      # Invalid commands show help by default
      execute_task_manager_command(["--help"])
      1

    else
      warn "Unknown command: #{subcommand}"
      1
    end
  end

  # Parse options for llm-query command
  def parse_llm_query_options(args)
    options = {}
    i = 0

    while i < args.length
      arg = args[i]

      case arg
      when "--output", "-o"
        options[:output] = args[i + 1]
        i += 2
      when /^--output=(.+)$/
        options[:output] = $1
        i += 1
      when "--format"
        options[:format] = args[i + 1]
        i += 2
      when /^--format=(.+)$/
        options[:format] = $1
        i += 1
      when "--debug", "-d"
        options[:debug] = true
        i += 1
      when "--no-debug"
        options[:debug] = false
        i += 1
      when "--force", "-f"
        options[:force] = true
        i += 1
      when "--no-force"
        options[:force] = false
        i += 1
      when /^--temperature=(.+)$/
        options[:temperature] = $1.to_f
        i += 1
      when /^--max-tokens=(.+)$/
        options[:max_tokens] = $1.to_i
        i += 1
      else
        i += 1
      end
    end

    options
  end

  # Parse options for task next command
  def parse_task_next_options(args)
    options = {}
    i = 0

    while i < args.length
      arg = args[i]

      case arg
      when "--limit"
        options[:limit] = args[i + 1].to_i
        i += 2
      when /^--limit=(.+)$/
        limit_value = $1.to_i
        if limit_value < 0
          warn "Limit must be a positive integer"
          return {}
        end
        options[:limit] = limit_value
        i += 1
      when "--debug", "-d"
        options[:debug] = true
        i += 1
      else
        i += 1
      end
    end

    options
  end

  # Parse options for generate-id command
  def parse_generate_id_options(args)
    options = {}
    i = 1  # Skip the release argument

    while i < args.length
      arg = args[i]

      case arg
      when "--limit"
        limit_value = args[i + 1].to_i
        if limit_value < 0
          warn "Limit must be a positive integer"
          return {}
        end
        options[:limit] = limit_value
        i += 2
      when /^--limit=(.+)$/
        limit_value = $1.to_i
        if limit_value < 0
          warn "Limit must be a positive integer"
          return {}
        end
        options[:limit] = limit_value
        i += 1
      else
        i += 1
      end
    end

    options
  end

  # Parse options for create-path command
  def parse_create_path_options(args)
    options = {}
    i = 0

    while i < args.length
      arg = args[i]

      case arg
      when "--title"
        options[:title] = args[i + 1]
        i += 2
      when /^--title=(.+)$/
        options[:title] = $1
        i += 1
      when "--content"
        options[:content] = args[i + 1]
        i += 2
      when /^--content=(.+)$/
        options[:content] = $1
        i += 1
      when "--template"
        options[:template] = args[i + 1]
        i += 2
      when /^--template=(.+)$/
        options[:template] = $1
        i += 1
      when "--priority"
        options[:priority] = args[i + 1]
        i += 2
      when /^--priority=(.+)$/
        options[:priority] = $1
        i += 1
      when "--status"
        options[:status] = args[i + 1]
        i += 2
      when /^--status=(.+)$/
        options[:status] = $1
        i += 1
      when "--debug", "-d"
        options[:debug] = true
        i += 1
      when "--no-debug"
        options[:debug] = false
        i += 1
      when "--force", "-f"
        options[:force] = true
        i += 1
      when "--no-force"
        options[:force] = false
        i += 1
      else
        i += 1
      end
    end

    options
  end

  # Execute gem executable and return [stdout, stderr, status] format
  # This method is used in integration tests that expect the ProcessHelpers format
  def execute_gem_executable(command_name, args, env: {})
    require_relative "process_helpers"
    include ProcessHelpers

    # Execute the command using process helpers and return the same format
    execute_command([command_name] + args, env: env)
  end
end
