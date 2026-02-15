# Frontend QA Skills Catalog

> A suite of Claude Code skills for component-level frontend QA in Next.js App Router / TypeScript projects. Six skills form a pipeline: map page components, diagnose bugs, debug CSS/layout, apply and verify fixes, generate regression tests -- orchestrated by a coordinator that classifies symptoms and dispatches silently.

---

## How to Use This Catalog

1. **Install** the suite using [install.sh](install.sh)
2. **Describe the bug** naturally -- the coordinator routes to the right skill
3. **Skills auto-activate** when Claude detects relevant keywords in your conversation
4. **Progressive loading**: only the coordinator + one specialist + one reference are loaded at a time (worst-case ~5,000 tokens)
5. **Always-pause**: the pipeline pauses for your confirmation between each phase

---

## Pipeline Flow

```
USER REPORT (route + description + optional screenshot)
       |
       v
 qa-coordinator (auto-detect stack, classify symptom, dispatch)
       |
       v
 page-component-mapper (build/refresh component map)
       |
       +---> [PAUSE: confirm component tree]
       |
       v
 qa-coordinator (route to specialist)
       |
       +----> ui-bug-investigator ------+
       +----> css-layout-debugger ------+---> DiagnosisReport
       |                                |
       +---> [PAUSE: confirm diagnosis] <+
       |
       v
 component-fix-and-verify (apply fix, verify)
       |
       +---> [PAUSE: confirm fix result]
       |
       v
 regression-test-generator (generate targeted test)
       |
       +---> [PAUSE: confirm test]
       v
     DONE
```

Each stage produces a typed artifact consumed by the next:

```
ComponentMap --> DiagnosisReport --> FixResult --> RegressionTest
```

---

## Skills

### Orchestration

| Skill | Description | Status |
|-------|-------------|--------|
| [qa-coordinator](qa-coordinator/) | Classify symptoms, auto-detect stack, dispatch to specialists, manage pipeline with pause points | **Available** |

**Trigger keywords**: bug, broken, investigate, QA, frontend issue, debug, not working, broken page

---

### Mapping

| Skill | Description | Status |
|-------|-------------|--------|
| [page-component-mapper](page-component-mapper/) | Route-to-component tree mapping with depth-limited tracing, server/client boundary detection, and caching | **Available** |

**Trigger keywords**: component map, component tree, page structure, what components, trace imports, route map

**Outputs**: `ComponentMap` -- component tree with props, hooks, boundaries, styling metadata, completeness field

---

### Diagnosis

| Skill | Description | Status |
|-------|-------------|--------|
| [ui-bug-investigator](ui-bug-investigator/) | Symptom-targeted diagnosis for rendering, state, data flow, and event handling bugs | **Available** |
| [css-layout-debugger](css-layout-debugger/) | Six-phase CSS diagnostic pipeline: token resolution, cascade, layout model, stacking, viewport | **Available** |

**Trigger keywords (ui-bug-investigator)**: blank screen, wrong data, stale data, click does nothing, hydration mismatch, flicker, re-render, state bug

**Trigger keywords (css-layout-debugger)**: layout broken, overlapping, spacing wrong, responsive issue, Tailwind conflict, z-index, overflow, CSS bug, dark mode

**Outputs**: `DiagnosisReport` -- FLAGGED/CLEAR/SKIPPED findings with evidence and scope-aware summary

---

### Remediation

| Skill | Description | Status |
|-------|-------------|--------|
| [component-fix-and-verify](component-fix-and-verify/) | Five-phase verification pipeline: pre-flight, apply, scoped verify, broad verify, verdict | **Available** |
| [regression-test-generator](regression-test-generator/) | Convention-aware regression test generation for Vitest+RTL, Jest+RTL, and Playwright | **Available** |

**Trigger keywords (fix-and-verify)**: fix it, apply fix, verify fix, run tests, check fix

**Trigger keywords (regression-test-generator)**: write test, regression test, prevent regression, test for this bug

**Outputs (fix-and-verify)**: `FixResult` -- changes applied, verification results, PASS/FAIL/PARTIAL verdict

**Outputs (regression-test-generator)**: `RegressionTest` -- test file with GUARDS AGAINST / DOES NOT GUARD AGAINST annotations

---

## Slash Commands

| Command | Description |
|---------|-------------|
| [`/qa`](commands/qa.md) | Full pipeline: describe the bug, the coordinator handles the rest |
| [`/map`](commands/map.md) | Map a route's component tree (mapper only) |
| [`/diagnose`](commands/diagnose.md) | Diagnose a bug against an existing component map |
| [`/fix`](commands/fix.md) | Apply and verify a fix from an existing diagnosis |

---

## Shared References

| Resource | Description | Referenced By |
|----------|-------------|---------------|
| [nextjs-app-router-gotchas](shared-references/frontend-qa/nextjs-app-router-gotchas.md) | Hydration, boundaries, fetch caching, Suspense, metadata | ui-bug-investigator, css-layout-debugger |
| [css-debugging-checklist](shared-references/frontend-qa/css-debugging-checklist.md) | 8 CSS bug categories, Tailwind patterns, CSS Modules gotchas | css-layout-debugger |
| [test-generation-patterns](shared-references/frontend-qa/test-generation-patterns.md) | Framework routing, anti-brittleness rules, query hierarchy | regression-test-generator |
| [component-analysis-patterns](shared-references/frontend-qa/component-analysis-patterns.md) | Import tracing, boundary detection, prop flow analysis | page-component-mapper, ui-bug-investigator |

---

## Skill Sizing

| Skill | SKILL.md Lines | SKILL.md ~Tokens | Ref Files | Ref ~Tokens (each) | Total Lines |
|-------|---------------|-----------------|-----------|-------------------|-------------|
| qa-coordinator | 101 | ~1,094 | 0 | -- | 101 |
| page-component-mapper | 128 | ~1,522 | 2 | ~1,024 / ~1,224 | 336 |
| ui-bug-investigator | 123 | ~1,288 | 3 | ~1,121 / ~1,148 / ~1,312 | 277 |
| css-layout-debugger | 131 | ~1,528 | 3 | ~1,381 / ~1,493 / ~1,506 | 317 |
| component-fix-and-verify | 118 | ~1,293 | 1 | ~966 | 258 |
| regression-test-generator | 130 | ~1,226 | 2 | ~1,023 / ~1,178 | 403 |
| **Shared references** | -- | -- | 4 | ~1,091-1,602 | 371 |
| **Suite total** | **731** | | **15** | | **~2,063** |

Worst-case context cost: coordinator (~1,094) + specialist (~1,528) + reference (~1,506) = ~4,128 tokens.

---

## Installation

```bash
# Install into a Next.js project
./install.sh /path/to/your/nextjs-project

# Install globally (available to all projects)
./install.sh --global

# Install specific roles
./install.sh --role diagnosis /path/to/your/nextjs-project
./install.sh --role diagnosis --global
```

Skills are installed to `.claude/skills/frontend-qa/` and slash commands to `.claude/commands/`.

### Role-Based Presets

| Role | Command | Skills Installed |
|------|---------|------------------|
| Full Suite | `./install.sh --role full` | All 6 skills + shared references |
| Diagnosis Only | `./install.sh --role diagnosis` | qa-coordinator, page-component-mapper, ui-bug-investigator, css-layout-debugger |
| Fix & Test | `./install.sh --role remediation` | component-fix-and-verify, regression-test-generator |

Shared references are always installed regardless of role.

### Global vs Project Install

| | Project (`./install.sh /path`) | Global (`./install.sh --global`) |
|---|---|---|
| Skills location | `<project>/.claude/skills/frontend-qa/` | `~/.claude/skills/frontend-qa/` |
| Commands location | `<project>/.claude/commands/` | `~/.claude/commands/` |
| Cache dirs | Created at install time | Created per-project on first use |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-14 | Initial release: 6 skills, 15 reference files, 4 shared references, 4 slash commands |
