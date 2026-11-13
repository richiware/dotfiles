---
name: octo-nvim-review
description: After a /octo:review (claude-octopus) run on a GitHub pull request, load its findings as draft comments into the user's pending PR review so they appear in neovim via octo.nvim (`:Octo review resume`). Use right after /octo:review finishes on a PR, or when the user asks to send/push/load octopus review findings or suggestions into octo.nvim, neovim, or their pending review.
---

# Octopus findings → octo.nvim pending review

octo.nvim keeps a review in progress as a GitHub **PENDING** review, which only
its author can see. Threads added to it appear in neovim with
`:Octo review resume`, where the user can edit, delete or submit them. Nothing
is public until the user submits the review from neovim.

## When to run

- Right after `/octo:review` finishes and the target is an open PR (or the
  current branch has one: `gh pr view --json number`).
- When the user asks to push or load the latest octopus findings into
  neovim/octo.
- Skip it, and say so, when the review was of staged changes or the working
  tree and no PR exists.

If octopus asked whether to post findings publicly to the PR, that is a
separate path. This skill only writes to the private pending review.

## Steps

1. **Find the findings file.** `/octo:review` writes
   `~/.claude-octopus/results/[<session-id>/]review-findings-<timestamp>.json`
   (`{"findings":[{file,line,severity,category,title,detail,confidence}]}`).
   Use the path the run printed, or else the newest file.

2. **Add suggestions (optional, recommended).** For each finding where the fix
   is concrete, small and certain (a typo, a wrong condition, a missing
   include), read the code at the head of the PR and add a `suggestion` object
   to that finding:
   ```json
   "suggestion": {"start_line": 48, "line": 49, "code": "exact replacement lines\n"}
   ```
   - `start_line`..`line` are lines in the new version of the file. `code`
     replaces those lines exactly, keeping the original indentation. Leave out
     `start_line` for a single line.
   - Don't add a suggestion when the fix is a judgment call or spans more than
     about 15 lines. The prose comment is enough there.
   - Write the enriched copy to the scratchpad directory, never over the
     original file, and pass that path with `--findings`.

3. **Humanize the wording.** Invoke the `humanizer:humanizer` skill and use it
   to rewrite each finding's `title` and `detail` in the enriched copy, so the
   comments read as if a teammate wrote them in a code review.
   - Keep the meaning, the technical facts, and identifiers, file names and
     code spans in backticks exactly as they are. Don't change the `file`,
     `line`, `severity`, `category`, `confidence` or `suggestion` fields.
   - Remove octopus's internal provenance from `detail`, such as
     `[Agent 1, line 49: ...; Agent 2: ... both agents independently
     confirmed ...]`. Reviewers of the PR don't need to know how the finding
     was produced.
   - Keep comments short and direct: say what's wrong, why it matters, and the
     fix. Phrase uncertain findings as questions ("Could this be null
     when...?"), not as verdicts.
   - Make the `title` a short plain sentence, not a headline.

4. **Dry run, then push.**
   ```bash
   python3 ~/.claude/skills/octo-nvim-review/scripts/push_pending_review.py --findings <file> [--pr N] --dry-run
   python3 ~/.claude/skills/octo-nvim-review/scripts/push_pending_review.py --findings <file> [--pr N]
   ```
   Options: `--repo owner/name`, `--min-confidence 0.7` (if the user wants
   only high-confidence findings).

   What the script does:
   - Reuses the user's existing pending review, or starts one on the PR head
     commit.
   - Adds a line thread when the line is in the diff. Otherwise it adds a
     file-level thread, or puts the finding in the review summary when the
     file isn't part of the PR.
   - Skips findings already pushed (each comment carries a hidden
     `<!-- octo-nvim-review:<hash> -->` marker), so a re-run doesn't create
     duplicates.

5. **Report back.** Give the counts (added / skipped / in the summary) and
   tell the user to run `:Octo review resume` in neovim. If an octo review
   buffer is already open, they need to close it (`:Octo review close`) and
   resume to reload.

## Notes

- Only one pending review per user per PR is allowed. Starting a review from
  neovim and running this skill share the same review.
- Requires `gh` authenticated for the repo's host.
