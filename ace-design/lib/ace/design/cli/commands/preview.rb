# frozen_string_literal: true
module Ace
  module Design
    module CLI
      module Commands
        class Preview < Ace::Support::Cli::Command
          desc "Build the session gallery and serve it on loopback; Ctrl-C stops the server"
          argument :session, required: true, desc: "Session token or directory"
          option :port, type: :integer, default: 0, desc: "Loopback port; 0 chooses an available port"
          def call(session:, port: 0, **)
            number = Integer(port)
            raise Error, "port must be 0..65535" unless (0..65_535).cover?(number)
            data = Molecules::Session.new(CLI.session_path(session))
            data.write_gallery
            Molecules::Runtime.new.preview(data, port: number)
          end
        end
      end
    end
  end
end
