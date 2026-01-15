# frozen_string_literal: true

require 'pathname'
require 'ace/core'
require 'ace/core/molecules/context_merger'
require 'ace/core/molecules/file_aggregator'
require 'ace/core/molecules/output_formatter'
require 'ace/support/fs'
require 'ace/core/atoms/command_executor'
require 'ace/core/atoms/template_parser'
require 'ace/core/atoms/file_reader'
require 'ace/git'
require_relative '../molecules/preset_manager'
require_relative '../molecules/section_processor'
require_relative '../molecules/section_formatter'
require_relative 'pr_context_loader'
require_relative '../models/context_data'
require_relative '../atoms/content_checker'
require_relative '../atoms/typo_detector'

module Ace
  module Bundle
    module Organisms
      # Main context loader that orchestrates preset loading using ace-core components
      class ContextLoader
        # Error raised when preset loading fails
        class PresetLoadError < StandardError; end

        def initialize(options = {})
          @options = options
          @preset_manager = Molecules::PresetManager.new
          @section_processor = Molecules::SectionProcessor.new
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
          begin
            context = load_from_preset_config(preset, merged_options)
          rescue PresetLoadError => e
            # Handle errors from top-level preset processing (fail-fast behavior)
            return Models::ContextData.new(
              preset_name: preset_name,
              metadata: { error: e.message }
            )
          end
          context.metadata[:preset_name] = preset_name
          context.metadata[:output] = preset[:output]  # Store default output mode

          # Add composition metadata if preset was composed
          if preset[:composed]
            context.metadata[:composed] = true
            context.metadata[:composed_from] = preset[:composed_from]
          end

          # Determine format - respect explicit format requests but default to markdown-xml for embedded sources
          # Check for explicit format request in preset or params
          explicit_format = preset[:format] || params['format'] || params[:format] || merged_options[:format]

          if explicit_format
            # Use the explicitly requested format
            format = explicit_format
          elsif preset.dig(:context, 'embed_document_source')
            # Default to markdown-xml format when embed_document_source is true and no explicit format requested
            format = 'markdown-xml'
          else
            # Fallback to markdown
            format = 'markdown'
          end
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
                    config = unwrap_context_config(frontmatter)
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
              context = load_file(file_path)
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
          elsif input.include?('files:') || input.include?('commands:') || input.include?('include:') || input.include?('diffs:') || input.include?('presets:') || input.include?('pr:')
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
            # Unwrap 'context' key if present (typed subjects use nested structure)
            # This allows both flat configs (diffs: [...]) and nested (context: { diffs: [...] })
            template_config = unwrap_context_config(config)
            context = process_template_config(template_config)
            # Process PR references if present (uses same unwrapped config)
            pr_processed = process_pr_config(context, template_config, @options)
            # Re-format context if PR processing added sections
            # Note: process_template_config already formats files/diffs/commands into context.content
            # We only need to re-format if process_pr_config added new sections (PR diffs)
            # If PR had no changes or failed, has_sections? returns false and we keep existing content
            if context.has_sections? || pr_processed
              format = config['format'] || @options[:format] || 'markdown-xml'
              format_context(context, format)
            end
            context
          rescue => e
            context = Models::ContextData.new
            context.metadata[:error] = "Failed to parse inline YAML: #{e.message}"
            context
          end
        end

        def load_template(path)
          # Read template file (preserve original for workflow fallback)
          original_content = File.read(path)
          template_content = original_content

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
            config = unwrap_context_config(frontmatter)

            # Merge params into options if present
            params = config['params']
            if params.is_a?(Hash)
              @options = @options.merge(params)
            end

            # Apply CLI overrides to config (CLI takes precedence)
            config = apply_cli_overrides(config)

            # Process the config (loads embedded files from context.files)
            context = process_template_config(config)

            # Process base content if present (for template files with context.base)
            process_base_content(context, config, @options)

            # Process PR references (context.pr)
            process_pr_config(context, config, @options)

            # Process sections if present (same as preset loading)
            preset_like_config = { 'context' => config }
            if @section_processor.has_sections?(preset_like_config)
              sections = @section_processor.process_sections(preset_like_config, @preset_manager)
              context.sections = sections

              # Process content for each section
              sections.each do |section_name, section_data|
                process_section_content(context, section_name, section_data, @options, config)
              end
            end

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
              # Use original_content instead of File.read to avoid redundant I/O
              context.content = original_content

              # context.files already has embedded files from process_template_config
              # Don't add source to files array - it will be output as raw content

              # Format and return
              format = config['format'] || @options[:format] || 'markdown-xml'
              return format_context(context, format)
            end

            # Format context before returning (same as preset loading)
            format = config['format'] || @options[:format] || 'markdown-xml'
            format_context(context, format)

            return context
          end

          # Check if this is plain markdown with metadata-only frontmatter
          # (e.g., workflow files with description/allowed-tools but no context config)
          if frontmatter.any?
            return load_plain_markdown(original_content, frontmatter, path)
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

          # Apply CLI overrides to context config (CLI takes precedence)
          context_config = apply_cli_overrides(context_config)

          # Process top-level preset references (context.presets)
          # This merges files, commands, and params from referenced presets
          context_config = process_top_level_presets(context_config)

          preset[:context] = context_config

          context = Models::ContextData.new(
            preset_name: preset[:name],
            metadata: preset[:metadata] || {}
          )

          # Process base content if present
          process_base_content(context, context_config, options)

          # Process sections if present
          if @section_processor.has_sections?(preset)
            sections = @section_processor.process_sections(preset, @preset_manager)
            context.sections = sections

            # Process content for each section
            sections.each do |section_name, section_data|
              process_section_content(context, section_name, section_data, options, context_config)
            end
          else
            # Migrate legacy configuration to sections if needed
            if should_migrate_to_sections?(context_config)
              migrated_config = @section_processor.migrate_legacy_to_sections(preset)
              sections = @section_processor.process_sections(migrated_config, @preset_manager)
              context.sections = sections

              # Process migrated sections
              sections.each do |section_name, section_data|
                process_section_content(context, section_name, section_data, options, context_config)
              end
            else
              # Legacy processing for non-section configurations
              process_legacy_content(context, context_config, options)
            end
          end

          # Process top-level PR references (works with both sections and legacy formats)
          # Called after section processing so PR diffs merge into existing sections
          process_pr_config(context, context_config, options)

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

        # Unwrap context configuration from wrapper if present
        # Handles both nested (context: { ... }) and flat ({ ... }) formats
        # @param config [Hash] Configuration hash, possibly with 'context' key
        # @return [Hash] The context configuration
        def unwrap_context_config(config)
          config['context'] || config
        end

        # Apply CLI overrides to configuration
        # CLI options take precedence over frontmatter/config settings
        #
        # This method is called at multiple points in the loading pipeline to ensure
        # CLI flags consistently override configuration at all entry points:
        # - load_template: For files with frontmatter
        # - load_from_preset_config: For preset-based loading
        # - process_template_config: For template processing
        def apply_cli_overrides(config)
          config = config || {}  # Guard against nil config
          if @options[:embed_source]
            config.merge('embed_document_source' => true)
          else
            config
          end
        end

        # Process top-level preset references in context configuration
        #
        # When a preset or file has `context: presets: [preset-name]` at the top level,
        # this method loads each referenced preset and merges their content (files,
        # commands, params) into the current configuration.
        #
        # Merge order: referenced presets first, then current config (current wins).
        # This is consistent with section-based preset handling.
        #
        # @param context_config [Hash] The context configuration to process
        # @return [Hash] Merged configuration with preset content incorporated
        def process_top_level_presets(context_config)
          return context_config unless context_config

          preset_refs = context_config['presets'] || context_config[:presets]
          return context_config unless preset_refs&.any?

          # Load all referenced presets, collecting any errors
          preset_contexts = []
          errors = []

          preset_refs.each do |preset_name|
            preset = @preset_manager.load_preset_with_composition(preset_name)
            if preset[:success]
              preset_contexts << { context: preset[:context] }
            else
              errors << "#{preset_name}: #{preset[:error]}"
            end
          end

          # Fail fast if any referenced preset failed to load
          if errors.any?
            raise PresetLoadError, "Failed to load referenced presets: #{errors.join('; ')}"
          end

          return context_config unless preset_contexts.any?

          # Merge: referenced presets first, then current config (current wins)
          merged = @preset_manager.merge_preset_data(preset_contexts + [{ context: context_config }])
          merged_config = merged[:context]

          # Remove presets key from merged config (already processed)
          merged_config.delete('presets')
          merged_config.delete(:presets)

          merged_config
        end

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
          return Models::ContextData.new if contexts.empty?

          # Single context with actual processed section content: preserve sections
          # This handles presets with explicit `sections:` that have real content
          if contexts.size == 1 && has_processed_section_content?(contexts.first)
            result = contexts.first
            result.metadata[:merged] = true
            result.metadata[:total_contexts] = 1
            result.metadata[:sources] = [result.metadata[:preset_name] || result.metadata[:source_path]].compact
            return format_context(result, @options[:format] || 'markdown-xml')
          end

          # Default path: use original merge logic for backward compatibility
          # This creates a new context without sections (uses OutputFormatter with metadata)
          context_hashes = contexts.map do |context|
            {
              files: context.files,
              metadata: context.metadata,
              preset_name: context.metadata[:preset_name],
              source_input: context.metadata[:source_input],
              errors: context.metadata[:errors] || []
            }
          end

          merged = @merger.merge_contexts(context_hashes)

          result = Models::ContextData.new(
            metadata: merged[:metadata] || {}
          )

          merged[:files]&.each do |file|
            result.add_file(file[:path], file[:content])
          end

          result.metadata[:merged] = true
          result.metadata[:total_contexts] = merged[:total_contexts]
          result.metadata[:sources] = merged[:sources]
          result.metadata[:errors] = merged[:errors] if merged[:errors]&.any?

          format_context(result, @options[:format] || 'markdown-xml')
        end

        # Check if context has sections with actual processed content
        # Returns true if sections have _processed_files, _processed_commands, or _processed_diffs
        # Note: Section data is normalized to symbol keys by SectionProcessor
        def has_processed_section_content?(context)
          return false unless context.has_sections?

          context.sections.any? do |_name, data|
            processed_files = data[:_processed_files] || []
            processed_commands = data[:_processed_commands] || []
            processed_diffs = data[:_processed_diffs] || []
            processed_files.any? || processed_commands.any? || processed_diffs.any?
          end
        end

        def process_template_config(config)
          # Apply CLI overrides to config (CLI takes precedence)
          config = apply_cli_overrides(config)

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
              result = generate_diff_safe(diff_range)
              data[:diffs] << result.slice(:range, :output, :success, :error, :error_type)

              unless result[:success]
                error_prefix = result[:error_type] == :git_error ? "Git diff failed" : "Invalid diff range"
                data[:errors] << "#{error_prefix} for '#{diff_range}': #{result[:error]}"
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
            # Use SectionFormatter if context has sections, otherwise fallback to OutputFormatter
            if context.has_sections?
              formatter = Molecules::SectionFormatter.new(format)
              context.content = formatter.format_with_sections(context)
            else
              # Use OutputFormatter for legacy contexts
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
            end
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
            # Protocol resolution failed - log warning for debugging
            warn "Warning: Failed to resolve protocol '#{protocol_ref}'" if @options[:debug]
            context = Models::ContextData.new
            context.metadata[:error] = "Failed to resolve protocol: #{protocol_ref}"
            context.metadata[:protocol_ref] = protocol_ref
            context
          end
        end

        def resolve_protocol(protocol_ref)
          # Use ace-nav to resolve protocol to real path
          # Using CommandExecutor for testability and security
          require "shellwords"

          # Escape the protocol ref to prevent command injection
          escaped_ref = Shellwords.escape(protocol_ref)
          command = "ace-nav #{escaped_ref}"

          # Execute using CommandExecutor (intercepted by test mocks)
          result = Ace::Core::Atoms::CommandExecutor.execute(command)

          if result[:success] && !result[:stdout].strip.empty? && File.exist?(result[:stdout].strip)
            result[:stdout].strip
          else
            # Log failure reason for debugging (only in debug mode)
            if @options[:debug]
              if !result[:success]
                warn "Warning: ace-nav command failed for '#{protocol_ref}': #{result[:error]}"
              elsif result[:stdout].strip.empty?
                warn "Warning: ace-nav returned empty path for '#{protocol_ref}'"
              else
                warn "Warning: ace-nav path does not exist for '#{protocol_ref}': #{result[:stdout].strip}"
              end
            end
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

        # Process content for a specific section
        def process_section_content(context, section_name, section_data, options, context_config = {})
          # Process all content types that are present in the section
          if has_files_content?(section_data)
            process_files_section(context, section_name, section_data, options, context_config)
          end

          if has_commands_content?(section_data)
            process_commands_section(context, section_name, section_data, options, context_config)
          end

          if has_diffs_content?(section_data)
            process_diffs_section(context, section_name, section_data, options)
          end

          if has_content_content?(section_data)
            process_inline_content_section(context, section_name, section_data, options)
          end
        end

        # Process files section content
        def process_files_section(context, section_name, section_data, options, context_config = {})
          files = section_data[:files] || section_data['files'] || []
          return unless files.any?

          # Resolve any protocol references (e.g., wfi://workflow-name)
          resolved_files = files.map do |file_ref|
            resolve_file_reference(file_ref)
          end.compact

          aggregator = Ace::Core::Molecules::FileAggregator.new(
            max_size: options[:max_size] || options['max_size'],
            base_dir: options[:base_dir] || project_root,
            exclude: section_data[:exclude] || section_data['exclude'] || []
          )

          # Check if any patterns contain glob characters
          has_globs = resolved_files.any? { |f| f.include?('*') || f.include?('?') || f.include?('[') }

          # Use aggregate for globs, aggregate_files for literal paths to preserve order
          result = if has_globs
                     aggregator.aggregate(resolved_files)
                   else
                     aggregator.aggregate_files(resolved_files)
                   end

          # Store section files in section data
          section_data[:_processed_files] = result[:files]

          # Add files to context if embed_document_source is true
          if context_config['embed_document_source']
            result[:files].each do |file_info|
              context.add_file(file_info[:path], file_info[:content])
            end
          end

          # Add errors if any
          result[:errors].each do |error|
            context.metadata[:errors] ||= []
            context.metadata[:errors] << "Section '#{section_name}': #{error}"
          end
        end

        # Process commands section content
        def process_commands_section(context, section_name, section_data, options, context_config = {})
          commands = section_data[:commands] || section_data['commands'] || []
          return unless commands.any?

          timeout = options[:timeout] || options['timeout'] || 30
          processed_commands = []

          commands.each do |command|
            cmd_result = @command_executor.execute(command, timeout: timeout, cwd: project_root)
            processed_commands << {
              command: command,
              output: cmd_result[:stdout],
              success: cmd_result[:success],
              error: cmd_result[:error]
            }
          end

          # Store processed commands in section data
          section_data[:_processed_commands] = processed_commands

          # Add commands to context (always, like in legacy processing)
          context.commands = (context.commands || []) + processed_commands
        end

        # Process top-level PR configuration
        # Delegates to PrContextLoader for PR fetching and section integration
        # @return [Boolean] true if PR config was present (even if fetch failed), false otherwise
        def process_pr_config(context, context_config, options)
          pr_refs = context_config["pr"] || context_config[:pr]
          return false unless pr_refs

          PrContextLoader.new(options).process(context, pr_refs)
        end

        # Process diffs section content
        def process_diffs_section(context, section_name, section_data, options)
          ranges = section_data[:ranges] || section_data['ranges'] || []
          return unless ranges.any?

          processed_diffs = []

          ranges.each do |diff_range|
            result = generate_diff_safe(diff_range)
            processed_diffs << result.slice(:range, :output, :success, :error)

            unless result[:success]
              context.metadata[:errors] ||= []
              error_prefix = result[:error_type] == :git_error ? "Git diff failed" : "Invalid diff range"
              context.metadata[:errors] << "Section '#{section_name}': #{error_prefix} for '#{diff_range}': #{result[:error]}"
            end
          end

          # Store processed diffs in section data
          section_data[:_processed_diffs] = processed_diffs
        end

        # Process inline content section
        def process_inline_content_section(context, section_name, section_data, options)
          content = section_data[:content] || section_data['content']
          # Store content in section data
          section_data[:_processed_content] = content if content
        end

        # Process legacy content (non-section configurations)
        def process_legacy_content(context, context_config, options)
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
        end

        # Check if configuration should be migrated to sections
        def should_migrate_to_sections?(context_config)
          # Auto-migrate if there are files, commands, or diffs but no sections
          return false if @section_processor.has_sections?({ 'context' => context_config })

          (context_config['files'] && context_config['files'].any?) ||
          (context_config['commands'] && context_config['commands'].any?) ||
          (context_config['diffs'] && context_config['diffs'].any?) ||
          (context_config['ranges'] && context_config['ranges'].any?)
        end

        # Process base content from context.base field
        #
        # Supports both file paths and inline content strings:
        # - File paths: Resolved via protocol or filesystem (e.g., "path/to/file.md", "wfi://context", "README")
        # - Inline content: Simple strings without path indicators (e.g., "System instructions")
        #
        # Resolution strategy prioritizes file existence to correctly handle extension-less files
        # (README, CONTEXT, etc.) while still supporting inline strings for simple use cases.
        def process_base_content(context, context_config, options)
          base_ref = context_config['base'] || context_config[:base]
          return unless base_ref && !base_ref.to_s.strip.empty?

          # Check if base_ref looks like a file reference (has protocol, slashes, or is a known path pattern)
          # This heuristic helps prioritize file resolution for extension-less files
          has_protocol = base_ref.match?(/^[\w-]+:\/\//)
          has_path_separators = base_ref.match?(/[\/\\]/)
          looks_like_file_ref = has_protocol || has_path_separators

          # Try to resolve as file reference first (handles extension-less files like README, CONTEXT)
          resolved_path = resolve_file_reference(base_ref)

          # Check if we successfully resolved to an existing file
          if resolved_path && File.exist?(resolved_path)
            # Load base content from file
            base_content = File.read(resolved_path).strip
            if base_content.empty?
              warn "Warning: Base file is empty: #{resolved_path}" if options[:debug]
            end

            # Store base content as primary content
            context.content = base_content
            context.metadata[:base_path] = resolved_path
            context.metadata[:base_ref] = base_ref
            context.metadata[:base_type] = 'file'
          elsif looks_like_file_ref
            # It looks like a file reference but resolution failed - set error
            if !resolved_path
              context.metadata[:base_error] = "Failed to resolve base reference: #{base_ref}"
              warn "Warning: Failed to resolve base reference: #{base_ref}" if options[:debug]
            else
              context.metadata[:base_error] = "Base file not found: #{resolved_path}"
              warn "Warning: Base file not found: #{resolved_path}" if options[:debug]
            end
          else
            # Simple string without path indicators - treat as inline content
            # This allows direct definition of base context without requiring separate files
            # Example: base: "System instructions for the task"
            context.content = base_ref.to_s.strip
            context.metadata[:base_type] = 'inline'
            context.metadata[:base_ref] = base_ref
          end
        end

        # Helper methods to detect content types in sections
        # Delegates to shared ContentChecker atom for consistency

        def has_files_content?(section_data)
          Atoms::ContentChecker.has_files_content?(section_data)
        end

        def has_commands_content?(section_data)
          Atoms::ContentChecker.has_commands_content?(section_data)
        end

        def has_diffs_content?(section_data)
          Atoms::ContentChecker.has_diffs_content?(section_data)
        end

        def has_content_content?(section_data)
          Atoms::ContentChecker.has_content_content?(section_data)
        end

        def project_root
          @project_root ||= Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
        end

        # Generate diff with ace-git and return standardized result hash
        # Handles GitError and ArgumentError with standardized error handling
        # @param diff_range [String] Git range to diff
        # @return [Hash] Result with :range, :output, :success, and optional :error
        def generate_diff_safe(diff_range)
          diff_result = Ace::Git::Organisms::DiffOrchestrator.generate(ranges: [diff_range])
          {
            range: diff_range,
            output: diff_result.content,
            success: true
          }
        rescue Ace::Git::Error => e
          {
            range: diff_range,
            output: "",
            success: false,
            error: e.message,
            error_type: :git_error
          }
        rescue ArgumentError => e
          {
            range: diff_range,
            output: "",
            success: false,
            error: e.message,
            error_type: :invalid_range
          }
        end

        # Load plain markdown file with metadata-only frontmatter
        # Used as fallback for workflow files with description/allowed-tools but no context config
        # @param original_content [String] The full file content with frontmatter
        # @param frontmatter [Hash] Parsed frontmatter YAML
        # @param path [String] File path for source metadata
        # @return [Models::ContextData] Context with original content and metadata
        def load_plain_markdown(original_content, frontmatter, path)
          context = Models::ContextData.new
          # Use original_content (preserved before frontmatter stripping)
          context.content = original_content
          # Store metadata from frontmatter using merge to preserve any existing metadata
          # Include frontmatter and frontmatter_yaml for parity with template path
          context.metadata = (context.metadata || {}).merge(
            frontmatter.transform_keys(&:to_sym)
          ).merge(
            source: path,
            frontmatter: frontmatter
          )
          # Store frontmatter_yaml if frontmatter was present
          context.metadata[:frontmatter_yaml] = frontmatter.to_yaml if frontmatter.any?

          # Check for frontmatter typos and store warnings in metadata
          warnings = detect_suspicious_keys(frontmatter, path)
          context.metadata[:warnings] = warnings if warnings.any?

          context
        end

        # Delegate to Atoms::TypoDetector for architectural consistency
        # @deprecated Use Atoms::TypoDetector.detect_suspicious_keys directly
        def detect_suspicious_keys(frontmatter, path)
          # Support both new ACE_BUNDLE_STRICT and legacy ACE_CONTEXT_STRICT for migration
          return [] unless ENV['ACE_BUNDLE_STRICT'] || ENV['ACE_CONTEXT_STRICT']

          Atoms::TypoDetector.detect_suspicious_keys(frontmatter, path)
        end

        # Delegate to Atoms::TypoDetector for architectural consistency
        # @deprecated Use Atoms::TypoDetector.typo_distance directly
        def typo_distance(str1, str2)
          Atoms::TypoDetector.typo_distance(str1, str2)
        end
      end
    end
  end
end
