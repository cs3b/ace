# frozen_string_literal: true

module Ace
  module LLM
    module Models
      # RoleConfig represents llm.roles configuration with validation.
      class RoleConfig
        attr_reader :roles

        def initialize(roles: {})
          @roles = normalize_roles(roles).freeze
          validate!
        end

        def self.from_hash(hash)
          return new unless hash

          unless hash.is_a?(Hash)
            raise Ace::LLM::ConfigurationError, "llm.roles config must be a Hash, got: #{hash.class}"
          end

          roles = hash.fetch(:roles, hash.fetch("roles", hash))
          new(roles: roles)
        end

        def role_names
          @roles.keys.sort
        end

        def candidates_for(role_name)
          normalized = normalize_role_name(role_name)
          @roles[normalized]
        end

        private

        def normalize_roles(roles)
          return {} if roles.nil?

          unless roles.is_a?(Hash)
            raise Ace::LLM::ConfigurationError, "llm.roles must be a hash, got: #{roles.class}"
          end

          roles.each_with_object({}) do |(name, candidates), acc|
            normalized_name = normalize_role_name(name)
            acc[normalized_name] = Array(candidates).map { |candidate| candidate.to_s.strip }
          end
        end

        def normalize_role_name(name)
          name.to_s.strip
        end

        def validate!
          @roles.each do |name, candidates|
            if name.empty?
              raise Ace::LLM::ConfigurationError, "role name cannot be empty"
            end

            unless candidates.is_a?(Array) && !candidates.empty?
              raise Ace::LLM::ConfigurationError, "role '#{name}' must define at least one candidate"
            end

            candidates.each do |candidate|
              if candidate.empty?
                raise Ace::LLM::ConfigurationError, "role '#{name}' contains an empty candidate"
              end

              if candidate.start_with?("role:")
                raise Ace::LLM::ConfigurationError,
                  "role '#{name}' cannot reference nested role candidate '#{candidate}'"
              end
            end
          end
        end
      end
    end
  end
end
