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

        option :claude, type: :boolean, default: false,
          desc: "Setup Claude Code integration"
        option :opencode, type: :boolean, default: false,
          desc: "Setup OpenCode integration (coming soon)"
        option :force, type: :boolean, default: false,
          desc: "Force overwrite existing integration (creates backup)"
        option :no_backup, type: :boolean, default: false,
          desc: "Skip backup when using --force"
        option :only, type: :string,
          desc: "Only integrate specific components (agents,commands,dotfiles,docs)"
        option :dry_run, type: :boolean, default: false,
          desc: "Preview what would be done without making changes"
        option :verbose, type: :boolean, default: false,
          desc: "Show detailed output"

        def call(**options)
          @options = options
          @dry_run = options[:dry_run]
          @verbose = options[:verbose]
          @project_root = find_project_root
          
          # Determine integration type
          if options[:opencode]
            show_coming_soon("OpenCode")
            return
          end
          
          # Default to Claude if no specific integration requested
          integration_type = options[:claude] || !options[:opencode] ? "claude" : nil
          
          unless integration_type
            puts "Please specify an integration type: --claude or --opencode"
            return
          end
          
          puts "🚀 Starting #{integration_type.capitalize} integration..."
          puts "   Mode: #{dry_run_mode}" if @dry_run
          
          # Load configuration
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
          
          # Check submodules
          check_and_setup_submodules(config["submodules"])
          
          # Handle backup if force mode
          backup_path = nil
          if options[:force] && !options[:no_backup]
            backup_path = create_backup
          end
          
          # Determine components to integrate
          components = determine_components(integration_config, options[:only])
          
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
            
            if submodule_path.exist? && (submodule_path + ".git").exist?
              log "  ✓ #{name} present"
            else
              puts "  → #{name} missing, setting up..."
              setup_submodule(name, config) unless @dry_run
            end
          end
        end
        
        def setup_submodule(name, config)
          url = config["url"]
          
          # Handle special case for dev-taskflow (auto URL)
          if url == "auto"
            origin_url = `git config --get remote.origin.url`.strip
            url = origin_url.sub(/\.git$/, "") + "-taskflow.git"
          end
          
          branch = config["branch"] || "main"
          
          # Try GitHub CLI first
          if system("which gh > /dev/null 2>&1")
            log "Using GitHub CLI to add submodule"
            system("gh repo clone #{url} #{name} -- --branch #{branch}")
            system("git submodule add #{url} #{name}")
          else
            log "Using git to add submodule"
            system("git submodule add -b #{branch} #{url} #{name}")
            system("git submodule update --init --recursive")
          end
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
          return unless backup_path && backup_path.exist?
          
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
        
        def determine_components(integration_config, only_option)
          all_components = integration_config["components"].keys
          
          if only_option
            requested = only_option.split(",").map(&:strip)
            invalid = requested - all_components
            
            if invalid.any?
              puts "❌ Invalid components: #{invalid.join(', ')}"
              puts "   Available: #{all_components.join(', ')}"
              return []
            end
            
            requested
          else
            all_components
          end
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