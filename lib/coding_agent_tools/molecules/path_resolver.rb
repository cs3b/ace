# frozen_string_literal: true

require "pathname"
require "fileutils"
require "find"
require_relative "path_config_loader"
require_relative "project_sandbox"

module CodingAgentTools
  module Molecules
    class PathResolver
      def initialize(config_loader = nil, sandbox = nil)
        @config_loader = config_loader || PathConfigLoader.new
        @config = @config_loader.load

        # Initialize sandbox with security configuration
        @sandbox = sandbox || ProjectSandbox.new(
          nil, # project_root (auto-detect)
          @config.dig("security", "allowed_patterns"), # may be nil for permissive mode
          @config.dig("security", "forbidden_patterns")
        )
      end

      def resolve_path(path_input, type: :file)
        return failure("Path input cannot be nil") if path_input.nil?
        return failure("Path input cannot be empty") if path_input.to_s.strip.empty?

        # Check if input uses scoped pattern syntax (scope:pattern)
        if path_input.include?(":") && type == :file
          resolve_scoped_pattern(path_input)
        else
          case type
          when :file
            resolve_file_path(path_input)
          when :task_new, :docs_new, :reflection_new
            generate_new_path(path_input, type)
          when :task
            resolve_task_path(path_input)
          when :reflection_list
            find_reflection_paths_in_current_release
          else
            failure("Unknown path type: #{type}")
          end
        end
      end

      def find_matching_paths(pattern, options = {})
        max_results = options.fetch(:max_results, 10)
        repositories = options.fetch(:repositories, scan_repositories)
        file_types = options.fetch(:file_types, preferred_file_types)
        include_directories = options.fetch(:include_directories, false)

        # Normalize and extract meaningful parts from the pattern
        normalized_pattern = normalize_pattern(pattern)

        matches = []

        repositories.each do |repo|
          repo_matches = scan_repository_for_pattern(repo, normalized_pattern, file_types, include_directories)
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

      def find_reflection_paths_in_current_release
        # Find current release directory
        current_release_path = find_current_release_path
        return failure("Could not find current release directory") unless current_release_path

        # Look for reflection directories in current release
        reflections_pattern = File.join(current_release_path, "*/reflections")
        reflection_dirs = Dir.glob(reflections_pattern).select { |path| Dir.exist?(path) }

        if reflection_dirs.empty?
          return success_with_list([])
        end

        # Find all .md files in reflection directories, excluding archived subdirectories
        all_reflections = []
        reflection_dirs.each do |reflections_dir|
          # Find all .md files in the reflections directory
          md_files = Dir.glob(File.join(reflections_dir, "**/*.md"))

          # Filter out files in archived subdirectories
          non_archived = md_files.reject do |file|
            relative_path = file.sub(reflections_dir + "/", "")
            relative_path.start_with?("archived/")
          end

          all_reflections.concat(non_archived)
        end

        # Sort by modification time (newest first) for consistent ordering
        sorted_reflections = all_reflections.sort_by { |file| -File.mtime(file).to_i }

        success_with_list(sorted_reflections)
      rescue => e
        failure("Error finding reflection paths: #{e.message}")
      end

      # Scoped pattern resolution (public method)
      def resolve_scoped_pattern(input)
        scope_part, pattern_part = input.split(":", 2)
        return failure("Empty scope or pattern") if scope_part.strip.empty? || pattern_part.strip.empty?

        # Simple scope resolution - get scope config
        scoped_config = @config.dig("scoped_autocorrect") || {}
        scope_autocorrect = scoped_config.dig("scope_autocorrect") || {}
        scope_mappings = scoped_config.dig("scope_mappings") || {}

        # Autocorrect scope - check exact match, case-insensitive, and partial matches
        corrected_scope = scope_part
        if scope_autocorrect.key?(scope_part)
          corrected_scope = scope_autocorrect[scope_part]
        else
          # Case-insensitive check
          scope_autocorrect.each do |from, to|
            if scope_part.downcase == from.downcase
              corrected_scope = to
              break
            end
          end
        end

        # Get scope paths
        scope_paths = scope_mappings[corrected_scope] || []
        return failure("No scope matches found for '#{scope_part}' (autocorrected to '#{corrected_scope}')") if scope_paths.empty?

        # Find matches in scope directories
        all_matches = []
        scope_paths.each do |scope_path|
          full_scope_path = File.join(@sandbox.project_root, scope_path)
          next unless Dir.exist?(full_scope_path)

          matches = find_matching_paths(pattern_part, repositories: [{"path" => scope_path}], max_results: 10)
          all_matches.concat(matches)
        end

        return failure("No patterns found for '#{pattern_part}' in scope '#{corrected_scope}'") if all_matches.empty?

        # Build result
        if all_matches.length == 1
          result = {success: true, path: all_matches.first, type: :single}
          if scope_part != corrected_scope
            result[:autocorrect_message] = "Autocorrected scope: '#{scope_part}' → '#{corrected_scope}'"
          end
        else
          prioritized = prioritize_matches(all_matches)
          result = {success: true, path: prioritized[:best], type: :scoped_multiple}
          if scope_part != corrected_scope
            result[:autocorrect_message] = "Autocorrected scope: '#{scope_part}' → '#{corrected_scope}'"
          end
          result[:alternatives] = prioritized[:alternatives]
          if prioritized[:alternatives].any?
            result[:alternative_message] = "\nOther scope combinations:\n  - #{corrected_scope}: #{prioritized[:alternatives].length} more match#{"es" if prioritized[:alternatives].length > 1}"
          end
        end
        result
      end

      private

      def matches_forbidden_pattern_for_search?(relative_path)
        # Get forbidden patterns from config, with fallback to sandbox defaults
        forbidden_patterns = @config.dig("security", "forbidden_patterns") || 
                             @sandbox.send(:default_forbidden_patterns)
        
        forbidden_patterns.any? do |pattern|
          File.fnmatch?(pattern, relative_path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end
      end

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
      rescue => e
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
          
          # Execute the command with error capture for debugging
          result_with_errors = `#{command} 2>&1`.strip
          exit_status = $?.exitstatus
          
          # If successful, return the result
          if exit_status == 0 && !result_with_errors.empty?
            # For JSON commands, extract just the result (not error messages)
            if command.include?("--format json")
              result_with_errors.split("\n").last.strip
            else
              result_with_errors
            end
          else
            # Command failed - use fallback detection methods
            case command
            when /release-manager current/
              # Use DirectoryNavigator as fallback to ensure consistency
              # Log the failure for debugging
              warn "Warning: release-manager command failed (exit: #{exit_status}): #{command}"
              warn "Error output: #{result_with_errors}" unless result_with_errors.empty?
              detect_current_release_fallback
            when /task-manager generate-id/
              # For task ID generation, we need to detect the version dynamically too
              current_release = detect_current_release_fallback
              match = current_release.match(/^(v\.\d+\.\d+\.\d+)/)
              version = match ? match[1] : "v.0.1.0"
              "#{version}+task.#{rand(100)}"
            else
              "unknown"
            end
          end
        ensure
          Dir.chdir(original_dir)
        end
      end

      # Fallback method to detect current release using DirectoryNavigator
      # This ensures consistency with release-manager when command execution fails
      def detect_current_release_fallback
        require_relative "../atoms/taskflow_management/directory_navigator"
        
        result = CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator
          .get_current_release_directory(base_path: @sandbox.project_root)
        
        if result && result[:path]
          File.basename(result[:path])
        else
          # If DirectoryNavigator can't find anything, there's no current release
          # This should cause an error rather than creating tasks in a non-existent release
          raise "No current release directory found. Cannot determine where to create tasks."
        end
      rescue => e
        # Re-raise with more context - we should never silently fail to detect the release
        raise "Failed to detect current release: #{e.message}. " \
              "Ensure dev-taskflow/current/ contains exactly one release directory."
      end

      def extract_task_number_from_context
        # Try to extract task number from current working context
        # This could be enhanced to look at current git branch, directory, etc.
        rand(100).to_s  # Simple fallback
      end

      def slugify(text)
        text.to_s
          .downcase
          .gsub(/[^\w\s-]/, "")  # Remove non-word characters except spaces and hyphens
          .gsub(/\s+/, "-").squeeze("-")       # Collapse multiple hyphens
          .strip                 # Remove leading/trailing whitespace
          .gsub(/^-|-$/, "")     # Remove leading/trailing hyphens
      end

      def scan_repositories
        @config.dig("repositories", "scan_order") || [
          {"name" => "tools-meta", "path" => ".", "priority" => 1}
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
          # Check if this path should be skipped based on forbidden patterns
          relative_path = path.sub(@sandbox.project_root + "/", "")
          
          # Skip forbidden directories during traversal (don't descend into them)
          if Dir.exist?(path) && matches_forbidden_pattern_for_search?(relative_path)
            Find.prune  # Don't descend into this directory
          end
          
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

          # Enhanced fuzzy pattern matching
          basename = File.basename(path)
          dirname = File.dirname(relative_path)

          # Check various matching strategies
          match_found = false

          # 1. Exact substring match (highest priority)
          if basename.downcase.include?(pattern.downcase) ||
              relative_path.downcase.include?(pattern.downcase)
            match_found = true
          end

          # 2. Fuzzy prefix matching (e.g., "dev" matches "dev-tools")
          if basename.downcase.start_with?(pattern.downcase) ||
              dirname.split("/").any? { |part| part.downcase.start_with?(pattern.downcase) }
            match_found = true
          end

          # 3. Word boundary matching (e.g., "tools" matches "dev-tools")
          if basename.downcase.split(/[-_]/).any? { |part| part.start_with?(pattern.downcase) } ||
              relative_path.downcase.split(/[\/\-_]/).any? { |part| part.start_with?(pattern.downcase) }
            match_found = true
          end

          # 4. Character similarity for very short patterns
          if pattern.length <= 3 && calculate_similarity_score(pattern, basename) > 0.6
            match_found = true
          end

          matches << path if match_found

          # Limit results to prevent performance issues
          break if matches.length >= 50
        end

        # Sort matches by relevance score
        matches.sort_by do |path|
          basename = File.basename(path)
          relative_path = path.sub(@sandbox.project_root + "/", "")

          # Calculate relevance score (lower is better for sorting)

          # Exact match gets highest priority
          score = if basename.downcase == pattern.downcase
            0
          # Exact prefix match
          elsif basename.downcase.start_with?(pattern.downcase)
            1
          # Contains pattern
          elsif basename.downcase.include?(pattern.downcase)
            2
          # Directory contains pattern
          elsif relative_path.downcase.include?(pattern.downcase)
            3
          else
            4
          end

          [score, repo["priority"], basename.length, basename]
        end
      rescue
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

      def prioritize_matches(matches, current_dir = nil)
        return {best: matches.first, alternatives: []} if matches.length <= 1

        current_dir ||= Dir.pwd

        scored_matches = matches.map do |match|
          score = calculate_proximity_score(match, current_dir)
          [match, score]
        end

        sorted_matches = scored_matches.sort_by { |_, score| -score }
        best_match = sorted_matches.first[0]
        alternatives = sorted_matches[1..].map { |match, _| match }

        {best: best_match, alternatives: alternatives}
      end

      def calculate_proximity_score(target_path, current_dir)
        target_abs = File.expand_path(target_path)
        current_abs = File.expand_path(current_dir)

        # 100 points: Within current directory tree (target is subdirectory of current)
        if target_abs.start_with?(current_abs + "/")
          return 100
        end

        # 90 points: Current directory is within target tree (current is subdirectory of target)
        if current_abs.start_with?(target_abs + "/")
          return 90
        end

        # 80 points: Sibling directories (same parent)
        if File.dirname(target_abs) == File.dirname(current_abs)
          return 80
        end

        # 70 points: In same repository (share common dev-* ancestor)
        target_repo = extract_repository_name(target_abs)
        current_repo = extract_repository_name(current_abs)
        if target_repo && current_repo && target_repo == current_repo
          return 70
        end

        # 60 points: Same repository type but different repos
        if target_repo && current_repo
          return 60
        end

        # 40 points: Within project root
        if target_abs.start_with?(@sandbox.project_root)
          return 40
        end

        # 20 points: Any other match
        20
      end

      def extract_repository_name(path)
        relative_path = path.sub(@sandbox.project_root + "/", "")
        path_parts = relative_path.split("/")

        # Look for dev-* directory in path
        dev_dir = path_parts.find { |part| part.start_with?("dev-") }
        return dev_dir if dev_dir

        # If path starts with a known repository name
        first_part = path_parts.first
        if %w[dev-tools dev-handbook dev-taskflow].include?(first_part)
          return first_part
        end

        nil
      end

      def normalize_pattern(pattern)
        return pattern if pattern.nil? || pattern.empty?

        # Clean up path traversal patterns
        normalized = pattern.to_s.strip

        # Step 1: Handle paths that traverse above project root
        normalized = clean_path_traversal(normalized)

        # Step 2: Extract meaningful parts from complex paths
        path_parts = normalized.split("/").reject(&:empty?)

        # Step 3: Apply autocorrect mappings to each part
        corrected_parts = path_parts.map { |part| apply_autocorrect_mappings(part) }

        # If we have path parts, use the last non-empty one as the search pattern
        if corrected_parts.any?
          meaningful_part = corrected_parts.last
          # If it looks like a filename with extension, remove extension for fuzzy matching
          meaningful_part = File.basename(meaningful_part, ".*") if meaningful_part.include?(".")
          meaningful_part
        else
          apply_autocorrect_mappings(normalized)
        end
      end

      def clean_path_traversal(path)
        # Convert path to absolute, then check if it's above project root

        expanded_path = File.expand_path(path, @sandbox.project_root)

        # If the expanded path is above or outside project root, extract meaningful parts
        unless expanded_path.start_with?(@sandbox.project_root)
          # Extract just the filename/directory name from complex traversal
          path_parts = path.split("/").reject { |part| part == "." || part == ".." || part.empty? }
          return path_parts.last || path
        end

        # Make relative to project root
        expanded_path.sub(@sandbox.project_root + "/", "")
      rescue
        # If path expansion fails, clean it manually
        path.gsub(/^(\.\.?\/)+/, "").split("/").reject(&:empty?).last || path
      end

      def apply_autocorrect_mappings(text)
        return text if text.nil? || text.empty?

        # Get autocorrect mappings from config
        mappings = @config.dig("autocorrect_mappings") || {}

        # Apply direct mappings
        return mappings[text] if mappings.key?(text)

        # Apply case-insensitive mappings
        mappings.each do |from, to|
          if text.downcase == from.downcase
            return to
          end
        end

        # Apply partial mappings (e.g., within longer paths)
        mappings.each do |from, to|
          if text.downcase.include?(from.downcase)
            return text.gsub(/#{Regexp.escape(from)}/i, to)
          end
        end

        text
      end

      def format_alternative_matches(alternatives)
        return "" if alternatives.empty?

        formatted_alternatives = alternatives.map { |alt| "  - #{alt}" }.join("\n")
        "\nOther matching paths:\n#{formatted_alternatives}"
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

      # Result helper methods
      def success(path)
        {success: true, type: :single, path: path}
      end

      def failure(error)
        {success: false, error: error}
      end

      def success_with_options(paths)
        {success: true, type: :multiple, paths: paths}
      end

      def success_with_list(paths)
        {success: true, type: :list, paths: paths}
      end

      def find_current_release_path
        # Look for current release in dev-taskflow/current
        current_base = File.join(@sandbox.project_root, "dev-taskflow/current")
        return nil unless Dir.exist?(current_base)

        # Find the first directory in current (should be the current release)
        release_dirs = Dir.glob(File.join(current_base, "*")).select { |path| Dir.exist?(path) }

        # Return the first one found, or nil if none
        release_dirs.first
      end
    end
  end
end
