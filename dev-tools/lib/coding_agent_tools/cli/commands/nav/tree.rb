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
            @path_resolver = CodingAgentTools::Molecules::PathResolver.new
            @alternatives = []

            # Resolve target directory
            target_dir = resolve_target_directory(path, options[:autocorrect])
            return unless target_dir

            # Determine context
            context = options[:context] || "default"
            context_config = config.dig("contexts", context) || config.dig("contexts", "default") || {}

            # Determine depth
            depth = options[:depth] || context_config["max_depth"] || config["default_depth"] || 3

            # Build tree command
            excludes = build_exclude_patterns(config, context_config)
            tree_command = build_tree_command(target_dir, depth, excludes)

            # Execute tree command
            output = `#{tree_command}`
            exit_status = $?.exitstatus

            if exit_status == 0
              puts output

              # Show alternatives if any exist
              puts @path_resolver.format_alternative_matches(@alternatives) unless @alternatives.empty?
            else
              puts "Error executing tree command: #{tree_command}"
              puts "Output: #{output}" unless output.strip.empty?
            end
          rescue => e
            puts "Error: #{e.message}"
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
            repo_excludes.each do |_repo, patterns|
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
            return path if Dir.exist?(path)

            # If autocorrect disabled, show error and exit
            unless autocorrect
              puts "Error: Directory '#{path}' not found and autocorrection is disabled"
              return nil
            end

            # Check if input uses scoped pattern syntax (scope:pattern)
            if path.include?(":")
              result = @path_resolver.resolve_scoped_pattern(path)

              if result[:success]
                resolved_path = result[:path]

                # Show autocorrection messages
                puts result[:autocorrect_message] if result[:autocorrect_message]

                # Check if resolved path is a directory
                if Dir.exist?(resolved_path)
                  puts "Best match: '#{resolved_path}'"
                  # Store alternatives for scoped results
                  if result[:type] == :scoped_multiple && result[:alternatives]
                    @alternatives = result[:alternatives].select { |p| Dir.exist?(p) }
                  end
                  return resolved_path
                else
                  # If it's a file, use its directory
                  dir_path = File.dirname(resolved_path)
                  puts "Best match: '#{dir_path}' (parent directory of found file)"
                  return dir_path
                end
              else
                puts "Error: #{result[:error]}"
                return nil
              end
            end

            # Try directory-specific search first
            matches = @path_resolver.find_matching_paths(path, include_directories: true, max_results: 5)
            directories = matches.select { |p| Dir.exist?(p) }

            if directories.length == 1
              resolved_path = directories.first
              puts "Autocorrected: '#{path}' → '#{resolved_path}'"
              return resolved_path
            elsif directories.length > 1
              # Use smart prioritization for multiple directory matches
              prioritized = @path_resolver.prioritize_matches(directories)
              puts "Autocorrected: '#{path}' → '#{prioritized[:best]}'"

              # Store alternatives to show later
              @alternatives = prioritized[:alternatives]
              return prioritized[:best]
            end

            # Fall back to file search
            result = @path_resolver.resolve_path(path, type: :file)

            if result[:success]
              case result[:type]
              when :single
                resolved_path = result[:path]
                # Check if resolved path is a directory
                if Dir.exist?(resolved_path)
                  puts "Autocorrected: '#{path}' → '#{resolved_path}'"
                  resolved_path
                else
                  # If it's a file, use its directory
                  dir_path = File.dirname(resolved_path)
                  puts "Autocorrected: '#{path}' → '#{dir_path}' (parent directory of found file)"
                  dir_path
                end
              when :multiple
                # Convert file paths to directory paths and use smart prioritization
                display_paths = result[:paths].map do |match_path|
                  Dir.exist?(match_path) ? match_path : File.dirname(match_path)
                end

                prioritized = @path_resolver.prioritize_matches(display_paths.uniq)
                puts "Autocorrected: '#{path}' → '#{prioritized[:best]}' (parent directory of found file)"

                # Store alternatives to show later
                @alternatives = prioritized[:alternatives]
                prioritized[:best]
              end
            else
              puts "Error: #{result[:error]}"
              nil
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
