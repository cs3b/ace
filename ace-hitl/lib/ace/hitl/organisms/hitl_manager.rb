# frozen_string_literal: true

require "time"
require "fileutils"
require "pathname"
require "ace/support/items"
require_relative "../molecules/hitl_config_loader"
require_relative "../molecules/hitl_scanner"
require_relative "../molecules/hitl_loader"
require_relative "../molecules/hitl_creator"
require_relative "../molecules/hitl_answer_editor"
require_relative "../molecules/resume_dispatcher"
require_relative "../molecules/worktree_scope_resolver"

module Ace
  module Hitl
    module Organisms
      class HitlManager
        class AmbiguousReferenceError < StandardError
          attr_reader :ref, :matches

          def initialize(ref, matches)
            @ref = ref
            @matches = matches
            super("Ambiguous HITL reference '#{ref}'")
          end
        end

        class NotAnswerableError < StandardError; end
        class AnswerConflictError < StandardError; end
        class UnknownCaseError < StandardError; end
        class LifecycleTransitionError < StandardError; end

        attr_reader :root_dir, :last_list_total, :last_folder_counts, :config

        def initialize(root_dir: nil, config: nil, scope_resolver: nil, resume_dispatcher: nil,
          address_resolver: nil)
          @config = config || load_config
          @configured_root_setting = @config.dig("hitl", "root_dir") || Molecules::HitlConfigLoader::DEFAULT_ROOT_DIR
          @root_dir = root_dir || resolve_root_dir
          @scope_resolver = scope_resolver || Molecules::WorktreeScopeResolver.new
          @resume_dispatcher = resume_dispatcher || Molecules::ResumeDispatcher.new
          @address_resolver = address_resolver || Molecules::HitlAddressResolver.new(config: @config)
        end

        def create(title, to: nil, **options)
          # Resolve the recipient address before any I/O: unknown names and
          # malformed addresses fail closed with nothing written. The reply
          # address (sender machine + events folder) applies to questions
          # only — a report carries the recipient but never awaits a reply,
          # so hitl.machine is not required for report+--to.
          recipient = nil
          reply_to = nil
          effective_to = to || @address_resolver.default_recipient
          event_type = options[:type] || "question"
          if effective_to
            recipient = @address_resolver.resolve(effective_to)
            if event_type == "question"
              # The reply address must identify THIS sender folder: use the
              # resolved root (absolute), not the configured setting — a
              # relative value like `.ace-local/hitl` is identical across
              # worktrees and gives the reply no base to resolve against.
              reply_to = @address_resolver.sender_address(folder: File.expand_path(@root_dir), id: "pending")
                .reject { |key, _| key == "id" }
            end
          end

          ensure_root_dir
          creator = Molecules::HitlCreator.new(root_dir: @root_dir, config: @config)
          creator.create(title, **options, recipient: recipient, reply_to: reply_to)
        end

        def show(ref, scope: nil)
          effective_scope = @scope_resolver.effective_scope(scope)
          roots = hitl_roots_for_scope(effective_scope)
          current_root = current_hitl_root

          resolved = resolve_from_roots(ref, roots, strict_ambiguity: true)

          fallback_used = false
          if resolved.nil? && scope.nil? && effective_scope == "current"
            resolved = resolve_from_roots(ref, hitl_roots_for_scope("all"), strict_ambiguity: true)
            effective_scope = "all" if resolved
            fallback_used = !resolved.nil?
          end

          return nil unless resolved

          {
            event: resolved[:event],
            effective_scope: effective_scope,
            fallback_used: fallback_used,
            resolved_hitl_root: resolved[:hitl_root],
            resolved_worktree_root: resolved[:worktree_root],
            resolved_outside_current: !current_root.nil? && resolved[:hitl_root] != current_root
          }
        end

        def list(status: nil, kind: nil, type: nil, delivery: nil, in_folder: "next", tags: [], scope: nil, limit: nil, strict: false)
          effective_scope = @scope_resolver.effective_scope(scope)
          scan_results = scan_results_for_scope(effective_scope, in_folder: in_folder)
          raise ArgumentError, "observation exceeds configured event budget" if limit && scan_results.size > limit
          events = load_events(scan_results)
          raise ArgumentError, "incomplete HITL observation" if strict && events.size != scan_results.size

          events = events.select { |event| event.status == status } if status
          events = events.select { |event| event.kind == kind } if kind
          events = events.select { |event| event.type == type } if type
          events = filter_by_delivery(events, delivery) if delivery
          events = filter_by_tags(events, tags) if tags.any?

          events
        end

        # Receive a delivered human answer for EXACTLY one case (task
        # 8xs.t.pu0.5 — the reply half of the Hermes → owner-machine
        # delivery). The reference must be the case's exact id — no
        # shortcut or latest-match resolution, so a reply can never land
        # in a foreign case on collision. Idempotent: re-delivering the
        # same answer for an already-answered case reports :duplicate
        # without a second write; a DIFFERENT answer conflicts and never
        # overwrites the human decision. The durable case file is the
        # record — an absent asker is fine, the armed wake consumes the
        # change whenever the asking session returns.
        # @return [Symbol] :received or :duplicate
        # @raise [UnknownCaseError] no case with this exact id
        # @raise [AmbiguousReferenceError] the reference collides
        # @raise [NotAnswerableError] the case is a report
        # @raise [AnswerConflictError] a different answer already exists
        def receive_answer(ref, answer, scope: nil)
          resolved = resolve_for_mutation(ref, scope: scope)
          raise UnknownCaseError, "no HITL case with exact id '#{ref}'" if resolved.nil?
          if resolved[:event].id.to_s != ref.to_s
            raise UnknownCaseError,
              "'#{ref}' is not an exact case id (resolved to '#{resolved[:event].id}'); " \
                "reply requires the exact case id from the ask"
          end

          event = resolved[:event]
          if event.report?
            raise NotAnswerableError,
              "HITL event '#{event.id}' is a report; reports do not await an answer"
          end

          content = File.read(event.file_path)
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)
          previous = body.sub(/\A\n/, "").match(/^## Answer[ \t]*(?:\n(.*))?\z/m)&.[](1).to_s.strip
          if frontmatter["answered"] == true || !previous.empty?
            if previous == answer.to_s.strip
              return :duplicate
            end

            raise AnswerConflictError,
              "case '#{event.id}' already has a different answer; a reply never overwrites a decision"
          end

          apply_field_and_answer_updates(event.file_path, set: {}, add: {}, remove: {},
            answer: answer, first_answer: true)
          :received
        end

        # --- case lifecycle (task 8xs.t.pu0.6) ------------------------------

        # The case's lifecycle facts, read from the canonical file only:
        # receipt (pending/received) and application
        # (pending/applied/closed/cancelled). Reports stay `recorded` —
        # they never await an answer or application.
        # @return [Hash] {"receipt"=>, "application"=>, "answered"=>,
        #   "effect_ref"=>, "answered_at"=>}
        def case_lifecycle(ref, scope: nil)
          event = exact_case(ref, scope: scope)
          frontmatter, _body = read_frontmatter(event.file_path)
          {"receipt" => frontmatter["answered"] ? "received" : "pending",
           "application" => frontmatter.dig("application", "state") || "pending",
           "answered" => frontmatter["answered"] == true,
           "effect_ref" => frontmatter.dig("application", "ref"),
           "answered_at" => frontmatter["answered_at"]}
        end

        # Record that the answer's effect was applied — with the
        # reference to the effect OWNER (task/assignment/PR) the
        # consumer verified. Idempotent per reference: re-recording the
        # same effect ref is a no-op; a different effect ref for an
        # applied case is a conflict. Closing happens only after this
        # proof exists.
        # @return [Symbol] :applied or :duplicate
        def apply_answer_effect(ref, effect_ref, scope: nil)
          require_effect_ref!(effect_ref)
          event = exact_case(ref, scope: scope)
          ensure_answered!(event)

          transition(event.file_path) do |frontmatter, _body|
            application = frontmatter["application"] || {}
            case application["state"].to_s
            when "", "pending"
              frontmatter["application"] = {"state" => "applied", "ref" => effect_ref,
                "applied_at" => timestamp}
              :applied
            when "applied"
              raise LifecycleTransitionError,
                "case '#{event.id}' already applied with effect '#{application["ref"]}'; " \
                  "a different effect reference is a conflict" unless application["ref"] == effect_ref

              :duplicate
            when "closed"
              raise LifecycleTransitionError,
                "case '#{event.id}' is closed; a closed case never re-opens — " \
                  "an explicit decision change needs a new case"
            else
              raise LifecycleTransitionError,
                "case '#{event.id}' is #{application["state"]}; it cannot be applied"
            end
          end
        end

        # Terminal close: only with a proven applied effect. A duplicate
        # close is a no-op; a close without the applied proof fails —
        # exactly-once belongs to the EFFECT, never to the close itself.
        # @return [Symbol] :closed or :duplicate
        def close_case(ref, scope: nil)
          event = exact_case(ref, scope: scope)
          ensure_answered!(event)

          transition(event.file_path) do |frontmatter, _body|
            application = frontmatter["application"] || {}
            case application["state"].to_s
            when "", "pending"
              raise LifecycleTransitionError,
                "case '#{event.id}' has no applied effect; close only after the " \
                  "applied proof (ace-hitl apply CASE --ref OWNER_REF)"
            when "applied"
              frontmatter["application"] = application.merge("state" => "closed",
                "closed_at" => timestamp)
              :closed
            when "closed"
              :duplicate
            else
              raise LifecycleTransitionError,
                "case '#{event.id}' is #{application["state"]}; it cannot be closed"
            end
          end
        end

        # Terminal without application: the question was abandoned
        # (superseded, withdrawn) without its answer ever being applied.
        # Only from the not-yet-applied states — an applied effect is
        # history and is closed, not cancelled.
        # @return [Symbol] :cancelled or :duplicate
        def cancel_case(ref, scope: nil)
          event = exact_case(ref, scope: scope)

          transition(event.file_path) do |frontmatter, _body|
            application = frontmatter["application"] || {}
            case application["state"].to_s
            when "", "pending"
              frontmatter["application"] = {"state" => "cancelled",
                "cancelled_at" => timestamp}
              :cancelled
            when "cancelled"
              :duplicate
            else
              raise LifecycleTransitionError,
                "case '#{event.id}' is #{application["state"]}; only an unanswered, " \
                  "unapplied case can be cancelled"
            end
          end
        end

        private

        def timestamp
          Time.now.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
        end

        public

        # Sweep of transport leftovers (task 8xs.t.pu0.6): qualify the
        # ask-bridge wake-request drop files (and any recorded delivery
        # remnants) against the CANONICAL case files. Deletion candidates
        # are ONLY requests whose case is terminally closed or cancelled;
        # active cases (pending/received/applied), unknown ids and the
        # canonical decision history are always preserved.
        # @return [Hash] {"qualified" => [{request:, case:, application:}],
        #   "preserved" => [{request:, reason:}]}
        def sweep(apply: false)
          requests_dir = File.join(File.expand_path(@root_dir), "wake-requests")
          return {"qualified" => [], "preserved" => [], "removed" => []} unless Dir.exist?(requests_dir)

          qualified = []
          preserved = []
          removed = []
          Dir.glob(File.join(requests_dir, "*.json")).sort.each do |request_path|
            request = JSON.parse(File.read(request_path))
            case_id = request["case_id"].to_s
            lifecycle = begin
              case_lifecycle(case_id)
            rescue UnknownCaseError, AmbiguousReferenceError
              nil
            end
            application = lifecycle && lifecycle["application"]
            if %w[closed cancelled].include?(application.to_s)
              entry = {"request" => request_path, "case" => case_id, "application" => application}
              qualified << entry
              if apply
                File.delete(request_path)
                removed << entry
              end
            else
              preserved << {"request" => request_path, "case" => case_id,
                "reason" => application.nil? ? "unknown case — preserved" :
                  "case application is '#{application}' (active)"}
            end
          rescue JSON::ParserError
            preserved << {"request" => request_path, "case" => nil,
              "reason" => "unparseable request — preserved"}
          end
          {"qualified" => qualified, "preserved" => preserved, "removed" => removed}
        end

        def exact_case(ref, scope: nil)
          resolved = resolve_for_mutation(ref, scope: scope)
          raise UnknownCaseError, "no HITL case with exact id '#{ref}'" if resolved.nil?
          if resolved[:event].id.to_s != ref.to_s
            raise UnknownCaseError,
              "'#{ref}' is not an exact case id (resolved to '#{resolved[:event].id}')"
          end

          resolved[:event]
        end

        def require_effect_ref!(effect_ref)
          unless effect_ref.is_a?(String) && !effect_ref.strip.empty?
            raise LifecycleTransitionError,
              "an effect reference is required (the task/assignment/PR that owns the effect)"
          end
        end

        def ensure_answered!(event)
          frontmatter, _body = read_frontmatter(event.file_path)
          return if frontmatter["answered"] == true

          raise LifecycleTransitionError,
            "case '#{event.id}' has no received answer; deliver the answer first " \
              "(ace-hitl reply CASE --stdin)"
        end

        def read_frontmatter(file_path)
          content = File.read(file_path)
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)
          [frontmatter, body.sub(/\A\n/, "")]
        end

        # Atomic, conflict-rejecting lifecycle transition: exclusive lock,
        # validate-and-mutate frontmatter in one pass, serialize back.
        def transition(file_path)
          File.open(file_path, File::RDWR) do |file|
            file.flock(File::LOCK_EX)
            file.rewind
            content = file.read
            frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)
            result = yield(frontmatter, body.sub(/\A\n/, ""))
            new_content = Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(frontmatter, body)
            file.rewind
            file.truncate(0)
            file.write(new_content)
            file.flush
            file.fsync
            result
          end
        end

        def timestamp
          Time.now.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
        end

        def update(ref, set: {}, add: {}, remove: {}, move_to: nil, answer: nil, scope: nil)
          resolved = resolve_for_mutation(ref, scope: scope)
          return nil unless resolved

          event = resolved[:event]
          hitl_root = resolved[:hitl_root] || @root_dir

          if !answer.nil? && event.report?
            raise NotAnswerableError,
              "HITL event '#{event.id}' is a report; reports do not await an answer"
          end

          has_field_updates = [set, add, remove].any? { |h| h && !h.empty? }
          if has_field_updates && !answer.nil?
            apply_field_and_answer_updates(event.file_path, set: set, add: add, remove: remove, answer: answer)
          elsif has_field_updates
            Ace::Support::Items::Molecules::FieldUpdater.update(
              event.file_path,
              set: set,
              add: add,
              remove: remove
            )
          end

          apply_answer_update(event.file_path, answer) unless answer.nil?

          current_path = event.path
          current_special = event.special_folder
          if move_to
            mover = Ace::Support::Items::Molecules::FolderMover.new(hitl_root)
            new_path = if Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?(move_to)
              mover.move_to_root(event)
            else
              mover.move(event, to: move_to, date: parse_archive_date(event))
            end
            current_path = new_path
            current_special = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(
              new_path,
              root: hitl_root
            )
          end

          loader = Molecules::HitlLoader.new
          loader.load(current_path, id: event.id, special_folder: current_special)
        end

        # Transport imports are first-answer-wins. The case's own write lock
        # checks the answer again, so replay cannot overwrite a human answer.
        # Explicit `update --answer` remains an intentional editing operation.
        def accept_answer(ref, answer:, scope: nil)
          resolved = resolve_for_mutation(ref, scope: scope)
          return nil unless resolved
          event = resolved[:event]
          raise NotAnswerableError, "reports do not await an answer" if event.report?
          raise NotAnswerableError, "managed requests require their authenticated lifecycle" if event.metadata["lab_request_id"]
          raise ArgumentError, "answer is empty" if answer.to_s.strip.empty?
          apply_field_and_answer_updates(event.file_path, set: {}, add: {}, remove: {},
            answer: answer, first_answer: true)
          Molecules::HitlLoader.new.load(event.path, id: event.id, special_folder: event.special_folder)
        end

        def wait_for_answer(ref, scope: nil, poll_every: 600, timeout: 14_400, waiter: {}, now_proc: nil, sleeper: nil)
          poll_every = normalize_poll_seconds(poll_every)
          timeout = normalize_timeout_seconds(timeout)
          now_proc ||= -> { Time.now.utc }
          sleeper ||= ->(seconds) { sleep(seconds) }

          started_at = now_proc.call
          deadline = started_at + timeout
          waiter_session_id = waiter[:session_id].to_s.strip
          waiter_provider = waiter[:provider].to_s.strip

          loop do
            current = show(ref, scope: scope)
            return {status: :not_found} unless current

            event = current[:event]
            return {status: :report, event: event} if event.report?

            if event.metadata["lab_request_id"]
              raise Lifecycle::StateError, "managed requests require authenticated scoped wait"
            end

            now = now_proc.call
            refresh_waiter_lease(
              event,
              now: now,
              deadline: deadline,
              poll_every: poll_every,
              waiter_session_id: waiter_session_id,
              waiter_provider: waiter_provider,
              scope: scope
            )

            if event.answered?
              update(event.id,
                set: {
                  "waiter_state" => "answered",
                  "waiter_last_seen_at" => now.iso8601
                },
                scope: scope
              )
              refreshed = show(event.id, scope: scope)&.dig(:event) || event
              return {status: :answered, event: refreshed}
            end

            if now >= deadline
              update(event.id, set: {"waiter_state" => "timed_out"}, scope: scope)
              return {status: :timeout, event: event}
            end

            sleep_seconds = [poll_every, (deadline - now).ceil].min
            sleeper.call(sleep_seconds) if sleep_seconds.positive?
          end
        end

        def dispatch_resume(ref, scope: nil, now: Time.now.utc)
          current = show(ref, scope: scope)
          return {status: :not_found} unless current

          event = current[:event]
          return {status: :report, event: event} if event.report?
          return {status: :managed_request, event: event} if event.metadata["lab_request_id"]

          answer = event.answer.to_s
          return {status: :no_answer, event: event} if answer.strip.empty?

          if waiter_active?(event, now: now)
            return {status: :waiter_active, event: event}
          end

          result = @resume_dispatcher.dispatch(event: event, answer: answer, now: now)
          unless result.success?
            update(event.id,
              set: {
                "resume_dispatch_status" => "failed",
                "resume_dispatch_attempted_at" => now.iso8601,
                "resume_dispatch_error" => result.error
              },
              scope: scope
            )
            return {status: :failed, event: event, error: result.error}
          end

          update(event.id,
            set: {
              "resume_dispatch_status" => "dispatched",
              "resume_dispatch_attempted_at" => now.iso8601,
              "resumed_at" => now.iso8601,
              "resumed_by" => result.details,
              "waiter_state" => "resumed",
              "resume_dispatch_error" => nil
            },
            scope: scope
          )

          note = "Work resumed at #{now.iso8601} via #{result.mode} (#{result.details})."
          append_resume_note(event.id, note, scope: scope)
          archived = update(event.id, move_to: "archive", scope: scope)

          {status: :dispatched, event: archived, mode: result.mode, details: result.details}
        end

        private

        def load_config
          Molecules::HitlConfigLoader.load
        end

        def resolve_root_dir
          Molecules::HitlConfigLoader.root_dir(@config)
        end

        def ensure_root_dir
          FileUtils.mkdir_p(@root_dir) unless Dir.exist?(@root_dir)
        end

        def resolve_for_mutation(ref, scope: nil)
          effective_scope = @scope_resolver.effective_scope(scope)
          roots = hitl_roots_for_scope(effective_scope)

          resolved = resolve_from_roots(ref, roots, strict_ambiguity: true)
          if resolved.nil? && scope.nil? && effective_scope == "current"
            resolved = resolve_from_roots(ref, hitl_roots_for_scope("all"), strict_ambiguity: true)
          end

          resolved
        end

        def resolve_from_roots(ref, hitl_roots, strict_ambiguity: false)
          root_results = hitl_roots.uniq.filter_map do |hitl_root|
            scanner = Molecules::HitlScanner.new(hitl_root)
            results = scanner.scan
            next if results.empty?

            {hitl_root: hitl_root, results: results}
          end
          return nil if root_results.empty?

          all_results = root_results.flat_map { |entry| entry[:results] }
          resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(all_results)
          matches = resolver.all_matches(ref)
          return nil if matches.empty?
          if strict_ambiguity && matches.size > 1
            raise AmbiguousReferenceError.new(ref, matches)
          end

          scan_result = resolver.resolve(ref, on_ambiguity: nil)
          return nil unless scan_result

          root_entry = root_results.find { |entry| entry[:results].include?(scan_result) }
          hitl_root = root_entry && root_entry[:hitl_root]
          event = load_event(scan_result)
          return nil unless event

          {
            event: event,
            hitl_root: hitl_root,
            worktree_root: worktree_root_from_hitl_root(hitl_root)
          }
        end

        def scan_results_for_scope(scope, in_folder:)
          total = 0
          folder_counts = Hash.new(0)

          results = hitl_roots_for_scope(scope).uniq.flat_map do |hitl_root|
            scanner = Molecules::HitlScanner.new(hitl_root)
            scoped_results = scanner.scan_in_folder(in_folder)
            total += scanner.last_scan_total.to_i
            (scanner.last_folder_counts || {}).each { |key, value| folder_counts[key] += value }
            scoped_results
          end

          @last_list_total = total
          @last_folder_counts = folder_counts
          results
        end

        def load_events(scan_results)
          scan_results.filter_map { |scan_result| load_event(scan_result) }
        end

        def load_event(scan_result)
          loader = Molecules::HitlLoader.new
          loader.load(scan_result.dir_path,
            id: scan_result.id,
            special_folder: scan_result.special_folder)
        end

        def hitl_roots_for_scope(scope)
          roots = @scope_resolver.worktree_roots(scope: scope)
          roots = [@scope_resolver.current_worktree_root].compact if roots.empty?
          roots = [nil] if roots.empty?

          roots.filter_map do |worktree_root|
            next @root_dir if worktree_root.nil?
            next @configured_root_setting if Pathname.new(@configured_root_setting).absolute?

            File.join(worktree_root, @configured_root_setting)
          end.uniq
        end

        def current_hitl_root
          root = @scope_resolver.current_worktree_root
          return @root_dir if root.nil?
          return @configured_root_setting if Pathname.new(@configured_root_setting).absolute?

          File.join(root, @configured_root_setting)
        end

        def worktree_root_from_hitl_root(hitl_root)
          return nil if hitl_root.nil?
          return nil if Pathname.new(@configured_root_setting).absolute?

          expanded = File.expand_path(hitl_root)
          relative = @configured_root_setting.sub(%r{\A\./}, "")
          suffix = "/#{relative}"
          return nil unless expanded.end_with?(suffix)

          expanded[0...-suffix.length]
        end

        def filter_by_tags(events, tags)
          events.select { |event| tags.any? { |tag| event.tags.include?(tag) } }
        end

        def filter_by_delivery(events, delivery)
          case delivery.to_s
          when "undelivered"
            events.select { |event| Molecules::HitlDeliveryState.undelivered?(event.metadata["delivery"]) }
          when "delivered"
            events.select { |event| Molecules::HitlDeliveryState.fully_delivered?(event.metadata["delivery"]) }
          else
            raise Error, "invalid delivery filter '#{delivery}' (undelivered, delivered)"
          end
        end

        def apply_answer_update(file_path, answer)
          content = File.read(file_path)
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)

          updated_body = Molecules::HitlAnswerEditor.apply(body, answer)
          answered = !answer.to_s.strip.empty?
          frontmatter["answered"] = answered
          frontmatter["status"] = answered ? "answered" : (frontmatter["status"] || "pending")
          frontmatter["answered_at"] = answered ? Time.now.utc : nil

          new_content = Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(frontmatter, updated_body)
          tmp_path = "#{file_path}.tmp.#{Process.pid}"
          File.write(tmp_path, new_content)
          File.rename(tmp_path, file_path)
        ensure
          File.unlink(tmp_path) if tmp_path && File.exist?(tmp_path)
        end

        def apply_field_and_answer_updates(file_path, set:, add:, remove:, answer:, first_answer: false)
          File.open(file_path, File::RDWR) do |file|
            file.flock(File::LOCK_EX)
            file.rewind

            content = file.read
            frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)
            body = body.sub(/\A\n/, "")
            previous = body.match(/^## Answer[ \t]*(?:\n(.*))?\z/m)&.[](1).to_s.strip
            if first_answer && (frontmatter["answered"] == true || !previous.empty?)
              raise AnswerConflictError, "case already has a different answer" unless previous == answer.to_s.strip
              return
            end

            Ace::Support::Items::Molecules::FieldUpdater.apply_set(frontmatter, set)
            Ace::Support::Items::Molecules::FieldUpdater.apply_add(frontmatter, add)
            Ace::Support::Items::Molecules::FieldUpdater.apply_remove(frontmatter, remove)

            updated_body = Molecules::HitlAnswerEditor.apply(body, answer)
            answered = !answer.to_s.strip.empty?
            frontmatter["answered"] = answered
            frontmatter["status"] = answered ? "answered" : (frontmatter["status"] || "pending")
            frontmatter["answered_at"] = answered ? Time.now.utc : nil

            new_content = Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(frontmatter, updated_body)
            file.rewind
            file.truncate(0)
            file.write(new_content)
            file.flush
            file.fsync
          end
        end

        def parse_archive_date(event)
          raw = event.metadata["answered_at"] || event.metadata["created_at"] || event.created_at
          return nil unless raw

          case raw
          when Time then raw
          when DateTime then raw.to_time
          else
            Time.parse(raw.to_s)
          end
        rescue StandardError
          nil
        end

        def refresh_waiter_lease(event, now:, deadline:, poll_every:, waiter_session_id:, waiter_provider:, scope:)
          set = {
            "waiter_state" => "waiting",
            "waiter_last_seen_at" => now.iso8601,
            "waiter_poll_every_sec" => poll_every,
            "waiter_timeout_at" => deadline.iso8601
          }
          set["waiter_session_id"] = waiter_session_id unless waiter_session_id.empty?
          set["waiter_provider"] = waiter_provider unless waiter_provider.empty?
          update(event.id, set: set, scope: scope)
        end

        def waiter_active?(event, now:)
          return false unless event.metadata["waiter_state"].to_s == "waiting"

          last_seen = parse_time(event.metadata["waiter_last_seen_at"])
          return false unless last_seen

          interval = event.metadata["waiter_poll_every_sec"].to_i
          interval = 600 if interval <= 0
          (now - last_seen) <= (interval * 2)
        end

        def parse_time(raw)
          return raw if raw.is_a?(Time)
          return nil if raw.nil?

          Time.parse(raw.to_s)
        rescue StandardError
          nil
        end

        def normalize_poll_seconds(value)
          parsed = value.to_i
          return 600 if parsed <= 0

          parsed
        end

        def normalize_timeout_seconds(value)
          parsed = value.to_i
          return 14_400 if parsed <= 0

          parsed
        end

        def append_resume_note(ref, note, scope: nil)
          current = show(ref, scope: scope)
          return unless current

          event = current[:event]
          content = File.read(event.file_path)
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)
          updated_body = body.to_s.sub(/\s*\z/, "")
          updated_body << "\n\n## Resume Dispatch\n\n#{note}\n"
          rebuilt = Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(frontmatter, updated_body)
          File.write(event.file_path, rebuilt)
        end
      end
    end
  end
end
