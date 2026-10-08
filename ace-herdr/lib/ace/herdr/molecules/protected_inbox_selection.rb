# frozen_string_literal: true
require "tmpdir"
require "ace/runtime/molecules/protected_task_context_entry"
require_relative "bounded_process"
require_relative "inbox_context_store"

module Ace
  module Herdr
    module Molecules
      # Existing immutable entry owns discovery; the endpoint still authorizes effects.
      class ProtectedInboxSelection
        TOKEN = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        def initialize(entry_owner: Ace::Runtime::Molecules::ProtectedTaskContextEntry.new,
          runner: BoundedProcess, uid: Process.uid, env: ENV)
          @owner, @runner, @uid, @env = entry_owner, runner, uid, env
        end

        def with(options)
          downstream_started = false
          selected = options.values_at(:project, :mapping, :inbox_context, :claim_generation, :assignment).any? { |item| !item.nil? } ||
            %w[ACE_ASSIGN_PROJECT_ID ACE_ASSIGN_LAUNCH_MAPPING ACE_ASSIGN_INBOX_CONTEXT_ID].any? { |key| !@env[key].to_s.empty? }
          @owner.with do |pin|
            unless pin
              raise ValidationError, "protected inbox entry is absent" if selected
              downstream_started = true
              next yield nil
            end
            principal = invoke(pin, ["authority", "inbox-context-principal"], 1024)
            object!(principal, %w[schema uid protected_participant])
            unless principal["schema"] == "ace.assign.inbox-context-principal/v1" && principal["uid"] == @uid &&
                principal["uid"].is_a?(Integer) && [true, false].include?(principal["protected_participant"])
              raise ValidationError, "protected inbox actual caller differs"
            end
            unless principal.fetch("protected_participant") || selected
              downstream_started = true
              next yield nil
            end
            keys = {project: "ACE_ASSIGN_PROJECT_ID", mapping: "ACE_ASSIGN_LAUNCH_MAPPING", inbox_context: "ACE_ASSIGN_INBOX_CONTEXT_ID"}
            selectors = keys.to_h do |key, hint_key|
              value, hint = options[key], @env[hint_key].to_s
              unless value.is_a?(String) && TOKEN.match?(value) && (hint.empty? || hint == value)
                raise ValidationError, "explicit protected inbox selectors differ"
              end
              [key, value]
            end
            args = selectors.flat_map { |key, value| ["--#{key.to_s.tr('_', '-')}", value] }
            result = invoke(pin, ["authority", "inbox-context-selection", *args], 16_384)
            object!(result, %w[schema uid project_id mapping_id inbox_context_id descriptor history context authority])
            unless result["schema"] == "ace.assign.inbox-context-selection/v1" && result["uid"] == @uid &&
                result.values_at("project_id", "mapping_id", "inbox_context_id") == selectors.values
              raise ValidationError, "protected inbox selected association differs"
            end
            %w[descriptor history].each do |field|
              reference = result.fetch(field)
              object!(reference, %w[path bytes sha256])
              @owner.validate_pin!({"manifest" => reference, "wrapper" => reference})
            end
            context = result.fetch("context")
            object!(context, %w[control_socket_path owner_credentials native_mapping_id])
            endpoint!(context.fetch("control_socket_path")); credentials!(context.fetch("owner_credentials"))
            raise ValidationError, "protected inbox native mapping differs" unless context["native_mapping_id"].is_a?(String) && TOKEN.match?(context["native_mapping_id"])
            authority = result.fetch("authority")
            object!(authority, %w[authority_id socket_path uid gid groups])
            endpoint!(authority.fetch("socket_path")); credentials!(authority.slice("uid", "gid", "groups"))
            raise ValidationError, "protected inbox authority ID differs" unless authority["authority_id"].is_a?(String) && TOKEN.match?(authority["authority_id"])
            downstream_started = true
            yield result
          end
        rescue Ace::Runtime::Error, IOError, SystemCallError, Timeout::Error, BoundedProcess::PostLaunchError, KeyError, TypeError, ArgumentError
          raise if downstream_started
          raise ValidationError, "protected inbox selection is unavailable"
        end

        private

        def invoke(pin, args, limit)
          @owner.with_entry(pin) do |entry|
            Dir.mktmpdir("ace-inbox-selector-", "/tmp") do |directory|
              path = File.join(directory, "selector.json")
              File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |writer|
                writer.write(JSON.generate(entry.pin.fetch("manifest")) + "\n"); writer.flush
                File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |reader|
                  unless reader.stat.file? && reader.stat.uid == Process.uid && (reader.stat.mode & 0o077).zero? &&
                      [reader.stat.dev, reader.stat.ino, reader.stat.size] == [writer.stat.dev, writer.stat.ino, writer.stat.size]
                    raise ValidationError, "protected inbox selector handle differs"
                  end
                  File.unlink(path)
                  output = @runner.call(["/proc/self/fd/4", "-I", "-S", "-B", "-", *args], stdin_data: entry.body,
                    timeout_s: 30, output_limit: limit, stderr_limit: 16_384,
                    descriptor_mapping: {4 => entry.interpreter, 5 => reader}, environment: {}, chdir: "/", cleanup_group: true)
                  unless output.status&.success? && !output.oversized && output.stdout.is_a?(String) &&
                      output.stdout.end_with?("\n") && output.stdout.count("\n") == 1
                    raise ValidationError, "protected inbox entry failed or framing differs"
                  end
                  record = InboxContextStore.decode(output.stdout, limit: limit)
                  raise ValidationError, "protected inbox entry is not compact JSON" unless JSON.generate(record) + "\n" == output.stdout
                  record
                end
              end
            end
          end
        end

        def object!(value, fields)
          raise ValidationError, "protected inbox fields differ" unless value.is_a?(Hash) && value.keys.sort == fields.sort
        end

        def endpoint!(value)
          unless value.is_a?(String) && value.encoding == Encoding::UTF_8 && value.valid_encoding? &&
              value.bytesize.between?(2, 4096) && value.start_with?("/") && !value.include?("\0") && File.expand_path(value) == value
            raise ValidationError, "protected inbox endpoint differs"
          end
        end

        def credentials!(value)
          object!(value, %w[uid gid groups])
          unless value.values_at("uid", "gid").all? { |number| number.is_a?(Integer) && number.positive? } &&
              value["groups"].is_a?(Array) && value["groups"].size <= 64 &&
              value["groups"].all? { |number| number.is_a?(Integer) && number.positive? } && value["groups"] == value["groups"].sort.uniq
            raise ValidationError, "protected inbox principal differs"
          end
        end
      end
    end
  end
end
