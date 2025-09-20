# frozen_string_literal: true

require 'pathname'
require 'ace/core'
require_relative '../molecules/preset_manager'
require_relative '../models/context_data'

module Ace
  module Context
    module Organisms
      # Main context loader that orchestrates preset loading using ace-core components
      class ContextLoader
        def initialize(options = {})
          @options = options
          @preset_manager = Molecules::PresetManager.new
          @file_aggregator = Ace::Core::Molecules::FileAggregator.new(
            max_size: options[:max_size],
            base_dir: options[:base_dir] || Dir.pwd
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

          load_from_config(preset)
        end

        def load_file(path)
          # Check if it's a template file
          content = File.read(path) rescue nil

          if content && Ace::Core::Atoms::TemplateParser.template?(content)
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

        def load_template(path)
          # Read template file
          template_content = File.read(path)

          # Parse template configuration
          parse_result = Ace::Core::Atoms::TemplateParser.parse(template_content)

          unless parse_result[:success]
            context = Models::ContextData.new
            context.metadata[:error] = parse_result[:error]
            return context
          end

          config = parse_result[:config]

          # Process files and commands from template
          process_template_config(config)
        end

        def load_from_config(config)
          context = Models::ContextData.new(
            preset_name: config[:name],
            metadata: config[:metadata] || {}
          )

          # Use file aggregator for include patterns
          if config[:include] && config[:include].any?
            aggregator = Ace::Core::Molecules::FileAggregator.new(
              max_size: @options[:max_size],
              base_dir: @options[:base_dir] || Dir.pwd,
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

        private

        def process_template_config(config)
          data = {
            files: [],
            commands: [],
            errors: [],
            metadata: config.slice('format', 'embed_document_source')
          }

          # Process files
          if config['files'] && config['files'].any?
            aggregator = Ace::Core::Molecules::FileAggregator.new(
              max_size: config['max_size'] || @options[:max_size],
              base_dir: @options[:base_dir] || Dir.pwd
            )

            result = aggregator.aggregate(config['files'])
            data[:files] = result[:files]
            data[:errors].concat(result[:errors])
          end

          # Process include patterns (similar to files)
          if config['include'] && config['include'].any?
            aggregator = Ace::Core::Molecules::FileAggregator.new(
              max_size: config['max_size'] || @options[:max_size],
              base_dir: @options[:base_dir] || Dir.pwd,
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
              cmd_result = @command_executor.execute(command, timeout: timeout)
              data[:commands] << {
                command: command,
                output: cmd_result[:stdout],
                success: cmd_result[:success],
                error: cmd_result[:error]
              }
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
              metadata: context.metadata
            }

            formatter = Ace::Core::Molecules::OutputFormatter.new(format)
            context.content = formatter.format(data)
            context
          else
            context
          end
        end
      end
    end
  end
end