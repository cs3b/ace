# frozen_string_literal: true

module Ace
  module Demo
    module Organisms
      class TapeCreator
        def initialize(writer: Molecules::TapeWriter.new)
          @writer = writer
        end

        def create(name:, commands:, description: nil, tags: nil,
                   font_size: 16, width: 960, height: 480, timeout: "2s",
                   format: "gif", force: false, dry_run: false)
          safe_name = Atoms::DemoNameSanitizer.sanitize(name)
          output_path = ".ace-local/demo/#{safe_name}.#{format}"

          content = Atoms::TapeContentGenerator.generate(
            name: safe_name,
            commands: commands,
            description: description,
            tags: tags,
            output_path: output_path,
            font_size: font_size,
            width: width,
            height: height,
            timeout: timeout
          )

          path = nil
          path = @writer.write(name: safe_name, content: content, force: force) unless dry_run

          { content: content, path: path, dry_run: dry_run }
        end
      end
    end
  end
end
