# Glenn Hall (`glenn`)

Glenn Hall, building 6. Runtime ID `glenn`; no prior Glenn data existed when digitized.

## Sources and files

- `csuc-floor-plans/Glenn/glenn-1.pdf`: floor 1, sheet 1 of 4, title-block and PDF date September 15, 2009.
- `csuc-floor-plans/Glenn/glenn-2.pdf`: floor 2, sheet 2 of 4, July 14, 2008.
- `csuc-floor-plans/Glenn/glenn-3.pdf`: floor 3, sheet 3 of 4, July 14, 2008.
- These are all supplied Glenn floor PDFs. No fourth floor is established by the sheet count or the UP arrows on floor 3.
- All native pages 612 × 792 standard PDF points, rotation 0, printed scale 1 inch = 30 feet. Text is vector outlined; empty text extraction does not imply absent labels.
- Digitized October 27, 2026. Floor 1: 82 nodes/79 edges; floor 2: 83 nodes/85 edges; floor 3: 64 nodes/67 edges. Eight inter-floor edges. Total 229 nodes/239 edges, expanding to 478 directed links.
- Runtime data: `src/data/glenn/floor-1.json` through `floor-3.json`, plus `connections.json`, discovered automatically by the current loader. Explicitly requested `floor-1-preview.png` through `floor-3-preview.png` are local review artifacts, not app imports or commit artifacts.

## Coordinates and alignment

Units feet, 30/72 feet/PDF point. Origin `glenn-1-entrance-north`: wheelchair-marked exterior entrance at north end of the main hall, native top-left PDF coordinate (319,66.5). Positive X drawing-right; Y drawing-up, not geographic north.

Floor 1 source-to-reference translation (0,0). Floor 2 (−4.5,−0.5) PDF points; floor 3 (−0.5,−5) PDF points. Transform first, then x = (referencePdfX − 319) × 30/72, y = (66.5 − referencePdfY) × 30/72. Projected origins on source floors 2/3 are (323.5,67)/(319.5,71.5), respectively. No independent origin or implied upper-floor entrance.

Landmarks: north structural wall around (238.5,70.5) on floor 1, (243,71) on floor 2, (239,75.5) on floor 3; south facade around y=658.5/659/663.5. Elevator shaft/doorway agrees with those translations within raster/manual precision. Doorway centers floor 1 (309.5,317.5), floor 2 (314,318), floor 3 (310,322.5) align exactly after rounding. Opposite shafts/stair cores provide additional orientation checks. Same printed scale and orientation; no rotation/scaling inferred. Coordinates rounded to 0.01 feet are manual estimates.

Previews reverse saved JSON coordinates into their own source PDF coordinates. Render at 3 px/PDF point, overlay teal corridors, orange door edges, purple stair approaches; red doorway/junction dots, blue transfer dots, and a red origin ring. Upper origin rings are projected positions, not physical exits. Source renders and working generators stayed in `/tmp`.

## Room and circulation topology

The central linear hall serves all three floors. Main hall nodes exist only for doorway/transfer branches and necessary bends; no grid or arbitrary furniture nodes.

Floor 1:

- 101/103/105–125 are doorway destinations on the east side. 121A via 121. 123 and 125 retain shown alternate hall doors. 102 has a direct west hall door.
- 104 is reached through its labelled entry vestibule; 104A via 104. An interior bend avoids tracing along the solid partition between their doors.
- West wheelchair-marked entrance opens into a cross hall next to an unnumbered closet and elevator. Middle east entrance also wheelchair marked.
- 106 has a hall entrance; 106B via 106 plus its own west exterior entrance.
- 108 leads to 108A, 108B, 108C and its custodian closet; 108D and an unnumbered northern closet via 108A. The unnumbered closet is separated from 106 by a solid wall: no shortcut through it. 108C's west exterior opening is retained, without extending a campus path.
- Men's room from hall; women's room through the 110 vestibule. 110C and 110B via the west bend of 110; 110A via 110B. This bend stays south/west of the women's enclosure.
- Two unnumbered north-facade doorways have no internal hall opening or depicted exterior walkway. They are isolated doorway nodes rather than invented connected rooms.

Floor 2:

- 204 office suite has north and south common entrances plus 204K's own hall door. The internal common route follows the left side of the central office block and its upper/lower cross passages. 204G/F/E/D/A, 204i/K/H/J/C/B enter from this common circulation; lower-case `i` preserves the drawing's label.
- 206A has its own hall opening above the elevator. 206B is entered through the south partition of 206. No diagonal shortcut from 206A through the 206B side wall.
- 210 has a hall door immediately north of its crossed service box. 212, 214 and 216 occupy the west side of the south wing; 212/214 retain both visible openings. 223 has only its lower hall door: the west wall opposite 212's south entrance is solid.
- 217/219 have their shown internal connecting door; 219 retains two hall openings. 221 and 225 from hall. No destination is invented for the crossed service box.
- Men's/women's restrooms, custodian and electrical closet retain their west approaches.

Floor 3:

- 302/304/306/308/310/312/314/316 occupy west rooms; other numbered rooms east. 306 retains its south vestibule opening next to the elevator.
- 321 has north/south hall doors and a door into the northern part of 323. An interior bend connects these doors without following a solid wall. 323A via 323. 323/325 share an open/dotted partition, not a solid wall. 325A is entered from this shared main studio; 325B has west and north doors, the north door connecting through 325A. No direct link through 325B's solid west upper wall.

## Inter-floor topology and limitations

Three distinct stair chains (north, middle, south) and one elevator, floors 1–2 and 2–3 only. Floor 2 has separate UP and DN landing nodes and local approaches. In particular, the south UP flight must approach via the lower landing opening and around the enclosure wall; a direct hall-to-UP diagonal would cross a wall and is excluded.

All edges undirected with weight 1; no serialized distance override. Current loader derives runtime distances from X/Y, including transfers; aligned elevator transfers have zero distance, and stair transfers include only plan-view landing separation. Floor height, waiting time and stair effort are not modeled. Stair edges explicitly inaccessible; only source-marked wheelchair/AO entrance edges accessible=true; remaining access unknown. Dated plans do not establish current elevator operation, door permissions, surveyed accuracy or GPS alignment.

Validation: unique IDs, finite coordinates, exact origin, valid edge kinds/weights/endpoints, no self-links or duplicate undirected pairs, no stored distance, and floor/connection separation checked. Expected components: 227-node three-floor main component and two isolated north doorway nodes. Tests exercise actual loader/Dijkstra reachability, parent-room access, stair enclosure constraint, adjacent transfers, floor-filtered snapping and independent loads. Source overlays were reviewed and wall-crossing candidates corrected before delivery.
