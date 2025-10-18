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
          # Use composition-aware loading
          preset = @preset_manager.load_preset_with_composition(preset_name)

          # Handle errors from composition loading
          unless preset[:success]
            return Models::ContextData.new(
              preset_name: preset_name,
              metadata: { error: preset[:error] }
            )
          end

          # Merge params into options for processing
          params = preset.dig(:context, :params) || preset.dig(:context, 'params') || {}
          merged_options = @options.merge(params)

          # Process the preset context configuration
          context = load_from_preset_config(preset, merged_options)
          context.metadata[:preset_name] = preset_name
          context.metadata[:output] = preset[:output]  # Store default output mode

          # Add composition metadata if preset was composed
          if preset[:composed]
            context.metadata[:composed] = true
            context.metadata[:composed_from] = preset[:composed_from]
          end

          # Determine format - use markdown-xml for embedded sources, markdown otherwise
          context_config = preset[:context] || {}
          default_format = context_config['embed_document_source'] ? 'markdown-xml' : 'markdown'
          format = preset[:format] || params['format'] || params[:format] || merged_options[:format] || default_format
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
          warnings = []

          preset_names.each do |preset_name|
            # Use composition-aware loading for each preset
            preset = @preset_manager.load_preset_with_composition(preset_name)

            if preset[:success]
              params = preset.dig(:context, :params) || preset.dig(:context, 'params') || {}
              merged_options = @options.merge(params)
              context = load_from_preset_config(preset, merged_options)
              context.metadata[:preset_name] = preset_name
              context.metadata[:output] = preset[:output]  # Store preset's output mode

              # Add composition metadata if preset was composed
              if preset[:composed]
                context.metadata[:composed] = true
                context.metadata[:composed_from] = preset[:composed_from]
              end

              contexts << context
            else
              # Log warning but continue with other presets
              warnings << "Warning: #{preset[:error]}"
              warn "Warning: #{preset[:error]}" if @options[:debug]
            end
          end

          # If no successful presets loaded, return error
          if contexts.empty?
            error_context = Models::ContextData.new(
              metadata: {
                error: "No valid presets loaded",
                warnings: warnings
              }
            )
            return error_context
          end

          # Merge all contexts
          merged = merge_contexts(contexts)
          merged.metadata[:warnings] = warnings if warnings.any?

          merged
        end

        # Inspect configuration without loading files or executing commands
        # Returns a ContextData with just the merged configuration as YAML
        def inspect_config(inputs)
          require 'yaml'

          # Load all inputs (presets and files) with composition
          configs = []
          warnings = []

          inputs.each do |input|
            # Auto-detect if it's a file or preset
            if File.exist?(input)
              # Load as file
              begin
                # Read file and parse config
                content = File.read(input)
                config = {}

                if input.match?(/\.ya?ml$/i)
                  config = YAML.safe_load(content, aliases: true, permitted_classes: [Symbol]) || {}
                elsif has_frontmatter?(input)
                  if content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
                    frontmatter = YAML.safe_load($1, aliases: true, permitted_classes: [Symbol]) || {}
                    config = frontmatter['context'] || frontmatter
                  end
                end

                # Handle preset composition if file references presets
                preset_refs = config['presets'] || config[:presets]
                if preset_refs && !preset_refs.empty?
                  # Load all referenced presets first
                  preset_contexts = []
                  preset_refs.each do |preset_name|
                    preset = @preset_manager.load_preset_with_composition(preset_name)
                    if preset[:success]
                      preset_contexts << { context: preset[:context] }
                    else
                      warnings << "Failed to load preset '#{preset_name}' from file #{input}"
                    end
                  end

                  # Merge all presets + file config (file config last = file wins)
                  # Order: preset1, preset2, ..., file config
                  if preset_contexts.any?
                    merged = @preset_manager.send(:merge_preset_data, preset_contexts + [{ context: config }])
                    config = merged[:context]
                  end

                  # Remove presets key from final config
                  config.delete('presets')
                  config.delete(:presets)
                end

                configs << {
                  success: true,
                  context: config,
                  name: File.basename(input),
                  source_file: input
                }
              rescue => e
                warnings << "Failed to load file #{input}: #{e.message}"
              end
            else
              # Load as preset
              preset = @preset_manager.load_preset_with_composition(input)
              if preset[:success]
                configs << preset
              else
                warnings << preset[:error]
              end
            end
          end

          # If no successful configs, return error
          if configs.empty?
            context = Models::ContextData.new
            context.metadata[:error] = "No valid inputs loaded"
            context.metadata[:warnings] = warnings
            return context
          end

          # Merge configurations (just the config, not content)
          merged_config = merge_preset_configurations(configs)

          # Add warnings if any
          merged_config[:warnings] = warnings if warnings.any?

          # Format as YAML
          yaml_output = YAML.dump(merged_config)

          # Create context with YAML content
          context = Models::ContextData.new
          context.content = yaml_output
          context.metadata[:inspect_mode] = true
          context.metadata[:inputs] = inputs

          context
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

        # Load multiple inputs (presets and files) and merge them
        # Maintains order of specification to allow proper override semantics
        def load_multiple_inputs(preset_names, file_paths, options = {})
          contexts = []
          warnings = []

          # Process presets
          preset_names.each do |preset_name|
            # Use composition-aware loading for each preset
            preset = @preset_manager.load_preset_with_composition(preset_name)

            if preset[:success]
              params = preset.dig(:context, :params) || preset.dig(:context, 'params') || {}
              merged_options = @options.merge(params)
              context = load_from_preset_config(preset, merged_options)
              context.metadata[:preset_name] = preset_name
              context.metadata[:source_type] = 'preset'
              context.metadata[:output] = preset[:output]  # Store preset's output mode

              # Add composition metadata if preset was composed
              if preset[:composed]
                context.metadata[:composed] = true
                context.metadata[:composed_from] = preset[:composed_from]
              end

              contexts << context
            else
              # Log warning but continue with other inputs
              warnings << "Warning: #{preset[:error]}"
              warn "Warning: #{preset[:error]}" if @options[:debug]
            end
          end

          # Process files
          file_paths.each do |file_path|
            begin
              context = load_file_as_preset(file_path)
              context.metadata[:source_type] = 'file'
              context.metadata[:source_path] = file_path
              contexts << context
            rescue => e
              warnings << "Warning: Failed to load file #{file_path}: #{e.message}"
              warn "Warning: Failed to load file #{file_path}: #{e.message}" if @options[:debug]
            end
          end

          # Return error if all inputs failed
          if contexts.empty? && warnings.any?
            return Models::ContextData.new.tap do |c|
              c.metadata[:error] = "Failed to load any inputs"
              c.metadata[:errors] = warnings
              c.content = warnings.join("\n")
            end
          end

          # Merge all contexts (with proper order for overrides)
          merged_context = merge_contexts(contexts)

          # Add warnings to metadata if any
          merged_context.metadata[:warnings] = warnings if warnings.any?

          merged_context
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
          frontmatter_yaml = nil
          if template_content =~ /\A---\s*\n(.*?)\n---\s*\n/m
            frontmatter_text = $1
            frontmatter_yaml = frontmatter_text  # Store original YAML for output
            begin
              require 'yaml'
              frontmatter = YAML.safe_load(frontmatter_text) || {}
              frontmatter = {} unless frontmatter.is_a?(Hash)
              # Remove frontmatter from content for processing
              template_content = template_content.sub(/\A---\s*\n.*?\n---\s*\n/m, '')
            rescue Psych::SyntaxError
              # Invalid YAML, ignore frontmatter
              frontmatter_yaml = nil
            end
          end

          # Check if frontmatter contains config directly (via 'context' key or template config keys)
          # This is the newer pattern for workflow files
          if frontmatter['context'].is_a?(Hash) ||
             (frontmatter.keys & %w[files commands include exclude diffs]).any?
            # Use frontmatter as the main config
            config = frontmatter['context'] || frontmatter

            # Merge params into options if present
            params = config['params']
            if params.is_a?(Hash)
              @options = @options.merge(params)
            end

            # Process the config (loads embedded files from context.files)
            context = process_template_config(config)

            # Replace metadata with original frontmatter (keep it unmodified)
            # Convert string keys to symbols for consistency
            context.metadata = {}
            frontmatter.each do |key, value|
              context.metadata[key.to_sym] = value
            end
            # Store original YAML for output formatting
            context.metadata[:frontmatter_yaml] = frontmatter_yaml if frontmatter_yaml

            # If embed_document_source is true, store original document and keep embedded files separate
            if config['embed_document_source']
              # Store original document (with frontmatter) as source content
              context.content = File.read(path)

              # context.files already has embedded files from process_template_config
              # Don't add source to files array - it will be output as raw content

              # Format and return
              format = config['format'] || @options[:format] || 'markdown-xml'
              return format_context(context, format)
            end

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

            # Add files to context if embed_document_source is true
            if context_config['embed_document_source']
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

          # If embed_document_source is true, set content to trigger XML formatting
          if context_config['embed_document_source'] && preset[:body] && !preset[:body].empty?
            context.content = preset[:body]
          else
            # Add preset body to metadata (old behavior for non-embedded)
            if preset[:body] && !preset[:body].empty?
              context.metadata[:preset_content] = preset[:body]
            end
          end

          context
        end

        # Load a file and treat it as a preset-like configuration
        # Supports YAML files and markdown with frontmatter
        def load_file_as_preset(path)
          unless File.exist?(path)
            return Models::ContextData.new.tap do |c|
              c.metadata[:error] = "File not found: #{path}"
              c.content = "Error: File not found: #{path}"
            end
          end

          content = File.read(path)
          config = {}

          # Check if it's a YAML file
          if path.match?(/\.ya?ml$/i)
            begin
              yaml_content = YAML.safe_load(content, aliases: true, permitted_classes: [Symbol])
              config = yaml_content.is_a?(Hash) ? yaml_content : {}
            rescue Psych::SyntaxError => e
              return Models::ContextData.new.tap do |c|
                c.metadata[:error] = "Invalid YAML in #{path}: #{e.message}"
                c.content = "Error: Invalid YAML: #{e.message}"
              end
            end
          elsif has_frontmatter?(path)
            # Extract frontmatter from markdown file
            if content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
              frontmatter_yaml = $1
              begin
                frontmatter = YAML.safe_load(frontmatter_yaml, aliases: true, permitted_classes: [Symbol])
                frontmatter = {} unless frontmatter.is_a?(Hash)

                # Use context key if present, otherwise use frontmatter directly
                config = frontmatter['context'] || frontmatter
              rescue Psych::SyntaxError => e
                return Models::ContextData.new.tap do |c|
                  c.metadata[:error] = "Invalid YAML frontmatter in #{path}: #{e.message}"
                  c.content = "Error: Invalid YAML frontmatter: #{e.message}"
                end
              end
            end
          else
            # Not a YAML file or markdown with frontmatter - treat as plain file
            return load_file(path)
          end

          # Extract params and merge into options
          params = config['params'] || config[:params] || {}
          merged_options = @options.merge(params)

          # Build a preset-like structure
          preset_data = {
            success: true,
            context: config,
            output: config['output'] || config[:output] || params['output'] || params[:output],
            name: File.basename(path, '.*'),
            source_file: path
          }

          # Check for preset composition in file
          if config['presets'] || config[:presets]
            preset_data[:presets] = Array(config['presets'] || config[:presets])
            # Load with composition
            preset_data = compose_file_with_presets(preset_data)
          end

          # Load from the preset-like config
          context = load_from_preset_config(preset_data, merged_options)
          context.metadata[:loaded_from_file] = true
          context.metadata[:file_path] = path
          context.metadata[:source_type] = 'file'
          context.metadata[:output] = preset_data[:output] if preset_data[:output]

          context
        end

        # Compose a file configuration with referenced presets
        def compose_file_with_presets(file_data)
          preset_names = file_data[:presets] || []
          return file_data if preset_names.empty?

          # Load all referenced presets first
          base_context = file_data[:context]
          composed_from = [file_data[:name]]
          preset_contexts = []

          preset_names.each do |preset_name|
            preset = @preset_manager.load_preset_with_composition(preset_name)
            if preset[:success]
              preset_contexts << { context: preset[:context] }
              composed_from << preset_name
              composed_from.concat(preset[:composed_from]) if preset[:composed_from]
            else
              warn "Warning: Failed to load preset '#{preset_name}' referenced in file" if @options[:debug]
            end
          end

          # Merge all presets + file context (file context last = file wins)
          # Order: preset1, preset2, ..., file context
          if preset_contexts.any?
            merged = @preset_manager.send(:merge_preset_data, preset_contexts + [{ context: base_context }])
            base_context = merged[:context]
          end

          # Remove presets key from context (it's metadata, already processed)
          base_context.delete('presets')
          base_context.delete(:presets)

          file_data[:context] = base_context
          file_data[:composed] = true
          file_data[:composed_from] = composed_from.uniq
          file_data
        end

        private

        # Check if a file has YAML frontmatter
        def has_frontmatter?(path)
          return false unless File.exist?(path)
          content = File.read(path, 100) rescue ""  # Read only beginning
          content.start_with?("---\n") || content.start_with?("---\r\n")
        end

        # Merge preset configurations (just config data, not content)
        def merge_preset_configurations(presets)
          merged = {
            'description' => nil,
            'context' => {
              'params' => {},
              'files' => [],
              'commands' => []
            }
          }

          presets.each do |preset|
            # Merge description (last wins)
            merged['description'] = preset[:description] if preset[:description]

            # Merge context configuration
            if preset[:context]
              context = preset[:context]

              # Merge params
              if context['params']
                merged['context']['params'].merge!(context['params'])
              end

              # Merge files
              if context['files']
                merged['context']['files'].concat(context['files'])
              end

              # Merge commands
              if context['commands']
                merged['context']['commands'].concat(context['commands'])
              end

              # Copy other context keys (embed_document_source, etc.)
              context.each do |key, value|
                next if %w[params files commands presets].include?(key)
                merged['context'][key] = value
              end
            end
          end

          # Deduplicate arrays
          merged['context']['files'].uniq!
          merged['context']['commands'].uniq!

          merged
        end

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
              base_dir: @options[:base_dir] || project_root,
              exclude: config['exclude'] || []
            )

            # Check if any patterns contain glob characters
            has_globs = resolved_files.any? { |f| f.include?('*') || f.include?('?') || f.include?('[') }

            # Use aggregate for globs, aggregate_files for literal paths
            result = if has_globs
                       aggregator.aggregate(resolved_files)
                     else
                       aggregator.aggregate_files(resolved_files)
                     end
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
              commands: context.commands,
              content: context.content
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