# frozen_string_literal: true

module Ace
  module Compressor
    module Atoms
      class RetentionReporter
        LITERAL_PROTECTED_TYPES = %w[RULE CONSTRAINT CMD U].freeze
        COUNT_PROTECTED_TYPES = %w[CODE TABLE].freeze
        STRUCTURED_TYPES = %w[LIST PROBLEMS FILES TREE EXAMPLE].freeze
        LOSS_MARKER_TYPES = %w[LOSS EXAMPLE_REF REFUSAL FALLBACK].freeze

        def compare(reference_content:, candidate_content:)
          reference = parse(reference_content)
          candidate = parse(candidate_content)

          {
            "sections" => coverage_for_sections(reference, candidate),
            "protected" => coverage_for_protected(reference, candidate),
            "structured" => coverage_for_structured(reference, candidate),
            "loss_markers" => LOSS_MARKER_TYPES.to_h { |type| [type.downcase, candidate.fetch("counts").fetch(type, 0)] }
          }
        end

        private

        def parse(content)
          lines = content.to_s.lines.map(&:strip).reject(&:empty?)
          counts = Hash.new(0)
          literal = Hash.new { |hash, key| hash[key] = Set.new }
          sections = Set.new
          structured_keys = Hash.new { |hash, key| hash[key] = Set.new }

          lines.each do |line|
            type = line.split("|", 2).first
            next if type.to_s.empty?

            counts[type] += 1
            sections << line.delete_prefix("SEC|") if type == "SEC"
            literal[type] << line if LITERAL_PROTECTED_TYPES.include?(type)
            structured_keys[type] << structured_key(type, line) if STRUCTURED_TYPES.include?(type)
          end

          {
            "counts" => counts,
            "sections" => sections,
            "literal" => literal,
            "structured_keys" => structured_keys
          }
        end

        def coverage_for_sections(reference, candidate)
          total = reference.fetch("sections").size
          retained = reference.fetch("sections").intersection(candidate.fetch("sections")).size
          coverage_hash(retained, total)
        end

        def coverage_for_protected(reference, candidate)
          literal_total = 0
          literal_retained = 0

          LITERAL_PROTECTED_TYPES.each do |type|
            ref_lines = reference.fetch("literal").fetch(type, Set.new)
            cand_lines = candidate.fetch("literal").fetch(type, Set.new)
            literal_total += ref_lines.size
            literal_retained += ref_lines.intersection(cand_lines).size
          end

          count_total = COUNT_PROTECTED_TYPES.sum { |type| reference.fetch("counts").fetch(type, 0) }
          count_retained = COUNT_PROTECTED_TYPES.sum do |type|
            [reference.fetch("counts").fetch(type, 0), candidate.fetch("counts").fetch(type, 0)].min
          end

          coverage_hash(literal_retained + count_retained, literal_total + count_total)
        end

        def coverage_for_structured(reference, candidate)
          total = 0
          retained = 0

          STRUCTURED_TYPES.each do |type|
            ref_keys = reference.fetch("structured_keys").fetch(type, Set.new)
            cand_keys = candidate.fetch("structured_keys").fetch(type, Set.new)
            total += ref_keys.size
            retained += ref_keys.intersection(cand_keys).size
          end

          coverage_hash(retained, total)
        end

        def structured_key(type, line)
          case type
          when "LIST", "FILES", "TREE"
            line.split("|", 3)[1].to_s
          when "EXAMPLE"
            line.split("|", 2)[1].to_s
          else
            line
          end
        end

        def coverage_hash(retained, total)
          {
            "retained" => retained,
            "total" => total,
            "percent" => total.zero? ? 100.0 : ((retained.to_f / total.to_f) * 100.0).round(1)
          }
        end
      end
    end
  end
end
