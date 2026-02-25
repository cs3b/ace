# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Parse `git diff --numstat` output into structured entries.
      module DiffNumstatParser
        class << self
          def parse(numstat_output)
            return [] if numstat_output.nil? || numstat_output.strip.empty?

            numstat_output.split("\n").map { |line| parse_line(line) }.compact
          end

          private

          def parse_line(line)
            return nil if line.nil? || line.strip.empty?

            additions_raw, deletions_raw, raw_path = line.split("\t", 3)
            return nil if raw_path.nil?

            rename_info = parse_rename(raw_path)
            binary = additions_raw == "-" && deletions_raw == "-"

            {
              path: rename_info[:to],
              display_path: rename_info[:display],
              additions: binary ? nil : additions_raw.to_i,
              deletions: binary ? nil : deletions_raw.to_i,
              binary: binary,
              rename_from: rename_info[:from],
              rename_to: rename_info[:to]
            }
          end

          def parse_rename(path)
            if path.include?(" => ")
              from, to = expand_brace_rename(path)
              return {
                from: from,
                to: to,
                display: "#{from} -> #{to}"
              }
            end

            {
              from: nil,
              to: path,
              display: path
            }
          end

          # Handles brace syntax: foo/{old.rb => new.rb}
          def expand_brace_rename(path)
            brace_match = path.match(/\A(.*)\{(.+) => (.+)\}(.*)\z/)
            if brace_match
              prefix = brace_match[1]
              from_inner = brace_match[2]
              to_inner = brace_match[3]
              suffix = brace_match[4]
              return ["#{prefix}#{from_inner}#{suffix}", "#{prefix}#{to_inner}#{suffix}"]
            end

            split = path.split(" => ", 2)
            [split[0], split[1]]
          end
        end
      end
    end
  end
end
