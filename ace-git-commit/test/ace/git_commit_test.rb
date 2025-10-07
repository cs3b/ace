# frozen_string_literal: true

require "test_helper"

module Ace
  class GitCommitTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Ace::GitCommit::VERSION
    end

    def test_version_format
      assert_match(/\A\d+\.\d+\.\d+/, ::Ace::GitCommit::VERSION)
    end

    def test_module_exists
      assert_kind_of Module, ::Ace::GitCommit
    end

    def test_atoms_module_exists
      assert_kind_of Module, ::Ace::GitCommit::Atoms
    end

    def test_molecules_module_exists
      assert_kind_of Module, ::Ace::GitCommit::Molecules
    end

    def test_organisms_module_exists
      assert_kind_of Module, ::Ace::GitCommit::Organisms
    end

    def test_models_module_exists
      assert_kind_of Module, ::Ace::GitCommit::Models
    end

    def test_error_classes_exist
      assert_kind_of Class, ::Ace::GitCommit::Error
      assert_kind_of Class, ::Ace::GitCommit::GitError
      assert_kind_of Class, ::Ace::GitCommit::ConfigurationError
    end
  end
end