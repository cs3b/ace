# Exact test selection — draft CLI contract

Given `test/fast/example_test.rb` with `test_alpha` declared at20, its body at21–24 and closing end at25:

- `bin/ace-test ace-example fast test/fast/example_test.rb:20` executes only that test. Lines21–25 select the same identity.
- `bin/ace-test ace-example fast test/fast/example_test.rb:19`, where19 is blank outside any test, exits nonzero with a selector error. It does not load the selected test file or run its tests.
- Combining a valid line20 with nonexistent line999 refuses the whole request before test execution. It does not run line20 alone.
- An unqualified `bin/ace-test ace-example fast test/fast/example_test.rb` keeps ordinary whole-file behavior.

These are behavioral examples against a controlled fixture, not current guarantees. Same-prefix and inherited methods are never implied by an explicit line selection.
