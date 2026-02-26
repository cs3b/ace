# frozen_string_literal: true

require "json"
require "yaml"

module Ace
  module Taskflow
    module Molecules
      # Default LLM-backed executor for next-phase simulation stages.
      class NextPhaseStageExecutor
        WORKFLOW_PATHS = {
          "draft" => "handbook/workflow-instructions/task/simulate-next-phase-draft.wf.md",
          "plan" => "handbook/workflow-instructions/task/simulate-next-phase-plan.wf.md",
          "work" => "handbook/workflow-instructions/task/work.wf.md"
        }.freeze

        VALID_STATUSES = %w[ok partial failed].freeze

        def initialize(llm_query: nil, file_reader: nil, model_resolver: nil, bundle_loader: nil)
          @llm_query = llm_query || method(:default_llm_query)
          @file_reader = file_reader || method(:default_file_reader)
          @model_resolver = model_resolver || method(:default_model)
          @bundle_loader = bundle_loader || method(:default_bundle_loader)
        end

        def call(resolved_source:, mode:, run_id:, previous_stage_output: nil)
          source_path = resolved_source[:path]
          raise ArgumentError, "Missing source path for stage execution" if source_path.nil? || source_path.strip.empty?

          source_body = @file_reader.call(source_path)
          previous_artifact = build_previous_context(previous_stage_output)

          # Load prompt structure from ace-bundle
          bundle = load_simulation_bundle(mode)

          # System prompt is the "system" section from bundle
          system_prompt = extract_section_content(bundle, "system")

          # User prompt is the "user" section template, interpolated
          user_template = extract_section_content(bundle, "user")
          user_prompt = interpolate_template(user_template,
            source_reference: resolved_source[:input],
            source_type: resolved_source[:type],
            source_content: source_body,
            previous_artifact: previous_artifact
          )

          response = @llm_query.call(
            @model_resolver.call,
            user_prompt,
            system: system_prompt,
            sandbox: { mode: "read-only", intent: "taskflow-next-phase-simulation" },
            temperature: 0.2,
            max_tokens: 6_000
          )

          payload = normalize_payload(response[:text], mode: mode)
          # Include prompts for storage by runner
          payload[:system_prompt] = system_prompt
          payload[:user_prompt] = user_prompt
          payload
        rescue StandardError => e
          raise e.class, "Next-phase stage '#{mode}' execution failed: #{e.message}", e.backtrace
        end

        private

        def load_simulation_bundle(mode)
          preset_name = "simulation-#{mode}"
          @bundle_loader.call(preset_name)
        end

        def extract_section_content(bundle, section_name)
          section = bundle.get_section(section_name)

          if section.nil?
            # Fallback: if no sections, use full bundle content for system
            return bundle.content if section_name == "system" && bundle.content
            return ""
          end

          # Check for inline content first (user section template)
          inline_content = section[:content] || section["content"]
          return inline_content if inline_content && !inline_content.empty?

          # Check for processed files (system section)
          processed_files = section[:_processed_files] || section["_processed_files"]
          if processed_files && !processed_files.empty?
            return format_files_content(processed_files)
          end

          # Fallback to bundle content for system section
          return bundle.content if section_name == "system" && bundle.content

          ""
        end

        def format_files_content(files)
          files.map do |file_info|
            path = file_info[:path] || file_info["path"]
            content = file_info[:content] || file_info["content"]
            <<~FILE
              ### #{path}
              ```
              #{content}
              ```
            FILE
          end.join("\n")
        end

        def interpolate_template(template, variables)
          return "" if template.nil? || template.empty?

          template.gsub(/\{\{(\w+)\}\}/) do
            key = $1.to_sym
            variables.key?(key) ? variables[key].to_s : ""
          end
        end

        def default_bundle_loader(preset_name)
          require "ace/bundle"
          Ace::Bundle.load_preset(preset_name)
        end

        def load_workflow_content(mode, source_type: nil)
          # Check config-defined phases first (allows per-source-type workflow override)
          if source_type
            config_path = workflow_path_from_config(mode, source_type)
            if config_path
              full_path = config_path.start_with?("/") ? config_path : File.join(gem_root, config_path)
              return @file_reader.call(full_path)
            end
          end

          rel_path = WORKFLOW_PATHS[mode]
          raise ArgumentError, "Unsupported simulation mode '#{mode}'" unless rel_path

          @file_reader.call(File.join(gem_root, rel_path))
        end

        def workflow_path_from_config(mode, source_type)
          phases = Ace::Taskflow.configuration.phases_for(source_type)
          return nil unless phases

          phase = phases.find { |p| p["mode"] == mode.to_s }
          return nil unless phase

          workflow_ref = phase["workflow"]
          return nil unless workflow_ref

          resolve_workflow_ref(workflow_ref)
        end

        def resolve_workflow_ref(workflow_ref)
          return workflow_ref unless workflow_ref.start_with?("wfi://")

          # Convert wfi://namespace/name to gem-relative handbook path
          without_scheme = workflow_ref.sub("wfi://", "")
          parts = without_scheme.split("/", 2)
          namespace = parts[0]
          name = parts[1]
          "handbook/workflow-instructions/#{namespace}/#{name}.wf.md"
        end

        def gem_root
          @gem_root ||= begin
            spec_root = ::Gem.loaded_specs["ace-taskflow"]&.gem_dir
            spec_root || File.expand_path("../../../..", __dir__)
          end
        end

        def build_previous_context(previous_stage_output)
          return "null" if previous_stage_output.nil?

          # Pass the artifact as readable text when available (plan stage gets the draft spec)
          artifact = previous_stage_output[:artifact] || previous_stage_output["artifact"]
          return artifact.to_s.strip if artifact && !artifact.to_s.strip.empty?

          JSON.pretty_generate(previous_stage_output)
        end

        def normalize_payload(raw_text, mode:)
          text = raw_text.to_s.strip
          raise ArgumentError, "LLM returned empty response for mode '#{mode}'" if text.empty?

          parsed = parse_payload(text)
          status = parsed["status"].to_s.strip.downcase
          status = "partial" unless VALID_STATUSES.include?(status)

          artifact = parsed["artifact"].to_s.strip
          findings = normalize_list(parsed["findings"])
          questions = normalize_list(parsed["questions"])
          refinements = normalize_list(parsed["refinements"])
          unresolved_gaps = normalize_list(parsed["unresolved_gaps"])

          if artifact.empty? && findings.empty? && questions.empty? && refinements.empty?
            unresolved_gaps << "Model output omitted expected fields."
          end

          payload = {
            status: status,
            findings: findings,
            questions: questions,
            refinements: refinements
          }
          payload[:artifact] = artifact unless artifact.empty?
          payload[:unresolved_gaps] = unresolved_gaps.uniq unless unresolved_gaps.empty?
          payload
        end

        def parse_payload(text)
          candidates = [text]
          fenced = fenced_block(text)
          candidates << fenced if fenced

          candidates.each do |candidate|
            begin
              parsed = JSON.parse(candidate)
              return stringify_keys(parsed) if parsed.is_a?(Hash)
            rescue JSON::ParserError
              nil
            end

            begin
              parsed = YAML.safe_load(candidate, permitted_classes: [Time], aliases: false)
              return stringify_keys(parsed) if parsed.is_a?(Hash)
            rescue Psych::SyntaxError
              nil
            end
          end

          parse_semantic_text(text)
        end

        def parse_semantic_text(text)
          sections = {}
          current = nil

          text.each_line do |line|
            stripped = line.strip
            next if stripped.empty?

            inline_key, inline_value = parse_inline_header(stripped)
            if inline_key
              current = inline_key
              sections[current] ||= []
              sections[current] << inline_value unless inline_value.empty?
              next
            end

            header = extract_header(stripped)
            if header
              current = header
              sections[current] ||= []
              next
            end

            next unless current

            entry = stripped.sub(/\A[-*]\s*/, "").strip
            sections[current] << entry unless entry.empty?
          end

          {
            "status" => sections["status"]&.first || "partial",
            "artifact" => sections["artifact"]&.join("\n") || "",
            "findings" => sections["findings"] || [],
            "questions" => sections["questions"] || [],
            "refinements" => sections["refinements"] || [],
            "unresolved_gaps" => sections["unresolved_gaps"] || []
          }
        end

        def parse_inline_header(line)
          match = line.match(/\A(status|artifact|findings|questions|refinements|unresolved[_ ]gaps)\s*:\s*(.*)\z/i)
          return [nil, nil] unless match

          key = extract_header(match[1])
          value = match[2].to_s.strip.sub(/\A[-*]\s*/, "")
          [key, value]
        end

        def extract_header(line)
          normalized = line.downcase.sub(/:\z/, "")
          return "status" if normalized.start_with?("status")
          return "artifact" if normalized.start_with?("artifact")
          return "findings" if normalized.start_with?("findings")
          return "questions" if normalized.start_with?("questions")
          return "refinements" if normalized.start_with?("refinements")
          return "unresolved_gaps" if normalized.start_with?("unresolved gaps")
          return "unresolved_gaps" if normalized.start_with?("unresolved_gaps")

          nil
        end

        def normalize_list(value)
          Array(value).flatten.map(&:to_s).map(&:strip).reject(&:empty?).uniq
        end

        def stringify_keys(value)
          return {} unless value.is_a?(Hash)

          value.each_with_object({}) do |(key, val), acc|
            normalized = extract_header(key.to_s) || key.to_s.strip.downcase
            acc[normalized] = val
          end
        end

        def fenced_block(text)
          match = text.match(/```(?:json|yaml|yml)?\s*(.*?)```/m)
          match && match[1]&.strip
        end

        def default_llm_query(model, prompt, **kwargs)
          require "ace/llm/query_interface"
          # Workaround for lazy-load issues in ace-llm alias resolution.
          require "ace/llm/molecules/llm_alias_resolver"

          Ace::LLM::QueryInterface.query(model, prompt, **kwargs)
        end

        def default_file_reader(path)
          File.read(path)
        end

        def default_model
          Ace::Taskflow.configuration.next_phase_review_model ||
            Ace::Taskflow.configuration.config.dig("defaults", "llm_model") ||
            "glite"
        end
      end
    end
  end
end
