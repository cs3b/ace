# frozen_string_literal: true

require "pathname"

module Ace
  module Support
    module Fs
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
          PROTOCOL_PATTERN = %r{^[a-z][a-z0-9+.-]*://}

          # Instance attributes
          attr_reader :source_dir, :project_root

          # Thread-safe protocol resolver registry
          @protocol_resolver = nil
          @protocol_resolver_mutex = Mutex.new

          class << self
            private

            attr_reader :protocol_resolver_mutex
          end

          # === Factory Methods ===

          # Create expander for a source file (config, workflow, template, prompt)
          # Automatically infers source_dir, uses provided or default project_root
          #
          # @param source_file [String] Path to source file
          # @param project_root [String, nil] Optional explicit project root (recommended)
          # @return [PathExpander] Instance with inferred context
          def self.for_file(source_file, project_root: nil)
            expanded_source = File.expand_path(source_file)
            source_dir = File.dirname(expanded_source)

            # Use provided project_root or fall back to current directory
            # Note: For full project root detection, caller should use
            # Ace::Support::Fs::Molecules::ProjectRootFinder and pass the result
            resolved_root = project_root || Dir.pwd

            new(source_dir: source_dir, project_root: resolved_root)
          end

          # Create expander for CLI context (no source file)
          # Uses current directory as source_dir
          #
          # @param project_root [String, nil] Optional explicit project root
          # @return [PathExpander] Instance with CLI context
          def self.for_cli(project_root: nil)
            resolved_root = project_root || Dir.pwd

            new(
              source_dir: Dir.pwd,
              project_root: resolved_root
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
              raise ArgumentError, "PathExpander requires both 'source_dir' and 'project_root' " \
                                   "(got source_dir: #{source_dir.inspect}, project_root: #{project_root.inspect})"
            end

            @source_dir = source_dir
            @project_root = project_root
          end

          # Resolve path using instance context
          # Handles: protocols, source-relative (./), project-relative, env vars, absolute
          #
          # @param path [String] Path to resolve
          # @return [String] Resolved absolute path
          # @raise [PathError] When protocol cannot be resolved
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
            if expanded.start_with?("./", "../")
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
          # Thread-safe registration using mutex.
          #
          # @param resolver [Object] Resolver responding to #resolve(uri)
          def self.register_protocol_resolver(resolver)
            protocol_resolver_mutex.synchronize do
              @protocol_resolver = resolver
            end
          end

          # Get the current protocol resolver (thread-safe)
          # @return [Object, nil] Current resolver or nil
          def self.protocol_resolver
            protocol_resolver_mutex.synchronize do
              @protocol_resolver
            end
          end

          # Reset protocol resolver (for testing)
          # @api private
          def self.reset_protocol_resolver!
            protocol_resolver_mutex.synchronize do
              @protocol_resolver = nil
            end
          end

          # Expand path with tilde and environment variables
          # Legacy stateless method for backward compatibility
          #
          # @param path [String] Path to expand
          # @return [String] Expanded absolute path
          def self.expand(path)
            return nil if path.nil?

            expanded = path.to_s.dup

            # Expand environment variables (uses class_get_env for testability)
            expanded.gsub!(/\$([A-Z_][A-Z0-9_]*)/i) do |match|
              class_get_env(match[1..-1]) || match
            end

            # Expand tilde
            File.expand_path(expanded)
          end

          # Access environment variable by name (class-level)
          # Extracted to allow test stubbing without modifying global ENV
          #
          # @param var_name [String] Environment variable name
          # @return [String, nil] Environment variable value or nil if not set
          def self.class_get_env(var_name)
            ENV[var_name]
          end

          # Join path components safely
          #
          # @param parts [Array<String>] Path parts to join
          # @return [String] Joined path
          def self.join(*parts)
            parts = parts.flatten.compact.map(&:to_s)
            return "" if parts.empty?

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

            path_str = path.to_s
            Pathname.new(path_str).absolute?
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

          protected

          # Access environment variable by name
          # Extracted to allow test stubbing without modifying global ENV
          #
          # @param var_name [String] Environment variable name
          # @return [String, nil] Environment variable value or nil if not set
          def get_env(var_name)
            ENV[var_name]
          end

          private

          # Resolve protocol URI
          # @raise [PathError] if no protocol resolver is registered
          def resolve_protocol(uri)
            resolver = self.class.protocol_resolver
            if resolver && resolver.respond_to?(:resolve)
              result = resolver.resolve(uri)
              # If resolver returns a Resource with path, extract it
              return result.path if result.respond_to?(:path)
              # Otherwise return the result as-is
              return result
            end

            # No resolver registered - raise exception for consistent error handling
            raise PathError,
              "Protocol '#{uri}' could not be resolved. " \
              "Register a protocol resolver with PathExpander.register_protocol_resolver(resolver)"
          end

          # Expand environment variables in path
          #
          # @note If an environment variable is not set, the original reference
          #   (e.g., "$VAR" or "${VAR}") is preserved in the output. This allows
          #   deferred resolution or detection of missing variables by the caller.
          #   Callers should validate paths if undefined variables are unacceptable.
          #
          # @param path [String] Path containing environment variable references
          # @return [String] Path with environment variables expanded
          def expand_env_vars(path)
            expanded = path.dup

            # Handle ${VAR} format
            expanded.gsub!(/\$\{([A-Z_][A-Z0-9_]*)\}/i) do |match|
              var_name = match[2..-2] # Remove ${ and }
              get_env(var_name) || match
            end

            # Handle $VAR format
            expanded.gsub!(/\$([A-Z_][A-Z0-9_]*)/i) do |match|
              get_env(match[1..-1]) || match
            end

            expanded
          end
        end
      end
    end
  end
end
