# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # Autoload coverage analysis atoms
    autoload :CoverageFileReader, "coding_agent_tools/atoms/coverage_file_reader"
    autoload :RubyMethodParser, "coding_agent_tools/atoms/ruby_method_parser"
    autoload :CoverageCalculator, "coding_agent_tools/atoms/coverage_calculator"
    autoload :ThresholdValidator, "coding_agent_tools/atoms/threshold_validator"

    # Autoload code review atoms
    module Code
      autoload :SessionTimestampGenerator, "coding_agent_tools/atoms/code/session_timestamp_generator"
      autoload :SessionNameBuilder, "coding_agent_tools/atoms/code/session_name_builder"
      autoload :FileContentReader, "coding_agent_tools/atoms/code/file_content_reader"
      autoload :DirectoryCreator, "coding_agent_tools/atoms/code/directory_creator"
    end
  end
end
