# frozen_string_literal: true
module Ace
  module Design
    module Molecules
      class DesignContext
        NAMES = %w[defaults.md user.md design.md].freeze
        attr_reader :repository
        def initialize(project: Dir.pwd, library: File.join(Design.gem_root, ".ace-defaults/design/contexts"))
          @repository = ContextRepository.new(project: project)
          @library = library
        end
        def self.select(surface:, kind:, context: nil)
          Atoms::Contracts.surface(surface)
          Atoms::Contracts.kind(kind)
          id = context || "#{surface}/#{kind}"
          unless id.is_a?(String) && id.split("/", -1).all? { |part| Preset::ID.match?(part) } &&
              (id == "#{surface}/#{kind}" || id.start_with?("#{surface}/#{kind}/"))
            raise Error, "profile must be #{surface}/#{kind} or a named descendant"
          end
          id
        end
        def self.chain(id)
          [""] + (1..id.split("/").size).map { |n| id.split("/").first(n).join("/") }
        end
        def self.file(id, name)
          id.empty? ? name : "#{id}/#{name}"
        end
        def default(id)
          source = File.join(@library, id.empty? ? "project.md" : "#{id}.md")
          raise Error, "Missing packaged context: #{source}" if !File.file?(source) && id.split("/").size <= 2
          body = File.file?(source) ? File.read(source) : "# Local context\n\nNo additional library rules for this named context.\n"
          ContextDocument.encode({"context" => id, "library_version" => VERSION,
            "source_sha256" => ContextDocument.sha(body)}, body)
        end
        def ids(files)
          files.keys.filter_map do |path|
            name = File.basename(path)
            next unless NAMES.include?(name)
            id = File.dirname(path)
            id == "." ? "" : id
          end.uniq.sort_by { |id| [id.count("/"), id.empty? ? 0 : 1, id] }
        end
        def targets(files, surface:, kind:, context: nil)
          if context
            self.class.chain(self.class.select(surface: surface, kind: kind, context: context))
          else
            Atoms::Contracts.surface(surface)
            Atoms::Contracts.kind(kind)
            (["", surface, "#{surface}/view", "#{surface}/component"] +
              ids(files).select { |id| id.start_with?(surface + "/") }).uniq.sort_by { |id| [id.split("/").size, id] }
          end
        end
        def read_generated(files, id)
          name = self.class.file(id, "design.md")
          text = files[name]
          raise Error, "Missing #{name}; run ace-design profile adjust for this context" unless text
          metadata, = ContextDocument.decode(text, name)
          raise Error, "Context identity mismatch: #{name}" unless metadata["context"] == id
          [text, metadata]
        end
        def resolve(files, id)
          parent = nil
          self.class.chain(id).each do |node|
            text, metadata = read_generated(files, node)
            expected = {"defaults_sha256" => ContextDocument.sha(files.fetch(self.class.file(node, "defaults.md"))),
              "user_sha256" => ContextDocument.sha(files.fetch(self.class.file(node, "user.md"))),
              "parent_sha256" => parent && ContextDocument.sha(parent)}
            unless expected.all? { |key, value| metadata[key] == value }
              raise Error, "Stale design context #{node.empty? ? 'project' : node}; run ace-design profile adjust"
            end
            parent = text
          end
          parent
        rescue KeyError => error
          raise Error, "Incomplete context #{id}; run ace-design profile adjust (#{error.message})"
        end
        def snapshot(surface:, kind:, context: nil, readonly: false)
          id = self.class.select(surface: surface, kind: kind, context: context)
          files = repository.read(readonly: readonly)
          if files.empty?
            raise Error, "Initialize named context #{id} with adjust first" if id.split("/").size > 2
            documents = self.class.chain(id).map { |node| default(node) }
            body = documents.map { |document| ContextDocument.decode(document, "library defaults").last }.join("\n")
            text = ContextDocument.effective(id: id, defaults: documents.join("\n"), user: "", parent: nil,
              body: body, decisions: {})
            source = "library"
          else
            text = resolve(files, id)
            source = "project"
          end
          {"id" => id, "source" => source, "sha256" => ContextDocument.sha(text), "document" => text}
        end
      end
    end
  end
end
