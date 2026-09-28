# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "tempfile"
require "yaml"

module Ace
  module Handbook
    module Organisms
      class ProviderSyncer
        PROJECTION_SOURCE_PREFIX = "ace-handbook-integration-"
        EXTENSION_RECEIPT_NAME = ".ace-handbook-projection.json"

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
          result = sync_skills(provider, skills: skills, source_breakdown: source_breakdown)
          prompts_result = sync_prompts(provider)
          result = result.merge(prompts_result) unless prompts_result.nil?
          extensions_result = sync_extensions(provider)
          result = result.merge(extensions_result) unless extensions_result.nil?
          result
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

        # Extension assets project from a package's handbook/extensions/ tree
        # into the provider manifest's extensions_dir. The target directory may
        # hold user-authored extensions, so pruning is receipt-based: only files
        # recorded in the projection receipt from a previous sync are removed.
        def sync_extensions(provider)
          extensions_dir = registry.extensions_dir(provider)
          return nil if extensions_dir.nil? || extensions_dir.to_s.empty?

          source_dir = File.join(registry.package_root(provider), "handbook", "extensions")
          expected = extension_source_files(source_dir)
          output_dir = File.join(project_root, extensions_dir)
          FileUtils.mkdir_p(output_dir)

          receipt = read_projection_receipt(output_dir, provider)
          # Ownership requires a valid receipt from this projection explicitly
          # listing the path. A missing, symlinked, or corrupt receipt leaves
          # ownership unknown: any conflicting destination file is refused so
          # user-authored extensions can never be overwritten on a guess.
          owned_paths = receipt&.fetch("files", []) || []
          reject_unowned_collisions(output_dir, expected.keys, owned_paths)

          # Pruning happens only after the replacement projection committed:
          # a failed upgrade must leave the previous installation usable.
          stale_paths = receipt&.fetch("files", [])&.-(expected.keys) || []
          updated_files = 0

          # Resolve and validate every destination before writing anything: a
          # failure mid-copy must never leave half a projection behind (files
          # written before a later validation error would be unowned and wedge
          # every retry).
          output_paths = expected.each_with_object({}) do |(relative_path, source_path), map|
            map[relative_path] = validate_projection_destination(output_dir, relative_path, extensions_dir)
          end

          newly_created = []
          saved_originals = {}
          failed_prunes = []
          begin
            output_paths.each do |relative_path, output_path|
              source_path = expected.fetch(relative_path)
              FileUtils.mkdir_p(File.dirname(output_path))
              created = !File.exist?(output_path)
              # Register before copying: a copy that fails partway (disk
              # exhaustion) must still roll back the partial file. Overwritten
              # files are receipt-owned, so rollback restores their previous
              # content instead of deleting them.
              saved_originals[output_path] = File.binread(output_path) unless created
              newly_created << output_path if created
              next if !created && FileUtils.compare_file(source_path, output_path)

              FileUtils.cp(source_path, output_path)
              updated_files += 1
            end

            removed_entries = prune_stale_extension_files(output_dir, stale_paths, failed_prunes)
            # Stale files whose removal failed keep their ownership until a
            # later sync manages to delete them.
            write_projection_receipt(output_dir, provider, expected.keys + failed_prunes)
          rescue
            # Roll back so a retry never finds its own partial installation
            # standing in the way as an unowned collision, and restore the
            # previous content of overwritten files — the previous
            # installation must stay complete and loadable.
            newly_created.each do |path|
              FileUtils.rm_f(path)
            rescue
              nil
            end
            saved_originals.each do |path, content|
              File.binwrite(path, content)
            rescue
              nil
            end
            newly_created.each do |path|
              remove_empty_parent_dirs(File.dirname(path), output_dir)
            end
            raise
          end

          {
            relative_extensions_dir: extensions_dir,
            projected_extensions: expected.size,
            updated_extension_files: updated_files,
            removed_extension_entries: removed_entries
          }
        end

        # The destination directory may hold user-authored extensions, so a
        # destination file that exists before the first ACE projection (or one
        # the receipt does not own) is never overwritten: the sync fails with
        # a visible error instead of destroying user files.
        def reject_unowned_collisions(output_dir, expected_relative_paths, owned_paths)
          expected_relative_paths.each do |relative_path|
            next if owned_paths.include?(relative_path)

            candidate = safe_projection_path(output_dir, relative_path)
            next if candidate.nil? || !File.exist?(candidate)

            raise StandardError,
              "refusing to overwrite existing file #{candidate}; it is not claimed by a valid projection receipt " \
              "(missing, symlinked, or corrupt receipts claim nothing). Move or remove the file — or repair or remove " \
              "#{File.join(output_dir, EXTENSION_RECEIPT_NAME)} — then rerun `ace-handbook sync`."
          end
        end

        # Resolve and fully validate a destination before any file is
        # written: every ancestor must be a directory or creatable (no
        # regular files, no symlinks), so a mid-copy failure can never leave
        # a half-installed projection that wedges retries.
        def validate_projection_destination(output_dir, relative_path, extensions_dir)
          segments = relative_path.split(File::SEPARATOR)
          if segments.empty? || segments.any? { |segment| segment.empty? || segment == "." || segment == ".." }
            raise StandardError, "cannot project #{relative_path.inspect}: invalid destination path"
          end

          current = Pathname.new(File.realpath(output_dir))
          segments.each do |segment|
            current = current.join(segment)
            if File.symlink?(current.to_s)
              raise StandardError,
                "cannot project #{relative_path} into #{extensions_dir}: a symlinked path component would escape the projection directory"
            end
            next if segments.last == segment

            if !current.directory? && File.exist?(current.to_s)
              raise StandardError,
                "cannot project #{relative_path} into #{extensions_dir}: #{current} exists and is not a directory"
            end
          end
          if File.directory?(current.to_s)
            # Receipt ownership of a path never authorizes writing through a
            # directory planted at that path — cp would reinterpret the
            # destination as a container and overwrite unowned content.
            raise StandardError,
              "cannot project #{relative_path} into #{extensions_dir}: #{current} exists and is a directory"
          end
          current.to_s
        rescue Errno::ENOENT
          raise StandardError, "cannot project #{relative_path} into #{extensions_dir}: projection directory vanished"
        end

        def extension_source_files(source_dir)
          return {} unless Dir.exist?(source_dir)

          source_root = Pathname.new(source_dir)
          Dir.glob(File.join(source_dir, "**", "*"))
            .select { |path| File.file?(path) }
            .to_h { |path| [Pathname.new(path).relative_path_from(source_root).to_s, path] }
        end

        def prune_stale_extension_files(output_dir, stale_relative_paths, failed_prunes)
          stale = stale_relative_paths
          removed = 0
          stale.each do |relative_path|
            contained = safe_projection_path(output_dir, relative_path)
            next if contained.nil?
            next unless File.file?(contained)

            begin
              FileUtils.rm(contained)
              removed += 1
              remove_empty_parent_dirs(File.dirname(contained), output_dir)
            rescue
              # Keep ownership of the undeletable file: the next sync retries
              # the removal instead of forgetting the file belongs to ACE.
              failed_prunes << relative_path
            end
          end
          removed
        end

        # Receipt files are projected data, so treat them as untrusted, and
        # destination paths are resolved on the real filesystem: only plain
        # relative paths whose every component stays inside output_dir — with
        # no symlinked component, which could point anywhere — may be written
        # or pruned.
        def safe_projection_path(output_dir, relative_path)
          return nil unless relative_path.is_a?(String)
          return nil if relative_path.include?("\0")

          segments = relative_path.split(File::SEPARATOR)
          return nil if segments.empty? || segments.any? { |segment| segment.empty? || segment == "." || segment == ".." }

          current = Pathname.new(File.realpath(output_dir))
          segments.each do |segment|
            current = current.join(segment)
            return nil if File.symlink?(current.to_s)
          end
          current.to_s
        rescue Errno::ENOENT
          nil
        end

        def read_projection_receipt(output_dir, provider)
          receipt_path = File.join(output_dir, EXTENSION_RECEIPT_NAME)
          return nil if File.symlink?(receipt_path)
          return nil unless File.file?(receipt_path)

          receipt = JSON.parse(File.read(receipt_path))
          return nil unless receipt.is_a?(Hash) && receipt["files"].is_a?(Array)
          # A receipt from another projector (or without provenance) claims
          # nothing: only our own source marker authorizes overwrites and
          # pruning.
          return nil unless receipt["source"] == "#{PROJECTION_SOURCE_PREFIX}#{provider}"

          receipt
        rescue JSON::ParserError
          nil
        end

        def write_projection_receipt(output_dir, provider, relative_paths)
          receipt_path = File.join(output_dir, EXTENSION_RECEIPT_NAME)
          # Create the temp file exclusively in the destination directory: a
          # predictable, plainly-opened temp path could follow a planted
          # symlink and truncate a file outside the projection. The rename
          # then replaces any symlink at the receipt path itself.
          temp = Tempfile.create([".ace-handbook-projection", ".tmp"], output_dir)
          begin
            temp.write(JSON.pretty_generate(
              "source" => "#{PROJECTION_SOURCE_PREFIX}#{provider}",
              "files" => relative_paths.sort
            ))
            temp.close
            File.rename(temp.path, receipt_path)
          ensure
            temp.close
            FileUtils.rm_f(temp.path)
          end
        end

        def remove_empty_parent_dirs(dir, stop_dir)
          until dir == stop_dir
            FileUtils.rmdir(dir)
            dir = File.dirname(dir)
          end
        rescue Errno::ENOTEMPTY, Errno::ENOENT
          # Surviving siblings (or a vanished ancestor) stop the ascent; the
          # sync must continue writing remaining assets and the receipt.
          nil
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
        rescue
          ""
        end
      end
    end
  end
end
