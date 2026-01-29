# frozen_string_literal: true

require "fileutils"
require "yaml"

module Ace
  module Coworker
    module Organisms
      # Orchestrates workflow operations on the work queue.
      #
      # Implements the state machine for queue operations:
      # start → advance → complete (with fail/add/retry branches)
      class WorkflowExecutor
        attr_reader :session_manager, :queue_scanner, :step_writer

        def initialize(cache_base: nil)
          @session_manager = Molecules::SessionManager.new(cache_base: cache_base)
          @queue_scanner = Molecules::QueueScanner.new
          @step_writer = Molecules::StepWriter.new
        end

        # Start a new workflow session from config file
        #
        # @param config_path [String] Path to job.yaml config
        # @return [Hash] Result with session and first step
        def start(config_path)
          raise ConfigNotFoundError, "Config file not found: #{config_path}" unless File.exist?(config_path)

          config = YAML.safe_load_file(config_path, permitted_classes: [Time, Date])
          session_config = config["session"] || {}
          steps_config = config["steps"] || []

          raise Error, "No steps defined in config" if steps_config.empty?

          # Create session
          session = session_manager.create(
            name: session_config["name"] || File.basename(config_path, ".yaml"),
            description: session_config["description"],
            source_config: config_path
          )

          # Create initial step files
          steps_config.each_with_index do |step, index|
            number = Atoms::NumberGenerator.from_index(index)
            extra = step.reject { |k, _| %w[name instructions].include?(k) }
            step_writer.create(
              jobs_dir: session.jobs_dir,
              number: number,
              name: step["name"],
              instructions: normalize_instructions(step["instructions"]),
              status: :pending,
              extra: extra
            )
          end

          # Mark first step as in_progress
          first_step_file = Dir.glob(File.join(session.jobs_dir, "*.j.md")).min
          step_writer.mark_in_progress(first_step_file) if first_step_file

          # Archive source config into task's jobs directory and update session metadata
          archived_path = archive_source_config(config_path, session.id)
          session = Models::Session.new(
            id: session.id,
            name: session.name,
            description: session.description,
            created_at: session.created_at,
            updated_at: session.updated_at,
            source_config: archived_path,
            cache_dir: session.cache_dir
          )
          session_manager.update(session)

          # Return result
          state = queue_scanner.scan(session.jobs_dir, session: session)
          {
            session: session,
            state: state,
            current: state.current
          }
        end

        # Get current session and queue state
        #
        # @return [Hash] Result with session and state
        def status
          session = session_manager.find_active
          raise NoActiveSessionError, "No active session. Use 'ace-coworker create <job.yaml>' to begin." unless session

          state = queue_scanner.scan(session.jobs_dir, session: session)
          {
            session: session,
            state: state,
            current: state.current
          }
        end

        # Complete current step with report and advance
        #
        # @param report_path [String] Path to report file
        # @return [Hash] Result with updated state
        def advance(report_path)
          raise Error, "Report file not found: #{report_path}" unless File.exist?(report_path)

          session = session_manager.find_active
          raise NoActiveSessionError, "No active session. Use 'ace-coworker create <job.yaml>' to begin." unless session

          state = queue_scanner.scan(session.jobs_dir, session: session)
          current = state.current
          raise Error, "No step currently in progress. Try 'ace-coworker add' to add a new step or 'ace-coworker retry' to retry a failed step." unless current

          # Read report content
          report_content = File.read(report_path)

          # Mark current step as done
          step_writer.mark_done(current.file_path, report_content: report_content, reports_dir: session.reports_dir)

          # Advance to next step
          next_step = state.next_pending
          if next_step
            step_writer.mark_in_progress(next_step.file_path)
          end

          # Update session timestamp
          session_manager.update(session)

          # Return updated state
          new_state = queue_scanner.scan(session.jobs_dir, session: session)
          {
            session: session,
            state: new_state,
            completed: current,
            current: new_state.current
          }
        end

        # Mark current step as failed
        #
        # @param message [String] Error message
        # @return [Hash] Result with updated state
        def fail(message)
          session = session_manager.find_active
          raise NoActiveSessionError, "No active session. Use 'ace-coworker create <job.yaml>' to begin." unless session

          state = queue_scanner.scan(session.jobs_dir, session: session)
          current = state.current
          raise Error, "No step currently in progress. Try 'ace-coworker add' to add a new step or 'ace-coworker retry' to retry a failed step." unless current

          # Mark step as failed
          step_writer.mark_failed(current.file_path, error_message: message)

          # Update session timestamp
          session_manager.update(session)

          # Return updated state (no automatic advancement after failure)
          new_state = queue_scanner.scan(session.jobs_dir, session: session)
          {
            session: session,
            state: new_state,
            failed: current
          }
        end

        # Add a new step dynamically
        #
        # @param name [String] Step name
        # @param instructions [String] Step instructions
        # @return [Hash] Result with new step
        def add(name, instructions)
          session = session_manager.find_active
          raise NoActiveSessionError, "No active session. Use 'ace-coworker create <job.yaml>' to begin." unless session

          state = queue_scanner.scan(session.jobs_dir, session: session)

          # Determine insertion point
          # If there's a current in_progress step, insert after it
          # Otherwise, insert after last done step (or at beginning if all pending)
          existing_numbers = queue_scanner.step_numbers(session.jobs_dir)

          base_number = if state.current
                          state.current.number
                        elsif state.last_done
                          state.last_done.number
                        else
                          "000" # Will generate 001
                        end

          new_number = Atoms::NumberGenerator.next_after(base_number, existing_numbers)

          # Determine initial status upfront to avoid redundant I/O
          initial_status = state.current ? :pending : :in_progress

          # Create new step file with correct status
          file_path = step_writer.create(
            jobs_dir: session.jobs_dir,
            number: new_number,
            name: name,
            instructions: instructions,
            status: initial_status,
            added_by: "dynamic"
          )

          # Update session timestamp
          session_manager.update(session)

          # Return updated state
          new_state = queue_scanner.scan(session.jobs_dir, session: session)
          new_step = new_state.steps.find { |s| s.number == new_number }

          {
            session: session,
            state: new_state,
            added: new_step
          }
        end

        # Retry a failed step (creates new step linked to original)
        #
        # @param step_ref [String] Step number or reference to retry
        # @return [Hash] Result with new retry step
        def retry_step(step_ref)
          session = session_manager.find_active
          raise NoActiveSessionError, "No active session. Use 'ace-coworker create <job.yaml>' to begin." unless session

          state = queue_scanner.scan(session.jobs_dir, session: session)

          # Find the step to retry
          original = state.find_by_number(step_ref.to_s)
          raise StepNotFoundError, "Step #{step_ref} not found in queue" unless original

          # Get existing numbers
          existing_numbers = queue_scanner.step_numbers(session.jobs_dir)

          # Insert after all current steps (at end of queue before pending)
          # Find last done or failed step
          base_number = if state.current
                          state.current.number
                        elsif state.last_done
                          state.last_done.number
                        else
                          original.number
                        end

          new_number = Atoms::NumberGenerator.next_after(base_number, existing_numbers)

          # Create retry step with link to original
          file_path = step_writer.create(
            jobs_dir: session.jobs_dir,
            number: new_number,
            name: original.name,
            instructions: original.instructions,
            status: :pending,
            added_by: "retry_of:#{original.number}"
          )

          # Update session timestamp
          session_manager.update(session)

          # Return updated state
          new_state = queue_scanner.scan(session.jobs_dir, session: session)
          retry_step = new_state.steps.find { |s| s.number == new_number }

          {
            session: session,
            state: new_state,
            retry: retry_step,
            original: original
          }
        end

        private

        # Archive source config into the task's jobs/ directory.
        # Moves job.yaml to <task>/jobs/<session_id>-job.yml for provenance.
        #
        # @param config_path [String] Path to the original job.yaml
        # @param session_id [String] Session identifier for filename prefix
        # @return [String] Path to archived file
        def archive_source_config(config_path, session_id)
          task_dir = File.dirname(File.expand_path(config_path))
          jobs_dir = File.join(task_dir, "jobs")
          FileUtils.mkdir_p(jobs_dir)

          dest = File.join(jobs_dir, "#{session_id}-job.yml")
          FileUtils.mv(File.expand_path(config_path), dest)
          dest
        end

        # Normalize instructions to a string.
        # Accepts arrays (joined with newlines) or strings (returned as-is).
        #
        # @param instructions [Array<String>, String, nil] Raw instructions from config
        # @return [String] Normalized instruction text
        def normalize_instructions(instructions)
          return "" if instructions.nil?

          instructions.is_a?(Array) ? instructions.join("\n") : instructions.to_s
        end
      end
    end
  end
end
