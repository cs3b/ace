# frozen_string_literal: true

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          # Provider-agnostic skill/command rewriter.
          # Transforms commands based on a formatter proc.
          #
          # Rules:
          # - Only matches `/name` preceded by start-of-line or whitespace
          # - Skips matches inside backtick code blocks (inline or fenced)
          # - Skips URL-like patterns
          # - Matches longest names first (avoids partial matches)
          class CommandRewriter
            # Rewrite command references in a prompt string.
            #
            # @param prompt [String] The prompt text to rewrite
            # @param skill_names [Array<String>] Known command names
            # @param formatter [Proc] Transformation proc (e.g., ->(name) { "/skill:#{name}" })
            # @return [String] Rewritten prompt
            def self.call(prompt, skill_names:, formatter:)
              return prompt if prompt.nil? || prompt.empty?
              return prompt if skill_names.nil? || skill_names.empty?

              sorted_names = skill_names.sort_by { |n| -n.length }
              name_pattern = sorted_names.map { |n| Regexp.escape(n) }.join("|")
              pattern = /(?<=\A|\s)\/(#{name_pattern})(?=\s|\z)/m

              rewrite_outside_code_blocks(prompt, pattern, formatter)
            end

            def self.rewrite_outside_code_blocks(prompt, pattern, formatter)
              lines = prompt.split("\n", -1)
              in_fenced_block = false
              result = []

              lines.each do |line|
                if line.match?(/\A\s*```/)
                  in_fenced_block = !in_fenced_block
                  result << line
                  next
                end

                if in_fenced_block
                  result << line
                  next
                end

                result << rewrite_line(line, pattern, formatter)
              end

              result.join("\n")
            end

            def self.rewrite_line(line, pattern, formatter)
              segments = line.split(/(`[^`]*`)/)

              segments.each_with_index.map do |segment, i|
                if i.odd?
                  segment
                else
                  segment.gsub(pattern) { formatter.call(Regexp.last_match(1)) }
                end
              end.join
            end

            private_class_method :rewrite_outside_code_blocks, :rewrite_line
          end
        end
      end
    end
  end
end
