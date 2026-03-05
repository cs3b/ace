# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      class DemoCommentFormatter
        def self.format(demo_name:, asset_url:, recorded_at: Time.now, format: "gif")
          timestamp = recorded_at.strftime("%Y-%m-%d %H:%M:%S")

          media_line = if format == "gif"
                         "![Demo](#{asset_url})"
                       else
                         "[#{demo_name}.#{format}](#{asset_url})"
                       end

          <<~MARKDOWN.strip
            ## Demo: #{demo_name}
            #{media_line}
            _Recorded at #{timestamp}_
          MARKDOWN
        end
      end
    end
  end
end
