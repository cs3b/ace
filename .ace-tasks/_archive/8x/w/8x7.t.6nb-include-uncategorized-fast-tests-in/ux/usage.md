# Complete deterministic selection

1. In a package containing test/fast/authority/owner_test.rb and test/feat/flow_test.rb, run `bin/ace-test fast`: owner_test executes; flow_test does not. Run `bin/ace-test all`: both execute once.
2. A project explicitly configures all to fast only. Run `bin/ace-test all`: fast files execute, feat and e2e remain excluded. Reports reflect this explicit scope.
3. A new uncategorized fast test fails. Default `bin/ace-test all` exits nonzero and names the failing file in its saved report. Running an explicit atoms category does not include the unrelated file.

Commands use the owning checkout binstub with the package as current directory (normally ../bin/ace-test). No new flags.
