# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module AttachOutputPrinter
        module_function

        def print(result, out: $stdout)
          if result[:dry_run]
            out.puts("[dry-run] Would upload: #{result[:asset_name]}")
            out.puts("[dry-run] Would post comment to PR ##{result[:pr]}:")
            out.puts(result[:comment_body])
          else
            out.puts("Uploaded: #{result[:asset_name]} -> #{result[:asset_url]}")
            out.puts("Posted demo comment to PR ##{result[:pr]}")
          end
        end
      end
    end
  end
end
