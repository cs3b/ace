# frozen_string_literal: true

module Ace
  module Compressor
    module Models
      class ContextPack
        SCHEMA = "ContextPack/3"

        def self.escape(value)
          value.to_s.gsub("|", "\\|").gsub("\n", " ").strip
        end

        def self.header(mode)
          "H|#{SCHEMA}|#{escape(mode)}"
        end

        def self.file_line(source)
          "FILE|#{escape(source)}"
        end

        def self.policy_line(doc_class:, action:)
          "POLICY|class=#{escape(doc_class)}|action=#{escape(action)}"
        end

        def self.fidelity_line(source:, status:, check:, details: nil)
          line = "FIDELITY|source=#{escape(source)}|status=#{escape(status)}|check=#{escape(check)}"
          details_text = details.to_s.strip
          return line if details_text.empty?

          "#{line}|details=#{escape(details_text)}"
        end

        def self.refusal_line(source:, reason:, failed_check:)
          "REFUSAL|source=#{escape(source)}|reason=#{escape(reason)}|failed_check=#{escape(failed_check)}"
        end

        def self.guidance_line(source:, retry_with:)
          "GUIDANCE|source=#{escape(source)}|retry_with=#{escape(retry_with)}"
        end

        def self.fallback_line(*args, **kwargs)
          return legacy_fallback_line(*args) if kwargs.empty?

          source = kwargs.fetch(:source)
          from = kwargs.fetch(:from)
          to = kwargs.fetch(:to)
          reason = kwargs.fetch(:reason)
          check = kwargs[:check]
          details = kwargs[:details]

          line = "FALLBACK|source=#{escape(source)}|from=#{escape(from)}|to=#{escape(to)}|reason=#{escape(reason)}"
          line += "|check=#{escape(check)}" unless check.to_s.strip.empty?
          line += "|details=#{escape(details)}" unless details.to_s.strip.empty?
          line
        end

        def self.section_line(title)
          "SEC|#{escape(title)}"
        end

        def self.summary_line(text)
          "SUMMARY|#{escape(text)}"
        end

        def self.fact_line(text)
          "FACT|#{escape(text)}"
        end

        def self.rule_line(text)
          "RULE|#{escape(text)}"
        end

        def self.constraint_line(text)
          "CONSTRAINT|#{escape(text)}"
        end

        def self.problems_line(items)
          values = Array(items).map { |item| escape(item) }.join(",")
          "PROBLEMS|[#{values}]"
        end

        def self.list_line(list_key, items)
          values = Array(items).map { |item| escape(item) }.join(",")
          key = list_key.to_s.strip
          key = "items" if key.empty?
          "LIST|#{escape(key)}|[#{values}]"
        end

        def self.example_line(tool)
          "EXAMPLE|#{escape("tool=#{tool}")}"
        end

        def self.cmd_line(command)
          "CMD|#{escape(command)}"
        end

        def self.files_line(label, files)
          "FILES|#{escape(label)}|[#{Array(files).map { |value| escape(value) }.join(',')}]"
        end

        def self.tree_line(label, tree)
          "TREE|#{escape(label)}|#{escape(tree)}"
        end

        def self.code_line(language, code)
          language_value = language.to_s.strip.empty? ? "code" : language.to_s.strip
          "CODE|#{escape(language_value)}|#{escape(code)}"
        end

        def self.table_line(rows, table_id: nil, strategy: nil)
          fields = []
          columns, data_rows = normalize_table_rows(rows)
          fields << "id=#{escape(table_id)}" unless table_id.to_s.strip.empty?
          fields << "strategy=#{escape(strategy)}" unless strategy.to_s.strip.empty?
          fields << "cols=#{escape(columns.join(','))}" unless columns.empty?
          fields << "rows=#{escape(encode_table_data_rows(data_rows))}"
          "TABLE|#{fields.join('|')}"
        end

        def self.loss_line(kind:, target:, strategy:, original:, retained:, unit:, source: nil, details: nil)
          unit_key = unit.to_s.strip
          unit_key = "items" if unit_key.empty?
          unit_key = unit_key.gsub(/[^a-z0-9_]/i, "_")

          original_count = original.to_i
          retained_count = retained.to_i
          dropped_count = [original_count - retained_count, 0].max

          line = [
            "LOSS|kind=#{escape(kind)}",
            "target=#{escape(target)}",
            "strategy=#{escape(strategy)}",
            "original_#{unit_key}=#{escape(original_count)}",
            "retained_#{unit_key}=#{escape(retained_count)}",
            "dropped_#{unit_key}=#{escape(dropped_count)}"
          ].join("|")

          line += "|source=#{escape(source)}" unless source.to_s.strip.empty?
          line += "|details=#{escape(details)}" unless details.to_s.strip.empty?
          line
        end

        def self.example_ref_line(tool:, source:, original_source:, reason: "duplicate")
          "EXAMPLE_REF|tool=#{escape(tool)}|source=#{escape(source)}|original_source=#{escape(original_source)}|reason=#{escape(reason)}"
        end

        def self.unresolved_line(kind, raw)
          "U|#{escape(kind)}|#{escape(raw)}"
        end

        # Backward-compatible helpers retained for call-site migration only.
        # Exact-mode now uses context-free output records without source IDs.
        def self.source_line(source_id, source); file_line(source); end

        def self.heading_line(_source_id, _level, title); section_line(title); end

        def self.fact_line_for_source(_source_id, text); fact_line(text); end

        def self.table_line_for_source(_source_id, rows); table_line(rows); end

        def self.unresolved_line_for_source(_source_id, kind, raw); unresolved_line(kind, raw); end

        def self.legacy_fallback_line(_source_id, _kind, raw); "CODE|fallback|#{escape(raw)}"; end

        def self.normalize_table_rows(rows)
          row_values = Array(rows)
          return [[], []] if row_values.empty?

          return [[], []] if row_values.all? { |row| row.to_s.strip.empty? }

          if row_values.length == 1 && !row_values.first.to_s.include?("|")
            return [[], [row_values.first.to_s]]
          end

          header_cells = parse_table_cells(row_values[0])
          data_rows = row_values[1..].to_a.reject { |row| table_separator_row?(row) }.map { |row| parse_table_cells(row) }
          [header_cells, data_rows]
        end

        def self.encode_table_data_rows(rows)
          Array(rows).map { |cells| Array(cells).map { |cell| escape_table_cell(cell) }.join(">") }.join(";")
        end

        def self.escape_table_cell(value)
          value.to_s.gsub("\\", "\\\\").gsub(">", "\\>").gsub(";", "\\;").strip
        end

        def self.parse_table_cells(row)
          row.to_s.split("|").map(&:strip).reject(&:empty?)
        end

        def self.table_separator_row?(row)
          row.to_s.strip.match?(/\A\|?[\-\s:|]+\|?\z/)
        end
      end
    end
  end
end
