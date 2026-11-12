# Ayres Hall (`ayres`)

Aliases: Ayres, Ayres Hall; user spelling “Ayers”. Building number 4. No prior runtime building ID existed when added.

## Sources and inventory

- `csuc-floor-plans/Ayres/ayrs-1.pdf`: floor 1, sheet 2 of 3.
- `csuc-floor-plans/Ayres/ayrs-2.pdf`: floor 2, sheet 3 of 3.
- Both title blocks dated July 14, 2008; PDF creation/modification dates agree. Digitized October 27, 2026.
- Both pages: 612 × 792 standard PDF points, rotation 0, printed scale 1 inch = 30 feet. Labels are vector outlines; empty text extraction is expected.
- `src/data/ayres/floor-1.json`: 134 nodes, 134 edges.
- `src/data/ayres/floor-2.json`: 54 nodes, 53 edges.
- `src/data/ayres/connections.json`: 3 adjacent-floor transfers.
- Explicitly requested `floor-1-preview.png` and `floor-2-preview.png` beside the JSON. Local verification aids, not application imports or commit artifacts.

## Coordinates and alignment

Units feet; 30/72 feet per PDF point. Reference origin `ayres-1-entrance-northwest` is the exterior AO-marked door north of the west hall, at native top-left PDF coordinate (161.5, 70.5). X drawing-right, Y drawing-up, unrelated to geographic north.

Floor 1: x = (pdfX − 161.5) × 30/72; y = (70.5 − pdfY) × 30/72. Floor 2 is translated (−29.5, +1) PDF points into floor-1 source space before applying this transform. Projected upper-floor origin is (191, 69.5); it is not an upper-floor entrance. No rotation or scale change.

Landmarks: elevator shaft floor-2 outline is 29.5 PDF points right of floor 1; south facade is approximately 1 point higher. Northwest stair and southeast stair agree with this shift within manual tracing/landing differences. Floor-2 elevator doorway lands at (209,420), floor 1 at (179.5,421), so elevator transfer endpoints coincide. Stair endpoints preserve different landing positions: floor 1 northwest (140.5,293.5), floor 2 (178.5,292.5); southeast floor 1 (425.5,633.5), floor 2 (456,632.5). Manual doorway-center precision is approximate; coordinates rounded to 0.01 feet.

For previews, reverse each saved node transform onto its own PDF, render at 3 pixels/PDF point, draw corridor teal, door orange, stairs purple, doorway/junction dots red, transfer dots blue, and projected origin ring red. The images were made from final saved JSON and visually inspected; preserve this derivation if refreshing them.

## Topology

- West hall and south cross hall form primary circulation. North suite corridor serves 100A–F, restroom, custodian and two Ayres Court openings. Room 100 and its restroom occupy the separate strip west of Ayres Court.
- 101A entered through 101. 107A/B/C/D entered through 107, with a west interior bend to avoid 107D when reaching 107C. 113/115/117 share the small west vestibule off the hall.
- Theatre 106 retains north and AO-marked southwest vestibule entrances, plus south circulation doors. 108 enters from the south theatre passage; 110 has west/east doors. 112 has west/south doors and an internal eastern stair marked UP. This stair has no established floor-2 counterpart and is not connected speculatively.
- Courtyard reaches foundry 130 through the west opening beneath the awning. Foundry south doors also lead into 122/126. Foundry north/east exterior doorways are retained without extending into unshown exterior paths. 122 has two doors into 126; 122A is internal to 122; 126A/B internal to 126.
- Studio 120 has exterior access through its south opening and 120B; 120B connects through 120A to 120. The suite and its UP stair form an eight-node component separate from the main graph. The upper sheet marks this footprint ROOF, so no studio-stair transfer is inferred.
- 129A and 129B have exterior-only south doorways and no shown internal openings. Each remains an isolated doorway node. No unsupported sidewalk links are drawn.
- Floor 2: 201A via 201; 202A via 202; 205A/B via 205; 207B via 207, 207A from hall; 213A via 213. Rooms 207/209 have no solid internal dividing wall in the drawing; hall doorway names follow nearby room labels. Restrooms and 206/208/210 share the east vestibule, approached around the restroom block.
- Connections: northwest stairs, southeast stairs, and elevator between 1 and 2 only. Central courtyard stair is DN-only on floor 1 and absent upstairs; no transfer. Basement, roofs and dashed Laxson Auditorium continuation are excluded.

## Assumptions and unresolved details

Door access, current elevator operation and opening hours unknown. Only explicitly AO-marked entrance/theatre-door edges are accessible=true; all stair edges false; remaining edges omit accessibility. AO at an edge does not certify the complete route. Crossed boxes and enclosed spaces without definite openings omitted. No invented room numbers.

Distances derive entirely from stored coordinates with weight 1 and undirected expansion. Aligned elevator transfer has zero plan-view distance; stairs use only landing coordinate offset. There is no floor-height override, stair effort or elevator waiting cost. These dated drawings do not establish surveyed dimensions, GPS alignment or current access permission.

Validation: 188 unique nodes; 190 serialized edges (380 directed loaded links). Four components: main two-floor component 178 nodes, studio-120 component 8 nodes, isolated 129A and 129B. Exact origin, endpoint existence, finite coordinates/distances, edge kinds, no self-links/duplicate undirected pairs, no serialized distances, and floor/connection separation checked. Overlays reviewed and parent-room/door positions corrected. Further checks are recorded in the task handoff and `tests/unit/ayresGraph.test.ts`.
