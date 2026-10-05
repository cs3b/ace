require "rubygems/package"
require "json"
require "fileutils"
root = Dir.pwd
out = File.join(root, ".ace-local/09j-vm/gems")
FileUtils.mkdir_p(out)
specs = Dir.glob("ace-*/*.gemspec").to_h do |path|
  spec = Dir.chdir(File.dirname(path)) { Gem::Specification.load(File.basename(path)) }
  [spec.name, [File.dirname(path), spec]]
end
names = []; pending = ["ace-assign"]
until pending.empty?
  name = pending.shift
  next if names.include?(name)
  dir, spec = specs.fetch(name)
  names << name
  pending.concat(spec.runtime_dependencies.map(&:name).select { |dep| specs.key?(dep) })
end
manifest = names.sort.map do |name|
  dir, spec = specs.fetch(name)
  file = Dir.chdir(dir) { Gem::Package.build(spec, false, false, File.join(out, "#{name}-#{spec.version}.gem")) }
  {name: name, version: spec.version.to_s, file: File.basename(file), dependencies: spec.runtime_dependencies.map { |dep| {name: dep.name, requirement: dep.requirement.to_s, local: names.include?(dep.name)} }}
end
File.write(File.join(out, "manifest.json"), JSON.pretty_generate(manifest) + "\n")
