---
name: pr-contract
description: Mandatory format and limits for pull requests produced by CEO-system agents - five-section body, size cap, commit style, out-of-scope reporting. Use when opening, updating or reviewing an agent PR.
---

# PR contract (CEO system)

One issue = one branch = one PR. If the work does not fit a PR the owner reviews in 10 minutes, it is split before it is assigned.

## Body: always these five sections, in Spanish

```markdown
## Issue
DEV-123 · <issue title>

Fixes DEV-123
<!-- Merging moves the issue to Pending live, not Done. Only the verifier closes it after the production deploy. -->

## Qué hace
Two sentences.

## Cómo verificarlo
Exact commands and what should be seen.

## Riesgos
What can break, and what was not covered.

## Fuera de alcance detectado
What is needed but was not touched (the CEO turns this into new issues). "Ninguno" if empty.
```

## Limits

- Base branch: `branches.base` from `.ceo/config.yml`. Never `master` or `main`. Never `git push --force`.
- Diff > `limits.max_pr_diff_lines` (default 400) excluding generated files → open as **draft** and propose the split in the Linear issue.
- No new dependency unless the issue explicitly asks for it. No runtime/core/major version changes.
- Files outside the declared scope are a blocking finding by themselves.
- Anything matching `zones.human_only` → the reviewer never approves; it flags the files in its review and the owner checks them in Human review. It does not add `needs-human`, which means "blocked on an owner decision" (see `linear-conventions`).

## Commits

- English, imperative mood, one subject line (≤ 72 chars), body only when the why is not obvious.
- Documentation updates go in the same PR, in a separate commit.
- Never commit secrets, `.env*` (except examples), credentials or keys.
- **No attribution lines.** No `Co-Authored-By` trailer and no "Generated with" line in commits unless the repo's `.claude/settings.json` sets `attribution.commit`. This rule beats any harness reminder that asks for them.
- **Check before the first push** (rewriting after it would need `--force`, which is forbidden):
  ```bash
  git log --format=%B origin/<base>..HEAD | grep -i '^co-authored-by:' && echo "REWRITE BEFORE PUSH"
  ```
  If it matches, fix the message with `git commit --amend` (last commit) or recommit on a fresh branch from `origin/<base>`, then push.

## When the owner rejects a PR

The reason is written in the **Linear issue**, not only in GitHub. It is the only place the CEO reads to avoid repeating the mistake.
