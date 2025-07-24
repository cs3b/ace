# frozen_string_literal: true

require "set"

module CodingAgentTools::Molecules
  # Molecule for detecting circular dependencies in documentation
  # Uses depth-first search to find cycles in the dependency graph
  class CircularDependencyDetector
    # Find all circular dependencies in the dependencies graph
    def find_cycles(dependencies)
      circular = Set.new

      dependencies.each_key do |file|
        visited = Set.new
        path = []
        recursion_stack = Set.new

        if has_cycle?(file, dependencies, visited, path, recursion_stack)
          # Extract the cycle from the path
          cycle_start = path.rindex(path.last)
          cycle = path[cycle_start..] if cycle_start
          circular << cycle.sort if cycle && cycle.length > 1
        end
      end

      circular.to_a
    end

    # Check if there's a cycle starting from the given node
    def has_cycle?(node, dependencies, visited, path, recursion_stack)
      visited << node
      recursion_stack << node
      path << node

      # Check all neighbors (files this node references)
      dependencies[node][:refs_to].each do |neighbor|
        if !visited.include?(neighbor)
          return true if has_cycle?(neighbor, dependencies, visited, path, recursion_stack)
        elsif recursion_stack.include?(neighbor)
          # Found a cycle - add the closing node to complete the cycle
          path << neighbor
          return true
        end
      end

      path.pop
      recursion_stack.delete(node)
      false
    end

    # Find strongly connected components (groups of mutually referencing files)
    def find_strongly_connected_components(dependencies)
      # Tarjan's algorithm for finding SCCs
      index = 0
      stack = []
      indices = {}
      lowlinks = {}
      on_stack = Set.new
      sccs = []

      dependencies.each_key do |node|
        next if indices.key?(node)

        tarjan_scc(node, dependencies, index, stack, indices, lowlinks, on_stack, sccs)
      end

      # Filter out single-node SCCs (not really circular)
      sccs.select { |scc| scc.length > 1 }
    end

    private

    def tarjan_scc(v, dependencies, index, stack, indices, lowlinks, on_stack, sccs)
      indices[v] = index
      lowlinks[v] = index
      index += 1
      stack.push(v)
      on_stack << v

      dependencies[v][:refs_to].each do |w|
        if !indices.key?(w)
          tarjan_scc(w, dependencies, index, stack, indices, lowlinks, on_stack, sccs)
          lowlinks[v] = [lowlinks[v], lowlinks[w]].min
        elsif on_stack.include?(w)
          lowlinks[v] = [lowlinks[v], indices[w]].min
        end
      end

      if lowlinks[v] == indices[v]
        scc = []
        loop do
          w = stack.pop
          on_stack.delete(w)
          scc << w
          break if w == v
        end
        sccs << scc if scc.length > 0
      end
    end

    # Check if a specific path creates a cycle
    def creates_cycle?(from, to, dependencies)
      # Simple check: if 'to' has a path back to 'from'
      visited = Set.new
      path_exists?(to, from, dependencies, visited)
    end

    def path_exists?(from, to, dependencies, visited)
      return false if visited.include?(from)
      return true if from == to

      visited << from

      dependencies[from][:refs_to].any? do |neighbor|
        path_exists?(neighbor, to, dependencies, visited)
      end
    end
  end
end
