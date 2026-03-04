# frozen_string_literal: true

require "yaml"
require "pathname"
require "date"

module Ace
  module Assign
    module Molecules
      # Resolves assignment metadata from skill frontmatter.
      #
      # Flow:
      # 1) Find SKILL.md by skill name (e.g., "ace-task-work")
      # 2) Read assign.source URI from skill frontmatter (e.g., wfi://task/work)
      # 3) Resolve workflow file from URI
      # 4) Parse workflow assign frontmatter (sub-phases/context)
      class SkillAssignSourceResolver
        DEFAULT_SKILL_SOURCE_PATHS = [".agent/skills", ".claude/skills"].freeze
        DEFAULT_WORKFLOW_SOURCE_PATHS = [
          "ace-taskflow/handbook/workflow-instructions",
          "ace-assign/handbook/workflow-instructions"
        ].freeze

        def initialize(project_root: nil, skill_paths: nil, workflow_paths: nil)
          @project_root = project_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          configured_skill_paths = skill_paths || Ace::Assign.config["skill_source_paths"]
          configured_workflow_paths = workflow_paths || Ace::Assign.config["workflow_source_paths"]
          configured_skill_paths = DEFAULT_SKILL_SOURCE_PATHS if configured_skill_paths.nil? || configured_skill_paths.empty?
          configured_workflow_paths = DEFAULT_WORKFLOW_SOURCE_PATHS if configured_workflow_paths.nil? || configured_workflow_paths.empty?

          @skill_paths = normalize_paths(configured_skill_paths)
          @workflow_paths = normalize_paths(configured_workflow_paths)
          @skill_index = nil
        end

        # Resolve assign config for a skill.
        #
        # @param skill_name [String] Skill identifier (e.g., "ace-task-work")
        # @return [Hash, nil] Parsed assign config (keys: :sub_phases, :context, etc.) or nil if not declared
        # @raise [Ace::Assign::Error] If skill declares an invalid/unresolvable source
        def resolve_assign_config(skill_name)
          skill_path = skill_index[skill_name] || find_skill_by_convention(skill_name)
          return nil unless skill_path

          skill_frontmatter = parse_frontmatter(File.read(skill_path))
          assign_block = skill_frontmatter["assign"]
          return nil unless assign_block.is_a?(Hash)

          source = assign_block["source"]&.to_s&.strip
          return nil if source.nil? || source.empty?

          workflow_path = resolve_source_uri(source, skill_name)
          workflow_frontmatter = parse_frontmatter(File.read(workflow_path))
          parsed = Atoms::AssignFrontmatterParser.parse(workflow_frontmatter)

          unless parsed[:valid]
            raise Error, "Invalid assign frontmatter in '#{workflow_path}' for skill '#{skill_name}': #{parsed[:errors].join('; ')}"
          end

          parsed[:config]
        end

        private

        attr_reader :project_root, :skill_paths, :workflow_paths

        def skill_index
          @skill_index ||= begin
            index = {}
            skill_paths.each do |base_path|
              Dir.glob(File.join(base_path, "**", "SKILL.md")).sort.each do |path|
                frontmatter = parse_frontmatter(File.read(path))
                name = frontmatter["name"]&.to_s
                index[name] = path if name && !name.empty?
              rescue StandardError
                next
              end
            end
            index
          end
        end

        def normalize_paths(paths)
          paths.map do |path|
            path_str = path.to_s
            if Pathname.new(path_str).absolute?
              path_str
            else
              File.expand_path(path_str, project_root)
            end
          end
        end

        def find_skill_by_convention(skill_name)
          dir_name = skill_name.to_s.tr(":", "_")
          skill_paths.each do |base_path|
            candidate = File.join(base_path, dir_name, "SKILL.md")
            return candidate if File.exist?(candidate)
          end
          nil
        end

        def parse_frontmatter(content)
          lines = content.lines
          return {} unless lines.first&.strip == "---"

          closing_index = lines[1..]&.index { |line| line.strip == "---" }
          return {} unless closing_index

          frontmatter_yaml = lines[1, closing_index].join
          YAML.safe_load(frontmatter_yaml, permitted_classes: [Date, Time]) || {}
        end

        def resolve_source_uri(uri, skill_name)
          if uri.start_with?("wfi://")
            resolve_wfi_uri(uri, skill_name)
          else
            raise Error, "Unsupported assign.source '#{uri}' for skill '#{skill_name}'. Supported: wfi://..."
          end
        end

        def resolve_wfi_uri(uri, skill_name)
          workflow_name = uri.delete_prefix("wfi://").strip
          if workflow_name.empty?
            raise Error, "Empty workflow name in assign.source '#{uri}' for skill '#{skill_name}'"
          end

          workflow_paths.each do |base_path|
            candidate = File.join(base_path, "#{workflow_name}.wf.md")
            return candidate if File.exist?(candidate)
          end

          searched = workflow_paths.join(", ")
          raise Error, "Could not resolve assign.source '#{uri}' for skill '#{skill_name}'. Searched: #{searched}"
        end
      end
    end
  end
end
