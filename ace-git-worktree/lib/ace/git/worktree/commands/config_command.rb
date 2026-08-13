require "json"
require "yaml"
require "fileutils"
require_relative "../organisms/worktree_manager"
require_relative "../molecules/config_loader"
require_relative "../models/worktree_config"

module Ace
  module Git
    module Worktree
      module Commands
        # Config command
        #
        # Displays, initializes, updates, and validates worktree configuration.
        # Shows current settings, provenance tracking, and validation results.
        class ConfigCommand
          # Initialize a new ConfigCommand
          def initialize
            @manager = Organisms::WorktreeManager.new
          end

          # Run the config command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            options = parse_arguments(args)
            return show_help if options[:help]

            if options[:init]
              return init_project_config
            end

            if options[:set_bootstrap]
              return set_bootstrap_config(options)
            end

            # Default to showing configuration if no action specified
            options[:show] = true unless options[:validate] || options[:show] || options[:files]

            results = []

            if options[:show]
              results << show_configuration(json: options[:json])
            end

            if options[:validate]
              results << validate_configuration(bootstrap_only: options[:bootstrap], json: options[:json])
            end

            if options[:files]
              results << show_configuration_files
            end

            (results.all? { |result| result == 0 }) ? 0 : 1
          rescue ArgumentError => e
            puts "Error: #{e.message}"
            1
          rescue => e
            puts "Error: #{e.message}"
            1
          end

          # Show help for the config command
          #
          # @return [Integer] Exit code
          def show_help
            puts <<~HELP
              ace-git-worktree config - Manage worktree configuration

              USAGE:
                  ace-git-worktree config [SUBCOMMAND / OPTIONS]

              ACTIONS:
                  init                                    Initialize minimal project worktree configuration
                  set-bootstrap                           Set bootstrap command policy
                  --show                                  Show current configuration (default)
                  --validate                              Validate configuration
                  --files                                 Show configuration file locations

              SET BOOTSTRAP OPTIONS:
                  --command <cmd>                         Command to run
                  --working-dir <path>                    Working directory relative to project root
                  --timeout <sec>                         Timeout in seconds (max 300)
                  --required | --advisory                 Policy for execution failure
                  --env KEY=VALUE                         Environment variables

              FORMAT OPTIONS:
                  --json                                  Format output as JSON
                  --bootstrap                             Validate bootstrap section only

              EXAMPLES:
                  ace-git-worktree config init
                  ace-git-worktree config set-bootstrap --command "npm install" --timeout 120 --required
                  ace-git-worktree config show --json
                  ace-git-worktree config validate --bootstrap --json
            HELP
            0
          end

          private

          # Parse command line arguments
          #
          # @param args [Array<String>] Command arguments
          # @return [Hash] Parsed options
          def parse_arguments(args)
            options = {
              show: false,
              validate: false,
              files: false,
              init: false,
              set_bootstrap: false,
              json: false,
              bootstrap: false,
              command: nil,
              working_dir: nil,
              timeout: nil,
              required: false,
              advisory: false,
              env: [],
              verbose: false,
              help: false
            }

            i = 0
            while i < args.length
              arg = args[i]

              case arg
              when "init"
                options[:init] = true
              when "set-bootstrap"
                options[:set_bootstrap] = true
              when "show", "--show"
                options[:show] = true
              when "validate", "--validate"
                options[:validate] = true
              when "files", "--files"
                options[:files] = true
              when "--json"
                options[:json] = true
              when "--bootstrap"
                options[:bootstrap] = true
              when "--command"
                i += 1
                options[:command] = args[i]
              when "--working-dir"
                i += 1
                options[:working_dir] = args[i]
              when "--timeout"
                i += 1
                options[:timeout] = args[i]
              when "--required"
                options[:required] = true
              when "--advisory"
                options[:advisory] = true
              when "--env"
                i += 1
                options[:env] << args[i] if args[i]
              when "--verbose", "-v"
                options[:verbose] = true
              when "--help", "-h"
                options[:help] = true
              when /^--/
                raise ArgumentError, "Unknown option: #{arg}"
              else
                raise ArgumentError, "Unexpected argument: #{arg}"
              end

              i += 1
            end

            options
          end

          # Initialize minimal project override configuration
          #
          # @return [Integer] Exit code
          def init_project_config
            project_root = Dir.pwd
            ace_dir = File.join(project_root, ".ace", "git")
            FileUtils.mkdir_p(ace_dir)
            config_file = File.join(ace_dir, "worktree.yml")

            if File.exist?(config_file)
              begin
                existing = YAML.safe_load_file(config_file, permitted_classes: [Date], aliases: true)
                if existing && !existing.is_a?(Hash)
                  puts "Error: Incompatible existing project configuration at #{config_file}"
                  return 1
                end
              rescue => e
                puts "Error: Incompatible existing project configuration at #{config_file}: #{e.message}"
                return 1
              end
              puts "Project configuration already initialized at #{config_file}"
              return 0
            end

            minimal = <<~YAML
              # ACE Git Worktree Project Configuration
              git:
                worktree: {}
            YAML

            tmp_file = "#{config_file}.tmp.#{Process.pid}"
            File.write(tmp_file, minimal)
            File.rename(tmp_file, config_file)
            puts "Initialized project worktree configuration at #{config_file}"
            0
          end

          # Set bootstrap policy configuration
          #
          # @param options [Hash] Options with command, working_dir, timeout, required/advisory, env
          # @return [Integer] Exit code
          def set_bootstrap_config(options)
            command = options[:command]
            if command.nil? || command.strip.empty?
              puts "Error: --command is required for set-bootstrap"
              return 1
            end

            working_dir = options[:working_dir] || "."
            if working_dir.start_with?("/") || working_dir.include?("..")
              puts "Error: --working-dir must be a relative path within the project root"
              return 1
            end

            timeout = (options[:timeout] || 60).to_i
            if timeout <= 0 || timeout > 300
              puts "Error: --timeout must be a positive integer <= 300"
              return 1
            end

            if options[:required] && options[:advisory]
              puts "Error: Cannot specify both --required and --advisory"
              return 1
            end

            policy = options[:advisory] ? "advisory" : "required"

            env_hash = {}
            Array(options[:env]).each do |pair|
              unless pair.include?("=")
                puts "Error: Environment variables must be in KEY=VALUE format: #{pair}"
                return 1
              end
              k, v = pair.split("=", 2)
              env_hash[k.strip] = v.to_s
            end

            project_root = Dir.pwd
            ace_dir = File.join(project_root, ".ace", "git")
            FileUtils.mkdir_p(ace_dir)
            config_file = File.join(ace_dir, "worktree.yml")

            existing_yaml = {}
            if File.exist?(config_file)
              begin
                loaded = YAML.safe_load_file(config_file, permitted_classes: [Date], aliases: true)
                existing_yaml = loaded if loaded.is_a?(Hash)
              rescue => e
                puts "Error reading existing configuration: #{e.message}"
                return 1
              end
            end

            existing_yaml["git"] ||= {}
            existing_yaml["git"]["worktree"] ||= {}
            existing_yaml["git"]["worktree"]["bootstrap"] = {
              "command" => command,
              "working_dir" => working_dir,
              "timeout" => timeout,
              "policy" => policy,
              "env" => env_hash
            }

            tmp_file = "#{config_file}.tmp.#{Process.pid}"
            File.write(tmp_file, YAML.dump(existing_yaml))
            File.rename(tmp_file, config_file)
            puts "Updated bootstrap policy at #{config_file}"
            0
          end

          # Show current configuration (text or JSON format)
          #
          # @param json [Boolean] Format as JSON
          # @return [Integer] Exit code
          def show_configuration(json: false)
            if json
              json_data = build_show_json
              puts JSON.pretty_generate(json_data)
              return 0
            end

            puts "Current Worktree Configuration:"
            puts "=" * 50

            config = @manager.configuration

            puts "Root Path: #{config.root_path}"
            puts "Absolute Root: #{config.absolute_root_path}"
            puts "Mise Trust Auto: #{config.mise_trust_auto? ? "enabled" : "disabled"}"
            puts

            if config.bootstrap_configured?
              bs = config.bootstrap
              puts "Bootstrap Settings:"
              puts "  Command: #{bs["command"]}"
              puts "  Working Dir: #{bs["working_dir"] || "."}"
              puts "  Timeout: #{bs["timeout"]}s"
              puts "  Policy: #{bs["policy"] || "required"}"
              puts
            else
              puts "Bootstrap Settings: not configured"
              puts
            end

            puts "Task Settings:"
            puts "  Directory Format: #{config.directory_format}"
            puts "  Branch Format: #{config.branch_format}"
            puts "  Auto Mark In Progress: #{config.auto_mark_in_progress? ? "enabled" : "disabled"}"
            puts "  Auto Commit Task: #{config.auto_commit_task? ? "enabled" : "disabled"}"
            puts "  Add Worktree Metadata: #{config.add_worktree_metadata? ? "enabled" : "disabled"}"
            puts

            0
          rescue => e
            puts "Error showing configuration: #{e.message}"
            1
          end

          # Validate configuration
          #
          # @param bootstrap_only [Boolean] Validate bootstrap section only
          # @param json [Boolean] Output JSON format
          def validate_configuration(bootstrap_only: false, json: false)
            result = @manager.validate_configuration rescue nil
            loader = Molecules::ConfigLoader.new(Dir.pwd)
            config = loader.load_without_validation rescue nil
            result ||= (config ? {success: config.validate.empty?, errors: config.validate} : {success: true, valid: true, errors: []})
            errors = bootstrap_only ? [] : (result[:errors] || []).dup

            if bootstrap_only || (config && config.bootstrap_configured?)
              bs = config ? config.bootstrap : {}
              if !config || !config.bootstrap_configured?
                errors << "Bootstrap is not configured" if bootstrap_only
              else
                cmd = bs["command"]
                errors << "Bootstrap command must be a non-empty string" if cmd.nil? || cmd.to_s.strip.empty?

                wdir = bs["working_dir"] || "."
                errors << "Bootstrap working_dir must be a relative path without leading slash or .." if wdir.start_with?("/") || wdir.include?("..")

                timeout = bs["timeout"].to_i
                errors << "Bootstrap timeout must be > 0 and <= 300" if timeout <= 0 || timeout > 300

                policy = bs["policy"] || "required"
                errors << "Bootstrap policy must be 'required' or 'advisory'" unless %w[required advisory].include?(policy)
              end
            end

            valid = errors.empty? && (bootstrap_only || result[:success] != false)

            if json
              json_result = {
                schema_version: "1.0",
                valid: valid,
                mode: bootstrap_only ? "bootstrap_only" : "full",
                errors: errors
              }
              puts JSON.pretty_generate(json_result)
              return valid ? 0 : 1
            end

            puts "Configuration Validation:"
            puts "=" * 30

            if valid
              puts "✅ Configuration is valid"
            else
              puts "❌ Configuration validation failed"
              errors.each { |err| puts "  ❌ #{err}" }
              return 1
            end

            0
          rescue => e
            puts "Error validating configuration: #{e.message}"
            1
          end

          # Safely load YAML file
          def load_yaml_file(path)
            return {} unless File.exist?(path)
            YAML.safe_load_file(path, aliases: true)
          rescue
            begin
              YAML.load_file(path) || {}
            rescue
              {}
            end
          end

          # Build JSON representation of configuration and provenance
          #
          # @return [Hash] JSON structure
          def build_show_json
            loader = Molecules::ConfigLoader.new(Dir.pwd)
            config = loader.load_without_validation
            project_root = Dir.pwd

            proj_file = File.join(project_root, ".ace", "git", "worktree.yml")
            user_file = File.expand_path("~/.ace/git/worktree.yml")
            pkg_file = File.join(project_root, ".ace-defaults", "git", "worktree.yml")

            proj_data = load_yaml_file(proj_file)
            user_data = load_yaml_file(user_file)

            provenance_for = lambda do |*keys|
              has_proj = proj_data.is_a?(Hash) && !proj_data.dig("git", "worktree", *keys).nil?
              has_user = user_data.is_a?(Hash) && !user_data.dig("git", "worktree", *keys).nil?

              if has_proj
                "project"
              elsif has_user
                "user"
              else
                "package_default"
              end
            end

            redact_env = lambda do |env_h|
              return {} unless env_h.is_a?(Hash)
              env_h.each_with_object({}) do |(k, v), acc|
                if k.to_s.match?(/(secret|token|key|pass|auth|credential)/i)
                  acc[k.to_s] = "[REDACTED]"
                else
                  acc[k.to_s] = v.to_s
                end
              end
            end

            bootstrap_h = config.bootstrap
            if config.bootstrap_configured?
              effective_bootstrap = {
                "command" => bootstrap_h["command"],
                "working_dir" => bootstrap_h["working_dir"] || ".",
                "timeout" => (bootstrap_h["timeout"] || 60).to_i,
                "policy" => bootstrap_h["policy"] || "required",
                "env" => redact_env.call(bootstrap_h["env"])
              }
            else
              effective_bootstrap = "not_configured"
            end

            provenance = {
              "root_path" => provenance_for.call("root_path"),
              "auto_navigate" => provenance_for.call("auto_navigate"),
              "tmux" => provenance_for.call("tmux"),
              "mise_trust_auto" => provenance_for.call("mise_trust_auto")
            }

            if config.bootstrap_configured?
              provenance["bootstrap.command"] = provenance_for.call("bootstrap", "command")
              provenance["bootstrap.working_dir"] = provenance_for.call("bootstrap", "working_dir")
              provenance["bootstrap.timeout"] = provenance_for.call("bootstrap", "timeout")
              provenance["bootstrap.policy"] = provenance_for.call("bootstrap", "policy")
              if bootstrap_h["env"].is_a?(Hash)
                bootstrap_h["env"].each_key do |ek|
                  provenance["bootstrap.env.#{ek}"] = provenance_for.call("bootstrap", "env", ek)
                end
              end
            end

            validation_errors = config.validate
            {
              schema_version: "1.0",
              config_files: [
                {path: proj_file, exists: File.exist?(proj_file), type: "project"},
                {path: user_file, exists: File.exist?(user_file), type: "user"},
                {path: pkg_file, exists: File.exist?(pkg_file), type: "package"}
              ],
              effective: {
                root_path: config.root_path,
                auto_navigate: config.auto_navigate?,
                mise_trust_auto: config.mise_trust_auto?,
                bootstrap: effective_bootstrap
              },
              provenance: provenance,
              validation: {
                valid: validation_errors.empty?,
                errors: validation_errors
              }
            }
          end

          # Show configuration file locations
          #
          # @return [Integer] Exit code
          def show_configuration_files
            puts "Configuration Files:"
            puts "=" * 20

            config_loader = @manager.instance_variable_get(:@config_loader)
            config_files = config_loader.config_files

            config_files.each do |file|
              if File.exist?(file)
                puts "✅ #{file} (exists)"
              else
                puts "❌ #{file} (not found)"
              end
            end

            0
          end
        end
      end
    end
  end
end
