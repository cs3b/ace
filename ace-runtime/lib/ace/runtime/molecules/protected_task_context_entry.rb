# frozen_string_literal: true
require "json"
require_relative "protected_artifact_set"

module Ace
  module Runtime
    module Molecules
      # Ref-only installed discovery. Domain publication owns the projection;
      # the selected child remains the original scope/admission authority.
      class ProtectedTaskContextEntry
        PATH = "/etc/ace/task-context-entry.json"
        PRESENCE_PATHS = %w[/etc/ace/assignment-authorities.json /etc/ace/assignment-deployment-history.json /usr/local/lib/lab/herdr.installation.json].freeze
        SCHEMA = "ace.protected-task-context-entry-selection/v1"
        MANIFEST_SCHEMA = "lab.protected-command-entry/v1"
        ROLE = "ace-assign-task-context"
        METADATA_LIMIT = 65_536
        FILE_LIMIT = 33_554_432
        TOTAL_LIMIT = 268_435_456
        COUNT_LIMIT = 4_096
        Entry = Struct.new(:pin, :manifest, :body, :interpreter, keyword_init: true)

        def initialize(artifacts_factory: -> { ProtectedArtifactSet.new(file_limit: FILE_LIMIT, total_limit: TOTAL_LIMIT, count_limit: COUNT_LIMIT) },
          stat: File.method(:lstat))
          @factory, @stat = artifacts_factory, stat
        end

        # Pure shape validation, never publication/original admission authority.
        def validate_pin!(pin)
          pin!(pin)
        end

        def with
          unless present?(PATH)
            refuse!("installed discovery is absent") if PRESENCE_PATHS.any? { |path| present?(path) }
            return yield nil
          end
          @factory.call.with do |held|
            @held = held
            bytes, = held.read_path!(PATH, limit: METADATA_LIMIT)
            projection = json!(bytes)
            object!(projection, %w[schema task_context_entry])
            refuse!("discovery schema") unless projection.fetch("schema") == SCHEMA
            pin = pin!(projection.fetch("task_context_entry"))
            held.verify_unchanged!
            result = yield pin
            held.verify_unchanged!
            result
          ensure
            @held = nil
          end
        rescue KeyError, TypeError, NoMethodError, ArgumentError, IOError, SystemCallError, EncodingError
          refuse!("installed discovery is unavailable")
        end

        # Live descriptor lifetime is this callback only. Exact protected bytes
        # go to stdin; callers never execute/reopen a manifest-selected pathname.
        def with_entry(pin)
          refuse!("entry requires held discovery") unless @held
          pin = pin!(pin)
          manifest = json!(@held.read!(pin.fetch("manifest")))
          object!(manifest, %w[schema role wrapper interpreter bootstrap])
          unless manifest.fetch("schema") == MANIFEST_SCHEMA && manifest.fetch("role") == ROLE && manifest.fetch("wrapper") == pin.fetch("wrapper")
            refuse!("selected fixed role differs")
          end
          reference!(manifest.fetch("interpreter"))
          bootstrap = manifest.fetch("bootstrap")
          object!(bootstrap, %w[original_source owner preparation startup_entries])
          %w[original_source owner preparation].each do |key|
            reference!(bootstrap.fetch(key))
            @held.read!(bootstrap.fetch(key))
          end
          entries = bootstrap.fetch("startup_entries")
          refuse!("bootstrap entry references") unless entries.is_a?(Hash)
          reference!(entries.fetch("ace-assign"))
          read_references!(entries)
          body = @held.read!(pin.fetch("wrapper"))
          text = body.dup.force_encoding(Encoding::UTF_8)
          refuse!("wrapper source encoding") unless text.valid_encoding? && !text.include?("\0")
          @held.with_readonly_handle!(manifest.fetch("interpreter")) do |interpreter|
            stat = interpreter.stat
            refuse!("selected interpreter is not executable") unless stat.file? && stat.executable? && (stat.mode & 0o6000).zero?
            @held.verify_unchanged!
            result = yield Entry.new(pin: pin, manifest: immutable(manifest), body: body, interpreter: interpreter).freeze
            @held.verify_unchanged!
            result
          end
        rescue KeyError, TypeError, NoMethodError, ArgumentError, IOError, SystemCallError, EncodingError
          refuse!("selected protected entry is unavailable")
        end

        private

        def present?(path)
          @stat.call(path)
          true
        rescue Errno::ENOENT
          false
        end

        def pin!(pin)
          object!(pin, %w[manifest wrapper])
          reference!(pin.fetch("manifest"), limit: METADATA_LIMIT)
          reference!(pin.fetch("wrapper"))
          immutable(pin)
        end

        def reference!(reference, limit: FILE_LIMIT)
          object!(reference, %w[bytes path sha256])
          path = reference.fetch("path")
          unless path.is_a?(String) && path.encoding == Encoding::UTF_8 && path.valid_encoding? &&
              path.bytesize.between?(2, 4096) && path.start_with?("/") && !path.include?("\0") && File.expand_path(path) == path &&
              reference.fetch("bytes").is_a?(Integer) && reference.fetch("bytes").between?(1, limit) &&
              reference.fetch("sha256").is_a?(String) && reference.fetch("sha256").match?(/\A[0-9a-f]{64}\z/)
            refuse!("protected entry reference")
          end
        end

        def read_references!(root)
          pending = [root]
          until pending.empty?
            value = pending.pop
            if value.is_a?(Hash) && value.keys.sort == %w[bytes path sha256]
              reference!(value)
              @held.read!(value)
            elsif value.is_a?(Hash) && value.keys.all? { |key| key.is_a?(String) }
              pending.concat(value.values)
            elsif value.is_a?(Array)
              pending.concat(value)
            else
              refuse!("bootstrap reference graph")
            end
          end
        end

        def json!(bytes)
          text = bytes.dup.force_encoding(Encoding::UTF_8)
          refuse!("entry metadata encoding or bound") unless text.valid_encoding? && text.bytesize.between?(1, METADATA_LIMIT)
          JSON.parse(text, create_additions: false, max_nesting: 32, allow_duplicate_key: false, allow_comments: false)
        rescue JSON::ParserError
          refuse!("entry metadata JSON")
        end

        def object!(value, fields)
          refuse!("entry fields") unless value.is_a?(Hash) && value.keys.sort == fields.sort
        end

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end

        def refuse!(detail)
          raise RuntimeUnavailableError, "protected task-context entry unavailable: #{detail}"
        end
      end
    end
  end
end
