# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module Nav
        class Tree < Dry::CLI::Command
          desc "Configuration-driven directory tree with filtering and autocorrection"

          argument :path, desc: "Directory path to show tree for (uses autocorrection if not found locally)"
          option :context, desc: "Tree context (default, dev, tasks, full)"
          option :depth, type: :integer, desc: "Maximum tree depth"
          option :autocorrect, type: :boolean, default: true, desc: "Enable path autocorrection suggestions"

          def call(path: nil, **options)
            # Initialize components
            config_loader = CodingAgentTools::Molecules::TreeConfigLoader.new
            config = config_loader.load

            # Resolve target directory
            target_dir = resolve_target_directory(path, options[:autocorrect])
            return unless target_dir

            # Determine context
            context = options[:context] || "default"
            context_config = config.dig("contexts", context) || config["contexts"]["default"]

            # Determine depth
            depth = options[:depth] || context_config["max_depth"] || config["default_depth"] || 3

            # Build tree command
            excludes = build_exclude_patterns(config, context_config)
            tree_command = build_tree_command(target_dir, depth, excludes)

            # Execute tree command
            begin
              output = `#{tree_command}`
              exit_status = $?.exitstatus

              if exit_status == 0
                puts output
              else
                puts "Error executing tree command: #{tree_command}"
                puts "Output: #{output}" unless output.strip.empty?
              end
            rescue StandardError => e
              puts "Error: #{e.message}"
            end
          end

          private

          def build_exclude_patterns(config, context_config)
            excludes = []
            
            # Add global excludes
            excludes.concat(config["global_excludes"] || [])
            
            # Add context-specific excludes
            excludes.concat(context_config["excludes"] || [])
            
            # Add repository-specific excludes
            repo_excludes = config.dig("repositories", "specific_excludes") || {}
            repo_excludes.each do |repo, patterns|
              excludes.concat(patterns)
            end
            
            excludes.uniq
          end

          def build_tree_command(target_dir, depth, excludes)
            cmd_parts = ["tree", "-L", depth.to_s]
            
            # Add exclude patterns
            excludes.each do |pattern|
              cmd_parts << "-I" << "'#{pattern}'"
            end
            
            # Add target directory (quoted for safety)
            cmd_parts << "'#{target_dir}'"
            
            cmd_parts.join(" ")
          end

          def resolve_target_directory(path, autocorrect)
            
            # If no path provided, use current directory
            return "." unless path

            # Check if path exists locally first
            if Dir.exist?(path)
              return path
            end

            # If autocorrect disabled, show error and exit
            unless autocorrect
              puts "Error: Directory '#{path}' not found and autocorrection is disabled"
              return nil
            end

            # Use path resolver to find the directory
            path_resolver = CodingAgentTools::Molecules::PathResolver.new
            
            # Try directory-specific search first
            matches = path_resolver.find_matching_paths(path, include_directories: true, max_results: 5)
            directories = matches.select { |p| Dir.exist?(p) }
            
            if directories.length == 1
              resolved_path = directories.first
              puts "Autocorrected: '#{path}' → '#{resolved_path}'"
              return resolved_path
            elsif directories.length > 1
              puts "Multiple directory matches found for '#{path}':"
              directories.each_with_index do |dir_path, index|
                puts "#{index + 1}) #{dir_path}"
              end
              puts "Please be more specific or use the full path"
              return nil
            end
            
            # Fall back to file search
            result = path_resolver.resolve_path(path, type: :file)

            if result[:success]
              case result[:type]
              when :single
                resolved_path = result[:path]
                # Check if resolved path is a directory
                if Dir.exist?(resolved_path)
                  puts "Autocorrected: '#{path}' → '#{resolved_path}'"
                  return resolved_path
                else
                  # If it's a file, use its directory
                  dir_path = File.dirname(resolved_path)
                  puts "Autocorrected: '#{path}' → '#{dir_path}' (parent directory of found file)"
                  return dir_path
                end
              when :multiple
                puts "Multiple matches found for '#{path}':"
                result[:paths].each_with_index do |match_path, index|
                  display_path = Dir.exist?(match_path) ? match_path : File.dirname(match_path)
                  puts "#{index + 1}) #{display_path}"
                end
                puts "Please be more specific or use the full path"
                return nil
              end
            else
              puts "Error: #{result[:error]}"
              return nil
            end
          end

          def show_autocorrection_info(config)
            return unless config.dig("autocorrect", "enabled")
            
            puts ""
            puts "💡 Path Autocorrection Available:"
            puts "   Use 'nav path file PATTERN' to find and autocorrect file paths"
            puts "   Example: nav path file README"
          end
        end
      end
    end
  end
end