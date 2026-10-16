# frozen_string_literal: true

module Ace
  module Assign
    module Molecules
      # Closed bounded read dialect shared by isolated protected snapshots and
      # trusted installed journals. Neither boundary can dispatch a Git write.
      module CanonicalReadCommands
        BYTE_LIMIT = 256 * 1_048_576
        OID = /\A[0-9a-f]{40}\z/

        attr_reader :commit

        # EvidenceJournal uses this only as its existing read command boundary.
        def call(argv, stdin_data: "", output_limit: BYTE_LIMIT)
          refuse!("read_outside_snapshot") unless @view && @commit
          unless read_command?(argv, stdin_data)
            refuse!("write_or_unsupported_command")
          end
          result = read_result(argv, stdin_data: stdin_data, limit: [output_limit, BYTE_LIMIT].min)
          [result.stdout.to_s.strip, result.stderr.to_s.strip, result.status]
        end

        def blob_batch(entries, output_limit:)
          refuse!("read_outside_snapshot") unless @view && @commit
          unless entries.is_a?(Array) && entries.all? { |oid| oid.is_a?(String) && oid.match?(OID) }
            refuse!("unsupported_command")
          end
          result = run!(["cat-file", "--batch"], stdin_data: entries.join("\n") + "\n",
            limit: [output_limit, BYTE_LIMIT].min)
          result.stdout.to_s.b
        end

        def history_diff(commits, paths, output_limit:)
          refuse!("read_outside_snapshot") unless @view && @commit
          unless commits.is_a?(Array) && commits.size.between?(1, 64) && commits.uniq.size == commits.size &&
              commits.all? { |commit| commit.is_a?(String) && commit.match?(OID) } &&
              paths.is_a?(Array) && !paths.empty? && paths.uniq.size == paths.size &&
              (paths == ["execution/"] || paths.all? { |path| path.is_a?(String) && path.match?(%r{\Aexecution/[a-zA-Z0-9_.:-]+/events/\z}) }) &&
              output_limit.is_a?(Integer) && output_limit.positive?
            refuse!("unsupported_command")
          end
          result = run!(%w[diff-tree --stdin --always --root -r --raw -z --no-renames --no-ext-diff
            --no-textconv --no-abbrev --] + paths, stdin_data: commits.join("\n") + "\n",
            limit: [output_limit, BYTE_LIMIT].min)
          result.stdout.to_s.b
        end

        def blob_sizes(oids)
          refuse!("read_outside_snapshot") unless @view && @commit
          unless oids.is_a?(Array) && oids.size.between?(1, 64) && oids.all? { |oid| oid.is_a?(String) && oid.match?(OID) }
            refuse!("unsupported_command")
          end
          run!(%w[cat-file --batch-check], stdin_data: oids.join("\n") + "\n", limit: oids.size * 128).stdout.to_s.b
        end

        def blob(path, commit:, max_bytes:)
          refuse!("read_outside_snapshot") unless @view && @commit
          unless commit.is_a?(String) && commit.match?(OID) && max_bytes.is_a?(Integer) && max_bytes.positive?
            refuse!("unsupported_command")
          end
          result = run!(["cat-file", "blob", "#{commit}:#{path}"], limit: [max_bytes, BYTE_LIMIT].min)
          result.stdout.to_s.b
        end

        private

        def read_result(argv, **options)
          run!(argv, **options)
        end

        def read_command?(argv, stdin)
          return false unless argv.is_a?(Array) && argv.all? { |item| item.is_a?(String) && !item.include?("\0") } && stdin.empty?
          allowed = {"rev-parse" => %w[--verify --quiet --git-dir], "cat-file" => %w[-t -s blob],
            "rev-list" => %w[--first-parent --parents], "ls-tree" => %w[-r -l -d --name-only --],
            "show" => [], "log" => %w[--diff-filter=A -1 --format=%H --]}
          flags = allowed[argv.first]
          flags && argv.drop(1).all? { |item| !item.start_with?("-") || flags.include?(item) || item == "--max-count=100001" }
        end

      end
    end
  end
end
