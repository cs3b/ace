# frozen_string_literal: true

require "json"
require_relative "errors"
require_relative "../atoms/hitl_effect_validator"

module Ace
  module Hitl
    module Lifecycle
      # The requester-declared answer-effect layer (spec 8wm.t.y21 §5;
      # recovered from the deployed 8wl.t.ga9 contract). A request may
      # declare a callback that executes exactly once when the answer
      # arrives — always AFTER the answer is relayed — AS THE REQUESTER,
      # through exec-style argv (a shell never sees the answer). The
      # answer content and the substituted argv never appear in any log;
      # full attempts live only in the root-only effects log.
      module Effects
        DEFAULT_TIMEOUT_S = 120
        TERMINATE_GRACE_SECONDS = 0.2
        OUTCOME_OK = "callback-ok"
        OUTCOME_ESCALATED = "callback-escalated"

        # A Lifecycle::Error so every lifecycle caller's typed rescue
        # (notably the provider seam's orphan-event ask wrapper) catches
        # declaration violations instead of a raw backtrace escaping to
        # the CLI (review F-R1 on W696).
        DeclarationError = Class.new(Lifecycle::Error)

        module_function

        # Validated by Atoms::HitlEffectValidator at the CLI boundary;
        # the store re-applies the declaration checks so direct API use
        # cannot bypass the bounds. Declarations are never rewritten.
        def validate_declaration!(effect)
          match = effect[:match]&.to_s
          cwd = (effect[:cwd] || effect[:effect_cwd])&.to_s
          # cwd is a required declaration field (spec §5: {argv:, cwd:,
          # match:, timeout_s:}). A cwd-less declaration would otherwise
          # pass validation and fail at answer time as a misleading
          # Errno::ENOENT spawn escalation (review F-A on W696).
          if cwd.nil? || cwd.strip.empty?
            raise DeclarationError,
              "--effect-cwd is required for an effect callback (absolute path to an existing directory)"
          end
          Atoms::HitlEffectValidator.validate!(
            match: match,
            effect_args: Array(effect[:effect_args] || effect[:argv]).map(&:to_s),
            effect_cwd: cwd,
            effect_timeout: (effect[:timeout_s] || effect[:effect_timeout]).to_s
          )
        rescue Atoms::HitlEffectValidator::ValidationError => e
          raise DeclarationError, e.message
        end

        # The persisted record shape, byte-compatible with the deployed
        # contract: {argv:, cwd:, match:, timeout_s:}.
        def normalized_declaration(effect)
          timeout = effect[:timeout_s] || effect[:effect_timeout] || DEFAULT_TIMEOUT_S
          {
            "argv" => Array(effect[:effect_args] || effect[:argv]).map(&:to_s),
            "cwd" => (effect[:cwd] || effect[:effect_cwd]).to_s,
            "match" => effect[:match]&.to_s,
            "timeout_s" => Integer(timeout)
          }
        end

        # Executed inside deliver's locked critical section, after the
        # answer is relayed. Exactly one attempt; failure escalates once.
        def run(store, value, answer, requester_uid:, requester_gid:, identity: Identity,
          spawner: Process, group_dropper: nil)
          declaration = value["effect"]
          return nil unless declaration.is_a?(Hash) && Array(declaration["argv"]).any?

          if !identity.root? && requester_uid != identity.euid
            raise Lifecycle::PermissionError,
              "effect callback requires the requester's identity and root authority to drop to it"
          end

          match_ok = declaration["match"].nil? || fullmatch?(declaration["match"], answer)
          attempt = {
            "at" => Time.now.to_i,
            "match_ok" => match_ok,
            "timed_out" => false,
            "exit_status" => nil,
            "duration_s" => nil
          }
          if match_ok
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            begin
              status, timed_out = execute(
                declaration, answer, requester_uid, requester_gid, spawner,
                group_dropper: group_dropper
              )
            rescue SystemCallError => e
              # A spawn/wait failure (missing binary, non-executable
              # argv, EPERM) must never escape deliver AFTER the answer
              # was relayed: the operator signal would be silently lost.
              # It is an escalation outcome exactly like a timeout or a
              # nonzero exit (spec §5; review F2 on W696).
              attempt["error"] = e.class.name
              status = nil
              timed_out = false
            end
            attempt["timed_out"] = timed_out
            attempt["exit_status"] = status
            attempt["duration_s"] = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(3)
          end
          attempt["outcome"] = outcome_of(attempt)

          record_effect_attempt(store, value, attempt)
          effect_state = (attempt["outcome"] == "ok") ? OUTCOME_OK : OUTCOME_ESCALATED
          value["effect_state"] = effect_state
          store.update_public(value, "answer-delivered")
          if effect_state == OUTCOME_ESCALATED
            escalate_once(store, value, attempt)
          end
          effect_state
        end

        def outcome_of(attempt)
          (attempt["match_ok"] && !attempt["timed_out"] && attempt["exit_status"] == 0) ? "ok" : "escalated"
        end

        # The root-only effects log: redacted attempts (no answer, no
        # argv) plus the deduped escalation marker.
        def record_effect_attempt(store, value, attempt)
          store.effects_dir.mkpath
          path = store.effects_dir.join("#{value["id"]}.json")
          record = AtomicJson.read(path)
          record = {"id" => value["id"], "attempts" => [], "escalated" => nil} unless record.is_a?(Hash)
          record["attempts"] << attempt
          if attempt["outcome"] != "ok" && record["escalated"].nil?
            record["escalated"] = {"at" => Time.now.to_i, "outcome" => attempt["outcome"]}
          end
          AtomicJson.call(path, record, mode: 0o600)
          nil
        end

        # The deduped escalation: recorded once per request in the
        # effects log; the wake/spool glue stays behind the sink seam.
        def escalate_once(store, value, attempt)
          return if value["escalation_spooled"]

          sink = store.escalation_sink
          value["escalation_spooled"] = true
          return unless sink

          sink.call(
            request_id: value["id"],
            work: value["work"],
            attempt: value["attempt"],
            project: value["project"],
            outcome: attempt["outcome"]
          )
        end

        # Python re.fullmatch equivalent: the whole answer must match.
        def fullmatch?(source, answer)
          Regexp.new("\\A(?:#{source})\\z").match?(answer)
        rescue RegexpError
          false
        end

        # Exec-style spawn, never a shell. {answer} substitutes once per
        # element as a plain string replace. Output is discarded
        # (redaction). Process.spawn applies only setgid/setuid, so the
        # supplementary-group drop happens around the spawn window (see
        # drop_child_groups) and the forked child inherits the dropped
        # list. Returns [exit_status, timed_out].
        def execute(declaration, answer, requester_uid, requester_gid, spawner = Process,
          group_dropper: nil)
          group_dropper ||= method(:drop_child_groups)
          # Block form: the answer is inserted literally. The
          # replacement-string form would interpret backslash sequences
          # in the answer as backreferences (review 8wq2ztty on PR#336).
          argv = declaration["argv"].map { |element| element.gsub("{answer}") { answer } }
          timeout = declaration["timeout_s"] || DEFAULT_TIMEOUT_S
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
          status = nil
          timed_out = false
          group_dropper.call(requester_gid) do
            # [cmd, cmd] forces exec/argv semantics: a single-element
            # argv would otherwise be handed to a shell as a command
            # string (review 8wq2ztu2 on PR#336), and a substituted
            # answer must never become shell syntax.
            #
            # pgroup: true makes the child a process group leader so the
            # timeout can signal its whole group (review 8wq2zttw on
            # PR#336).
            pid = spawner.spawn(
              [argv.first, argv.first],
              *argv.drop(1),
              chdir: declaration["cwd"],
              gid: requester_gid,
              uid: requester_uid,
              pgroup: true,
              out: File::NULL,
              err: File::NULL
            )
            loop do
              _, status = spawner.waitpid2(pid, Process::WNOHANG)
              break if status

              if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
                timed_out = true
                # -pid addresses the process group: a callback that
                # forked leaves no descendants running after the
                # timeout. ESRCH means the group is already gone; macOS
                # additionally raises EPERM when signaling a group whose
                # only remaining members are zombies — both are fine,
                # the direct child is reaped by the wait below.
                begin
                  spawner.kill("TERM", -pid)
                rescue Errno::ESRCH, Errno::EPERM
                end
                sleep_after_terminate
                begin
                  spawner.kill("KILL", -pid)
                rescue Errno::ESRCH, Errno::EPERM
                end
                _, status = spawner.waitpid2(pid)
                break
              end
              sleep 0.05
            end
          end
          [status&.exitstatus, timed_out]
        end

        # Supplementary-group isolation for the effect child (spec §5;
        # review F7 on W696): spawn has no groups hook, so root swaps the
        # process supplementary list for exactly the requester's group
        # for the duration of the block and restores it afterwards; the
        # child inherits the dropped list. A non-root process has nothing
        # to drop and would hit EPERM, so it yields unchanged.
        def drop_child_groups(gid)
          return yield unless Process.euid.zero?

          previous = Process.groups
          Process::Sys.setgroups([gid])
          begin
            yield
          ensure
            Process::Sys.setgroups(previous)
          end
        end

        def sleep_after_terminate
          sleep(TERMINATE_GRACE_SECONDS)
        end
      end
    end
  end
end
