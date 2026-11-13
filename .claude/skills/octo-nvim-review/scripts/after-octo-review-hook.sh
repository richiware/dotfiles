#!/usr/bin/env bash
# PostToolUse(Bash) hook: after /octo:review runs its pipeline, ask Claude to
# load the findings into the octo.nvim pending review via the octo-nvim-review skill.
cmd=$(jq -r '.tool_input.command // empty')
[[ "$cmd" == *orchestrate.sh*code-review* ]] || exit 0
jq -n '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:
  "The /octo:review pipeline just finished. If it reviewed an open GitHub PR, invoke the octo-nvim-review skill now to load the findings (with fix suggestions) into the user'\''s pending review for octo.nvim."}}'
