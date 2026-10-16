# frozen_string_literal: true
require "digest"
require "cgi"
require "pathname"
module Ace
  module Design
    module Molecules
      class Session
        attr_reader :root, :metadata, :fixtures
        def initialize(path)
          @root = File.realpath(path)
          raise Error, "session must be a directory" unless File.directory?(root)
          @metadata = read_json("session.json")
          Atoms::Contracts.surface(metadata["surface"])
          Atoms::Contracts.text(metadata["title"], "session title")
          Atoms::Contracts.text(metadata["language"], "session language")
          ids = metadata["variants"]
          unless ids.is_a?(Array) && !ids.empty? && ids.uniq == ids &&
              ids.all? { |id| id.is_a?(String) && Preset::ID.match?(id) }
            raise Error, "session variants must be a nonempty list of unique safe IDs"
          end
          @fixtures = read_json("fixtures.json")
          safe_file("brief.md")
        rescue Errno::ENOENT, Errno::ENOTDIR => e
          raise Error, "Session missing or incomplete: #{e.message}"
        end
        def safe_file(relative)
          path = File.realpath(File.join(root, relative))
          unless path.start_with?(root + File::SEPARATOR) && File.file?(path)
            raise Error, "Session file escapes session root: #{relative}"
          end
          path
        rescue Errno::ENOENT, Errno::ENOTDIR, Errno::ELOOP
          raise Error, "Session file missing or broken symlink: #{relative}"
        end
        def read_json(relative)
          Atoms::Contracts.object(JSON.parse(File.read(safe_file(relative))), relative)
        rescue JSON::ParserError => e
          raise Error, "Invalid #{relative}: #{e.message}"
        end
        def variants
          metadata.fetch("variants").select do |id|
            directory = File.join(root, "variants", id)
            next false unless File.directory?(directory)
            next false unless File.file?(File.join(directory, "direction.md"))
            Artifacts.files(directory)
            artifact = Artifacts.descriptor(directory)
            safe_file("variants/#{id}/#{artifact.fetch('entry')}") unless artifact["type"] == "url"
            safe_file("variants/#{id}/direction.md")
            true
          end
        end
        def validate(allow_empty: false)
          available = variants
          raise Error, "No ready variants: add variants/#{metadata.fetch("variants").first}/index.html and direction.md" if available.empty? && !allow_empty
          selection = File.join(root, "selection.json")
          validate_selection if File.exist?(selection) || File.symlink?(selection)
          {"surface" => metadata["surface"], "variants" => available,
           "missing_variants" => metadata.fetch("variants") - available, "selected" => File.exist?(selection)}
        end
        def validate_selection
          chosen = read_json("selection.json")
          unless chosen["surface"] == metadata["surface"] && variants.include?(chosen["variant"])
            raise Error, "Selection must name an available variant and the session surface"
          end
          expected = Digest::SHA256.file(safe_file("fixtures.json")).hexdigest
          raise Error, "Selection is stale: fixtures changed; confirm the direction again" unless chosen["fixtures_sha256"] == expected
          if chosen["variant_sha256"] != Artifacts.digest(File.join(root, "variants", chosen["variant"]))
            raise Error, "Selection is stale: variant changed; confirm the direction again"
          end
          decisions = chosen["decisions"]
          unless decisions.is_a?(Array) && !decisions.empty? && decisions.all? { |s| s.is_a?(String) && !s.strip.empty? }
            raise Error, "Selection decisions must be a nonempty list of text"
          end
          chosen
        end
        def write_gallery
          result = validate(allow_empty: true)
          path = File.join(root, "gallery.html")
          raise Error, "Refusing symlink gallery.html" if File.symlink?(path)
          cards = result["variants"].map do |id|
            direction = CGI.escapeHTML(File.read(safe_file("variants/#{id}/direction.md")))
            artifact = Artifacts.descriptor(File.join(root, "variants", id))
            entry = artifact.fetch("entry")
            url = CGI.escapeHTML(artifact["type"] == "url" ? entry : "variants/#{id}/#{entry}")
            visual = case artifact["type"]
            when "html" then %(<div class="frame"><iframe title="Direction #{id.upcase}" src="#{url}" sandbox="allow-scripts"></iframe></div>)
            when "image" then %(<img src="#{url}" alt="Direction #{id.upcase}" style="max-width:100%">)
            else %(<p>External result — open the provider preview. Remote content may change independently.</p>)
            end
            %(<section><h2>#{id.upcase} <a href="#{url}" target="_blank" rel="noopener noreferrer">Open #{id.upcase}</a></h2><p>#{artifact.fetch('type')}</p>#{visual}<details><summary>Direction notes</summary><p class="direction">#{direction}</p></details></section>)
          end.join("\n")
          title = CGI.escapeHTML(metadata["title"])
          run = File.file?(File.join(root, "run.json")) ? read_json("run.json") : nil
          missing = result["missing_variants"].empty? ? "" : "Still preparing: #{result['missing_variants'].join(', ')}"
          if run && !result["missing_variants"].empty?
            labels = result["missing_variants"].map { |id| "#{id} (#{run.dig('workers', id, 'status') || 'pending'})" }
            missing = CGI.escapeHTML("Not ready: #{labels.join(', ')}")
          end
          refresh = run && run["status"] == "running" ? '<meta http-equiv="refresh" content="3">' : ""
          html = <<~HTML
            <!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
            <title>#{title} — directions</title>#{refresh}<style>
            *{box-sizing:border-box}body{margin:0;padding:24px;background:#f5f5f5;color:#171717;font:16px system-ui}
            main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,420px),1fr));gap:24px}
            section{min-width:0}h2 a{font-size:16px;font-weight:normal;margin-left:12px}.frame{overflow:hidden;border:1px solid #ccc;background:white}iframe{display:block;width:1200px;height:900px;border:0;transform-origin:top left}details{margin-top:12px}
            .direction{white-space:pre-wrap}a{color:#174dad}header{max-width:85ch;margin-bottom:24px}
            </style><header><h1>#{title}</h1><p>Compare directions. Give feedback in chat or with ace-design revise using a variant ID. These are mockups.</p><p>#{missing}</p><label>Preview width <select id="width"><option value="1200">Desktop</option><option value="768">Tablet</option><option value="390">Mobile</option></select></label></header><main>#{cards}</main>
            <script>
            const select=document.getElementById('width');
            function size(frame){const width=Number(select.value),scale=frame.clientWidth/width,iframe=frame.querySelector('iframe');iframe.style.width=width+'px';iframe.style.transform='scale('+scale+')';frame.style.height=(900*scale)+'px';}
            const frames=[...document.querySelectorAll('.frame')];
            const observer=new ResizeObserver(entries=>entries.forEach(entry=>size(entry.target)));
            frames.forEach(frame=>observer.observe(frame));select.addEventListener('change',()=>frames.forEach(size));
            </script></html>
          HTML
          File.write(path, html)
          path
        end
      end
    end
  end
end
