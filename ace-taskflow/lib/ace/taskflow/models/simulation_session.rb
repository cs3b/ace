# frozen_string_literal: true

require "time"
require "ace/b36ts"

module Ace
  module Taskflow
    module Models
      # Immutable data model for next-phase simulation run state.
      class SimulationSession
        attr_reader :run_id, :source, :modes, :status, :started_at, :finished_at, :artifacts, :failed_stage, :error

        def initialize(run_id:, source:, modes:, status:, started_at:, finished_at: nil, artifacts: {}, failed_stage: nil, error: nil)
          unless Ace::B36ts.valid?(run_id)
            raise ArgumentError, "Invalid run_id format: #{run_id.inspect}. Expected 6-char ace-b36ts ID."
          end

          @run_id = run_id
          @source = source
          @modes = Array(modes).map(&:to_s)
          @status = status.to_s
          @started_at = to_time(started_at)
          @finished_at = finished_at ? to_time(finished_at) : nil
          @artifacts = artifacts
          @failed_stage = failed_stage
          @error = error
        end

        def with_updates(**updates)
          self.class.new(
            run_id: updates.fetch(:run_id, @run_id),
            source: updates.fetch(:source, @source),
            modes: updates.fetch(:modes, @modes),
            status: updates.fetch(:status, @status),
            started_at: updates.fetch(:started_at, @started_at),
            finished_at: updates.fetch(:finished_at, @finished_at),
            artifacts: updates.fetch(:artifacts, @artifacts),
            failed_stage: updates.fetch(:failed_stage, @failed_stage),
            error: updates.fetch(:error, @error)
          )
        end

        def to_h
          {
            run_id: @run_id,
            source: @source,
            modes: @modes,
            status: @status,
            started_at: @started_at.utc.iso8601,
            finished_at: @finished_at&.utc&.iso8601,
            artifacts: @artifacts,
            failed_stage: @failed_stage,
            error: @error
          }.compact
        end

        private

        def to_time(value)
          return value if value.is_a?(Time)

          Time.parse(value.to_s)
        end
      end
    end
  end
end
