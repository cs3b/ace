# frozen_string_literal: true
require "tmpdir"
module Ace
  module Design
    module Molecules
      class SkillSources
        def initialize(config = Design.config)
          @config = config
        end
        def requirements(preset)
          preset.fetch("variants").flat_map do |slot|
            Array(slot["requirements"]).map do |requirement|
              raise Error, "Requirements must be objects with a name" unless requirement.is_a?(Hash) && requirement["name"]
              executable = requirement["executable"]
              available = executable && ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |path|
                file = File.join(path, executable)
                File.file?(file) && File.executable?(file)
              end
              requirement.merge("variant" => slot.fetch("id"), "status" => executable ? (available ? "available" : "missing") : "agent_check")
            end
          end
        end
        def copy_tree(source, target, boundary, ancestors)
          actual = File.realpath(source)
          unless actual == boundary || actual.start_with?(boundary + "/")
            raise Error, "Skill resource link escapes pinned repository: #{source}"
          end
          if File.directory?(actual)
            raise Error, "Cyclic skill resource link: #{source}" if ancestors.include?(actual)
            FileUtils.mkdir_p(target)
            Dir.children(actual).each { |name| copy_tree(File.join(actual, name), File.join(target, name), boundary, ancestors + [actual]) }
          elsif File.file?(actual)
            FileUtils.cp(actual, target, preserve: true)
          else
            raise Error, "Unsupported skill resource: #{source}"
          end
        end
        def snapshot(root, preset)
          preset.fetch("variants").each do |slot|
            Array(slot["skills"]).each_with_index do |spec, index|
              revision = spec.fetch("revision")
              raise Error, "Skill revision must be a full commit SHA" unless /\A[0-9a-f]{40}\z/.match?(revision)
              target = File.join(root, "skills", slot.fetch("id"), index.to_s)
              FileUtils.mkdir_p(target)
              Dir.mktmpdir("ace-design-skill") do |checkout|
                runtime = Runtime.new(@config)
                commands = [["git", "init", "--quiet", checkout],
                  ["git", "-C", checkout, "fetch", "--quiet", "--depth=1", spec.fetch("source"), revision],
                  ["git", "-C", checkout, "checkout", "--quiet", "--detach", "FETCH_HEAD"]]
                commands.each do |command|
                  result = runtime.capture(*command, timeout: 120)
                  raise Error, "Skill fetch failed: #{result['stderr']}" unless result["exit_code"] == 0
                end
                result = runtime.capture("git", "-C", checkout, "rev-parse", "HEAD", timeout: 10)
                raise Error, "Skill revision mismatch" unless result["stdout"].strip == revision
                FileUtils.rm_rf(File.join(checkout, ".git"))
                copy_tree(checkout, target, File.realpath(checkout), [])
              end
              entry = spec.fetch("entry")
              resolved = File.expand_path(entry, target)
              unless resolved.start_with?(target + "/") && File.file?(resolved)
                raise Error, "Missing skill entry: #{entry}"
              end
              spec["snapshot"] = "skills/#{slot.fetch('id')}/#{index}/#{entry}"
            end
          end
        end
      end
    end
  end
end
