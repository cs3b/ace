# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Atom for distributing errors evenly across multiple files
      # Ensures one issue per file for agent processing
      class ErrorDistributor
        DEFAULT_MAX_FILES = 4

        attr_reader :max_files, :one_issue_per_file

        def initialize(options = {})
          @max_files = options[:max_files] || DEFAULT_MAX_FILES
          @one_issue_per_file = options.fetch(:one_issue_per_file, true)
        end

        def distribute(errors)
          return { distributions: [], total_errors: 0 } if errors.empty?

          grouped_errors = group_errors_by_file(errors)
          distributions = create_distributions(grouped_errors)
          
          {
            distributions: distributions,
            total_errors: errors.size,
            files_with_errors: grouped_errors.keys.size
          }
        end

        private

        def group_errors_by_file(errors)
          grouped = {}
          
          errors.each do |error|
            file = error[:file] || error["file"] || "unknown"
            grouped[file] ||= []
            grouped[file] << error
          end
          
          grouped
        end

        def create_distributions(grouped_errors)
          distributions = Array.new(max_files) { [] }
          
          if one_issue_per_file
            distribute_one_per_file(grouped_errors, distributions)
          else
            distribute_evenly(grouped_errors, distributions)
          end
          
          # Remove empty distributions
          distributions.reject(&:empty?).map.with_index do |errors, idx|
            {
              file_number: idx + 1,
              errors: errors,
              error_count: errors.size
            }
          end
        end

        def distribute_one_per_file(grouped_errors, distributions)
          file_index = 0
          
          grouped_errors.each do |file, errors|
            # Take only the first error from each file
            error = errors.first
            
            # Distribute to next available distribution
            dist_index = file_index % max_files
            distributions[dist_index] << error
            
            file_index += 1
          end
        end

        def distribute_evenly(grouped_errors, distributions)
          all_errors = grouped_errors.values.flatten
          
          all_errors.each_with_index do |error, idx|
            dist_index = idx % max_files
            distributions[dist_index] << error
          end
        end
      end
    end
  end
end