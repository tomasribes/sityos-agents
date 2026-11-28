---
name: linear-conventions
description: Conventions of the CEO system on Linear - workflow states, label groups, who moves each transition, issue contract and branch/PR naming. Use whenever an agent reads, creates or moves a Linear issue.
---

# Linear conventions (CEO system)

Linear is the "what"; GitHub is the "how". No agent keeps its own state: if it is not in Linear, in the repo or in the PR, it does not exist.

## Workspace facts

- Plan: **Free**. No Initiatives, no Loops. Active-issue cap applies: create little, close and archive often.
- Teams: `DEV` (code and versioned config) · `TOM` (owner decisions, content ops, purchases, clients).
- One Linear **project per repo**. Key Results are **milestones** inside it. Objectives are the `goal` label.
- Business line = project label group `line` (`Producto propio`, `Contenido`, `Clientes y automatizaciones`, `Infraestructura y tooling`).

## DEV workflow states

| State | Type | Meaning |
|---|---|---|
| Backlog | backlog | Idea recorded, no acceptance criteria |
| Proposed | unstarted | Written by the CEO, waiting for the owner's OK |
| Ready | unstarted | Approved, assignable to an agent |
| In Progress | started | An agent has a branch open |
| In Review | started | PR open, CI and control agents running |
| Human review | started | Gates green, the owner must look at the PR |
| Blocked | started | Agent stopped: missing context or decision, or a live check failed |
| Pending live | started | PR merged to `develop`; waiting for merge to `master`, deploy and live verification |
| Done | completed | Verified on the live site by the verifier |
| Canceled / Duplicate | canceled | Discarded |

## Who moves what (one owner per transition)

| From → To | Who | Trigger |
|---|---|---|
| Backlog → Proposed | CEO | Has acceptance criteria and fits an active milestone |
| Proposed → Ready | **Owner** | Approves it |
| Proposed → Backlog | CEO | Batch priority changed before approval |
| Ready → In Progress | Agent launched by `/ceo-system:dispatch` | WIP slot free and `role` label has an agent; the agent moves it when it creates the branch (the dispatcher never moves states) |
| Ready → Blocked | Dev | A start condition fails |
| In Progress → In Review | Dev | Opens a non-draft PR. A Linear Git automation may do it; the dev re-reads the issue and moves it if it did not (see `pr-contract` → *Linear after the PR*). A draft PR stays In Progress |
| In Review → In Progress | Tester | FAIL on a criterion |
| In Review → Blocked | Tester | A criterion is not verifiable as written |
| In Review → Human review | Reviewer | No blocking findings |
| Human review → In Progress | **Owner** | Requests changes |
| Human review → Pending live | **Owner** (via GitHub merge) | `Fixes DEV-123` + Linear Git automation "PR merged → Pending live" |
| Pending live → Done | Verifier | Merge commit deployed by a successful `live.deploy_workflow` run and every live check PASS |
| Pending live → Blocked | Verifier | A live check FAILS (evidence in a comment) |
| Blocked → Proposed | CEO | Rewrites or splits it |

Never move an issue along a transition you do not own. **Nobody but the verifier moves an issue to Done**: merged is not finished, live is.

After every state change, re-read the issue (`get_issue`) and report the state Linear returns, not the one you expect.

## Agent comments

The Linear connector writes with the owner's account, so an agent comment looks like the owner wrote it and triggers no notification. Every comment an agent writes starts with `🤖 <agent name> ·` (for example `🤖 dev-frontend · PR abierto`), so the owner can tell it apart and filter it.

## Definition of done: verified live

An issue is finished only when its change works on the public site (`live.url` in `.ceo/config.yml`). Flow:

```
Human review → merge to develop → Pending live → merge develop→master → artifact build → deploy → verifier → Done
                                                                                                  └→ Blocked + evidence
```

The verifier runs with `/ceo-system:live-verify` after each deploy, and automatically at the start of `/ceo-system:ceo-run`. It checks the issue's `## Verificación en producción` section from outside, like a visitor: HTTP with `curl`, visual with Claude in Chrome when connected. Checks it cannot run leave the issue in Pending live with `needs-human` and a checklist for the owner.

## Label groups (issue labels)

Label names are **unique across the workspace**: apply them by their bare name (`dev`, `L0`, `O1`), not `role/dev`.

| Group | Values | Rule |
|---|---|---|
| `role` | dev · tester · reviewer · docs · content · research · pm | exactly 1 — dispatcher routes by it |
| `type` | Bug · Feature · Improvement · Maintenance | exactly 1 |
| `risk` | low · medium · high | exactly 1 |
| `auto` | L0 · L1 · L2 · L3 | exactly 1 — never above the archetype ceiling nor `autonomy.default` |
| `goal` | O1 · O2 · O3 · O4 | exactly 1 when the repo has goals with objectives |
| `area` | drupal · scss · backend · mcp · infra · data · seo · video · editorial | 1 or 2 (`editorial` = content work) |
| `flag` | needs-scoping · needs-human · budget-hit · agent-paused | any; any flag removes the issue from the queue |

`needs-human` means "blocked on an owner decision", never "touches a human_only zone". Scope that touches `zones.human_only` is stated in the description (`**Zona human_only:** ...`) and enforced by the reviewer at PR time.

## Autonomy levels

| Level | Agent may |
|---|---|
| L0 · Proposes | Create the issue in Proposed. Nobody assigned. Owner moves it to Ready |
| L1 · Executes | Take Ready issues, implement, open PR to `develop` |
| L2 · Integrates | L1 + auto-merge to `develop` if CI + tester + reviewer pass |
| L3 · Autonomous | Direct commit in declared sandbox zones only |

Default level per change category: docs/README/UI translations L2 · new tests L2 · patch/minor deps with green CI L1 · internal refactor L1 · new feature/endpoint/Drupal field L1 · SCSS/theme incl. critical CSS L1 · DB migrations and update hooks L0 · exported Drupal config L0 · trading decision/risk/sizing L0 · major deps or runtime versions L0 · secrets/CI/CD/infra/DNS L0 (written proposal only).

A new project runs **entirely at L0 for two weeks** (`autonomy.default: L0` in `.ceo/config.yml`). The table is the destination, not the start.

## Issue contract (seven conditions)

1. **Title**: imperative, in Spanish, ≤ 80 chars, without the project name.
2. **Observable result**: one sentence describing what will be true, checkable without reading code.
3. **Acceptance criteria**: checkbox list, 2–6 items, each verifiable by a test, a command or a screenshot. Seven or more → split into sub-issues.
4. **Closed scope**: expected files/modules, plus a line `Fuera de alcance:` with what must not be touched.
5. **Labels**: one of role, type, risk, auto, goal; one or two of area.
6. **Size**: fits a PR the owner reviews in 10 minutes (≤ 400 diff lines) and ≤ 4 h of work.
7. **Live verification**: a `## Verificación en producción` section with 1–4 checks run against `live.url` from outside (URL + expected status, header, HTML fragment or visible behaviour; viewport when it matters). If nothing is observable on the public site (drafts in `docs/`, internal tooling), write `No aplica: <motivo>`; the verifier then closes the issue once the merge commit is deployed. Never "check the code" or "run locally" here.

Implementation detail goes in a collapsible section at the end of the description:

```
+++ Agent notes

Candidate files, commands to run, risks, what was tried before.

+++
```

## Branch and PR naming

- Branch: the name Linear generates for the issue (`<user>/dev-123-slug`). The Linear GitHub integration *may* move the issue to In Progress on branch creation and to In Review on PR open, depending on each team's Git automations. **Agents never rely on it**: the dev moves the issue to In Progress when it creates the branch (before opening the PR) and checks In Review after opening it.
- PR title starts with the identifier: `DEV-123: ...`. PR body contains `Fixes DEV-123`.
- PR base is `branches.base` from `.ceo/config.yml` (normally `develop`). **Never** `master`/`main`.

## Kill-switches

- Project level: **project label** `agent-paused` on the Linear project → CEO and dispatcher exit cleanly. (The issue label `agent-paused` pauses a single issue.)
- Repo level: file `.ceo/PAUSE` exists → exit without doing anything.
