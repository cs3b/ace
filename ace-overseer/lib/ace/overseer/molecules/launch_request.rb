# frozen_string_literal: true

require "json"
require "digest"
require "ace/assign/authority/prepared_work"
require "ace/assign/authority/private_directory"

module Ace
  module Overseer
    module Molecules
      # Retained inputs, never an authority grant or an attempt/progress ledger.
      class LaunchRequest
        KEYS = %w[version project_id mapping_id assignment_id task_id scope base_head mutation_id definition_bytes definition_sha256 prepared_bundle].sort.freeze
        BUNDLE_KEYS = %w[filename bytes sha256].sort.freeze
        MAX_REQUEST = 131_072
        MAX_DEFINITION = 32_768
        MAX_BUNDLE = 64 * 1024 * 1024
        SHA = /\A[0-9a-f]{64}\z/
        GIT = /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/
        MUTATION = /\A[a-zA-Z0-9][a-zA-Z0-9._-]{0,115}\z/

        def initialize(root:)
          @root = Ace::Assign::Authority::PrivateDirectory.verify!(root)
        rescue Ace::Assign::AttemptErrors::ReceiptRejected => error
          raise Error, error.message
        end

        def publish(project_id:, mapping_id:, task_id:, base_head:, mutation_id:, prepared:)
          bundle = prepared.fetch("bundle")
          document = {"version" => 1, "project_id" => project_id, "mapping_id" => mapping_id,
            "assignment_id" => prepared.fetch("assignment_id"), "task_id" => task_id,
            "scope" => prepared.fetch("scope"), "base_head" => base_head, "mutation_id" => mutation_id,
            "definition_bytes" => prepared.fetch("definition_bytes"),
            "definition_sha256" => Digest::SHA256.hexdigest(prepared.fetch("definition_bytes")),
            "prepared_bundle" => {"filename" => "#{mutation_id}.prepared.bundle", "bytes" => prepared.fetch("bytes"), "sha256" => prepared.fetch("sha256")}}
          validate!(document)
          verify_bundle!(document, bundle)
          bytes = JSON.generate(document)
          raise Error, "Retained launch request exceeds bound" if bytes.bytesize > MAX_REQUEST
          request_path = File.join(@root, "#{mutation_id}.json")
          bundle_path = File.join(@root, document.fetch("prepared_bundle").fetch("filename"))
          sidecar_path = definition_path(document)
          [request_path, bundle_path, sidecar_path].each do |path|
            begin
              File.lstat(path)
              raise Error, "Retained launch invocation already exists"
            rescue Errno::ENOENT
              # Both names must be absent; exclusive creation closes the race.
            end
          end
          # Never overwrite either input. Failure can leave an unselected orphan;
          # it cannot create a different accepted invocation under the same ID.
          write_exclusive(bundle_path, bundle)
          write_exclusive(sidecar_path, document.fetch("definition_bytes"))
          write_exclusive(request_path, bytes)
          File.open(@root, File::RDONLY) { |directory| directory.fsync }
          load(request_path)
        rescue KeyError, JSON::GeneratorError, SystemCallError => error
          raise Error, "Retained launch publication failed: #{error.message}"
        end

        def load(path)
          path = File.expand_path(path)
          raise Error, "Retained launch request is outside its private owner" unless File.dirname(path) == @root
          bytes = held_read(path, MAX_REQUEST)
          value = JSON.parse(bytes, create_additions: false, max_nesting: 32, allow_duplicate_key: false, allow_comments: false)
          validate!(value)
          raise Error, "Retained launch filename differs" unless File.basename(path) == "#{value.fetch('mutation_id')}.json"
          freeze_value(value)
        rescue JSON::ParserError, KeyError, TypeError, SystemCallError => error
          raise Error, "Retained launch request is invalid: #{error.message}"
        end

        # Fresh launch requires the original complete bundle. Recovery only
        # loads the document and observes availability; it never reconstructs.
        def verify_fresh!(document)
          validate!(document)
          definition = held_read(definition_path(document), MAX_DEFINITION)
          raise Error, "Retained definition sidecar differs" unless definition == document.fetch("definition_bytes")
          bytes = held_read(File.join(@root, document.fetch("prepared_bundle").fetch("filename")), MAX_BUNDLE)
          verify_bundle!(document, bytes)
          bytes.freeze
        end

        def definition_path(document)
          validate!(document)
          File.join(@root, document.fetch("mutation_id") + ".definition.json")
        end

        def definition_availability(document)
          bytes = held_read(definition_path(document), MAX_DEFINITION)
          bytes == document.fetch("definition_bytes") ? "available" : "mismatch"
        rescue Errno::ENOENT
          "unavailable"
        rescue Error, SystemCallError
          "mismatch"
        end

        def bundle_availability(document)
          validate!(document)
          bytes = held_read(File.join(@root, document.fetch("prepared_bundle").fetch("filename")), MAX_BUNDLE)
          ref = document.fetch("prepared_bundle")
          bytes.bytesize == ref.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == ref.fetch("sha256") ? "available" : "mismatch"
        rescue Errno::ENOENT
          "unavailable"
        rescue Error, SystemCallError
          "mismatch"
        end

        private

        def validate!(value)
          closed!(value, KEYS)
          raise Error, "Retained launch version differs" unless value["version"].is_a?(Integer) && value["version"] == 1
          %w[project_id mapping_id assignment_id task_id].each do |key|
            raise Error, "Retained launch identity is invalid" unless value[key].is_a?(String) && value[key].match?(Ace::Assign::Authority::PreparedWork::TOKEN)
          end
          raise Error, "Retained launch mutation is invalid" unless value["mutation_id"].is_a?(String) && value["mutation_id"].match?(MUTATION)
          raise Error, "Retained launch scope is invalid" unless value["scope"].is_a?(String) && value["scope"].match?(Ace::Assign::Authority::PreparedWork::SCOPE)
          raise Error, "Retained launch base is invalid" unless value["base_head"].is_a?(String) && value["base_head"].match?(GIT)
          definition = value["definition_bytes"]
          raise Error, "Retained launch definition exceeds bound" unless definition.is_a?(String) && definition.bytesize.between?(1, MAX_DEFINITION) && definition.valid_encoding?
          raise Error, "Retained launch definition digest differs" unless value["definition_sha256"].is_a?(String) && value["definition_sha256"].match?(SHA) && Digest::SHA256.hexdigest(definition) == value["definition_sha256"]
          parsed = JSON.parse(definition, create_additions: false, max_nesting: 32, allow_duplicate_key: false, allow_comments: false)
          unless parsed.is_a?(Hash) && parsed.values_at("session_id", "project_id", "task_id") == value.values_at("assignment_id", "project_id", "task_id")
            raise Error, "Retained definition association differs"
          end
          reference = parsed.fetch("prepared_work")
          closed!(reference, %w[version task_id scope prepared_head prepared_tree manifest_bytes manifest_sha256 selection_sha256].sort)
          unless reference["version"].is_a?(Integer) && reference["version"] == 1 && reference.values_at("task_id", "scope") == value.values_at("task_id", "scope") &&
              %w[prepared_head prepared_tree].all? { |key| reference[key].is_a?(String) && reference[key].match?(/\A[0-9a-f]{40}\z/) } &&
              reference["manifest_bytes"].is_a?(Integer) && reference["manifest_bytes"].between?(1, MAX_DEFINITION) &&
              %w[manifest_sha256 selection_sha256].all? { |key| reference[key].is_a?(String) && reference[key].match?(SHA) }
            raise Error, "Retained prepared selection differs"
          end
          bundle = value["prepared_bundle"]
          closed!(bundle, BUNDLE_KEYS)
          unless bundle["filename"] == "#{value['mutation_id']}.prepared.bundle" && bundle["bytes"].is_a?(Integer) && bundle["bytes"].between?(1, MAX_BUNDLE) && bundle["sha256"].is_a?(String) && bundle["sha256"].match?(SHA)
            raise Error, "Retained bundle reference differs"
          end
          value
        rescue JSON::ParserError, KeyError, TypeError
          raise Error, "Retained launch definition is invalid"
        end

        def verify_bundle!(document, bytes)
          ref = document.fetch("prepared_bundle")
          raise Error, "Retained bundle bytes differ" unless bytes.is_a?(String) && bytes.bytesize == ref.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == ref.fetch("sha256")
          reference = JSON.parse(document.fetch("definition_bytes")).fetch("prepared_work")
          work = Ace::Assign::Authority::PreparedWork.admit(bytes: bytes, head: reference.fetch("prepared_head"), tree: reference.fetch("prepared_tree"), sha256: ref.fetch("sha256"), size: ref.fetch("bytes"), root: @root)
          unless work.definition_bytes(head: reference.fetch("prepared_head"), tree: reference.fetch("prepared_tree")) == document.fetch("definition_bytes")
            raise Error, "Retained prepared definition differs"
          end
        rescue ArgumentError, Ace::Assign::AttemptErrors::ReceiptRejected => error
          raise Error, "Retained prepared work is invalid: #{error.message}"
        end

        def held_read(path, limit)
          File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
            before = file.stat
            unless before.file? && before.uid == Process.uid && (before.mode & 0077).zero? && before.size.between?(1, limit)
              raise Error, "Retained input is not a bounded private regular file"
            end
            bytes = file.read(limit + 1)
            after = file.stat
            fields = %i[dev ino mode uid gid size mtime ctime]
            unless fields.all? { |field| before.public_send(field) == after.public_send(field) } && bytes.bytesize == before.size
              raise Error, "Retained input changed during held read"
            end
            bytes
          end
        end

        def write_exclusive(path, bytes)
          File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0600) do |file|
            file.write(bytes)
            file.flush
            file.fsync
          end
        end

        def closed!(value, keys)
          raise Error, "Retained launch fields differ" unless value.is_a?(Hash) && value.keys.all? { |key| key.is_a?(String) } && value.keys.sort == keys
        end

        def freeze_value(value)
          case value
          when Hash then value.each { |key, item| freeze_value(key); freeze_value(item) }
          when Array then value.each { |item| freeze_value(item) }
          end
          value.freeze
        end
      end
    end
  end
end
