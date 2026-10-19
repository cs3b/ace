# frozen_string_literal: true

require_relative "../errors"
require_relative "grant_resolver"
require "yaml"
require "date"
require "fileutils"

module Ace
  module Lab
    module Molecules
      # Writes the trusted-tier principal grants (task 8xg.t.sbz.7.2,
      # L8.3): the `principals` section of the deployment-owned
      # authorization document at the fixed AUTHORIZATION_PATH — the only
      # place GrantResolver reads grants from, so `ace-lab projects` /
      # `ace-overseer projects` see the installed projects with no
      # read-side change.
      #
      # The installer owns this configuration, but never overwrites a
      # foreign lab: a document whose principals grant projects outside
      # the manifest's declared set is foreign (`foreign_grants?`, used
      # by the installer as a before-any-mutation guard), and a manifest
      # that would REMOVE an existing grant is refused — grants only
      # grow. All other sections of the document are preserved
      # untouched. Writes are atomic (temp file + rename) with mode
      # 0644, mirroring the registry's write discipline.
      class GrantProvisioner
        STATUS_DRY = {"created" => "would_create", "updated" => "would_update"}.freeze

        # @param resolver [Object] trusted-read seam (defaults to
        #   GrantResolver; injected in tests)
        # @param authorization_path [String] trusted grants location
        def initialize(resolver: GrantResolver, authorization_path: Ace::Lab.authorization_path)
          @resolver = resolver
          @authorization_path = authorization_path
        end

        # Foreign-lab detection: an existing trusted document that grants
        # projects outside the manifest's declared set belongs to a
        # different lab and must never be overwritten by this install.
        #
        # @param declared_projects [Array<String>] project ids declared
        #   by the install manifest
        # @return [String, nil] conflict message, nil when compatible
        # @raise [Ace::Lab::InvalidConfigurationError] the trusted
        #   document exists but fails verification or parsing — a lab
        #   the installer cannot reason about is treated as foreign
        def foreign_grants?(declared_projects)
          document = read_document
          return nil if document.nil?

          (document["principals"] || {}).each do |principal, policy|
            foreign = granted_projects(policy) - declared_projects
            next if foreign.empty?

            return "trusted authorization file #{@authorization_path} already grants " \
              "project(s) #{foreign.sort.join(', ')} to principal '#{principal}' — this lab's " \
              "manifest does not declare them; refusing to overwrite a foreign lab"
          end
          nil
        end

        # Idempotently converge the principal grants.
        #
        # @param desired [Hash] principal => project ids (normalized
        #   manifest grants)
        # @param declared_projects [Array<String>] manifest project ids
        # @param dry_run [Boolean]
        # @return [Hash] {path:, status:, principals:, message:} where
        #   status is created / updated / exists / would_create /
        #   would_update / failed and principals carries one entry per
        #   desired principal
        def call(desired:, declared_projects:, dry_run: false)
          document = begin
            read_document
          rescue Ace::Lab::InvalidConfigurationError => e
            return failure(e.message)
          end
          existing = document ? (document["principals"] || {}) : {}

          removal = desired.filter_map do |principal, projects|
            granted = existing.key?(principal) ? granted_projects(existing[principal]) : []
            next if (granted - projects).empty?

            "principal '#{principal}' is already granted project(s) " \
              "#{(granted - projects).sort.join(', ')} which this manifest does not grant; " \
              "refusing to remove trusted grants — edit #{@authorization_path} manually"
          end
          return failure(removal.join("; ")) unless removal.empty?

          merged, statuses = merge_principals(existing, desired)

          # An empty grants manifest over an absent document is a no-op
          # (review r1): nothing is granted, so no empty authorization
          # document is created.
          if document.nil? && merged.empty?
            return report("skipped", {}, "no grants declared and no trusted document present; " \
              "nothing to write", existing, desired)
          end

          aggregate = if statuses.values.include?("created") && existing.empty?
            "created"
          elsif statuses.values.any? { |status| %w[created updated].include?(status) }
            "updated"
          else
            "exists"
          end

          # Dry-run parity: per-principal predictions mirror the wet
          # statuses (an already-converged principal stays `exists`).
          statuses = statuses.transform_values { |status| STATUS_DRY.fetch(status, status) } if dry_run

          return report(STATUS_DRY.fetch(aggregate, aggregate), statuses, nil, existing,
            desired) if dry_run

          # Converged: the merged principals deep-equal the parsed
          # existing mapping, so the write is skipped — the trusted
          # document (admin-authored comments included) stays
          # byte-identical instead of being round-tripped through YAML
          # (review r1). An absent document is always created.
          if document && merged == existing
            return report(aggregate, statuses, nil, existing, desired)
          end

          write_failure = persist(document, merged)
          return write_failure if write_failure

          report(aggregate, statuses, nil, existing, desired)
        rescue Ace::Lab::InvalidConfigurationError => e
          failure(e.message)
        end

        private

        # Per-principal convergence: a principal with no grants yet is
        # `created`, one gaining projects is `updated`, an already
        # fully-granted one is `exists`. Principals absent from the
        # manifest are carried over unchanged (never removed).
        def merge_principals(existing, desired)
          merged = existing.each_with_object({}) do |(principal, policy), acc|
            acc[principal] = {"projects" => granted_projects(policy)}
          end
          statuses = desired.each_with_object({}) do |(principal, projects), acc|
            granted = merged.key?(principal) ? merged[principal]["projects"] : []
            acc[principal] = if granted.empty?
              "created"
            elsif (projects - granted).empty?
              "exists"
            else
              "updated"
            end
            merged[principal] = {"projects" => (granted | projects).sort}
          end
          [merged, statuses]
        end

        # Atomic write preserving every other section of the document.
        # Returns nil on success, a failed report otherwise.
        def persist(document, merged)
          updated = document ? deep_copy(document) : {}
          updated["principals"] = merged

          dir = File.dirname(@authorization_path)
          tmp = File.join(dir, ".authorization.yml.tmp.#{Process.pid}")
          begin
            FileUtils.mkdir_p(dir)
            File.write(tmp, YAML.dump(updated))
            File.chmod(0o644, tmp)
            File.rename(tmp, @authorization_path)
          rescue SystemCallError, IOError => e
            File.delete(tmp) if File.exist?(tmp)
            return failure("writing #{@authorization_path} failed: #{e.message}")
          end
          nil
        end

        def report(status, statuses, message, existing, desired)
          {
            "path" => @authorization_path,
            "status" => status,
            "principals" => statuses,
            "message" => message,
            # Always present (empty when nothing is carried over) so
            # JSON consumers see a stable schema (review r1).
            "kept" => existing.keys - desired.keys
          }
        end

        def failure(message)
          # `kept` is present (empty) like in every report so JSON
          # consumers see one stable schema — a failure merges
          # nothing, so nothing is carried over (resume/verification
          # readers, tasks 8xg.t.sbz.7.3/.7.4).
          {"path" => @authorization_path, "status" => "failed", "principals" => {},
            "message" => message, "kept" => []}
        end

        # Read and parse the trusted document through the same
        # fail-closed verification every grant reader uses.
        # @return [Hash, nil] parsed document, nil when absent
        # @raise [Ace::Lab::InvalidConfigurationError]
        def read_document
          content = @resolver.read_verified(@authorization_path)
          return nil if content.nil?

          document = begin
            YAML.safe_load(content, permitted_classes: [Date], aliases: true)
          rescue Psych::Exception
            raise Ace::Lab::InvalidConfigurationError,
              "#{@authorization_path} could not be parsed as YAML; refusing to overwrite"
          end
          unless document.is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError,
              "#{@authorization_path} must contain a YAML mapping; refusing to overwrite"
          end
          principals = document["principals"]
          return document if principals.nil?

          # Per-principal validation identical to the read side
          # (GrantResolver.parse_grants): a malformed policy is refused
          # with the classified error instead of silently rewritten,
          # and principal names are stripped so a whitespace-padded
          # existing principal cannot coexist with its stripped twin
          # after a write (review r1).
          document.merge("principals" =>
            GrantResolver.validate_principals(principals, @authorization_path))
        end

        def granted_projects(policy)
          policy.is_a?(Hash) && policy["projects"].is_a?(Array) ? policy["projects"] : []
        end

        def deep_copy(document)
          YAML.safe_load(YAML.dump(document), permitted_classes: [Date], aliases: true)
        end
      end
    end
  end
end
