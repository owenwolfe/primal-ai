# Acker Gymnasium (`acker`)

Generated 2026-10-27 from the three supplied PDFs, all dated 7/14/08:

- `csuc-floor-plans/Acker/agym-1.pdf`: partial first floor, northern main gym and locker block.
- `csuc-floor-plans/Acker/agym-2.pdf`: continuation of the **same first floor**, rooms 111–127.
- `csuc-floor-plans/Acker/agym-3.pdf`: second floor, rooms 201–207 and covered walkway.

PDF suffixes identify sheets, not floors. Runtime data comprises `src/data/acker/floor-1.json`, `floor-2.json`, and `connections.json`. Requested `floor-1-preview.png` combines overlays for both first-floor source sheets side by side; `floor-2-preview.png` overlays sheet 3. Previews are local review artifacts, not application imports or commit artifacts. Existing loader discovers JSON automatically.

## Scale and alignment

Pages are 612 x 792 PDF points, rotation 0, printed scale 1 inch = 40 feet. Feet per PDF point = 40/72. Inspected exact 2x renders, including enlarged washroom, locker, suite and stair details. Labels are vector outlines and text extraction is empty.

Building origin: `acker-1-exit-lobby-east-ao`, the east lobby AO doorway on sheet 1, native top-left PDF coordinate (427, 329.5). X drawing-right, Y drawing-up. Reference conversion: x=(pdfX-427)*40/72, y=(329.5-pdfY)*40/72. Upper floors retain this origin, projected onto the first-floor roof in sheet 3.

Translations into sheet-1 native PDF coordinates (rotation 0, scale 1):

- Sheet 1: (0,0).
- Sheet 2: (+3,+499), supported by the match line (sheet-1 Y=672, sheet-2 Y=173) and east outside wall. The west corridor wall differs about 1.5 PDF points after translation; this is a manual alignment uncertainty, not a surveyed fit.
- Sheet 3: (+13.5,+7), supported by the main gym right/left walls and its south wall, with small source drafting differences near the gym top wall. Matching north/south stair cores support the alignment. Landing positions need not coincide.

## Routing and access

Two stair cores connect floors 1 and 2: the north stair next to floor-1 telecom / floor-2 room 201B, and the south stair by floor-1 room 129 / floor-2 rooms 205 and 207. Only adjacent supplied floors connect. The floor-2 broadcasting booth stair is marked UP; no supplied booth floor geometry is invented. The floor-2 elevator is retained as a destination, but the floor-1 lower shaft/approach is only dashed at the sheet match line. No lower landing or elevator transfer is inferred.

The first-floor east corridor continues across the two sheets. Room 126A is reached through 126, and 126B through 126A. Rooms 149A and the east changing passage are reached through 149. Rooms 149B/C face 145 circulation. Room 145 links to 146 and to 144 through the visible shower aisle opening. Room 147 opens from 146; the unnumbered south room opens from 147. The two southern men's rooms open separately from 143 and 142; no shortcut crosses the dividing walls. East restroom/custodial pairs use their small shared vestibules.

Floor-2 room 201 has multiple north entries and a south entry through 202; 201A/B are internal. Restrooms/custodial use the visible west corridor openings. Rooms 203A/B are internal to 203. Suffixes A/B/C at the east side of 204 are retained as 204A/B/C doorway destinations. Room 205A is reached through 205. The covered walkway connects the west corridor to the southeast stair/elevator landing.

Eight exterior-only doorway nodes are intentionally isolated: first-floor rooms 151–156, west storage, and the unnumbered northwest room on sheet 2. Their doors are visible but no connecting exterior walkway is drawn. The northwest unnumbered room is separated from 126A by a closed partition. These nodes must not be linked through walls or invented exterior routes. Shurmer Gymnasium outlines and detached key-plan/building graphics are context only and excluded.

Only explicitly AO-marked entrance edges are accessible=true; stair edges false, all other accessibility unspecified. Source wheelchair restroom symbols do not certify an entire route. Plans do not establish present locks, permissions, elevator operation or compliance. All weights are 1; distances, including vertical transfers, derive from endpoint positions without a floor-height override.

## Validation

Final floor 1: 136 nodes, 137 within-floor edges. Floor 2: 50 nodes, 54 within-floor edges. Two inter-floor stair edges. Structural checks cover unique/global IDs, building/floor fields, finite coordinates, exact origin, allowed edge kinds, valid nonnegative weights, endpoint existence, no duplicate undirected pairs/self-links, no serialized distances, within-floor containment and cross-floor separation. The main component contains 178 of 186 nodes, with exactly the eight documented isolated exterior-only doors. JSON-derived overlays were inspected and corrected at restroom vestibules, room 147, 205A, interior washroom access and the locker/shower aisle.

Project verification passed: lint, typecheck, full Vitest suite, coverage thresholds, infrastructure smoke and production build. E2E command completed with no tests. A temporary container-mounted Vitest validation exercised the actual loader and Dijkstra: all 178 main-component nodes route in both directions; eight isolated doors remain unreachable; 386 directed edges, coordinate-derived distances, floor-aware entrance snapping, internal 126B/205A access and independent mutable loads all pass. Acker JSON passes Prettier. Repository-wide formatting remains blocked by pre-existing workflow YAML syntax and unrelated file formatting.
