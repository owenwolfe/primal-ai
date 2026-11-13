# Holt Hall (holt)

Display name: Holt Hall; alias Holt. The stable dataset ID is `holt`, matching
the supplied HOLT drawing names. Digitized from the local PDFs in October 2026.

## Sources and coordinates

| Floor | Exact source | Printed date | Dataset |
| --- | --- | --- | --- |
| 1 | `csuc-floor-plans/Holt/holt-1.pdf` | 2011-02-17 | `src/data/holt/floor-1.json` |
| 2 | `csuc-floor-plans/Holt/holt-2.pdf` | 2008-07-24 | `src/data/holt/floor-2.json` |
| 3 | `csuc-floor-plans/Holt/holt-3.pdf` | 2009-09-15 | `src/data/holt/floor-3.json` |

All three pages are 612 × 792 PDF points, rotation 0, and print 1 inch = 40 feet.
Text is vector outlines, so text extraction is empty; rendered drawings were
visually inspected at full-floor and enlarged crop scales.

The common origin is `holt-1-exit-south-ao`, the AO-marked doorway at the
drawing-bottom east stair lobby: native top-left PDF point (355, 682).
Coordinates are feet: x = (pdfX - 355) × 40/72 and
y = (682 - pdfY) × 40/72. Positive x is drawing-right, positive y drawing-up;
these are not geographic axes. Inspection used a 2× raster reference, so
x = (pixelX - 710)/3.6 and y = (1364 - pixelY)/3.6.

Upper floors use the same origin projected into their pages and an identity
transform (scale 1, rotation 0, translation 0). Matching landmarks include the
north stair shaft upper-left at approximately (317, 73), south stair shaft at
(317, 632), and elevator shaft at (231, 273), in native PDF points.
The outlines and shafts agree across the three sheets; no GPS calibration or
survey accuracy is claimed. Coordinates are rounded to two decimals.

## Topology and access

Rooms are doorway destinations, with separate nodes for additional doors.
Corridor bends and room-interior bends avoid walls and courtyard voids.
Connections are undirected and serialized once, with weight 1 and no stored
distance. The loader discovers the files automatically.

Four stair cores (`stairs-north`, `stairs-middle-north`,
`stairs-middle-south`, `stairs-south`) and one `elevator` connect
adjacent floors in `connections.json`. The elevator opening is at the top
of its drawn shaft, reached from the north bridge, not through rooms 161,
255 or 333. First-floor west descending stairs and the auditorium east stair
are not extended to upper floors. UP on the middle third-floor stairs does
not establish a fourth-floor graph without a source sheet.

Aligned transfer endpoints can have zero coordinate-derived distance.
No floor heights, elevator waiting times or stair-effort costs are supplied;
no artificial offset or distance override is invented. Stair traversal is
marked inaccessible. Other accessibility is unknown except the two
source-marked AO entrance edges on floor 1. Current access permissions,
door locking and elevator operation are unknown.

Interior access examples:

- Floor 1: 157A through 157; 165A and 135 through 165; 101 subrooms through
  the 101 suite; 171A through 171; the open court through 118.
- Floor 2: 251A through 253/251; 243 through 245; 237C through 237B;
  285D and 287 through the north office suite; 227A through 227.
- Floor 3: 329A/B/D/E through 329; 329C also opens to 331; 325F/G through
  the southern 325 suite; 307A through 303; the 301 and 347 suites retain
  their actual interior branches.

Suffix-only B/C/D and A labels are associated with their visibly enclosing
parent suite where unambiguous. The letter in 301I is capital I.

## Uncertainties and review

The floor-1 auditorium says SEE SHEET 1, but the supplied files are sheets
2–4. Room 170's lower doorway and western descending access are retained;
no speculative path is drawn through seating or the stage. Room 172 is
inside the auditorium boundary and is omitted because its internal access
cannot be completed confidently without the referenced detail.

The two first-floor bridge stair runs span the passage wall-to-wall. A
high-resolution follow-up review rejected direct west-to-east corridor edges
through those flights. The north east landing remains reachable via the
auditorium east stair. The south east landing and its exterior doorway
(`holt-1-south-bridge-east`, `holt-1-exit-east-south`) remain a separate
two-node component: the supplied plan does not resolve the transfer landing
correspondence, and no same-floor bypass or outdoor connection is invented.

The folding partition between 129 and 129B is not treated as an open
through-route. Dashed/open-ended partitions in 253, 301 and 325 require
interpretation of open circulation; their exact furniture-level paths are
not survey measurements. No neighboring buildings or campus paths are added.

Temporary overlays were generated from saved JSON by reversing the coordinate
transform onto the source renderings, inspected, corrected and regenerated.
An independent review inspected all nine north/middle/south overlay crops;
the dashed partitions around 325A/C and 251 remain an explicitly approximate
part of the digitization. At the user's October 2026 request,
`src/data/holt/floor-2-preview.png` was generated from the saved floor-2 JSON
as the official floor-2 preview. It is a local review aid, not an application
import.

## Application integration

Both buildings use local coordinates and have an origin at (0, 0). The
instruction adapter therefore requires a final `buildingId` argument:
`getReadableInstructions(startX, startY, startFloor, endX, endY, endFloor, buildingId)`.
Its only repository consumers were tests, which now pass `ocon` or `holt`.
It filters candidates by building before the existing floor-aware nearest-node
lookup. Dijkstra and the graph loader are unchanged. There is no route between
Holt and O'Connell without future explicitly aligned outdoor links.

## Validation

Holt-specific tests check finite unique coordinates, shared origin, local
edges and allowed kinds, absence of serialized distances, no duplicate pairs
or self-links, two-way attribute preservation, adjacent-floor transfers,
building/floor-aware snapping, and Dijkstra reachability to every interior
destination and back. The unresolved exterior landing is tested as a separate
component, including its local exit link and absence of either bridge shortcut.
Existing loader tests now count all bundled data while
testing O'Connell reachability within its own component.

Final inventory:

| File | Nodes | Undirected edges |
| --- | ---: | ---: |
| floor-1.json | 183 | 193 |
| floor-2.json | 183 | 191 |
| floor-3.json | 212 | 222 |
| connections.json | 0 | 10 |
| Total | 578 | 616 |

576 nodes are reachable from the origin; the documented two-node south east
exit landing is separate. All 616 edges expand to 1,232 directed Holt entries.

Validation ran in the existing Node 22.14.0 development container because the
host uses Node 26 and its dependency mount is not writable:

- `npm test`: 35 tests passed, including the new building-selection regression
  and all Holt graph checks.
- `npm run lint`, `npm run typecheck`, `npm run coverage`,
  `npm run test:smoke`, `npm run build`, and `docker compose config`: passed.
- Coverage: 92.25% statements, 92.02% lines, 89.55% branches, 85.71% functions.
  The current configuration declares no numeric threshold.
- `npm run test:e2e`: exited successfully with no tests present; not browser
  user-flow coverage.
- Changed-file Prettier check and `git diff --check`: passed.
- Repository-wide `npm run format:check`: failed on the existing malformed
  workflow expression at `.github/workflows/pr-checks.yml:34`, plus existing
  formatting in `src/lib/graph.ts`, `src/main.tsx`, and `src/styles.css`.
  Those unrelated files were not changed.

Remaining evidence needed: the referenced auditorium detail sheet, confirmed
east-facing south stair landing correspondence, and current site access data.
No further floors were supplied; no additional digitization batch is pending.
