---
name: component-fix-and-verify
description: Apply a diagnosed fix to a component and verify it through scoped then broad checks — tsc, lint, and tests — with mandatory diff preview and atomic safety
license: Apache-2.0
metadata:
  author: Daniel Song
  version: 1.0.0
  suite: frontend-qa-skills
  pipeline_position: S3
  upstream_contract: DiagnosisReport
  downstream_contract: FixResult
---

# Procedure

## Phase 1: Pre-flight

1. Run `git status --short`. If untracked or modified files exist outside the fix scope, warn: "Working tree has uncommitted changes in: [files]. These are unrelated to this fix." Pause for acknowledgment.
2. If no git repo, warn: "No git repository — revert will require manual undo." Pause.
3. Identify the files to change from the DiagnosisReport. Record them as `affectedFiles`.
4. Capture baseline state: run `tsc --noEmit 2>&1 | tail -5` and record pre-existing error count. Note: "Baseline: N pre-existing type errors."

## Phase 2: Preview

5. Generate the complete fix as a unified diff. Show it with a plain-language explanation:
   - What changes and why (1-2 sentences per file)
   - **What this does NOT address** — related issues the fix intentionally leaves untouched
   - Risk level: **Low** (style/typo), **Medium** (logic change), or **High** (architectural change, cross-file)
6. Pause: "Review the diff above. Apply this fix?"
7. Do NOT write any file until the user confirms.

## Phase 3: Apply

8. Write the changes to disk. One fix at a time — never batch multiple independent fixes.
9. Record exactly what was written for revert reference.

## Phase 4: Scoped Verification

10. Read `references/verification-commands.md`. Run scoped checks on `affectedFiles` only:
    - **TypeScript**: `tsc --noEmit` on affected files (see reference for project-specific variants)
    - **Lint**: detected linter on affected files (ESLint, Biome, or project lint script)
    - **Tests**: related tests only (`vitest --related`, `jest --findRelatedTests`, or directory-scoped)
11. If test runner is not detected or test command fails to start, report: "No test infrastructure detected. Verification limited to tsc + lint." Mark tests as SKIPPED.
12. If any scoped check fails, skip Phase 5. Go directly to Phase 6 with FAIL.

## Phase 5: Broad Verification

13. Run full-project `tsc --noEmit`. Compare error count to Phase 1 baseline.
14. Run full test suite via the project's test script (`npm test`, `pnpm test`, etc.).
15. If broad checks introduce new failures beyond the Phase 1 baseline, go to Phase 6 with FAIL. If only pre-existing failures remain, go to Phase 6 with PARTIAL.

## Phase 6: Verdict

Report one of three outcomes:

**PASS** — All scoped and broad checks green.
```
Fix verified: PASS
  tsc: 0 errors (was N baseline)
  lint: clean
  tests: M passed, 0 failed
  scope: [affectedFiles]
```

**FAIL** — Any check introduced new errors. Do NOT auto-revert. Show:
```
Fix verified: FAIL
  failed phase: [Scoped Verification | Broad Verification]
  failing check: [tsc | lint | tests]
  error: [first error message]
  files changed: [affectedFiles]

Options:
  1. Show full error output
  2. Revert this fix (restores original files)
  3. Keep changes and investigate
```

**PARTIAL** — Fix is clean but pre-existing failures exist in broad checks.
```
Fix verified: PARTIAL
  scoped checks: all passed
  broad checks: pre-existing failures detected (not caused by this fix)
  pre-existing: N type errors, M test failures (same as baseline)
  scope: [affectedFiles]
```

16. If user chooses revert on FAIL: restore the original file contents recorded in Phase 3, then confirm: "Reverted [N] files. Working tree matches pre-fix state."

## Visual Triage (When Screenshots Provided)

If the DiagnosisReport includes before/after screenshots:

**Tier 1 — Qualitative** (always available): Examine both screenshots cross-referenced with the code changes. Report observations with mandatory disclaimers:
- "Visual analysis is qualitative, not pixel-accurate"
- "Sub-pixel differences require dedicated tooling"
- "Dynamic states (hover, animation) cannot be assessed from static screenshots"
- Never state "no visual differences" as a pass — say "no differences observed in static comparison"

**Tier 2 — Automated** (if tooling detected): Check for Playwright with `toHaveScreenshot()` or pixelmatch in dependencies. If found, scaffold the comparison command and run it. If not found, note: "Automated visual regression available with Playwright — see playwright.dev/docs/test-snapshots." Proceed with Tier 1 only.

## Output Contract: FixResult

```yaml
FixResult:
  version: "1.0"
  diagnosis_ref: "[DiagnosisReport ID]"
  affectedFiles: ["path/to/file.tsx"]
  diff: "[unified diff string]"
  verdict: "PASS | FAIL | PARTIAL"
  checks:
    tsc: { status: "pass|fail|skip", errors: 0, baseline: 0 }
    lint: { status: "pass|fail|skip", tool: "eslint|biome|none" }
    tests: { status: "pass|fail|skip", passed: 0, failed: 0, runner: "vitest|jest|none" }
  visual: { tier: "1|2|none", observations: "string" }
  notAddressed: ["related issue this fix does not cover"]
  reverted: false
```
