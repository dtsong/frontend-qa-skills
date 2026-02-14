---
name: page-component-mapper
description: Map a Next.js route to its full component tree with server/client boundaries, props, hooks, data fetching, and styling metadata. Use when investigating any frontend issue, before diagnosis or debugging.
license: Apache-2.0
metadata:
  author: Daniel Song
  version: 1.0.0
  suite: frontend-qa-skills
  pipeline_position: S0
  upstream_contract: Route
  downstream_contract: ComponentMap
---

# Page Component Mapper

Given a route, produce a depth-limited component tree with file paths, server/client boundaries, props, hooks, state management, data fetching patterns, and styling metadata. Output a ComponentMap artifact consumed by all downstream skills.

## Procedure

### Step 0: Check Cache

1. Look for `.claude/qa-cache/component-maps/{route-slug}.json`.
2. If found, follow the caching protocol in `references/caching-protocol.md`.
3. If cache is valid, return the cached map and print:
   `Using cached map ({age} old, {N} components, completeness: {level}) | --fresh to rebuild`
4. If `--fresh` flag provided, skip cache entirely.

### Step 1: Resolve tsconfig Path Aliases (PREREQUISITE)

1. Read `tsconfig.json` at the project root. If it has an `extends` field, read the parent config too.
2. Extract `compilerOptions.paths` and `compilerOptions.baseUrl`.
3. Build a lookup table mapping each alias pattern to its resolved directory.
   Example: `{ "@/*": "./src/*", "~/lib/*": "./lib/*" }`.
4. Keep this table in working memory -- use it to resolve every aliased import in Steps 2-3.
5. If `tsconfig.json` is missing, warn the user and proceed with relative-path-only resolution.

### Step 2: Identify Route Entry Points

**App Router** (default -- `app/` directory exists):
1. Locate `app/{route}/page.tsx` (or `.ts`, `.jsx`, `.js`).
2. Also locate if present: `layout.tsx`, `loading.tsx`, `error.tsx`, `not-found.tsx` in the same directory and parent directories up to `app/layout.tsx`.
3. The trace order is: root layout -> nested layouts -> loading -> error -> page.

**Pages Router** (fallback -- `pages/` directory, no `app/`):
1. Locate `pages/{route}.tsx` (or `pages/{route}/index.tsx`).
2. Also check `pages/_app.tsx` and `pages/_document.tsx`.
3. Look for `getServerSideProps` or `getStaticProps` exports.

### Step 3: Trace Imports (Depth-Limited)

Default depth: **3 levels** from route entry. Override with `--depth N`.

For each file, starting from the entry points found in Step 2:

1. Read the file. Scan the first 5 lines for `'use client'` or `'use server'` directives.
2. Extract all import statements. For each import, resolve the target:
   - **Relative** (`./Button`): try `.tsx`, `.ts`, `.jsx`, `.js`, `/index.tsx`, `/index.ts`
   - **Aliased** (`@/components/Button`): resolve using the Step 1 lookup table, then try extensions
   - **External** (`react`, `next/link`, `@radix-ui/*`): record as external, stop tracing
   - **Dynamic** (`next/dynamic(() => import(...))`, `React.lazy`): trace literal paths, flag `isDynamic: true`
   - **Barrel** (`import { X } from './components'`): follow re-export through index files, cap at 5 levels
3. For detailed resolution rules and edge cases, read `references/import-tracing-protocol.md`.
4. For each resolved component file, extract:
   - `displayName`: the component function/const name
   - `boundary`: `"server"` (has `'use server'` or in `app/` without directive), `"client"` (has `'use client'`), `"shared"` (no directive, outside `app/`)
   - `props`: from TypeScript type annotation on the component parameter
   - `hooks`: all `useXxx(` calls
   - `stateManagement`: imports from `zustand`, `jotai`, `recoil`, `@tanstack/react-query`, or React context usage
   - `dataFetching`: `fetch()` calls, server actions, tRPC calls, React Query hooks, SWR hooks
   - `styling_approach`: based on import type (`.module.css` -> css-modules, tailwind classes in JSX -> tailwind)
   - `has_conditional_classes`: `clsx(`, `cn(`, `classNames(`, or ternary in className
   - `design_system_component`: true if imported from a known UI library
   - `accepts_className_prop`: true if props type includes `className`
   - `layout_role`: infer from file location and component name
5. If at the depth limit, record remaining imports with `unresolved: true, unresolvedReason: "depth-limit"`.

### Step 4: Classify Completeness

- `"full"`: `unresolvedImports` array is empty
- `"shallow"`: all unresolved entries have reason `"depth-limit"`
- `"partial"`: any unresolved entry has a non-depth reason (`"dynamic-computed"`, `"barrel-depth-exceeded"`, `"not-found"`)

### Step 5: Persist and Present

1. Collect all resolved file paths into `cachedFiles` array.
2. Write the ComponentMap to `.claude/qa-cache/component-maps/{route-slug}.json`.
3. Present a summary to the user:

```
Component Map: /dashboard/settings (depth 3, shallow)
Entry: app/dashboard/settings/page.tsx [server]
  Layout: app/dashboard/layout.tsx [server]

23 components mapped | 4 unresolved (depth-limit) | 2 external (shadcn)

Server (8): SettingsPage, SettingsLayout, AccountSection, ...
Client (12): ThemeToggle, NotificationForm, ProfileEditor, ...
Shared (3): Button, Card, Input

Data flow: 2 server actions, 1 React Query hook, 3 prop chains
Hooks: useState(5), useEffect(3), useForm(2), useQuery(1)
```

4. Wait for user confirmation before the coordinator proceeds to diagnosis.

## Output Format

The ComponentMap JSON follows the schema in the design document. Key fields:

```json
{
  "version": "1.0",
  "route": "/dashboard/settings",
  "depth": 3,
  "completeness": "shallow",
  "framework": { "name": "next", "routerType": "app", "version": "14.1.0" },
  "entryComponent": {
    "filePath": "/abs/path/app/dashboard/settings/page.tsx",
    "displayName": "SettingsPage",
    "boundary": "server",
    "imports": [{ "targetPath": "...", "importType": "component" }]
  },
  "unresolvedImports": [{ "sourcePath": "...", "importSpecifier": "./DeepChild", "reason": "depth-limit" }],
  "cachedFiles": ["..."]
}
```
