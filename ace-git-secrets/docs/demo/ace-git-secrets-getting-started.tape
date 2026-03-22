# Description: Show ace-git-secrets detecting a leaked token in a sample repository
# Tags: ace-git-secrets,docs,security

Output ace-git-secrets/docs/demo/ace-git-secrets-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

Type "rm -rf .ace-local/demo/ace-git-secrets-scan-repo && mkdir -p .ace-local/demo/ace-git-secrets-scan-repo"
Enter
Sleep 1s

Type "cd .ace-local/demo/ace-git-secrets-scan-repo && git init -q && git config user.email demo@example.com && git config user.name demo"
Enter
Sleep 1s

Type "TOKEN_PREFIX=ghp_ && TOKEN_SUFFIX=123456789012345678901234567890123456 && printf 'GITHUB_TOKEN=%s%s\n' $TOKEN_PREFIX $TOKEN_SUFFIX > .env && git add .env && git commit -qm seed-demo-token"
Enter
Sleep 1s

Type "ace-git-secrets scan"
Enter
Sleep 4s
