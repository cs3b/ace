# Package verification selection gap

Observed on main `3e7f363ff`: `../bin/ace-test all --timeout 180` from ace-assign selects 127/133 files. The default `ace-test-runner/.ace-defaults/test-runner/config.yml` enumerates category patterns and excludes `test/fast/authority`, which contains six current test files. This is a verification gap, not evidence those tests passed as part of `all`.

Explicit `../bin/ace-test test/fast/authority/*_test.rb` selected all six files and passed **49 tests / 277 assertions**, no failures/errors,60.42ms. Receipt `assign/96661b6b-7d5d-4626-b198-e38bc3d5299c` resides in the primary checkout. The ongoing all-target invocation is tracked separately and has no terminal verdict yet.

Required before claiming complete package verification: preserve explicit coverage of these files and repair the owning runner discovery/category contract so new valid test directories cannot silently disappear from the advertised complete target. Do not weaken file-line selection requirements or count zero selected tests as success. This finding belongs to the program verification work and remains open; no source correction has been implemented here.
