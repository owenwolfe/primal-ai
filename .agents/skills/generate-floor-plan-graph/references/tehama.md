# Tehama Hall (`tehama`)

Generated 2026-10-27 from all supplied Tehama floor plans. No existing Tehama dataset or conflicting application building ID was found.

## Sources and outputs

- `csuc-floor-plans/Tehama/tehama-1.pdf`: first floor, dated 2008-08-05, sheet 2 of 5.
- `csuc-floor-plans/Tehama/tehama-2.pdf`: second floor, dated 2008-08-05, sheet 3 of 5.
- `csuc-floor-plans/Tehama/tehama-3.pdf`: third floor, dated 2008-08-05, sheet 4 of 5.
- Each PDF has one 612 × 792 point page, rotation 0. Labels are vector outlines; text extraction is empty. All were visually inspected, including enlarged doorway details.
- Each prints `1 inch = 30 feet`: use 30/72 feet per native PDF point, or 30/144 feet per pixel in the 2× inspection render.
- `src/data/tehama/floor-1.json`: 109 nodes, 113 within-floor edges.
- `src/data/tehama/floor-2.json`: 161 nodes, 165 within-floor edges.
- `src/data/tehama/floor-3.json`: 182 nodes, 185 within-floor edges.
- `src/data/tehama/connections.json`: 9 adjacent-floor links.
- Three explicitly requested `floor-<n>-preview.png` files overlay the final saved JSON on source plans. These are local review aids, not application imports or commit artifacts.

## Coordinates and alignment

Origin: `tehama-1-exit-north-ao`, the AO-marked northeast exterior double door beside room 106. Native first-floor PDF coordinate is **(362, 139)** from top-left. Positive X is drawing-right and positive Y drawing-up. Coordinates are approximate local feet, not GPS or surveyed positions.

Translation to first-floor PDF coordinates:

| Floor | PDF translation (points) | Projected origin in its PDF |
| --- | --- | --- |
| 1 | (0, 0) | (362, 139) |
| 2 | (-32, -16) | (394, 155) |
| 3 | (-12.5, +6.5) | (374.5, 132.5) |

Scale 1 and rotation 0 across floors. North stair landings and the two elevator shafts support these translations. Elevator doorway landmarks in the 2× source renders are (616,451)/(656,451), (679,480)/(723,480), and (640,437)/(684,437). Small manual/source residuals remain. The southern stair is a secondary landmark: its floor-2 landing retains about 5 feet of displacement relative to floor 1 after alignment. Preserve actual drawn landing geometry instead of forcing every transfer endpoint to coincide. Upper-floor origins are projections of the same floor-1 entrance, not upper-floor exits.

## Topology and access observations

- North and south stair cores and two separate elevator shafts connect floors 1–2 and 2–3. Elevator purposes and access restrictions are unspecified. No floor beyond the supplied three is inferred from stair UP/DN arrows or sheet counts.
- The separate west stair appears only on floors 1 and 2. Its second-floor approach is from the east corridor, above the women restroom; a direct line from the cross-corridor would pass through that restroom.
- First-floor west doors 130–134 open to exterior circulation beneath the shown canopy. The exterior route joins the north and south entrance passages. It does not imply a campus path.
- First-floor 131A is entered through 131; 132A through 132B; 133A through 133. 132B also links 132 and 116. Unnumbered storage opens from 132 and a small service closet opens from 116. Interior entrances between 133/116 and 134/118 are retained.
- East first-floor 101A–E are reached through 101. Room 105 has its own north entrance.
- Second-floor 214 is reached through 212. 224A, 230A, and 228A are reached through their respective parent rooms. Both entrances of 210 and 226 are retained. 201B has a lobby door and a door to 201.
- Third-floor west office groups use short corridor branches. 322A opens through 322. 340 connects to 346; the interior route bends below the 346A partition.
- Third-floor 303A and 303B label one open suite without a dividing wall. The interior bend passes east of 301B. 301B opens into that suite; 301A opens into 301.
- Small unnumbered service recess north of the third-floor men restroom has no confirmed door and is omitted. Dashed equipment is not treated as circulation.
- Only the first-floor AO entrance approach is marked accessible true. Stair movements are false; elevator and other accessibility remain unknown.
- Undirected edges are stored once with weight 1. The existing loader computes distances from rounded positions, including transfers. No vertical rise, effort, or elevator waiting cost is added.

## Validation

All three overlays were inspected and corrected against the source openings. Automated integrity, loader expansion, full-building reachability, real Dijkstra, floor/building-filtered snapping, parent-room access, shaft-range, attribute-preservation, and load-independence checks are in `tests/unit/tehamaGraph.test.ts`. Execution: all 61 tests in 12 files passed (including all 4 Tehama tests); lint, TypeScript, production build, coverage thresholds, infrastructure smoke check, and Docker Compose configuration passed. Coverage: 92.25% statements, 89.55% branches, 85.71% functions, 92.02% lines. Playwright completed with no E2E tests present. Targeted formatting of Tehama JSON/tests passed. Repository-wide formatting fails on the existing malformed expression in `.github/workflows/pr-checks.yml` and existing style issues in README, the Plumas renderer, graph.ts, main.tsx, and styles.css; unrelated files were not reformatted. `git diff --check` passed.

Current access permissions, elevator service, and accessibility certification cannot be established from these dated drawings.
