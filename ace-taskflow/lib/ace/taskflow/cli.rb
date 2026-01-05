# frozen_string_literal: true

require "ace/core/cli/base"

module Ace
  module Taskflow
    class CLI < Ace::Core::CLI::Base
      # class_options :quiet, :verbose, :debug inherited from Base

      # Additional class options for command-level OptionParser flags
      # These allow Thor to accept flags that are re-parsed by command classes
      # TODO: Full migration to Thor options (refactor command classes)
      class_option :json, type: :boolean, desc: "Output as JSON"
      class_option :markdown, type: :boolean, desc: "Output as Markdown (default)"
      class_option :status, type: :string, desc: "Filter by status"
      class_option :stats, type: :boolean, desc: "Show statistics"
      class_option :tree, type: :boolean, desc: "Show tree structure"
      class_option :format, type: :string, desc: "Output format"
      class_option :limit, type: :numeric, desc: "Limit results"
      class_option :all, type: :boolean, desc: "Show all items"
      class_option :recently_done_limit, type: :numeric, desc: "Max recently done tasks to show"
      class_option :up_next_limit, type: :numeric, desc: "Max up next tasks to show"
      class_option :include_drafts, type: :boolean, desc: "Include draft tasks in Up Next"
      class_option :include_activity, type: :boolean, desc: "Include task activity section"
      class_option :output, type: :string, aliases: "-o", desc: "Output file path"

      default_task :task

      # Clear per-command caches at the start of each CLI invocation
      def self.start(given_args = ARGV, config = {})
        clear_caches!
        super(given_args, config)
      end

      # Override help to add task reference system section
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "Default Command Routing:"
        shell.say "  Unknown commands are auto-routed to 'task' - task numbers can be passed directly:"
        shell.say "    ace-taskflow 114                   → ace-taskflow task 114"
        shell.say "    ace-taskflow 114 done              → ace-taskflow task done 114"
        shell.say "  No need to type 'task' explicitly for task operations"
        shell.say ""
        shell.say "Task Reference System:"
        shell.say "  Tasks can be referenced by multiple formats - ace-taskflow handles resolution:"
        shell.say "    114           → Task number in current release"
        shell.say "    task.114      → Task ID format"
        shell.say "    v.0.9.0+114  → Full task reference"
        shell.say "  Use 'ace-taskflow task <ref>' for any reference format"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-taskflow task 114                # Find by number"
        shell.say "  ace-taskflow 114                     # Same as above (routing)"
        shell.say "  ace-taskflow task done 114           # Mark complete"
        shell.say "  ace-taskflow tasks --status pending  # List pending"
      end

      desc "idea [ACTION] [ARGS]", "Operations on single ideas"
      long_desc <<~DESC
        Operations on single ideas.

        SYNTAX:
          ace-taskflow idea [ACTION] [ARGS]

        EXAMPLES:

          # Show next idea
          $ ace-taskflow idea

          # Create new idea
          $ ace-taskflow idea create 'Add caching'

          # Prioritize ideas
          $ ace-taskflow idea prioritize

        CONFIGURATION:

          Global config:  ~/.ace/taskflow/config.yml
          Project config: .ace/taskflow/config.yml
          Example:        ace-taskflow/.ace-defaults/taskflow/config.yml

        OUTPUT:

          Idea details printed to stdout
          Exit codes: 0 (success), 1 (error)
      DESC
      def idea(*args)
        # Handle --help/-h passed as first argument
        if args.first == "--help" || args.first == "-h"
          invoke :help, ["idea"]
          return 0
        end
        require_relative "commands/idea_command"
        Commands::IdeaCommand.new.execute(args)
      end

      desc "ideas [ACTION] [ARGS]", "Browse and list multiple ideas"
      long_desc <<~DESC
        Browse and list multiple ideas.

        Examples:
          ace-taskflow ideas --all             # List all ideas
      DESC
      def ideas(*args)
        # Handle --help/-h passed as first argument
        if args.first == "--help" || args.first == "-h"
          invoke :help, ["ideas"]
          return 0
        end
        require_relative "commands/ideas_command"
        Commands::IdeasCommand.new.execute(args)
      end

      desc "task [REF] [ACTION]", "Operations on single tasks"
      long_desc <<~DESC
        Operations on single tasks.

        SYNTAX:
          ace-taskflow task [REF] [ACTION] [ARGS]

        EXAMPLES:

          # Show next task
          $ ace-taskflow task

          # Show task by any reference format
          $ ace-taskflow task 114               # By number
          $ ace-taskflow task task.114          # Task ID format
          $ ace-taskflow task v.0.9.0+114      # Full reference

          # Mark task as done
          $ ace-taskflow task done 114

          # Show task status
          $ ace-taskflow task status 114

        CONFIGURATION:

          Global config:  ~/.ace/taskflow/config.yml
          Project config: .ace/taskflow/config.yml
          Example:        ace-taskflow/.ace-defaults/taskflow/config.yml

        OUTPUT:

          Task details printed to stdout
          Exit codes: 0 (success), 1 (error)

        TASK REFERENCE SYSTEM:

          Tasks can be referenced by multiple formats:
          114           → Task number in current release
          task.114      → Task ID format
          v.0.9.0+114  → Full task reference

          ace-taskflow handles resolution automatically
      DESC
      def task(*args)
        # Handle --help/-h passed as first argument
        if args.first == "--help" || args.first == "-h"
          invoke :help, ["task"]
          return 0
        end
        require_relative "commands/task_command"
        Commands::TaskCommand.new(args, options).execute
      end

      desc "tasks [ACTION] [ARGS]", "Browse and list multiple tasks"
      long_desc <<~DESC
        Browse and list multiple tasks.

        Examples:
          ace-taskflow tasks --status pending  # List pending tasks
      DESC
      def tasks(*args)
        # Handle --help/-h passed as first argument
        if args.first == "--help" || args.first == "-h"
          invoke :help, ["tasks"]
          return 0
        end
        require_relative "commands/tasks_command"
        Commands::TasksCommand.new.execute(args, options)
      end

      desc "release [ACTION] [ARGS]", "Operations on single releases"
      long_desc <<~DESC
        Operations on single releases.

        Examples:
          ace-taskflow release                 # Show active release
          ace-taskflow release start           # Start a new release
      DESC
      def release(*args)
        require_relative "commands/release_command"
        Commands::ReleaseCommand.new.execute(args)
      end

      desc "releases [ACTION] [ARGS]", "Browse and list multiple releases"
      long_desc <<~DESC
        Browse and list multiple releases.

        Examples:
          ace-taskflow releases --stats        # Show release statistics
      DESC
      def releases(*args)
        require_relative "commands/releases_command"
        Commands::ReleasesCommand.new.execute(args, options)
      end

      desc "retro [ACTION] [ARGS]", "Operations on single retrospective notes"
      long_desc <<~DESC
        Operations on single retrospective notes.

        Examples:
          ace-taskflow retro create 'Session learnings'
      DESC
      def retro(*args)
        require_relative "commands/retro_command"
        Commands::RetroCommand.new.execute(args)
      end

      desc "retros [ACTION] [ARGS]", "Browse and list multiple retrospective notes"
      long_desc <<~DESC
        Browse and list multiple retrospective notes.

        Examples:
          ace-taskflow retros --all            # List all retros (including done)
      DESC
      def retros(*args)
        require_relative "commands/retros_command"
        Commands::RetrosCommand.new.execute(args)
      end

      desc "status", "Show current taskflow status and activity"
      long_desc <<~DESC
        Show current taskflow status including release, task, and activity.

        SYNTAX:
          ace-taskflow status [OPTIONS]

        EXAMPLES:

          # Show status
          $ ace-taskflow status
          $ ace-taskflow context

          # JSON output
          $ ace-taskflow status --json

        CONFIGURATION:

          Global config:  ~/.ace/taskflow/config.yml
          Project config: .ace/taskflow/config.yml
          Example:        ace-taskflow/.ace-defaults/taskflow/config.yml

        OUTPUT:

          Shows: Release info, current task, task activity
          Exit codes: 0 (success), 1 (error)
      DESC
      map %w[context] => :status
      def status(*args)
        require_relative "commands/status_command"
        Commands::StatusCommand.new.execute(args, options)
      end

      desc "doctor", "Run health checks and auto-fix issues"
      long_desc <<~DESC
        Run health checks and auto-fix issues.
      DESC
      def doctor(*args)
        require_relative "commands/doctor_command"
        Commands::DoctorCommand.new.execute(args)
      end

      desc "migrate-paths [PATHS]", "Migrate folder structure to new naming convention"
      long_desc <<~DESC
        Migrate folder structure to new naming convention.
      DESC
      def migrate_paths(*args)
        require_relative "cli/migrate_paths"
        Commands::MigratePaths.run(args)
      end

      desc "migrate [ACTION]", "Migrate folder structure to new naming convention"
      long_desc <<~DESC
        Migrate folder structure to new naming convention.
      DESC
      def migrate(*args)
        require_relative "commands/migrate_command"
        Commands::MigrateCommand.new.execute(args)
      end

      desc "config", "Show current configuration"
      long_desc <<~DESC
        Show current ace-taskflow configuration.
      DESC
      def config(*args)
        require_relative "molecules/config_loader"
        config_loader = Molecules::ConfigLoader.load

        puts "ace-taskflow Configuration:"
        puts "=" * 50
        puts "Root directory: #{config_loader['root']}"
        puts "Task directory: #{config_loader['task_dir']}"
        puts "Active strategy: #{config_loader['active_strategy']}"
        puts "Allow multiple active: #{config_loader['allow_multiple_active']}"
        puts ""
        puts "References:"
        puts "  Allow qualified: #{config_loader['references']['allow_qualified']}"
        puts "  Allow cross-release: #{config_loader['references']['allow_cross_release']}"
        puts ""
        puts "Defaults:"
        puts "  Idea location: #{config_loader['defaults']['idea_location']}"
        puts "  Task location: #{config_loader['defaults']['task_location']}"
        0
      end

      desc "version", "Show version"
      long_desc <<~DESC
        Display the current version of ace-taskflow.

        EXAMPLES:

          $ ace-taskflow version
          $ ace-taskflow --version
      DESC
      version_command "ace-taskflow", Ace::Taskflow::VERSION

      # Handle unknown commands as arguments to the default 'task' command
      def method_missing(command, *args)
        invoke :task, [command.to_s] + args
      end
      # respond_to_missing? inherited from Ace::Core::CLI::Base

      # Clear per-command caches in loaders
      # Called at the start of each CLI invocation to ensure fresh data
      def self.clear_caches!
        require_relative "molecules/task_loader"
        require_relative "molecules/release_resolver"

        Molecules::TaskLoader.clear_cache!
        Molecules::ReleaseResolver.clear_cache!
      end
    end
  end
end
