# frozen_string_literal: true

require "yaml"
require "open3"

module Ace
  module Overseer
    module Molecules
      # Strict parser for the optional `--preservation FILE` manifest.
      #
      # FILE is a claim to verify, never authorization or proof by itself.
      # Schema: `version: 1` plus `candidates:`; each record declares the
      # cross-repository destination that received a candidate's work:
      #
      #   - worktree_path: the candidate worktree the record belongs to
      #   - source_repo / source_base / source_head: the candidate's common
      #     repository and the claimed work range
      #   - destination_repo / destination_base / destination_head /
      #     destination_branch: where the work was transferred
      #
      # Paths must be local absolute repositories and revisions must resolve
      # to exact commits. Duplicate worktree entries, entries pointing at the
      # source checkout itself, and unresolvable revisions fail before any
      # apply action.
      class PreservationManifest
        REQUIRED_FIELDS = %w[
          worktree_path
          source_repo
          source_base
          source_head
          destination_repo
          destination_base
          destination_head
          destination_branch
        ].freeze

        Record = Struct.new(
          :worktree_path, :source_repo, :source_base, :source_head,
          :destination_repo, :destination_base, :destination_head, :destination_branch,
          :resolved_source_base, :resolved_source_head,
          :resolved_destination_base, :resolved_destination_head, :resolved_destination_branch_tip,
          keyword_init: true
        ) do
          def destination_branch_name
            destination_branch.sub(%r{\Arefs/heads/}, "")
          end
        end

        class Invalid < Ace::Overseer::Error; end

        # @param path [String] Manifest file path
        # @param git_runner [Proc] `->(repo, *args) { [stdout, stderr, status] }`
        # @return [PreservationManifest]
        def self.load(path, git_runner: method(:default_git_runner))
          raise Invalid, "Preservation manifest not found: #{path}" unless File.file?(path.to_s)

          data = begin
            YAML.safe_load_file(path, permitted_classes: [Time, Date])
          rescue Psych::SyntaxError, Psych::Exception => e
            raise Invalid, "Preservation manifest is not valid YAML: #{e.message}"
          end
          unless data.is_a?(Hash)
            raise Invalid, "Preservation manifest must be a YAML mapping"
          end

          version = data["version"]
          unless version == 1
            raise Invalid, "Preservation manifest requires `version: 1` (got #{version.inspect})"
          end

          candidates = data["candidates"]
          unless candidates.is_a?(Array)
            raise Invalid, "Preservation manifest requires a `candidates` list"
          end

          new(parse_candidates(candidates, git_runner: git_runner))
        end

        def self.default_git_runner(repo, *args)
          Open3.capture3("git", "-C", repo, *args)
        end
        private_class_method :default_git_runner

        def self.parse_candidates(entries, git_runner:)
          records = entries.map.with_index(1) do |entry, index|
            parse_record(entry, index, git_runner: git_runner)
          end

          duplicate = records.group_by(&:worktree_path).select { |_path, group| group.length > 1 }
          unless duplicate.empty?
            raise Invalid, "Preservation manifest has duplicate entries for #{duplicate.keys.join(", ")}"
          end

          records
        end
        private_class_method :parse_candidates

        def self.parse_record(entry, index, git_runner:)
          unless entry.is_a?(Hash)
            raise Invalid, "Preservation manifest candidate #{index} must be a mapping"
          end

          unknown = entry.keys.map(&:to_s) - REQUIRED_FIELDS
          unless unknown.empty?
            raise Invalid, "Preservation manifest candidate #{index} has unknown fields: #{unknown.join(", ")}"
          end

          missing = REQUIRED_FIELDS.select { |field| entry[field].nil? || entry[field].to_s.strip.empty? }
          unless missing.empty?
            raise Invalid, "Preservation manifest candidate #{index} is missing: #{missing.join(", ")}"
          end

          attrs = REQUIRED_FIELDS.to_h { |field| [field.to_sym, entry[field].to_s] }
          require_absolute_repository(attrs[:worktree_path], "worktree_path", index)
          require_absolute_repository(attrs[:source_repo], "source_repo", index)
          require_absolute_repository(attrs[:destination_repo], "destination_repo", index)
          require_real_repository(attrs[:source_repo], "source_repo", index)
          require_real_repository(attrs[:destination_repo], "destination_repo", "destination")

          if same_path?(attrs[:worktree_path], attrs[:destination_repo])
            raise Invalid,
              "Preservation manifest candidate #{index}: the source checkout #{attrs[:worktree_path]} is " \
              "scheduled for deletion and cannot be its own surviving destination"
          end

          record = Record.new(**attrs)
          record.resolved_source_base = resolve_revision(record.source_repo, record.source_base, "source_base", index, git_runner)
          record.resolved_source_head = resolve_revision(record.source_repo, record.source_head, "source_head", index, git_runner)
          record.resolved_destination_base = resolve_revision(record.destination_repo, record.destination_base, "destination_base", index, git_runner)
          record.resolved_destination_head = resolve_revision(record.destination_repo, record.destination_head, "destination_head", index, git_runner)
          record.resolved_destination_branch_tip = resolve_revision(
            record.destination_repo, record.destination_branch, "destination_branch", index, git_runner
          )
          record
        end
        private_class_method :parse_record

        def self.require_absolute_repository(path, field, index)
          return if path.to_s.start_with?("/")

          raise Invalid, "Preservation manifest candidate #{index}: #{field} must be an absolute path"
        end
        private_class_method :require_absolute_repository

        def self.require_real_repository(path, field, index)
          return if File.directory?(path)

          raise Invalid, "Preservation manifest candidate #{index}: #{field} is not a directory: #{path}"
        end
        private_class_method :require_real_repository

        def self.same_path?(left, right)
          File.realpath(left) == File.realpath(right)
        rescue Errno::ENOENT
          false
        end
        private_class_method :same_path?

        def self.resolve_revision(repo, revision, field, index, git_runner)
          stdout, stderr, status = git_runner.call(repo, "rev-parse", "--verify", "--quiet", "#{revision}^{commit}")
          unless status.success?
            raise Invalid,
              "Preservation manifest candidate #{index}: #{field} `#{revision}` does not resolve to a commit " \
              "in #{repo}: #{stderr.to_s.strip}"
          end

          stdout.to_s.strip
        end
        private_class_method :resolve_revision

        # @param records [Array<Record>] Parsed, resolved records
        def initialize(records)
          @records = records.freeze
        end

        attr_reader :records

        # @return [Record, nil] The record declaring the given worktree
        def for_worktree(worktree_path)
          canonical = canonical_path(worktree_path)
          records.find { |record| canonical_path(record.worktree_path) == canonical }
        end

        # Reject manifest entries that do not belong to any selected
        # candidate. A record for an unselected worktree is an input error.
        #
        # @param selected_paths [Array<String>] Candidate worktree paths
        # @raise [Invalid] When an entry matches no selected worktree
        def ensure_all_match!(selected_paths)
          selected = selected_paths.map { |path| canonical_path(path) }
          unmatched = records.reject { |record| selected.include?(canonical_path(record.worktree_path)) }
          return if unmatched.empty?

          raise Invalid,
            "Preservation manifest entries do not match any selected worktree: " +
            unmatched.map(&:worktree_path).join(", ")
        end

        private

        def canonical_path(path)
          File.realpath(path)
        rescue Errno::ENOENT
          File.expand_path(path)
        end
      end
    end
  end
end
