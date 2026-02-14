---
name: qa-coordinator
description: Orchestrate frontend QA for Next.js/TypeScript. Classifies symptoms, dispatches to specialists, pauses for confirmation at each phase.
license: Apache-2.0
metadata:
  author: Daniel Song
  version: 1.0.0
  suite: frontend-qa-skills
  pipeline_position: C0
---

# QA Coordinator

Classify the issue, auto-detect the stack, dispatch to specialists, pause between phases.

## Stack Detection

If no `.claude/qa-cache/project-config.json`: read `package.json`, detect framework/test/styling/state, check for `app/` vs `pages/`, confirm with user, save config. Re-detect only when `package.json` changes.

## Classification

Extract **route** and **symptom** from user input. If ambiguous, ask one question.

| Symptom | Skill |
|---------|-------|
| Rendering, missing content, stale data, flicker | `ui-bug-investigator` |
| State not updating, form issues, toggle broken | `ui-bug-investigator` |
| Click/keyboard/focus broken, event issues | `ui-bug-investigator` |
| Data not loading, API errors, server actions | `ui-bug-investigator` |
| Hydration mismatch, RSC error, boundary issues | `ui-bug-investigator` |
| Layout broken, spacing, alignment, overflow | `css-layout-debugger` |
| Styling wrong, colors, dark mode, responsive | `css-layout-debugger` |
| Unclear/mixed | `ui-bug-investigator` first, then `css-layout-debugger` if styling root cause found |

## Pipeline

**MAP**: Read `page-component-mapper/SKILL.md`, follow its procedure. Pause: "{N} components mapped. Continue?"

**DIAGNOSE**: Read the classified skill's SKILL.md, pass ComponentMap path + symptom + classification. Pause: "Root cause: {description} in {file}:{line}. Proceed with fix?"

**FIX**: Read `component-fix-and-verify/SKILL.md`, pass DiagnosisReport + ComponentMap paths. Pause: "{PASS/FAIL/PARTIAL}. Generate regression test?"

**TEST**: Read `regression-test-generator/SKILL.md`, pass FixResult + DiagnosisReport + ComponentMap paths. "Test written. Investigation complete."

## Skill Registry

| Skill | Path |
|-------|------|
| Mapper | `page-component-mapper/SKILL.md` |
| UI Investigator | `ui-bug-investigator/SKILL.md` |
| CSS Debugger | `css-layout-debugger/SKILL.md` |
| Fix & Verify | `component-fix-and-verify/SKILL.md` |
| Test Generator | `regression-test-generator/SKILL.md` |

## Rules

- Route silently. Never present a skill menu.
- Sequential only. Never skip a pause. If user declines, stop and summarize.
- To re-run a phase, re-read the specialist SKILL.md and re-execute.
