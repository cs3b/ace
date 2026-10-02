# Goal 1 — Install and deliver once

The setup has installed local dependency gems in `install/`. Build the current `ace-herdr` gem from the sandbox `ace-herdr/` directory to `artifacts/ace-herdr.gem`, and install it in `install/` with `gem install --local --ignore-dependencies --no-document`. Capture both commands' stdout, stderr, and exit code under `results/tc/01/`.

Run the installed executable at `$PWD/install/bin/ace-herdr` with `BUNDLE_GEMFILE`, `RUBYOPT`, and `RUBYLIB` unset and `GEM_HOME` and `GEM_PATH` both set to `$PWD/install`. Use `env -u BUNDLE_GEMFILE -u RUBYOPT -u RUBYLIB` for this isolation. Capture `ruby -e 'require "ace/herdr"; puts Gem.loaded_specs.fetch("ace-herdr").full_gem_path'` under the same isolated environment and verify it points inside `install/gems/ace-herdr-*`, never the source checkout. Use this isolated environment for **every** inbox CLI call in both goals.

Put the sandbox `bin/` first on `PATH`. Its fake `herdr` reports one busy Codex pane; its fake `codex` records native queue calls to a sandbox-local log selected by `ACE_E2E_QUEUE_LOG`. Setup has configured the trusted public key in `.ace/herdr/config.yml`. Create `ref.json` with `{"session":"ws1","pane":"p1"}` and a `prompt.txt` payload. From the documented usage guide, run `inbox enqueue`, `inbox deliver`, and then `inbox deliver` again in a separate process. Capture each command's stdout, stderr, and exit code under `results/tc/01/`. Keep the delivery record and queue log as sandbox state.

The expected user result is one `delivered` event with one queue submission, even across separate CLI processes. Do not use any lab-config Python transport file.
