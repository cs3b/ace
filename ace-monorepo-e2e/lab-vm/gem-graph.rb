# frozen_string_literal: true

require "json"
require "rubygems/package"
require "rubygems/dependency_list"
require "rubygems/installer"
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

  def self.install_order(manifest, artifact_dir, roots: ROOTS)
    validate!(manifest, artifact_dir, roots: roots)
    graph = Gem::DependencyList.new
    manifest.fetch("gems").each do |entry|
      graph.add(Gem::Package.new(File.join(artifact_dir, "#{entry.fetch('name')}-#{entry.fetch('version')}.gem")).spec)
    end
    graph.tsort # Detect cycles before installing anything.
  end

  # Only the installer and index tool need bootstrap installation. All other
  # exact pins are installed by ace-lab using the dependency-first plan.
  def self.bootstrap!(manifest, artifact_dir, roots: ROOTS,
    bootstrap_roots: %w[ace-lab rubygems-generate_index])
    ordered = install_order(manifest, artifact_dir, roots: roots)
    specs = ordered.to_h { |spec| [spec.name, spec] }
    selected = Set.new
    pending = bootstrap_roots.dup
    until pending.empty?
      name = pending.pop
      next unless selected.add?(name)
      specs.fetch(name).runtime_dependencies.each do |dependency|
        pending << dependency.name if specs.key?(dependency.name)
      end
    end
    ordered.select { |spec| selected.include?(spec.name) }.each do |spec|
      archive = File.join(artifact_dir, "#{spec.full_name}.gem")
      Gem::Installer.at(archive, install_dir: ENV.fetch("GEM_HOME"), wrappers: true).install
    end
  end

end

if $PROGRAM_NAME == __FILE__
  manifest = JSON.parse(File.read(ARGV.fetch(0)))
  ordered = LabVmGemGraph.install_order(manifest, ARGV.fetch(1))
  LabVmGemGraph.bootstrap!(manifest, ARGV.fetch(1)) if ARGV[3] == "--bootstrap"
  File.write(ARGV.fetch(2), JSON.generate(ordered.map(&:name)) + "\n")
  puts "verified complete pinned dependency graph: #{manifest.fetch('gems').length} gems, #{LabVmGemGraph::ROOTS.length} roots"
end
