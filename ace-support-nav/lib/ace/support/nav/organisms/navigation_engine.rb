# frozen_string_literal: true

require_relative "../molecules/protocol_scanner"
require_relative "../molecules/resource_resolver"
require_relative "../atoms/path_normalizer"

module Ace
  module Support
    module Nav
      module Organisms
        # Orchestrates navigation operations
        class NavigationEngine
          def initialize(handbook_scanner: nil, protocol_scanner: nil, resource_resolver: nil, path_normalizer: nil)
            # Support legacy handbook_scanner parameter
            @protocol_scanner = protocol_scanner || handbook_scanner || Molecules::ProtocolScanner.new
            @resource_resolver = resource_resolver || Molecules::ResourceResolver.new(protocol_scanner: @protocol_scanner)
            @path_normalizer = path_normalizer || Atoms::PathNormalizer.new
          end

          # Resolve a single resource URI to a path
          def resolve(uri_string, options = {})
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

          # List resources matching a pattern
          def list(uri_pattern, options = {})
            resources = @resource_resolver.resolve_pattern(uri_pattern)

            if options[:tree]
              format_as_tree(resources)
            elsif options[:verbose]
              resources.map(&:to_h)
            else
              format_as_list(resources)
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
            all_sources = @protocol_scanner.scan_all_sources

            if options[:verbose]
              all_sources.map(&:to_h)
            else
              all_sources.map { |s| "#{s.alias_name} (#{s.type}): #{s.path}" }
            end
          end

          # Get all discovered protocols
          def discovered_protocols
            config_loader.discovered_protocols
          end

          # Check if a protocol is cmd-type (command delegation)
          # @param protocol_name [String] The protocol name to check
          # @return [Boolean] true if protocol delegates to external command
          def cmd_protocol?(protocol_name)
            config_loader.protocol_type(protocol_name) == "cmd"
          end

          # Resolve a cmd-type protocol URI by running its command and capturing stdout
          # Used by tools that need to programmatically obtain the resolved path
          # @param uri_string [String] e.g., "task://8c0.t.05p"
          # @return [String, nil] captured stdout (path), or nil on failure
          def resolve_cmd_to_path(uri_string)
            protocol, reference = uri_string.split("://", 2)
            return nil unless cmd_protocol?(protocol)

            protocol_config = config_loader.load_protocol_config(protocol)
            command_template = protocol_config["command_template"]
            return nil unless command_template

            require "open3"
            require "shellwords"
            require "timeout"
            args = Shellwords.split(command_template.gsub("%{ref}", Shellwords.escape(reference)))
            stdout, status = Timeout.timeout(10) { Open3.capture2(*args) }
            return nil unless status.success?

            result = stdout.strip
            result.empty? ? nil : result
          rescue Timeout::Error
            warn "Warning: cmd protocol timed out for '#{uri_string}'"
            nil
          end

          private

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

            # Otherwise, create in project .ace-handbook
            project_handbook = File.expand_path("./.ace-handbook")

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

          # Access the config_loader from protocol_scanner
          # Reuses the same ConfigLoader instance across all protocol operations
          def config_loader
            @protocol_scanner.config_loader
          end
        end
      end
    end
  end
end
