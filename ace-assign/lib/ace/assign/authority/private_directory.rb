# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      module PrivateDirectory
        module_function

        # Source configuration chooses this path. Each ancestor must prevent
        # another principal from replacing the private leaf or its contents.
        def verify!(root)
          path = File.expand_path(root)
          cursor = path
          loop do
            stat = File.lstat(cursor)
            unless stat.directory? && !stat.symlink? && [0, Process.uid].include?(stat.uid) && (stat.mode & 0022).zero?
              raise AttemptErrors::ReceiptRejected, "Private directory ancestry is not protected"
            end
            break if cursor == "/"
            cursor = File.dirname(cursor)
          end
          stat = File.stat(path)
          unless stat.uid == Process.uid && (stat.mode & 0077).zero?
            raise AttemptErrors::ReceiptRejected, "Private directory must be owned by this peer and private"
          end
          path
        rescue SystemCallError, TypeError
          raise AttemptErrors::ReceiptRejected, "Private directory is unavailable"
        end
      end
    end
  end
end
