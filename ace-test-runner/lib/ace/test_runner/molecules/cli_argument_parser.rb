# frozen_string_literal: true

require_relative "package_resolver"

module Ace
  module TestRunner
    module Molecules
      # Parses CLI arguments to identify package, target, and test files.
      # Handles the complexity of distinguishing between:
      # - Direct file paths (./path/file.rb, ../path/file.rb, /abs/path/file.rb)
      # - Package-prefixed file paths (ace-bundle/test/file.rb)
      # - Package names (ace-bundle)
      # - Test targets (atoms, molecules, unit, etc.)
      class CliArgumentParser
        KNOWN_TARGETS = %w[atoms molecules organisms models unit integration int all quick].freeze

        attr_reader :package_dir, :target, :test_files

        # @param argv [Array<String>] Command line arguments (will be modified)
        # @param package_resolver [PackageResolver] Optional resolver for testing
        def initialize(argv, package_resolver: nil)
          @argv = argv
          @package_resolver = package_resolver || PackageResolver.new
          @package_dir = nil
          @target = nil
          @test_files = []
        end

        # Parse arguments and populate package_dir, target, test_files.
        #
        # Parsing precedence (order matters for correct classification):
        # 1. Existing files (./path/file.rb, ../path/file.rb) - direct file paths
        # 2. Package-prefixed file paths (ace-bundle/test/file.rb) - sets package + adds file
        # 3. Package names (ace-bundle) - sets package directory
        # 4. Known targets (atoms, molecules, etc.) - sets test target
        # 5. Relative file paths within package (test/file.rb when package is set)
        # 6. Unrecognized args - treated as custom targets for PatternResolver
        #
        # @return [Hash] Parsed options with :package_dir, :target, :files keys
        def parse
          parse_first_argument
          parse_remaining_arguments

          result = {}
          result[:package_dir] = @package_dir if @package_dir
          result[:target] = @target if @target
          result[:files] = @test_files unless @test_files.empty?
          result
        end

        # Check if an argument is a known test target
        # @param arg [String] The argument to check
        # @return [Boolean]
        def known_target?(arg)
          KNOWN_TARGETS.include?(arg)
        end

        private

        # Extract file path and optional line number from a path string.
        # Handles both "file.rb" and "file.rb:42" formats.
        # @param path [String] File path, optionally with :line suffix
        # @return [Array(String, String|nil)] [file_path, line_number]
        def extract_file_and_line(path)
          if path =~ /^(.+\.rb):(\d+)$/
            [$1, $2]
          else
            [path, nil]
          end
        end

        # Split a package-prefixed path into package name and file path.
        # Example: "ace-bundle/test/file.rb" -> ["ace-bundle", "test/file.rb"]
        # @param arg [String] Package-prefixed path
        # @return [Array(String, String)] [package_name, file_path]
        def split_package_prefix(arg)
          arg.split("/", 2)
        end

        # Format a file path with optional line number.
        # @param file_path [String] The file path
        # @param line_number [String, nil] Optional line number
        # @return [String] Formatted path (e.g., "file.rb" or "file.rb:42")
        def format_file_with_line(file_path, line_number)
          line_number ? "#{file_path}:#{line_number}" : file_path
        end

        def parse_first_argument
          first_arg_index = @argv.find_index { |arg| !arg.start_with?("-") }
          return unless first_arg_index

          first_arg = @argv[first_arg_index]

          # First, check if the argument is an existing file (handles ./path/file.rb, ../path/file.rb)
          # This must be checked BEFORE package detection to avoid misclassification
          if existing_file?(first_arg)
            @test_files << first_arg
            @argv.delete_at(first_arg_index)
            return
          end

          # Check for package-prefixed file path (e.g., ace-bundle/test/foo_test.rb)
          if package_prefixed_file_path?(first_arg)
            handle_package_prefixed_path(first_arg, first_arg_index)
            return
          end

          # Check if first arg is a package (not a known target, not a ruby file, not file:line)
          return if @package_dir || !@test_files.empty?

          handle_potential_package(first_arg, first_arg_index)
        end

        def parse_remaining_arguments
          @argv.each do |arg|
            next if arg.start_with?("-")

            # Check package-prefixed paths first (before file_with_line?) to handle
            # cases like "ace-bundle/test/file.rb:42" correctly when package is resolved
            if @package_dir && handle_remaining_package_prefixed_path(arg)
              next
            elsif file_with_line?(arg)
              handle_file_with_line(arg)
            elsif existing_ruby_file?(arg)
              @test_files << arg
            elsif package_relative_ruby_file?(arg)
              @test_files << arg
            elsif known_target?(arg)
              @target = normalize_target(arg)
            elsif @target.nil? && !File.exist?(arg)
              # Unrecognized target - will be handled by PatternResolver
              @target = arg
            end
          end
        end

        def normalize_target(arg)
          arg == "int" ? "integration" : arg
        end

        def existing_file?(arg)
          file_arg = arg.sub(/:\d+$/, "") # Strip line number if present
          File.file?(file_arg) && file_arg.end_with?(".rb")
        end

        def package_prefixed_file_path?(arg)
          arg.include?("/") && (arg.end_with?(".rb") || arg =~ /\.rb:\d+$/)
        end

        # Handle package-prefixed file paths in remaining args when package already resolved.
        # Example: "ace-bundle ace-bundle/test/foo.rb" - second arg should be recognized
        # as a file within the already-resolved package.
        # @return [Boolean] true if arg was handled as a package-prefixed file
        def handle_remaining_package_prefixed_path(arg)
          return false unless package_prefixed_file_path?(arg)

          potential_package, file_path = split_package_prefix(arg)

          # Check if the prefix matches our resolved package
          resolved_package = @package_resolver.resolve(potential_package)
          return false unless resolved_package == @package_dir

          file_path_only, line_number = extract_file_and_line(file_path)

          full_file_path = File.join(@package_dir, file_path_only)
          return false unless File.exist?(full_file_path)

          @test_files << format_file_with_line(file_path_only, line_number)
          true
        end

        def handle_package_prefixed_path(arg, index)
          # Split into package name and file path using first "/" as delimiter.
          # This assumes package names don't contain "/" (true for all ace-* packages).
          # Note: If a package were ever named with "/" (e.g., "ace/context"), this
          # would misparse it. Current ace-* naming convention prevents this issue.
          potential_package, file_path = split_package_prefix(arg)
          file_path_only, line_number = extract_file_and_line(file_path)

          # Try to resolve the package
          resolved_package = @package_resolver.resolve(potential_package)
          return unless resolved_package

          full_file_path = File.join(resolved_package, file_path_only)
          return unless File.exist?(full_file_path)

          @package_dir = resolved_package
          @test_files << format_file_with_line(file_path_only, line_number)
          @argv.delete_at(index)
        end

        def handle_potential_package(arg, index)
          return unless potential_package?(arg)

          # Try to resolve as package (works for package names and explicit paths)
          resolved_path = @package_resolver.resolve(arg)
          if resolved_path
            @package_dir = resolved_path
            @argv.delete_at(index)
          elsif explicit_path?(arg)
            raise_package_not_found_error(arg)
          elsif looks_like_package_name?(arg)
            # Package-like name (e.g., ace-foo) that didn't resolve - give helpful error
            raise_package_not_found_error(arg)
          end
          # Otherwise, fall through and let it be handled as target/file
        end

        # Check if argument looks like a package name (ace-* pattern)
        def looks_like_package_name?(arg)
          arg.start_with?("ace-") && !arg.include?("/")
        end

        # Check if an argument could be a package name (not a target, file, or file:line)
        def potential_package?(arg)
          !known_target?(arg) &&
            !(arg.end_with?(".rb") && File.file?(arg)) &&
            !file_with_line?(arg)
        end

        def explicit_path?(arg)
          arg.start_with?("./", "../", "/")
        end

        def file_with_line?(arg)
          arg =~ /^(.+):(\d+)$/
        end

        def handle_file_with_line(arg)
          file_part, line_part = extract_file_and_line(arg)

          # If we have a package_dir, make the path relative to it
          check_path = @package_dir ? File.join(@package_dir, file_part) : file_part

          unless File.exist?(check_path)
            raise ArgumentError, "File not found: #{check_path}"
          end

          # Store the path that will work from the package directory
          @test_files << (@package_dir ? format_file_with_line(file_part, line_part) : arg)
        end

        def existing_ruby_file?(arg)
          File.exist?(arg) && arg.end_with?(".rb")
        end

        def package_relative_ruby_file?(arg)
          @package_dir && File.exist?(File.join(@package_dir, arg)) && arg.end_with?(".rb")
        end

        def raise_package_not_found_error(arg)
          message = "Package not found: #{arg}\n"
          message += if Dir.exist?(arg)
            "Directory exists but has no test/ subdirectory.\n"
          else
            "Directory does not exist.\n"
          end

          available = @package_resolver.available_packages
          message += "Available packages: #{available.join(", ")}" if available.any?

          raise ArgumentError, message
        end
      end
    end
  end
end
