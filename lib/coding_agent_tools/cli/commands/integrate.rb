# frozen_string_literal: true

require "dry/cli"
require "fileutils"
require "yaml"
require "pathname"
require "time"

module CodingAgentTools
  module Cli
    module Commands
      class Integrate < Dry::CLI::Command
        desc "Integrate AI assistant development environment"

        # Positional argument for integration type
        argument :type, required: false, default: "claude",
          desc: "Integration type (claude, opencode)"

        # Module selection flags (all default to nil for smart detection)
        option :agents, type: :boolean, default: nil,
          desc: "Include agent definitions"
        option :commands, type: :boolean, default: nil,
          desc: "Include command files"
        option :dotfiles, type: :boolean, default: nil,
          desc: "Include configuration dotfiles"
        option :docs, type: :boolean, default: nil,
          desc: "Update documentation"
        option :submodules, type: :boolean, default: nil,
          desc: "Setup git submodules"
        option :config, type: :boolean, default: nil,
          desc: "Include config files"
        option :hooks, type: :boolean, default: nil,
          desc: "Include git hooks"

        # Negative flags for exclusion
        option :no_agents, type: :boolean, default: false,
          desc: "Exclude agent definitions"
        option :no_commands, type: :boolean, default: false,
          desc: "Exclude command files"
        option :no_dotfiles, type: :boolean, default: false,
          desc: "Exclude configuration dotfiles"
        option :no_docs, type: :boolean, default: false,
          desc: "Skip documentation update"
        option :no_submodules, type: :boolean, default: false,
          desc: "Skip git submodules setup"
        option :no_config, type: :boolean, default: false,
          desc: "Exclude config files"
        option :no_hooks, type: :boolean, default: false,
          desc: "Exclude git hooks"

        # Other options
        option :force, type: :boolean, default: false,
          desc: "Force overwrite existing integration (creates backup)"
        option :no_backup, type: :boolean, default: false,
          desc: "Skip backup when using --force"
        option :dry_run, type: :boolean, default: false,
          desc: "Preview what would be done without making changes"
        option :verbose, type: :boolean, default: false,
          desc: "Show detailed output"

        def call(type: "claude", **options)
          @options = options
          @type = type
          @dry_run = options[:dry_run]
          @verbose = options[:verbose]
          @project_root = find_project_root

          # Validate integration type
          if type == "opencode"
            show_coming_soon("OpenCode")
            return
          elsif type != "claude"
            puts "❌ Unknown integration type '#{type}'. Available: claude, opencode"
            return
          end

          integration_type = type

          puts "🚀 Starting #{integration_type.capitalize} integration..."
          puts "   Mode: #{dry_run_mode}" if @dry_run

          # Load configuration hierarchy
          config = load_configuration
          unless config
            puts "❌ Could not load integration configuration"
            return
          end

          integration_config = config["integrations"][integration_type]
          unless integration_config && integration_config["status"] == "implemented"
            puts "❌ #{integration_type.capitalize} integration is not available"
            return
          end

          # Load user/project specific configuration
          user_config = load_user_configuration
          project_config = load_project_configuration

          # Check submodules unless explicitly skipped
          unless options[:no_submodules]
            check_and_setup_submodules(config["submodules"])
          end

          # Handle backup if force mode
          backup_path = nil
          if options[:force] && !options[:no_backup]
            backup_path = create_backup
          end

          # Determine components to integrate using new logic
          components = determine_modules(integration_config, project_config, user_config, options)

          # Perform integration
          success = integrate_components(integration_config, components, options[:force])

          if success
            puts "✅ #{integration_type.capitalize} integration complete!"
            puts "   Backup created at: #{backup_path}" if backup_path
          else
            puts "❌ Integration failed. Check errors above."
            restore_backup(backup_path) if backup_path && !@dry_run
          end
        end

        private

        def find_project_root
          current = Pathname.pwd
          while current.parent != current
            return current if (current + ".git").exist?
            current = current.parent
          end
          Pathname.pwd
        end

        def load_configuration
          config_paths = [
            @project_root + "dev-tools/config/integration.yml",
            @project_root + "config/integration.yml",
            Pathname.new(__dir__) + "../../../config/integration.yml"
          ]

          config_path = config_paths.find { |path| path.exist? }
          return nil unless config_path

          log "Loading configuration from: #{config_path}"
          YAML.load_file(config_path)
        rescue => e
          log "Error loading configuration: #{e.message}"
          nil
        end

        def check_and_setup_submodules(submodules_config)
          return unless submodules_config

          puts "✓ Checking submodules..."

          submodules_config.each do |name, config|
            submodule_path = @project_root + name

            # Check if submodule is properly initialized (directory exists with content)
            # A submodule is considered present if:
            # 1. The directory exists
            # 2. It has a .git file/directory
            # 3. It contains actual files (not just empty)
            if submodule_path.exist? &&
                (submodule_path + ".git").exist? &&
                !Dir.empty?(submodule_path.to_s)
              log "  ✓ #{name} present"
            else
              puts "  → #{name} missing or not initialized, setting up..."
              setup_submodule(name, config) unless @dry_run
            end
          end
        end

        def setup_submodule(name, config)
          url = config["url"]
          submodule_path = @project_root + name

          # Handle auto URL detection
          if url == "auto"
            # First, try to get URL from existing submodule config
            existing_url = `git config --get submodule.#{name}.url`.strip

            if !existing_url.empty?
              url = existing_url
              log "  → Using existing submodule URL: #{url}"
            else
              # Fall back to auto-generation based on origin URL
              origin_url = `git config --get remote.origin.url`.strip

              if origin_url =~ %r{github\.com[:/](.+?)(?:\.git)?$}
                repo_path = $1
                base_name = repo_path.sub(/\.git$/, "")

                # Generate URL based on submodule name pattern
                suffix = case name
                when "dev-taskflow"
                  "-taskflow"
                when "dev-handbook"
                  "-handbook"
                when "dev-tools"
                  "-tools"
                else
                  "-#{name}"
                end

                # Remove any existing suffix that matches and add the correct one
                base_name = base_name.sub(/-?(taskflow|handbook|tools|meta)$/, "")

                # Construct proper URL based on original format
                url = if origin_url.start_with?("git@")
                  "git@github.com:#{base_name}#{suffix}.git"
                else
                  "https://github.com/#{base_name}#{suffix}.git"
                end

                log "  → Auto-generated URL: #{url}"
              else
                log "Warning: Could not parse origin URL: #{origin_url}"
                return
              end
            end
          end

          branch = config["branch"] || "main"

          # Check if submodule is already registered in .git/modules but not initialized
          git_modules_path = @project_root + ".git/modules" + name
          if git_modules_path.exist?
            log "  → Found existing git directory for #{name}, attempting to reinitialize..."

            # Try to update and reinitialize the existing submodule
            if system("git submodule update --init #{name}")
              log "  ✓ Successfully reinitialized #{name}"
              return
            else
              log "  → Reinitialize failed, trying to remove and re-add..."
              # Remove the submodule completely and re-add
              system("git submodule deinit -f #{name}")
              system("git rm -f #{name}")
              system("rm -rf #{git_modules_path}")
              FileUtils.rm_rf(submodule_path) if submodule_path.exist?
            end
          end

          # Try GitHub CLI first (only if URL looks like GitHub)
          if system("which gh > /dev/null 2>&1") && url.include?("github.com")
            # Extract owner/repo from URL for gh CLI
            if url =~ %r{github\.com[:/](.+?)(?:\.git)?$}
              repo_path = $1.sub(/\.git$/, "")
              log "Using GitHub CLI to clone #{repo_path}"
              # Use proper gh CLI syntax with owner/repo format
              if system("gh repo clone #{repo_path} #{name} -- --branch #{branch}")
                # Add as submodule after successful clone
                system("git submodule add -f #{url} #{name}")
              else
                log "GitHub CLI clone failed, falling back to git"
                system("git submodule add -f -b #{branch} #{url} #{name}")
              end
            else
              log "Could not parse GitHub URL, using git directly"
              system("git submodule add -f -b #{branch} #{url} #{name}")
            end
          else
            log "Using git to add submodule"
            system("git submodule add -f -b #{branch} #{url} #{name}")
          end

          # Always try to update after adding
          system("git submodule update --init --recursive #{name}")
        end

        def create_backup
          return nil if @dry_run

          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          backup_dir = @project_root + ".claude.backup.#{timestamp}"

          puts "⚠ Creating backup at: #{backup_dir}"

          # Backup existing .claude directory
          claude_dir = @project_root + ".claude"
          if claude_dir.exist?
            FileUtils.cp_r(claude_dir, backup_dir)
          end

          # Backup existing .coding-agent directory
          coding_agent_dir = @project_root + ".coding-agent"
          if coding_agent_dir.exist?
            backup_coding_agent = backup_dir + ".coding-agent"
            FileUtils.mkdir_p(backup_dir) unless backup_dir.exist?
            FileUtils.cp_r(coding_agent_dir, backup_coding_agent)
          end

          backup_dir
        end

        def restore_backup(backup_path)
          return unless backup_path&.exist?

          puts "↩ Restoring from backup..."

          # Remove failed integration
          FileUtils.rm_rf(@project_root + ".claude")
          FileUtils.rm_rf(@project_root + ".coding-agent")

          # Restore from backup
          if (backup_path + ".claude").exist?
            FileUtils.cp_r(backup_path + ".claude", @project_root + ".claude")
          end

          if (backup_path + ".coding-agent").exist?
            FileUtils.cp_r(backup_path + ".coding-agent", @project_root + ".coding-agent")
          end
        end

        def load_user_configuration
          user_config_path = Pathname.new(ENV["XDG_CONFIG_HOME"] || "#{ENV["HOME"]}/.config") + "coding-agent-tools/integrate.yml"
          return {} unless user_config_path.exist?

          log "Loading user configuration from: #{user_config_path}"
          YAML.load_file(user_config_path) || {}
        rescue => e
          log "Error loading user configuration: #{e.message}"
          {}
        end

        def load_project_configuration
          project_config_path = @project_root + ".coding-agent/integrate.yml"
          return {} unless project_config_path.exist?

          log "Loading project configuration from: #{project_config_path}"
          YAML.load_file(project_config_path) || {}
        rescue => e
          log "Error loading project configuration: #{e.message}"
          {}
        end

        def determine_modules(integration_config, project_config, user_config, cli_options)
          all_modules = integration_config["components"].keys

          # Check for mixed positive and negative flags
          positive_flags = []
          negative_flags = []

          all_modules.each do |module_name|
            positive_value = cli_options[module_name.to_sym]
            negative_value = cli_options[:"no_#{module_name}"]

            positive_flags << module_name if positive_value == true
            negative_flags << module_name if negative_value == true
          end

          # Error if mixing positive and negative flags
          if positive_flags.any? && negative_flags.any?
            puts "❌ Cannot mix --module and --no-module flags."
            puts "   Use either positive flags to specify what to install,"
            puts "   or negative flags to specify what to skip."
            return []
          end

          # Determine modules based on flag patterns
          selected_modules = if positive_flags.any?
            # Positive flags only: Install ONLY specified modules
            puts "Installing ONLY: #{positive_flags.join(", ")}"
            positive_flags
          elsif negative_flags.any?
            # Negative flags only: Install all EXCEPT specified modules
            excluded = all_modules & negative_flags
            selected = all_modules - excluded
            puts "Installing all modules EXCEPT: #{excluded.join(", ")}"
            selected
          else
            # No flags: Use configuration or defaults
            modules_from_config = get_modules_from_config(project_config, user_config, @type)

            if modules_from_config.any?
              log "Using modules from configuration: #{modules_from_config.join(", ")}"
              modules_from_config
            else
              log "Using all available modules (default)"
              all_modules
            end
          end

          # Filter out any modules that don't exist in the integration config
          valid_modules = selected_modules & all_modules
          invalid_modules = selected_modules - all_modules

          if invalid_modules.any?
            puts "⚠ Warning: Ignoring unknown modules: #{invalid_modules.join(", ")}"
          end

          valid_modules
        end

        def get_modules_from_config(project_config, user_config, integration_type)
          # Project config takes precedence over user config
          modules = []

          # Try project config first
          if project_config.dig("integrations", integration_type, "modules")
            modules = project_config.dig("integrations", integration_type, "modules") || []
          elsif project_config.dig("default_modules")
            modules = project_config["default_modules"] || []
          end

          # Fall back to user config if no project config
          if modules.empty?
            if user_config.dig("integrations", integration_type, "modules")
              modules = user_config.dig("integrations", integration_type, "modules") || []
            elsif user_config.dig("default_modules")
              modules = user_config["default_modules"] || []
            end
          end

          modules
        end

        def integrate_components(integration_config, components, force)
          components_config = integration_config["components"]
          created_count = 0
          skipped_count = 0

          components.each do |component|
            config = components_config[component]
            next unless config

            puts "✓ Integrating #{component}..."

            case config["method"]
            when "symlink"
              created, skipped = create_symlinks(config["source"], config["target"], force)
              created_count += created
              skipped_count += skipped
            when "copy"
              created, skipped = copy_files(config["source"], config["target"], force)
              created_count += created
              skipped_count += skipped
            when "update"
              if update_documentation(config["source"], config["target"], force)
                created_count += 1
              else
                skipped_count += 1
              end
            end
          end

          puts "\n📊 Integration Summary:"
          puts "   Created: #{created_count} new components"
          puts "   Skipped: #{skipped_count} existing components" if skipped_count > 0

          true
        rescue => e
          puts "❌ Error during integration: #{e.message}"
          log e.backtrace.join("\n") if @verbose
          false
        end

        def create_symlinks(source_pattern, target_dir, force)
          created = 0
          skipped = 0

          source_path = @project_root + source_pattern
          target_path = @project_root + target_dir

          # Create target directory if it doesn't exist
          unless @dry_run
            FileUtils.mkdir_p(target_path) unless target_path.exist?
          end

          # Find all files to symlink
          source_files = if source_path.directory?
            Dir.glob(source_path + "*")
          else
            Dir.glob(source_path.to_s)
          end

          source_files.each do |source_file|
            source = Pathname.new(source_file)
            target = target_path + source.basename

            # Calculate relative path for symlink
            relative_path = source.relative_path_from(target_path)

            if target.exist? || target.symlink?
              if force
                log "  → Removing existing: #{target.basename}"
                FileUtils.rm_rf(target) unless @dry_run
              else
                log "  → Skipping existing: #{target.basename}"
                skipped += 1
                next
              end
            end

            log "  → Creating symlink: #{target.basename} -> #{relative_path}"
            unless @dry_run
              File.symlink(relative_path, target)
            end
            created += 1
          end

          [created, skipped]
        end

        def copy_files(source_pattern, target_dir, force)
          created = 0
          skipped = 0

          source_path = @project_root + source_pattern
          target_path = @project_root + target_dir

          # Find all files to copy
          source_files = if source_path.directory?
            Dir.glob(source_path + "**/*").select { |f| File.file?(f) }
          else
            Dir.glob(source_path.to_s).select { |f| File.file?(f) }
          end

          source_files.each do |source_file|
            source = Pathname.new(source_file)
            relative = source.relative_path_from(source_path.directory? ? source_path : source_path.parent)
            target = target_path + relative

            if target.exist?
              if force
                log "  → Overwriting: #{relative}"
                FileUtils.cp(source, target) unless @dry_run
                created += 1
              else
                log "  → Skipping existing: #{relative}"
                skipped += 1
              end
            else
              log "  → Copying: #{relative}"
              unless @dry_run
                FileUtils.mkdir_p(target.parent)
                FileUtils.cp(source, target)
              end
              created += 1
            end
          end

          [created, skipped]
        end

        def update_documentation(source_file, target_file, force)
          source_path = @project_root + source_file
          target_path = @project_root + target_file

          unless source_path.exist?
            log "  → Source documentation not found, creating template"
            unless @dry_run
              create_claude_md_template(target_path)
            end
            return true
          end

          if target_path.exist? && !force
            log "  → Documentation exists, skipping update"
            return false
          end

          log "  → Updating documentation: #{target_file}"
          unless @dry_run
            update_claude_md(source_path, target_path)
          end
          true
        end

        def create_claude_md_template(target_path)
          template = <<~MARKDOWN
            # CLAUDE.md
            
            This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
            
            ## Project Overview
            
            [Describe your project here]
            
            ## Agent Recommendations
            
            When working with specific tasks, use these specialized agents:
            
            ### Task Management
            - **`task-finder`** - Find and list tasks
            - **`task-creator`** - Create new task files
            
            ### Git Operations
            - **`git-all-commit`** - Commit all changes
            - **`git-files-commit`** - Commit specific files
            - **`git-review-commit`** - Review before commit
            
            ### Development Tools
            - **`lint-files`** - Lint and fix code issues
            - **`create-path`** - Create files/directories
            - **`search`** - Search code patterns
            
            ## Development Setup
            
            This project uses the Coding Agent Tools for development automation.
            Run `coding-agent-tools integrate --claude` to set up your environment.
          MARKDOWN

          File.write(target_path, template)
        end

        def update_claude_md(source_path, target_path)
          content = File.read(source_path)

          # Add agent recommendations if not present
          unless content.include?("## Agent Recommendations")
            agent_section = <<~MARKDOWN
              
              ## Agent Recommendations
              
              When working with specific tasks, use these specialized agents for focused, efficient execution:
              
              ### Task Management
              - **`task-finder`** - FIND tasks only - list, filter, discover next actionable tasks
              - **`task-creator`** - CREATE tasks only - generate task files with content and metadata
              - **`release-navigator`** - NAVIGATE releases - discover current/all releases, track recent activity
              
              ### Git Operations  
              - **`git-all-commit`** - COMMIT ALL changes - fast execution without file selection
              - **`git-files-commit`** - COMMIT SPECIFIC files - requires file list
              - **`git-review-commit`** - REVIEW then COMMIT - analyze changes before committing
              
              ### Development Tools
              - **`lint-files`** - LINT and FIX code quality - supports ruby, markdown, all types with autofix
              - **`create-path`** - CREATE files/directories - supports templates (NOT for tasks)
              - **`feature-research`** - RESEARCH gaps and missing features - outputs .fr.md reports
              - **`search`** - SEARCH code patterns and files - intelligent filtering across codebase
            MARKDOWN

            # Insert after project overview or at the end
            if content.include?("## ")
              first_section = content.index(/^## (?!Project Overview)/)
              if first_section
                content.insert(first_section, agent_section)
              else
                content += agent_section
              end
            else
              content += agent_section
            end
          end

          File.write(target_path, content)
        end

        def log(message)
          puts message if @verbose || @dry_run
        end

        def dry_run_mode
          @dry_run ? "DRY RUN (no changes will be made)" : "LIVE"
        end

        def show_coming_soon(integration_type)
          puts "🚧 #{integration_type} integration coming soon!"
          puts "   Follow updates at https://github.com/CodingAgentDev"
        end
      end
    end
  end
end
