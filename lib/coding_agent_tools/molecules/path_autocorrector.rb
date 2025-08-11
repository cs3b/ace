# frozen_string_literal: true

require "open3"
require "shellwords"
require "find"
require "pathname"

module CodingAgentTools
  module Molecules
    class PathAutocorrector
      def initialize(config_loader = nil, sandbox = nil)
        @config_loader = config_loader || PathConfigLoader.new
        @sandbox = sandbox || ProjectSandbox.new
        @config = @config_loader.load
      end

      def autocorrect(input_path, options = {})
        return failure("Path input cannot be nil") if input_path.nil?
        return failure("Path input cannot be empty") if input_path.to_s.strip.empty?

        max_suggestions = options.fetch(:max_suggestions, 10)
        use_fzf = options.fetch(:use_fzf, fzf_enabled?)
        min_similarity = options.fetch(:min_similarity, min_similarity_threshold)

        # Try exact match first
        exact_matches = find_exact_matches(input_path)
        return success(exact_matches.first) unless exact_matches.empty?

        # Try fuzzy matching
        candidates = find_candidates(input_path)

        if use_fzf && candidates.length > 1
          fzf_result = use_fzf_selection(candidates, input_path)
          return fzf_result if fzf_result[:success]
        end

        # Fall back to similarity scoring
        scored_matches = score_candidates(candidates, input_path, min_similarity)
        best_matches = scored_matches.take(max_suggestions)

        return failure("No similar paths found for: #{input_path}") if best_matches.empty?
        return success(best_matches.first[:path]) if best_matches.length == 1

        # Multiple good matches
        success_with_suggestions(best_matches.map { |match| match[:path] })
      end

      def suggest_corrections(input_path, max_suggestions = 5)
        return [] if input_path.nil? || input_path.to_s.strip.empty?

        candidates = find_candidates(input_path)
        scored = score_candidates(candidates, input_path, 0.3)

        scored.take(max_suggestions).map do |match|
          {
            path: match[:path],
            score: match[:score],
            explanation: generate_explanation(input_path, match[:path], match[:score])
          }
        end
      end

      def interactive_select(input_path, candidates = nil)
        candidates ||= find_candidates(input_path)
        return failure("No candidates found") if candidates.empty?

        if fzf_available? && fzf_enabled?
          use_fzf_selection(candidates, input_path)
        else
          # Simple numbered selection fallback
          present_numbered_selection(candidates)
        end
      end

      private

      def find_exact_matches(input_path)
        # Try to find exact matches considering different contexts
        search_paths = generate_search_paths(input_path)

        search_paths.filter_map do |path|
          next unless File.exist?(path)

          validation = @sandbox.validate_path(path)
          validation[:success] ? validation[:path] : nil
        end
      end

      def generate_search_paths(input_path)
        paths = []

        # As provided
        paths << input_path

        # Relative to project root
        paths << File.join(@sandbox.project_root, input_path) unless Pathname.new(input_path).absolute?

        # With common extensions if no extension provided
        unless File.extname(input_path) != ""
          [".md", ".rb", ".yml", ".yaml", ".sh"].each do |ext|
            paths << "#{input_path}#{ext}"
            paths << File.join(@sandbox.project_root, "#{input_path}#{ext}")
          end
        end

        # In important directories
        important_dirs = @config.dig("resolution", "file_preferences", "important_directories") || []
        important_dirs.each do |dir|
          dir_path = File.join(@sandbox.project_root, dir)
          next unless Dir.exist?(dir_path)

          basename = File.basename(input_path)
          paths << File.join(dir_path, basename)

          # With extensions
          next if File.extname(basename) != ""

          [".md", ".rb", ".yml", ".yaml", ".sh"].each do |ext|
            paths << File.join(dir_path, "#{basename}#{ext}")
          end
        end

        paths.uniq
      end

      def find_candidates(input_path)
        candidates = []
        search_pattern = File.basename(input_path).downcase

        # Search across all configured repositories
        repositories = @config.dig("repositories", "scan_order") || default_repositories

        repositories.each do |repo|
          repo_path = File.join(@sandbox.project_root, repo["path"])
          next unless Dir.exist?(repo_path)

          repo_candidates = scan_directory_for_candidates(repo_path, search_pattern, repo["priority"])
          candidates.concat(repo_candidates)
        end

        # Remove duplicates and validate paths
        candidates.uniq.filter_map do |path|
          validation = @sandbox.validate_path(path)
          validation[:success] ? validation[:path] : nil
        end
      end

      def scan_directory_for_candidates(directory, pattern, priority = 1)
        candidates = []
        max_files = @config.dig("performance", "limits", "max_files_scan") || 1000

        Find.find(directory) do |path|
          break if candidates.length >= max_files

          next unless File.file?(path)
          next unless matches_preferred_extensions?(path)

          basename = File.basename(path).downcase
          dirname = File.dirname(path).downcase

          # Score based on basename and directory name similarity
          if basename.include?(pattern) || dirname.include?(pattern) ||
              levenshtein_distance(basename, pattern) <= 3
            candidates << path
          end
        end

        candidates.sort_by { |path| [priority, File.basename(path)] }
      rescue
        []
      end

      def matches_preferred_extensions?(path)
        preferred = @config.dig("resolution", "file_preferences", "preferred_extensions") ||
          [".md", ".rb", ".yml", ".yaml", ".sh"]

        preferred.any? { |ext| path.end_with?(ext) }
      end

      def score_candidates(candidates, input_path, min_similarity)
        input_basename = File.basename(input_path).downcase

        scored = candidates.map do |candidate|
          candidate_basename = File.basename(candidate).downcase
          score = calculate_similarity_score(input_basename, candidate_basename)

          {
            path: candidate,
            score: score,
            basename: candidate_basename
          }
        end

        scored
          .select { |match| match[:score] >= min_similarity }
          .sort_by { |match| -match[:score] }
      end

      def calculate_similarity_score(input, candidate)
        # Exact match gets highest score
        return 1.0 if input == candidate

        # Substring match gets high score
        return 0.9 if candidate.include?(input) || input.include?(candidate)

        # Calculate similarity based on character overlap and edit distance
        char_similarity = character_overlap_score(input, candidate)
        edit_similarity = edit_distance_score(input, candidate)

        # Weighted combination
        (char_similarity * 0.6) + (edit_similarity * 0.4)
      end

      def character_overlap_score(str1, str2)
        return 0.0 if str1.empty? || str2.empty?

        common_chars = (str1.chars & str2.chars).uniq.length
        max_chars = [str1.length, str2.length].max

        common_chars.to_f / max_chars
      end

      def edit_distance_score(str1, str2)
        distance = levenshtein_distance(str1, str2)
        max_length = [str1.length, str2.length].max

        return 1.0 if max_length.zero?

        1.0 - (distance.to_f / max_length)
      end

      def levenshtein_distance(str1, str2)
        # Classic Levenshtein distance algorithm
        return str2.length if str1.empty?
        return str1.length if str2.empty?

        matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1, 0) }

        (0..str1.length).each { |i| matrix[i][0] = i }
        (0..str2.length).each { |j| matrix[0][j] = j }

        (1..str1.length).each do |i|
          (1..str2.length).each do |j|
            cost = (str1[i - 1] == str2[j - 1]) ? 0 : 1
            matrix[i][j] = [
              matrix[i - 1][j] + 1,      # deletion
              matrix[i][j - 1] + 1,      # insertion
              matrix[i - 1][j - 1] + cost # substitution
            ].min
          end
        end

        matrix[str1.length][str2.length]
      end

      def use_fzf_selection(candidates, query)
        return failure("FZF not available") unless fzf_available?

        # Prepare candidates for fzf
        candidate_list = candidates.map { |path| relative_path_for_display(path) }.join("\n")
        fzf_options = @config.dig("integration", "tools", "fzf", "options") || "--height 40% --reverse --border"

        # Run fzf with query
        stdin_data = candidate_list
        command = "fzf #{fzf_options} --query #{Shellwords.escape(query)}"

        stdout, stderr, status = Open3.capture3(command, stdin_data: stdin_data)

        if status.success? && !stdout.strip.empty?
          selected_relative = stdout.strip
          selected_absolute = candidates.find { |c| relative_path_for_display(c) == selected_relative }

          if selected_absolute
            success(selected_absolute)
          else
            failure("Selected path not found in candidates")
          end
        else
          failure("No selection made or FZF error: #{stderr}")
        end
      rescue => e
        failure("FZF execution failed: #{e.message}")
      end

      def present_numbered_selection(candidates)
        display_paths = candidates.map { |path| relative_path_for_display(path) }

        success_with_suggestions(candidates, display_paths)
      end

      def relative_path_for_display(path)
        project_path = Pathname.new(@sandbox.project_root)
        target_path = Pathname.new(path)

        # Check if the path is actually within the project
        if target_path.to_s.start_with?(project_path.to_s)
          target_path.relative_path_from(project_path).to_s
        else
          path # Return original path if it's outside the project
        end
      rescue ArgumentError
        path
      end

      def generate_explanation(_input, _match, score)
        if score >= 0.9
          "Exact or very close match"
        elsif score >= 0.7
          "Close match based on filename similarity"
        elsif score >= 0.5
          "Partial match based on character overlap"
        else
          "Weak match - consider refining your search"
        end
      end

      def fzf_available?
        return @fzf_available if defined?(@fzf_available)

        @fzf_available = system("which fzf > /dev/null 2>&1")
      end

      def fzf_enabled?
        return false unless fzf_available?

        @config.dig("integration", "tools", "fzf", "enabled") != false &&
          @config.dig("resolution", "fuzzy", "use_fzf") != false
      end

      def min_similarity_threshold
        @config.dig("resolution", "fuzzy", "min_similarity") || 0.5
      end

      def default_repositories
        [{"name" => "current", "path" => ".", "priority" => 1}]
      end

      def success(path)
        {success: true, path: path, type: :single}
      end

      def success_with_suggestions(paths, display_paths = nil)
        {
          success: true,
          type: :multiple,
          paths: paths,
          display_paths: display_paths || paths.map { |p| relative_path_for_display(p) },
          message: "Multiple matches found. Please select:"
        }
      end

      def failure(error)
        {success: false, error: error}
      end
    end
  end
end
