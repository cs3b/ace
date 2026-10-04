# frozen_string_literal: true
require "ace/git/atoms/server_url"

module Ace
  module Assign
    module Atoms
      # Explicit non-secret remote delivery inputs; local recipes need not call this validator.
      module DeliveryParameters
        PROVENANCE_FIELDS = %w[mode head_repository_url head_ref base_repository_url base_ref].freeze
        def self.validate(input)
          raise ArgumentError, "Delivery parameters must be a mapping" unless input.is_a?(Hash)
          default = input.fetch("forge_default", false)
          raise ArgumentError, "forge_default must be boolean" unless [true, false].include?(default)
          server = input["forge_server"]
          if server && (!server.is_a?(String) || !server.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/))
            raise ArgumentError, "Invalid forge_server"
          end
          raise ArgumentError, "forge_server and forge_default are mutually exclusive" if server && default
          provenance = input["pr_provenance"]
          unless provenance.is_a?(Hash) && provenance.keys.sort == PROVENANCE_FIELDS.sort &&
              %w[fork canonical].include?(provenance["mode"])
            raise ArgumentError, "Explicit complete fork or canonical PR provenance is required"
          end
          %w[head_repository_url base_repository_url].each { |key| validate_url!(provenance[key]) }
          %w[head_ref base_ref].each do |key|
            ref = provenance[key]
            unless ref.is_a?(String) && ref.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_\/.\-]{0,255}\z/) &&
                !ref.include?("..") && !ref.include?("//") && !ref.end_with?("/", ".", ".lock")
              raise ArgumentError, "Invalid PR ref"
            end
          end
          if provenance["mode"] == "canonical" && !Ace::Git::Atoms::ServerUrl.match?(
              provenance["head_repository_url"], provenance["base_repository_url"])
            raise ArgumentError, "Canonical provenance requires matching head and base repositories"
          end
          {"forge_server" => server, "forge_default" => default,
           "pr_provenance" => provenance.transform_values(&:dup)}
        end

        def self.validate_url!(url)
          unless url.is_a?(String) && url.length <= 512 &&
              (url.match?(%r{\Ahttps?://[a-zA-Z0-9.:-]+/[a-zA-Z0-9_./-]+\z}) ||
               url.match?(%r{\Agit@[a-zA-Z0-9.-]+:[a-zA-Z0-9_./-]+\z}) ||
               url.match?(%r{\Assh://git@[a-zA-Z0-9.:-]+/[a-zA-Z0-9_./-]+\z}))
            raise ArgumentError, "PR repository URL must contain a repository and no credentials or query"
          end
        end
      end
    end
  end
end
