# Explicit test selection — draft usage

## Missing file with a layer

`bin/ace-test ace-lab organisms test/organisms/missing_test.rb`

Expected: nonzero input error naming the missing selector; no organism tests start.

## Mixed valid and missing files

`bin/ace-test ace-lab organisms test/organisms/authority_composition_test.rb test/organisms/missing_test.rb`

Expected: reject the whole selection before execution. Reversing file order has the same outcome.

## Existing explicit selection

`bin/ace-test ace-lab organisms test/organisms/authority_composition_test.rb`

Expected: the requested file runs under existing execution policy. Named target usage without an explicit file retains its documented behavior.
