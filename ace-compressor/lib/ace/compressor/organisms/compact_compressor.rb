# frozen_string_literal: true

require "pathname"

module Ace
  module Compressor
    module Organisms
      # Orchestrates compact mode by classifying source policy risk, preserving
      # must-keep structure, and emitting explicit fidelity/loss metadata.
      class CompactCompressor
        DENSE_FACT_RE = /\d|(?:must|must not|never|required|should|shall|cannot|can't|do not|only)\b/i
        MIMICRY_RE = /\b(?:exact output|required format|must match|mimic|verbatim|follow exactly)\b/i
        SENSITIVE_TABLE_RE = /\b(?:must|must not|never|required|only|shall|cannot|do not|policy|constraint)\b/i
        TABLE_SEPARATOR_RE = /\A\|?\s*:?-{3,}:?(?:\s*\|\s*:?-{3,}:?)*\|?\z/
        TABLE_ROW_SEPARATOR_ESCAPED_RE = /\s+\\\|\\\|ROW\\\|\\\|\s+/
        EXAMPLE_PAYLOAD_PREFIXES = ["CMD|", "FILES|", "TREE|", "CODE|"].freeze
        PRESERVE_TABLE_MAX_ROWS = 2
        SCHEMA_KEY_ROWS_MAX_ROWS = 6
        SCHEMA_KEY_ROWS_LIMIT = 2
        SUMMARY_ROWS_LIMIT = 1

        attr_reader :ignored_paths, :refused_sources

        def initialize(paths, verbose: false)
          @resolver = ExactCompressor.new(paths, verbose: verbose, mode_label: "compact")
          @parser = Ace::Compressor::Atoms::MarkdownParser.new
          @transformer = Ace::Compressor::Atoms::CanonicalBlockTransformer
          @classifier = Ace::Compressor::Atoms::CompactPolicyClassifier.new
          @refused_sources = []
          @example_registry = {}
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
          @refused_sources = []
          @example_registry = {}
          lines = [Ace::Compressor::Models::ContextPack.header("compact")]

          sources.each do |source|
            source_label = source_label(source)
            lines << Ace::Compressor::Models::ContextPack.file_line(source_label)
            text = File.read(source)
            if text.strip.empty?
              raise Ace::Compressor::Error, "Input file is empty. Compact mode requires content: #{source}"
            end

            blocks = @parser.call(text)
            if blocks.empty?
              raise Ace::Compressor::Error,
                    "Input file is empty after frontmatter removal. Compact mode requires content: #{source}"
            end

            policy = @classifier.call(source: source_label, blocks: blocks)
            action = policy.fetch("action")
            lines << Ace::Compressor::Models::ContextPack.policy_line(
              doc_class: policy.fetch("class"),
              action: action
            )

            transformed = @transformer.new(source).call(blocks)
            case action
            when "refuse_compact"
              lines << Ace::Compressor::Models::ContextPack.fidelity_line(
                source: source_label,
                status: "fail",
                check: "compact_preflight",
                details: "rule-heavy source requires exact mode"
              )
              append_refusal(
                lines,
                source_label: source_label,
                reason: policy.fetch("class"),
                failed_check: "compact_preflight"
              )
            when "compact_with_exact_rule_sections"
              mixed_records = compact_with_exact_rule_sections(transformed, source_label: source_label)
              fidelity = mixed_fidelity(transformed, mixed_records)
              lines << Ace::Compressor::Models::ContextPack.fidelity_line(
                source: source_label,
                status: fidelity.fetch(:status),
                check: "exact_rule_sections",
                details: fidelity.fetch(:details)
              )

              if fidelity.fetch(:status) == "pass"
                lines.concat mixed_records
              else
                append_refusal(
                  lines,
                  source_label: source_label,
                  reason: policy.fetch("class"),
                  failed_check: "exact_rule_sections"
                )
              end
            else
              lines.concat compact_records(transformed, action, source_label: source_label)
            end
          end

          lines.join("\n")
        end

        private

        def compact_records(records, action, source_label:)
          if action == "aggressive_compact"
            aggressive_compact(records, source_label: source_label)
          else
            conservative_compact(records, source_label: source_label)
          end
        end

        def aggressive_compact(records, source_label:)
          current_section = "__root__"
          pending_section = nil
          summary_seen = {}
          fact_seen = {}
          kept = []

          Array(records).each do |line|
            case line
            when /\ASEC\|/
              current_section = line
              pending_section = line
            when /\ASUMMARY\|/
              next if summary_seen[current_section]

              summary_seen[current_section] = true
              flush_pending_section!(kept, pending_section)
              pending_section = nil
              kept << compact_summary_line(line)
            when /\A(?:RULE|CONSTRAINT|PROBLEMS|LIST|EXAMPLE|U|CMD|FILES|TREE|CODE|TABLE)\|/
              flush_pending_section!(kept, pending_section)
              pending_section = nil
              kept << line
            when /\AFACT\|/
              fact_key = current_section
              text = line.sub(/\AFACT\|/, "")
              next if fact_seen[fact_key] && !DENSE_FACT_RE.match?(text)

              fact_seen[fact_key] = true
              flush_pending_section!(kept, pending_section)
              pending_section = nil
              kept << line
            end
          end

          post_process_structured_records(kept, source_label: source_label)
        end

        def compact_with_exact_rule_sections(records, source_label:)
          aggressive_compact(records, source_label: source_label)
        end

        def mixed_fidelity(original_records, compacted_records)
          original_rules = rule_records(original_records)
          compacted_rules = rule_records(compacted_records)
          missing_rules = original_rules.reject { |line| compacted_rules.include?(line) }

          if missing_rules.empty?
            { status: "pass", details: "all_rule_records_preserved" }
          else
            { status: "fail", details: "missing_rule_records=#{missing_rules.size}" }
          end
        end

        def rule_records(records)
          Array(records).select { |line| line.start_with?("RULE|", "CONSTRAINT|") }
        end

        def append_refusal(lines, source_label:, reason:, failed_check:)
          lines << Ace::Compressor::Models::ContextPack.refusal_line(
            source: source_label,
            reason: reason,
            failed_check: failed_check
          )
          lines << Ace::Compressor::Models::ContextPack.guidance_line(
            source: source_label,
            retry_with: "--mode exact"
          )
          @refused_sources << {
            "source" => source_label,
            "reason" => reason,
            "failed_check" => failed_check
          }
        end

        def conservative_compact(records, source_label:)
          seen = {}
          deduped = Array(records).each_with_object([]) do |line, acc|
            next if seen[line]

            seen[line] = true
            acc << line
          end

          post_process_structured_records(deduped, source_label: source_label)
        end

        def post_process_structured_records(records, source_label:)
          table_index = 0
          mimicry_required = false
          collapse_example_payload = false
          Array(records).each_with_object([]) do |line, acc|
            case line
            when /\ASEC\|/
              mimicry_required = false
              collapse_example_payload = false
              acc << line
            when /\A(?:RULE|CONSTRAINT|FACT)\|/
              mimicry_required ||= line.match?(MIMICRY_RE)
              collapse_example_payload = false
              acc << line
            when /\AEXAMPLE\|/
              collapse_example_payload = false
              tool = example_tool(line)
              if tool.empty?
                acc << line
                next
              end

              if mimicry_required
                register_example(tool, source_label)
                acc << line
                next
              end

              seen = @example_registry[tool]
              if seen
                acc << Ace::Compressor::Models::ContextPack.example_ref_line(
                  tool: tool,
                  source: source_label,
                  original_source: seen.fetch("source"),
                  reason: "duplicate_example"
                )
                acc << Ace::Compressor::Models::ContextPack.loss_line(
                  kind: "example",
                  target: tool,
                  strategy: "reference",
                  original: 1,
                  retained: 0,
                  unit: "examples",
                  source: source_label,
                  details: "collapsed_to=#{seen.fetch('source')}"
                )
                collapse_example_payload = true
              else
                register_example(tool, source_label)
                acc << line
              end
            when /\ATABLE\|/
              collapse_example_payload = false
              table_index += 1
              acc.concat compact_table_records(line, source_label: source_label, table_index: table_index)
            else
              if collapse_example_payload && example_payload_line?(line)
                next
              end

              collapse_example_payload = false unless example_payload_line?(line)
              acc << line
            end
          end
        end

        def compact_table_records(line, source_label:, table_index:)
          rows = parse_table_rows(line)
          return [line] if rows.empty?

          header_rows, data_rows = split_table_rows(rows)
          original_data_count = data_rows.size
          table_id = table_record_id(source_label, table_index)
          strategy, retained_data_rows = select_table_strategy(rows, data_rows)
          retained_rows = header_rows + retained_data_rows

          compact_rows = retained_rows.join(" ||ROW|| ")
          records = [
            Ace::Compressor::Models::ContextPack.table_line(
              compact_rows,
              table_id: table_id,
              strategy: strategy
            )
          ]

          if original_data_count > retained_data_rows.size
            records << Ace::Compressor::Models::ContextPack.loss_line(
              kind: "table",
              target: table_id,
              strategy: strategy,
              original: original_data_count,
              retained: retained_data_rows.size,
              unit: "rows",
              source: source_label,
              details: "data_rows_only"
            )
          end

          records
        end

        def select_table_strategy(all_rows, data_rows)
          original_count = data_rows.size
          if original_count <= PRESERVE_TABLE_MAX_ROWS || sensitive_table?(all_rows)
            ["preserve", data_rows]
          elsif original_count <= SCHEMA_KEY_ROWS_MAX_ROWS
            ["schema_plus_key_rows", select_key_rows(data_rows, limit: SCHEMA_KEY_ROWS_LIMIT)]
          else
            ["summarize_with_loss", select_key_rows(data_rows, limit: SUMMARY_ROWS_LIMIT)]
          end
        end

        def split_table_rows(rows)
          separator_index = rows.find_index { |row| row.match?(TABLE_SEPARATOR_RE) }
          if separator_index
            [rows[0..separator_index], rows[(separator_index + 1)..] || []]
          else
            [rows.first ? [rows.first] : [], rows[1..] || []]
          end
        end

        def parse_table_rows(line)
          payload = line.sub(/\ATABLE\|/, "").to_s
          return [] if payload.strip.empty?

          payload.split(TABLE_ROW_SEPARATOR_ESCAPED_RE).map { |row| row.gsub("\\|", "|").strip }
        end

        def select_key_rows(rows, limit:)
          return rows if rows.size <= limit

          selected_indexes = []
          selected_indexes << 0

          dense_index = rows.find_index { |row| row.match?(DENSE_FACT_RE) }
          selected_indexes << dense_index unless dense_index.nil?

          selected_indexes << (rows.size - 1)
          selected_indexes = selected_indexes.uniq

          rows.each_index do |index|
            break if selected_indexes.size >= limit
            next if selected_indexes.include?(index)

            selected_indexes << index
          end

          selected_indexes.sort.take(limit).map { |index| rows[index] }
        end

        def sensitive_table?(rows)
          Array(rows).any? { |row| row.match?(SENSITIVE_TABLE_RE) }
        end

        def table_record_id(source_label, table_index)
          base = File.basename(source_label.to_s, File.extname(source_label.to_s))
                     .downcase
                     .gsub(/[^a-z0-9]+/, "_")
                     .sub(/\A_+/, "")
                     .sub(/_+\z/, "")
          base = "source" if base.empty?
          "#{base}_t#{table_index}"
        end

        def example_payload_line?(line)
          line.start_with?(*EXAMPLE_PAYLOAD_PREFIXES)
        end

        def example_tool(line)
          line[/\AEXAMPLE\|tool=([^|]+)/, 1].to_s.gsub("\\|", "|")
        end

        def register_example(tool, source_label)
          @example_registry[tool] ||= { "source" => source_label }
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

        def flush_pending_section!(lines, pending_section)
          return if pending_section.nil?

          lines << pending_section
        end

        def compact_summary_line(line)
          text = line.sub(/\ASUMMARY\|/, "")
          first_sentence = text.split(/(?<=[.!?])\s+/).first.to_s.strip
          compact_text = first_sentence.empty? ? text : first_sentence
          Ace::Compressor::Models::ContextPack.summary_line(compact_text)
        end
      end
    end
  end
end
