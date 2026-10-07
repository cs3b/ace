# frozen_string_literal: true

require "json"

module Ace
  module Lab
    module Atoms
      # Structural input validation only. Canonical ownership, preservation and
      # current permission are independently verified by the operation owners.
      module ProtectedWorkspacePruneInput
        MAX_BYTES = 65_536
        ID = /\A[A-Za-z0-9_.-]{1,200}\z/
        SHA = /\A[0-9a-f]{64}\z/
        COMMIT = /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/
        ASSOCIATION = %w[project_id mapping_id assignment_id attempt_id].freeze

        module_function

        def parse(bytes)
          reject! unless bytes.is_a?(String) && bytes.bytesize.between?(1, MAX_BYTES)
          text = bytes.dup.force_encoding(Encoding::UTF_8)
          reject! unless text.valid_encoding?
          input = JSON.parse(text, create_additions: false, max_nesting: 16,
            allow_nan: false, allow_comments: false, allow_duplicate_key: false)
          object!(input, %w[schema maintenance target publication preservation])
          reject! unless input.fetch("schema") == "ace.protected-workspace-prune/v1"
          association!(input.fetch("maintenance"))
          target = object!(input.fetch("target"), ASSOCIATION +
            %w[resource artifact_digest descriptor_sha256 binding_event_digest release_event_digest journal_commit])
          ASSOCIATION.each { |field| token!(target.fetch(field)) }
          %w[artifact_digest descriptor_sha256 binding_event_digest release_event_digest].each { |key| digest!(target.fetch(key)) }
          commit!(target.fetch("journal_commit"))
          resource = "workspace:#{target.fetch('project_id')}:#{target.fetch('mapping_id')}:#{target.fetch('assignment_id')}"
          reject! unless resource.bytesize <= 256 && target.fetch("resource") == resource
          publication = object!(input.fetch("publication"), %w[descriptor_sha256 installation_ref])
          digest!(publication.fetch("descriptor_sha256"))
          reference!(publication.fetch("installation_ref"))
          preservation!(input.fetch("preservation"))
          freeze_value(input)
        rescue JSON::ParserError, JSON::NestingError, EncodingError
          reject!
        end

        def preservation!(value)
          object!(value, %w[head branch destinations manifest_sha256])
          commit!(value.fetch("head"))
          branch = value.fetch("branch")
          unless branch.nil?
            ref!(branch)
            reject! unless branch.start_with?("refs/heads/")
          end
          digest!(value.fetch("manifest_sha256"))
          destinations = value.fetch("destinations")
          reject! unless destinations.is_a?(Array) && destinations.length <= 64
          identities = destinations.map do |entry|
            object!(entry, %w[repository_id ref head])
            token!(entry.fetch("repository_id"))
            ref!(entry.fetch("ref"))
            commit!(entry.fetch("head"))
            entry.values_at("repository_id", "ref", "head")
          end
          reject! unless identities == identities.sort && identities.uniq == identities
        end

        def association!(value)
          object!(value, ASSOCIATION)
          value.each_value { |item| token!(item) }
        end

        def reference!(value)
          object!(value, %w[path bytes sha256])
          path = value.fetch("path")
          reject! unless path.is_a?(String) && path.bytesize.between?(2, 4096) &&
            path.start_with?("/") && !path.include?("\0") && !path.end_with?("/") &&
            path.split("/", -1).drop(1).all? { |part| !part.empty? && !%w[. ..].include?(part) }
          reject! unless value.fetch("bytes").is_a?(Integer) && value.fetch("bytes").between?(1, MAX_BYTES)
          digest!(value.fetch("sha256"))
        end

        def object!(value, fields)
          reject! unless value.is_a?(Hash) && value.keys.sort == fields.sort
          value
        end

        def token!(value)
          reject! unless value.is_a?(String) && ID.match?(value)
        end

        def digest!(value)
          reject! unless value.is_a?(String) && SHA.match?(value)
        end

        def commit!(value)
          reject! unless value.is_a?(String) && COMMIT.match?(value)
        end

        def ref!(value)
          reject! unless value.is_a?(String) && value.bytesize.between?(6, 256) &&
            value.start_with?("refs/") && !value.match?(/[\x00-\x20\x7f~^:?*\[\\]/) &&
            !value.include?("..") && !value.include?("@{") && !value.end_with?(".") &&
            value.split("/", -1).all? { |part| !part.empty? && !part.start_with?(".") && !part.end_with?(".lock") }
        end

        def freeze_value(value)
          value.each { |key, item| key.freeze; freeze_value(item) } if value.is_a?(Hash)
          value.each { |item| freeze_value(item) } if value.is_a?(Array)
          value.freeze
        end

        def reject! = raise(ArgumentError, "invalid protected prune input")
      end
    end
  end
end
