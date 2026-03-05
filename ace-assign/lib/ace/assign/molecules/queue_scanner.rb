# frozen_string_literal: true

module Ace
  module Assign
    module Molecules
      # Scans and builds queue state from phase files.
      #
      # Reconstructs queue by scanning phases/*.md files, sorting them,
      # and parsing each file to build the complete queue state.
      class QueueScanner
        # Scan a phases directory and build queue state
        #
        # @param phases_dir [String] Path to phases directory
        # @param assignment [Models::Assignment] Assignment metadata
        # @return [Models::QueueState] Queue state
        def scan(phases_dir, assignment:)
          return Models::QueueState.new(phases: [], assignment: assignment) unless File.directory?(phases_dir)

          # Get all phase files
          files = Dir.glob(File.join(phases_dir, "*.ph.md"))

          # Sort files
          sorted_files = Atoms::PhaseSorter.sort(files.map { |f| File.basename(f) })
                                           .map { |f| File.join(phases_dir, f) }

          # Parse each file into a Phase
          phases = sorted_files.map { |file| parse_phase_file(file) }.compact

          Models::QueueState.new(phases: phases, assignment: assignment)
        end

        # Get current phase from queue
        #
        # @param phases_dir [String] Path to phases directory
        # @param assignment [Models::Assignment] Assignment metadata
        # @return [Models::Phase, nil] Current in-progress phase
        def current(phases_dir, assignment:)
          state = scan(phases_dir, assignment: assignment)
          state.current
        end

        # Get all phase numbers in the queue
        #
        # @param phases_dir [String] Path to phases directory
        # @return [Array<String>] Phase numbers
        def phase_numbers(phases_dir)
          return [] unless File.directory?(phases_dir)

          files = Dir.glob(File.join(phases_dir, "*.ph.md"))
          files.map do |file|
            parsed = Atoms::PhaseFileParser.parse_filename(File.basename(file))
            parsed[:number]
          end.compact
        end

        private

        def parse_phase_file(file_path)
          content = File.read(file_path)
          parsed = Atoms::PhaseFileParser.parse(content)
          fields = Atoms::PhaseFileParser.extract_fields(parsed)

          # Extract number and name from filename
          filename_info = Atoms::PhaseFileParser.parse_filename(File.basename(file_path))

          # Load report from separate file if it exists
          report = load_report(file_path, filename_info[:number], filename_info[:name])

          Models::Phase.new(
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
            context: fields[:context],
            stall_reason: fields[:stall_reason],
            file_path: file_path
          )
        rescue ArgumentError => e
          # ArgumentError indicates invalid data (e.g., invalid context value)
          # Surface these errors visibly to help users fix configuration
          warn "Invalid phase file #{file_path}: #{e.message}"
          nil
        rescue StandardError => e
          warn "Failed to parse phase file #{file_path}: #{e.message}" if Ace::Assign.debug?
          nil
        end

        # Load report from the reports/ directory
        # @param phase_file_path [String] Path to phase file
        # @param number [String] Phase number
        # @param name [String] Phase name
        # @return [String, nil] Report content or nil
        def load_report(phase_file_path, number, name)
          # reports/ is sibling of phases/
          phases_dir = File.dirname(phase_file_path)
          cache_dir = File.dirname(phases_dir)
          reports_dir = File.join(cache_dir, "reports")

          return nil unless File.directory?(reports_dir)

          report_filename = Atoms::PhaseFileParser.generate_report_filename(number, name)
          report_path = File.join(reports_dir, report_filename)

          return nil unless File.exist?(report_path)

          # Read report file and extract body (skip frontmatter)
          content = File.read(report_path)
          parsed = Atoms::PhaseFileParser.parse(content)
          parsed[:body].strip
        end
      end
    end
  end
end
