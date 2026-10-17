# frozen_string_literal: true

require_relative "../errors"
require_relative "../atoms/ordinary_merge_input"
require "ace/assign/errors"
require "time"

module Ace
  module Lab
    module Molecules
      # Deployment-owned ordinary fixed-merge admission facts. The installed
      # section supplies identity and placement only; the caller selects no
      # endpoint, credential or receiver. The authorization decisions are the
      # exact principal-owned grants; the proposal resolver is the canonical
      # proposal authority for `proposal-*` references.
      class OrdinaryMergePolicy
        ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/

        def initialize(document, proposal_resolver = nil)
          @document = document
          @authorizations = document.fetch("authorizations", {})
          @proposal_resolver = proposal_resolver
          unless @authorizations.is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError, "trusted merge policy must contain an authorizations mapping"
          end
        end

        # The trusted installation document as loaded. Decisions are mutable;
        # all other configuration remains bound for the receiver lifetime.
        attr_reader :document

        def self.configuration_digest(document)
          Atoms::OrdinaryMergeInput.digest(document.except("authorizations"))
        end

        def authorize!(reference, binding)
          raise ArgumentError, "invalid authorization reference" unless reference.to_s.match?(ID)
          if reference.start_with?("proposal-")
            raise SecurityError, "canonical proposal authority is unavailable" unless @proposal_resolver
            begin
              return @proposal_resolver.call(reference, binding)
            rescue Ace::Assign::Error
              raise SecurityError, "canonical proposal does not authorize this exact effect"
            end
          end
          decision = @authorizations[reference]
          raise SecurityError, "authorization reference is unresolved" unless decision.is_a?(Hash)
          required = %w[operation project_id assignment_id attempt_id input_digest target candidate_head caller_uid]
          unless required.all? { |key| decision[key] == binding[key] }
            raise SecurityError, "authorization does not match the exact service request"
          end
          raise SecurityError, "authorization has expired" if parse_time(decision["expires_at"]) <= Time.now.utc
          decision
        end

        # ---- ordinary fixed merge admission policy (spec 8x3.t.xz9.4) ------
        #
        # The installed ordinary section is the separately configured
        # ordinary receiver mapping and admission policy. It supplies
        # identity and placement only: the caller selects no endpoint,
        # credential or receiver. An absent project section or a disabled
        # admission flag is rollback: new admission is unavailable while
        # canonical records and read-only status stay preserved.
        ORDINARY_SECTION_KEYS = %w[projects].freeze
        ORDINARY_PROJECT_KEYS = %w[receiver_id socket_path receiver_uid principal admission
          journal_repository journal_ref].freeze
        ORDINARY_AUTHORIZATION_KEYS = %w[operation project_id assignment_id attempt_id queue_entry
          input_digest forge pr_url head_repository head_ref candidate_head base_repository
          base_ref expected_base_head expires_at].freeze
        # expires_at bounds the decision itself; it is never exact-matched
        # against the request binding, which carries no expiry.
        ORDINARY_BINDING_KEYS = ORDINARY_AUTHORIZATION_KEYS - %w[expires_at].freeze

        def ordinary_receiver!(project)
          section = @document["ordinary"]
          return nil unless section.is_a?(Hash)
          validate_ordinary_section!(section)
          entry = section.fetch("projects")[project.to_s]
          return nil unless entry.is_a?(Hash)
          entry
        end

        # The ordinary admission decision: exact-match on every closed
        # binding key, like authorize!, but over the ordinary request
        # identity (forge/PR/repository/ref) instead of execution selectors.
        def authorize_ordinary!(reference, binding)
          raise ArgumentError, "invalid authorization reference" unless reference.to_s.match?(ID)
          decision = @authorizations[reference]
          raise SecurityError, "authorization reference is unresolved" unless decision.is_a?(Hash)
          unless ORDINARY_AUTHORIZATION_KEYS.all? { |key| decision.key?(key) }
            raise SecurityError, "authorization reference is not an ordinary merge decision"
          end
          unless ORDINARY_BINDING_KEYS.all? { |key| decision[key] == binding[key] }
            raise SecurityError, "authorization does not match the exact ordinary merge request"
          end
          raise SecurityError, "authorization has expired" if parse_time(decision["expires_at"]) <= Time.now.utc
          decision
        end

        def validate_ordinary_section!(section)
          unless (section.keys - ORDINARY_SECTION_KEYS).empty? && section["projects"].is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError, "ordinary section must map projects"
          end
          section.fetch("projects").each do |project, entry|
            unless project.is_a?(String) && project.match?(ID) && entry.is_a?(Hash) &&
                (entry.keys - ORDINARY_PROJECT_KEYS).empty?
              raise Ace::Lab::InvalidConfigurationError, "ordinary project section is invalid"
            end
            unless entry["receiver_id"].is_a?(String) && entry["receiver_id"].match?(ID) &&
                entry["socket_path"].is_a?(String) && entry["socket_path"].start_with?("/") &&
                entry["receiver_uid"].is_a?(Integer) && entry["receiver_uid"].positive? &&
                entry["principal"].is_a?(String) && !entry["principal"].empty?
              raise Ace::Lab::InvalidConfigurationError, "ordinary receiver mapping is incomplete"
            end
            admission = entry.fetch("admission", "enabled")
            unless %w[enabled disabled].include?(admission)
              raise Ace::Lab::InvalidConfigurationError, "ordinary admission flag is invalid"
            end
            repository, ref = entry.values_at("journal_repository", "journal_ref")
            unless repository.is_a?(String) && repository.start_with?("/") && !repository.include?("\0") &&
                File.expand_path(repository) == repository &&
                ref.is_a?(String) && ref.match?(%r{\Arefs/[a-zA-Z0-9_-]+(?:/[a-zA-Z0-9_-]+)+\z})
              raise Ace::Lab::InvalidConfigurationError, "ordinary journal selection is invalid"
            end
          end
          true
        end

        private

        def parse_time(value)
          Time.iso8601(value.to_s)
        rescue ArgumentError
          raise Ace::Lab::InvalidConfigurationError, "trusted policy has invalid expiry"
        end
      end
    end
  end
end
