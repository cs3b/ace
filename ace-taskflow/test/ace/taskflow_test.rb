# frozen_string_literal: true

require "test_helper"

module Ace
  class TaskflowTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Ace::Taskflow::VERSION
    end

    def test_version_is_correct
      assert_equal "0.9.0", ::Ace::Taskflow::VERSION
    end

    def test_module_exists
      assert_kind_of Module, ::Ace::Taskflow
    end

    def test_atoms_module_exists
      assert_kind_of Module, ::Ace::Taskflow::Atoms
    end

    def test_molecules_module_exists
      assert_kind_of Module, ::Ace::Taskflow::Molecules
    end

    def test_organisms_module_exists
      assert_kind_of Module, ::Ace::Taskflow::Organisms
    end

    def test_models_module_exists
      assert_kind_of Module, ::Ace::Taskflow::Models
    end

    def test_commands_module_exists
      assert_kind_of Module, ::Ace::Taskflow::Commands
    end
  end
end