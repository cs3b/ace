# frozen_string_literal: true

require 'pathname'

module Ace
  module Core
    module Atoms
      # Path expansion and resolution with automatic context inference
      #
      # Supports:
      # - Instance-based API for context-aware resolution
      # - Protocol URIs (wfi://, guide://, tmpl://, task://, prompt://)
      # - Source-relative paths (./, ../)
      # - Project-relative paths (no prefix)
      # - Environment variables ($VAR, ${VAR})
      # - Backward compatible class methods for utilities
      class PathExpander
        # Protocol pattern for URI detection
        PROTOCOL_PATTERN = %r{^[a-z][a-z0-9+.-]*://}.freeze

        # Instance attributes
        attr_reader :source_dir, :project_root

        # Protocol resolver registry
        @@protocol_resolver = nil

        # === Factory Methods ===

        # Create expander for a source file (config, workflow, template, prompt)
        # Automatically infers source_dir and project_root
        #
        # @param source_file [String] Path to source file
        # @return [PathExpander] Instance with inferred context
        def self.for_file(source_file)
          require_relative '../molecules/project_root_finder'

          expanded_source = File.expand_path(source_file)
          source_dir = File.dirname(expanded_source)
          project_root = Molecules::ProjectRootFinder.new.find || Dir.pwd

          new(source_dir: source_dir, project_root: project_root)
        end

        # Create expander for CLI context (no source file)
        # Uses current directory as source_dir
        #
        # @return [PathExpander] Instance with CLI context
        def self.for_cli
          require_relative '../molecules/project_root_finder'

          new(
            source_dir: Dir.pwd,
            project_root: Molecules::ProjectRootFinder.new.find || Dir.pwd
          )
        end

        # === Instance Methods ===

        # Initialize with explicit context
        #
        # @param source_dir [String] Source document directory (REQUIRED)
        # @param project_root [String] Project root directory (REQUIRED)
        # @raise [ArgumentError] if either parameter is nil
        def initialize(source_dir:, project_root:)
          if source_dir.nil? || project_root.nil?
            raise ArgumentError, "PathExpander requires both 'source_dir' and 'project_root' (got source_dir: #{source_dir.inspect}, project_root: #{project_root.inspect})"
          end

          @source_dir = source_dir
          @project_root = project_root
        end

        # Resolve path using instance context
        # Handles: protocols, source-relative (./), project-relative, env vars, absolute
        #
        # @param path [String] Path to resolve
        # @return [String, Hash] Resolved absolute path, or Hash with error for protocols
        def resolve(path)
          return nil if path.nil? || path.empty?

          path_str = path.to_s

          # Check for protocol URIs first
          if self.class.protocol?(path_str)
            return resolve_protocol(path_str)
          end

          # Expand environment variables
          expanded = expand_env_vars(path_str)

          # Handle absolute paths
          return File.expand_path(expanded) if Pathname.new(expanded).absolute?

          # Handle source-relative paths (./ or ../)
          if expanded.start_with?('./') || expanded.start_with?('../')
            return File.expand_path(expanded, @source_dir)
          end

          # Default: project-relative paths
          File.expand_path(expanded, @project_root)
        end

        # === Class Methods (Utilities and Backward Compatibility) ===

        # Check if path is a protocol URI
        #
        # @param path [String] Path to check
        # @return [Boolean] true if protocol format detected
        def self.protocol?(path)
          return false if path.nil? || path.empty?
          !!(path.to_s =~ PROTOCOL_PATTERN)
        end

        # Register a protocol resolver (e.g., ace-nav)
        #
        # @param resolver [Object] Resolver responding to #resolve(uri)
        def self.register_protocol_resolver(resolver)
          @@protocol_resolver = resolver
        end

        # Expand path with tilde and environment variables
        # Legacy stateless method for backward compatibility
        #
        # @param path [String] Path to expand
        # @return [String] Expanded absolute path
        def self.expand(path)
          return nil if path.nil?

          expanded = path.to_s.dup

          # Expand environment variables
          expanded.gsub!(/\$([A-Z_][A-Z0-9_]*)/i) do |match|
            ENV[match[1..-1]] || match
          end

          # Expand tilde
          File.expand_path(expanded)
        end

        # Join path components safely
        #
        # @param parts [Array<String>] Path parts to join
        # @return [String] Joined path
        def self.join(*parts)
          parts = parts.flatten.compact.map(&:to_s)
          return '' if parts.empty?

          File.join(*parts)
        end

        # Get directory name from path
        #
        # @param path [String] File path
        # @return [String] Directory path
        def self.dirname(path)
          return nil if path.nil?

          File.dirname(path.to_s)
        end

        # Get base name from path
        #
        # @param path [String] File path
        # @return [String] Base name
        def self.basename(path, suffix = nil)
          return nil if path.nil?

          if suffix
            File.basename(path.to_s, suffix)
          else
            File.basename(path.to_s)
          end
        end

        # Check if path is absolute
        #
        # @param path [String] Path to check
        # @return [Boolean] true if absolute path
        def self.absolute?(path)
          return false if path.nil?

          Pathname.new(path.to_s).absolute?
        end

        # Make path relative to base
        #
        # @param path [String] Path to make relative
        # @param base [String] Base path
        # @return [String] Relative path
        def self.relative(path, base)
          return nil if path.nil? || base.nil?

          path_obj = Pathname.new(expand(path))
          base_obj = Pathname.new(expand(base))

          path_obj.relative_path_from(base_obj).to_s
        rescue ArgumentError
          # Paths are on different drives or one is relative
          path
        end

        # Normalize path (remove .., ., duplicates slashes)
        #
        # @param path [String] Path to normalize
        # @return [String] Normalized path
        def self.normalize(path)
          return nil if path.nil?

          Pathname.new(path.to_s).cleanpath.to_s
        end

        private

        # Resolve protocol URI
        def resolve_protocol(uri)
          if @@protocol_resolver && @@protocol_resolver.respond_to?(:resolve)
            result = @@protocol_resolver.resolve(uri)
            # If resolver returns a Resource with path, extract it
            return result.path if result.respond_to?(:path)
            # Otherwise return the result as-is
            return result
          end

          # No resolver registered - return error hash
          {
            error: "Protocol resolver not available",
            uri: uri,
            message: "Protocol '#{uri}' could not be resolved. Register a protocol resolver with PathExpander.register_protocol_resolver(resolver)"
          }
        end

        # Expand environment variables in path
        def expand_env_vars(path)
          expanded = path.dup

          # Handle ${VAR} format
          expanded.gsub!(/\$\{([A-Z_][A-Z0-9_]*)\}/i) do |match|
            var_name = match[2..-2]  # Remove ${ and }
            ENV[var_name] || match
          end

          # Handle $VAR format
          expanded.gsub!(/\$([A-Z_][A-Z0-9_]*)/i) do |match|
            ENV[match[1..-1]] || match
          end

          expanded
        end
      end
    end
  end
end

