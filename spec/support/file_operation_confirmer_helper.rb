# frozen_string_literal: true

# Helper to ensure FileOperationConfirmer never prompts during tests
RSpec.configure do |config|
  # Only apply this to tests that aren't specifically testing FileOperationConfirmer
  config.before(:each) do |example|
    # Skip this mock for FileOperationConfirmer's own tests
    unless example.metadata[:file_path]&.include?("file_operation_confirmer_spec.rb")
      # Mock FileOperationConfirmer.new to always return a non-interactive instance
      allow(CodingAgentTools::Molecules::FileOperationConfirmer).to receive(:new).and_wrap_original do |method, *args, **kwargs|
        # If StringIO is already being used (test environment), don't wrap
        if args.any? { |arg| arg.is_a?(Hash) && (arg[:input].is_a?(StringIO) || arg[:output].is_a?(StringIO)) }
          method.call(*args, **kwargs)
        else
          # Create instance with StringIO to prevent any TTY interaction
          require 'stringio'
          modified_kwargs = kwargs.dup
          modified_kwargs[:input] ||= StringIO.new
          modified_kwargs[:output] ||= StringIO.new
          method.call(*args, **modified_kwargs)
        end
      end
    end
  end
end