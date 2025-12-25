# frozen_string_literal: true

require "thor"

module Ace
  module Git
    # Thor CLI for ace-git
    class CLI < Thor
      def self.exit_on_failure?
        true
      end

      # Override banner for better formatting
      def self.banner(command, _namespace = nil, _subcommand = false)
        return "#{basename} diff [RANGE] [OPTIONS]" if command.name == "diff"

        "#{basename} #{command.usage}"
      end

      # Override help to add examples section
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "Magic Range Routing:"
        shell.say "  Git ranges are auto-routed to 'diff' command - no need to type 'diff':"
        shell.say "    ace-git HEAD~5..HEAD     → ace-git diff HEAD~5..HEAD"
        shell.say "    ace-git origin/main...   → ace-git diff origin/main..."
        shell.say "  Recognized patterns: .. / ... / ~ / ^ / HEAD / @{}"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-git                                # Smart diff (unstaged or branch)"
        shell.say "  ace-git HEAD~5..HEAD                   # Last 5 commits (magic routing)"
        shell.say "  ace-git HEAD~5..HEAD --format summary  # With options"
        shell.say "  ace-git origin/main...HEAD --paths 'lib/**/*.rb'"
        shell.say "  ace-git status                         # Branch + PR info"
        shell.say "  ace-git pr 123                         # PR details"
      end

      desc "diff [RANGE]", "Generate git diff with filtering (default command)"
      long_desc <<~DESC
        Generate git diff with configurable filtering and formatting.

        SYNTAX:
          ace-git [RANGE] [OPTIONS]
          ace-git diff [RANGE] [OPTIONS]

        RANGE:
          Optional git range specification:
          - HEAD~N..HEAD     Last N commits
          - origin/main..HEAD  Changes since main
          - commit1..commit2   Between two commits
          - origin/main...HEAD Three-dot (merge-base)

        EXAMPLES:

          # Basic usage (smart defaults)
          $ ace-git                          # Unstaged changes or branch diff
          $ ace-git diff                     # Same as above

          # Range with options (combining RANGE + OPTIONS)
          $ ace-git HEAD~5..HEAD --format summary
          $ ace-git origin/main...HEAD --paths "lib/**/*.rb"
          $ ace-git HEAD~10..HEAD --exclude "test/**/*" --output changes.diff

          # Time-based filtering
          $ ace-git --since "7d"             # Last 7 days
          $ ace-git --since "1 week ago"     # Same as above
          $ ace-git HEAD~20..HEAD --since "2025-01-01"

          # Path filtering (glob patterns)
          $ ace-git --paths "lib/**/*.rb" "src/**/*.js"
          $ ace-git --exclude "test/**/*" "vendor/**/*"

          # Output options
          $ ace-git --format summary         # Human-readable summary
          $ ace-git --output changes.diff    # Save to file
          $ ace-git --raw                    # Raw unfiltered diff

        CONFIGURATION:

          Global config:  ~/.ace/git/config.yml
          Project config: .ace/git/config.yml
          Example:        ace-git/.ace.example/git/config.yml

        OUTPUT:

          By default, diff is printed to stdout. Use --output to save to file.
          Exit code: 0 (success), 1 (error)
      DESC
      option :format, type: :string, aliases: "-f", default: "diff",
                      desc: "Output format: diff, summary"
      option :since, type: :string, aliases: "-s",
                     desc: "Changes since date/duration (e.g., '7d', '1 week ago')"
      option :paths, type: :array, aliases: "-p",
                     desc: "Include only these glob patterns"
      option :exclude, type: :array, aliases: "-e",
                       desc: "Exclude these glob patterns"
      option :output, type: :string, aliases: "-o",
                      desc: "Write diff to file instead of stdout"
      option :config, type: :string, aliases: "-c",
                      desc: "Load config from specific file"
      option :raw, type: :boolean, default: false,
                   desc: "Raw unfiltered output (no exclusions)"
      def diff(range = nil)
        # Handle --help/-h passed as range argument
        if range == "--help" || range == "-h"
          invoke :help, ["diff"]
          return 0
        end

        require_relative "commands/diff_command"
        Commands::DiffCommand.new.execute(range, options)
      rescue Ace::Git::Error => e
        warn "Error: #{e.message}"
        1
      end

      desc "status", "Show repository context (branch, PR, activity)"
      long_desc <<~DESC
        Display comprehensive repository context including current branch,
        associated PR information, and detected task pattern.

        EXAMPLES:

          # Full context output
          $ ace-git status

          # JSON output
          $ ace-git status --format json

          # Include PR diff in output
          $ ace-git status --with-diff

          # Skip PR lookups (faster, no network)
          $ ace-git status --no-pr

          # Show more recent commits
          $ ace-git status --commits 5

        OUTPUT:

          Markdown-formatted context including:
          - Current branch and remote tracking status
          - Git status (working tree changes)
          - Recent commits
          - Current PR metadata (if found)
          - PR activity (recently merged and open PRs)
      DESC
      option :format, type: :string, aliases: "-f", default: "markdown",
                      desc: "Output format: markdown, json"
      option :with_diff, type: :boolean, default: false,
                         desc: "Include PR diff in output"
      option :no_pr, type: :boolean, default: false, aliases: "-n",
                     desc: "Skip all PR lookups (faster, no network)"
      option :commits, type: :numeric, aliases: "-c",
                       desc: "Number of recent commits to show (0 to disable, default: config)"
      def status
        require_relative "commands/context_command"
        Commands::ContextCommand.new.execute(options)
      rescue Ace::Git::Error => e
        warn "Error: #{e.message}"
        1
      end

      desc "branch", "Show current branch information"
      long_desc <<~DESC
        Display current branch name and remote tracking status.

        EXAMPLES:

          $ ace-git branch
          # Output: 140-feature-name (tracking: origin/140-feature-name)

          $ ace-git branch --format json
          # Output: {"name":"140-feature-name","tracking":"origin/140-feature-name"}
      DESC
      option :format, type: :string, aliases: "-f", default: "text",
                      desc: "Output format: text, json"
      def branch
        require_relative "commands/branch_command"
        Commands::BranchCommand.new.execute(options)
      rescue Ace::Git::Error => e
        warn "Error: #{e.message}"
        1
      end

      desc "pr [NUMBER]", "Show PR information"
      long_desc <<~DESC
        Fetch and display PR metadata using GitHub CLI.

        NUMBER:
          Optional PR number. If not provided, attempts to detect from current branch.

        FORMATS:
          - Simple number: 123
          - Qualified: owner/repo#456
          - GitHub URL: https://github.com/owner/repo/pull/789

        EXAMPLES:

          # Auto-detect PR from current branch
          $ ace-git pr

          # Specific PR number
          $ ace-git pr 123

          # Cross-repository PR
          $ ace-git pr owner/repo#456

          # JSON output
          $ ace-git pr --format json

        REQUIREMENTS:

          GitHub CLI (gh) must be installed and authenticated.
          Install: brew install gh
          Auth: gh auth login
      DESC
      option :format, type: :string, aliases: "-f", default: "markdown",
                      desc: "Output format: markdown, json"
      option :with_diff, type: :boolean, default: false,
                         desc: "Include PR diff in output"
      def pr(number = nil)
        require_relative "commands/pr_command"
        Commands::PrCommand.new.execute(number, options)
      rescue Ace::Git::Error => e
        warn "Error: #{e.message}"
        1
      end

      desc "version", "Show version"
      def version
        puts Ace::Git::VERSION
        0
      end

      map %w[-v --version] => :version

      default_task :diff

      # Catch "unknown commands" that might be git ranges (e.g., HEAD~1..HEAD)
      # and treat them as the range argument for the default diff command.
      #
      # This is a "magic" UX feature - documented in usage.md.
      # The pattern is restrictive to avoid false positives.
      def method_missing(method_name, *args, &block)
        method_str = method_name.to_s

        # Only treat as git range if it matches specific git range patterns:
        # - Contains range operators: .. or ...
        # - Contains ref modifiers: ~ or ^ (with optional number)
        # - Exact match for HEAD (case-sensitive)
        # - Contains @{} syntax for reflog
        if git_range_pattern?(method_str)
          invoke :diff, [method_str]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        git_range_pattern?(method_name.to_s) || super
      end

      private

      # Check if a string looks like a git range or ref
      # More restrictive than the original pattern to avoid false positives
      # @param str [String] String to check
      # @return [Boolean] True if it looks like a git range
      def git_range_pattern?(str)
        # Must match one of these specific patterns:
        # 1. Contains range operators (.., ...)
        # 2. Contains ref modifiers (~, ^) with optional number
        # 3. Is exactly "HEAD"
        # 4. Contains @{} reflog syntax
        # 5. Starts with a known remote/branch pattern and contains range operator
        return true if str.match?(/\.\.\.?/)           # Range operators: .. or ...
        return true if str.match?(/[~^]\d*/)           # Ref modifiers: ~, ~2, ^, ^2
        return true if str == "HEAD"                   # Exact HEAD match
        return true if str.match?(/@\{/)               # Reflog: @{1}, @{yesterday}

        false
      end
    end
  end
end
