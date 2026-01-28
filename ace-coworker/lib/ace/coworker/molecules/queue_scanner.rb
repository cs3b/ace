# frozen_string_literal: true

module Ace
  module Coworker
    module Molecules
      # Scans and builds queue state from step files.
      #
      # Reconstructs queue by scanning jobs/*.md files, sorting them,
      # and parsing each file to build the complete queue state.
      class QueueScanner
        # Scan a jobs directory and build queue state
        #
        # @param jobs_dir [String] Path to jobs directory
        # @param session [Models::Session] Session metadata
        # @return [Models::QueueState] Queue state
        def scan(jobs_dir, session:)
          return Models::QueueState.new(steps: [], session: session) unless File.directory?(jobs_dir)

          # Get all step files
          files = Dir.glob(File.join(jobs_dir, "*.md"))

          # Sort files
          sorted_files = Atoms::StepSorter.sort(files.map { |f| File.basename(f) })
                                          .map { |f| File.join(jobs_dir, f) }

          # Parse each file into a Step
          steps = sorted_files.map { |file| parse_step_file(file) }.compact

          Models::QueueState.new(steps: steps, session: session)
        end

        # Get current step from queue
        #
        # @param jobs_dir [String] Path to jobs directory
        # @param session [Models::Session] Session metadata
        # @return [Models::Step, nil] Current in-progress step
        def current(jobs_dir, session:)
          state = scan(jobs_dir, session: session)
          state.current
        end

        # Get all step numbers in the queue
        #
        # @param jobs_dir [String] Path to jobs directory
        # @return [Array<String>] Step numbers
        def step_numbers(jobs_dir)
          return [] unless File.directory?(jobs_dir)

          files = Dir.glob(File.join(jobs_dir, "*.md"))
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

          Models::Step.new(
            number: filename_info[:number],
            name: fields[:name] || filename_info[:name],
            status: fields[:status],
            instructions: fields[:instructions],
            report: fields[:report],
            error: fields[:error],
            started_at: fields[:started_at],
            completed_at: fields[:completed_at],
            added_by: fields[:added_by],
            parent: fields[:parent],
            file_path: file_path
          )
        rescue StandardError => e
          warn "Failed to parse step file #{file_path}: #{e.message}" if Ace::Coworker.debug?
          nil
        end
      end
    end
  end
end
