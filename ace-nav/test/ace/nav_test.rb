# frozen_string_literal: true

require "test_helper"

module Ace
  class NavTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Ace::Nav::VERSION
    end

    def test_version_is_correct
      assert_equal "0.9.1", ::Ace::Nav::VERSION
    end

    def test_module_exists
      assert_kind_of Module, ::Ace::Nav
    end

    def test_atoms_module_exists
      assert_kind_of Module, ::Ace::Nav::Atoms
    end

    def test_molecules_module_exists
      assert_kind_of Module, ::Ace::Nav::Molecules
    end

    def test_organisms_module_exists
      assert_kind_of Module, ::Ace::Nav::Organisms
    end

    def test_models_module_exists
      assert_kind_of Module, ::Ace::Nav::Models
    end
  end
end