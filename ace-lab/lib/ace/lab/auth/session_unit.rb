# frozen_string_literal: true

require_relative "error"
require_relative "session_peer"

module Ace
  module Lab
    module Auth
      # Host-side unit specification. Command and environment must come from
      # protected host configuration, never the session socket's JSON payload.
      # Launch ownership and terminal readiness remain the launcher's concern.
      class SessionUnit
        ROLES = %w[lab-overseer project-overseer worker verifier integrator].freeze
        ENVIRONMENT = %w[PATH GEM_HOME GEM_PATH HOME LANG LC_ALL PI_CODING_AGENT_DIR].freeze

        def initialize(role:, id:, command:, directory:, environment: {})
          unless ROLES.include?(role) && id.is_a?(String) && id.match?(/\A[0-9a-f]{16}\z/)
            raise ArgumentError, "invalid configured session role or id"
          end
          unless command.is_a?(Array) && !command.empty? && command.all? { |arg| clean?(arg) } &&
              command.first.start_with?("/") && File.expand_path(command.first) == command.first
            raise ArgumentError, "session command requires an absolute configured executable"
          end
          unless environment.is_a?(Hash) && environment.all? { |key, value| ENVIRONMENT.include?(key) && clean?(value) }
            raise ArgumentError, "session environment is not allowlisted"
          end
          unless clean?(directory) && directory.start_with?("/") && File.expand_path(directory) == directory
            raise ArgumentError, "session directory must be a canonical absolute path"
          end
          @role, @id = role, id
          @directory = directory.dup.freeze
          @command = command.map(&:dup).freeze
          @environment = environment.transform_values(&:dup).freeze
        end

        def name = "ace-auth-session-#{@role}-#{@id}.service"
        def executable = @command.first.dup

        def with_preparation_entry(ruby:, entry:)
          self.class.new(role: @role, id: @id, environment: @environment, directory: @directory,
            command: [ruby, entry, "--directory", @directory, "--", *@command])
        end

        def argv
          properties = {
            "Type" => "exec", "Slice" => SessionPeer::SLICE,
            "DynamicUser" => "yes", "NoNewPrivileges" => "yes",
            "CapabilityBoundingSet" => "", "AmbientCapabilities" => "",
            "PrivateMounts" => "yes", "PrivateTmp" => "yes",
            "ProtectSystem" => "strict", "ProtectHome" => "yes",
            "ProtectControlGroups" => "yes", "Delegate" => "no",
            "KillMode" => "control-group", "SendSIGKILL" => "yes",
            "RuntimeDirectory" => "ace-auth-#{@id}", "RuntimeDirectoryMode" => "0700",
            "RuntimeDirectoryPreserve" => "no", "UMask" => "0077"
          }
          environment = @environment.merge("ACE_TOOLCHAIN" => "installed", "ACE_LAB_SESSION" => "1")
          ["/usr/bin/systemd-run", "--quiet", "--wait", "--pipe", "--no-ask-password",
            "--expand-environment=no", "--unit=#{name}",
            *properties.map { |key, value| "--property=#{key}=#{value}" },
            *environment.map { |key, value| "--setenv=#{key}=#{value}" }, "--", *@command]
        end

        private

        def clean?(value)
          value.is_a?(String) && !value.empty? && value.valid_encoding? && !value.match?(/[[:cntrl:]]/)
        end
      end
    end
  end
end
