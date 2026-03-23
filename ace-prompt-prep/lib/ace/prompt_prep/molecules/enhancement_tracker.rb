# frozen_string_literal: true

require "fileutils"
require "digest"
require "ace/support/fs"

module Ace
  module PromptPrep
    module Molecules
      # Tracks enhancement iterations and manages enhancement cache
      class EnhancementTracker
        # Default directories (fallback if config unavailable)
        DEFAULT_CACHE_DIR = Ace::PromptPrep::Defaults::DEFAULT_CACHE_DIR
        DEFAULT_ENHANCE_CACHE = "enhance-cache"
        DEFAULT_ARCHIVE_DIR = "prompts/archive"

        # Get enhance cache directory from config
        # @return [String] Enhance cache directory relative to project root
        def self.enhance_cache_dir
          config = Ace::PromptPrep.config
          cache_dir = config.dig("paths", "cache_dir") || DEFAULT_CACHE_DIR
          enhance_cache = config.dig("paths", "enhance_cache") || DEFAULT_ENHANCE_CACHE
          File.join(cache_dir, enhance_cache)
        end

        # Get archive directory from config
        # @return [String] Archive directory relative to project root
        def self.archive_dir
          config = Ace::PromptPrep.config
          cache_dir = config.dig("paths", "cache_dir") || DEFAULT_CACHE_DIR
          archive = config.dig("paths", "archive_dir") || DEFAULT_ARCHIVE_DIR
          File.join(cache_dir, archive)
        end

        # Calculate cache key including all parameters that affect output
        #
        # @param content [String] Content to enhance
        # @param model [String] Model identifier
        # @param system_prompt_content [String] Resolved system prompt content (not URI)
        # @param temperature [Float] Temperature for LLM generation
        # @return [String] SHA256 hash of combined parameters
        # @note Uses resolved system prompt content so cache invalidates when prompt changes
        def self.cache_key(content, model, system_prompt_content, temperature)
          # Hash the system prompt content to keep cache key manageable
          system_prompt_hash = Digest::SHA256.hexdigest(system_prompt_content || "")
          key_material = "#{content}|#{model}|#{system_prompt_hash}|#{temperature}"
          Digest::SHA256.hexdigest(key_material)
        end

        # Calculate content hash for cache lookup (legacy - content only)
        #
        # @param content [String] Content to hash
        # @return [String] SHA256 hash
        # @deprecated Use cache_key instead for full parameter tracking
        def self.content_hash(content)
          Digest::SHA256.hexdigest(content)
        end

        # Check if content exists in cache
        #
        # @param hash [String] Content hash
        # @return [Boolean] True if cached
        def self.cached?(hash)
          project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          cache_path = File.join(project_root, enhance_cache_dir, "#{hash}.md")
          File.exist?(cache_path)
        end

        # Get cached content
        #
        # @param hash [String] Content hash
        # @return [String, nil] Cached content or nil if not found
        def self.get_cached(hash)
          project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          cache_path = File.join(project_root, enhance_cache_dir, "#{hash}.md")
          return nil unless File.exist?(cache_path)

          File.read(cache_path, encoding: "utf-8")
        rescue => e
          warn "Warning: Failed to read cache: #{e.message}"
          nil
        end

        # Store content in cache
        #
        # @param hash [String] Content hash
        # @param content [String] Content to cache
        # @return [Boolean] True if successful
        def self.store_cache(hash, content)
          project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          cache_dir_path = File.join(project_root, enhance_cache_dir)
          FileUtils.mkdir_p(cache_dir_path)

          cache_path = File.join(cache_dir_path, "#{hash}.md")
          File.write(cache_path, content, encoding: "utf-8")
          true
        rescue => e
          warn "Warning: Failed to store cache: #{e.message}"
          false
        end

        # Calculate next iteration number for a session ID
        #
        # @param session_id [String] Base36 session ID (e.g., "i50jj3")
        # @return [Integer] Next iteration number (1, 2, 3, etc.)
        def self.next_iteration(session_id)
          project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          archive_dir_path = File.join(project_root, archive_dir)

          return 1 unless Dir.exist?(archive_dir_path)

          # Find all enhancement files for this session ID
          pattern = File.join(archive_dir_path, "#{session_id}_e*.md")
          existing_files = Dir.glob(pattern)

          return 1 if existing_files.empty?

          # Extract iteration numbers and find max
          iterations = existing_files.map do |file|
            basename = File.basename(file, ".md")
            match = basename.match(/_e(\d+)$/)
            match ? match[1].to_i : 0
          end

          iterations.max + 1
        end

        # Generate enhancement archive filename
        #
        # @param session_id [String] Base36 session ID (e.g., "i50jj3")
        # @param iteration [Integer] Iteration number
        # @return [String] Filename (e.g., "i50jj3_e001.md")
        def self.enhancement_filename(session_id, iteration)
          "#{session_id}_e#{iteration.to_s.rjust(3, "0")}.md"
        end
      end
    end
  end
end
