# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module Nav
        class Ls < Dry::CLI::Command
          desc "Intelligent directory listing with path autocorrection"

          argument :path, desc: "Directory path to list (uses autocorrection if not found locally)"
          option :long, type: :boolean, default: false, desc: "Use long format (ls -l)"
          option :all, type: :boolean, default: false, desc: "Show hidden files (ls -a)"
          option :autocorrect, type: :boolean, default: true, desc: "Enable path autocorrection"

          def call(path: nil, **options)
            # Resolve target directory
            target_dir = resolve_target_directory(path, options[:autocorrect])
            return unless target_dir

            # Build ls command
            ls_command = build_ls_command(target_dir, options)

            # Execute ls command
            begin
              output = `#{ls_command}`
              exit_status = $?.exitstatus

              if exit_status == 0
                puts output
              else
                puts "Error executing ls command: #{ls_command}"
                puts "Output: #{output}" unless output.strip.empty?
              end
            rescue StandardError => e
              puts "Error: #{e.message}"
            end
          end

          private

          def build_ls_command(target_dir, options)
            cmd_parts = ["ls"]
            
            # Add flags based on options
            flags = []
            flags << "l" if options[:long]
            flags << "a" if options[:all]
            
            unless flags.empty?
              cmd_parts << "-#{flags.join('')}"
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
        end
      end
    end
  end
end