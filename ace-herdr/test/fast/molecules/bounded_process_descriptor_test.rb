# frozen_string_literal: true
require "test_helper"
require "rbconfig"
require "tempfile"
require "fcntl"

module Ace
  module Herdr
    module Molecules
      class BoundedProcessDescriptorTest < Minitest::Test
        def with_selected
          Tempfile.create("bounded-selected-source") do |file|
            file.write("accepted bytes")
            file.flush
            File.open(file.path, File::RDONLY) { |selected| yield file, selected }
          end
        end

        def test_explicit_readonly_file_and_exact_stdin_reach_owned_source_child
          with_selected do |_, selected|
            code = "STDOUT.write(IO.for_fd(4).read);STDOUT.write('|');STDOUT.write(STDIN.read)"
            result = BoundedProcess.call([RbConfig.ruby, "--disable=gems", "-e", code],
              stdin_data: "selected entry bytes", descriptor_mapping: {4 => selected}, timeout_s: 5)
            assert result.status.success?
            assert_equal "accepted bytes|selected entry bytes", result.stdout
            assert_empty result.stderr
            refute result.oversized
            refute selected.closed?
          end
        end

        def test_replaced_path_cannot_change_selected_child_file
          with_selected do |original, selected|
            File.rename(original.path, original.path + ".retained")
            File.binwrite(original.path, "replacement bytes")
            result = BoundedProcess.call([RbConfig.ruby, "--disable=gems", "-e", "STDOUT.write(IO.for_fd(4).read)"],
              descriptor_mapping: {4 => selected}, timeout_s: 5)
            assert result.status.success?
            assert_equal "accepted bytes", result.stdout
          ensure
            File.unlink(original.path + ".retained") if File.exist?(original.path + ".retained")
          end
        end

        def test_default_does_not_inherit_an_ambient_readonly_descriptor
          with_selected do |_, selected|
            selected.close_on_exec = false
            code = "begin;STDOUT.write(IO.for_fd(Integer(ARGV.fetch(0))).read);rescue Errno::EBADF,IOError;STDOUT.write('closed');end"
            result = BoundedProcess.call([RbConfig.ruby, "--disable=gems", "-e", code, selected.fileno.to_s], timeout_s: 5)
            assert result.status.success?
            assert_equal "closed", result.stdout
          end
        end

        def test_invalid_mappings_refuse_before_any_child_effect
          with_selected do |writable, selected|
            read_pipe, write_pipe = IO.pipe
            closed = selected.dup
            closed.close
            mappings = [nil, [], {0 => selected}, {1 => selected}, {2 => selected},
              {3.0 => selected}, {"4" => selected}, {64 => selected}, {-1 => selected},
              {4 => closed}, {4 => writable}, {4 => read_pipe}, {4 => selected.fileno},
              (3..19).to_h { |descriptor| [descriptor, selected] }]
            mappings.each do |mapping|
              # A missing executable would raise ENOENT if validation spawned.
              assert_raises(ArgumentError) do
                BoundedProcess.call(["/missing/child-must-not-run"], descriptor_mapping: mapping, timeout_s: 5)
              end
            end
          ensure
            read_pipe&.close
            write_pipe&.close
          end
        end
      end
    end
  end
end
