Coding Agent strugtle with proper path (because don't know where they are and try to count r in strawberries (counting path traversiong))

# input
bin/path asdfasdf/some/wrong/path

# how it works
- we should use fuzyy search to get the most probably paths
- present paths relative from the project root
- we should be able to define folders with preferences

- maybe we should name it differently the path - its not $PATH (maybe bin/navigate-me, or somethign else meanigful and short)

# output

project root:
possible path:
-
-
-
-
-


### suplementary

create rules file:
dev-handbook/.integrations/claude/rules.md
- when you have issue with file not found, run: ${project_path}/bin/path


#######

Additional to this we can have bin/exe (with full path in the rule to run any cmd from project home directory)

bin/exe bin/lint | bin/test ... etc

#######

bin/new <filecode> (optional: codename) (optional: --release --parent-path --context task / info relevant for generating path   )

e.g.
- bin/new task create-llm-query -> path to new file with some tags already prefiled (dates / id)
- bin/new reflection-note -> path to new file with structure
- ...
