# frozen_string_literal: true

require "digest"
require "json"

module Ace
  module Review
    module Atoms
      # Pure campaign input contracts and canonical identities.
      module CampaignContract
        class Invalid < ArgumentError; end
        SHA = /\A[0-9a-f]{40}(?:[0-9a-f]{24})?\z/.freeze
        ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/.freeze

        def self.canonical(value)
          case value
          when Hash then value.keys.sort.to_h { |key| [key, canonical(value[key])] }
          when Array then value.map { |item| canonical(item) }
          else value
          end
        end

        def self.digest(value)
          Digest::SHA256.hexdigest(JSON.generate(canonical(value)))
        end

        def self.object!(value, name)
          raise Invalid, "#{name} must be an object" unless value.is_a?(Hash)
          value
        end

        def self.string!(value, name)
          raise Invalid, "#{name} must be a nonempty string" unless value.is_a?(String) && !value.strip.empty?
          value
        end

        def self.id!(value, name)
          string!(value, name)
          raise Invalid, "invalid #{name}" unless ID.match?(value)
          value
        end

        def self.sha!(value, name)
          raise Invalid, "#{name} must be an exact Git SHA" unless value.is_a?(String) && SHA.match?(value)
          value
        end

        def self.strings!(value, name)
          unless value.is_a?(Array) && !value.empty? && value.all? { |v| v.is_a?(String) && !v.strip.empty? } &&
              value.uniq == value
            raise Invalid, "#{name} must be a nonempty array of unique strings"
          end
          value
        end

        # Repository is an explicit canonical identity, independent of forge.
        # PR parsing reuses the provider-neutral owner/repo#number contract.
        def self.subject!(value)
          object!(value, "subject")
          unknown = value.keys - %w[repository pr local_candidate_id]
          raise Invalid, "unknown subject fields: #{unknown.join(', ')}" unless unknown.empty?
          repository = string!(value["repository"], "repository")
          local = value["local_candidate_id"]
          pr = value["pr"]
          raise Invalid, "subject requires exactly one PR or local_candidate_id" if (!!pr) == (!!local)
          if pr
            parsed = Ace::Git::Atoms::PrIdentifier.parse(string!(pr, "pr"))
            raise Invalid, "PR must include repository identity (owner/repo#number)" unless parsed&.repo
            raise Invalid, "PR number must be positive" unless parsed.number.to_i.positive?
            {"repository" => repository, "pr" => "#{parsed.repo}##{parsed.number.to_i}"}
          else
            {"repository" => repository, "local_candidate_id" => id!(local, "local_candidate_id")}
          end
        end

        def self.policy!(value)
          object!(value, "policy")
          required = %w[revision minimum_rounds clean_rounds required_scopes required_checks]
          raise Invalid, "policy requires #{required.join(', ')}" unless (required - value.keys).empty?
          raise Invalid, "unknown policy fields" unless (value.keys - required).empty?
          string!(value["revision"], "policy revision")
          %w[minimum_rounds clean_rounds].each do |key|
            raise Invalid, "#{key} must be a positive integer" unless value[key].is_a?(Integer) && value[key].positive?
          end
          strings!(value["required_scopes"], "required_scopes").each { |v| id!(v, "scope") }
          strings!(value["required_checks"], "required_checks")
          canonical(value)
        end
      end
    end
  end
end
