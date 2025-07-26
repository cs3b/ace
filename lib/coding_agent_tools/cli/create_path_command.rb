# frozen_string_literal: true

require "dry/cli"
require "open3"
require "shellwords"

module CodingAgentTools
  module Cli
    # CreatePath command for creating files and directories with metadata and templates
    class CreatePathCommand < Dry::CLI::Command
      desc "Create files and directories with content from templates and metadata"

      argument :type, desc: "Type of creation (task-new, file, directory, docs-new, template)"
      argument :target, desc: "Target identifier (title for new items, path for files/directories)"

      option :title, desc: "Title for new path generation (alternative to target argument)"
      option :force, type: :boolean, default: false, aliases: ["f"],
        desc: "Force overwrite existing files without confirmation"
      option :content, type: :string, desc: "Direct content for file creation"
      option :template, type: :string, desc: "Custom template path (for template type)"

      # Metadata options that become template variables
      option :priority, type: :string, values: %w[high medium low],
        desc: "Priority level (for task creation)"
      option :estimate, type: :string, desc: "Time estimate (e.g., '4h', '2d')"
      option :dependencies, type: :string, desc: "Comma-separated list of dependencies"
      option :status, type: :string, values: %w[pending in-progress done blocked],
        desc: "Initial status"

      example [
        'task-new "implement-feature-x" --priority high --estimate 4h',
        'file README.md --content "# My Project"',
        'directory src/components',
        'docs-new "api-documentation" --title "API Documentation"',
        'template my-doc.md --template custom-template.md --title "Custom Doc"'
      ]

      def call(type:, target:, **options)
        # Initialize components
        @path_resolver = Molecules::PathResolver.new
        @file_handler = Molecules::FileIoHandler.new
        @security_validator = Molecules::SecurePathValidator.new
        @config_loader = load_create_path_config

        # Get target from title option if not provided as argument
        actual_target = target || options[:title]

        if actual_target.nil? || actual_target.strip.empty?
          puts "Error: Target required for path creation"
          puts "Usage: create-path TYPE TARGET [OPTIONS]"
          puts "       create-path TYPE --title 'Title'"
          return 1
        end

        # Process the creation request
        result = process_creation(type, actual_target, options)
        
        if result[:success]
          puts result[:message]
          puts "Created: #{result[:path]}" if result[:path]
          return 0
        else
          puts "Error: #{result[:error]}"
          return 1
        end
      rescue => e
        puts "Error: #{e.message}"
        return 1
      end

      private

      def process_creation(type, target, options)
        case type
        when "task-new"
          create_with_nav_path_and_template(:task_new, target, options)
        when "docs-new" 
          create_with_nav_path_and_template(:docs_new, target, options)
        when "file"
          create_file(target, options)
        when "directory"
          create_directory(target, options)
        when "template"
          create_with_custom_template(target, options)
        else
          {success: false, error: "Unknown creation type '#{type}'"}
        end
      end

      def create_with_nav_path_and_template(nav_type, title, options)
        # Use PathResolver to get the target path (delegates to nav-path logic)
        path_result = @path_resolver.resolve_path(title, type: nav_type)
        
        unless path_result[:success]
          return {success: false, error: "Path resolution failed: #{path_result[:error]}"}
        end

        target_path = path_result[:path]

        # Get template configuration
        template_config = get_template_config(nav_type.to_s.gsub("_", "-"))
        
        unless template_config
          return {success: false, error: "No template configuration found for #{nav_type}"}
        end

        # Generate content from template
        content = generate_content_from_template(template_config, title, options)
        
        # Create the file
        create_file_with_content(target_path, content, options)
      end

      def create_file(target, options)
        # Validate path
        validation_result = @security_validator.validate_path(target, operation: :write)
        unless validation_result.valid?
          return {success: false, error: "Path validation failed: #{validation_result.error_message}"}
        end

        validated_path = validation_result.sanitized_path

        # Get content from options or prompt
        content = options[:content] || ""
        
        if content.empty?
          return {success: false, error: "Content required for file creation (use --content)"}
        end

        create_file_with_content(validated_path, content, options)
      end

      def create_directory(target, options)
        # Validate path
        validation_result = @security_validator.validate_path(target, operation: :write)
        unless validation_result.valid?
          return {success: false, error: "Path validation failed: #{validation_result.error_message}"}
        end

        validated_path = validation_result.sanitized_path

        # Check if directory already exists
        if Dir.exist?(validated_path) && !options[:force]
          return {success: false, error: "Directory already exists (use --force to proceed anyway)"}
        end

        # Create directory
        begin
          FileUtils.mkdir_p(validated_path)
          {success: true, message: "Directory created successfully", path: validated_path}
        rescue => e
          {success: false, error: "Failed to create directory: #{e.message}"}
        end
      end

      def create_with_custom_template(target, options)
        template_path = options[:template]
        
        unless template_path
          return {success: false, error: "Template path required (use --template)"}
        end

        # Validate target path
        validation_result = @security_validator.validate_path(target, operation: :write)
        unless validation_result.valid?
          return {success: false, error: "Path validation failed: #{validation_result.error_message}"}
        end

        validated_path = validation_result.sanitized_path

        # Read template content
        begin
          template_content = File.read(template_path)
        rescue => e
          return {success: false, error: "Failed to read template: #{e.message}"}
        end

        # Apply variable substitution
        content = apply_variable_substitution(template_content, target, options)

        create_file_with_content(validated_path, content, options)
      end

      def create_file_with_content(path, content, options)
        begin
          # Use FileIoHandler for secure file writing
          @file_handler.write_content(content, path, force: options[:force])
          {success: true, message: "File created successfully", path: path}
        rescue CodingAgentTools::Error => e
          {success: false, error: e.message}
        end
      end

      def get_template_config(type)
        @config_loader.dig("templates", type)
      end

      def generate_content_from_template(template_config, title, options)
        template_path = template_config["template"]
        
        unless template_path && File.exist?(template_path)
          raise "Template file not found: #{template_path}"
        end

        # Read template content
        template_content = File.read(template_path)

        # Apply variable substitution
        apply_variable_substitution(template_content, title, options, template_config["variables"] || {})
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
        result = apply_built_in_variables(result)

        result
      end

      def build_metadata_hash(title, options)
        metadata = {
          "title" => title,
          "slug" => slugify(title)
        }

        # Add all provided options as metadata
        options.each do |key, value|
          next if value.nil?
          metadata[key.to_s] = value
        end

        # Apply defaults if config loader is available
        if @config_loader
          defaults = @config_loader.dig("variable_processors", "defaults") || {}
          defaults.each do |key, default_value|
            metadata[key] = default_value unless metadata.key?(key)
          end
        end

        metadata
      end

      def resolve_variable_value(source, metadata)
        case source
        when "user_input"
          metadata["title"]
        when /^datetime:/
          Time.now.strftime(source.sub("datetime:", ""))
        when /^\{metadata\.(.+)\}$/
          metadata[$1] || ""
        else
          # Execute command or return literal value
          if source.include?(" ")
            execute_command(source)
          else
            source
          end
        end
      end

      def execute_command(command)
        # Execute command safely and return output using Open3
        # Security check: reject commands with shell metacharacters
        if command.match?(/[;&|`$<>(){}\\]/)
          return "unknown"
        end
        
        # Parse command into executable and arguments
        command_parts = Shellwords.split(command)
        return "unknown" if command_parts.empty?
        
        executable = command_parts.first
        args = command_parts[1..]
        
        # Whitelist only safe commands (extend as needed)
        safe_commands = %w[date echo pwd whoami hostname uname git]
        unless safe_commands.include?(executable)
          return "unknown"
        end
        
        begin
          stdout, stderr, status = Open3.capture3(executable, *args)
          if status.success?
            stdout.strip
          else
            # Log the error for debugging but return unknown for security
            "unknown"
          end
        rescue => e
          # Command execution failed, return default
          "unknown"
        end
      end

      def apply_built_in_variables(content)
        # Apply built-in timestamp variables
        now = Time.now
        content
          .gsub("{timestamp}", now.strftime("%Y%m%d-%H%M%S"))
          .gsub("{date}", now.strftime("%Y-%m-%d"))
          .gsub("{time}", now.strftime("%H:%M:%S"))
      end

      def slugify(text)
        text.to_s
          .downcase
          .gsub(/[^\w\s-]/, "")
          .gsub(/\s+/, "-")
          .squeeze("-")
          .strip
          .gsub(/^-|-$/, "")
      end

      def load_create_path_config
        config_path = File.join(
          @path_resolver.project_root,
          ".coding-agent",
          "create-path.yml"
        )

        if File.exist?(config_path)
          require "yaml"
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