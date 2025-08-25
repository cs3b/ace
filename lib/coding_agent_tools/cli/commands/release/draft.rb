# frozen_string_literal: true

require "dry/cli"
require "fileutils"
require "pathname"
require "date"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Release
        # Draft command for creating new release directory structure
        # Always operates relative to project root to ensure releases are created
        # in the correct location regardless of current working directory
        class Draft < Dry::CLI::Command
          desc "Create a new release draft in backlog with directory structure (at project root)"

          argument :version, required: true, desc: "Semantic version (e.g., v.0.1.0)"
          argument :codename, required: true, desc: "Release codename (e.g., foundation)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          example [
            "v.0.1.0 foundation",
            "v.0.2.0 compass",
            "v.1.0.0 stable"
          ]

          def call(version:, codename:, **options)
            @debug = options[:debug]
            
            # Validate version format
            unless version.match?(/^v\.\d+\.\d+\.\d+$/)
              error_output("Error: Version must follow semantic versioning format (v.X.Y.Z)")
              return 1
            end

            # Find project root - this ensures we always work from the project root
            # regardless of where the command is executed from
            project_root = Pathname.new(CodingAgentTools::Atoms::ProjectRootDetector.find_project_root)
            
            # Ensure dev-taskflow exists at project root
            taskflow_path = project_root.join("dev-taskflow")
            unless taskflow_path.exist?
              error_output("Error: dev-taskflow directory not found at project root: #{project_root}")
              error_output("Please ensure dev-taskflow exists or run 'coding-agent-tools integrate claude --init-project' first")
              return 1
            end
            
            # Construct release directory path - always relative to project root
            release_name = "#{version}-#{codename}"
            release_path = taskflow_path.join("backlog", release_name)
            
            # Check if release already exists
            if release_path.exist?
              error_output("Error: Release #{release_name} already exists at #{release_path}")
              return 1
            end

            # Find template directory
            template_path = find_template_path(project_root)
            
            unless template_path && template_path.exist?
              error_output("Error: Release template not found. Expected at dev-handbook/.meta/tpl/project-structure/release-dir-structure/")
              return 1
            end

            # Create release structure
            begin
              create_release_structure(release_path, template_path)
              create_release_overview(release_path, version, codename)
              
              success_output("✓ Created release draft: #{release_name}")
              success_output("  Location: #{release_path}")
              success_output("")
              success_output("Next steps:")
              success_output("  1. Update release-overview.md with goals and scope")
              success_output("  2. Create tasks for the release using task-manager")
              success_output("  3. Update dev-taskflow/roadmap.md with the new release")
              
              0
            rescue StandardError => e
              error_output("Error creating release: #{e.message}")
              warn e.backtrace.join("\n") if @debug
              1
            end
          end

          private

          def find_template_path(project_root)
            # Try to find dev-handbook as submodule or directory
            handbook_paths = [
              project_root.join("dev-handbook"),
              project_root.parent.join("dev-handbook")
            ]
            
            handbook_path = handbook_paths.find(&:exist?)
            return nil unless handbook_path
            
            handbook_path.join(".meta", "tpl", "project-structure", "release-dir-structure")
          end

          def create_release_structure(release_path, template_path)
            # Create release directory
            FileUtils.mkdir_p(release_path)
            
            # Copy template structure
            template_path.children.each do |item|
              target = release_path.join(item.basename)
              
              if item.directory?
                FileUtils.cp_r(item, target)
              else
                FileUtils.cp(item, target)
              end
            end
          end

          def create_release_overview(release_path, version, codename)
            overview_path = release_path.join("release-overview.md")
            
            content = <<~MARKDOWN
              # Release #{version} - "#{codename.capitalize}"
              
              ## Status
              **Phase**: Planning  
              **Start Date**: #{Date.today}  
              **Target Date**: TBD  
              **Progress**: 0%
              
              ## Goals
              
              - [ ] Primary goal 1
              - [ ] Primary goal 2
              - [ ] Primary goal 3
              
              ## Scope
              
              ### In Scope
              - Feature or improvement 1
              - Feature or improvement 2
              
              ### Out of Scope
              - Deferred item 1
              - Deferred item 2
              
              ## Success Criteria
              
              - [ ] All tests passing
              - [ ] Documentation updated
              - [ ] Release notes prepared
              
              ## Notes
              
              _Add any relevant notes, decisions, or context here._
            MARKDOWN
            
            File.write(overview_path, content)
          end

          def success_output(message)
            puts message
          end

          def error_output(message)
            warn message
          end
        end
      end
    end
  end
end