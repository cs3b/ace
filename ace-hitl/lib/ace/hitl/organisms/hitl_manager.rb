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

        attr_reader :root_dir, :last_list_total, :last_folder_counts

        def initialize(root_dir: nil, config: nil, scope_resolver: nil, resume_dispatcher: nil)
          @config = config || load_config
          @configured_root_setting = @config.dig("hitl", "root_dir") || Molecules::HitlConfigLoader::DEFAULT_ROOT_DIR
          @root_dir = root_dir || resolve_root_dir
          @scope_resolver = scope_resolver || Molecules::WorktreeScopeResolver.new
          @resume_dispatcher = resume_dispatcher || Molecules::ResumeDispatcher.new
        end

        def create(title, **options)
          ensure_root_dir
          creator = Molecules::HitlCreator.new(root_dir: @root_dir, config: @config)
          creator.create(title, **options)
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

        def list(status: nil, kind: nil, in_folder: "next", tags: [], scope: nil)
          effective_scope = @scope_resolver.effective_scope(scope)
          scan_results = scan_results_for_scope(effective_scope, in_folder: in_folder)
          events = load_events(scan_results)

          events = events.select { |event| event.status == status } if status
          events = events.select { |event| event.kind == kind } if kind
          events = filter_by_tags(events, tags) if tags.any?

          events
        end

        def update(ref, set: {}, add: {}, remove: {}, move_to: nil, answer: nil, scope: nil)
          resolved = resolve_for_mutation(ref, scope: scope)
          return nil unless resolved

          event = resolved[:event]
          hitl_root = resolved[:hitl_root] || @root_dir

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

        def apply_answer_update(file_path, answer)
          content = File.read(file_path)
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)

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

        def apply_field_and_answer_updates(file_path, set:, add:, remove:, answer:)
          File.open(file_path, File::RDWR) do |file|
            file.flock(File::LOCK_EX)
            file.rewind

            content = file.read
            frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
            body = body.sub(/\A\n/, "")

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
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
          updated_body = body.to_s.sub(/\s*\z/, "")
          updated_body << "\n\n## Resume Dispatch\n\n#{note}\n"
          rebuilt = Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(frontmatter, updated_body)
          File.write(event.file_path, rebuilt)
        end
      end
    end
  end
end
