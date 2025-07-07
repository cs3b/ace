# frozen_string_literal: true

require "pathname"
require "fileutils"
require "find"

module CodingAgentTools
  module Molecules
    class PathResolver
      def initialize(config_loader = nil, sandbox = nil)
        @config_loader = config_loader || PathConfigLoader.new
        @sandbox = sandbox || ProjectSandbox.new
        @config = @config_loader.load
      end

      def resolve_path(path_input, type: :file)
        return failure("Path input cannot be nil") if path_input.nil?
        return failure("Path input cannot be empty") if path_input.to_s.strip.empty?

        case type
        when :file
          resolve_file_path(path_input)
        when :task_new, :docs_new, :reflection_new
          generate_new_path(path_input, type)
        when :task
          resolve_task_path(path_input)
        else
          failure("Unknown path type: #{type}")
        end
      end

      def find_matching_paths(pattern, options = {})
        max_results = options.fetch(:max_results, 10)
        repositories = options.fetch(:repositories, scan_repositories)
        file_types = options.fetch(:file_types, preferred_file_types)
        include_directories = options.fetch(:include_directories, false)

        matches = []
        
        repositories.each do |repo|
          repo_matches = scan_repository_for_pattern(repo, pattern, file_types, include_directories)
          matches.concat(repo_matches)
          break if matches.length >= max_results
        end

        matches.take(max_results).map do |match|
          @sandbox.validate_path(match)
        end.select { |result| result[:success] }.map { |result| result[:path] }
      end

      def resolve_existing_task(task_id)
        task_pattern = "**/tasks/*#{task_id}*.md"
        matches = find_matching_paths(task_pattern, max_results: 5)
        
        return failure("No task found with ID: #{task_id}") if matches.empty?
        return success(matches.first) if matches.length == 1
        
        # Multiple matches - return all for user selection
        success_with_options(matches)
      end

      def autocorrect_path(incomplete_path)
        # Remove any leading/trailing whitespace and normalize
        normalized = incomplete_path.to_s.strip
        
        # Try exact match first
        exact_matches = find_matching_paths(normalized, max_results: 1)
        return success(exact_matches.first) unless exact_matches.empty?

        # Try fuzzy matching
        fuzzy_matches = find_fuzzy_matches(normalized)
        
        return failure("No matches found for: #{incomplete_path}") if fuzzy_matches.empty?
        return success(fuzzy_matches.first) if fuzzy_matches.length == 1
        
        # Multiple matches - return all for user selection
        success_with_options(fuzzy_matches)
      end

      private

      def resolve_file_path(path_input)
        # Try as absolute path first
        if Pathname.new(path_input).absolute?
          validation = @sandbox.validate_path(path_input)
          return validation[:success] ? success(validation[:path]) : failure(validation[:error])
        end

        # Try as relative path from project root
        absolute_attempt = @sandbox.absolute_path(path_input)
        return success(absolute_attempt) if File.exist?(absolute_attempt)

        # Try autocorrection for incomplete paths
        autocorrect_path(path_input)
      rescue CodingAgentTools::Error => e
        failure("Path resolution failed: #{e.message}")
      end

      def resolve_task_path(task_id)
        resolve_existing_task(task_id)
      end

      def generate_new_path(title, type)
        pattern_config = @config.dig("path_patterns", type.to_s)
        return failure("No path pattern configured for type: #{type}") unless pattern_config

        template = pattern_config["template"]
        variables = pattern_config["variables"]

        # Resolve template variables
        resolved_path = resolve_template_variables(template, variables, title)
        
        # Validate the generated path
        validation = @sandbox.validate_path(resolved_path)
        return failure(validation[:error]) unless validation[:success]

        success(validation[:path])
      rescue StandardError => e
        failure("Path generation failed: #{e.message}")
      end

      def resolve_template_variables(template, variables, title)
        resolved = template.dup

        variables.each do |var, source|
          value = case source
          when "user_input"
            slugify(title)
          when /^datetime:/
            Time.now.strftime(source.sub("datetime:", ""))
          when "task_number"
            extract_task_number_from_context
          else
            # Shell command
            execute_command(source)
          end

          resolved = resolved.gsub("{#{var}}", value)
        end

        # Make path relative to project root
        if resolved.start_with?("/")
          resolved
        else
          File.join(@sandbox.project_root, resolved)
        end
      end

      def execute_command(command)
        # Execute command safely and return output
        # Navigate to project root since commands expect to run from there
        original_dir = Dir.pwd
        
        begin
          Dir.chdir(@sandbox.project_root)
          result = `#{command} 2>/dev/null`.strip
          
          # Handle common command failures
          if result.empty? || $?.exitstatus != 0
            case command
            when /release-manager current/
              "v.0.3.0-migration"  # Fallback release name
            when /task-manager generate-id/
              "v.0.3.0+task.#{rand(100)}"  # Better fallback ID format
            else
              "unknown"
            end
          else
            result
          end
        ensure
          Dir.chdir(original_dir)
        end
      end

      def extract_task_number_from_context
        # Try to extract task number from current working context
        # This could be enhanced to look at current git branch, directory, etc.
        "#{rand(100)}"  # Simple fallback
      end

      def slugify(text)
        text.to_s
            .downcase
            .gsub(/[^\w\s-]/, "")  # Remove non-word characters except spaces and hyphens
            .gsub(/\s+/, "-")      # Convert spaces to hyphens
            .gsub(/-+/, "-")       # Collapse multiple hyphens
            .strip                 # Remove leading/trailing whitespace
            .gsub(/^-|-$/, "")     # Remove leading/trailing hyphens
      end

      def scan_repositories
        @config.dig("repositories", "scan_order") || [
          { "name" => "tools-meta", "path" => ".", "priority" => 1 }
        ]
      end

      def preferred_file_types
        @config.dig("resolution", "file_preferences", "preferred_extensions") || 
          [".md", ".rb", ".yml", ".yaml"]
      end

      def scan_repository_for_pattern(repo, pattern, file_types, include_directories = false)
        repo_path = File.join(@sandbox.project_root, repo["path"])
        return [] unless Dir.exist?(repo_path)

        matches = []
        
        # Use Find to search for files and optionally directories
        Find.find(repo_path) do |path|
          # Skip if it's neither a file nor a directory we're interested in
          next unless File.file?(path) || (include_directories && Dir.exist?(path))
          
          # For directories, we don't need to check file extensions
          if Dir.exist?(path)
            # Skip the root path itself
            next if path == repo_path
          else
            # For files, check file types
            next unless file_types.any? { |ext| 
              if ext.empty?
                # For empty extension, match files without extensions
                File.extname(path).empty?
              else
                path.end_with?(ext)
              end
            }
          end
          
          relative_path = path.sub(@sandbox.project_root + "/", "")
          
          # Simple pattern matching - could be enhanced with more sophisticated matching
          if File.fnmatch?("*#{pattern}*", File.basename(path), File::FNM_CASEFOLD) ||
             File.fnmatch?("*#{pattern}*", relative_path, File::FNM_CASEFOLD)
            matches << path
          end
          
          # Limit results to prevent performance issues
          break if matches.length >= 50
        end

        matches.sort_by { |path| [repo["priority"], File.basename(path)] }
      rescue StandardError
        []
      end

      def find_fuzzy_matches(pattern)
        # Simple fuzzy matching implementation
        # Could be enhanced with more sophisticated algorithms
        all_matches = find_matching_paths("*#{pattern}*", max_results: 20)
        
        # Score matches by similarity and return best matches
        scored_matches = all_matches.map do |match|
          score = calculate_similarity_score(pattern, match)
          [match, score]
        end

        # Sort by score (higher is better) and return paths
        scored_matches
          .select { |_, score| score > 0.3 }  # Minimum similarity threshold
          .sort_by { |_, score| -score }
          .map { |match, _| match }
          .take(10)
      end

      def calculate_similarity_score(pattern, path)
        # Simple similarity calculation - could use more sophisticated algorithms
        basename = File.basename(path, ".*").downcase
        pattern_lower = pattern.downcase
        
        # Exact match bonus
        return 1.0 if basename == pattern_lower
        
        # Substring match
        return 0.8 if basename.include?(pattern_lower)
        
        # Character overlap
        common_chars = (basename.chars & pattern_lower.chars).uniq.length
        max_chars = [basename.length, pattern_lower.length].max
        return 0.0 if max_chars.zero?
        
        common_chars.to_f / max_chars
      end

      def success(path)
        { success: true, path: path, type: :single }
      end

      def success_with_options(paths)
        { success: true, paths: paths, type: :multiple }
      end

      def failure(error)
        { success: false, error: error }
      end
    end
  end
end