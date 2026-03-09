# frozen_string_literal: true

require "pathname"

module Ace
  module Compressor
    module Organisms
      # Orchestrates compact mode with a tiered section ladder. In agent mode the
      # same ladder is used, but eligible narrative sections may be rewritten by
      # AgentCompressor while rule-bearing sections stay deterministic.
      class CompactCompressor
        DENSE_FACT_RE = /\d|(?:must|must not|never|required|should|shall|cannot|can't|do not|only)\b/i
        MIMICRY_RE = /\b(?:exact output|required format|must match|mimic|verbatim|follow exactly)\b/i
        SENSITIVE_TABLE_RE = /\b(?:must|must not|never|required|only|shall|cannot|do not|policy|constraint)\b/i
        TABLE_SEPARATOR_RE = /\A\|?\s*:?-{3,}:?(?:\s*\|\s*:?-{3,}:?)*\|?\z/
        TABLE_ROW_SEPARATOR_ESCAPED_RE = /\s+\\\|\\\|ROW\\\|\\\|\s+/
        EXAMPLE_PAYLOAD_PREFIXES = ["CMD|", "FILES|", "TREE|", "CODE|"] .freeze
        PRESERVE_TABLE_MAX_ROWS = 2
        SCHEMA_KEY_ROWS_MAX_ROWS = 6
        SCHEMA_KEY_ROWS_LIMIT = 2
        SUMMARY_ROWS_LIMIT = 1
        EXACT_SECTION_PREFIXES = ["RULE|", "CONSTRAINT|", "CMD|", "U|"] .freeze

        attr_reader :ignored_paths, :refused_sources

        def initialize(paths, verbose: false, mode_label: "compact", agent_rewriter: nil)
          @paths = Array(paths)
          @mode_label = mode_label
          @resolver = ExactCompressor.new(paths, verbose: verbose, mode_label: mode_label)
          @parser = Ace::Compressor::Atoms::MarkdownParser.new
          @transformer = Ace::Compressor::Atoms::CanonicalBlockTransformer
          @classifier = Ace::Compressor::Atoms::CompactPolicyClassifier.new
          @agent_rewriter = agent_rewriter
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
          lines = [Ace::Compressor::Models::ContextPack.header(@mode_label)]

          Array(sources).each do |source|
            source_label = source_label(source)
            lines << Ace::Compressor::Models::ContextPack.file_line(source_label)
            text = File.read(source)
            raise Ace::Compressor::Error, "Input file is empty. #{@mode_label.capitalize} mode requires content: #{source}" if text.strip.empty?

            blocks = @parser.call(text)
            raise Ace::Compressor::Error, "Input file is empty after frontmatter removal. #{@mode_label.capitalize} mode requires content: #{source}" if blocks.empty?

            policy = @classifier.call(source: source_label, blocks: blocks)
            action = policy.fetch("action")
            lines << Ace::Compressor::Models::ContextPack.policy_line(doc_class: policy.fetch("class"), action: action)
            transformed = @transformer.new(source).call(blocks)

            if @mode_label == "agent"
              lines.concat agent_records(transformed, policy: policy, source_label: source_label)
            else
              lines.concat deterministic_records(transformed, action: action, source_label: source_label, policy_class: policy.fetch("class"))
            end
          end

          lines.join("\n")
        end

        private

        def deterministic_records(transformed, action:, source_label:, policy_class:)
          case action
          when "refuse_compact"
            refusal_for_source(source_label, policy_class, "compact_preflight", "rule-heavy source requires exact mode")
          when "compact_with_exact_rule_sections"
            mixed_records = compact_with_exact_rule_sections(transformed, source_label: source_label)
            fidelity = mixed_fidelity(transformed, mixed_records)
            if fidelity.fetch(:status) == "pass"
              [Ace::Compressor::Models::ContextPack.fidelity_line(source: source_label, status: "pass", check: "exact_rule_sections", details: fidelity.fetch(:details)), *mixed_records]
            else
              refusal_for_source(source_label, policy_class, "exact_rule_sections", fidelity.fetch(:details))
            end
          else
            compact_records(transformed, action, source_label: source_label)
          end
        end

        def agent_records(transformed, policy:, source_label:)
          sections = split_sections(transformed)
          used_agent = false
          result = []

          sections.each do |section_records|
            strategy = section_strategy(section_records, policy_class: policy.fetch("class"))
            deterministic = deterministic_section_records(section_records, strategy: strategy, source_label: source_label)

            if agent_eligible?(strategy) && @agent_rewriter
              rewrite = @agent_rewriter.rewrite_section(section_records, source_label: source_label)
              if rewrite[:ok] && section_improves?(rewrite[:lines], deterministic)
                result.concat(rewrite[:lines])
                used_agent = true
                next
              end
            end

            result.concat(deterministic)
          end

          if used_agent
            [Ace::Compressor::Models::ContextPack.fidelity_line(source: source_label, status: "pass", check: "agent_value", details: "agent_sections_applied"), *result]
          else
            @refused_sources << { "source" => source_label, "reason" => "no_win", "failed_check" => "agent_value" }
            [
              Ace::Compressor::Models::ContextPack.fidelity_line(source: source_label, status: "fail", check: "agent_value", details: "no_agent_section_beat_deterministic"),
              *result,
              Ace::Compressor::Models::ContextPack.refusal_line(source: source_label, reason: "no_win", failed_check: "agent_value"),
              Ace::Compressor::Models::ContextPack.guidance_line(source: source_label, retry_with: "--mode compact")
            ]
          end
        end

        def split_sections(records)
          sections = []
          current = []
          Array(records).each do |line|
            if line.start_with?("SEC|")
              sections << current unless current.empty?
              current = [line]
            else
              current << line unless current.empty?
            end
          end
          sections << current unless current.empty?
          sections
        end

        def section_strategy(section_records, policy_class:)
          payload = Array(section_records).reject { |line| line.start_with?("SEC|") }
          return :exact if payload.any? { |line| line.start_with?(*EXACT_SECTION_PREFIXES) }
          return :hybrid if payload.any? { |line| line.start_with?("TABLE|") }
          return :lossy if %w[narrative-heavy mixed].include?(policy_class)
          return :hybrid if %w[overview architecture reference guide vision].include?(policy_class)

          :deterministic
        end

        def agent_eligible?(strategy)
          %i[lossy hybrid].include?(strategy)
        end

        def deterministic_section_records(section_records, strategy:, source_label:)
          return section_records if strategy == :exact

          action = strategy == :lossy ? "aggressive_compact" : "conservative_compact"
          compact_records(section_records, action, source_label: source_label)
        end

        def section_improves?(candidate_lines, deterministic_lines)
          Array(candidate_lines).join("\n").bytesize < Array(deterministic_lines).join("\n").bytesize
        end

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
          sections = split_sections(records)
          sections.flat_map do |section_records|
            strategy = section_strategy(section_records, policy_class: "mixed")
            deterministic_section_records(section_records, strategy: strategy, source_label: source_label)
          end
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

        def refusal_for_source(source_label, reason, failed_check, details)
          @refused_sources << { "source" => source_label, "reason" => reason, "failed_check" => failed_check }
          [
            Ace::Compressor::Models::ContextPack.fidelity_line(source: source_label, status: "fail", check: failed_check, details: details),
            Ace::Compressor::Models::ContextPack.refusal_line(source: source_label, reason: reason, failed_check: failed_check),
            Ace::Compressor::Models::ContextPack.guidance_line(source: source_label, retry_with: "--mode exact")
          ]
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
                acc << Ace::Compressor::Models::ContextPack.example_ref_line(tool: tool, source: source_label, original_source: seen.fetch("source"), reason: "duplicate_example")
                acc << Ace::Compressor::Models::ContextPack.loss_line(kind: "example", target: tool, strategy: "reference", original: 1, retained: 0, unit: "examples", source: source_label, details: "collapsed_to=#{seen.fetch('source')}")
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
          records = [Ace::Compressor::Models::ContextPack.table_line(retained_rows, table_id: table_id, strategy: strategy)]

          if original_data_count > retained_data_rows.size
            records << Ace::Compressor::Models::ContextPack.loss_line(kind: "table", target: table_id, strategy: strategy, original: original_data_count, retained: retained_data_rows.size, unit: "rows", source: source_label, details: "data_rows_only")
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

          return parse_structured_table_rows(payload) if payload.include?("rows=")

          payload.split(TABLE_ROW_SEPARATOR_ESCAPED_RE).map { |row| row.gsub("\\|", "|").strip }
        end

        def parse_structured_table_rows(payload)
          fields = payload.split("|").each_with_object({}) do |field, hash|
            key, value = field.split("=", 2)
            next if value.nil?

            hash[key] = value
          end

          columns = fields.fetch("cols", "").split(",").map { |cell| cell.gsub("\\|", "|").strip }.reject(&:empty?)
          data_rows = decode_structured_table_rows(fields.fetch("rows", ""))
          rows = []
          rows << "| #{columns.join(' | ')} |" unless columns.empty?
          rows << "|#{Array(columns).map { '---' }.join('|')}|" unless columns.empty?
          rows.concat(data_rows.map { |cells| "| #{cells.join(' | ')} |" })
          rows
        end

        def decode_structured_table_rows(value)
          rows = []
          current_row = []
          current_cell = +""
          escape_next = false

          value.to_s.each_char do |char|
            if escape_next
              current_cell << char
              escape_next = false
            elsif char == "\\"
              escape_next = true
            elsif char == ">"
              current_row << current_cell.strip
              current_cell = +""
            elsif char == ";"
              current_row << current_cell.strip
              rows << current_row
              current_row = []
              current_cell = +""
            else
              current_cell << char
            end
          end

          unless current_cell.empty? && current_row.empty?
            current_row << current_cell.strip
            rows << current_row
          end

          rows
        end

        def select_key_rows(rows, limit:)
          return rows if rows.size <= limit
          selected_indexes = [0]
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
          base = File.basename(source_label.to_s, File.extname(source_label.to_s)).downcase.gsub(/[^a-z0-9]+/, "_").sub(/\A_+/, "").sub(/_+\z/, "")
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
          lines << pending_section unless pending_section.nil?
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
