# Unified the way we embed templates in workflows

## at create task workflow

a) go through all the workflow instructions and make list of all embeded templates / documents

b) compare this with what we have int dev-handbook/templates/**/*

- match the embede document with the template
- check the difference between them
- if template is not found propose where should we create it

## at work on task workflow

c) create missing templates

d) update the workflow guide how to embed templates

- they should be at the very end of the workflow instruction with format

- escaped with ```` four tics ````
- path of document in the project (in the workflow part we should use only this name, and refer to templates at the end of the document)
- (path for the template)

````docs/architecture.md (dev-handbook/templates/project-docs/architecture.template.md)



````

e) write a script that update the content of the embeded documents:
  `markdown-sync-embeded-documents dev-handbook/workflow-instructions/*.wf.md`

- it scans for all the embeded templates in workflow instructions folder
  (embeding starting block should follow the path: ````$path ($template_path)
- it one by one it check of the content of the block is identical as in template if not it updates
- present summary of have been done
- commit changes bin/gc -i 'chore: sync embede templates in workflow instructions'

f) run this script and ensure it update all the embeded templates

g) update documentation about this script
