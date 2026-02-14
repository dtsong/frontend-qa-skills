## Diagnosis: Sidebar overlaps main content on mobile

### FLAGGED: app/components/Sidebar.tsx:42 -- Fixed width with no responsive breakpoint

The Sidebar uses `position: fixed` with a hardcoded `w-[280px]` Tailwind class. There is
no responsive variant (e.g., `max-md:hidden` or `max-md:w-0`) to collapse the sidebar on
narrow viewports. MainContent has a corresponding `ml-[280px]` that also lacks a responsive
override, so on mobile the sidebar and content overlap.

Evidence:
- **Sidebar.tsx:42** -- `className="fixed left-0 top-0 h-full w-[280px]"` has no `md:` or `max-md:` variant
- **MainContent.tsx:18** -- `className="ml-[280px] p-6"` hardcodes the offset with no responsive fallback
- Reported symptom matches: fixed sidebar + static margin = overlap on viewports below 768px

### CLEAR
- **DashboardLayout.tsx** (app/components/DashboardLayout.tsx) -- flex container is correctly configured, not the cause
- **NavItem.tsx** (app/components/NavItem.tsx) -- no layout-affecting styles
- **UserMenu.tsx** (app/components/UserMenu.tsx) -- positioned within Sidebar, not independently

### SKIPPED (3 categories)
- Data Flow -- not relevant to layout/visual symptom
- Event Handling -- not relevant to layout/visual symptom
- Next.js-Specific -- no server/client boundary signals in the report

Checked: 5 components (Styling, Rendering, Layout) | Not checked: Data Flow, Events, Next.js-Specific | Confidence: High
