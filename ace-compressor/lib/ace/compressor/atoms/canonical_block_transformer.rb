# frozen_string_literal: true

module Ace
  module Compressor
    module Atoms
      class CanonicalBlockTransformer
        RULE_RE = /\b(?:must|must not|never|required|required to|should|shall|shall not|cannot|can't|do not)\b/i
        CONSTRAINT_RE = /\b(?:constraint|no more than|at most|must not|never|cannot)\b/i
        RULE_SECTION_RE = /(rules?|guidelines?|policy|requirements?|constraints?|musts?)/i
        SUMMARY_SECTION_RE = /(overview|summary|vision|purpose|goal|why|motivation|introduction|intro)/i
        EXAMPLE_HEADING_RE = /\Aexample\s*:\s*(.+)\z/i
        PROBLEM_SECTION_RE = /(problems?|issues?|risks?|pitfalls?|drawbacks?)/i
        PROBLEM_CONTEXT_RE = /\b(?:suffer from|struggle with|problems?|issues?|risks?|pitfalls?|drawbacks?|pain points?)\b/i
        TREE_LINE_RE = /[│├└╰]--/
        FILE_PATH_RE = /\A(?:\.{1,2}\/)?[A-Za-z0-9._-]+(?:\/[A-Za-z0-9._-]+)*\z/
        SHELL_LANGS = %w[bash sh shell zsh fish cmd powershell ps1].freeze
        SHELL_CONTROL_RE = /\A(?:#|if\b|then\b|else\b|elif\b|fi\b|for\b|while\b|until\b|do\b|done\b|case\b|esac\b|function\b|\{|\})/
        CONTEXTPACK_PREFIXES = %w[
          H FILE POLICY FIDELITY REFUSAL GUIDANCE FALLBACK SEC SUMMARY FACT RULE CONSTRAINT
          PROBLEMS LIST EXAMPLE CMD FILES TREE CODE TABLE LOSS EXAMPLE_REF U
        ].freeze
        LIST_NARRATIVE_MIN_CHARS = 48
        LIST_NARRATIVE_MIN_WORDS = 6
        LIST_STOPWORDS = %w[a an and as at by for from in into is of on or that the this to via with within].freeze
        LIST_TOKEN_MAP = {
          "architecture" => "arch",
          "architectural" => "arch",
          "configuration" => "config",
          "documentation" => "docs",
          "generation" => "gen",
          "management" => "mgmt",
          "repository" => "repo",
          "repositories" => "repos",
          "development" => "dev",
          "integration" => "integr",
          "execution" => "exec",
          "reporting" => "reports",
          "organization" => "org",
          "organizations" => "orgs",
          "capabilities" => "caps",
          "capability" => "cap",
          "foundation" => "base",
          "tracking" => "track",
          "powered" => "pwr",
          "detected" => "detect",
          "matching" => "match"
        }.freeze

        def initialize(source)
          @source = source
          @current_section = nil
          @example_tool = nil
          @last_text = nil
        end

        def call(blocks)
          lines = []

          Array(blocks).each do |block|
            next unless block.is_a?(Hash) && block[:type]

            case block[:type]
            when :heading
              lines << section_line(block)
            when :text
              lines << text_record(block[:text])
            when :list
              lines.concat list_lines(block)
            when :fenced_code
              lines.concat fenced_code_lines(block)
            when :table
              table = table_line(block)
              lines << table if table
            when :unresolved
              lines << unresolved_line(block)
            end
          end

          lines.compact
        end

        private

        def section_line(block)
          heading = normalize_heading_text(normalize_inline(block[:text].to_s))
          return nil if heading.empty?

          match = heading.match(EXAMPLE_HEADING_RE)
          if match
            tool = heading_tool_slug(match[1].to_s)
            @example_tool = tool
            @last_text = nil
            "EXAMPLE|tool=#{tool}"
          else
            @example_tool = nil
            @current_section = heading_slug(heading)
            @last_text = nil
            Ace::Compressor::Models::ContextPack.section_line(@current_section)
          end
        end

        def text_record(raw_text)
          text = normalize_inline(raw_text.to_s)
          return nil if text.empty?

          example_match = text.match(EXAMPLE_HEADING_RE)
          if example_match
            @example_tool = heading_tool_slug(example_match[1].to_s)
            @last_text = text
            return Ace::Compressor::Models::ContextPack.example_line(@example_tool)
          end

          kind =
            if text_summary?
              :summary
            elsif RULE_RE.match?(text)
              :rule
            elsif CONSTRAINT_RE.match?(text)
              :constraint
            elsif RULE_SECTION_RE.match?(@current_section.to_s)
              :rule
            else
              :fact
            end

          @last_text = text

          case kind
          when :summary
            Ace::Compressor::Models::ContextPack.summary_line(text)
          when :constraint
            Ace::Compressor::Models::ContextPack.constraint_line(text)
          when :rule
            Ace::Compressor::Models::ContextPack.rule_line(text)
          else
            Ace::Compressor::Models::ContextPack.fact_line(text)
          end
        end

        def list_lines(block)
          items = Array(block[:items]).map { |item| list_item_slug(item.to_s) }.reject(&:empty?)
          return [] if items.empty?

          if problem_list_context?
            [Ace::Compressor::Models::ContextPack.problems_line(items)]
          else
            list_key = @current_section.to_s.empty? ? "items" : @current_section
            [Ace::Compressor::Models::ContextPack.list_line(list_key, items)]
          end
        end

        def fenced_code_lines(block)
          code_lines = Array(block[:content].to_s.lines).map(&:strip).reject(&:empty?)
          return [] if code_lines.empty?

          nested_lines = nested_contextpack_lines(code_lines)
          return nested_lines if nested_lines

          language = block[:language].to_s.strip.downcase
          if file_list_block?(code_lines)
            [Ace::Compressor::Models::ContextPack.files_line(file_label, code_lines)]
          elsif tree_block?(code_lines)
            [Ace::Compressor::Models::ContextPack.tree_line(tree_label, code_lines.join(" "))]
          elsif shell_script_block?(language, code_lines)
            [Ace::Compressor::Models::ContextPack.code_line(language.empty? ? "bash" : language, code_lines.join(" "))]
          elsif shell_command_block?(language, code_lines)
            code_lines.map { |line| Ace::Compressor::Models::ContextPack.cmd_line(line) }
          else
            [Ace::Compressor::Models::ContextPack.code_line(language.empty? ? "code" : language, code_lines.join(" "))]
          end
        end

        def table_line(block)
          rows = Array(block[:rows])
          return nil if rows.empty?

          Ace::Compressor::Models::ContextPack.table_line(rows)
        end

        def unresolved_line(block)
          kind = block[:kind].to_s
          raw = block[:text].to_s
          Ace::Compressor::Models::ContextPack.unresolved_line(kind, raw)
        end

        def text_summary?
          return false if @current_section.to_s.empty?

          SUMMARY_SECTION_RE.match?(@current_section.to_s)
        end

        def shell_command_block?(language, lines)
          return false if shell_script_block?(language, lines)
          return true if SHELL_LANGS.include?(language)
          return false unless language.empty?

          lines.all? { |line| line.match?(/\A[a-zA-Z0-9_.\/-]+(?:\s+.+)?\z/) }
        end

        def shell_script_block?(language, lines)
          return false if lines.empty?

          shell_language = SHELL_LANGS.include?(language)
          inferred_shell = language.empty? && lines.all? { |line| shellish_line?(line) }
          return false unless shell_language || inferred_shell

          lines.size > 3 || lines.any? { |line| shell_script_line?(line) }
        end

        def tree_block?(lines)
          lines.any? { |line| TREE_LINE_RE.match?(line) || line.match?(/\A[|` ]*[├└]──/) }
        end

        def file_list_block?(lines)
          return false if lines.empty?

          lines.all? { |line| FILE_PATH_RE.match?(line) }
        end

        def nested_contextpack_lines(lines)
          payload = Array(lines).reject { |line| contextpack_header_line?(line) }
          return nil if payload.empty?
          return nil unless payload.all? { |line| contextpack_line?(line) }

          payload
        end

        def contextpack_line?(line)
          prefix = line.to_s.split("|", 2).first
          CONTEXTPACK_PREFIXES.include?(prefix)
        end

        def contextpack_header_line?(line)
          line.to_s.start_with?("H|ContextPack/")
        end

        def tree_label
          return @example_tool unless @example_tool.to_s.empty?
          return @current_section unless @current_section.to_s.empty?

          File.basename(@source).sub(/\.[^.]+\z/, "")
        end

        def file_label
          return @example_tool unless @example_tool.to_s.empty?
          return @current_section unless @current_section.to_s.empty?

          "files"
        end

        def section_contains_problems?(section)
          PROBLEM_SECTION_RE.match?(section.to_s.tr("_", " "))
        end

        def problem_list_context?
          section_contains_problems?(@current_section) || PROBLEM_CONTEXT_RE.match?(@last_text.to_s)
        end

        def heading_slug(text)
          normalize_heading_text(text)
            .downcase
            .gsub(/["']/, "")
            .gsub(/\P{Alnum}+/, "_").squeeze("_")
            .sub(/\A_+/, "")
            .sub(/_+\z/, "")
            .then { |value| value.empty? ? "section" : value }
        end

        def heading_tool_slug(text)
          normalize_heading_text(text)
            .downcase
            .gsub(/["']/, "")
            .gsub(/\P{Alnum}+/, "-").squeeze("-")
            .sub(/\A-+/, "")
            .sub(/-+\z/, "")
            .then { |value| value.empty? ? "tool" : value }
        end

        def list_item_slug(text)
          return heading_slug(text) unless narrative_list_item?(text)

          compact_phrase_slug(text)
        end

        def narrative_list_item?(text)
          raw = normalize_inline(text.to_s)
          raw.length > LIST_NARRATIVE_MIN_CHARS || raw.split(/\s+/).length >= LIST_NARRATIVE_MIN_WORDS
        end

        def compact_phrase_slug(text)
          tokens = normalize_heading_text(normalize_inline(text.to_s))
            .downcase
            .gsub(/["']/, "")
            .scan(/[a-z0-9]+/)
            .filter_map do |token|
              next if LIST_STOPWORDS.include?(token)

              LIST_TOKEN_MAP.fetch(token, token)
            end

          tokens = tokens.each_with_object([]) do |token, result|
            result << token unless result.last == token
          end

          value = tokens.join("_")
          value.empty? ? heading_slug(text) : value
        end

        def shellish_line?(line)
          line.match?(/\A[a-zA-Z0-9_.\/\-$"'`#\[\]()=:;]+(?:\s+.+)?\z/)
        end

        def shell_script_line?(line)
          line.match?(SHELL_CONTROL_RE)
        end

        def normalize_heading_text(text)
          text
            .to_s
            .strip
            .sub(/\A[#\s]+/, "")
            .sub(/\A\d+(?:[.)])?\s*/, "")
            .gsub(/^\p{Extended_Pictographic}+\s*/, "")
        end

        def normalize_inline(text)
          without_links = text.gsub(/\[([^\]]+)\]\([^)]+\)/, "\\1")
          without_emoji = without_links.gsub(emoji_re, "")
          without_bold = without_emoji.gsub(/\*{1,3}([^*]+)\*{1,3}/, "\\1")
          without_backticks = without_bold.gsub(/`([^`]+)`/, "\\1")
          without_blockquote = without_backticks.gsub(/^(?:\s*>+\s*)+/, "")
          without_blockquote.gsub(/\s+/, " ").strip
        end

        def emoji_re
          /[\u{1F300}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]+/u
        end
      end
    end
  end
end
