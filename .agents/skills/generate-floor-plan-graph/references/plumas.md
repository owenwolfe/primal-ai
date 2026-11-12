# Plumas Hall (`plumas`)

Sources: `csuc-floor-plans/Plumas/plms-1.pdf`, dated April 7, 2010, and `csuc-floor-plans/Plumas/plms-2.pdf`, dated July 18, 2006. Floors 1 and 2 digitized October 26, 2026. Floor 3 remains outside this batch.

Inventory: `src/data/plumas/floor-1.json` (113 nodes, 121 edges), `floor-2.json` (85 nodes, 91 edges), `connections.json` (three transfers), and explicitly requested `floor-1-preview.png` and `floor-2-preview.png`. The current glob loader discovers the JSON automatically. Previews are local review artifacts, not application imports or commit artifacts.

Both unrotated PDFs are 612 × 792 points. Printed scale is 1 inch = 30 feet, giving 30/72 feet per PDF point. Origin `plumas-1-exit-east-ao` is the floor 1 east AO entrance at native top-left PDF coordinates approximately (480, 496.2). Positive X is drawing-right; positive Y is drawing-up. No geographic calibration. Floor 1 uses the identity alignment transform.

## Floor 1

Manual rendering calibration: 5/3 pixels per PDF point. The inspection image was cropped from a Firefox screenshot at (290, 87); the resulting image maps native PDF coordinates to raster `(pdfX * 5/3, pdfY * 5/3 - 37)`. Preview is drawn from final serialized JSON by reversing its coordinate transform.

The central courtyard stair is an explicit inaccessible stair edge. West and east stair nodes represent access landings only. Initially no inter-floor edges were created; adjacent-floor transfers were added with floor 2. The dashed western courtyard line is not a walkway. The west stair is not a shortcut between room 112 and the main corridor.

Interior access: 112A/B/C/D through 112; 114A/B through 114; 116B through 116; 116A connects 114 and 116; 108 through 110; 100 through 102; 119D/E through the west passage within 119; 119 connects to 117 at the east door; 117B through 117A; 115A/B/D through 115. The small unnumbered space below 115C opens from 115C's east side, and is separated by a solid wall from the southern service lobby. Room 111 has both a west hall doorway and a doorway from 113; 111A opens from 111.

Only the east AO entrance edge is marked accessible. Other access permissions are unknown. The 102B/C southern labels are represented as doorway destinations without inventing enclosed room geometry. Manually digitized coordinates are approximate; the plan does not establish current access or survey precision.

Floor 1 validation: unique IDs, valid endpoints, no duplicate pairs or self-links, finite coordinates, correct building/floor, weight 1, no serialized distance, exact origin, and complete reachability passed. 242 directed links result from two-way expansion. Overlay inspected against source, correcting elevator-hall routing and 115C access.

## Floor 2 and alignment

Apply a native PDF translation of (-3.6, -1.2) points to floor 2 before applying the floor 1 origin. Scale 1, rotation 0. The projected reference origin on floor 2 is native (483.6, 497.4); this is not an upper-floor exit.

Landmarks: west landing floor 2 (151.8, 478.2) versus floor 1 (148.8, 477); east landing floor 2 (465.6, 478.2) versus floor 1 (461.4, 477). Translation balances their residuals, leaving -0.25 feet X at the west landing and +0.25 feet X at the east landing, with Y aligned. Elevator doorway differs by approximately (+1.75, -4.5) feet after this fit. The dated drawings have modest geometric differences; preserve the printed scale and doorway positions rather than claiming exact shaft agreement.

Floor 2 screenshot calibration differs from floor 1: native PDF maps to cropped raster `(pdfX * 5/3, pdfY * 5/3 + 13)`. Thus final graph coordinates map back to raster `(806 + 4*x, 842 - 4*y)`. The preview was generated from the final JSON and visually inspected.

Floor 2 access: 205A through 205; 201A through 201; 203A/C through 203; 203B through 203 and a secondary doorway from 205. 203C has an east doorway to 201, which also has two corridor entrances. 204 has north and south entrances and an internal door to 206. Restroom destinations use their actual inner doorways and retain the entrance bends. Two unnumbered rooms beside the shaft retain shown doors; the enclosed shaft has no invented entry. The dashed divider between 208 and 210 is not treated as an assured opening. The dashed first-floor outline is a reference boundary, not upper-floor circulation.

Transfers: `stairs-west`, `stairs-east`, and `elevator` connect corresponding nodes only between floors 1 and 2. Stair transfers are inaccessible; elevator access is unknown. Endpoint-derived distances are 0.25 feet for each stair link and approximately 4.828 feet for the elevator. These are plan-coordinate distances, not vertical walking distances. No overrides, stair effort, vertical rise, or elevator waiting costs are represented. Floor 3 must be inspected and aligned before adding transfers to it.

Combined validation: 198 unique nodes, 215 unique undirected edges, 430 expanded links; finite coordinates and weights, valid endpoints and types, no self-links or serialized distances, correct floor boundaries, adjacent matching transfers, and weighted paths from the floor 1 origin to every destination and back passed using a standalone validator. Floor 2 overlay checked, including restroom bends and interior routes in 201/205. `npm test` and `npm run build` were attempted but failed because `vitest` and `vite` are not installed in the empty local node_modules directory. The standalone validator does not replace tests of the real TypeScript loader/Dijkstra. No application code changed.


## Floor 3 — digitized October 26, 2026

Source `csuc-floor-plans/Plumas/plms-3.pdf`, dated November 8, 1999. Unrotated native page 612 × 792 points; printed scale 1 inch = 30 feet, same conversion 30/72 feet per PDF point. Deliverables `src/data/plumas/floor-3.json` and explicitly requested `floor-3-preview.png`: 82 nodes, 88 undirected edges, 176 expanded links. No loader change is required by the current glob import.

The floor 1 origin remains `plumas-1-exit-east-ao`, native (480,496.2). On the floor 3 source its projected location is (483.3,499.8). Translate floor 3 native PDF coordinates by (-3.3,-3.6) points into the reference frame; no rotation or rescaling. Positive X drawing-right and Y drawing-up. Inspection raster is 5/3 pixels per point with offset (0,+43), after cropping the Firefox screenshot at (290,87). Coordinates are rounded to two decimals in feet.

Corresponding west/east stair access landings are raster (248,844)/(780,844) on floor 3, versus (248,758)/(769,758) on floor 1. The chosen translation splits their X mismatch: residuals -1.38/+1.37 feet, Y 0. The elevator access doorway differs by about 7.64 feet; first-floor and third-floor doors lie on different sides of the shaft, so doorway positions are not exact shaft-center landmarks. This is approximate alignment between differently dated plans. Do not infer surveyed accuracy or force door nodes onto an identical point.

Room access: 317A/B through 317; 321 has a north doorway through 317 and an east doorway from the west passage. Its north approach must bend inside 321 to avoid the wall of 319. 315 has two main-corridor doors. 312 has main-corridor and north-passage doors. 309 opens through 309A. 303 connects the main hall to the northern passage, which serves 302/305/307/308/309A/310/311 and the east door of 312. 306 and 304 open from the main corridor. 325 opens from the west passage; 325A and 327 open through 325. The path from 325 to 329 must stay north of enclosed room 327. 329 also has a main-hall entrance. Custodial 323 opens off the west passage. 301A opens from 301. 333A/B open from 333; 333C opens from 333B and passage 335; 333D opens from passage 335. The unnumbered doorway beside the women restroom is retained, but no access into the enclosed shaft is invented.

West/east stair and elevator access nodes are retained. Floor 2 is currently absent from `src/data/plumas`, so no connections file or floor-1-to-floor-3 shortcut was created. Connect adjacent floors when floor 2 is available. An UP annotation on the west stair does not justify inventing another floor dataset. No accessibility claims were added; omitted edge attributes remain unknown.

Validation: source overlay generated from final saved JSON and inspected, including corrections to 312, 321, and the route around 327. Unique IDs, finite coordinates, valid floor/building fields and edge kinds, existing endpoints, no self-links or duplicate undirected pairs, no serialized distance, weight 1, and full within-floor reachability passed. All 82 nodes reachable from the west stair. Infrastructure smoke and Docker Compose configuration passed. Format, lint, typecheck, unit/coverage, and E2E commands could not execute because dependencies are absent from local node_modules. No application or loader behavior was changed.
