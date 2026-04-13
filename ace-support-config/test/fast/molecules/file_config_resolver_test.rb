# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Molecules
        class FileConfigResolverTest < TestCase
          def test_distributed_config_has_precedence
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                  YAML
                }
              },
              ".ace-task" => {
                ".ace" => {
                  "git" => {
                    "commit.yml" => <<~YAML
                      git:
                        model: gflash
                    YAML
                  }
                },
                "spec.md" => ""
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new
              result = resolver.resolve(".ace-task/spec.md")

              assert_equal ".ace-task", result.name
              assert_equal({"model" => "gflash"}, result.config)
              assert result.source.include?(".ace-task/.ace/git/commit.yml")
            end
          end

          def test_paths_rules_apply_when_no_distributed_config
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                      paths:
                        docs-scope:
                          glob: "docs/**"
                          model: gflash
                  YAML
                }
              },
              "docs" => {
                "readme.md" => ""
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new
              result = resolver.resolve("docs/readme.md")

              assert_equal "docs-scope", result.name
              assert_equal "gflash", result.config["model"]
              assert result.source.include?(".ace/git/commit.yml")
            end
          end

          def test_project_default_used_when_no_match
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                      paths:
                        docs-scope:
                          glob: "docs/**"
                          model: gflash
                  YAML
                }
              },
              "lib" => {
                "file.rb" => ""
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new
              result = resolver.resolve("lib/file.rb")

              assert_equal "project default", result.name
              assert_equal "glite", result.config["model"]
            end
          end

          def test_path_rules_list_supported
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    model: glite
                    path_rules:
                      - name: docs-scope
                        glob: "docs/**"
                        model: gflash
                  YAML
                }
              },
              "docs" => {
                "readme.md" => ""
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new
              result = resolver.resolve("docs/readme.md")

              assert_equal "docs-scope", result.name
              assert_equal "gflash", result.config["model"]
            end
          end

          def test_root_overrides_merge_into_git_section
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                    model: gflash
                  YAML
                }
              },
              "lib" => {
                "file.rb" => ""
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new
              result = resolver.resolve("lib/file.rb")

              assert_equal "gflash", result.config["model"]
            end
          end

          # Relative path resolution tests

          def test_nested_config_paths_relative_to_nested_directory
            # Path rules in nested configs should match relative to that config's directory
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                  YAML
                }
              },
              "ace-bundle" => {
                ".ace" => {
                  "git" => {
                    "commit.yml" => <<~YAML
                      git:
                        model: gflash
                        paths:
                          lib-scope:
                            glob: "lib/**"
                            type_hint: feat
                    YAML
                  }
                },
                "lib" => {
                  "file.rb" => ""
                }
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new

              # File in nested lib/ should match the nested config's lib/** rule
              result = resolver.resolve("ace-bundle/lib/file.rb")
              assert_equal "lib-scope", result.name
              assert_equal "feat", result.config["type_hint"]
            end
          end

          def test_nested_config_paths_dont_match_root_files
            # Path rules in nested configs should NOT match files outside that directory
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                  YAML
                }
              },
              "ace-bundle" => {
                ".ace" => {
                  "git" => {
                    "commit.yml" => <<~YAML
                      git:
                        model: gflash
                        paths:
                          lib-scope:
                            glob: "lib/**"
                            type_hint: feat
                    YAML
                  }
                }
              },
              "lib" => {
                "root_file.rb" => ""
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new

              # File in root lib/ should NOT match nested config's lib/** rule
              result = resolver.resolve("lib/root_file.rb")
              assert_equal "project default", result.name
            end
          end

          def test_root_config_paths_relative_to_project_root
            # Path rules in root config should match relative to project root
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                      paths:
                        lib-scope:
                          glob: "lib/**"
                          type_hint: feat
                  YAML
                }
              },
              "lib" => {
                "file.rb" => ""
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new

              result = resolver.resolve("lib/file.rb")
              assert_equal "lib-scope", result.name
              assert_equal "feat", result.config["type_hint"]
            end
          end

          def test_path_rules_checked_before_distributed_config_scope
            # Path rules should be checked before falling back to distributed config scope
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                      paths:
                        ace-config:
                          glob: ".ace/**"
                          type_hint: chore
                  YAML
                }
              },
              "ace-bundle" => {
                ".ace" => {
                  "git" => {
                    "commit.yml" => <<~YAML
                      git:
                        model: gflash
                    YAML
                  }
                }
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new

              # The nested config file should match the inherited .ace/** rule
              # Path rules are evaluated relative to closest config root (ace-bundle/)
              # So ace-bundle/.ace/git/commit.yml → .ace/git/commit.yml matches .ace/**
              result = resolver.resolve("ace-bundle/.ace/git/commit.yml")

              # With _config_root inheritance fix, all inherited rules evaluate
              # relative to closest config, so .ace/** now matches correctly
              assert_equal "ace-config", result.name
            end
          end

          def test_inherited_path_rules_matched_against_config_root
            # When nested config inherits rules from root, rules use their original config root
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                      paths:
                        config-scope:
                          glob: ".ace/**"
                          type_hint: chore
                  YAML
                }
              },
              "ace-bundle" => {
                ".ace" => {
                  "git" => {
                    "commit.yml" => <<~YAML
                      git:
                        model: gflash
                    YAML
                  }
                }
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new

              # Root's .ace/git/commit.yml should match root's .ace/** rule
              result = resolver.resolve(".ace/git/commit.yml")
              assert_equal "config-scope", result.name
              assert_equal "chore", result.config["type_hint"]
            end
          end

          def test_nested_config_can_override_path_rules
            # Nested config can override inherited path rules
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                      paths:
                        lib-scope:
                          glob: "lib/**"
                          type_hint: feat
                  YAML
                }
              },
              "ace-bundle" => {
                ".ace" => {
                  "git" => {
                    "commit.yml" => <<~YAML
                      git:
                        model: gflash
                        paths:
                          lib-scope:
                            glob: "lib/**"
                            type_hint: refactor
                    YAML
                  }
                },
                "lib" => {
                  "file.rb" => ""
                }
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new

              # Nested lib should use nested config's overridden rule
              result = resolver.resolve("ace-bundle/lib/file.rb")
              assert_equal "lib-scope", result.name
              assert_equal "refactor", result.config["type_hint"]
            end
          end

          # ===== rule_config tests (for grouping) =====

          def test_rule_config_contains_only_rule_specific_settings
            # rule_config should contain only the path rule's overrides, not cascade merged values
            # Note: glob is stripped by PathRuleMatcher since it's for matching, not config
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                      paths:
                        docs-scope:
                          glob: "docs/**"
                          type_hint: docs
                  YAML
                }
              },
              "docs" => {
                "readme.md" => ""
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new
              result = resolver.resolve("docs/readme.md")

              # rule_config contains only rule overrides (type_hint) - glob is stripped
              assert_equal "docs-scope", result.name
              assert_includes result.rule_config.keys, "type_hint"
              refute_includes result.rule_config.keys, "model"
              refute_includes result.rule_config.keys, "glob" # glob is stripped by PathRuleMatcher

              # config contains merged values (model from base + type_hint from rule)
              assert_equal "glite", result.config["model"]
              assert_equal "docs", result.config["type_hint"]
            end
          end

          def test_rule_config_nil_for_distributed_config_match
            # rule_config should be nil when using distributed config (no path rule match)
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                  YAML
                }
              },
              "ace-bundle" => {
                ".ace" => {
                  "git" => {
                    "commit.yml" => <<~YAML
                      git:
                        model: gflash
                    YAML
                  }
                },
                "lib" => {
                  "file.rb" => ""
                }
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new
              result = resolver.resolve("ace-bundle/lib/file.rb")

              assert_equal "ace-bundle", result.name
              assert_nil result.rule_config
              assert_equal "gflash", result.config["model"]
            end
          end

          def test_rule_config_nil_for_project_default
            # rule_config should be nil for project default (no path rule match)
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => <<~YAML
                    git:
                      model: glite
                  YAML
                }
              },
              "lib" => {
                "file.rb" => ""
              }
            ) do |tmpdir|
              resolver = FileConfigResolver.new
              result = resolver.resolve("lib/file.rb")

              assert_equal "project default", result.name
              assert_nil result.rule_config
            end
          end
        end
      end
    end
  end
end
