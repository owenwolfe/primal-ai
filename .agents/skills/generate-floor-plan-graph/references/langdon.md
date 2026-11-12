# Langdon Hall (`langdon`)

Digitized 2026-10-27. Alias: Langdon. The two source PDFs contain **three floors**:

- `csuc-floor-plans/Langdon/lang-1.pdf`: first floor; sheet 2 of 3.
- `csuc-floor-plans/Langdon/lang-2.pdf`: second floor in the lower drawing and third floor in the upper drawing; sheet 3 of 3.
- Both drawings print 9/2/10. PDF metadata creation dates are 2010-09-07 and 2010-09-02 respectively. Labels are vector outlines and text extraction is empty.

## Files and units

`src/data/langdon/floor-1.json`, `floor-2.json`, `floor-3.json`, and `connections.json`. Requested review artifacts: `floor-1-preview.png`, `floor-2-preview.png`, `floor-3-preview.png`. Upper previews retain the full source sheet and overlay only their corresponding floor. Previews are local review aids, not application imports or commit artifacts.

All pages are 612 × 792 PDF points, rotation 0. Printed scale is 1 inch = 30 feet; conversion is 30/72 feet per PDF point. Manual points were traced on exact 2 pixels/PDF-point renders with 4x detail inspection. Coordinates are rounded to two decimals in feet. Positive X is drawing-right, positive Y drawing-up, without geographic calibration.

## Origin and alignment

Origin `langdon-1-exit-north-wing` is the double exterior doorway at the south end of the first-floor north wing opening onto the south gallery: native top-left PDF coordinate **(216.5, 508.5)**. It is exactly (0, 0) in the graph. This reference doorway has no upper-floor counterpart.

Transforms from each upper drawing to floor-1 PDF space preserve scale and orientation:

| Floor | PDF translation X | PDF translation Y | Projected reference origin |
| --- | --- | --- | --- |
| 1 | 0 | 0 | (216.5, 508.5) |
| 2 | +1.5 | +171.5 | (215, 337) |
| 3 | +1.5 | +394 | (215, 114.5) |

Evidence: west facade/column line at raster X 95 on floor 1 versus 92 upstairs; central crossed-out shaft X 283–359 versus 280–357; main gallery south wall raster Y 1076 versus 733 on floor 2 and 288 on floor 3; exterior south wall Y 1278 versus 934/489. East facade residual is about 0.6 ft and south-wall residual about 0.2 ft. The west elevator enclosure differs slightly, so its actual doorway offset is retained. Landings and elevator points need not coincide exactly. Manual alignment is not surveyed accuracy.

## Topology

Two end stair cores and one elevator link floors 1→2 and 2→3: six undirected transfers. West landing uses the north end of the west flight; east landing uses the west opening beside the east flight. There are no straight shortcuts across either stair flight. The crossed-out rectangle beside the elevator is excluded. Vertical costs use endpoint horizontal coordinates under the current loader; no height or waiting-time override is serialized. Stairs are inaccessible; no accessibility/availability claim is made for the elevator.

The north wing exists only on floor 1. Main south gallery circulation follows the shown open strip. A short outdoor approach links the shown loading dock to that gallery; 115 has only its dock doorway. No campus routes or O'Connell connections are inferred from proximity.

Floor 1: 121A is through 121; 122A/B through 122. 119A/B are through 119, with another 119B door from 118. 118A is through 118, 118B and the adjacent custodian closet use the main spine. 117A is through 117. Both shown 120 doors and the 117↔116 door are retained. 114 suffix destinations use the west vestibule/114 circulation. South classroom 107/106/105 entrances are separate. 101 and 100 retain secondary access, and 100A/B open from 100.

Floor 2: 203 has a gallery entrance plus a west door from 204; 203A has openings from 203, 204 and 200. 200 has two gallery doors. 205A is through 205. 207D and 207A are through 207; 207B has its 207 door plus the west door at the end of the service corridor. 206 has both gallery and south doors. 209A/F/G/H/J use the west service circulation. Three distinct unnumbered storage doorways are spatially named.

Floor 3: 303A is through 303. Secondary south doors connect 303↔302↔300. Mechanical/electrical/custodian/telecom and storage destinations reflect drawn openings without asserting public access. West service circulation includes required bends around storage and restroom walls.

## Validation and limits

Saved graph inventory: floor 1 **91 nodes / 95 edges**; floor 2 **60 / 64**; floor 3 **43 / 44**; connections **6 edges**. Total **194 nodes / 209 undirected edges**, yielding 418 directed loaded links.

Structural validation checked unique IDs, finite positions, exact origin, existing endpoints, no duplicate pairs/self-links/serialized distances, weight 1, and floor-local edges. Each floor is individually connected; the entire building is reachable from the origin. Source overlays were regenerated from saved JSON and inspected for door placement and wall crossings. `tests/unit/langdonGraph.test.ts` checks real-loader distances, reverse edges, independent floor reachability, real Dijkstra routes, floor-filtered snapping, transfers, and parent-room relationships.

Geometry is manually digitized from dated plans. Current partitions, access permissions, stair effort, elevator operation and accessible routes remain unknown. No unshown opening is intentionally inferred; small doorway positions are approximate, not a survey. No further floor is present in the supplied PDFs.

Verification completed 2026-10-27 using the existing Docker Compose Node 22 toolchain: all 46 unit tests passed (including four Langdon tests); typecheck, lint, production build, coverage (92.25% statements), infrastructure smoke checks and Compose configuration passed. E2E found no tests. Repository formatting is blocked by the pre-existing malformed `if` expression in `.github/workflows/pr-checks.yml` and existing formatting issues in `scripts/render-plumas-preview.mjs`, `src/lib/graph.ts`, `src/main.tsx` and `src/styles.css`. Langdon JSON and test files were formatted successfully.
