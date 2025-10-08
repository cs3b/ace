# frozen_string_literal: true

require "open3"

module Ace
  module Search
    module Molecules
      # Integrates with fzf for interactive result selection
      # This is a molecule - composed operation using fzf
      class FzfIntegrator
        # Show results in fzf for interactive selection
        # @param results [Array<Hash>] Search results
        # @param options [Hash] fzf options
        # @return [Array<Hash>] Selected results
        def self.select(results, options = {})
          return results unless Atoms::ToolChecker.fzf_available?
          return results if results.empty?

          # Format results for fzf display
          formatted_lines = results.map.with_index do |result, idx|
            format_result_for_fzf(result, idx)
          end

          # Run fzf
          selected_indices = run_fzf(formatted_lines, options)

          # Return selected results
          selected_indices.map { |idx| results[idx] }
        end

        # Format a result for fzf display
        def self.format_result_for_fzf(result, index)
          case result[:type]
          when :file
            "#{index}|FILE|#{result[:path]}"
          when :match
            "#{index}|MATCH|#{result[:path]}:#{result[:line]}|#{result[:text]}"
          else
            "#{index}|#{result[:type]}|#{result[:path]}"
          end
        end

        # Run fzf and get selected indices
        def self.run_fzf(lines, options = {})
          fzf_options = build_fzf_options(options)
          input = lines.join("\n")

          stdout, _stderr, status = Open3.capture3(fzf_options, stdin_data: input)

          return [] unless status.success?

          # Parse selected lines and extract indices
          stdout.lines.map do |line|
            line.split("|").first.to_i
          end
        end

        # Build fzf command with options
        def self.build_fzf_options(options)
          args = ["fzf"]
          args << "--multi" unless options[:single]
          args << "--preview='cat {3}'" if options[:preview]
          args << "--delimiter='|'"
          args << "--with-nth=2.."

          args.join(" ")
        end
      end
    end
  end
end
