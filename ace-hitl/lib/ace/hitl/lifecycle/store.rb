# frozen_string_literal: true

require "securerandom"
require "fileutils"
require_relative "errors"
require_relative "identity"
require_relative "peer"
require_relative "policy"
require_relative "atomic_json"
require_relative "kinds"
require_relative "binding"
require_relative "effects"
require_relative "otp_vault"

module Ace
  module Hitl
    module Lifecycle
      # The generic, file-backed HITL request lifecycle (spec 8wm.t.y21
      # §3, scoped by 8wq.t.34i): create/read/deliver/consume/cancel.
      # Time never ends a request (W651): only an answer, its
      # consumption, or an explicit audited cancellation removes one.
      # All terminal transitions share one stable per-request flock.
      #
      # The store is the PRIVATE state of one boundary process: every
      # caller is an authenticated identity (the service resolves kernel
      # peer credentials into a Peer and builds one store view per
      # connection). Role gates are exact:
      #
      # - create/read/consume/cancel: the requester of record only;
      # - deliver/pending/states: the configured transport policy only;
      # - every request is bound to a verified live attempt and that
      #   authority is re-held across each transition via the binding's
      #   with_active scope (the assignment exclusion), so stale, ended
      #   or replaced attempts cannot acquire new authority.
      class Store
        MAX_ANSWER = 4096
        # IO#read(limit) is byte-oriented, so the character limit is
        # enforced on a decoded string with this separate byte bound
        # (review 8wq2zttz on PR#336); 4 bytes per character is the
        # UTF-8 worst case.
        MAX_ANSWER_BYTES = MAX_ANSWER * 4
        MAX_PLAN_QUESTION = 240
        MAX_OPTIONS = 8
        MAX_OPTION = 80
        PUBLIC_MODE = 0o440
        ANSWER_MODE = 0o600
        REQUEST_MODE = 0o600
        TERMINAL_MODE = 0o600
        CONSUME_POLL_SECONDS = 1

        # Pinned directory modes (spec §2): the root is traverse-only
        # (0711) so the service-owned public projection stays reachable
        # without exposing any private directory; everything else is
        # 0700 except public (0755). Enforced umask-proof at first
        # create (review F6 on W696).
        ROOT_MODE = 0o711
        DIR_MODES = {
          "requests" => 0o700,
          "secrets" => 0o700,
          "answers" => 0o700,
          "public" => 0o755,
          "effects" => 0o700,
          "locks" => 0o700,
          "terminals" => 0o700
        }.freeze

        DEFAULT_GROUP = "lab-control"

        attr_reader :root, :binding, :policy

        # The escalation spool seam (spec 8wm.t.y21 §1): the generic core
        # records deduped escalation state; the wake/spool glue stays
        # lab-side and wires in through this callable. No default spool.
        attr_accessor :escalation_sink

        def initialize(root:, binding:, policy: AccessPolicy.new,
          identity: Identity, ownership: AtomicJson::DEFAULT_OWNERSHIP,
          poll_seconds: CONSUME_POLL_SECONDS, vault: :file)
          raise ArgumentError, "a binding policy is required (fail closed without one)" unless binding
          raise ArgumentError, "an access policy is required (fail closed without one)" unless policy

          @root = Pathname.new(root)
          @binding = binding
          @policy = policy
          @identity = identity
          @ownership = ownership
          @poll_seconds = poll_seconds
          @vault = vault == :file ? OtpVault::FileVault : vault
        end

        # ---- requester side ------------------------------------------------

        # Create one request bound to the exact live attempt of the
        # CALLING identity. Managed requests bind by assignment
        # (--assignment/--attempt/--project); the legacy lab path binds
        # by Work (kept until vs2 switches consumers). EVERY request
        # validates its binding — unknown identity/authority is an
        # error, never permission.
        def create(id:, attempt:, plan:, question:, ace_hitl_id:, project: "ace", harness: "lab-admin",
          work: nil, assignment: nil, kind: "text", options: [], effect: nil, otp: nil)
          requester = @identity.username
          request_id = safe_id(id)
          binding_kind = validate_binding_ids!(work, assignment, attempt)
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
            raise StateError, "OTP requests must not declare an effect callback" if effect
            challenge = normalize_otp_challenge!(otp)
          end

          validate_request_binding(binding_kind, work, assignment, attempt, project, requester)

          value = {
            "id" => request_id,
            "work" => work,
            "assignment" => assignment,
            "binding_kind" => binding_kind,
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
          value["otp"] = challenge if challenge
          Effects.validate_declaration!(effect) if effect
          value["effect"] = Effects.normalized_declaration(effect) if effect
          value["incarnation"] = SecureRandom.hex(8)

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
          initialize_projection!(value)
          {
            "id" => request_id,
            "work" => value["work"],
            "assignment" => value["assignment"],
            "attempt" => attempt,
            "requested" => true
          }
        end

        # Non-secret request facts for the requester of record (or the
        # transport). Never carries answer content.
        def read(id)
          request_id = safe_id(id)
          value = load_request(request_id)
          gate_read_access!(value)
          {
            "id" => request_id,
            "work" => value["work"],
            "assignment" => value["assignment"],
            "attempt" => value["attempt"],
            "project" => value["project"],
            "harness" => value["harness"],
            "kind" => value["kind"],
            "sensitive" => value["sensitive"] == true,
            "question" => value["question"],
            "options" => value["options"],
            "plan" => value["plan"],
            "otp" => value["otp"],
            "requester" => value["requester"],
            "state" => public_state(request_id, value),
            "effect" => value["effect_state"]
          }
        end

        # Consumes the answer for one requester-owned request. Without a
        # positive timeout the wait is indefinite; a timeout bounds ONLY
        # this local wait and never cancels the request (W651). An OTP
        # answer transfers exactly once and only for the challenge's
        # authorized operation; a consumed retry replays the committed
        # receipt (never the secret bytes).
        def consume(id, timeout: 0, operation: nil)
          request_id = safe_id(id)
          replay = replay_terminal!(request_id, "consumed")
          return replay if replay

          value = load_request(request_id)
          requester_gate!(value)
          verify_operation!(value, operation)
          deadline = timeout.positive? ? Time.now.to_i + timeout : nil
          loop do
            answer = nil
            with_request_lock(request_id) do
              value = load_request(request_id)
              requester_gate!(value)
              # Live authority is HELD across the terminal commit: an
              # attempt ending concurrently cancels the request and
              # fails closed instead of handing over an answer.
              with_live_authority!(value, requester: @identity.username) do
                verify_operation!(value, operation)
                answer = read_answer(value)
                unless answer
                  next
                end

                commit_terminal!(value, "consumed",
                  answer: value["sensitive"] == true ? nil : answer)
                update_public(value, "consumed")
                @vault.discard(self, value)
                remove_request(value, keep_public: true)
              end
            end
            if answer
              return {
                "id" => request_id,
                "work" => value["work"],
                "assignment" => value["assignment"],
                "attempt" => value["attempt"],
                "project" => value["project"],
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
        # cancellation by the requester of record (W651). Time never
        # cancels anything.
        def cancel(id, reason: "")
          request_id = safe_id(id)
          cancelled_by = @identity.username
          replay = replay_terminal!(request_id, "cancelled")
          return replay if replay

          audit = {"cancelled_by" => cancelled_by, "reason" => reason.to_s.strip.empty? ? "unspecified" : reason.to_s.strip}
          locked_value = nil
          with_request_lock(request_id) do
            value = load_request(request_id)
            # Ownership is re-checked against the LOCKED record: an
            # unlocked check would race a concurrent recreate of the id
            # (review 8wq2zttu on PR#336).
            unless @identity.username == value["requester"].to_s
              raise PermissionError, "only the requesting role can cancel this request"
            end
            commit_terminal!(value, "cancelled", audit)
            update_public(value, "cancelled", audit: audit)
            @vault.discard(self, value)
            remove_request(value, keep_public: true)
            locked_value = value
          end
          {
            "id" => request_id,
            "work" => locked_value["work"],
            "assignment" => locked_value["assignment"],
            "attempt" => locked_value["attempt"],
            "cancelled" => true,
            "cancelled_by" => cancelled_by,
            "reason" => audit["reason"]
          }
        end

        # ---- configured transport side -------------------------------------

        # Answer one pending request as the configured transport. The
        # answer is ALWAYS relayed unchanged; the declared effect callback
        # (if any) then executes inside the same locked critical section
        # with live authority held. Duplicate answers are idempotent: a
        # repeat delivery observes the already-relayed answer and returns
        # the prior result without re-running any effect.
        def deliver(id, answer_reader)
          request_id = safe_id(id)
          terminal = load_terminal(request_id)
          if terminal
            raise StateError, terminal["state"] == "cancelled" ? "HITL request was already cancelled" : "HITL request was already consumed"
          end
          value = load_request(request_id)
          require_transport!("deliver", value)
          if value["sensitive"] == true && !Kinds.secret?(value["kind"].to_s)
            raise StateError, "secret HITL answers are forbidden"
          end
          return delivered_result(value) if answer_present?(value)

          answer = read_bounded_answer(answer_reader)
          Kinds.check_answer!(value["kind"].to_s, answer)
          incarnation = [value["created_at"], value["kind"], value["sensitive"], value["requester"]]
          with_request_lock(request_id) do
            value = load_request(request_id)
            if [value["created_at"], value["kind"], value["sensitive"], value["requester"]] != incarnation
              raise StateError, "HITL request was cancelled and recreated while the answer was read"
            end
            # Idempotent duplicate: the first delivery already committed
            # under the lock; report it without a second write or effect.
            return delivered_result(value) if answer_present?(value)
            with_live_authority!(value, requester: value["requester"]) do
              write_answer(value, answer)
              update_public(value, "answer-delivered")
              unless value["sensitive"] == true
                requester_uid, requester_gid = @identity.user_ids(value["requester"])
                Effects.run(self, value, answer,
                  requester_uid: requester_uid, requester_gid: requester_gid, identity: @identity)
              end
            end
          end
          delivered_result(value)
        ensure
          answer&.clear
        end

        # Answerable requests; never purges or cancels anything (W651).
        def pending
          require_transport!("pending")
          requests_dir.glob("*.json").sort.filter_map do |path|
            value = AtomicJson.read(path)
            next unless value.is_a?(Hash)

            value if !answer_present?(value)
          end
        end

        # All public lifecycle records (non-secret projections).
        def states
          require_transport!("states")
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

        def locks_dir
          @root.join("locks")
        end

        def terminals_dir
          @root.join("terminals")
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

        # The public lifecycle projection: merge-on-write — every write
        # merges over the existing projection (state, timestamps and
        # audit fields win; effect/escalation fields recorded by an
        # earlier write survive every later lifecycle write, review
        # F-R2 on W696), 0440, never carries answer content. A root
        # service projects with requester ownership (0440, owner =
        # requester, group = the control group); a non-root service
        # keeps the projection service-owned — requesters always have
        # the boundary `read`/`states` operations.
        def update_public(value, state, audit: nil)
          request_id = safe_id(value["id"].to_s)
          public = {
            "id" => request_id,
            "work" => value["work"].to_s,
            "assignment" => value["assignment"].to_s,
            "attempt" => value["attempt"].to_s,
            "project" => value["project"].to_s,
            "harness" => value["harness"].to_s,
            "kind" => value["kind"].to_s,
            "state" => state,
            "created_at" => Integer(value["created_at"]),
            "updated_at" => Time.now.to_i
          }
          public["incarnation"] = value["incarnation"] if value["incarnation"]
          public["otp"] = public_otp_projection(value["otp"]) if value["otp"]
          public["effect_state"] = value["effect_state"] if value["effect_state"]
          public.update(audit) if audit
          existing = AtomicJson.read(public_path(request_id))
          public = existing.merge(public) if existing.is_a?(Hash)
          AtomicJson.call(
            public_path(request_id), public,
            mode: PUBLIC_MODE, ownership: ownership_for(value), ownership_strategy: @ownership
          )
        end

        def remove_request(value, keep_public: false)
          request_id = safe_id(value["id"].to_s)
          request_path(request_id).unlink if request_path(request_id).exist?
          public_path(request_id).unlink if !keep_public && public_path(request_id).exist?
          @vault.discard(self, value)
          nil
        end

        # The per-request flock on a STABLE lock file: lock files live in
        # locks/ and are never unlinked, so a cancelled-and-recreated
        # request id cannot land on a fresh inode and lose the mutual
        # exclusion (spec 8wq.t.34i). A record that vanished under a
        # concurrent cancel is a StateError, never a raw Errno escape
        # (review F5 on W696).
        def with_request_lock(request_id)
          ensure_layout!
          path = locks_dir.join("#{safe_id(request_id)}.lock")
          File.open(path, File::RDWR | File::CREAT, 0o600) do |file|
            file.flock(File::LOCK_EX)
            yield path
          ensure
            file.flock(File::LOCK_UN)
          end
        rescue Errno::ENOENT
          raise StateError, "unknown or invalid HITL request"
        end

        # First projection of a fresh incarnation, run under the same
        # per-request flock every transition uses (review 8wq2zttv on
        # PR#336). The projection-and-effects cleanup of a consumed or
        # cancelled predecessor happens here, keyed by the incarnation
        # token: a predecessor's artifacts never leak into the new
        # incarnation (review F-B on W696), and a broker that won the
        # lock first and already delivered can never be regressed to
        # "created" — a current-incarnation projection is left untouched.
        def initialize_projection!(value)
          request_id = safe_id(value["id"].to_s)
          with_request_lock(request_id) do
            current = AtomicJson.read(public_path(request_id))
            predecessor = current.nil? || current["incarnation"] != value["incarnation"]
            if predecessor
              public_path(request_id).unlink if public_path(request_id).exist?
              effects_dir.join("#{request_id}.json").unlink if effects_dir.join("#{request_id}.json").exist?
              # A new incarnation supersedes the predecessor's terminal
              # receipt: idempotent replays describe THIS lifecycle only
              # (spec 8wq.t.34i).
              terminals_dir.join("#{request_id}.json").unlink if terminals_dir.join("#{request_id}.json").exist?
              update_public(value, "created")
            end
          end
          nil
        end

        def load_request(request_id)
          path = request_path(request_id)
          raise StateError, "unknown or invalid HITL request" unless path.exist?

          value = AtomicJson.read(path)
          raise StateError, "unknown or invalid HITL request" unless value.is_a?(Hash)

          value
        end

        # The committed terminal receipt for one request id, or nil.
        def load_terminal(request_id)
          path = terminals_dir.join("#{safe_id(request_id)}.json")
          return nil unless path.exist?

          record = AtomicJson.read(path)
          record.is_a?(Hash) ? record : nil
        end

        def read_answer(value)
          # OTP bytes live only in the vault (spec 8wq.t.34i); plain
          # answers are the service-owned 0600 file in answers/.
          return @vault.read(self, value) if value["sensitive"] == true

          path = answers_dir.join("#{safe_id(value["id"])}.answer")
          return nil unless path.exist?

          answer = path.read
          Kinds.check_answer!(value["kind"].to_s, answer)
          answer
        end

        def answer_present?(value)
          if value["sensitive"] == true
            return true if @vault.is_a?(OtpVault::MemoryVault) && @vault.peek_present(self, value)

            secrets_dir.join("#{safe_id(value["id"])}.answer").exist?
          else
            answers_dir.join("#{safe_id(value["id"])}.answer").exist?
          end
        end

        def safe_id(value)
          id = value.to_s
          raise StateError, "invalid HITL request id" unless Kinds::REQUEST_ID.match?(id)

          id
        end

        private

        # ---- creation helpers ----------------------------------------------

        # Work ids and managed assignment ids are mutually exclusive; the
        # attempt id format follows the binding kind. Returns the binding
        # kind tag persisted with the request.
        def validate_binding_ids!(work, assignment, attempt)
          if work && assignment
            raise StateError, "bind the request by assignment OR by work, never both"
          end
          if assignment
            unless Kinds::COMPACT_ID.match?(assignment) && Kinds::COMPACT_ID.match?(attempt.to_s)
              raise StateError, "HITL request requires the exact managed assignment and attempt ids"
            end
            return "assignment"
          end
          unless Kinds::WORK_ID.match?(work.to_s)
            raise StateError, "HITL request requires a Work id or a managed assignment binding"
          end
          unless attempt && Kinds::ATTEMPT_ID.match?(attempt)
            raise StateError, "HITL request requires the exact active Attempt id"
          end
          "work"
        end

        # The OTP challenge evidence (spec 8wq.t.34i): non-secret,
        # structurally validated, and time-bounded. The challenge is the
        # ONLY way an OTP request exists — no publisher result, no
        # challenge.
        def normalize_otp_challenge!(context)
          unless context.is_a?(Hash)
            raise StateError,
              "OTP requests require the authorized-operation challenge " \
              "(otp: {operation:, result_ref:, input_digest:, expires_at:})"
          end
          operation = context[:operation] || context["operation"]
          result_ref = context[:result_ref] || context["result_ref"]
          input_digest = context[:input_digest] || context["input_digest"]
          expires_at = context[:expires_at] || context["expires_at"]
          unless Kinds::OTP_OPERATION.match?(operation.to_s)
            raise StateError, "OTP challenge operation must be a configured operation name"
          end
          unless Kinds::OTP_RESULT_REF.match?(result_ref.to_s)
            raise StateError, "OTP challenge requires the OTP-required publisher result reference"
          end
          unless Kinds::OTP_INPUT_DIGEST.match?(input_digest.to_s)
            raise StateError, "OTP challenge input digest must be a sha256 hex digest"
          end
          expires_at = Integer(expires_at)
          now = Time.now.to_i
          unless expires_at > now && expires_at <= now + Kinds::OTP_MAX_TTL_SECONDS
            raise StateError, "OTP challenge expiry must be in the future and within 24 hours"
          end
          {"operation" => operation, "result_ref" => result_ref,
           "input_digest" => input_digest, "expires_at" => expires_at}
        end

        def validate_request_binding(binding_kind, work, assignment, attempt, project, requester)
          @binding.validate_request(work: work, assignment: assignment, attempt: attempt,
            project: project, requester: requester)
        end

        # ---- role gates ------------------------------------------------------

        def requester_gate!(value)
          unless @identity.username == value["requester"].to_s
            raise PermissionError, "only the requesting role can consume this answer"
          end
        end

        def gate_read_access!(value)
          return if @identity.username == value["requester"].to_s

          require_transport!("read", value)
        end

        def require_transport!(operation, value = nil)
          return true if @policy.transport?(@identity, project: value && value["project"])

          raise PermissionError, "#{operation} requires the configured transport identity"
        end

        # The OTP exactness gate: the consuming executor must present the
        # challenge's authorized operation; anything else fails closed
        # without touching the secret.
        def verify_operation!(value, operation)
          return unless value["otp"]

          presented = operation.to_s
          raise StateError, "OTP consumption requires the authorized operation" if presented.empty?
          unless presented == value["otp"]["operation"]
            raise PermissionError, "this OTP is authorized only for operation #{value["otp"]["operation"].inspect}"
          end
        end

        # ---- terminal receipts -----------------------------------------------

        # The committed outcome of a terminal transition, used to make
        # duplicate consume/cancel idempotent (spec 8wq.t.34i): a retry
        # reports the committed receipt instead of "unknown request".
        # A consumed receipt replays to its requester (never the secret
        # bytes of an OTP); a cancelled terminal replays only to cancel.
        def replay_terminal!(request_id, operation)
          terminal = load_terminal(request_id)
          return nil unless terminal

          case terminal["state"]
          when "cancelled"
            return replayed_cancel(request_id, terminal) if operation == "cancelled"

            raise StateError, "HITL request was already cancelled"
          when "consumed"
            return replayed_consume(terminal) if operation == "consumed"

            raise StateError, "HITL request was already consumed"
          end
          nil
        end

        def replayed_consume(terminal)
          result = {
            "id" => terminal["id"],
            "work" => terminal["work"],
            "assignment" => terminal["assignment"],
            "attempt" => terminal["attempt"],
            "sensitive" => terminal["sensitive"] == true,
            "replay" => true
          }
          result["answer"] = terminal["answer"] unless terminal["sensitive"] == true
          result
        end

        def replayed_cancel(request_id, terminal)
          audit = terminal["audit"].is_a?(Hash) ? terminal["audit"] : {}
          {
            "id" => request_id,
            "work" => terminal["work"],
            "assignment" => terminal["assignment"],
            "attempt" => terminal["attempt"],
            "cancelled" => true,
            "cancelled_by" => audit["cancelled_by"],
            "reason" => audit["reason"],
            "replay" => true
          }
        end

        # Committed under the same per-request flock as the projection
        # update, BEFORE the request file is removed: the receipt is the
        # durable, non-secret (answers only for non-sensitive kinds) word
        # on what happened to this incarnation.
        def commit_terminal!(value, state, extra = {})
          request_id = safe_id(value["id"].to_s)
          record = {
            "id" => request_id,
            "incarnation" => value["incarnation"],
            "state" => state,
            "work" => value["work"],
            "assignment" => value["assignment"],
            "attempt" => value["attempt"],
            "project" => value["project"],
            "sensitive" => value["sensitive"] == true,
            "at" => Time.now.to_i
          }
          record["answer"] = extra[:answer] if extra[:answer]
          record["audit"] = extra["audit"] if extra["audit"]
          terminals_dir.mkpath
          AtomicJson.call(terminals_dir.join("#{request_id}.json"), record, mode: TERMINAL_MODE)
          nil
        end

        # ---- transition helpers ----------------------------------------------

        # Live authority is HELD across the transition commit; a binding
        # that reports the attempt ended (or became unverifiable) cancels
        # the request and fails closed — stale attempts never hand over
        # answers (spec 8wq.t.34i).
        def with_live_authority!(value, requester:)
          @binding.with_active(
            work: value["work"], assignment: value["assignment"], attempt: value["attempt"],
            project: value["project"], requester: requester
          ) do
            yield
          end
        rescue BindingError
          update_public(value, "cancelled")
          remove_request(value, keep_public: true)
          raise
        end

        def public_state(request_id, value)
          projection = AtomicJson.read(public_path(request_id))
          projection.is_a?(Hash) ? projection["state"] : "created"
        end

        def public_otp_projection(challenge)
          {"operation" => challenge["operation"], "expires_at" => challenge["expires_at"]}
        end

        def delivered_result(value)
          {
            "id" => value["id"],
            "work" => value["work"],
            "assignment" => value["assignment"],
            "attempt" => value["attempt"],
            "delivered" => true,
            "sensitive" => value["sensitive"] == true
          }
        end

        # Liveness re-verification is scoped by the binding's with_active
        # (the authority holds its exclusion across the caller's commit);
        # a binding that ends mid-transition is cancelled-and-raised by
        # the composite policy itself.

        def read_bounded_answer(reader)
          raw = reader.call(MAX_ANSWER_BYTES + 1).to_s
          if raw.bytesize > MAX_ANSWER_BYTES
            raise AnswerError, "answer exceeds #{MAX_ANSWER_BYTES} bytes"
          end

          # The documented 1-4096 bound is on CHARACTERS: decode UTF-8
          # before measuring, so a valid multibyte answer is not
          # rejected for its byte length (review 8wq2zttz on PR#336).
          answer = raw.dup.force_encoding(Encoding::UTF_8)
          raise AnswerError, "answer must be valid UTF-8" unless answer.valid_encoding?

          answer = answer.strip
          if answer.empty? || answer.length > MAX_ANSWER || answer.include?("\u0000")
            raise AnswerError, "answer must contain 1-#{MAX_ANSWER} characters"
          end

          answer
        end

        # Persist the answer service-owned (0600): requesters never touch
        # store files — consumption transfers the bytes over the
        # authenticated boundary. The temporary is unique per invocation
        # so a competing writer's cleanup can never delete it (review
        # 8wq2zttt on PR#336).
        def write_answer(value, answer)
          if value["sensitive"] == true
            @vault.write(self, value, answer)
            return
          end
          destination = answer_path(value)
          temporary = destination.parent.join(".#{safe_id(value["id"])}.#{$PROCESS_ID}.#{SecureRandom.hex(4)}")
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
          File.rename(temporary, destination)
        ensure
          temporary.unlink if temporary&.exist?
        end

        def ownership_for(value)
          return nil unless @identity.root?

          uid, _ = @identity.user_ids(value["requester"].to_s)
          AtomicJson::Ownership.new(uid: uid, gid: group_id)
        rescue Lifecycle::Error
          nil
        end

        def group_id
          @group_id ||= @identity.group_id(DEFAULT_GROUP)
        end
      end
    end
  end
end
