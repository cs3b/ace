questions & feedback to
  /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/065-create-ace-docs-package/ux/usage.md

1. what are the all managed documents?

2. how the types works (what are the context docs and where it is defined? we have additional config when we define types by glob or extension ?)

3. what sync is doing ? I'm assume that it will do the full update of docs to up to date - using llm-query

4. how the validate will be configurable - do we have global rules and we can overwrite them in the files    ?

5. in regards of sources - we should always analyze the whole diff, we can only add filters for some files ( if we want to, but it might be safer to allow subagent to make decisions what is relevant for this file ) -> we should only support to git diff -- <glob/path> and by default generate diffs with option -w (ignore whitespce)
How can we ingore rename or move ?

6. the rules should be defined by the linting (we don't have it but it should be delegated there)
   additional rules - they are defined by the guide (not so deterministic, so verify also weould need to use llm-query to do it)
7.
