# frozen_string_literal: true

require 'pathname'
require 'ace/core'
require 'ace/core/molecules/context_merger'
require 'ace/core/molecules/file_aggregator'
require 'ace/core/molecules/output_formatter'
require 'ace/core/molecules/project_root_finder'
require 'ace/core/atoms/command_executor'
require 'ace/core/atoms/template_parser'
require 'ace/core/atoms/file_reader'
require_relative '../molecules/preset_manager'
require_relative '../models/context_data'
require_relative '../atoms/git_extractor'

module Ace
  module Context
    module Organisms
      # Main context loader that orchestrates preset loading using ace-core components
      class ContextLoader
        def initialize(options = {})
          @options = options
          @preset_manager = Molecules::PresetManager.new
          @merger = Ace::Core::Molecules::ContextMerger.new
          @file_aggregator = Ace::Core::Molecules::FileAggregator.new(
            max_size: options[:max_size],
            base_dir: options[:base_dir] || project_root
          )
          @command_executor = Ace::Core::Atoms::CommandExecutor
          @output_formatter = Ace::Core::Molecules::OutputFormatter.new(
            options[:format] || 'markdown-xml'
          )
        end

        def load_preset(preset_name)
          preset = @preset_manager.get_preset(preset_name)
          unless preset
            return Models::ContextData.new(
              preset_name: preset_name,
              metadata: { error: "Preset '#{preset_name}' not found" }
            )
          end

          # Merge params into options for processing
          merged_options = @options.merge(preset[:params] || {})

          # Process the preset context configuration
          context = load_from_preset_config(preset, merged_options)
          context.metadata[:preset_name] = preset_name
          context.metadata[:output] = preset[:output]  # Store default output mode

          # Re-format if format was specified
          format = preset[:format] || preset.dig(:params, 'format') || merged_options[:format] || 'markdown'
          format_context(context, format)

          context
        end

        def load_file(path)
          # Check if it's a template file
          content = File.read(path) rescue nil

          # Treat as template if:
          # 1. TemplateParser recognizes it as a template, OR
          # 2. It has YAML frontmatter (starts with ---)
          is_template = content && (
            Ace::Core::Atoms::TemplateParser.template?(content) ||
            content.start_with?('---')
          )

          if is_template
            # Parse as template
            load_template(path)
          else
            # Load as regular file
            max_size = @options[:max_size] || Ace::Core::Atoms::FileReader::MAX_FILE_SIZE
            result = Ace::Core::Atoms::FileReader.read(path, max_size: max_size)

            context = Models::ContextData.new
            if result[:success]
              context.add_file(path, result[:content])
            else
              context.metadata[:error] = result[:error]
            end

            context
          end
        end

        def load_multiple_presets(preset_names)
          contexts = []

          preset_names.each do |preset_name|
            preset = @preset_manager.get_preset(preset_name)
            if preset
              merged_options = @options.merge(preset[:params] || {})
              context = load_from_preset_config(preset, merged_options)
              context.metadata[:preset_name] = preset_name
              contexts << context
            else
              # Add error but continue
              error_context = Models::ContextData.new(
                preset_name: preset_name,
                metadata: { error: "Preset '#{preset_name}' not found" }
              )
              contexts << error_context
            end
          end

          # Merge all contexts
          merge_contexts(contexts)
        end

        def load_multiple(inputs)
          contexts = []

          inputs.each do |input|
            context = load_auto(input)
            context.metadata[:source_input] = input
            contexts << context
          end

          # Merge all contexts
          merge_contexts(contexts)
        end

        def load_auto(input)
          # Auto-detect input type
          # Strip whitespace to handle CLI arguments properly
          input = input.strip

          # Check for protocol first (e.g., wfi://,  guide://, task://)
          if input.match?(/\A[\w-]+:\/\//)
            return load_protocol(input)
          end

          if File.exist?(input)
            # It's a file
            load_file(input)
          elsif input.match?(/\A[\w-]+\z/)
            # Looks like a preset name
            load_preset(input)
          elsif input.include?('files:') || input.include?('commands:') || input.include?('include:') || input.include?('diffs:') || input.include?('presets:')
            # Looks like inline YAML
            load_inline_yaml(input)
          else
            # Try as file first, then preset
            if File.exist?(input)
              load_file(input)
            else
              load_preset(input)
            end
          end
        end

        def load_inline_yaml(yaml_string)
          begin
            require 'yaml'
            config = YAML.safe_load(yaml_string)
            process_template_config(config)
          rescue => e
            context = Models::ContextData.new
            context.metadata[:error] = "Failed to parse inline YAML: #{e.message}"
            context
          end
        end

        def load_template(path)
          # Read template file
          template_content = File.read(path)

          # Extract and strip frontmatter if present
          frontmatter = {}
          if template_content =~ /\A---\s*\n(.*?)\n---\s*\n/m
            frontmatter_text = $1
            begin
              require 'yaml'
              frontmatter = YAML.safe_load(frontmatter_text) || {}
              frontmatter = {} unless frontmatter.is_a?(Hash)
              # Remove frontmatter from content for processing
              template_content = template_content.sub(/\A---\s*\n.*?\n---\s*\n/m, '')
            rescue Psych::SyntaxError
              # Invalid YAML, ignore frontmatter
            end
          end

          # Check if frontmatter contains config directly (via 'context' key or template config keys)
          # This is the newer pattern for workflow files
          if frontmatter['context'].is_a?(Hash) ||
             (frontmatter.keys & %w[files commands include exclude diffs]).any?
            # Use frontmatter as the main config
            config = frontmatter['context'] || frontmatter

            # Merge params into options if present
            if frontmatter['params'].is_a?(Hash)
              @options = @options.merge(frontmatter['params'])
            end

            # Process the config
            context = process_template_config(config)
            context.metadata[:frontmatter] = frontmatter
            return context
          end

          # Otherwise, parse template configuration from body
          parse_result = Ace::Core::Atoms::TemplateParser.parse(template_content)

          unless parse_result[:success]
            context = Models::ContextData.new
            context.metadata[:error] = parse_result[:error]
            return context
          end

          config = parse_result[:config]

          # Merge frontmatter into config (frontmatter has lower priority)
          config = frontmatter.merge(config) if frontmatter.any?

          # Process files and commands from template
          context = process_template_config(config)

          # Add frontmatter to metadata for reference
          context.metadata[:frontmatter] = frontmatter if frontmatter.any?

          context
        end

        def load_from_config(config)
          # If config has a template path, load from template instead
          if config[:template] && File.exist?(config[:template])
            return load_template(config[:template])
          end

          context = Models::ContextData.new(
            preset_name: config[:name],
            metadata: config[:metadata] || {}
          )

          # Use file aggregator for include patterns
          if config[:include] && config[:include].any?
            aggregator = Ace::Core::Molecules::FileAggregator.new(
              max_size: @options[:max_size],
              base_dir: @options[:base_dir] || project_root,
              exclude: config[:exclude] || []
            )

            result = aggregator.aggregate(config[:include])

            # Add files to context
            result[:files].each do |file_info|
              context.add_file(file_info[:path], file_info[:content])
            end

            # Add errors if any
            result[:errors].each do |error|
              context.metadata[:errors] ||= []
              context.metadata[:errors] << error
            end
          end

          # Format output
          format_context(context, config[:format])
        end

        def load_from_preset_config(preset, options)
          context_config = preset[:context] || {}

          context = Models::ContextData.new(
            preset_name: preset[:name],
            metadata: preset[:metadata] || {}
          )

          # Process files from context configuration
          if context_config['files'] && context_config['files'].any?
            # Resolve any protocol references (e.g., wfi://workflow-name)
            resolved_files = context_config['files'].map do |file_ref|
              resolve_file_reference(file_ref)
            end.compact

            aggregator = Ace::Core::Molecules::FileAggregator.new(
              max_size: options[:max_size] || options['max_size'],
              base_dir: options[:base_dir] || project_root,
              exclude: context_config['exclude'] || []
            )

            # Use aggregate to handle glob patterns
            result = aggregator.aggregate(resolved_files)

            # Add files to context if embed_itself is true
            if options[:embed_itself] || options['embed_itself']
              result[:files].each do |file_info|
                context.add_file(file_info[:path], file_info[:content])
              end
            end

            # Add errors if any
            result[:errors].each do |error|
              context.metadata[:errors] ||= []
              context.metadata[:errors] << error
            end
          end

          # Process commands
          if context_config['commands'] && context_config['commands'].any?
            timeout = options[:timeout] || options['timeout'] || 30
            context_config['commands'].each do |command|
              cmd_result = @command_executor.execute(command, timeout: timeout, cwd: project_root)
              context.commands ||= []
              context.commands << {
                command: command,
                output: cmd_result[:stdout],
                success: cmd_result[:success],
                error: cmd_result[:error]
              }
            end
          end

          # Add preset body content if it exists
          if preset[:body] && !preset[:body].empty?
            context.metadata[:preset_content] = preset[:body]
          end

          context
        end

        private

        def merge_contexts(contexts)
          # Convert ContextData objects to hashes for merging
          context_hashes = contexts.map do |context|
            {
              files: context.files,
              metadata: context.metadata,
              preset_name: context.metadata[:preset_name],
              source_input: context.metadata[:source_input],
              errors: context.metadata[:errors] || []
            }
          end

          # Use the merger to combine contexts
          merged = @merger.merge_contexts(context_hashes)

          # Create new ContextData from merged result
          result = Models::ContextData.new(
            metadata: merged[:metadata] || {}
          )

          # Add all merged files
          merged[:files]&.each do |file|
            result.add_file(file[:path], file[:content])
          end

          # Add merged metadata
          result.metadata[:merged] = true
          result.metadata[:total_contexts] = merged[:total_contexts]
          result.metadata[:sources] = merged[:sources]
          result.metadata[:errors] = merged[:errors] if merged[:errors]&.any?

          # Format the merged content
          format_context(result, @options[:format] || 'markdown-xml')
        end

        def process_template_config(config)
          data = {
            files: [],
            commands: [],
            errors: [],
            metadata: config.slice('format', 'embed_document_source')
          }

          # Process files
          if config['files'] && config['files'].any?
            # Resolve any protocol references (e.g., wfi://workflow-name)
            resolved_files = config['files'].map do |file_ref|
              resolve_file_reference(file_ref)
            end.compact

            aggregator = Ace::Core::Molecules::FileAggregator.new(
              max_size: config['max_size'] || @options[:max_size],
              base_dir: @options[:base_dir] || project_root
            )

            # Use aggregate_files to preserve order for explicit file lists
            result = aggregator.aggregate_files(resolved_files)
            data[:files] = result[:files]
            data[:errors].concat(result[:errors])
          end

          # Process include patterns (similar to files)
          if config['include'] && config['include'].any?
            aggregator = Ace::Core::Molecules::FileAggregator.new(
              max_size: config['max_size'] || @options[:max_size],
              base_dir: @options[:base_dir] || project_root,
              exclude: config['exclude'] || []
            )

            result = aggregator.aggregate(config['include'])
            data[:files].concat(result[:files])
            data[:errors].concat(result[:errors])
          end

          # Process commands
          if config['commands'] && config['commands'].any?
            timeout = config['timeout'] || @options[:timeout] || 30
            config['commands'].each do |command|
              cmd_result = @command_executor.execute(command, timeout: timeout, cwd: project_root)
              data[:commands] << {
                command: command,
                output: cmd_result[:stdout],
                success: cmd_result[:success],
                error: cmd_result[:error]
              }
            end
          end

          # Process diffs
          if config['diffs'] && config['diffs'].any?
            data[:diffs] ||= []
            config['diffs'].each do |diff_range|
              result = Atoms::GitExtractor.extract_diff(diff_range)
              if result[:success]
                data[:diffs] << {
                  range: diff_range,
                  output: result[:output],
                  success: true
                }
              else
                data[:diffs] << {
                  range: diff_range,
                  output: "",
                  success: false,
                  error: result[:error]
                }
                data[:errors] << "Git diff failed for '#{diff_range}': #{result[:error]}"
              end
            end
          end

          # Format output
          formatter = Ace::Core::Molecules::OutputFormatter.new(
            config['format'] || @options[:format] || 'markdown-xml'
          )
          formatted_content = formatter.format(data)

          # Create context with formatted content
          context = Models::ContextData.new(metadata: data[:metadata])
          context.content = formatted_content
          context.commands = data[:commands]

          # Store individual files if embed_document_source is true
          if config['embed_document_source']
            data[:files].each do |file_info|
              context.add_file(file_info[:path], file_info[:content])
            end
          end

          context
        end

        def format_context(context, format)
          case format
          when 'markdown', 'yaml', 'xml', 'markdown-xml', 'json'
            # Use OutputFormatter for all formats
            data = {
              files: context.files,
              metadata: context.metadata.dup,
              commands: context.commands
            }

            # Include preset_name at the top level for YAML format
            if context.metadata[:preset_name]
              data[:preset_name] = context.metadata[:preset_name]
            end

            formatter = Ace::Core::Molecules::OutputFormatter.new(format)
            context.content = formatter.format(data)
            context
          else
            context
          end
        end

        def load_protocol(protocol_ref)
          # Resolve protocol using ace-nav
          resolved_path = resolve_protocol(protocol_ref)

          if resolved_path && File.exist?(resolved_path)
            # Load the resolved file
            load_file(resolved_path)
          else
            # Protocol resolution failed
            context = Models::ContextData.new
            context.metadata[:error] = "Failed to resolve protocol: #{protocol_ref}"
            context.metadata[:protocol_ref] = protocol_ref
            context
          end
        end

        def resolve_protocol(protocol_ref)
          # Use ace-nav to resolve protocol to real path
          result = `ace-nav "#{protocol_ref}" 2>&1`.strip

          if $?.success? && !result.empty? && File.exist?(result)
            result
          else
            nil
          end
        end

        def resolve_file_reference(file_ref)
          # Check if it's a protocol reference (contains ://)
          if file_ref.match?(/^[\w-]+:\/\//)
            resolve_protocol(file_ref)
          else
            # Regular file path or glob pattern
            file_ref
          end
        end

        def project_root
          @project_root ||= Ace::Core::Molecules::ProjectRootFinder.find_or_current
        end
      end
    end
  end
end