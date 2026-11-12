# Butte Hall (`butte`)

Digitized 2026-10-27 from all five supplied source PDFs. Alias: Butte.

| Floor | Source | Printed date | Nodes | Within-floor edges |
| --- | --- | --- | --- | --- |
| 1 | `csuc-floor-plans/Butte/bute-1.pdf` | 4/7/10 | 69 | 70 |
| 2 | `csuc-floor-plans/Butte/bute-2.pdf` | 1/22/03 | 45 | 45 |
| 3 | `csuc-floor-plans/Butte/bute-3.pdf` | 8/4/08 | 54 | 57 |
| 4 | `csuc-floor-plans/Butte/bute-4.pdf` | 8/4/08 | 86 | 97 |
| 5 | `csuc-floor-plans/Butte/bute-5.pdf` | 9/16/09 | 92 | 100 |

Runtime files: `src/data/butte/floor-1.json` through `floor-5.json` and `connections.json`. The requested `floor-1-preview.png` through `floor-5-preview.png` are overlays generated from saved JSON onto the corresponding PDFs, not application imports or commit artifacts. Tests: `tests/unit/butteGraph.test.ts`. No loader changes are required because its eager glob discovers these files.

All PDFs have one 612 × 792-point page, rotation 0. Printed scale on every sheet is **1 inch = 20 feet**, yielding 20/72 feet per native PDF point. PDF creation dates are 2010-04-07, 2005-07-20, 2008-08-04, 2008-08-04 and 2009-09-16; these are not substituted for the printed source dates. Text extraction is empty because the labels are vector outlines. Manual tracing used exact 2 pixels/PDF-point renderings and 4x detail crops.

## Origin and floor alignment

Origin **`butte-1-exit-north-east-ao`**, the northeast AO-marked entrance beside the northern first-floor stair, is at native top-left PDF **(291, 135)**. Its graph coordinate is exactly (0, 0). Axes are positive drawing-right and drawing-up, without geographic calibration. Coordinates are feet, rounded to two decimals.

The following translations map each sheet to floor-1 PDF space, with scale 1 and rotation 0:

| Floor | PDF translation X | PDF translation Y | Projected reference origin |
| --- | --- | --- | --- |
| 1 | 0 | 0 | (291, 135) |
| 2 | -54 | +1 | (345, 134) |
| 3 | -35 | 0 | (326, 135) |
| 4 | -39 | +1 | (330, 134) |
| 5 | -43 | -3 | (334, 138) |

Evidence in the exact 2x raster: west/east facades are X 202/809 on floor 1, 310/917 on floor 2, 272/879 on floor 3, 280/887 on floor 4 and 288/895 on floor 5. Central crossed shaft X ranges are 462–552, 570–660, 532–622, 541–631 and 548–638 respectively; its top edge is Y 758, 755, 758, 755 and 763. Upper elevator/stair-core positions support the same translations, mostly within 0.5 feet. The shaft bottom changes on floors 4/5 with the restroom arrangement. Northern stairs differ substantially and were not alignment anchors. These are manual architectural alignments, not survey measurements.

## Transfers and unresolved source details

`connections.json` stores **16 undirected adjacent-floor transfers**:

- West stair and southeast stair: floors 1→2→3→4→5 (eight links).
- Aggregate elevator bank: floors 1→2→3→4→5 (four links).
- Northern west/east flight correspondence: floors 1→2→3 only (four links).

No northern stair is present on floors 4 or 5. Do not extend the floor-3 chains into the fourth-floor 401 suite. On floor 1, northern flights start from the shown exterior north approach; the solid south stair wall is not treated as a lobby doorway. Floor 2 has two separate north stair entrances. Floor 3 uses the shared central opening for both northern flight access endpoints, rather than cutting through the enclosing walls. **The west/east correspondence is an explicit schematic assumption:** footprints do not coincide, and exact individual landing geometry is unresolved.

The first-floor west stair starts from its west side: its route bends around the south of the flight, instead of going through the steps from the east entrance. Upper west and southeast access nodes sit at the hallway-side landings. The four-node floor-1 southeast vestibule (`exit-southeast-stairs`, `southeast-landing`, `custodian-southeast`, `stairs-southeast`) is a separate local component because 130 and the 150 annex enclose it. It connects to the building through floor-2 stairs; no nonexistent door through 130 or unshown exterior circuit is added.

A small stair in the first-floor upper east service vestibule is retained as `stairs-east-service-unresolved`. Its corresponding upper landing is not identifiable, so no vertical transfer is fabricated.

The source labels the elevator bank collectively and does not delineate individual cars or identify passenger/service shafts. A single representative bank access is retained on each floor: west side on floors 1/5, east side on floors 2–4. Individual car identity and exact sliding-door interpretation on the dashed west facade remain uncertain; the bank is not split into invented shaft chains. Access side changes and sheet discrepancies therefore contribute to the coordinate-derived transfer distance. No height, effort or waiting-time override is used. Stair traversal is false for accessibility; elevator access and current operation are unknown. AO-marked entrance edges only are explicitly true.

## Doorway relationships

Floor 1 retains both room-side exterior doors of 101–104, both north entrances, west stair entrances, south AO entrance, upper east service vestibule, 130 and the 150 annex doors. The central custodian room has a service-vestibule door and a door from 130. Restroom entry bends preserve the short screened approaches. The immediate south exterior approach to 150 bends below the men's-room wall. No campus routing is inferred.

Floor 2 uses two side corridors around the core, joined above and below it. Small 202, the custodian closet and both restrooms use their visible openings. Classroom vestibules retain their notches.

Floor 3: 303A is reached through 303. The west doors in the 301/303 and 303/305 boundaries are internal room connections, not facade exits. 311A/B open through 311; a secondary door connects 313 and 315.

Floor 4: 401C wraps around a wall projection, so its west circulation bends above the projection. 401A has doors from 401 and 401C. An unnumbered northeast room connects 401/401C and 401F, with a lower opening to 423A. 423A also opens from 423 and to 421. 421A–E open from 421; the internal route stays east of the inset 421D/E closets. 419A/B are through 419; 417A–C through 417. 407E/B/C use 407, with additional B/C and C/A doors and 407D off A. The 409A/B approach stays west of the 409A top wall. 424 retains both top entrances. Unnumbered destinations receive spatial names rather than invented numbers.

Floor 5: 501A–E open from 501. 503 and 501 also connect through their north-side doorway. 543A–D use 543, reached from the north end of the east corridor. All odd numbered rooms 501–543 and even rooms 502/504/506/508/512/518 are retained. 509A/B have doors from both 507 and 509. 511A/B/C open from 511, which also has a door from 509. Core-side 518/512/508/504/506 use the east corridor or north/south circulation, without routing across the elevator bank.

## Validation

Total: **346 nodes / 385 undirected edges**, including 16 transfers; the loader expands these to **770 directed links**. Structural checks verified unique IDs, finite coordinates, exact origin, endpoint existence, edge kinds, weight 1, no duplicate pairs/self-links/serialized distances, and floor-local edges. Within-floor components are [65, 4], [45], [54], [86], [92]; all nodes are reachable from the origin when supported transfers are included. Final JSON overlays were visually inspected and regenerated after wall-crossing corrections. Redundant collinear degree-two corridor points were removed.

The test suite exercises loaded forward/reverse distances and attributes, real Dijkstra paths, floor-aware start candidates, the separate first-floor southeast component, transfer floor ranges, parent-room relationships and fifth-floor room coverage.

Remaining limits: dated/manual geometry; schematic north flight correspondence; aggregate elevator access and unknown individual car assignments; unresolved small east service stair; current partitions, access permissions and accessible-route suitability unknown. No GPS or survey accuracy is claimed.

Checks completed 2026-10-27 with the existing Docker Compose Node 22 toolchain: all 57 unit tests passed, including four new Butte tests. Typecheck, lint, production build, coverage, infrastructure smoke checks and Compose configuration passed. E2E found no tests. Butte JSON and tests are formatted. Repository-wide formatting still reports the pre-existing malformed workflow expression in `.github/workflows/pr-checks.yml`, plus README and unrelated source/script formatting issues. The O’Connell floor-inventory assertion was scoped to O’Connell so adding Butte floor 5 does not invalidate a test about O’Connell’s four floors.
