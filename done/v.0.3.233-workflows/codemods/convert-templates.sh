#!/bin/bash
# Script to convert all workflow files from four-tick to XML template format

cd dev-handbook

# List of workflow files with templates
files=(
    "workflow-instructions/create-api-docs.wf.md"
    "workflow-instructions/create-test-cases.wf.md"
    "workflow-instructions/publish-release.wf.md"
    "workflow-instructions/draft-release.wf.md"
    "workflow-instructions/initialize-project-structure.wf.md"
    "workflow-instructions/create-reflection-note.wf.md"
    "workflow-instructions/review-task.wf.md"
    "workflow-instructions/update-roadmap.wf.md"
    "workflow-instructions/update-blueprint.wf.md"
    "workflow-instructions/create-task.wf.md"
)

for file in "${files[@]}"; do
    echo "Processing $file..."
    
    # Check if file has four-tick templates
    if grep -q "````" "$file"; then
        echo "  - Found four-tick templates in $file"
        
        # Use sed to replace four-tick blocks with XML format
        # This is a simplified approach - we'll need to manually adjust
        sed -i.bak 's/````markdown/```markdown/g' "$file"
        sed -i.bak 's/````yaml/```yaml/g' "$file"
        sed -i.bak 's/````json/```json/g' "$file"
        sed -i.bak 's/````bash/```bash/g' "$file"
        sed -i.bak 's/````/```/g' "$file"
        
        echo "  - Converted four-tick to three-tick in $file"
    fi
done

echo "Conversion complete. Manual XML template conversion still needed."