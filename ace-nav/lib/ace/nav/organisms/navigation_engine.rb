# frozen_string_literal: true

require_relative "../molecules/handbook_scanner"
require_relative "../molecules/resource_resolver"
require_relative "../molecules/task_resolver"
require_relative "../atoms/path_normalizer"

module Ace
  module Nav
    module Organisms
      # Orchestrates navigation operations
      class NavigationEngine
        def initialize(handbook_scanner: nil, resource_resolver: nil, task_resolver: nil, path_normalizer: nil)
          @handbook_scanner = handbook_scanner || Molecules::HandbookScanner.new
          @resource_resolver = resource_resolver || Molecules::ResourceResolver.new(handbook_scanner: @handbook_scanner)
          @task_resolver = task_resolver || Molecules::TaskResolver.new
          @path_normalizer = path_normalizer || Atoms::PathNormalizer.new
        end

        # Resolve a single resource URI to a path
        def resolve(uri_string, options = {})
          # Check if it's a task URI
          if uri_string.start_with?("task://")
            resolve_task(uri_string, options)
          else
            resource = @resource_resolver.resolve(uri_string)
            return nil unless resource

            if options[:content]
              resource.content
            elsif options[:verbose]
              resource.to_h
            else
              resource.path
            end
          end
        end

        # List resources matching a pattern
        def list(uri_pattern, options = {})
          # Check if it's a task pattern
          if uri_pattern.start_with?("task://")
            list_tasks(uri_pattern, options)
          else
            resources = @resource_resolver.resolve_pattern(uri_pattern)

            if options[:tree]
              format_as_tree(resources)
            elsif options[:verbose]
              resources.map(&:to_h)
            else
              format_as_list(resources)
            end
          end
        end

        # Create a new resource from a template
        def create(uri_string, target_path = nil)
          # Resolve the template
          template = @resource_resolver.resolve(uri_string)
          return { error: "Template not found: #{uri_string}" } unless template

          # Determine target path
          target = determine_target_path(template, target_path)
          return { error: "Could not determine target path" } unless target

          # Create directory if needed
          target_dir = File.dirname(target)
          FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

          # Copy template content
          if template.content
            File.write(target, template.content)
            { created: target, from: template.path }
          else
            { error: "Template has no content: #{template.path}" }
          end
        end

        # Show available sources
        def sources(options = {})
          all_sources = @handbook_scanner.scan_all_sources

          if options[:verbose]
            all_sources.map(&:to_h)
          else
            all_sources.map { |s| "#{s.alias_name} (#{s.type}): #{s.handbook_path}" }
          end
        end

        private

        def resolve_task(uri_string, options = {})
          # Extract task identifier from URI
          task_id = uri_string.sub("task://", "")

          # Find the task file
          task_path = @task_resolver.resolve(task_id)
          return nil unless task_path

          if options[:content]
            File.read(task_path)
          elsif options[:verbose]
            {
              uri: uri_string,
              path: task_path,
              exists: File.exist?(task_path)
            }
          else
            task_path
          end
        end

        def list_tasks(uri_pattern, options = {})
          # Extract pattern from URI
          pattern = uri_pattern.sub("task://", "")

          # Get matching task files
          tasks = @task_resolver.list_tasks(pattern)

          if options[:verbose]
            tasks.map do |path|
              {
                uri: "task://#{File.basename(path, ".md")}",
                path: path
              }
            end
          else
            tasks.map do |path|
              "task://#{File.basename(path, ".md")} → #{path}"
            end
          end
        end

        def format_as_list(resources)
          resources.map do |resource|
            "#{resource.uri} → #{resource.path} (#{resource.source.alias_name})"
          end
        end

        def format_as_tree(resources)
          # Group by source
          by_source = resources.group_by { |r| r.source.alias_name }

          tree = []
          by_source.each do |source_alias, source_resources|
            tree << "#{source_alias}/"

            # Group by protocol
            by_protocol = source_resources.group_by(&:protocol)
            by_protocol.each do |protocol, protocol_resources|
              tree << "  #{protocol}://"

              # Sort and display resources
              protocol_resources.sort_by(&:resource_path).each do |resource|
                tree << "    #{resource.resource_path}"
              end
            end
          end

          tree
        end

        def determine_target_path(template, target_path)
          # If explicit target provided, use it
          return @path_normalizer.normalize(target_path) if target_path

          # Otherwise, create in project .ace/handbook
          project_handbook = File.expand_path("./.ace/handbook")

          # Determine subdirectory based on protocol
          subdir = case template.protocol
                   when "wfi" then "workflow-instructions"
                   when "tmpl" then "templates"
                   when "guide" then "guides"
                   when "sample" then "samples"
                   else template.protocol
                   end

          # Build target path
          filename = File.basename(template.path)
          File.join(project_handbook, subdir, filename)
        end
      end
    end
  end
end