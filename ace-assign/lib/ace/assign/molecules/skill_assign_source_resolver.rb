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
      # 4) Parse workflow assign frontmatter (sub-steps/context)
      class SkillAssignSourceResolver
        ASSIGN_CAPABLE_KINDS = %w[workflow orchestration].freeze

        def initialize(project_root: nil, skill_paths: nil, workflow_paths: nil)
          @project_root = project_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          configured_skill_paths = skill_paths || Ace::Assign.config["skill_source_paths"]
          configured_workflow_paths = workflow_paths || Ace::Assign.config["workflow_source_paths"]

          canonical_paths = discover_canonical_skill_source_paths
          canonical_workflow_paths = discover_canonical_workflow_source_paths
          override_paths = normalize_paths(configured_skill_paths || [])
          if canonical_workflow_paths.empty? && (configured_workflow_paths.nil? || configured_workflow_paths.empty?)
            configured_workflow_paths = discover_workspace_workflow_paths
          end
          configured_workflow_paths = canonical_workflow_paths if configured_workflow_paths.nil? || configured_workflow_paths.empty?
          @skill_paths = (canonical_paths + override_paths).uniq
          @workflow_paths = (canonical_workflow_paths + normalize_paths(configured_workflow_paths || [])).uniq
          @skill_index = nil
        end

        # Resolve assign config for a skill.
        #
        # @param skill_name [String] Skill identifier (e.g., "ace-task-work")
        # @return [Hash, nil] Parsed assign config (keys: :sub_steps, :context, etc.) or nil if not declared
        # @raise [Ace::Assign::Error] If skill declares an invalid/unresolvable source
        def resolve_assign_config(skill_name)
          skill_path = skill_index[skill_name] || find_skill_by_convention(skill_name)
          return nil unless skill_path

          skill_frontmatter = parse_frontmatter(File.read(skill_path))
          if assign_capable_skill_frontmatter?(skill_frontmatter) && skill_frontmatter["assign"]
            validate_assign_source!(skill_frontmatter["assign"], skill_name)
          end

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

        # List assign-capable canonical skills discovered from skill sources.
        #
        # Assign-capable skills are canonical skills with:
        # - skill.kind: workflow|orchestration
        # - assign.source present and non-empty
        #
        # @return [Array<String>] Skill names
        # @raise [Ace::Assign::Error] When assign-capable skill has invalid assign metadata
        def assign_capable_skill_names
          skill_index.keys.sort.filter do |skill_name|
            skill_path = skill_index[skill_name]
            frontmatter = parse_frontmatter(File.read(skill_path))
            next false unless assign_capable_skill_frontmatter?(frontmatter)
            next false unless frontmatter["assign"].is_a?(Hash)

            validate_assign_source!(frontmatter["assign"], skill_name)
            true
          end
        end

        # Build assignment step entries from canonical skills.
        #
        # Only steps declared under `assign.steps` are emitted here. This keeps
        # canonical skills authoritative for public skill-backed assignment steps,
        # while internal helper steps can continue to use catalog templates.
        #
        # @return [Array<Hash>] Step definitions keyed by canonical precedence
        def assign_step_catalog
          catalog = {}

          each_assign_capable_skill do |skill_name, frontmatter|
            steps = frontmatter.dig("assign", "steps")
            workflow_source = frontmatter.dig("assign", "source")&.to_s&.strip
            workflow_source = frontmatter.dig("skill", "execution", "workflow")&.to_s&.strip if workflow_source.nil? || workflow_source.empty?
            next unless steps.is_a?(Array)

            steps.each do |step|
              next unless step.is_a?(Hash)

              step_name = step["name"]&.to_s&.strip
              next if step_name.nil? || step_name.empty?
              next if catalog.key?(step_name)

              entry = step.dup
              entry["name"] = step_name
              entry["skill"] = skill_name
              entry["source_skill"] = skill_name
              entry["workflow"] = workflow_source if workflow_source && !workflow_source.empty?
              entry["description"] ||= frontmatter["description"]
              catalog[step_name] = entry
            end
          end

          catalog.values
        end

        # Resolve canonical skill rendering details for a skill-backed step.
        #
        # @param skill_name [String]
        # @return [Hash, nil]
        def resolve_skill_rendering(skill_name)
          skill_path = skill_index[skill_name] || find_skill_by_convention(skill_name)
          return nil unless skill_path

          frontmatter, skill_body = parse_frontmatter_and_body(File.read(skill_path))
          workflow_source = frontmatter.dig("assign", "source")&.to_s&.strip
          if workflow_source.nil? || workflow_source.empty?
            workflow_source = frontmatter.dig("skill", "execution", "workflow")&.to_s&.strip
          end

          workflow_path = resolve_workflow_path(workflow_source, skill_name)
          workflow_body = workflow_path ? parse_frontmatter_and_body(File.read(workflow_path)).last.to_s.strip : ""

          {
            "name" => frontmatter["name"] || skill_name,
            "description" => frontmatter["description"],
            "skill" => skill_name,
            "workflow" => workflow_source,
            "workflow_path" => workflow_path,
            "body" => workflow_body.empty? ? skill_body.to_s.strip : workflow_body
          }
        end

        def resolve_workflow_rendering(workflow_source, step_name: nil, source_skill: nil)
          workflow_ref = workflow_source&.to_s&.strip
          return nil if workflow_ref.nil? || workflow_ref.empty?

          workflow_path = resolve_workflow_path(workflow_ref, step_name || source_skill || workflow_ref)
          return nil unless workflow_path

          frontmatter, body = parse_frontmatter_and_body(File.read(workflow_path))
          {
            "name" => step_name || frontmatter["name"],
            "description" => frontmatter["description"],
            "workflow" => workflow_ref,
            "workflow_path" => workflow_path,
            "source_skill" => source_skill,
            "body" => body.to_s.strip
          }
        end

        def resolve_workflow_assign_config(workflow_source, step_name: nil, source_skill: nil)
          rendering = resolve_workflow_rendering(workflow_source, step_name: step_name, source_skill: source_skill)
          return nil unless rendering && rendering["workflow_path"]

          workflow_frontmatter = parse_frontmatter(File.read(rendering["workflow_path"]))
          parsed = Atoms::AssignFrontmatterParser.parse(workflow_frontmatter)
          return nil unless parsed[:valid]

          parsed[:config]
        end

        # Resolve canonical rendering details for a public step name.
        #
        # @param step_name [String]
        # @return [Hash, nil]
        def resolve_step_rendering(step_name)
          entry = assign_step_catalog.find { |step| step["name"] == step_name }
          return nil unless entry

          workflow_rendering = resolve_workflow_rendering(
            entry["workflow"],
            step_name: entry["name"],
            source_skill: entry["source_skill"] || entry["skill"]
          )
          return entry.merge(workflow_rendering) if workflow_rendering

          rendering = resolve_skill_rendering(entry["skill"])
          return nil unless rendering

          entry.merge(rendering)
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
                index[name] ||= path if name && !name.empty?
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
          parse_frontmatter_and_body(content).first
        end

        def parse_frontmatter_and_body(content)
          lines = content.lines
          return [{}, content.to_s] unless lines.first&.strip == "---"

          closing_index = lines[1..]&.index { |line| line.strip == "---" }
          return [{}, content.to_s] unless closing_index

          frontmatter_yaml = lines[1, closing_index].join
          frontmatter = YAML.safe_load(frontmatter_yaml, permitted_classes: [Date, Time]) || {}
          body_lines = lines[(closing_index + 2)..] || []
          [frontmatter, body_lines.join]
        end

        def assign_capable_skill_frontmatter?(frontmatter)
          kind = frontmatter.dig("skill", "kind")&.to_s
          ASSIGN_CAPABLE_KINDS.include?(kind)
        end

        def validate_assign_source!(assign_block, skill_name)
          source = assign_block["source"]&.to_s&.strip
          if source.nil? || source.empty?
            raise Error, "Missing assign.source for assign-capable skill '#{skill_name}'"
          end
        end

        def resolve_workflow_path(workflow_source, reference_name)
          return nil if workflow_source.nil? || workflow_source.empty?
          return nil unless workflow_source.start_with?("wfi://")

          resolve_source_uri(workflow_source, reference_name)
        end

        def each_assign_capable_skill
          skill_index.each do |skill_name, skill_path|
            frontmatter = parse_frontmatter(File.read(skill_path))
            next unless assign_capable_skill_frontmatter?(frontmatter)
            next unless frontmatter["assign"].is_a?(Hash)

            validate_assign_source!(frontmatter["assign"], skill_name)
            yield skill_name, frontmatter
          end
        end

        def discover_canonical_skill_source_paths
          discover_protocol_source_paths(
            protocol: "skill",
            package_glob: File.join(project_root, "*", ".ace-defaults", "nav", "protocols", "skill-sources", "*.yml")
          )
        end

        def discover_canonical_workflow_source_paths
          discover_protocol_source_paths(
            protocol: "wfi",
            package_glob: File.join(project_root, "*", ".ace-defaults", "nav", "protocols", "wfi-sources", "*.yml")
          )
        end

        def discover_protocol_source_paths(protocol:, package_glob:)
          registry_paths = Dir.chdir(project_root) do
            registry = Ace::Support::Nav::Molecules::SourceRegistry.new
            registry.sources_for_protocol(protocol).filter_map do |source|
              next if source.config.is_a?(Hash) && source.config["enabled"] == false

              candidate = resolve_source_directory(source)
              File.directory?(candidate) ? candidate : nil
            rescue StandardError
              nil
            end
          end

          (registry_paths + discover_package_default_source_paths(package_glob)).uniq
        end

        def resolve_source_directory(source)
          candidate = source.full_path
          return candidate if File.directory?(candidate)

          relative_path = source.config&.dig("relative_path")&.to_s&.strip
          return nil if relative_path.nil? || relative_path.empty?

          return nil unless source.config_file&.include?("/.ace-defaults/")

          package_root = source.config_file.split("/.ace-defaults/").first
          fallback = File.expand_path(relative_path, package_root)
          File.directory?(fallback) ? fallback : nil
        end

        def discover_package_default_source_paths(source_glob)
          source_files = Dir.glob(source_glob).sort
          source_files.filter_map do |source_file|
            source_data = YAML.safe_load_file(source_file, permitted_classes: [Date, Time]) || {}
            relative_path = source_data.dig("config", "relative_path")&.to_s&.strip
            next if relative_path.nil? || relative_path.empty?

            package_root = File.expand_path("../../../../..", source_file)
            candidate = File.expand_path(relative_path, package_root)
            File.directory?(candidate) ? candidate : nil
          rescue StandardError
            nil
          end
        end

        def discover_workspace_workflow_paths
          Dir.glob(File.join(project_root, "*", "handbook", "workflow-instructions")).sort
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
