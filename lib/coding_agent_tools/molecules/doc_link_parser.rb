# frozen_string_literal: true

require_relative "../atoms/file_reference_extractor"
require_relative "../atoms/path_resolver"
require_relative "../atoms/docs_dependencies_config_loader"

module CodingAgentTools::Molecules
  # Molecule for parsing and resolving documentation links
  # Combines file reference extraction with path resolution
  class DocLinkParser
    def initialize(config_path = nil)
      @reference_extractor = CodingAgentTools::Atoms::FileReferenceExtractor.new
      @path_resolver = CodingAgentTools::Atoms::PathResolver.new
      @config_loader = CodingAgentTools::Atoms::DocsDependenciesConfigLoader.new(config_path)
      @config = @config_loader.load_config
    end

    # Parse file and return resolved references that exist
    def parse_file_references(file_path, all_files)
      return [] unless File.exist?(file_path)

      content = File.read(file_path)
      references = []

      # Extract all references from content
      raw_references = @reference_extractor.extract_all_references(content)

      raw_references.each do |link|
        # Check if we should skip external links
        if @reference_extractor.external_link?(link) && !@config_loader.include_external_links?(@config)
          next
        end

        # Check if we should skip anchor links
        if @reference_extractor.anchor_link?(link) && !@config_loader.include_anchor_links?(@config)
          next
        end

        # Skip if it's neither external nor anchor but also not internal
        # (this handles edge cases)
        is_valid_link = @reference_extractor.internal_link?(link) ||
          (@reference_extractor.external_link?(link) && @config_loader.include_external_links?(@config)) ||
          (@reference_extractor.anchor_link?(link) && @config_loader.include_anchor_links?(@config))
        next unless is_valid_link

        # Resolve the link relative to the source file
        resolved_path = @path_resolver.resolve_link(file_path, link)

        # Only include if target exists in our file set
        if all_files.include?(resolved_path)
          references << resolved_path
        end
      end

      references
    end

    # Get all files matching documentation patterns
    def collect_documentation_files
      file_patterns = @config_loader.get_file_patterns(@config)
      exclude_patterns = @config_loader.get_exclude_patterns(@config)
      skip_folders = @config_loader.get_skip_folders(@config)

      files = Set.new

      file_patterns.each do |_type, pattern|
        Dir.glob(pattern).each do |file|
          next unless File.file?(file)

          # Skip if file matches any exclude pattern
          next if exclude_patterns.any? { |exclude| File.fnmatch(exclude, file) }

          # Skip if file is in any skip folder
          next if skip_folders.any? { |folder| file.start_with?("#{folder}/") }

          files << file
        end
      end

      files
    end

    # Parse references with context about link types
    def parse_with_context(file_path, all_files)
      return {markdown_links: [], context_refs: []} unless File.exist?(file_path)

      content = File.read(file_path)
      result = {markdown_links: [], context_refs: []}

      # Process markdown links separately
      @reference_extractor.extract_markdown_links(content).each do |text, link|
        next unless @reference_extractor.internal_link?(link)

        resolved_path = @path_resolver.resolve_link(file_path, link)
        if all_files.include?(resolved_path)
          result[:markdown_links] << {text: text, link: link, resolved: resolved_path}
        end
      end

      # Process context references separately
      @reference_extractor.extract_context_references(content).each do |ref|
        resolved_path = @path_resolver.resolve_link(file_path, ref)
        if all_files.include?(resolved_path)
          result[:context_refs] << {original: ref, resolved: resolved_path}
        end
      end

      result
    end
  end
end
