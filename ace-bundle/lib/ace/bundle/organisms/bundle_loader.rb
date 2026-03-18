# frozen_string_literal: true

require 'pathname'
require 'ace/core'
require_relative '../molecules/bundle_merger'
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
require_relative '../molecules/section_compressor'
require_relative 'pr_bundle_loader'
require_relative '../models/bundle_data'
require_relative '../atoms/content_checker'
require_relative '../atoms/typo_detector'

module Ace
  module Bundle
    module Organisms
      # Main bundle loader that orchestrates preset loading using ace-core components
      class BundleLoader
        def initialize(options = {})
          @options = options
          @template_dir = nil
          @preset_manager = Molecules::PresetManager.new
          @section_processor = Molecules::SectionProcessor.new
          @merger = Molecules::BundleMerger.new
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
            return Models::BundleData.new(
              preset_name: preset_name,
              metadata: { error: preset[:error] }
            )
          end

          # Merge params into options for processing
          params = preset.dig(:context, :params) || preset.dig(:context, 'params') || {}
          merged_options = @options.merge(params)

          # Process the preset bundle configuration
          begin
            bundle = load_from_preset_config(preset, merged_options)
          rescue Ace::Bundle::PresetLoadError => e
            # Handle errors from top-level preset processing (fail-fast behavior)
            return Models::BundleData.new(
              preset_name: preset_name,
              metadata: { error: e.message }
            )
          end
          bundle.metadata[:preset_name] = preset_name
          bundle.metadata[:output] = preset[:output]  # Store default output mode
          bundle.metadata[:compressor_mode] = preset[:compressor_mode] if preset[:compressor_mode]
          bundle.metadata[:compressor_source_scope] = preset[:compressor_source_scope] if preset[:compressor_source_scope]

          # Add composition metadata if preset was composed
          if preset[:composed]
            bundle.metadata[:composed] = true
            bundle.metadata[:composed_from] = preset[:composed_from]
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
          format_bundle(bundle, format)

          bundle
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

            bundle = Models::BundleData.new
            if result[:success]
              # Plain file inputs should emit readable content to stdout.
              # Keep content as primary payload and record source metadata.
              bundle.content = result[:content]
              bundle.metadata[:source] = path
            else
              bundle.metadata[:error] = result[:error]
            end

            compress_bundle_sections(bundle)
            bundle
          end
        end

        def load_multiple_presets(preset_names)
          bundles = []
          warnings = []

          preset_names.each do |preset_name|
            # Use composition-aware loading for each preset
            preset = @preset_manager.load_preset_with_composition(preset_name)

            if preset[:success]
              params = preset.dig(:context, :params) || preset.dig(:context, 'params') || {}
              merged_options = @options.merge(params)
              bundle = load_from_preset_config(preset, merged_options)
              bundle.metadata[:preset_name] = preset_name
              bundle.metadata[:output] = preset[:output]  # Store preset's output mode

              # Add composition metadata if preset was composed
              if preset[:composed]
                bundle.metadata[:composed] = true
                bundle.metadata[:composed_from] = preset[:composed_from]
              end

              bundles << bundle
            else
              # Log warning but continue with other presets
              warnings << "Warning: #{preset[:error]}"
              warn "Warning: #{preset[:error]}" if @options[:debug]
            end
          end

          # If no successful presets loaded, return error
          if bundles.empty?
            error_bundle = Models::BundleData.new(
              metadata: {
                error: "No valid presets loaded",
                warnings: warnings
              }
            )
            return error_bundle
          end

          # Merge all bundles
          merged = merge_bundles(bundles)
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
                    config = unwrap_bundle_config(frontmatter)
                  end
                end

                # Handle preset composition if file references presets
                preset_refs = config['presets'] || config[:presets]
                if preset_refs && !preset_refs.empty?
                  # Load all referenced presets first
                  preset_bundles = []
                  preset_refs.each do |preset_name|
                    preset = @preset_manager.load_preset_with_composition(preset_name)
                    if preset[:success]
                      preset_bundles << { bundle: preset[:bundle] }
                    else
                      warnings << "Failed to load preset '#{preset_name}' from file #{input}"
                    end
                  end

                  # Merge all presets + file config (file config last = file wins)
                  # Order: preset1, preset2, ..., file config
                  if preset_bundles.any?
                    merged = @preset_manager.send(:merge_preset_data, preset_bundles + [{ bundle: config }])
                    config = merged[:bundle]
                  end

                  # Remove presets key from final config
                  config.delete('presets')
                  config.delete(:presets)
                end

                configs << {
                  success: true,
                  bundle: config,
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
            bundle = Models::BundleData.new
            bundle.metadata[:error] = "No valid inputs loaded"
            bundle.metadata[:warnings] = warnings
            return bundle
          end

          # Merge configurations (just the config, not content)
          merged_config = merge_preset_configurations(configs)

          # Add warnings if any
          merged_config[:warnings] = warnings if warnings.any?

          # Format as YAML
          yaml_output = YAML.dump(merged_config)

          # Create bundle with YAML content
          bundle = Models::BundleData.new
          bundle.content = yaml_output
          bundle.metadata[:inspect_mode] = true
          bundle.metadata[:inputs] = inputs

          bundle
        end

        def load_multiple(inputs)
          bundles = []

          inputs.each do |input|
            bundle = load_auto(input)
            bundle.metadata[:source_input] = input
            bundles << bundle
          end

          # Merge all bundles
          merge_bundles(bundles)
        end

        # Load multiple inputs (presets and files) and merge them
        # Maintains order of specification to allow proper override semantics
        def load_multiple_inputs(preset_names, file_paths, options = {})
          bundles = []
          warnings = []

          # Process presets
          preset_names.each do |preset_name|
            # Use composition-aware loading for each preset
            preset = @preset_manager.load_preset_with_composition(preset_name)

            if preset[:success]
              params = preset.dig(:context, :params) || preset.dig(:context, 'params') || {}
              merged_options = @options.merge(params)
              bundle = load_from_preset_config(preset, merged_options)
              bundle.metadata[:preset_name] = preset_name
              bundle.metadata[:source_type] = 'preset'
              bundle.metadata[:output] = preset[:output]  # Store preset's output mode

              # Add composition metadata if preset was composed
              if preset[:composed]
                bundle.metadata[:composed] = true
                bundle.metadata[:composed_from] = preset[:composed_from]
              end

              bundles << bundle
            else
              # Log warning but continue with other inputs
              warnings << "Warning: #{preset[:error]}"
              warn "Warning: #{preset[:error]}" if @options[:debug]
            end
          end

          # Process files
          file_paths.each do |file_path|
            begin
              bundle = load_file(file_path)
              bundle.metadata[:source_type] = 'file'
              bundle.metadata[:source_path] = file_path
              bundles << bundle
            rescue => e
              warnings << "Warning: Failed to load file #{file_path}: #{e.message}"
              warn "Warning: Failed to load file #{file_path}: #{e.message}" if @options[:debug]
            end
          end

          # Return error if all inputs failed
          if bundles.empty? && warnings.any?
            return Models::BundleData.new.tap do |c|
              c.metadata[:error] = "Failed to load any inputs"
              c.metadata[:errors] = warnings
              c.content = warnings.join("\n")
            end
          end

          # Merge all bundles (with proper order for overrides)
          merged_bundle = merge_bundles(bundles)

          # Add warnings to metadata if any
          merged_bundle.metadata[:warnings] = warnings if warnings.any?

          merged_bundle
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
            # Unwrap 'bundle' key if present (typed subjects use nested structure)
            # This allows both flat configs (diffs: [...]) and nested (bundle: { diffs: [...] })
            template_config = unwrap_bundle_config(config)
            bundle = process_template_config(template_config)
            # Process PR references if present (uses same unwrapped config)
            pr_processed = process_pr_config(bundle, template_config, @options)
            # Re-format bundle if PR processing added sections
            # Note: process_template_config already formats files/diffs/commands into bundle.content
            # We only need to re-format if process_pr_config added new sections (PR diffs)
            # If PR had no changes or failed, has_sections? returns false and we keep existing content
            if bundle.has_sections? || pr_processed
              format = config['format'] || @options[:format] || 'markdown-xml'
              format_bundle(bundle, format)
            end
            bundle
          rescue => e
            bundle = Models::BundleData.new
            bundle.metadata[:error] = "Failed to parse inline YAML: #{e.message}"
            bundle
          end
        end

        def load_template(path)
          # Track the template file's directory for resolving ./ relative paths
          @template_dir = File.dirname(File.expand_path(path))

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

          # Check if frontmatter contains config directly (via 'bundle' key or template config keys)
          # This is the newer pattern for workflow files
          if frontmatter['bundle'].is_a?(Hash) ||
             (frontmatter.keys & %w[preset presets files commands include exclude diffs]).any?
            # Use frontmatter as the main config
            config = unwrap_bundle_config(frontmatter)

            # Merge params into options if present
            params = config['params']
            if params.is_a?(Hash)
              @options = @options.merge(params)
            end

            # Handle preset/presets keys from frontmatter
            preset_names = []
            if frontmatter['preset'] && !frontmatter['preset'].to_s.strip.empty?
              preset_names << frontmatter['preset'].to_s.strip
            end
            if frontmatter['presets'] && frontmatter['presets'].is_a?(Array)
              preset_names += frontmatter['presets'].compact.map(&:to_s).map(&:strip)
            end

            if preset_names.any?
              existing_presets = config['presets'] || []
              config['presets'] = preset_names + existing_presets
            end

            # Apply CLI overrides to config (CLI takes precedence)
            config = apply_cli_overrides(config)

            # Process presets from frontmatter
            preset_error = nil
            preset_names_loaded = []
            if config['presets'] && config['presets'].any?
              begin
                preset_names_loaded = config['presets'].dup
                config = process_top_level_presets(config)
              rescue Ace::Bundle::PresetLoadError => e
                preset_error = e.message
                warn "Warning: #{e.message}" if @options[:debug]
                config.delete('presets')
                config.delete(:presets)
              end
            end

            # Process the config (loads embedded files from bundle.files)
            bundle = process_template_config(config)

            bundle.metadata[:presets] = preset_names_loaded if preset_names_loaded.any?
            bundle.metadata[:preset_error] = preset_error if preset_error

            # Process base content if present (for template files with context.base)
            process_base_content(bundle, config, @options)

            # Process PR references (context.pr)
            process_pr_config(bundle, config, @options)

            # Process sections if present (same as preset loading)
            preset_like_config = { 'bundle' => config }
            if @section_processor.has_sections?(preset_like_config)
              sections = @section_processor.process_sections(preset_like_config, @preset_manager)
              bundle.sections = sections

              # Process content for each section
              sections.each do |section_name, section_data|
                process_section_content(bundle, section_name, section_data, @options, config)
              end
            end

            # Track base resolution before metadata reset (metadata gets replaced below)
            resolved = bundle.metadata[:base_type] ? bundle.content : nil
            base_content_resolved = resolved.to_s.strip.empty? ? nil : resolved

            # Replace metadata with original frontmatter (keep it unmodified)
            # Convert string keys to symbols for consistency
            bundle.metadata = {}
            frontmatter.each do |key, value|
              bundle.metadata[key.to_sym] = value
            end
            # Store original YAML for output formatting
            bundle.metadata[:frontmatter_yaml] = frontmatter_yaml if frontmatter_yaml

            # If embed_document_source is true, store original document and keep embedded files separate
            if config['embed_document_source']
              # base replaces the source document for embedding
              bundle.content = base_content_resolved || original_content

              # bundle.files already has embedded files from process_template_config
              # Don't add source to files array - it will be output as raw content

              # Format and return
              format = config['format'] || @options[:format] || 'markdown-xml'
              return format_bundle(bundle, format)
            end

            # Format bundle before returning (same as preset loading)
            format = config['format'] || @options[:format] || 'markdown-xml'
            format_bundle(bundle, format)

            return bundle
          end

          # Check if this is plain markdown with metadata-only frontmatter
          # (e.g., workflow files with description/allowed-tools but no context config)
          if frontmatter.any?
            return load_plain_markdown(original_content, frontmatter, path)
          end

          # Otherwise, parse template configuration from body
          parse_result = Ace::Core::Atoms::TemplateParser.parse(template_content)

          unless parse_result[:success]
            bundle = Models::BundleData.new
            bundle.metadata[:error] = parse_result[:error]
            return bundle
          end

          config = parse_result[:config]

          # Merge frontmatter into config (frontmatter has lower priority)
          config = frontmatter.merge(config) if frontmatter.any?

          # Process files and commands from template
          bundle = process_template_config(config)

          # Add frontmatter to metadata for reference
          bundle.metadata[:frontmatter] = frontmatter if frontmatter.any?

          bundle
        end

        def load_from_config(config)
          # If config has a template path, load from template instead
          if config[:template] && File.exist?(config[:template])
            return load_template(config[:template])
          end

          bundle = Models::BundleData.new(
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

            # Add files to bundle
            result[:files].each do |file_info|
              bundle.add_file(file_info[:path], file_info[:content])
            end

            # Add errors if any
            result[:errors].each do |error|
              bundle.metadata[:errors] ||= []
              bundle.metadata[:errors] << error
            end
          end

          # Format output
          format_bundle(bundle, config[:format])
        end

        def load_from_preset_config(preset, options)
          bundle_config = preset[:bundle] || {}

          # Apply CLI overrides to context config (CLI takes precedence)
          bundle_config = apply_cli_overrides(bundle_config)

          # Process top-level preset references (context.presets)
          # This merges files, commands, and params from referenced presets
          bundle_config = process_top_level_presets(bundle_config)

          preset[:bundle] = bundle_config

          bundle = Models::BundleData.new(
            preset_name: preset[:name],
            metadata: preset[:metadata] || {}
          )

          # Process base content if present
          process_base_content(bundle, bundle_config, options)

          # Process sections (legacy non-section preset formats are no longer supported)
          raise Ace::Bundle::PresetLoadError, "Preset '#{preset[:name]}' must define bundle sections" unless @section_processor.has_sections?(preset)

          sections = @section_processor.process_sections(preset, @preset_manager)
          bundle.sections = sections

          # Process content for each section
          sections.each do |section_name, section_data|
            process_section_content(bundle, section_name, section_data, options, bundle_config)
          end

          # Process top-level PR references
          # Called after section processing so PR diffs merge into existing sections
          process_pr_config(bundle, bundle_config, options)

          # If embed_document_source is true, set content to trigger XML formatting
          if bundle_config['embed_document_source'] && preset[:body] && !preset[:body].empty?
            bundle.content = preset[:body]
          else
            # Add preset body to metadata (old behavior for non-embedded)
            if preset[:body] && !preset[:body].empty?
              bundle.metadata[:preset_content] = preset[:body]
            end
          end

          bundle
        end

        # Compose a file configuration with referenced presets
        def compose_file_with_presets(file_data)
          preset_names = file_data[:presets] || []
          return file_data if preset_names.empty?

          # Load all referenced presets first
          base_bundle = file_data[:bundle]
          composed_from = [file_data[:name]]
          preset_bundles = []

          preset_names.each do |preset_name|
            preset = @preset_manager.load_preset_with_composition(preset_name)
            if preset[:success]
              preset_bundle = preset[:bundle]
              preset_bundles << { bundle: preset_bundle }
              composed_from << preset_name
              composed_from.concat(preset[:composed_from]) if preset[:composed_from]
            else
              warn "Warning: Failed to load preset '#{preset_name}' referenced in file" if @options[:debug]
            end
          end

          # Merge all presets + file bundle (file bundle last = file wins)
          # Order: preset1, preset2, ..., file bundle
          if preset_bundles.any?
            merged = @preset_manager.send(:merge_preset_data, preset_bundles + [{ bundle: base_bundle }])
            base_bundle = merged[:bundle]
          end

          # Remove presets key from bundle (it's metadata, already processed)
          base_bundle.delete('presets')
          base_bundle.delete(:presets)

          file_data[:bundle] = base_bundle
          file_data[:composed] = true
          file_data[:composed_from] = composed_from.uniq
          file_data
        end

        private

        # Unwrap bundle configuration from wrapper if present
        # Handles both nested (bundle: { ... }) and flat ({ ... }) formats
        # @param config [Hash] Configuration hash, possibly with 'bundle' key
        # @return [Hash] The bundle configuration
        def unwrap_bundle_config(config)
          config['bundle'] || config
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

        # Process top-level preset references in bundle configuration
        #
        # When a preset or file has `bundle: presets: [preset-name]` at the top level,
        # this method loads each referenced preset and merges their content (files,
        # commands, params) into the current configuration.
        #
        # Merge order: referenced presets first, then current config (current wins).
        # This is consistent with section-based preset handling.
        #
        # @param bundle_config [Hash] The bundle configuration to process
        # @return [Hash] Merged configuration with preset content incorporated
        def process_top_level_presets(bundle_config)
          return bundle_config unless bundle_config

          preset_refs = bundle_config['presets'] || bundle_config[:presets]
          return bundle_config unless preset_refs&.any?

          # Load all referenced presets, collecting any errors
          preset_bundles = []
          errors = []

          preset_refs.each do |preset_name|
            preset = @preset_manager.load_preset_with_composition(preset_name)
            if preset[:success]
              preset_bundle = preset[:bundle]
              preset_bundles << { bundle: preset_bundle }
            else
              errors << "#{preset_name}: #{preset[:error]}"
            end
          end

          # Fail fast if any referenced preset failed to load
          if errors.any?
            raise Ace::Bundle::PresetLoadError, "Failed to load referenced presets: #{errors.join('; ')}"
          end

          return bundle_config unless preset_bundles.any?

          # Merge: referenced presets first, then current config (current wins)
          merged = @preset_manager.merge_preset_data(preset_bundles + [{ bundle: bundle_config }])
          merged_config = merged[:bundle]

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
            'bundle' => {
              'params' => {},
              'files' => [],
              'commands' => []
            }
          }

          presets.each do |preset|
            # Merge description (last wins)
            merged['description'] = preset[:description] if preset[:description]

            # Merge bundle configuration
            if preset[:bundle]
              bundle_config = preset[:bundle]

              # Merge params
              if bundle_config['params']
                merged['bundle']['params'].merge!(bundle_config['params'])
              end

              # Merge files
              if bundle_config['files']
                merged['bundle']['files'].concat(bundle_config['files'])
              end

              # Merge commands
              if bundle_config['commands']
                merged['bundle']['commands'].concat(bundle_config['commands'])
              end

              # Copy other bundle keys (embed_document_source, etc.)
              bundle_config.each do |key, value|
                next if %w[params files commands presets].include?(key)
                merged['bundle'][key] = value
              end
            end
          end

          # Deduplicate arrays
          merged['bundle']['files'].uniq!
          merged['bundle']['commands'].uniq!

          merged
        end

        def merge_bundles(bundles)
          return Models::BundleData.new if bundles.empty?

          # Single context with actual processed section content: preserve sections
          # This handles presets with explicit `sections:` that have real content
          if bundles.size == 1 && has_processed_section_content?(bundles.first)
            result = bundles.first
            result.metadata[:merged] = true
            result.metadata[:total_bundles] = 1
            result.metadata[:sources] = [result.metadata[:preset_name] || result.metadata[:source_path]].compact
            return format_bundle(result, @options[:format] || 'markdown-xml')
          end

          # Default path: use original merge logic for backward compatibility
          # This creates a new bundle without sections (uses OutputFormatter with metadata)
          bundle_hashes = bundles.map do |bundle|
            {
              files: bundle.files,
              metadata: bundle.metadata,
              preset_name: bundle.metadata[:preset_name],
              source_input: bundle.metadata[:source_input],
              errors: bundle.metadata[:errors] || []
            }
          end

          merged = @merger.merge_bundles(bundle_hashes)

          result = Models::BundleData.new(
            metadata: merged[:metadata] || {}
          )

          merged[:files]&.each do |file|
            result.add_file(file[:path], file[:content])
          end

          result.metadata[:merged] = true
          result.metadata[:total_bundles] = merged[:total_bundles]
          result.metadata[:sources] = merged[:sources]
          result.metadata[:errors] = merged[:errors] if merged[:errors]&.any?

          format_bundle(result, @options[:format] || 'markdown-xml')
        end

        # Check if bundle has sections with actual processed content
        # Returns true if sections have _processed_files, _processed_commands, or _processed_diffs
        # Note: Section data is normalized to symbol keys by SectionProcessor
        def has_processed_section_content?(bundle)
          return false unless bundle.has_sections?

          bundle.sections.any? do |_name, data|
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

          # Create bundle with formatted content
          bundle = Models::BundleData.new(metadata: data[:metadata])
          bundle.content = formatted_content
          bundle.commands = data[:commands]

          # Store individual files if embed_document_source is true
          if config['embed_document_source']
            data[:files].each do |file_info|
              bundle.add_file(file_info[:path], file_info[:content])
            end
          end

          bundle
        end

        def format_bundle(bundle, format)
          # Apply compression before formatting (if enabled)
          compress_bundle_sections(bundle)

          case format
          when 'markdown', 'yaml', 'xml', 'markdown-xml', 'json'
            # Use SectionFormatter if bundle has sections, otherwise fallback to OutputFormatter
            if bundle.has_sections?
              formatter = Molecules::SectionFormatter.new(format)
              bundle.content = formatter.format_with_sections(bundle)
            else
              # Use OutputFormatter for legacy bundles
              data = {
                files: bundle.files,
                metadata: bundle.metadata.dup,
                commands: bundle.commands,
                content: bundle.content
              }

              # Include preset_name at the top level for YAML format
              if bundle.metadata[:preset_name]
                data[:preset_name] = bundle.metadata[:preset_name]
              end

              formatter = Ace::Core::Molecules::OutputFormatter.new(format)
              bundle.content = formatter.format(data)
            end
          end

          # Post-format: compress rendered content for section bundles where
          # section-level compression was not applicable (sections had commands/diffs
          # but no files, so _processed_files was empty)
          compress_rendered_bundle(bundle)

          bundle
        end

        def compress_bundle_sections(bundle)
          # --compressor off: absolute kill switch
          return if @options[:compressor]&.to_s == "off"

          # Resolve mode: CLI > preset > config > "exact"
          compressor_mode = @options[:compressor_mode]&.to_s
          compressor_mode = bundle.metadata[:compressor_mode]&.to_s if compressor_mode.nil? || compressor_mode.empty?
          compressor_mode = Ace::Bundle.compressor_mode if compressor_mode.nil? || compressor_mode.empty?
          compressor_mode = "exact" if compressor_mode.nil? || compressor_mode.empty?

          # Resolve source_scope: CLI > preset > config > "off"
          source_scope = @options[:compressor_source_scope]&.to_s
          source_scope = bundle.metadata[:compressor_source_scope]&.to_s if source_scope.nil? || source_scope.empty?
          source_scope = Ace::Bundle.compressor_source_scope if source_scope.nil? || source_scope.empty?

          # --compressor on: force-enable if scope resolved to "off"
          if @options[:compressor]&.to_s == "on" && (source_scope.nil? || source_scope.empty? || source_scope == "off")
            source_scope = "per-source"
          end

          return if source_scope.nil? || source_scope.empty? || source_scope == "off"
          source_scope = "per-source" if %w[true on yes].include?(source_scope)

          require "ace/compressor"
          compressor = Molecules::SectionCompressor.new(default_mode: source_scope, compressor_mode: compressor_mode)
          compressor.call(bundle)
        end

        # Compress rendered bundle content in-memory for section bundles where
        # section-level compression was a no-op (no _processed_files to compress).
        # This handles template bundles with command-only/diff-only sections.
        def compress_rendered_bundle(bundle)
          return unless bundle.has_sections?
          return if bundle.metadata[:compressed]
          return if sections_have_processed_files?(bundle)

          # --compressor off: absolute kill switch
          return if @options[:compressor]&.to_s == "off"

          # Resolve compressor_mode: CLI > preset > config > "exact"
          compressor_mode = @options[:compressor_mode]&.to_s
          compressor_mode = bundle.metadata[:compressor_mode]&.to_s if compressor_mode.nil? || compressor_mode.empty?
          compressor_mode = Ace::Bundle.compressor_mode if compressor_mode.nil? || compressor_mode.empty?
          compressor_mode = "exact" if compressor_mode.nil? || compressor_mode.empty?

          # Resolve source_scope: CLI > preset > config > "off"
          source_scope = @options[:compressor_source_scope]&.to_s
          source_scope = bundle.metadata[:compressor_source_scope]&.to_s if source_scope.nil? || source_scope.empty?
          source_scope = Ace::Bundle.compressor_source_scope if source_scope.nil? || source_scope.empty?

          # --compressor on: force-enable if scope resolved to "off"
          if @options[:compressor]&.to_s == "on" && (source_scope.nil? || source_scope.empty? || source_scope == "off")
            source_scope = "per-source"
          end

          return if source_scope.nil? || source_scope.empty? || source_scope == "off"

          content = bundle.content.to_s
          return if content.strip.empty?

          require "ace/compressor"
          label = bundle.metadata[:source]&.to_s || "bundle.md"
          compressed = Ace::Compressor.compress_text(content, label: label, mode: compressor_mode)
          bundle.content = compressed
          bundle.metadata[:compressed] = true
        end

        def sections_have_processed_files?(bundle)
          return false unless bundle.has_sections?

          bundle.sections.any? { |_, data| data[:_processed_files]&.any? }
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
            bundle = Models::BundleData.new
            bundle.metadata[:error] = "Failed to resolve protocol: #{protocol_ref}"
            bundle.metadata[:protocol_ref] = protocol_ref
            bundle
          end
        end

        def resolve_protocol(protocol_ref)
          require "ace/support/nav"
          engine = Ace::Support::Nav::Organisms::NavigationEngine.new
          path = engine.resolve(protocol_ref)

          return path if path && File.exist?(path)

          # Fallback: handle cmd-type protocols (e.g., task://) by capturing command output
          protocol = protocol_ref.split("://", 2).first
          if engine.cmd_protocol?(protocol)
            cmd_path = engine.resolve_cmd_to_path(protocol_ref)
            return cmd_path if cmd_path && File.exist?(cmd_path)
          end

          if @options[:debug]
            if path.nil?
              warn "Warning: ace-nav could not resolve '#{protocol_ref}'"
            else
              warn "Warning: ace-nav path does not exist for '#{protocol_ref}': #{path}"
            end
          end
          nil
        end

        def resolve_file_reference(file_ref)
          # Check if it's a protocol reference (contains ://)
          if file_ref.match?(/^[\w-]+:\/\//)
            resolve_protocol(file_ref)
          elsif file_ref.start_with?('./') && @template_dir
            # Resolve ./ paths relative to the template file's directory
            File.join(@template_dir, file_ref)
          else
            # Regular file path or glob pattern (resolved from project root)
            file_ref
          end
        end

        # Process content for a specific section
        def process_section_content(bundle, section_name, section_data, options, bundle_config = {})
          # Process all content types that are present in the section
          if has_files_content?(section_data)
            process_files_section(bundle, section_name, section_data, options, bundle_config)
          end

          if has_commands_content?(section_data)
            process_commands_section(bundle, section_name, section_data, options, bundle_config)
          end

          if has_diffs_content?(section_data)
            process_diffs_section(bundle, section_name, section_data, options)
          end

          if has_content_content?(section_data)
            process_inline_content_section(bundle, section_name, section_data, options)
          end
        end

        # Process files section content
        def process_files_section(bundle, section_name, section_data, options, bundle_config = {})
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

          # Add files to bundle if embed_document_source is true
          if bundle_config['embed_document_source']
            result[:files].each do |file_info|
              bundle.add_file(file_info[:path], file_info[:content])
            end
          end

          # Add errors if any
          result[:errors].each do |error|
            bundle.metadata[:errors] ||= []
            bundle.metadata[:errors] << "Section '#{section_name}': #{error}"
          end
        end

        # Process commands section content
        def process_commands_section(bundle, section_name, section_data, options, bundle_config = {})
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

          # Add commands to bundle (always, like in legacy processing)
          bundle.commands = (bundle.commands || []) + processed_commands
        end

        # Process top-level PR configuration
        # Delegates to PrBundleLoader for PR fetching and section integration
        # @return [Boolean] true if PR config was present (even if fetch failed), false otherwise
        def process_pr_config(bundle, bundle_config, options)
          pr_refs = bundle_config["pr"] || bundle_config[:pr]
          return false unless pr_refs

          PrBundleLoader.new(options).process(bundle, pr_refs)
        end

        # Process diffs section content
        def process_diffs_section(bundle, section_name, section_data, options)
          ranges = section_data[:ranges] || section_data['ranges'] || []
          return unless ranges.any?

          processed_diffs = []

          ranges.each do |diff_range|
            result = generate_diff_safe(diff_range)
            processed_diffs << result.slice(:range, :output, :success, :error)

            unless result[:success]
              bundle.metadata[:errors] ||= []
              error_prefix = result[:error_type] == :git_error ? "Git diff failed" : "Invalid diff range"
              bundle.metadata[:errors] << "Section '#{section_name}': #{error_prefix} for '#{diff_range}': #{result[:error]}"
            end
          end

          # Store processed diffs in section data
          section_data[:_processed_diffs] = processed_diffs
        end

        # Process inline content section
        def process_inline_content_section(bundle, section_name, section_data, options)
          content = section_data[:content] || section_data['content']
          # Store content in section data
          section_data[:_processed_content] = content if content
        end

        # Process base content from context.base field
        #
        # Supports both file paths and inline content strings:
        # - File paths: Resolved via protocol or filesystem (e.g., "path/to/file.md", "wfi://context", "README")
        # - Inline content: Simple strings without path indicators (e.g., "System instructions")
        #
        # Resolution strategy prioritizes file existence to correctly handle extension-less files
        # (README, CONTEXT, etc.) while still supporting inline strings for simple use cases.
        def process_base_content(bundle, bundle_config, options)
          base_ref = bundle_config['base'] || bundle_config[:base]
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
            bundle.content = base_content
            bundle.metadata[:base_path] = resolved_path
            bundle.metadata[:base_ref] = base_ref
            bundle.metadata[:base_type] = 'file'
          elsif looks_like_file_ref
            # It looks like a file reference but resolution failed - set error
            if !resolved_path
              bundle.metadata[:base_error] = "Failed to resolve base reference: #{base_ref}"
              warn "Warning: Failed to resolve base reference: #{base_ref}" if options[:debug]
            else
              bundle.metadata[:base_error] = "Base file not found: #{resolved_path}"
              warn "Warning: Base file not found: #{resolved_path}" if options[:debug]
            end
          else
            # Simple string without path indicators - treat as inline content
            # This allows direct definition of base context without requiring separate files
            # Example: base: "System instructions for the task"
            bundle.content = base_ref.to_s.strip
            bundle.metadata[:base_type] = 'inline'
            bundle.metadata[:base_ref] = base_ref
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
        # @return [Models::BundleData] Context with original content and metadata
        def load_plain_markdown(original_content, frontmatter, path)
          bundle = Models::BundleData.new
          # Use original_content (preserved before frontmatter stripping)
          bundle.content = original_content
          # Store metadata from frontmatter using merge to preserve any existing metadata
          # Include frontmatter and frontmatter_yaml for parity with template path
          bundle.metadata = (bundle.metadata || {}).merge(
            frontmatter.transform_keys(&:to_sym)
          ).merge(
            source: path,
            frontmatter: frontmatter
          )
          # Store frontmatter_yaml if frontmatter was present
          bundle.metadata[:frontmatter_yaml] = frontmatter.to_yaml if frontmatter.any?

          # Check for frontmatter typos and store warnings in metadata
          warnings = detect_suspicious_keys(frontmatter, path)
          bundle.metadata[:warnings] = warnings if warnings.any?

          compress_bundle_sections(bundle)
          compress_rendered_bundle(bundle)
          bundle
        end

        # Delegate to Atoms::TypoDetector for architectural consistency
        # @deprecated Use Atoms::TypoDetector.detect_suspicious_keys directly
        def detect_suspicious_keys(frontmatter, path)
          return [] unless ENV["ACE_BUNDLE_STRICT"]

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
