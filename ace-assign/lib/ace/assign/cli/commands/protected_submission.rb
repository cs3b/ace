# frozen_string_literal: true
require_relative "attempt/base"
require "digest"

module Ace
  module Assign
    module CLI
      module Commands
        # Local files provide bounded bytes; only the existing authority grants admission.
        module ProtectedSubmission
          include Attempt::Base
          private

          def submission_request(options, usage)
            context = protected_context(options)
            raise AttemptErrors::EvidenceUnavailable, "Submission requires installed protected authority" unless context
            protected_attempt_request(context, options, usage)
          end

          def input_bytes(path, limit:, nonempty: true)
            File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
              before = file.stat
              raise Ace::Support::Cli::Error, "Input must be a bounded regular file" unless before.file? && before.size.between?(nonempty ? 1 : 0, limit)
              bytes = file.read(limit + 1)
              after = file.stat
              selected = File.lstat(path)
              identity = ->(stat) { [stat.dev, stat.ino, stat.size, stat.mtime, stat.ctime] }
              unless bytes.bytesize == before.size && identity.call(before) == identity.call(after) &&
                  identity.call(after) == identity.call(selected) && !selected.symlink?
                raise Ace::Support::Cli::Error, "Input changed during bounded read"
              end
              bytes.freeze
            end
          rescue SystemCallError, IOError
            raise Ace::Support::Cli::Error, "Input file is unavailable"
          end

          def input_json(bytes)
            text = bytes.dup.force_encoding(Encoding::UTF_8)
            raise Ace::Support::Cli::Error, "Input JSON is malformed" unless text.valid_encoding?
            JSON.parse(text, create_additions: false, max_nesting: 32, allow_duplicate_key: false, allow_comments: false)
          rescue JSON::ParserError
            raise Ace::Support::Cli::Error, "Input JSON is malformed"
          end

          def upload_call(client, operation, params, mutation, parts, purpose)
            client.call(operation, params, mutation_id: mutation, upload_parts: parts, purpose: purpose, timeout: 30).data
          rescue SecurityError, Ace::Runtime::RuntimeUnavailableError, SystemCallError, IOError
            protected_transport_unavailable!
          end
        end
      end
    end
  end
end
