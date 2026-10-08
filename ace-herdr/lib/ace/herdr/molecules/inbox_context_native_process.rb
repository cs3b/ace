# frozen_string_literal: true

require "ace/runtime/molecules/protected_artifact_set"
require_relative "inbox_context_service_configuration"
require_relative "bounded_process"

module Ace
  module Herdr
    module Molecules
      # Exact accepted executable inode, fixed environment and startup closure.
      # This is process construction, not original-target authorization.
      class InboxContextNativeProcess
        def initialize(configuration:, artifacts_factory: nil, process: BoundedProcess)
          unless configuration.is_a?(InboxContextServiceConfiguration)
            raise ValidationError, "context native selection is not held"
          end
          @selection = configuration.data.fetch("native_clients")
          @credentials = configuration.data.fetch("owner_credentials")
          @artifacts_factory = artifacts_factory || -> { Ace::Runtime::Molecules::ProtectedArtifactSet.new(
            file_limit: 268_435_456, total_limit: 268_435_456, count_limit: 512) }
          @process = process
        end

        def verify!
          @artifacts_factory.call.with do |reader|
            references.each { |ref| reader.read!(ref) }
            @selection.values_at("codex", "pi", "herdr").each do |ref|
              reader.with_readonly_handle!(ref) { |handle| verify_executable!(handle) }
            end
            resource_snapshot!
            reader.verify_unchanged!
          end
          true
        rescue Ace::Runtime::RuntimeUnavailableError, SystemCallError, IOError
          raise ValidationError, "context native release is unavailable"
        end

        def call(argv, stdin_data:, timeout_s:, output_limit: 65_536)
          selected = @selection.values_at("codex", "pi", "herdr").find { |ref| ref.fetch("path") == argv.first }
          raise ValidationError, "context native executable is not selected" unless selected
          @artifacts_factory.call.with do |reader|
            references.each { |ref| reader.read!(ref) }
            resources = resource_snapshot!
            reader.with_readonly_handle!(selected) do |handle|
              verify_executable!(handle)
              result = @process.call(["/proc/self/fd/5", *argv.drop(1)], stdin_data: stdin_data, timeout_s: timeout_s,
                output_limit: output_limit, environment: @selection.fetch("environment"),
                chdir: @selection.fetch("cwd"), descriptor_mapping: {5 => handle})
              raise ValidationError, "context native resource changed" unless resource_snapshot! == resources
              result
            end
          end
        rescue Ace::Runtime::RuntimeUnavailableError, SystemCallError, IOError
          raise ValidationError, "context native executable evidence is unavailable"
        end

        private

        def references = @selection.values_at("codex", "pi", "herdr", "codex_runtime_intent") + @selection.fetch("dependencies")

        def access_bits(stat)
          if stat.uid == @credentials.fetch("uid")
            (stat.mode >> 6) & 7
          elsif (@credentials.fetch("groups") + [@credentials.fetch("gid")]).include?(stat.gid)
            (stat.mode >> 3) & 7
          else
            stat.mode & 7
          end
        end

        def verify_executable!(handle)
          raise ValidationError, "context native executable mode differs" unless (access_bits(handle.stat) & 1) == 1
        end

        def resource_snapshot!
          @selection.fetch("resources").map do |row|
            stat = File.lstat(row.fetch("path"))
            kind = row.fetch("kind") == "directory" ? stat.directory? : stat.socket?
            unless kind && !stat.symlink? && stat.uid == row.fetch("uid") && stat.gid == row.fetch("gid") &&
                (stat.mode & 0o7777) == row.fetch("mode")
              raise ValidationError, "context native resource placement differs"
            end
            bits = access_bits(stat)
            required = row.fetch("kind") == "socket" ? 2 : row.fetch("access") == "write" ? 3 : 5
            raise ValidationError, "context native resource access differs" unless (bits & required) == required
            [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode]
          end
        end
      end
    end
  end
end
