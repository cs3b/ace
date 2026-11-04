# frozen_string_literal: true

require "json"
require "rubygems/package"
require "set"

module LabVmGemGraph
  ROOTS = %w[ace-lab ace-git-commit ace-handbook-integration-pi ace-test ace-test-runner
    ace-wake rubygems-generate_index].freeze

  def self.validate!(manifest, artifact_dir, roots: ROOTS)
    entries = manifest.fetch("gems")
    specs = entries.to_h do |gem|
      file = File.join(artifact_dir, "#{gem.fetch('name')}-#{gem.fetch('version')}.gem")
      spec = Gem::Package.new(file).spec
      unless spec.name == gem.fetch("name") && spec.version.to_s == gem.fetch("version") && spec.platform.to_s == "ruby"
        raise ArgumentError, "gem metadata does not match manifest"
      end
      [spec.name, spec]
    end
    raise ArgumentError, "duplicate pinned gem names" unless specs.size == entries.size
    seen = Set.new
    queue = roots.dup
    until queue.empty?
      name = queue.shift
      next if seen.include?(name)
      seen.add(name)
      spec = specs.fetch(name)
      spec.runtime_dependencies.each do |dependency|
        pinned = specs[dependency.name]
        if pinned
          raise ArgumentError, "pinned dependency does not satisfy #{name}" unless dependency.matches_spec?(pinned)
          queue << dependency.name
        else
          builtin = Gem::Specification.find_all_by_name(dependency.name).any? do |candidate|
            candidate.default_gem? && dependency.matches_spec?(candidate)
          end
          raise ArgumentError, "undeclared dependency for #{name}: #{dependency.name}" unless builtin
        end
      end
    end
    raise ArgumentError, "pinned gems are not covered by the install roots" unless seen == specs.keys.to_set
    roots
  end
end

if $PROGRAM_NAME == __FILE__
  manifest = JSON.parse(File.read(ARGV.fetch(0)))
  roots = LabVmGemGraph.validate!(manifest, ARGV.fetch(1))
  File.write(ARGV.fetch(2), JSON.generate(roots) + "\n")
  puts "verified complete pinned dependency graph: #{manifest.fetch('gems').length} gems, #{roots.length} roots"
end
