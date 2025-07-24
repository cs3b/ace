# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # Autoload code review atoms
    module Code
      autoload :SessionTimestampGenerator, "coding_agent_tools/atoms/code/session_timestamp_generator"
      autoload :SessionNameBuilder, "coding_agent_tools/atoms/code/session_name_builder"
      autoload :FileContentReader, "coding_agent_tools/atoms/code/file_content_reader"
      autoload :DirectoryCreator, "coding_agent_tools/atoms/code/directory_creator"
    end
  end
end
