# frozen_string_literal: true

require "yaml"
require_relative "../errors"
require_relative "service_policy"

module Ace
  module Lab
    module Molecules
      # Project-scoped, explicitly filed receiver configuration (spec
      # 8x3.t.xz9.4 execution clauses). The host owns the file, its
      # placement, its credentials and its deployment; this loader only
      # validates the exact closed shape and fails closed on anything else.
      # It invents no credential and accepts no caller-selected endpoint:
      # every value comes from one explicit deployment-owned YAML file.
      class OrdinaryReceiverConfig
        KEYS = %w[project receiver_id socket_path receiver_uid principal principal_uid
          repo_path policy_path execution_identity].freeze
        OPTIONAL_KEYS = %w[socket_gid forge_config_path].freeze
        IDENTITY_KEYS = %w[checkout_id worktree_id branch].freeze
        ID = ServicePolicy::ID

        def self.load(path)
          raise Ace::Lab::InvalidConfigurationError, "receiver config path is required" unless path.is_a?(String) && !path.empty?
          document = YAML.safe_load_file(path, permitted_classes: [Date], aliases: false)
          new(document, source: path)
        rescue Errno::ENOENT, Errno::EACCES, Psych::Exception
          raise Ace::Lab::InvalidConfigurationError, "receiver configuration is unreadable: #{path}"
        end

        attr_reader :project, :receiver_id, :socket_path, :receiver_uid, :principal,
          :principal_uid, :repo_path, :policy_path, :execution_identity, :source, :socket_gid, :forge_config_path

        def initialize(document, source: nil)
          unless document.is_a?(Hash) && (document.keys - KEYS - OPTIONAL_KEYS).empty? &&
              (KEYS - document.keys).empty?
            raise Ace::Lab::InvalidConfigurationError,
              "receiver configuration requires #{KEYS.join(', ')}; optional: #{OPTIONAL_KEYS.join(', ')}"
          end
          @socket_gid = uid!(document.fetch("socket_gid"), "socket_gid") if document.key?("socket_gid")
          @forge_config_path = absolute!(document.fetch("forge_config_path"), "forge_config_path") if
            document.key?("forge_config_path")
          @source = source
          @project = string!(document.fetch("project"), "project")
          @receiver_id = string!(document.fetch("receiver_id"), "receiver_id")
          @principal = string!(document.fetch("principal"), "principal")
          @socket_path = absolute!(document.fetch("socket_path"), "socket_path")
          @repo_path = absolute!(document.fetch("repo_path"), "repo_path")
          @policy_path = absolute!(document.fetch("policy_path"), "policy_path")
          @receiver_uid = uid!(document.fetch("receiver_uid"), "receiver_uid")
          @principal_uid = uid!(document.fetch("principal_uid"), "principal_uid")
          identity = document.fetch("execution_identity")
          unless identity.is_a?(Hash) && (identity.keys - IDENTITY_KEYS).empty? &&
              IDENTITY_KEYS.all? { |key| identity[key].is_a?(String) && !identity[key].empty? }
            raise Ace::Lab::InvalidConfigurationError,
              "receiver execution_identity is incomplete"
          end
          @execution_identity = IDENTITY_KEYS.to_h { |key| [key, identity.fetch(key)] }.freeze
          unless @repo_path.start_with?("/") && File.directory?(@repo_path)
            raise Ace::Lab::InvalidConfigurationError, "receiver repo_path is not a directory"
          end
          freeze
        end

        private

        def string!(value, name)
          unless value.is_a?(String) && !value.empty? && value.length <= 256 && value.match?(ID)
            raise Ace::Lab::InvalidConfigurationError, "receiver #{name} is invalid"
          end
          value
        end

        def absolute!(value, name)
          unless value.is_a?(String) && value.start_with?("/") && value.length <= 1024
            raise Ace::Lab::InvalidConfigurationError, "receiver #{name} must be an absolute path"
          end
          value
        end

        def uid!(value, name)
          unless value.is_a?(Integer) && value >= 0
            raise Ace::Lab::InvalidConfigurationError, "receiver #{name} must be a non-negative integer"
          end
          value
        end
      end
    end
  end
end
