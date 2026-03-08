# frozen_string_literal: true

require "open3"
require "pathname"
require "tempfile"

module Ace
  module Compressor
    module Organisms
      class AgentCompressor
        PROVIDER_UNAVAILABLE_CHECK = "provider_unavailable"
        VALIDATION_CHECK = "agent_validation"
        REQUIRED_PASSTHROUGH_PREFIXES = [
          "RULE|",
          "CONSTRAINT|",
          "U|",
          "CMD|",
          "EXAMPLE|",
          "TABLE|"
        ].freeze
        NUMERIC_FIDELITY_PREFIXES = [
          "RULE|",
          "CONSTRAINT|",
          "FACT|",
          "CMD|",
          "TABLE|",
          "CODE|"
        ].freeze
        STRUCTURED_SIGNAL_PREFIXES = [
          "RULE|",
          "CONSTRAINT|",
          "FACT|",
          "PROBLEMS|",
          "LIST|",
          "EXAMPLE|",
          "EXAMPLE_REF|",
          "CMD|",
          "FILES|",
          "TREE|",
          "CODE|",
          "TABLE|",
          "U|",
          "LOSS|"
        ].freeze
        ALLOWED_RECORD_PREFIXES = [
          "H|",
          "FILE|",
          "POLICY|",
          "FIDELITY|",
          "REFUSAL|",
          "GUIDANCE|",
          "FALLBACK|",
          "SEC|",
          "SUMMARY|",
          "FACT|",
          "RULE|",
          "CONSTRAINT|",
          "PROBLEMS|",
          "LIST|",
          "EXAMPLE|",
          "EXAMPLE_REF|",
          "CMD|",
          "FILES|",
          "TREE|",
          "CODE|",
          "TABLE|",
          "LOSS|",
          "U|"
        ].freeze
        SEMANTIC_PAYLOAD_PREFIXES = [
          "FACT|",
          "RULE|",
          "CONSTRAINT|",
          "PROBLEMS|",
          "LIST|"
        ].freeze
        REQUIRED_RECORD_AUTOFILL_THRESHOLD = 4
        SPIKE_VALIDATED_CONCEPTS = [
          "prompt_composed_flow",
          "structured_input_contract",
          "validator_visible_outcome"
        ].freeze
        SPIKE_DEFERRED_CONCEPTS = [
          "corpus_level_behavior",
          "cross_source_optimization",
          "final_ratio_tuning"
        ].freeze

        attr_reader :ignored_paths

        def initialize(paths, verbose: false, shell_runner: nil)
          @resolver = ExactCompressor.new(paths, verbose: verbose, mode_label: "agent")
          @exact = ExactCompressor.new(paths, verbose: verbose, mode_label: "agent")
          @shell_runner = shell_runner || method(:default_shell_runner)
        end

        def call
          compress_sources(resolve_sources)
        end

        def resolve_sources
          @resolver.resolve_sources
        end

        def ignored_paths
          @resolver.ignored_paths
        end

        def compress_sources(sources)
          baseline = nil
          source_labels = nil
          baseline = @exact.compress_sources(sources)
          source_labels = extract_source_labels(baseline)
          required_lines = required_record_lines(baseline)
          required_numbers = required_numeric_tokens(baseline)
          semantic_seeds = semantic_seed_lines(baseline)
          prompt = compose_prompt(
            baseline,
            required_lines: required_lines,
            required_numbers: required_numbers
          )

          agent_output = invoke_agent(prompt)
          normalized_output = normalize_agent_output(
            agent_output,
            source_labels,
            required_lines: required_lines,
            semantic_seed_lines: semantic_seeds
          )
          validate = validate_agent_output(
            normalized_output,
            baseline,
            source_labels,
            required_lines: required_lines,
            required_numbers: required_numbers
          )
          unless validate[:ok]
            return build_failure_pack(
              baseline: baseline,
              source_labels: source_labels,
              check: VALIDATION_CHECK,
              details: validate[:details],
              reason: "validation_failed"
            )
          end

          build_success_pack(normalized_output)
        rescue Ace::Compressor::Error => e
          raise unless e.message.start_with?("Agent provider unavailable:")

          labels = source_labels || Array(sources).map { |source| source_label(source) }
          fallback_baseline = baseline || @exact.compress_sources(sources)
          build_failure_pack(
            baseline: fallback_baseline,
            source_labels: labels,
            check: PROVIDER_UNAVAILABLE_CHECK,
            details: e.message,
            reason: "provider_unavailable"
          )
        rescue StandardError => e
          labels = source_labels || Array(sources).map { |source| source_label(source) }
          fallback_baseline = baseline || @exact.compress_sources(sources)
          build_failure_pack(
            baseline: fallback_baseline,
            source_labels: labels,
            check: PROVIDER_UNAVAILABLE_CHECK,
            details: e.message,
            reason: "provider_unavailable"
          )
        end

        private

        def compose_prompt(structured_input, required_lines:, required_numbers:)
          prompt_config = Tempfile.new(["ace-compressor-agent-spike", ".yml"])
          input_file = Tempfile.new(["ace-compressor-agent-input", ".pack"])
          begin
            input_file.write(structured_input)
            input_file.flush
            prompt_config.write(
              bundle_config(
                input_file.path,
                required_lines: required_lines,
                required_numbers: required_numbers
              )
            )
            prompt_config.flush

            execute_command(["ace-bundle", prompt_config.path]).strip
          ensure
            prompt_config.close!
            input_file.close!
          end
        end

        def bundle_config(input_path, required_lines:, required_numbers:)
          <<~YAML
            bundle:
              base: #{agent_prompt_template_path}
              sections:
                contract:
                  content: |
                    Output contract:
                    - Return only pipe-delimited ContextPack records.
                    - First line MUST be exactly `H|ContextPack/3|agent`.
                    - Emit `FILE|...` scope lines for every source in the input.
                    - Prefer factual/typed records over broad `SUMMARY|` narrative output.
                    - If table rows or executable examples are reduced, include explicit `LOSS|` and/or `EXAMPLE_REF|` markers.
                required_records:
                  content: |
#{indent_block(required_record_instructions(required_lines), 20)}
                required_numbers:
                  content: |
#{indent_block(required_number_instructions(required_numbers), 20)}
                input:
                  files:
                    - #{input_path}
          YAML
        end

        def invoke_agent(prompt)
          provider = Ace::Compressor.config["agent_provider"].to_s.strip
          provider = "gflash" if provider.empty?
          response = execute_command(["ace-llm", provider, prompt])
          response.strip
        rescue Ace::Compressor::Error => e
          raise Ace::Compressor::Error, "Agent provider unavailable: #{e.message}"
        end

        def validate_agent_output(agent_output, baseline, source_labels, required_lines:, required_numbers:)
          lines = normalize_output_lines(agent_output)
          return { ok: false, details: "missing_header" } unless lines.first == "H|ContextPack/3|agent"

          output_scopes = extract_source_labels_from_lines(lines)
          source_labels.each do |label|
            next if source_scope_present?(label, output_scopes)

            available = output_scopes.empty? ? "none" : output_scopes.join(",")
            return { ok: false, details: "missing_file_scope=#{label};available=#{available}" }
          end

          unknown_records = lines.reject { |line| line.start_with?(*ALLOWED_RECORD_PREFIXES) }
          return { ok: false, details: "unknown_record_prefixes=#{unknown_records.size}" } unless unknown_records.empty?

          missing = required_lines.reject { |line| lines.include?(line) }
          return { ok: false, details: "missing_required_records=#{missing.size}" } unless missing.empty?

          missing_numbers = required_numbers.reject { |token| numeric_token_present?(lines, token) }
          return { ok: false, details: "missing_numeric_tokens=#{missing_numbers.size}" } unless missing_numbers.empty?

          return { ok: false, details: "missing_semantic_payload" } if missing_semantic_payload?(lines, baseline)

          return { ok: false, details: "summary_only_output" } if summary_only_output?(lines)

          return { ok: false, details: "not_smaller_than_exact" } unless lines.join("\n").bytesize < baseline.bytesize

          { ok: true, details: "all_required_records_preserved" }
        end

        def normalize_output_lines(output)
          output.to_s.lines.map(&:strip).reject(&:empty?)
        end

        def normalize_agent_output(agent_output, source_labels, required_lines:, semantic_seed_lines:)
          lines = normalize_output_lines(agent_output)
          return lines.join("\n") if lines.empty?

          if Array(source_labels).size == 1
            expected_scope = source_labels.first
            without_file_scope = lines.reject { |line| line.start_with?("FILE|") }
            if without_file_scope.first&.start_with?("H|")
              lines = [without_file_scope.first, "FILE|#{expected_scope}", *without_file_scope[1..]]
            else
              lines = ["FILE|#{expected_scope}", *without_file_scope]
            end
          end

          lines = canonicalize_nonstandard_records(lines)
          lines = backfill_required_records(lines, required_lines)
          lines = backfill_semantic_seed_lines(lines, semantic_seed_lines)
          lines.join("\n")
        end

        def canonicalize_nonstandard_records(lines)
          Array(lines).map do |line|
            next line if line.start_with?(*ALLOWED_RECORD_PREFIXES)
            next line unless line.include?("|")

            prefix, payload = line.split("|", 2)
            prefix_text = prefix.to_s.downcase.gsub(/[^a-z0-9]+/, "_").sub(/\A_+/, "").sub(/_+\z/, "")
            payload_text = payload.to_s.gsub("|", " ").strip
            fact_text = prefix_text.empty? ? payload_text : "#{prefix_text}=#{payload_text}"
            Ace::Compressor::Models::ContextPack.fact_line(fact_text)
          end
        end

        def backfill_required_records(lines, required_lines)
          required = Array(required_lines).uniq
          return lines if required.size < REQUIRED_RECORD_AUTOFILL_THRESHOLD

          missing = required.reject { |line| lines.include?(line) }
          return lines if missing.empty?

          lines + missing
        end

        def backfill_semantic_seed_lines(lines, semantic_seed_lines)
          seeds = Array(semantic_seed_lines).uniq
          return lines if seeds.empty?

          has_seed = seeds.any? { |line| lines.include?(line) }
          return lines if has_seed

          lines + seeds
        end

        def build_success_pack(agent_output)
          lines = normalize_output_lines(agent_output)
          lines << Ace::Compressor::Models::ContextPack.list_line("validated_concepts", SPIKE_VALIDATED_CONCEPTS)
          lines << Ace::Compressor::Models::ContextPack.list_line("deferred_concepts", SPIKE_DEFERRED_CONCEPTS)
          lines.join("\n")
        end

        def required_record_lines(baseline)
          baseline.to_s.lines.map(&:strip).select do |line|
            line.start_with?(*REQUIRED_PASSTHROUGH_PREFIXES)
          end.uniq
        end

        def required_numeric_tokens(baseline)
          baseline.to_s.lines.map(&:strip).filter_map do |line|
            next unless line.start_with?(*NUMERIC_FIDELITY_PREFIXES)

            line.scan(/\b\d+(?:\.\d+)?\b/)
          end.flatten.uniq
        end

        def semantic_seed_lines(baseline)
          baseline.to_s.lines.map(&:strip).select do |line|
            line.start_with?("FACT|", "LIST|", "PROBLEMS|")
          end.take(3)
        end

        def numeric_token_present?(lines, token)
          pattern = /(?<!\d)#{Regexp.escape(token)}(?!\d)/
          lines.any? { |line| line.match?(pattern) }
        end

        def summary_only_output?(lines)
          payload = lines.reject { |line| line.start_with?("H|", "FILE|") }
          return false if payload.empty?

          structured = payload.any? { |line| line.start_with?(*STRUCTURED_SIGNAL_PREFIXES) }
          return false if structured

          payload.all? { |line| line.start_with?("SEC|", "SUMMARY|") }
        end

        def missing_semantic_payload?(lines, baseline)
          baseline_has_semantic = baseline.to_s.lines.any? do |line|
            line.strip.start_with?(*SEMANTIC_PAYLOAD_PREFIXES)
          end
          return false unless baseline_has_semantic

          !lines.any? { |line| line.start_with?(*SEMANTIC_PAYLOAD_PREFIXES) }
        end

        def required_record_instructions(required_lines)
          return "- No strict pass-through records were detected in the baseline." if required_lines.empty?

          required_lines.map { |line| "- #{line}" }.join("\n")
        end

        def required_number_instructions(required_numbers)
          return "- No numeric-fidelity tokens detected in baseline." if required_numbers.empty?

          required_numbers.map { |token| "- #{token}" }.join("\n")
        end

        def indent_block(text, spaces)
          indent = " " * spaces
          text.to_s.lines.map { |line| "#{indent}#{line}".rstrip }.join("\n")
        end

        def agent_prompt_template_path
          @agent_prompt_template_path ||= begin
            gem_root = ::Gem.loaded_specs["ace-compressor"]&.gem_dir || File.expand_path("../../../../..", __dir__)
            template_path = File.join(gem_root, "handbook", "templates", "agent", "minify-single-source.template.md")
            raise Ace::Compressor::Error, "Agent prompt template not found: #{template_path}" unless File.file?(template_path)

            template_path
          end
        end

        def build_failure_pack(baseline:, source_labels:, check:, details:, reason:)
          lines = normalize_output_lines(baseline)
          Array(source_labels).each do |label|
            lines << Ace::Compressor::Models::ContextPack.fidelity_line(
              source: label,
              status: "fail",
              check: check,
              details: details
            )
            lines << Ace::Compressor::Models::ContextPack.fallback_line(
              source: label,
              from: "agent",
              to: "exact",
              reason: reason,
              check: check,
              details: details
            )
          end
          lines << Ace::Compressor::Models::ContextPack.list_line("validated_concepts", SPIKE_VALIDATED_CONCEPTS)
          lines << Ace::Compressor::Models::ContextPack.list_line("deferred_concepts", SPIKE_DEFERRED_CONCEPTS)
          lines.join("\n")
        end

        def extract_source_labels(content)
          content.to_s.lines.filter_map do |line|
            next unless line.start_with?("FILE|")

            line.sub("FILE|", "").strip
          end
        end

        def extract_source_labels_from_lines(lines)
          Array(lines).filter_map do |line|
            next unless line.start_with?("FILE|")

            line.sub("FILE|", "").strip
          end
        end

        def source_scope_present?(expected_scope, output_scopes)
          return true if output_scopes.include?(expected_scope)

          expected_basename = File.basename(expected_scope.to_s)
          basename_matches = output_scopes.select { |scope| File.basename(scope.to_s) == expected_basename }
          basename_matches.size == 1
        end

        def source_label(source)
          pathname = Pathname.new(source)
          project_root = Pathname.new(Dir.pwd)
          relative = pathname.relative_path_from(project_root).to_s
          return relative unless relative.start_with?("..")

          source
        rescue ArgumentError
          source
        end

        def execute_command(command)
          stdout, stderr, status = @shell_runner.call(command)
          return stdout if status.success?

          details = stderr.to_s.strip
          details = stdout.to_s.strip if details.empty?
          raise Ace::Compressor::Error, "#{command.first} failed: #{details}"
        end

        def default_shell_runner(command)
          Open3.capture3(*command)
        end
      end
    end
  end
end
