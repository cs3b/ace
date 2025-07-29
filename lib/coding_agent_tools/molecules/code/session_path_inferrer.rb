# frozen_string_literal: true

require "pathname"

module CodingAgentTools
  module Molecules
    module Code
      # SessionPathInferrer handles automatic inference of session directories from report paths
      # This molecule focuses on session directory detection and path analysis
      class SessionPathInferrer
        # Result class for session path inference
        class InferenceResult
          attr_reader :session_directory, :session_type, :session_id, :metadata

          def initialize(session_directory: nil, session_type: nil, session_id: nil, metadata: {})
            @session_directory = session_directory
            @session_type = session_type
            @session_id = session_id
            @metadata = metadata
          end

          def has_session?
            !@session_directory.nil?
          end

          def no_session?
            @session_directory.nil?
          end
        end

        # Infer session directory from a report file path
        # @param report_path [String] Path to a review report file
        # @return [InferenceResult] Result containing session information
        def infer_session_path(report_path)
          return InferenceResult.new unless report_path && File.exist?(report_path)

          # Convert to absolute path for analysis
          abs_path = File.expand_path(report_path)
          current_dir = File.dirname(abs_path)

          # Try different session detection strategies
          session_info = detect_session_directory(current_dir) ||
            detect_taskflow_session(current_dir) ||
            detect_generic_session(current_dir)

          session_info || InferenceResult.new
        end

        # Infer output path from multiple report paths
        # @param report_paths [Array<String>] Array of report file paths
        # @return [String] Inferred output path for synthesis
        def infer_output_path(report_paths)
          return "/inferred/path.md" if report_paths.empty?

          # Try to infer from the first report
          inference_result = infer_session_path(report_paths.first)

          if inference_result.has_session?
            File.join(inference_result.session_directory, "cr-report.md")
          else
            "cr-report.md"
          end
        end

        private

        # Detect explicit session directory (has session.meta file)
        # @param directory [String] Directory to check
        # @return [InferenceResult, nil] Session information if found
        def detect_session_directory(directory)
          session_meta_path = File.join(directory, "session.meta")

          return nil unless File.exist?(session_meta_path)

          # Parse session metadata
          metadata = parse_session_metadata(session_meta_path)
          session_id = extract_session_id_from_path(directory)

          InferenceResult.new(
            session_directory: directory,
            session_type: "explicit_session",
            session_id: session_id,
            metadata: metadata
          )
        end

        # Detect taskflow-style session directory
        # @param directory [String] Directory to check
        # @return [InferenceResult, nil] Session information if found
        def detect_taskflow_session(directory)
          # Look for taskflow patterns: dev-taskflow/current/*/code_review/*
          path_parts = directory.split(File::SEPARATOR)

          # Find code_review index
          code_review_index = path_parts.rindex("code_review")
          return nil unless code_review_index

          # Check if it's in a taskflow structure
          if code_review_index >= 2 &&
              path_parts[code_review_index - 2] == "dev-taskflow" &&
              path_parts[code_review_index - 1] == "current"

            session_id = path_parts[code_review_index + 1] if path_parts[code_review_index + 1]

            InferenceResult.new(
              session_directory: directory,
              session_type: "taskflow_session",
              session_id: session_id,
              metadata: {"taskflow_pattern" => true}
            )
          end
        end

        # Detect generic session-like directory structure
        # @param directory [String] Directory to check
        # @return [InferenceResult, nil] Session information if found
        def detect_generic_session(directory)
          # Look for session-like indicators in directory structure
          session_indicators = check_session_indicators(directory)

          return nil unless session_indicators[:is_session]

          session_id = extract_session_id_from_path(directory)

          InferenceResult.new(
            session_directory: directory,
            session_type: "inferred_session",
            session_id: session_id,
            metadata: session_indicators
          )
        end

        # Check for session indicators in directory
        # @param directory [String] Directory to check
        # @return [Hash] Session indicators found
        def check_session_indicators(directory)
          indicators = {is_session: false}

          return indicators unless File.directory?(directory)

          # Check for session-like files and patterns
          files = begin
            Dir.entries(directory)
          rescue
            []
          end

          # Session indicator files
          session_files = %w[
            input.diff input.xml project_context.md combined_prompt.md
            README.md session.log synthesis.meta
          ]

          found_session_files = session_files.select { |f| files.include?(f) }
          indicators[:session_files] = found_session_files

          # Report files indicate a session
          report_files = files.select { |f| f.match?(/^cr-report.*\.md$/) }
          indicators[:report_files] = report_files

          # Directory name patterns
          dir_name = File.basename(directory)
          indicators[:timestamp_pattern] = dir_name.match?(/\d{8}-\d{6}/) # YYYYMMDD-HHMMSS
          indicators[:session_name_pattern] = dir_name.match?(/session|review|analysis/)

          # Consider it a session if it has multiple indicators
          session_score = 0
          session_score += 2 if found_session_files.length >= 2
          session_score += 2 if report_files.length >= 1
          session_score += 1 if indicators[:timestamp_pattern]
          session_score += 1 if indicators[:session_name_pattern]

          indicators[:is_session] = session_score >= 3
          indicators[:session_score] = session_score

          indicators
        end

        # Parse session metadata from session.meta file
        # @param meta_path [String] Path to session.meta file
        # @return [Hash] Parsed metadata
        def parse_session_metadata(meta_path)
          metadata = {}

          begin
            content = File.read(meta_path, encoding: "UTF-8")

            # Parse simple key: value pairs
            content.each_line do |line|
              line = line.strip
              next if line.empty? || line.start_with?("#")

              if line.include?(":")
                key, value = line.split(":", 2)
                metadata[key.strip] = value.strip if key && value
              end
            end
          rescue => e
            metadata[:parse_error] = e.message
          end

          metadata
        end

        # Extract session ID from directory path
        # @param directory [String] Directory path
        # @return [String, nil] Extracted session ID
        def extract_session_id_from_path(directory)
          dir_name = File.basename(directory)

          # Try different session ID patterns
          if dir_name.match?(/\d{8}-\d{6}/) # YYYYMMDD-HHMMSS
            dir_name
          elsif dir_name.match?(/session-/)
            dir_name
          elsif dir_name.match?(/review-/)
            dir_name
          else
            # Use last component of path as session ID
            dir_name unless dir_name == "."
          end
        end
      end
    end
  end
end
