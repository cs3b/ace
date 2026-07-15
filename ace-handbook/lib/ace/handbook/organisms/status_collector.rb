# frozen_string_literal: true

module Ace
  module Handbook
    module Organisms
      class StatusCollector
        attr_reader :project_root, :registry, :config, :inventory

        def initialize(project_root: Ace::Handbook.project_root, registry: nil, inventory: nil, config: nil)
          @project_root = project_root
          @registry = registry || Atoms::ProviderRegistry.new(project_root: project_root)
          @inventory = inventory || SkillInventory.new(project_root: project_root)
          @config = config || Ace::Handbook.config.resolve_namespace("handbook").to_h
        end

        def collect(provider: nil)
          skills = inventory.all

          {
            "canonical" => canonical_summary(skills),
            "providers" => selected_providers(provider).map { |provider_id| provider_status(provider_id, skills) }
          }
        end

        def to_table(snapshot)
          summary_lines = canonical_summary_lines(snapshot.fetch("canonical"))
          rows = snapshot.fetch("providers").map do |entry|
            [
              entry.fetch("provider"),
              entry.fetch("enabled") ? "yes" : "no",
              entry.fetch("path_type"),
              entry.fetch("expected").to_s,
              entry.fetch("installed").to_s,
              entry.fetch("in_sync").to_s,
              entry.fetch("outdated").to_s,
              entry.fetch("missing").to_s,
              entry.fetch("extra").to_s,
              entry.fetch("projection_policy", "").to_s,
              entry.fetch("excluded_count", "").to_s,
              entry.fetch("policy_reason", "").to_s,
              entry.fetch("relative_output_dir")
            ]
          end

          widths = [
            ["PROVIDER", *rows.map { |row| row[0] }].map(&:length).max,
            ["ENABLED", *rows.map { |row| row[1] }].map(&:length).max,
            ["TYPE", *rows.map { |row| row[2] }].map(&:length).max,
            ["EXPECTED", *rows.map { |row| row[3] }].map(&:length).max,
            ["INSTALLED", *rows.map { |row| row[4] }].map(&:length).max,
            ["IN_SYNC", *rows.map { |row| row[5] }].map(&:length).max,
            ["OUTDATED", *rows.map { |row| row[6] }].map(&:length).max,
            ["MISSING", *rows.map { |row| row[7] }].map(&:length).max,
            ["EXTRA", *rows.map { |row| row[8] }].map(&:length).max,
            ["POLICY", *rows.map { |row| row[9] }].map(&:length).max,
            ["EXCLUDED", *rows.map { |row| row[10] }].map(&:length).max,
            ["REASON", *rows.map { |row| row[11] }].map(&:length).max,
            ["PATH", *rows.map { |row| row[12] }].map(&:length).max
          ]

          right_aligned = (3..8).to_a + [10]
          formats = widths.each_index.map do |index|
            right_aligned.include?(index) ? "%#{widths[index]}s" : "%-#{widths[index]}s"
          end
          table_format = formats.join("  ")
          headers = %w[PROVIDER ENABLED TYPE EXPECTED INSTALLED IN_SYNC OUTDATED MISSING EXTRA POLICY EXCLUDED REASON PATH]
          header = format(table_format, *headers)
          lines = rows.map { |row| format(table_format, *row) }

          (summary_lines + ["", header] + lines).join("\n")
        end

        private

        def canonical_summary(skills)
          counts = skills.group_by(&:source).transform_values(&:size)

          {
            "total" => skills.size,
            "by_source" => counts.keys.sort.map do |source|
              {"source" => source, "count" => counts.fetch(source)}
            end
          }
        end

        def provider_status(provider, skills)
          relative_output_dir = registry.output_dir(provider)
          output_dir = File.join(project_root, relative_output_dir)
          expected = expected_projection_map(provider, skills)
          installed_paths = installed_skill_paths(output_dir)
          installed_names = installed_paths.map { |path| File.basename(File.dirname(path)) }

          in_sync = 0
          outdated = 0
          extra = 0

          installed_paths.each do |path|
            skill_name = File.basename(File.dirname(path))
            expected_content = expected[skill_name]

            if expected_content.nil?
              extra += 1
            elsif File.read(path) == expected_content
              in_sync += 1
            else
              outdated += 1
            end
          end

          status = {
            "provider" => provider,
            "enabled" => provider_enabled?(provider),
            "relative_output_dir" => relative_output_dir,
            "output_dir" => output_dir,
            "path_type" => path_type(output_dir),
            "manifest_path" => registry.manifest(provider)["_manifest_path"],
            "expected" => expected.size,
            "installed" => installed_paths.size,
            "in_sync" => in_sync,
            "outdated" => outdated,
            "missing" => (expected.keys - installed_names).size,
            "extra" => extra
          }

          status.merge!(projection_coverage(skills, expected)) if provider == "agents"
          status
        end

        def projection_coverage(skills, expected)
          excluded_count = skills.size - expected.size

          {
            "projection_policy" => excluded_count.zero? ? "complete" : "curated",
            "excluded_count" => excluded_count,
            "policy_reason" => excluded_count.zero? ? nil : "provider-specific targeting"
          }
        end

        def expected_projection_map(provider, skills)
          skills.each_with_object({}) do |skill, expected|
            next unless Molecules::SkillProjection.projection_targets(skill.frontmatter, registry: registry).include?(provider)

            frontmatter = Molecules::SkillProjection.projected_frontmatter(skill.frontmatter, provider: provider)
            expected[skill.name] = Molecules::SkillProjection.render(frontmatter, skill.body)
          end
        end

        def installed_skill_paths(output_dir)
          return [] unless Dir.exist?(output_dir)

          Dir.glob(File.join(output_dir, "*", "SKILL.md")).sort
        end

        def canonical_summary_lines(summary)
          rows = summary.fetch("by_source").map { |entry| [entry.fetch("source"), entry.fetch("count").to_s] }
          source_width = ["SOURCE", *rows.map { |row| row[0] }, "TOTAL"].map(&:length).max
          count_width = ["COUNT", *rows.map { |row| row[1] }, summary.fetch("total").to_s].map(&:length).max

          lines = [
            "CANONICAL SKILLS",
            format("%-#{source_width}s  %#{count_width}s", "SOURCE", "COUNT")
          ]
          rows.each do |source, count|
            lines << format("%-#{source_width}s  %#{count_width}s", source, count)
          end
          lines << format("%-#{source_width}s  %#{count_width}s", "TOTAL", summary.fetch("total"))
          lines
        end

        def selected_providers(provider)
          selected = if provider
            [provider.to_s]
          else
            default_status_providers
          end
          unknown = selected.reject { |provider_id| registry.known?(provider_id) }
          raise ArgumentError, "Unknown provider: #{unknown.join(", ")}" if unknown.any?

          selected
        end

        def default_status_providers
          enabled = enabled_providers
          return enabled unless enabled.empty?

          return ["agents"] if registry.known?("agents") && !provider_disabled?("agents")

          registry.providers.reject { |provider| provider_disabled?(provider) }
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

        def provider_enabled?(provider)
          enabled = enabled_providers

          return enabled.include?(provider) unless enabled.empty?

          return provider.to_s == "agents" if registry.known?("agents")

          !provider_disabled?(provider)
        end

        def path_type(path)
          return "symlink" if File.symlink?(path)
          return "directory" if File.directory?(path)
          return "file" if File.file?(path)

          "missing"
        end
      end
    end
  end
end
