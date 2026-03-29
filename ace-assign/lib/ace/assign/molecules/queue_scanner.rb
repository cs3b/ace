# frozen_string_literal: true

module Ace
  module Assign
    module Molecules
      # Scans and builds queue state from step files.
      #
      # Reconstructs queue by scanning steps/*.md files, sorting them,
      # and parsing each file to build the complete queue state.
      class QueueScanner
        # Scan a steps directory and build queue state
        #
        # @param steps_dir [String] Path to steps directory
        # @param assignment [Models::Assignment] Assignment metadata
        # @return [Models::QueueState] Queue state
        def scan(steps_dir, assignment:)
          return Models::QueueState.new(steps: [], assignment: assignment) unless File.directory?(steps_dir)

          # Get all step files
          files = Dir.glob(File.join(steps_dir, "*.st.md"))

          # Sort files
          sorted_files = Atoms::StepSorter.sort(files.map { |f| File.basename(f) })
            .map { |f| File.join(steps_dir, f) }

          # Parse each file into a Step
          steps = sorted_files.map { |file| parse_step_file(file) }.compact

          Models::QueueState.new(steps: steps, assignment: assignment)
        end

        # Get current step from queue
        #
        # @param steps_dir [String] Path to steps directory
        # @param assignment [Models::Assignment] Assignment metadata
        # @return [Models::Step, nil] Current in-progress step
        def current(steps_dir, assignment:)
          state = scan(steps_dir, assignment: assignment)
          state.current
        end

        # Get all step numbers in the queue
        #
        # @param steps_dir [String] Path to steps directory
        # @return [Array<String>] Step numbers
        def step_numbers(steps_dir)
          return [] unless File.directory?(steps_dir)

          files = Dir.glob(File.join(steps_dir, "*.st.md"))
          files.map do |file|
            parsed = Atoms::StepFileParser.parse_filename(File.basename(file))
            parsed[:number]
          end.compact
        end

        private

        def parse_step_file(file_path)
          content = File.read(file_path)
          parsed = Atoms::StepFileParser.parse(content)
          fields = Atoms::StepFileParser.extract_fields(parsed)

          # Extract number and name from filename
          filename_info = Atoms::StepFileParser.parse_filename(File.basename(file_path))

          # Load report from separate file if it exists
          report = load_report(file_path, filename_info[:number], filename_info[:name])

          Models::Step.new(
            number: filename_info[:number],
            name: fields[:name] || filename_info[:name],
            status: fields[:status],
            instructions: fields[:instructions],
            report: report,
            error: fields[:error],
            started_at: fields[:started_at],
            completed_at: fields[:completed_at],
            fork_launch_pid: fields[:fork_launch_pid],
            fork_tracked_pids: fields[:fork_tracked_pids],
            fork_pid_updated_at: fields[:fork_pid_updated_at],
            fork_pid_file: fields[:fork_pid_file],
            added_by: fields[:added_by],
            parent: fields[:parent],
            skill: fields[:skill],
            workflow: fields[:workflow],
            context: fields[:context],
            batch_parent: fields[:batch_parent],
            parallel: fields[:parallel],
            max_parallel: fields[:max_parallel],
            fork_retry_limit: fields[:fork_retry_limit],
            fork_options: fields[:fork_options],
            stall_reason: fields[:stall_reason],
            file_path: file_path
          )
        rescue ArgumentError => e
          # ArgumentError indicates invalid data (e.g., invalid context value)
          # Surface these errors visibly to help users fix configuration
          warn "Invalid step file #{file_path}: #{e.message}"
          nil
        rescue => e
          warn "Failed to parse step file #{file_path}: #{e.message}" if Ace::Assign.debug?
          nil
        end

        # Load report from the reports/ directory
        # @param step_file_path [String] Path to step file
        # @param number [String] Step number
        # @param name [String] Step name
        # @return [String, nil] Report content or nil
        def load_report(step_file_path, number, name)
          # reports/ is sibling of steps/
          steps_dir = File.dirname(step_file_path)
          cache_dir = File.dirname(steps_dir)
          reports_dir = File.join(cache_dir, "reports")

          return nil unless File.directory?(reports_dir)

          report_filename = Atoms::StepFileParser.generate_report_filename(number, name)
          report_path = File.join(reports_dir, report_filename)

          return nil unless File.exist?(report_path)

          # Read report file and extract body (skip frontmatter)
          content = File.read(report_path)
          parsed = Atoms::StepFileParser.parse(content)
          parsed[:body].strip
        end
      end
    end
  end
end
