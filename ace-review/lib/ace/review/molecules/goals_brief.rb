# frozen_string_literal: true

require "digest"
require "json"
require "ace/compressor"
require "ace/llm"
require_relative "../atoms/prompt_budget"
require_relative "llm_executor"

module Ace
  module Review
    module Molecules
      # One content-addressed summary of the change goal, shared by review scopes.
      # Sources and their authority are supplied by the caller from exact git refs.
      class GoalsBrief
        CONTRACT = "review-goals-v3"
        DEFAULT_MODELS = ["pi:glmflash", "gemini:flash-latest"].freeze
        MAX_BRIEF_TOKENS = 6_000
        SYSTEM_PROMPT = <<~PROMPT
          Summarize project requirements for a code reviewer. Return only JSON with keys:
          objective ({"text":"...","sources":["source-id"],"status":"accepted|proposed"}),
          accepted_requirements (array), constraints (accepted-only array),
          proposed_constraints (array), proposed_changes (array), deferred (array).
          Each array item must be
          {"text":"...","sources":["source-id"]}. Cite only provided source IDs.
          Cite the objective and every item. An accepted objective, requirement,
          or constraint may cite only accepted base sources. Keep PR-head
          constraints and goals explicitly proposed, not accepted authority.
          Preserve explicit constraints and deferred scope. Do not invent decisions.
        PROMPT

        def initialize(project_root:, llm_executor: nil, cache_store: nil, model_resolver: nil, system_prompt: SYSTEM_PROMPT)
          @project_root = project_root
          @llm_executor = llm_executor || LlmExecutor.new
          @cache_store = cache_store || Ace::Compressor::Molecules::CacheStore.new(project_root: project_root)
          @model_resolver = model_resolver || method(:resolve_model)
          @system_prompt = system_prompt
        end

        def prepare(sources:, session_dir:, models: DEFAULT_MODELS, generate: false)
          source_manifest = normalize_sources(sources)
          return failure("Goals brief needs at least one source") if source_manifest.empty?

          last_error = nil
          candidates = Array(models).filter_map do |candidate|
            resolved = @model_resolver.call(candidate)
            if resolved && resolved.split("@").first.match?(/\A[^:]+:\z/)
              last_error = "Goals-brief model selector must name a model: #{candidate}"
              next
            end
            [candidate, resolved] if resolved
          end
          candidates.each do |_candidate, resolved|
            key = cache_key(source_manifest, resolved)
            paths = cache_paths(source_manifest, key)
            cached = read_cache(paths, key)
            return materialize(cached.merge(cache_hit: true), source_manifest, session_dir) if cached
          end

          candidates.each do |candidate, resolved|
            next unless generate

            key = cache_key(source_manifest, resolved)
            paths = cache_paths(source_manifest, key)
            result = generate_brief(source_manifest, candidate, resolved, session_dir)
            unless result[:success]
              last_error = result[:error]
              next
            end

            write_cache(paths, key, result)
            return materialize(result.merge(cache_hit: false), source_manifest, session_dir)
          end

          message = generate ? "No goals-brief model completed" :
            "Goals brief is not cached; run ace-review --pr <number> --preset <preset> --prepare-goals-brief"
          failure(last_error || message)
        end

        private

        def normalize_sources(sources)
          entries = Array(sources).map do |entry|
            path = entry.fetch(:path)
            ref = entry.fetch(:ref)
            authority = entry.fetch(:authority)
            content = File.read(entry.fetch(:snapshot), encoding: "UTF-8")
            raise ArgumentError, "Goals source is not valid UTF-8: #{path}" unless content.valid_encoding?
            raise ArgumentError, "Invalid goals source authority" unless %w[accepted proposed].include?(authority)
            raise ArgumentError, "Invalid goals source ref" unless %w[base head].include?(ref)
            raise ArgumentError, "Accepted goals source must come from base" if authority == "accepted" && ref != "base"
            raise ArgumentError, "Goals source is empty: #{path}" if content.strip.empty?

            {id: "#{ref}:#{path}", path: path, ref: ref, authority: authority, url: entry[:url],
             snapshot: entry.fetch(:snapshot), sha256: Digest::SHA256.hexdigest(content), content: content}
          end.sort_by { |entry| entry[:id] }
          raise ArgumentError, "Duplicate goals source IDs" unless entries.map { |entry| entry[:id] }.uniq.size == entries.size

          entries
        end

        def resolve_model(candidate)
          parsed = Ace::LLM::Molecules::ProviderModelParser.new.parse(candidate.to_s)
          parsed.valid? ? parsed.to_s : nil
        rescue Ace::LLM::Error
          nil
        end

        def cache_key(sources, resolved)
          payload = {contract: CONTRACT, prompt_sha256: Digest::SHA256.hexdigest(@system_prompt),
                     model: resolved, sources: sources.map { |entry| entry.slice(:id, :authority, :sha256) }}
          Digest::SHA256.hexdigest(JSON.generate(payload))
        end

        def cache_paths(sources, key)
          metadata = sources.map { |entry| {content_path: entry[:snapshot], source_path: entry[:id]} }
          @cache_store.canonical_paths(mode: "goals", sources: metadata, manifest_key: key)
        end

        def read_cache(paths, key)
          return nil unless @cache_store.cache_hit?(pack_path: paths[:pack_path], metadata_path: paths[:metadata_path])

          metadata = @cache_store.read_metadata(paths[:metadata_path])
          content = @cache_store.read_pack(paths[:pack_path])
          return nil unless metadata["key"] == key && metadata["sha256"] == Digest::SHA256.hexdigest(content)
          return nil if content.strip.empty?

          {success: true, content: content, metadata: metadata, path: paths[:pack_path]}
        rescue JSON::ParserError, Errno::ENOENT
          nil
        end

        def materialize(result, sources, session_dir)
          links = sources.filter_map do |entry|
            "- [#{entry[:id]}](#{entry[:url]})" if entry[:url]
          end
          content = result.fetch(:content)
          content += "\n## Current source links\n#{links.join("\n")}\n" if links.any?
          path = File.join(session_dir, "goals-brief.md")
          File.write(path, content)
          result.merge(path: path, content: content,
            metadata: result.fetch(:metadata).merge("sources" => sources.map { |entry| entry.slice(:id, :authority, :sha256, :url) }))
        end

        def generate_brief(sources, candidate, resolved, session_dir)
          prompt = JSON.pretty_generate(sources.map { |entry| entry.slice(:id, :authority, :content) })
          budget = Atoms::PromptBudget.check(system_prompt: @system_prompt, user_prompt: prompt, models: [candidate])
          return failure("Goals sources exceed input budget: #{budget[:errors].join("; ")}") unless budget[:success]

          result = @llm_executor.execute(system_prompt: @system_prompt, user_prompt: prompt,
            model: candidate, session_dir: session_dir,
            output_file: File.join(session_dir, "goals-brief.raw.json"))
          return failure(result[:error] || "Goals-brief generation failed") unless result[:success]

          execution = result[:execution]
          return failure("Goals-brief model identity is missing") unless execution.is_a?(Hash)
          actual = "#{execution[:provider]}:#{execution[:model]}"
          resolved_identity = resolved.split("@").first.sub(/:(?:low|medium|high|xhigh|max)\z/, "")
          return failure("Goals-brief model changed during execution") unless actual == resolved_identity

          data = JSON.parse(result[:response])
          content = render(data, sources)
          if Atoms::TokenEstimator.estimate(content) > MAX_BRIEF_TOKENS
            return failure("Goals brief exceeds #{MAX_BRIEF_TOKENS} tokens")
          end

          {success: true, content: content, metadata: {"resolved_model" => resolved,
                                                       "execution" => execution, "sources" => sources.map { |entry| entry.slice(:id, :authority, :sha256, :url) }}}
        rescue JSON::ParserError, ArgumentError, KeyError => e
          failure("Goals brief is invalid: #{e.message}")
        end

        def render(data, sources)
          raise ArgumentError, "Goals brief must be an object" unless data.is_a?(Hash)
          ids = sources.map { |entry| entry[:id] }
          objective = data.fetch("objective")
          raise ArgumentError, "Goals objective must be a cited object" unless objective.is_a?(Hash)
          objective_status = objective.fetch("status")
          raise ArgumentError, "Invalid goals objective status" unless %w[accepted proposed].include?(objective_status)
          validate_item!(objective, ids, sources, accepted_only: objective_status == "accepted")
          if objective_status == "proposed" && objective.fetch("sources").none? { |ref| source_authority(sources, ref) == "proposed" }
            raise ArgumentError, "Proposed objective needs a proposed source"
          end

          lines = ["# Shared change goal (#{objective_status})", "", "#{objective.fetch("text").strip} (#{objective.fetch("sources").join(", ")})"]
          {"accepted_requirements" => "Accepted requirements", "constraints" => "Accepted constraints",
           "proposed_constraints" => "Proposed constraints (not accepted authority)",
           "proposed_changes" => "Proposed changes (not accepted authority)",
           "deferred" => "Deferred scope"}.each do |key, title|
            items = data.fetch(key)
            raise ArgumentError, "#{key} must be an array" unless items.is_a?(Array)

            lines += ["", "## #{title}"]
            items.each do |item|
              validate_item!(item, ids, sources, accepted_only: %w[accepted_requirements constraints].include?(key))
              lines << "- #{item.fetch("text").strip} (#{item.fetch("sources").join(", ")})"
            end
          end
          lines += ["", "## Sources"]
          sources.each do |entry|
            lines << "- #{entry[:id]} [#{entry[:authority]}] SHA-256 #{entry[:sha256]}"
          end
          lines.join("\n") + "\n"
        end

        def validate_item!(item, ids, sources, accepted_only:)
          refs = item.fetch("sources")
          text = item.fetch("text")
          unless text.is_a?(String) && !text.strip.empty? && refs.is_a?(Array) &&
              refs.any? && refs.all? { |ref| ids.include?(ref) }
            raise ArgumentError, "Goals brief contains an uncited or invalid item"
          end
          if accepted_only && refs.any? { |ref| source_authority(sources, ref) != "accepted" }
            raise ArgumentError, "A proposed source was promoted to accepted authority"
          end
        end

        def source_authority(sources, ref)
          sources.find { |source| source[:id] == ref }[:authority]
        end

        def write_cache(paths, key, result)
          content = result.fetch(:content)
          metadata = result.fetch(:metadata).merge("key" => key,
            "sha256" => Digest::SHA256.hexdigest(content))
          @cache_store.write_cache(pack_path: paths[:pack_path], metadata_path: paths[:metadata_path],
            content: content, metadata: metadata)
        end

        def failure(message)
          {success: false, error: message}
        end
      end
    end
  end
end
