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
- Anything matching `zones.human_only` → the reviewer never approves; it goes to Human review with the `needs-human` label.

## Commits

- English, imperative mood, one subject line (≤ 72 chars), body only when the why is not obvious.
- Documentation updates go in the same PR, in a separate commit.
- Never commit secrets, `.env*` (except examples), credentials or keys.

## When the owner rejects a PR

The reason is written in the **Linear issue**, not only in GitHub. It is the only place the CEO reads to avoid repeating the mistake.
