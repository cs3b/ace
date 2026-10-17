# frozen_string_literal: true

require "json"
require "yaml"
require "digest"
require "ace/assign/atoms/evidence_digest"
require_relative "grant_resolver"

module Ace
  module Lab
    module Molecules
      # One deployment-owned policy, independent of repository preferences.
      # The selected grant covers the WHOLE service combination and exact argv.
      class CommandPolicy
        PATH = "/etc/lab/ace-lab/project-commands.yml"
        ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,63}\z/
        ENV_KEY = /\A[A-Z][A-Z0-9_]{0,63}\z/
        MAX_SOURCE_ENTRIES = 20_000
        MAX_GIT_ADMIN_ENTRIES = 1_000
        RESERVED = %w[HOME USER LOGNAME SHELL PATH RUBYOPT RUBYLIB BUNDLE_GEMFILE GEM_HOME GEM_PATH BASH_ENV ENV PYTHONPATH PYTHONHOME PERL5LIB LD_PRELOAD LD_LIBRARY_PATH].freeze
        attr_reader :project, :launcher

        def self.load(project:)
          bytes = GrantResolver.read_verified(PATH)
          raise InvalidConfigurationError, "project commands are not installed" unless bytes && bytes.bytesize <= 65_536
          new(YAML.safe_load(bytes, aliases: false), project: project)
        rescue Psych::Exception
          raise InvalidConfigurationError, "invalid project command policy"
        end

        def initialize(document, project:)
          strict!(document, %w[version projects])
          invalid! unless document["version"] == 1 && document["projects"].is_a?(Hash) &&
            document["projects"].keys.all? { |id| id.is_a?(String) && ID.match?(id) } && project.is_a?(String) && ID.match?(project)
          @project = project
          @document = JSON.parse(JSON.generate(document))
          @entry = @document.fetch("projects").fetch(project) { invalid! }
          strict!(@entry, %w[launcher default_executor default_services executors services commands grants])
          @launcher = @entry.fetch("launcher")
          strict!(@launcher, %w[socket_path identity_path])
          invalid! unless @launcher.values.all? { |value| absolute?(value) }
          %w[executors services commands].each do |key|
            value = @entry.fetch(key)
            invalid! unless value.is_a?(Hash) && value.size <= 64 && value.keys.all? { |id| id.is_a?(String) && ID.match?(id) }
          end
          @entry.fetch("executors").each_value do |value|
            strict!(value, %w[uid gid groups home cwd path environment])
            invalid! unless %w[uid gid].all? { |key| uid?(value[key]) } &&
              value["groups"].is_a?(Array) && value["groups"].all? { |gid| uid?(gid) } &&
              value["groups"].uniq == value["groups"] &&
              %w[home cwd].all? { |key| absolute?(value[key]) } &&
              value["path"].is_a?(Array) && !value["path"].empty? && value["path"].all? { |item| absolute?(item) }
            environment!(value.fetch("environment"))
          end
          @entry.fetch("services").each_value do |value|
            strict!(value, %w[environment secret_references])
            environment!(value.fetch("environment"))
            references = value.fetch("secret_references")
            invalid! unless references.is_a?(Hash) && references.all? { |key, path| env_key?(key) && absolute?(path) }
          end
          @entry.fetch("commands").each_value do |value|
            strict!(value, %w[argv executable_sha256 source purpose])
            invalid! unless %w[command test].include?(value["purpose"])
            argv!(value.fetch("argv"))
            invalid! unless sha?(value.fetch("executable_sha256"))
            source = value.fetch("source")
            if source.is_a?(Hash) && source["kind"] == "ordinary-candidate"
              strict!(source, %w[kind root runtime_path runtime_sha256])
              invalid! unless value["purpose"] == "test" && absolute?(source["root"]) &&
                absolute?(source["runtime_path"]) && sha?(source["runtime_sha256"])
            else
              strict!(source, %w[head tree])
              invalid! unless source.values.all? { |sha| sha.nil? || (sha.is_a?(String) && sha.match?(/\A[0-9a-f]{40}\z/)) } &&
                source.values.all?(&:nil?) == source.values.any?(&:nil?)
              invalid! if value["purpose"] == "test" && source.values.any?(&:nil?)
            end
          end
          invalid! unless @entry.fetch("executors").key?(@entry["default_executor"])
          services!(@entry.fetch("default_services"))
          invalid! unless @entry["grants"].is_a?(Array) && @entry["grants"].size <= 256
          @entry["grants"].each do |grant|
            strict!(grant, %w[kind uid command executor services])
            invalid! unless %w[operator agent].include?(grant["kind"]) && uid?(grant["uid"]) &&
              @entry.fetch("commands").key?(grant["command"]) && @entry.fetch("executors").key?(grant["executor"])
            services!(grant.fetch("services"))
          end
          @fingerprint = Ace::Assign::Atoms::EvidenceDigest.digest(@entry)
          freeze_value(@document)
        end

        def reader!(uid)
          deny! unless @entry.fetch("grants").any? { |grant| grant.fetch("uid") == uid }
          true
        end

        def select(selection:, peer:)
          invalid! unless selection.is_a?(Hash)
          strict!(selection, %w[argv executor services pane] + (selection.key?("candidate") ? ["candidate"] : []))
          argv!(selection.fetch("argv"))
          executor_id = selection["executor"] || @entry.fetch("default_executor")
          executor = @entry.fetch("executors")[executor_id]
          deny! unless executor
          requested = selection["services"].nil? ? @entry.fetch("default_services") : selection["services"]
          services!(requested)
          selected = requested.uniq.sort
          matches = @entry.fetch("commands").select { |_name, value| value.fetch("argv") == selection["argv"] }
          deny! unless matches.size == 1
          command_id, command = matches.first
          reference = selection["candidate"]
          if command.dig("source", "kind") == "ordinary-candidate"
            strict!(reference, %w[assignment_id attempt_id candidate_generation acceptance_event_digest])
            invalid! unless %w[assignment_id attempt_id].all? { |key| reference[key].is_a?(String) && ID.match?(reference[key]) } &&
              reference["candidate_generation"].is_a?(Integer) && reference["candidate_generation"].positive? && sha?(reference["acceptance_event_digest"])
          else
            invalid! unless reference.nil?
          end
          kind = selection["pane"].nil? ? "operator" : "agent"
          deny! unless @entry.fetch("grants").any? { |grant|
            grant.values_at("kind", "uid", "command", "executor") == [kind, peer.fetch("uid"), command_id, executor_id] &&
              grant.fetch("services").sort == selected }
          environment = executor.fetch("environment").dup
          references = {}
          selected.each do |id|
            service = @entry.fetch("services").fetch(id)
            additions = service.fetch("environment")
            secrets = service.fetch("secret_references")
            deny! unless (environment.keys & (additions.keys + secrets.keys)).empty? &&
              (references.keys & (additions.keys + secrets.keys)).empty? && (additions.keys & secrets.keys).empty?
            environment.merge!(additions)
            references.merge!(secrets)
          end
          definition = {"policy_sha256" => @fingerprint, "project_id" => @project, "command_id" => command_id,
            "argv" => command.fetch("argv"), "executable_sha256" => command.fetch("executable_sha256"),
            "source" => command.fetch("source"), "purpose" => command.fetch("purpose"), "executor_id" => executor_id,
            "executor" => executor.merge("environment" => environment, "groups" => executor.fetch("groups").sort), "services" => selected,
            "secret_references" => references, "requester" => peer, "requester_kind" => kind,
            "selection" => selection}
          invalid! if JSON.generate(definition).bytesize > 8192
          definition
        end

        private

        def strict!(value, keys)
          invalid! unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end
        def argv!(value)
          invalid! unless value.is_a?(Array) && value.size.between?(1, 128) &&
            value.all? { |item| item.is_a?(String) && item.bytesize <= 4096 && !item.include?("\0") } &&
            !value.first.empty? && value.sum(&:bytesize) <= 8192
        end
        def services!(value)
          invalid! unless value.is_a?(Array) && value.size <= 64 && value.all? { |id| @entry.fetch("services").key?(id) }
        end
        def environment!(value)
          invalid! unless value.is_a?(Hash) && value.size <= 64 && value.all? { |key, item|
            env_key?(key) && item.is_a?(String) && item.bytesize <= 4096 && !item.include?("\0") }
        end
        def env_key?(key) = key.is_a?(String) && ENV_KEY.match?(key) && !RESERVED.include?(key) && !key.start_with?("GIT_CONFIG_", "BUNDLE_", "LD_", "DYLD_")
        def absolute?(value) = value.is_a?(String) && value.start_with?("/") && !value.include?("\0") && File.expand_path(value) == value
        def uid?(value) = value.is_a?(Integer) && value.between?(1, 2**31 - 1)
        def sha?(value) = value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/)
        def invalid! = raise(InvalidConfigurationError, "invalid project command policy")
        def deny! = raise(SecurityError, "project command selection is not authorized")
        def freeze_value(value)
          case value
          when Hash then value.each { |key, child| key.freeze; freeze_value(child) }
          when Array then value.each { |child| freeze_value(child) }
          end
          value.freeze
        end
      end
    end
  end
end
