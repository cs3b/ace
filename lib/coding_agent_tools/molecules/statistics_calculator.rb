# frozen_string_literal: true

module CodingAgentTools::Molecules
  # Molecule for calculating statistics about documentation dependencies
  # Provides various metrics and analysis of the dependency graph
  class StatisticsCalculator
    # Calculate basic dependency statistics
    def calculate_basic_stats(dependencies)
      {
        total_files: dependencies.count,
        files_with_outgoing_refs: dependencies.count { |_, deps| deps[:refs_to].any? },
        files_with_incoming_refs: dependencies.count { |_, deps| deps[:refs_from].any? },
        total_references: dependencies.sum { |_, deps| deps[:refs_to].size },
        average_outgoing_refs: calculate_average_outgoing(dependencies),
        average_incoming_refs: calculate_average_incoming(dependencies)
      }
    end

    # Find most referenced files (highest incoming reference count)
    def most_referenced_files(dependencies, limit = 10)
      dependencies
        .select { |_, deps| deps[:refs_from].any? }
        .sort_by { |_, deps| -deps[:refs_from].size }
        .first(limit)
        .map { |file, deps| {file: file, reference_count: deps[:refs_from].size} }
    end

    # Find files with most outgoing references
    def most_referencing_files(dependencies, limit = 10)
      dependencies
        .select { |_, deps| deps[:refs_to].any? }
        .sort_by { |_, deps| -deps[:refs_to].size }
        .first(limit)
        .map { |file, deps| {file: file, reference_count: deps[:refs_to].size} }
    end

    # Find orphaned files (no incoming or outgoing references)
    def find_orphaned_files(dependencies)
      dependencies
        .select { |_, deps| deps[:refs_from].empty? && deps[:refs_to].empty? }
        .keys
        .sort
    end

    # Find isolated files (no incoming references, but may have outgoing)
    def find_isolated_files(dependencies)
      dependencies
        .select { |_, deps| deps[:refs_from].empty? }
        .keys
        .sort
    end

    # Find hub files (high incoming and outgoing references)
    def find_hub_files(dependencies, min_incoming = 3, min_outgoing = 3)
      dependencies
        .select do |_, deps|
          deps[:refs_from].size >= min_incoming && deps[:refs_to].size >= min_outgoing
        end
        .map do |file, deps|
          {
            file: file,
            incoming_count: deps[:refs_from].size,
            outgoing_count: deps[:refs_to].size,
            total_connections: deps[:refs_from].size + deps[:refs_to].size
          }
        end
        .sort_by { |hub| -hub[:total_connections] }
    end

    # Calculate file type distribution
    def calculate_file_type_distribution(dependencies)
      distribution = Hash.new(0)

      dependencies.each_key do |file|
        type = categorize_file_type(file)
        distribution[type] += 1
      end

      distribution
    end

    # Get reference patterns (which file types reference which)
    def analyze_reference_patterns(dependencies)
      patterns = Hash.new { |h, k| h[k] = Hash.new(0) }

      dependencies.each do |from_file, deps|
        from_type = categorize_file_type(from_file)

        deps[:refs_to].each do |to_file|
          to_type = categorize_file_type(to_file)
          patterns[from_type][to_type] += 1
        end
      end

      patterns
    end

    private

    def calculate_average_outgoing(dependencies)
      return 0.0 if dependencies.empty?

      total_outgoing = dependencies.sum { |_, deps| deps[:refs_to].size }
      (total_outgoing.to_f / dependencies.count).round(2)
    end

    def calculate_average_incoming(dependencies)
      return 0.0 if dependencies.empty?

      total_incoming = dependencies.sum { |_, deps| deps[:refs_from].size }
      (total_incoming.to_f / dependencies.count).round(2)
    end

    def categorize_file_type(file)
      case file
      when /\.wf\.md$/
        :workflow
      when /\.g\.md$/
        :guide
      when /tasks.*\.md$/
        :task
      when /^docs\//
        :documentation
      when /^dev-taskflow\//
        :taskflow
      else
        :other
      end
    end
  end
end
