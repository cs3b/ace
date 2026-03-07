# frozen_string_literal: true

module Ace
  module Compressor
    module Atoms
      # Classifies a source into compact-mode policy categories so the caller
      # can choose the safest compression strategy for that document.
      class CompactPolicyClassifier
        # Narrative file-name hints commonly used for explanatory docs.
        NARRATIVE_FILE_HINT_RE = /(?:^|\/)(?:readme|vision|guide|guides|architecture)(?:\.|\/|$)/i
        # Headings that signal descriptive/explanatory prose.
        NARRATIVE_HEADING_RE = /\b(?:overview|vision|introduction|core principles|why|how it works|purpose|motivation|summary|guide)\b/i
        # Headings that indicate normative policy or constraints.
        RULE_HEADING_RE = /\b(?:decision|impact|policy|rule|rules|requirement|requirements|constraint|constraints)\b/i
        # Modal language that usually indicates must-follow rules.
        RULE_TEXT_RE = /\b(?:must|must not|never|required|requires|should|shall|cannot|can't|do not|only)\b/i

        def call(source:, blocks:)
          stats = signal_stats(source, blocks)
          doc_class = classify(stats)
          action = action_for(doc_class)
          {
            "class" => doc_class,
            "action" => action
          }
        end

        private

        def classify(stats)
          return "rule-heavy" if rule_heavy?(stats)
          return "mixed" if mixed?(stats)
          return "narrative-heavy" if narrative_heavy?(stats)

          "unknown"
        end

        def action_for(doc_class)
          case doc_class
          when "narrative-heavy"
            "aggressive_compact"
          when "mixed"
            "compact_with_exact_rule_sections"
          when "rule-heavy"
            "refuse_compact"
          else
            "conservative_compact"
          end
        end

        def signal_stats(source, blocks)
          source_text = source.to_s
          block_list = Array(blocks)
          heading_hits = block_list.count { |block| narrative_heading?(block) }
          text_blocks = block_list.count { |block| block[:type] == :text }
          list_blocks = block_list.count { |block| block[:type] == :list }
          file_hint = source_text.match?(NARRATIVE_FILE_HINT_RE)
          rule_heading_hits = block_list.count { |block| rule_heading?(block) }
          rule_text_hits = block_list.count { |block| rule_text?(block) }
          rule_list_hits = block_list.sum { |block| rule_list_hits(block) }

          {
            heading_hits: heading_hits,
            text_blocks: text_blocks,
            list_blocks: list_blocks,
            file_hint: file_hint,
            rule_heading_hits: rule_heading_hits,
            rule_signal_count: rule_heading_hits + rule_text_hits + rule_list_hits
          }
        end

        def narrative_heavy?(stats)
          heading_hits = stats.fetch(:heading_hits)
          text_blocks = stats.fetch(:text_blocks)
          list_blocks = stats.fetch(:list_blocks)
          file_hint = stats.fetch(:file_hint)

          return true if file_hint && text_blocks >= 2 && text_blocks >= list_blocks
          return true if heading_hits >= 2 && text_blocks >= 2 && text_blocks >= list_blocks

          false
        end

        def mixed?(stats)
          rule_signal_count = stats.fetch(:rule_signal_count)
          return false if rule_signal_count < 2
          return false if rule_heavy?(stats)
          return false if stats.fetch(:file_hint) && stats.fetch(:rule_heading_hits).zero?

          narrative_heavy?(stats) || stats.fetch(:heading_hits) >= 1 || stats.fetch(:text_blocks) >= 2
        end

        def rule_heavy?(stats)
          rule_signal_count = stats.fetch(:rule_signal_count)
          rule_heading_hits = stats.fetch(:rule_heading_hits)
          narrative_signals = stats.fetch(:heading_hits) + (stats.fetch(:file_hint) ? 1 : 0)

          return true if rule_signal_count >= 6 && narrative_signals <= 1
          return true if rule_signal_count >= 5 && rule_heading_hits >= 2

          false
        end

        def narrative_heading?(block)
          return false unless block[:type] == :heading

          NARRATIVE_HEADING_RE.match?(block[:text].to_s)
        end

        def rule_heading?(block)
          return false unless block[:type] == :heading

          RULE_HEADING_RE.match?(block[:text].to_s)
        end

        def rule_text?(block)
          return false unless block[:type] == :text

          RULE_TEXT_RE.match?(block[:text].to_s)
        end

        def rule_list_hits(block)
          return 0 unless block[:type] == :list

          Array(block[:items]).count { |item| RULE_TEXT_RE.match?(item.to_s) }
        end
      end
    end
  end
end
