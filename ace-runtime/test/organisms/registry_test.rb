# frozen_string_literal: true

require "test_helper"

module Ace
  module Runtime
    class RegistryOrganismsTest < AceRuntimeTestCase
      def setup
        @registry = Registry.new
      end

      def test_register_and_resolve_returns_factory_result
        adapter = Object.new
        @registry.register(:tmux, -> { adapter })

        assert_same adapter, @registry.resolve("tmux")
      end

      def test_resolve_accepts_symbols
        @registry.register(:herdr, -> { :herdr_adapter })

        assert_equal :herdr_adapter, @registry.resolve(:herdr)
      end

      def test_available_is_sorted
        @registry.register(:tmux, -> { :tmux })
        @registry.register(:herdr, -> { :herdr })

        assert_equal %w[herdr tmux], @registry.available
      end

      def test_registered_predicate
        @registry.register(:tmux, -> { :tmux })

        assert @registry.registered?(:tmux)
        refute @registry.registered?(:herdr)
      end

      def test_unknown_name_fails_closed_with_available_list
        @registry.register(:tmux, -> { :tmux })

        error = assert_raises(UnknownRuntimeError) do
          @registry.resolve("nope")
        end

        assert_match(/unknown runtime 'nope'/, error.message)
        assert_match(/available: tmux/, error.message)
        assert_equal %w[tmux], error.available
        assert_equal "nope", error.requested
      end

      def test_factory_must_be_callable
        error = assert_raises(ArgumentError) do
          @registry.register(:tmux, "not callable")
        end

        assert_match(/must respond to #call/, error.message)
      end

      def test_block_registration
        @registry.register(:tmux) { :blocked }

        assert_equal :blocked, @registry.resolve(:tmux)
      end

      def test_unregistered_identifier_name_attempts_entrypoint_load_then_fails_closed
        error = assert_raises(UnknownRuntimeError) do
          @registry.resolve("definitely_not_installed")
        end

        assert_equal [], error.available
      end

      def test_entrypoint_load_registers_factory_lazily
        entrypoint_dir = Dir.mktmpdir("ace_runtime_adapters")
        adapters_dir = File.join(entrypoint_dir, "ace", "runtime", "adapters")
        FileUtils.mkdir_p(adapters_dir)
        File.write(File.join(adapters_dir, "lazytest.rb"), <<~RUBY)
          Ace::Runtime.register(:lazytest, -> { :lazy_adapter })
        RUBY

        Ace::Runtime.reset_registry!
        $LOAD_PATH.unshift(entrypoint_dir)
        begin
          assert_equal :lazy_adapter, Ace::Runtime.resolve("lazytest")
        ensure
          $LOAD_PATH.delete(entrypoint_dir)
          Ace::Runtime.reset_registry!
        end
      ensure
        FileUtils.remove_entry(entrypoint_dir) if entrypoint_dir && Dir.exist?(entrypoint_dir)
      end

      def test_non_identifier_name_never_attempts_load_path_traversal
        error = assert_raises(UnknownRuntimeError) do
          @registry.resolve("../../etc/passwd")
        end

        assert_equal [], error.available
      end

      def test_broken_installed_entrypoint_raises_load_error_not_unknown_runtime
        entrypoint_dir = Dir.mktmpdir("ace_runtime_broken")
        adapters_dir = File.join(entrypoint_dir, "ace", "runtime", "adapters")
        FileUtils.mkdir_p(adapters_dir)
        File.write(File.join(adapters_dir, "brokentest.rb"), <<~RUBY)
          require "definitely_missing_dependency_xyz"
        RUBY

        Ace::Runtime.reset_registry!
        $LOAD_PATH.unshift(entrypoint_dir)
        begin
          error = assert_raises(LoadError) do
            Ace::Runtime.resolve("brokentest")
          end

          assert_match(/definitely_missing_dependency_xyz/, error.message)
        ensure
          $LOAD_PATH.delete(entrypoint_dir)
          Ace::Runtime.reset_registry!
        end
      ensure
        FileUtils.remove_entry(entrypoint_dir) if entrypoint_dir && Dir.exist?(entrypoint_dir)
      end
    end
  end
end
