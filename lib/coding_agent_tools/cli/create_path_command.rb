# frozen_string_literal: true

require 'dry/cli'
require 'open3'
require 'shellwords'
require 'fileutils'

module CodingAgentTools
  module Cli
    # CreatePath command for creating files and directories with metadata and templates
    class CreatePathCommand < Dry::CLI::Command
      desc 'Create files and directories with content from templates and metadata'

      argument :type,
        desc: 'Type of creation (task-new, file, directory, docs-new, template) or delegation format (file:docs-new, file:reflection-new, directory:code-review-new)'

      option :title, desc: 'Title for new path generation', required: true
      option :force, type: :boolean, default: false, aliases: ['f'],
        desc: 'Force overwrite existing files without confirmation'
      option :content, type: :string, desc: 'Direct content for file creation'
      option :template, type: :string, desc: 'Custom template path (for template type)'

      # Metadata options that become template variables
      option :priority, type: :string, values: ['high', 'medium', 'low'],
        desc: 'Priority level (for task creation)'
      option :estimate, type: :string, desc: "Time estimate (e.g., '4h', '2d')"
      option :dependencies, type: :string, desc: 'Comma-separated list of dependencies'
      option :status, type: :string, values: ['pending', 'in-progress', 'done', 'blocked', 'draft'],
        desc: 'Initial status'

      example [
        'task-new --title "implement-feature-x" --priority high --estimate 4h',
        'file --title "README.md" --content "# My Project"',
        'directory --title "src/components"',
        'docs-new --title "API Documentation"',
        'template --title "my-doc.md" --template custom-template.md',
        'file:docs-new --title "API Guide"',
        'file:reflection-new --title "oauth-implementation-review"',
        'directory:code-review-new --title "authentication-session"'
      ]

      def call(type:, **options)
        # Initialize components
        @path_resolver = Molecules::PathResolver.new
        @file_handler = Molecules::FileIoHandler.new
        @security_validator = Molecules::SecurePathValidator.new
        @config_loader = load_create_path_config

        # Parse undefined flags from ARGV and merge with options
        undefined_flags = parse_undefined_flags(ARGV)
        enhanced_options = options.merge(undefined_flags)

        # Get target from title option (now required)
        actual_target = enhanced_options[:title]

        if actual_target.nil? || actual_target.strip.empty?
          puts 'Error: Title required for path creation'
          puts "Usage: create-path TYPE --title 'Title' [OPTIONS]"
          return 1
        end

        # Process the creation request
        result = process_creation(type, actual_target, enhanced_options)

        if result[:success]
          puts result[:message]
          puts "Created: #{result[:path]}" if result[:path]

          # Report dynamic flags that were added
          dynamic_flags = undefined_flags.reject { |k, _| k == :title }
          unless dynamic_flags.empty?
            flag_summary = dynamic_flags.map { |k, v| "#{k}=#{v}" }.join(', ')
            puts "Added metadata: #{flag_summary}"
          end

          0
        else
          puts "Error: #{result[:error]}"
          1
        end
      rescue => e
        puts "Error: #{e.message}"
        1
      end

      private

      # Parse undefined flags from ARGV that weren't processed by dry-cli
      # This captures dynamic flags like --custom-field value
      def parse_undefined_flags(argv)
        undefined_flags = {}
        defined_flag_names = get_defined_flag_names

        i = 0
        while i < argv.length
          arg = argv[i]

          # Check if this is a flag (starts with --)
          if arg.start_with?('--')
            flag_name = arg.sub(/^--/, '')

            # Skip if this is a defined flag or if it's the command/type
            if defined_flag_names.include?(flag_name) ||
               ['task-new', 'file', 'directory', 'docs-new', 'template'].include?(arg)
              i += 1
              next
            end

            # Look for the value (next argument that doesn't start with --)
            value = nil
            if i + 1 < argv.length && !argv[i + 1].start_with?('--')
              value = argv[i + 1]
              i += 2  # Skip both flag and value
            else
              # Boolean flag with no value
              value = true
              i += 1
            end

            # Validate flag name for security
            if validate_flag_name(flag_name)
              # Convert value to appropriate type and store
              converted_value = convert_flag_value(value)
              undefined_flags[flag_name.tr('-', '_').to_sym] = converted_value
            else
              warn "Warning: Skipped invalid flag name: --#{flag_name}"
            end
          else
            i += 1
          end
        end

        undefined_flags
      rescue => e
        warn "Warning: Error parsing undefined flags: #{e.message}"
        {}
      end

      # Get list of defined flag names for conflict detection
      def get_defined_flag_names
        ['title', 'force', 'content', 'template', 'priority', 'estimate', 'dependencies', 'status']
      end

      # Validate flag name for security and conflicts
      def validate_flag_name(flag_name)
        # Check for valid flag name pattern (letters, numbers, hyphens)
        return false unless flag_name.match?(/\A[a-z][a-z0-9\-]*\z/i)

        # Check length limit
        return false if flag_name.length > 50

        # Check for reserved names
        reserved_names = ['help', 'version', 'debug', 'verbose', 'quiet']
        return false if reserved_names.include?(flag_name)

        true
      end

      # Convert flag value to appropriate YAML type
      def convert_flag_value(value)
        return value unless value.is_a?(String)

        # Handle empty strings
        return '' if value.empty?

        # Try boolean conversion first (but be more specific to avoid conflicts with numbers)
        case value.downcase
        when 'true', 'yes', 'on'
          return true
        when 'false', 'no', 'off'
          return false
        when '1', '0'  # Handle numeric booleans separately to avoid conflicts
          # For '1' and '0', prefer integer interpretation unless explicitly boolean context
          return value.to_i
        end

        # Try integer conversion
        if value.match?(/\A-?\d+\z/)
          return value.to_i
        end

        # Try float conversion
        if value.match?(/\A-?\d+\.\d+\z/)
          return value.to_f
        end

        # Handle arrays (comma-separated values)
        if value.include?(',')
          return value.split(',').map(&:strip)
        end

        # Return as string (default)
        value
      end

      def process_creation(type, target, options)
        # Handle delegation format (file:type, directory:type)
        return process_delegation_type(type, target, options) if type.include?(':')

        case type
        when 'task-new'
          { success: false, error: "The 'task-new' type has been removed. Please use 'task-manager create' instead." }
        when 'docs-new'
          create_with_nav_path_and_template(:docs_new, target, options)
        when 'file'
          create_file(target, options)
        when 'directory'
          create_directory(target, options)
        when 'template'
          create_with_custom_template(target, options)
        else
          { success: false, error: "Unknown creation type '#{type}'" }
        end
      end

      def process_delegation_type(type, target, options)
        creation_type, nav_type = type.split(':', 2)

        case creation_type
        when 'file'
          case nav_type
          when 'docs-new'
            create_with_nav_path_and_template(:docs_new, target, options)
          when 'reflection-new'
            create_with_nav_path_and_template(:reflection_new, target, options)
          else
            { success: false, error: "Unknown delegation nav-type '#{nav_type}' for file creation" }
          end
        when 'directory'
          case nav_type
          when 'code-review-new'
            create_with_nav_path_and_template(:code_review_new, target, options)
          else
            { success: false, error: "Unknown delegation nav-type '#{nav_type}' for directory creation" }
          end
        else
          { success: false, error: "Unknown delegation creation-type '#{creation_type}'. Supported: file, directory" }
        end
      end

      def create_with_nav_path_and_template(nav_type, title, options)
        # Use PathResolver to get the target path (delegates to nav-path logic)
        path_result = @path_resolver.resolve_path(title, type: nav_type)

        return { success: false, error: "Path resolution failed: #{path_result[:error]}" } unless path_result[:success]

        target_path = path_result[:path]

        # Get template configuration
        template_config = get_template_config(nav_type.to_s.tr('_', '-'))

        unless template_config
          # Create empty file with notice when template not found
          puts "Notice: Template not found for #{nav_type} - creating empty file"
          return create_empty_file_with_notice(target_path, nav_type, title, options)
        end

        # Generate content from template
        content = generate_content_from_template(template_config, title, options, nav_type)

        # Create the file
        create_file_with_content(target_path, content, options)
      end

      def create_file(title, options)
        # Use title as the file path
        target = title
        # Validate path
        validation_result = @security_validator.validate_path(target, operation: :write)
        unless validation_result.valid?
          return { success: false, error: "Path validation failed: #{validation_result.error_message}" }
        end

        validated_path = validation_result.sanitized_path

        # Get content from options or prompt
        content = options[:content] || ''

        return { success: false, error: 'Content required for file creation (use --content)' } if content.empty?

        create_file_with_content(validated_path, content, options)
      end

      def create_directory(title, options)
        # Use title as the directory path
        target = title
        # Validate path
        validation_result = @security_validator.validate_path(target, operation: :write)
        unless validation_result.valid?
          return { success: false, error: "Path validation failed: #{validation_result.error_message}" }
        end

        validated_path = validation_result.sanitized_path

        # Check if directory already exists
        if Dir.exist?(validated_path) && !options[:force]
          return { success: false, error: 'Directory already exists (use --force to proceed anyway)' }
        end

        # Create directory
        begin
          FileUtils.mkdir_p(validated_path)
          { success: true, message: 'Directory created successfully', path: validated_path }
        rescue => e
          { success: false, error: "Failed to create directory: #{e.message}" }
        end
      end

      def create_with_custom_template(title, options)
        template_path = options[:template]

        return { success: false, error: 'Template path required (use --template)' } unless template_path

        # Use title as the target path
        target = title
        # Validate target path
        validation_result = @security_validator.validate_path(target, operation: :write)
        unless validation_result.valid?
          return { success: false, error: "Path validation failed: #{validation_result.error_message}" }
        end

        validated_path = validation_result.sanitized_path

        # Read template content
        begin
          template_content = File.read(template_path)
        rescue => e
          return { success: false, error: "Failed to read template: #{e.message}" }
        end

        # Apply variable substitution
        content = apply_variable_substitution(template_content, title, options)

        create_file_with_content(validated_path, content, options)
      end

      def create_file_with_content(path, content, options)
        # Use FileIoHandler for secure file writing
        @file_handler.write_content(content, path, force: options[:force])
        { success: true, message: 'File created successfully', path: path }
      rescue CodingAgentTools::Error => e
        { success: false, error: e.message }
      end

      def get_template_config(type)
        @config_loader.dig('templates', type)
      end

      def generate_content_from_template(template_config, title, options, nav_type = nil)
        template_path = template_config['template']

        unless template_path && File.exist?(template_path)
          # Return contextual content when template file doesn't exist
          puts "Notice: Template file not found: #{template_path} - creating empty file"
          # Use nav_type if provided, otherwise fall back to template path analysis
          return generate_contextual_content(nav_type, title) if nav_type

          return generate_contextual_content_from_template_context(template_config, title)

        end

        # Read template content
        template_content = File.read(template_path)

        # Apply variable substitution
        apply_variable_substitution(template_content, title, options, template_config['variables'] || {})
      end

      def apply_variable_substitution(content, title, options, template_variables = {})
        result = content.dup

        # Build metadata hash from options and built-ins
        metadata = build_metadata_hash(title, options)

        # Apply template variables first
        template_variables.each do |var, source|
          value = resolve_variable_value(source, metadata)
          result = result.gsub("{#{var}}", value.to_s)
        end

        # Apply direct metadata substitution
        metadata.each do |key, value|
          result = result.gsub("{metadata.#{key}}", value.to_s)
        end

        # Apply built-in variables
        apply_built_in_variables(result)
      end

      def build_metadata_hash(title, options)
        metadata = {
          'title' => title,
          'slug' => slugify(title)
        }

        # Add all provided options as metadata
        options.each do |key, value|
          next if value.nil?

          metadata[key.to_s] = value
        end

        # Apply defaults if config loader is available
        if @config_loader
          defaults = @config_loader.dig('variable_processors', 'defaults') || {}
          defaults.each do |key, default_value|
            metadata[key] = default_value unless metadata.key?(key)
          end
        end

        metadata
      end

      def resolve_variable_value(source, metadata)
        case source
        when 'user_input'
          metadata['title']
        when /^datetime:/
          Time.now.strftime(source.sub('datetime:', ''))
        when /^\{metadata\.(.+)\}$/
          metadata[::Regexp.last_match(1)] || ''
        else
          # Execute command or return literal value
          if source.include?(' ')
            execute_command(source)
          else
            source
          end
        end
      end

      def execute_command(command)
        # Execute command safely and return output using Open3
        # Security check: reject commands with shell metacharacters
        return 'unknown' if command.match?(/[;&|`$<>(){}\\]/)

        # Parse command into executable and arguments
        command_parts = Shellwords.split(command)
        return 'unknown' if command_parts.empty?

        executable = command_parts.first
        args = command_parts[1..]

        # Whitelist only safe commands (extend as needed)
        safe_commands = ['date', 'echo', 'pwd', 'whoami', 'hostname', 'uname', 'git', 'task-manager']
        return 'unknown' unless safe_commands.include?(executable)

        begin
          stdout, _, status = Open3.capture3(executable, *args)
          if status.success?
            stdout.strip
          else
            # Log the error for debugging but return unknown for security
            'unknown'
          end
        rescue
          # Command execution failed, return default
          'unknown'
        end
      end

      def apply_built_in_variables(content)
        # Apply built-in timestamp variables
        now = Time.now
        content
          .gsub('{timestamp}', now.strftime('%Y%m%d-%H%M%S'))
          .gsub('{date}', now.strftime('%Y-%m-%d'))
          .gsub('{time}', now.strftime('%H:%M:%S'))
      end

      def slugify(text)
        slug = text.to_s
          .downcase
          .gsub(/[^\w\s-]/, '')
          .gsub(/\s+/, '-')
          .squeeze('-')
          .strip
          .gsub(/^-|-$/, '')

        # Limit slug length to prevent filesystem filename length issues
        # Truncate at word boundaries to keep it readable
        max_slug_length = 80
        if slug.length > max_slug_length
          # Find the last word boundary (hyphen) within the limit
          truncated = slug[0, max_slug_length]
          last_hyphen = truncated.rindex('-')

          slug = if last_hyphen && last_hyphen > max_slug_length * 0.7 # Keep at least 70% of desired length
            truncated[0, last_hyphen]
          else
                   # Fallback: truncate and clean up
            truncated.gsub(/-+$/, '')
          end
        end

        slug
      end

      def create_empty_file_with_notice(target_path, nav_type, title, options)
        # Ensure target directory exists
        target_dir = File.dirname(target_path)
        begin
          FileUtils.mkdir_p(target_dir) unless File.exist?(target_dir)
        rescue => e
          return { success: false, error: "Failed to create directory: #{e.message}" }
        end

        # Create contextual title based on nav_type and user title
        contextual_content = generate_contextual_content(nav_type, title)

        begin
          @file_handler.write_content(contextual_content, target_path, force: options[:force])
          {
            success: true,
            message: "Empty file created (template not found for #{nav_type})",
            path: target_path
          }
        rescue CodingAgentTools::Error => e
          { success: false, error: e.message }
        rescue => e
          { success: false, error: "Failed to create file: #{e.message}" }
        end
      end

      def generate_contextual_content(nav_type, title)
        case nav_type.to_s
        when 'reflection_new'
          "# Reflection - #{title}\n\n"
        when 'docs_new'
          "# Documentation - #{title}\n\n"
        when 'code_review_new'
          "# Code Review - #{title}\n\n"
        else
          "# #{title.capitalize}\n\n"
        end
      end

      def generate_contextual_content_from_template_context(template_config, title)
        # Extract type from template path to determine context
        template_path = template_config&.dig('template') || ''

        if template_path.include?('docs')
          "# Documentation - #{title}\n\n"
        elsif template_path.include?('reflection')
          "# Reflection - #{title}\n\n"
        elsif template_path.include?('code-review') || template_path.include?('review')
          "# Code Review - #{title}\n\n"
        else
          "# #{title.capitalize}\n\n"
        end
      end

      def load_create_path_config
        config_path = File.join(
          @path_resolver.project_root,
          '.coding-agent',
          'create-path.yml'
        )

        if File.exist?(config_path)
          require 'yaml'
          YAML.load_file(config_path)
        else
          {}
        end
      rescue => e
        puts "Warning: Failed to load create-path config: #{e.message}"
        {}
      end
    end
  end
end
