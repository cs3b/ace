We have made signficant change in the way we place certain folders:

- docs-dev/tools -> dev-tools/exe-old
- docs-dev -> dev-handbook
- docs-project -> dev-taskflow
- exe -> dev-tools/exe

So now we have update all the references (only in this directories)

- bin
- docs
- .claude/
- *.md

To reflect that change.


find . -type f -name "bin/**/*" -exec perl -pi -e 's/old_string/new_string/g' {} +

and then review all the changes in the repository and submodules
