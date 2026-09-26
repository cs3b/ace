# frozen_string_literal: true

require "securerandom"
require "fileutils"
require_relative "errors"
require_relative "identity"
require_relative "atomic_json"
require_relative "kinds"
require_relative "binding"
require_relative "effects"

module Ace
  module Hitl
    module Lifecycle
      # The generic, file-backed HITL request lifecycle (spec 8wm.t.y21
      # §3): create/pending/states/deliver/consume/cancel. Time never
      # ends a request (W651): only an answer, its consumption, or an
      # explicit audited cancellation removes one. All terminal
      # transitions share one per-request flock, the same transaction
      # boundary the lab-side stop protocol uses.
      class Store
        MAX_ANSWER = 4096
        MAX_PLAN_QUESTION = 240
        MAX_OPTIONS = 8
        MAX_OPTION = 80
        PUBLIC_MODE = 0o440
        ANSWER_MODE = 0o400
        REQUEST_MODE = 0o600
        CONSUME_POLL_SECONDS = 1

        # Pinned directory modes (spec §2): everything 0700 except the
        # public projection (0755). Enforced umask-proof at first create
        # (review F6 on W696).
        ROOT_MODE = 0o700
        DIR_MODES = {
          "requests" => 0o700,
          "secrets" => 0o700,
          "answers" => 0o700,
          "public" => 0o755,
          "effects" => 0o700
        }.freeze

        DEFAULT_ADMIN_USER = "lab-admin"
        DEFAULT_GROUP = "lab-control"

        attr_reader :root, :binding

        # The escalation spool seam (spec 8wm.t.y21 §1): the generic core
        # records deduped escalation state; the wake/spool glue stays
        # lab-side and wires in through this callable. No default spool.
        attr_accessor :escalation_sink

        def initialize(root:, binding:, admin_user: DEFAULT_ADMIN_USER,
          group: DEFAULT_GROUP, ownership: AtomicJson::DEFAULT_OWNERSHIP,
          identity: Identity, poll_seconds: CONSUME_POLL_SECONDS)
          raise ArgumentError, "a binding policy is required (fail closed without one)" unless binding

          @root = Pathname.new(root)
          @binding = binding
          @admin_user = admin_user
          @group = group
          @ownership = ownership
          @identity = identity
          @poll_seconds = poll_seconds
        end

        # ---- requester side ------------------------------------------------

        def create(id:, work:, attempt:, plan:, question:, ace_hitl_id:, project: "ace", harness: DEFAULT_ADMIN_USER,
          kind: "text", options: [], effect: nil)
          requester = @identity.username
          request_id = safe_id(id)
          unless Kinds::WORK_ID.match?(work)
            raise StateError, "invalid work id"
          end
          unless attempt && Kinds::ATTEMPT_ID.match?(attempt)
            raise StateError, "HITL request requires the exact active Attempt id"
          end
          unless Kinds::SAFE_LABEL.match?(project) && Kinds::SAFE_LABEL.match?(harness)
            raise StateError, "invalid project or harness label"
          end
          plan = plan.to_s.strip
          question = question.to_s.strip
          if plan.empty? || plan.length > MAX_PLAN_QUESTION ||
              question.empty? || question.length > MAX_PLAN_QUESTION
            raise StateError, "plan and question must contain 1-#{MAX_PLAN_QUESTION} characters"
          end
          options = Array(options).map(&:strip)
          if options.length > MAX_OPTIONS || options.any? { |item| item.empty? || item.length > MAX_OPTION }
            raise StateError, "options must contain at most eight 1-#{MAX_OPTION} character values"
          end
          if kind == "secret"
            raise StateError, "secret HITL must use the approved otp kind"
          end
          unless Kinds.valid?(kind)
            raise StateError, "unknown HITL kind: #{kind}"
          end
          if Kinds.secret?(kind)
            unless options.empty?
              raise StateError, "OTP requests must not offer choices"
            end
            validate_request_binding(work, attempt, project, requester)
          elsif requester != @admin_user
            validate_request_binding(work, attempt, project, requester)
          end

          value = {
            "id" => request_id,
            "work" => work,
            "attempt" => attempt,
            "project" => project,
            "harness" => harness,
            "kind" => kind,
            "sensitive" => Kinds.secret?(kind),
            "plan" => plan,
            "question" => question,
            "options" => options,
            "ace_hitl_id" => ace_hitl_id,
            "requester" => requester,
            "created_at" => Time.now.to_i
          }
          Effects.validate_declaration!(effect) if effect
          value["effect"] = Effects.normalized_declaration(effect) if effect

          request_path = requests_dir.join("#{request_id}.json")
          raise StateError, "HITL request already exists" if request_path.exist?

          ensure_layout!
          begin
            # link(2) is the create-once commit point: rename(2) would
            # silently let a concurrent duplicate-id create overwrite the
            # winner (review F8 on W696).
            AtomicJson.call(request_path, value, mode: REQUEST_MODE,
              ownership_strategy: @ownership, exclusive: true)
          rescue Errno::EEXIST
            raise StateError, "HITL request already exists"
          end
          update_public(value, "created")
          {
            "id" => request_id,
            "work" => work,
            "attempt" => attempt,
            "requested" => true
          }
        end

        # Consumes the answer for one requester-owned request. Without a
        # positive timeout the wait is indefinite; a timeout bounds ONLY
        # this local wait and never cancels the request (W651).
        def consume(id, timeout: 0)
          request_id = safe_id(id)
          value = load_request(request_id)
          requester_gate!(value)
          deadline = timeout.positive? ? Time.now.to_i + timeout : nil
          loop do
            answer = nil
            with_request_lock(request_id) do
              value = load_request(request_id)
              requester_gate!(value)
              verify_active!(value)
              answer = read_answer(value)
              unless answer
                next
              end

              # The terminal transition commits under the same per-request
              # flock as deliver/cancel (spec §3): a concurrent cancel
              # must not interleave between reading the answer and
              # removing the request (review F5 on W696).
              update_public(value, "consumed")
              remove_request(value, keep_public: true)
            end
            if answer
              return {
                "id" => request_id,
                "work" => value["work"],
                "attempt" => value["attempt"],
                "answer" => answer,
                "sensitive" => value["sensitive"] == true
              }
            end

            break if deadline && Time.now.to_i > deadline

            sleep(@poll_seconds)
          end
          raise StateError, "timed out waiting for HITL answer; the request remains pending"
        end

        # The only way to abandon a request: explicit, audited
        # cancellation (W651). Time never cancels anything.
        def cancel(id, reason: "")
          request_id = safe_id(id)
          value = load_request(request_id)
          unless @identity.root? || @identity.username == value["requester"].to_s
            raise PermissionError, "only the requesting role can cancel this request"
          end
          cancelled_by = @identity.username
          audit = {"cancelled_by" => cancelled_by, "reason" => reason.to_s.strip.empty? ? "unspecified" : reason.to_s.strip}
          with_request_lock(request_id) do
            value = load_request(request_id)
            update_public(value, "cancelled", audit: audit)
            remove_request(value, keep_public: true)
          end
          {
            "id" => request_id,
            "work" => value["work"],
            "attempt" => value["attempt"],
            "cancelled" => true,
            "cancelled_by" => cancelled_by,
            "reason" => audit["reason"]
          }
        end

        # ---- host-broker side (root-only) ----------------------------------

        # Answer one pending request as the host broker. The answer is
        # ALWAYS relayed unchanged; the declared effect callback (if any)
        # then executes inside the same locked critical section.
        def deliver(id, answer_reader)
          require_root!("deliver")
          request_id = safe_id(id)
          value = load_request(request_id)
          if value["sensitive"] == true && !Kinds.secret?(value["kind"].to_s)
            raise StateError, "secret HITL answers are forbidden"
          end
          raise StateError, "HITL request already has an answer" if answer_path(value).exist?

          answer = read_bounded_answer(answer_reader)
          Kinds.check_answer!(value["kind"].to_s, answer)
          requester_uid, requester_gid = @identity.user_ids(value["requester"])
          with_request_lock(request_id) do
            value = load_request(request_id)
            raise StateError, "HITL request already has an answer" if answer_path(value).exist?
            begin
              binding.require_active(work: value["work"], attempt: value["attempt"])
            rescue BindingError
              update_public(value, "cancelled")
              remove_request(value, keep_public: true)
              raise
            end
            write_answer(value, answer, requester_uid, requester_gid)
            update_public(value, "answer-delivered")
            Effects.run(
              self, value, answer,
              requester_uid: requester_uid, requester_gid: requester_gid
            )
          end
          {
            "id" => request_id,
            "work" => value["work"],
            "attempt" => value["attempt"],
            "delivered" => true,
            "sensitive" => value["sensitive"] == true
          }
        ensure
          answer&.clear
        end

        # Answerable requests; never purges or cancels anything (W651).
        def pending
          require_root!("pending")
          requests_dir.glob("*.json").sort.filter_map do |path|
            value = AtomicJson.read(path)
            next unless value.is_a?(Hash)

            value if !answer_path(value).exist?
          end
        end

        # All public lifecycle records.
        def states
          require_root!("states")
          public_dir.glob("*.json").sort.filter_map do |path|
            AtomicJson.read(path)
          end
        end

        # ---- shared internals ----------------------------------------------

        def requests_dir
          @root.join("requests")
        end

        def secrets_dir
          @root.join("secrets")
        end

        def answers_dir
          @root.join("answers")
        end

        def public_dir
          @root.join("public")
        end

        def effects_dir
          @root.join("effects")
        end

        def answer_path(value)
          directory = (value["sensitive"] == true) ? secrets_dir : answers_dir
          directory.join("#{safe_id(value["id"])}.answer")
        end

        def request_path(request_id)
          requests_dir.join("#{safe_id(request_id)}.json")
        end

        # Provision the store layout with the pinned directory modes
        # (spec §2; review F6 on W696). mkdir(2) bakes in the process
        # umask, so every directory is chmod'd explicitly after mkdir —
        # the same umask-proof pattern as the atomic writer.
        def ensure_layout!
          FileUtils.mkdir_p(@root)
          File.chmod(ROOT_MODE, @root)
          DIR_MODES.each do |name, mode|
            dir = @root.join(name)
            FileUtils.mkdir_p(dir)
            File.chmod(mode, dir)
          end
          nil
        end

        def public_path(request_id)
          public_dir.join("#{safe_id(request_id)}.json")
        end

        # The public lifecycle projection: merge-on-write (audit fields
        # merge into the base record), 0440, owner = requester,
        # group = the control group. Never carries answer content.
        def update_public(value, state, audit: nil)
          request_id = safe_id(value["id"].to_s)
          public = {
            "id" => request_id,
            "work" => value["work"].to_s,
            "attempt" => value["attempt"].to_s,
            "project" => value["project"].to_s,
            "harness" => value["harness"].to_s,
            "kind" => value["kind"].to_s,
            "state" => state,
            "created_at" => Integer(value["created_at"]),
            "updated_at" => Time.now.to_i
          }
          public["effect_state"] = value["effect_state"] if value["effect_state"]
          public.update(audit) if audit
          ownership = ownership_for(value)
          AtomicJson.call(
            public_path(request_id), public,
            mode: PUBLIC_MODE, ownership: ownership, ownership_strategy: @ownership
          )
        end

        def remove_request(value, keep_public: false)
          request_id = safe_id(value["id"].to_s)
          request_path(request_id).unlink if request_path(request_id).exist?
          public_path(request_id).unlink if !keep_public && public_path(request_id).exist?
          answer_path(value).unlink if answer_path(value).exist?
          nil
        end

        # The per-request flock: the transaction boundary shared with
        # deliver/consume/cancel and the lab-side stop protocol. A record
        # that vanished under a concurrent cancel is a StateError, never
        # a raw Errno escape (review F5 on W696).
        def with_request_lock(request_id)
          path = request_path(request_id)
          begin
            File.open(path, "r") do |file|
              file.flock(File::LOCK_EX)
              yield path
            ensure
              file.flock(File::LOCK_UN)
            end
          rescue Errno::ENOENT
            raise StateError, "unknown or invalid HITL request"
          end
        end

        def load_request(request_id)
          path = request_path(request_id)
          raise StateError, "unknown or invalid HITL request" unless path.exist?

          value = AtomicJson.read(path)
          raise StateError, "unknown or invalid HITL request" unless value.is_a?(Hash)

          value
        end

        def read_answer(value)
          path = answer_path(value)
          return nil unless path.exist?

          answer = path.read
          Kinds.check_answer!(value["kind"].to_s, answer)
          answer
        end

        def ownership_for(value)
          uid, _ = @identity.user_ids(value["requester"].to_s)
          AtomicJson::Ownership.new(uid: uid, gid: group_id)
        rescue Lifecycle::Error
          nil
        end

        def group_id
          @group_id ||= @identity.group_id(@group)
        end

        def require_root!(operation)
          unless @identity.root?
            raise PermissionError, "#{operation} is a host-broker operation"
          end
        end

        def safe_id(value)
          id = value.to_s
          raise StateError, "invalid HITL request id" unless Kinds::REQUEST_ID.match?(id)

          id
        end

        private

        def validate_request_binding(work, attempt, project, requester)
          binding.validate_request(work: work, attempt: attempt, project: project, requester: requester)
        end

        def requester_gate!(value)
          unless @identity.username == value["requester"].to_s
            raise PermissionError, "only the requesting role can consume this answer"
          end
        end

        # Liveness re-verification inside the locked critical section:
        # a terminal attempt cancels the request and fails closed.
        def verify_active!(value)
          binding.require_active(work: value["work"], attempt: value["attempt"])
        rescue BindingError
          update_public(value, "cancelled")
          remove_request(value, keep_public: true)
          raise
        end

        def read_bounded_answer(reader)
          answer = reader.call(MAX_ANSWER + 1).to_s.strip
          if answer.empty? || answer.length > MAX_ANSWER || answer.include?("\u0000")
            raise AnswerError, "answer must contain 1-#{MAX_ANSWER} characters"
          end

          answer
        end

        # Relay the answer 0400 owner=requester through an O_EXCL|O_NOFOLLOW
        # temporary; the content never appears in any projection or log.
        def write_answer(value, answer, requester_uid, requester_gid)
          destination = answer_path(value)
          temporary = destination.parent.join(".#{safe_id(value["id"])}.#{$PROCESS_ID}")
          flags = File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW
          fd = IO.sysopen(temporary, flags, ANSWER_MODE)
          begin
            io = IO.for_fd(fd, mode: "w")
            io.write(answer)
            io.flush
            io.fsync
            io.close
          rescue
            begin
              temporary.unlink
            rescue
              nil
            end
            raise
          end
          @ownership.chown(temporary, AtomicJson::Ownership.new(uid: requester_uid, gid: requester_gid))
          File.chmod(ANSWER_MODE, temporary)
          File.rename(temporary, destination)
        ensure
          temporary.unlink if temporary&.exist?
        end
      end
    end
  end
end
