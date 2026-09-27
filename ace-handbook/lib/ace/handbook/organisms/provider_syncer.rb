# frozen_string_literal: true

require "fileutils"
require "yaml"

module Ace
  module Handbook
    module Organisms
      class ProviderSyncer
        PROJECTION_SOURCE_PREFIX = "ace-handbook-integration-"

        attr_reader :project_root, :registry, :inventory, :prompt_inventory, :config

        def initialize(
          project_root: Ace::Handbook.project_root,
          registry: nil,
          inventory: nil,
          prompt_inventory: nil,
          config: nil
        )
          @project_root = project_root
          @registry = registry || Atoms::ProviderRegistry.new(project_root: project_root)
          @inventory = inventory || SkillInventory.new(project_root: project_root)
          @prompt_inventory = prompt_inventory || PromptTemplateInventory.new(project_root: project_root)
          @config = config || Ace::Handbook.config.resolve_namespace("handbook").to_h
        end

        def sync(provider: nil)
          skills = inventory.all
          source_breakdown = summarize_sources(skills)
          providers_to_sync(provider).map do |provider_id|
            sync_provider(provider_id, skills: skills, source_breakdown: source_breakdown)
          end
        end

        private

        def sync_provider(provider, skills:, source_breakdown:)
          skills_result = sync_skills(provider, skills: skills, source_breakdown: source_breakdown)
          prompts_result = sync_prompts(provider)
          return skills_result if prompts_result.nil?

          skills_result.merge(prompts_result)
        end

        def sync_skills(provider, skills:, source_breakdown:)
          output_dir = File.join(project_root, registry.output_dir(provider))
          prepare_output_dir(output_dir)

          expected = {}
          updated_files = 0

          skills.each do |skill|
            next unless Molecules::SkillProjection.projection_targets(skill.frontmatter, registry: registry).include?(provider)

            frontmatter = Molecules::SkillProjection.projected_frontmatter(skill.frontmatter, provider: provider)
            rendered = Molecules::SkillProjection.render(frontmatter, skill.body)
            output_path = File.join(output_dir, skill.name, "SKILL.md")
            expected[skill.name] = output_path

            FileUtils.mkdir_p(File.dirname(output_path))
            next if File.exist?(output_path) && File.read(output_path) == rendered

            File.write(output_path, rendered)
            updated_files += 1
          end

          removed_entries = prune_stale_entries(output_dir, expected.keys)

          {
            provider: provider,
            relative_output_dir: registry.output_dir(provider),
            projected_skills: expected.size,
            updated_files: updated_files,
            removed_entries: removed_entries,
            source_breakdown: source_breakdown
          }
        end

        def sync_prompts(provider)
          prompts_dir = registry.prompts_dir(provider)
          return nil if prompts_dir.nil? || prompts_dir.to_s.empty?

          output_dir = File.join(project_root, prompts_dir)
          FileUtils.mkdir_p(output_dir)

          expected = {}
          updated_files = 0

          prompt_inventory.for_provider(provider).each do |template|
            output_path = File.join(output_dir, "#{template.name}.md")
            expected[template.name] = output_path
            next if File.exist?(output_path) && File.read(output_path) == template.content

            File.write(output_path, template.content)
            updated_files += 1
          end

          removed_entries = prune_stale_prompt_files(output_dir, expected.keys)

          {
            relative_prompts_dir: prompts_dir,
            projected_prompts: expected.size,
            updated_prompt_files: updated_files,
            removed_prompt_entries: removed_entries
          }
        end

        def summarize_sources(skills)
          skills.each_with_object(Hash.new(0)) do |skill, memo|
            source = skill.source.to_s
            key = source.empty? ? "unknown" : source
            memo[key] += 1
          end.sort.to_h
        end

        def providers_to_sync(requested_provider)
          if requested_provider
            provider = requested_provider.to_s
            raise ArgumentError, "Unknown provider: #{provider}" unless registry.known?(provider)
            if provider_disabled?(provider)
              raise ArgumentError, "Provider '#{provider}' is disabled in handbook sync config"
            end

            return [provider]
          end

          providers = default_sync_providers
          unknown = providers.reject { |provider| registry.known?(provider) }
          raise ArgumentError, "Unknown provider: #{unknown.join(", ")}" if unknown.any?

          providers.reject { |provider| provider_disabled?(provider) }
        end

        def default_sync_providers
          enabled = enabled_providers
          return enabled unless enabled.empty?

          return ["agents"] if registry.known?("agents") && !provider_disabled?("agents")

          registry.providers
        end

        def enabled_providers
          sync_config = config.fetch("sync", {})
          providers = sync_config.fetch("providers", {})

          Array(providers["enabled"]).map(&:to_s)
        end

        def provider_disabled?(provider)
          sync_config = config.fetch("sync", {})
          providers = sync_config.fetch("providers", {})
          disabled = Array(providers["disabled"]).map(&:to_s)

          disabled.include?(provider.to_s)
        end

        def prepare_output_dir(output_dir)
          if File.symlink?(output_dir) || File.file?(output_dir)
            FileUtils.rm_rf(output_dir)
          end

          FileUtils.mkdir_p(output_dir)
        end

        def prune_stale_entries(output_dir, expected_skill_names)
          existing = Dir.glob(File.join(output_dir, "*")).select { |path| File.directory?(path) }
          stale = existing.reject { |path| expected_skill_names.include?(File.basename(path)) }
          stale.each { |path| FileUtils.rm_rf(path) }
          stale.size
        end

        # The prompts dir is shared with user-authored templates, so only files
        # carrying an ACE integration provenance marker are ever pruned.
        def prune_stale_prompt_files(output_dir, expected_template_names)
          stale = Dir.glob(File.join(output_dir, "*.md")).reject do |path|
            expected_template_names.include?(File.basename(path, ".md"))
          end.select do |path|
            template_source(path).start_with?(PROJECTION_SOURCE_PREFIX)
          end
          stale.each { |path| FileUtils.rm(path) }
          stale.size
        end

        def template_source(path)
          match = File.read(path).match(/\A---\s*\n(.*?)\n---/m)
          return "" unless match

          frontmatter = YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true)
          frontmatter.is_a?(Hash) ? frontmatter["source"].to_s : ""
        rescue StandardError
          ""
        end
      end
    end
  end
end
