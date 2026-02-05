Commit all changes with a short commit message and push to current branch:

1. Stage all changes with `git add .`
2. Review the full diff with `git diff --cached` to understand ALL changes being committed
3. Analyze the diff content to identify the most significant changes
4. Create a concise 1-sentence commit message that captures the primary purpose of the changes
   - If multiple unrelated changes exist, mention the most important one
   - Don't base the message only on recent session context - analyze the actual diff
5. Commit the changes
6. Push to the current branch via `git push`

Keep the commit message short but ensure it reflects what the diff actually contains.
