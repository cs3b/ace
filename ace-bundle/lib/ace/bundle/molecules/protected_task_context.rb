# frozen_string_literal: true
require "json"
require "tmpdir"
require "ace/runtime/molecules/protected_task_context_entry"
require "ace/herdr/molecules/bounded_process"

module Ace
  module Bundle
    module Molecules
      # Fixed installed CLI boundary. Bundle does not import Assign, select its
      # roster or resolve task context through project command templates.
      class ProtectedTaskContext
        TOKEN = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,199}\z/
        SCOPE = /\A[0-9]+(?:\.[0-9]+)*\z/
        SHA = /\A[0-9a-f]{64}\z/
        TEXT_LIMIT = 1_048_576
        RESPONSE_LIMIT = 6_307_840
        SELECTION_LIMIT = 65_536
        PRINCIPAL_LIMIT = 1_024
        STDERR_LIMIT = 16_384
        DEADLINE = 30
        SELECTOR_FIELDS = %w[mapping_id assignment_id attempt_id scope].freeze
        ASSOCIATION_FIELDS = (SELECTOR_FIELDS + %w[definition_digest selection_sha256]).freeze

        def initialize(entry_owner: Ace::Runtime::Molecules::ProtectedTaskContextEntry.new,
          runner: Ace::Herdr::Molecules::BoundedProcess, uid: Process.uid, env: ENV)
          @owner, @runner, @uid, @env = entry_owner, runner, uid, env
        end

        # nil means genuinely ordinary; every installed failure raises.
        def load(uri, options: {})
          selected = selected?(options)
          @owner.with do |discovery|
            unless discovery
              unavailable!("installed entry is absent") if selected
              next nil
            end
            principal = invoke(discovery, ["authority", "task-context-principal"], PRINCIPAL_LIMIT)
            object!(principal, %w[schema uid protected_worker])
            unless principal.fetch("schema") == "ace.assign.task-context-principal/v1" &&
                principal.fetch("uid").is_a?(Integer) && principal.fetch("uid") == @uid && [true, false].include?(principal.fetch("protected_worker"))
              mismatch!("actual caller classification")
            end
            next nil unless principal.fetch("protected_worker") || selected
            task = uri.delete_prefix("task://")
            mismatch!("task URI") unless uri.start_with?("task://") && task.match?(TOKEN)
            selectors, argv = selectors!(options)
            selection = invoke(discovery, ["authority", "task-context-selection", *argv], SELECTION_LIMIT)
            object!(selection, ASSOCIATION_FIELDS + %w[schema task_context_entry])
            association!(selection, selectors, "ace.assign.task-context-selection/v1")
            original = validated_output_pin!(selection.fetch("task_context_entry"))
            manifest_hint!(original)
            result = invoke(original, ["authority", "task-context", *argv, "--task", task], RESPONSE_LIMIT)
            object!(result, ASSOCIATION_FIELDS + %w[schema task_id text])
            association!(result, selectors, "ace.assign.prepared-task-context/v1")
            unless result.slice(*ASSOCIATION_FIELDS) == selection.slice(*ASSOCIATION_FIELDS) && result.fetch("task_id") == task
              mismatch!("original prepared response association")
            end
            text = result.fetch("text")
            mismatch!("captured text bound") unless text.is_a?(String) && text.valid_encoding? && text.bytesize.between?(1, TEXT_LIMIT)
            text.freeze
          end
        rescue Ace::Runtime::Error, IOError, SystemCallError, Timeout::Error, Ace::Herdr::Molecules::BoundedProcess::PostLaunchError => error
          unavailable!(error.message)
        rescue KeyError, TypeError, NoMethodError, ArgumentError, JSON::ParserError, EncodingError
          mismatch!("closed task-context response")
        end

        private

        def selected?(options)
          options.values_at(:mapping, :assignment, :attempt).any? { |value| value && !value.to_s.empty? } ||
            %w[ACE_ASSIGN_LAUNCH_MAPPING ACE_ASSIGN_ASSIGNMENT_ID ACE_ASSIGN_ATTEMPT_ID ACE_ASSIGN_TASK_CONTEXT_ENTRY].any? { |key| !@env[key].to_s.empty? }
        end

        def selectors!(options)
          mapping = hint!(options[:mapping], "ACE_ASSIGN_LAUNCH_MAPPING")
          attempt = hint!(options[:attempt], "ACE_ASSIGN_ATTEMPT_ID")
          scoped = hint!(options[:assignment], "ACE_ASSIGN_DEFAULT_TARGET", token: false)
          assignment, scope = scoped.split("@", 2)
          mismatch!("explicit scoped original assignment") unless assignment&.match?(TOKEN) && scope&.match?(SCOPE)
          bare_hint = @env["ACE_ASSIGN_ASSIGNMENT_ID"].to_s
          mismatch!("assignment hint differs") unless bare_hint.empty? || bare_hint == assignment
          [{"mapping_id" => mapping, "assignment_id" => assignment, "attempt_id" => attempt, "scope" => scope},
            ["--mapping", mapping, "--assignment", scoped, "--attempt", attempt]]
        end

        def hint!(explicit, key, token: true)
          hint = @env[key].to_s
          value = explicit || hint
          unless value.is_a?(String) && value.encoding == Encoding::UTF_8 && value.valid_encoding? && !value.empty? &&
              (hint.empty? || hint == value) && (!token || value.match?(TOKEN))
            mismatch!("complete original selectors required")
          end
          value
        end

        def association!(record, selectors, schema)
          unless record.fetch("schema") == schema && record.slice(*SELECTOR_FIELDS) == selectors &&
              %w[definition_digest selection_sha256].all? { |key| record.fetch(key).is_a?(String) && record.fetch(key).match?(SHA) }
            mismatch!("original prepared selectors or digest")
          end
        end

        def manifest_hint!(pin)
          hint = @env["ACE_ASSIGN_TASK_CONTEXT_ENTRY"].to_s
          return if hint.empty?
          mismatch!("manifest hint bound") if hint.bytesize > SELECTION_LIMIT
          reference = JSON.parse(hint, create_additions: false, max_nesting: 8, allow_duplicate_key: false, allow_comments: false)
          candidate = validated_output_pin!({"manifest" => reference, "wrapper" => pin.fetch("wrapper")})
          mismatch!("manifest hint differs from original") unless candidate == pin
        end

        def validated_output_pin!(pin)
          @owner.validate_pin!(pin)
        rescue Ace::Runtime::Error, KeyError, TypeError, NoMethodError, ArgumentError
          mismatch!("original entry reference fields")
        end

        def invoke(pin, arguments, limit)
          @owner.with_entry(pin) do |entry|
            with_selector(entry.pin.fetch("manifest")) do |selector|
              result = @runner.call(["/proc/self/fd/4", "-I", "-S", "-B", "-", *arguments],
                stdin_data: entry.body, timeout_s: DEADLINE, output_limit: limit, stderr_limit: STDERR_LIMIT,
                descriptor_mapping: {4 => entry.interpreter, 5 => selector}, environment: {}, chdir: "/", cleanup_group: true)
              unavailable!("fixed task-context command failed") unless result.status&.success?
              mismatch!("fixed task-context output was truncated") if result.oversized
              bytes = result.stdout
              unless bytes.is_a?(String) && bytes.bytesize.between?(1, limit)
                mismatch!("fixed task-context output bound")
              end
              text = bytes.dup.force_encoding(Encoding::UTF_8)
              unless text.valid_encoding? && text.end_with?("\n") && text.count("\n") == 1
                mismatch!("fixed task-context output framing")
              end
              record = JSON.parse(text, create_additions: false, max_nesting: 16, allow_duplicate_key: false, allow_comments: false)
              mismatch!("fixed task-context output is not compact JSON") unless JSON.generate(record) + "\n" == text
              record
            end
          end
        end

        # This private temporary transports only an untrusted manifest REF. The
        # accepted code/interpreter come from retained protected handles above.
        def with_selector(reference)
          bytes = JSON.generate(reference) + "\n"
          mismatch!("entry selector bound") if bytes.bytesize > SELECTION_LIMIT
          Dir.mktmpdir("ace-task-context-", "/tmp") do |directory|
            path = File.join(directory, "selector.json")
            File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |writer|
              writer.write(bytes); writer.flush
              File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |reader|
                unless reader.stat.file? && reader.stat.uid == Process.uid && (reader.stat.mode & 0o077).zero? &&
                    [reader.stat.dev, reader.stat.ino, reader.stat.size] == [writer.stat.dev, writer.stat.ino, bytes.bytesize]
                  unavailable!("private selector descriptor differs")
                end
                File.unlink(path)
                yield reader
              end
            end
          end
        end

        def object!(record, fields)
          mismatch!("closed fixed task-context fields") unless record.is_a?(Hash) && record.keys.sort == fields.sort
        end

        def mismatch!(detail)
          raise Ace::Bundle::Error, "prepared_input_mismatch: #{detail}"
        end

        def unavailable!(detail)
          raise Ace::Bundle::Error, "prepared_input_unavailable: #{detail}"
        end
      end
    end
  end
end
