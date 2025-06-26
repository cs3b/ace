1. read [@fix-tests.wf.md](@file:coding-agent-tools/dev-handbook/workflow-instructions/fix-tests.wf.md)

2. read recommended docs from document read in step 1.

3. use instructions from step 1 to
a) identified failing test (use `bin/test --next-failure` to effectively identified next failing tests)
b) investigate the rease
c) implement the solutions (only if not sure about solution ask user)
d) go back to step 2.a untill it will return no error

4. run full test test suite (`bin/test`), and ensure everything works fine
