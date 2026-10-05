require "json"
manifest = JSON.parse(File.read("/opt/ace-gems/manifest.json"))
manifest.flat_map { |row| row.fetch("dependencies") }.reject { |dep| dep.fetch("local") }.uniq { |dep| [dep.fetch("name"), dep.fetch("requirement")] }.each do |dep|
  abort "external gem install failed" unless system("gem", "install", dep.fetch("name"), "--version", dep.fetch("requirement"), "--no-document")
end
Dir.glob("/opt/ace-gems/*.gem").each do |path|
  abort "ACE gem install failed" unless system("gem", "install", path, "--local", "--ignore-dependencies", "--no-document")
end
