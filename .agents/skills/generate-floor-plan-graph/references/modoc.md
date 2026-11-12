# Modoc Hall (`modoc`)

## Sources and inventory

Display name: Modoc Hall. The runtime building ID is `modoc`; source filenames use the abbreviation `modc`.

- `csuc-floor-plans/Modoc/modc-1.pdf`: first floor, dated September 15, 2009, sheet 2 of 3.
- `csuc-floor-plans/Modoc/modc-2.pdf`: second floor, dated July 15, 2008, sheet 3 of 3.
- Each PDF has one 612 × 792 point page, rotation 0. Both print `1 inch = 30 feet`. Labels are vector outlines; ordinary text extraction is empty.
- `src/data/modoc/floor-1.json`: 133 nodes, 138 within-floor edges, including the shown yard circulation.
- `src/data/modoc/floor-2.json`: 119 nodes, 125 within-floor edges.
- `src/data/modoc/connections.json`: four adjacent-floor links: north, southwest, and southeast stairs, and the elevator.
- Requested `floor-1-preview.png` and `floor-2-preview.png` are inverse-transform source overlays generated from the saved JSON. These are local review aids, not application imports or commit artifacts.

## Coordinates and alignment

Units are feet, with `feetPerPdfPoint = 30 / 72`. Digitization used 2 pixels per native PDF point; raster coordinates therefore use `30 / 144` feet per pixel. Positive X is drawing-right; positive Y is drawing-up, without geographic alignment.

The origin is `modoc-1-exit-southwest-ao`, the AO-marked southwest lobby exterior doorway, at first-floor native PDF point `(192, 521.5)` from the top left, or raster `(384,1043)`. First-floor conversion is `x = (pdfX - 192) * 30 / 72`, `y = (521.5 - pdfY) * 30 / 72`.

The upper drawing is approximately 3 native PDF points left and 3 points down relative to floor 1. Apply `(pdfX + 3, pdfY - 3)` before the reference-floor conversion. Its projected origin is native PDF `(189,524.5)`. Fixed outlines agree at the elevator, north stair, southwest stair, and southeast stair. Example source raster corners: first-floor elevator outer west line X=475 and upper-floor X=469; north stair upper boundary Y=183 versus Y=189. No rotation or rescaling is applied. Distinct landing access points remain distinct, and approximate doorway picks can leave a small residual elevator separation.

## Topology and room access

- The north, southwest, and southeast stair cores connect floors 1–2. The elevator is a separate chain. Distances are coordinate-derived plan-view distances, omitting vertical effort and waiting. Stair transfers are inaccessible; elevator availability and other accessibility remain unknown.
- The first-floor east exterior stair is labelled DN and appears only on that sheet. It is represented as a local stair segment from the yard gate landing to the shown lower approach and east doorway. This is a plan-view interpretation of the supplied geometry, not evidence for a basement or another floor. There is no invented inter-floor transfer at this stair.
- First-floor 120A is reached through 120, below the north stair; no edge crosses its treads. Room 129A has a west entrance vestibule with a narrow wall requiring a northward bend, and an east door to the suite passage. Room 129C opens into that narrow passage. The suite restroom opens from 129. Room 129B has internal north/south doors to 131/129; neither is a yard exit. Actual east yard doors are shown from 131, 129, and 125.
- Room 127A opens from 127. The 125A vestibule opens from the hall and connects to 125A and the north door of 125. Room 125B has a hall door and opens into 125 and 125C. Room 125 also has its yard door. Unnumbered service spaces and both custodial rooms at the south lobby are retained by spatial name.
- Second-floor 224A opens through 224. Room 223B is accessed through 223A, which opens into 223. Room 223C has west-hall and east-suite openings. Rooms 221A–D open onto the narrow cross passage north of 221, not through 221.
- The 219 suite has a west entry to its internal passage and a second connection from 217 through 219B. The upper approach to 219B bends around its west partition. Room 217A opens from 217; 217B has its own west-hall doorway.
- Rooms 216A/B/C open from 216. Room 214 has doors to 216 and the south lobby. The 215 suite is entered from the small corridor pocket north of the main cross corridor. Room 215C opens through 215A; 215A/B open into 215. Room 213 has a west corridor door and a north connection to 215. Room 211 connects to 213 and 209 internally as well as to the corridor. Room 212 also connects internally to 210.

## Yard scope and uncertainty

The first-floor drawing supplies a fenced playground, covered play area, storage rooms 1–4, and a sandbox outline. Routes use only shown gates, the open covered area, and clear perimeter circulation. They avoid the sandbox's rectangular base and its northern projection. The north gate approach stays west of Storage 2 until below its south wall. Storage access does not establish current permission to enter these spaces. No campus path or neighboring building is inferred.

Only the AO southwest entrance and source-wheelchair-marked north and southeast exterior entrance approaches are true for accessibility. Other values are omitted, and stair edges are false. Symbols do not establish a complete accessible route or current compliance.

The two sheets differ in date, and neither establishes current access or surveyed accuracy. The missing sheet 1 is not treated as an extra floor. Coordinates and doorway locations are approximate manual picks, rounded to two decimal feet.

## Validation

Inspected both native PDF renderings, detailed room/landing crops, and overlays generated by reversing the final JSON transform. Corrections include 129B internal doors versus yard exits, the 129A vestibule wall, 225's southern opening, 219B's partition, the southwest vending recess, and sandbox avoidance.

`tests/unit/modocGraph.test.ts` validates unique IDs and pairs, finite coordinates, exact origin and scale, floor-local edges, endpoint existence and allowed types, absence of serialized distances, loaded two-way coordinate distances and attributes, four corresponding adjacent-floor transfers, independent loads, parent-room access, floor-filtered nearest candidates, and real Dijkstra reachability from the origin to all nodes and back. All mapped nodes belong to one connected building component after transfers. No GPS calibration, present access guarantee, or accessibility certification is claimed.
