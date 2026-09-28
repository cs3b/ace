# frozen_string_literal: true

require "time"

module Ace
  module Herdr
    module Organisms
      # Owner of tidy behavior (spec 8wq.t.1w0): dry-run-first cleanup of
      # finished agent panes and old delivered delivery records. Safety rule:
      # only positive evidence closes — a pane is closed solely on observed
      # `done` agent state or a dead pane process, confirmed by a fresh probe
      # immediately before the rename->close mutation (a candidate that
      # revived in between is excluded, never mutated). Delivered records
      # older than the retention threshold are archived only when a reload
      # under the per-event lock still proves them eligible; failed,
      # retryable, pending, and unreadable records are never touched.
      class Tidy
        DEFAULT_RETENTION_DAYS = 7
        CLOSE_LABEL = "done"
        DAY_SECONDS = 86_400
        ELIGIBLE_EVIDENCE = %i[agent_done process_exited].freeze

        attr_reader :retention_days

        # @param executor [Molecules::HerdrExecutor] the exclusive native seam
        # @param record_store [Molecules::DeliveryRecordStore] record access
        # @param deliveries_dir [String] delivery record directory
        # @param retention_days [Integer] archive delivered records strictly
        #   older than this many days (age = record updated_at)
        # @param clock [#now] time source for the retention cutoff
        def initialize(executor:, record_store: Molecules::DeliveryRecordStore,
          deliveries_dir:, retention_days: DEFAULT_RETENTION_DAYS, clock: Time)
          @executor = executor
          @record_store = record_store
          @deliveries_dir = deliveries_dir
          @retention_days =
            begin
              Integer(retention_days)
            rescue ArgumentError, TypeError
              raise ValidationError, "tidy.delivered_retention_days must be a non-negative integer"
            end
          raise ValidationError, "tidy.delivered_retention_days must be a non-negative integer" if @retention_days.negative?

          @clock = clock
        end

        # Classify cleanup candidates (and everything preserved) and, with
        # apply:, perform the mutations. Returns the deterministic report
        # hash the CLI renders as one JSON line.
        def run(apply: false)
          report = {
            apply: apply,
            retention_days: @retention_days,
            panes: {candidates: [], preserved: [], closed: [], excluded: []},
            deliveries: {candidates: [], protected: [], archived: [], preserved: []}
          }

          # Discovery probes everything before any mutation; a probe failure
          # here (unavailable runtime) aborts with no partial report.
          classify_panes!(report)
          classify_deliveries!(report)
          close_panes!(report) if apply
          archive_deliveries!(report) if apply
          report
        end

        private

        # --- discovery ---------------------------------------------------------

        def classify_panes!(report)
          pane_ids = pane_rows.map { |row| row["pane_id"] }

          pane_ids.each do |pane_id|
            evidence = Molecules::PaneTidyProbe.pane_evidence(@executor, pane_id)
            if ELIGIBLE_EVIDENCE.include?(evidence)
              report[:panes][:candidates] << {id: pane_id, evidence: evidence.to_s}
            else
              report[:panes][:preserved] << {id: pane_id, reason: evidence.to_s}
            end
          end

          report[:panes][:candidates].sort_by! { |entry| entry[:id].to_s }
          report[:panes][:preserved].sort_by! { |entry| entry[:id].to_s }
        end

        def classify_deliveries!(report)
          @record_store.list_records(@deliveries_dir).each do |entry|
            event_id = entry[:event_id]
            record = entry[:record]
            if record.nil?
              report[:deliveries][:preserved] << {event_id: event_id, reason: "unreadable"}
            elsif record.state != "delivered"
              report[:deliveries][:protected] << {event_id: event_id, state: record.state}
            elsif (updated_at = parse_updated_at(record))
              entry = {event_id: event_id, updated_at: record.updated_at}
              if updated_at < cutoff
                report[:deliveries][:candidates] << entry
              else
                report[:deliveries][:protected] << {event_id: event_id, state: record.state}
              end
            else
              report[:deliveries][:preserved] << {event_id: event_id, reason: "invalid_updated_at"}
            end
          end

          sort_delivery_entries!(report)
        end

        # --- apply ---------------------------------------------------------------

        # Re-probe every candidate immediately before mutating: close only on
        # still-positive evidence, rename -> close (vs0 close semantics)
        def close_panes!(report)
          report[:panes][:candidates].each do |candidate|
            pane_id = candidate[:id]
            evidence = Molecules::PaneTidyProbe.pane_evidence(@executor, pane_id)
            unless ELIGIBLE_EVIDENCE.include?(evidence)
              report[:panes][:excluded] << {id: pane_id, reason: evidence.to_s}
              next
            end

            @executor.pane_rename(pane_id, CLOSE_LABEL)
            @executor.pane_close(pane_id)
            report[:panes][:closed] << {id: pane_id}
          end
        end

        # Re-load each candidate under its per-event lock and archive only
        # when it still proves eligible; a changed, vanished, or unreadable
        # record stays in place and is reported as preserved
        def archive_deliveries!(report)
          report[:deliveries][:candidates].each do |candidate|
            event_id = candidate[:event_id]
            fresh =
              begin
                @record_store.load(@deliveries_dir, event_id)
              rescue JSON::ParserError, ArgumentError, Errno::EACCES
                :unreadable
              end
            if fresh == :unreadable
              report[:deliveries][:preserved] << {event_id: event_id, reason: "unreadable"}
              next
            end

            archive_path = nil
            @record_store.with_lock(@deliveries_dir, event_id) do
              next unless fresh&.delivered? && older_than_retention?(fresh)

              archive_path = @record_store.archive(@deliveries_dir, event_id)
            end
            if archive_path
              report[:deliveries][:archived] << {event_id: event_id, archive_path: archive_path}
            else
              report[:deliveries][:preserved] << {event_id: event_id, reason: "changed"}
            end
          end
        end

        # --- shared helpers ------------------------------------------------------

        # Native list response nests rows under result.panes; anything else
        # is an explicit empty state, never an error
        def pane_rows
          parsed = @executor.pane_list.parsed_json
          rows = parsed.is_a?(Hash) && parsed["result"].is_a?(Hash) ? parsed["result"]["panes"] : nil
          rows.is_a?(Array) ? rows : []
        end

        def cutoff
          @clock.now - @retention_days * DAY_SECONDS
        end

        def older_than_retention?(record)
          updated_at = parse_updated_at(record)
          updated_at && updated_at < cutoff
        end

        # RFC 3339 / ISO 8601 only; anything else fails closed (nil)
        def parse_updated_at(record)
          Time.iso8601(record.updated_at)
        rescue ArgumentError, TypeError
          nil
        end

        def sort_delivery_entries!(report)
          %i[candidates protected archived preserved].each do |bucket|
            report[:deliveries][bucket].sort_by! { |entry| entry[:event_id].to_s }
          end
        end
      end
    end
  end
end
