---
name: generate-floor-plan-graph
description: Digitize building floor-plan PDFs into minimal ClassFinder routing graphs, organize per-floor JSON, align building coordinates, and connect floors. Use when adding or correcting floor-plan graph data. Temporary verification previews are allowed; final previews under src/data require an explicit request.
---

# Generate Floor-Plan Graphs

Create small, traceable routing datasets from architectural drawings. Preserve the following user decisions. Inspect current code before relying on a historical loader or routing API.

## Scope and source inspection

- Read `AGENTS.md`, `src/lib/graph.ts`, `src/lib/dijkstras.ts`, `src/graph/graphLoader.ts`, existing building data, and relevant tests. Preserve unrelated edits and existing IDs when extending a building.
- Locate PDFs with `rg --files csuc-floor-plans`. Inspect every requested floor visually, including openings and small labels. Vector-outline labels may not appear in text extraction; an empty extraction does not mean the drawing is empty.
- When working on a building, resolve its stable building ID and read this skill's `references/<building-id>.md` if it exists. Load only the corresponding building reference, not every building's notes. For GPS or outdoor integration, also read [references/geographic-alignment.md](references/geographic-alignment.md).
- Work incrementally: inspect/map one floor, check geometry and topology, then extend and connect it. Save completed work and give meaningful progress updates instead of endlessly planning.
- Generating more than 4–5 floors in the same session may trigger context compression, especially with detailed PDF inspection. Prefer batches of at most 4–5 floors. Before continuing to another batch, save completed datasets and record alignment decisions, unresolved openings, connection assumptions, validation results, and remaining work so progress can resume accurately after compression or in a new session. This is a practical batching guideline, not a guaranteed context limit.
- Temporary preview images, overlays, and source renderings may be generated when useful for verifying your own work. Keep them in a temporary location such as `/tmp`. **Do not create or refresh an official final preview under `src/data` unless explicitly requested.** Earlier preview requests do not grant standing permission for final deliverables in future tasks.

## Location and naming

```text
src/data/
  <building-id>/
    floor-1.json
    floor-2.json
    floor-3.json
    floor-4.json
    connections.json
```

- Use one JSON file per floor, grouped by the existing lowercase building ID. Resolve casual names or spelling variants to that ID rather than introducing a duplicate building.
- Source PDFs stay in `csuc-floor-plans/<source-building-folder>/`. Preserve their actual filenames and record exact source paths; source folders need not match application building IDs.
- `src/data` is intentional: these are imported application datasets. Earlier root-level `data/` and flat `src/data/ocon-1.json` were superseded. Avoid duplicate copies and one monolithic campus JSON.
- `floor-<floorId>.json` contains local nodes and within-floor edges. `<building>/connections.json` contains inter-floor edges referencing those nodes, not duplicate node definitions.
- IDs are globally unique: `<buildingId>-<floorId>-<purpose>`, e.g. `ocon-2-room-214`, `ocon-2-hall-north`, `ocon-2-stairs-west`, `ocon-2-elevator-passenger`.
- Preserve room suffixes such as `114A`. Name additional doors (`room-124-lobby-door`), turns, and junctions descriptively. Give visible unnumbered destinations spatial names, not invented room numbers.
- Only when requested, put `floor-<floorId>-preview.png` beside its JSON. Generate it from final saved JSON, not a separate digitization table. Existing images may be preserved during a move, but are not regenerated unasked. They are local review aids, not application imports or commit artifacts.
- Update README and AGENTS when paths or loading behavior change. Inspection tools must not introduce unrelated application dependencies or infrastructure decisions.

## Building reference records

Create `references/<building-id>.md` within this skill when adding a building that has no reference yet. Use the same ID as its `src/data/<building-id>/` folder. Update the existing reference when extending or correcting that building; this generic lookup is sufficient, so do not add a building-specific link to this entrypoint for every new building.

Record the building's display name/aliases, source PDF paths and dates, floor/file inventory, units and printed scales, chosen origin node and native PDF position, axis conventions, floor alignment transforms and supporting landmarks, stair/elevator topology, unusual room-access relationships, unresolved geometry, and validation results. Save remaining work and decisions needed to resume between batches. Include only established facts or explicitly labelled assumptions; do not invent missing values to fill a template.

Keep these records synchronized with data changes. They preserve reasoning and provenance rather than overriding corrected source evidence or current JSON. Reference records are agent documentation, not runtime application data. Preserve useful history when renaming an older reference to match its building ID.

## Serialization and graph types

Floor files contain `{ "metadata": {...}, "nodes": [...], "edges": [...] }`; connections contain `{ "metadata": {...}, "edges": [...] }`.

```typescript
type SerializedNode = {
  id: string;
  buildingId: string | null;
  floorId: number | null;
  position: { x: number; y: number };
};
type SerializedEdge = {
  from: string;
  to: string;
  weight: number;
  type: 'corridor' | 'door' | 'stairs' | 'elevator' | 'ramp' | 'outdoor';
  isAccessible?: boolean;
};
```

Check these against current `graph.ts`. Restore `NodeId` branding at the TypeScript boundary. `from` is only for serialization: it becomes the loaded `Graph` adjacency-list key and is omitted from `Edge` values. Indoor nodes use the building ID and numeric floor. Use nullable fields appropriately for genuinely outdoor nodes when outdoor work is requested.

Set `metadata.undirected: true`. Store each two-way edge once and expand it in both directions when loading. Serialized edges do not contain `distance`: the loader calculates its runtime value with `Math.hypot(from.position.x - to.position.x, from.position.y - to.position.y)`. Default weight is `1`; the current Dijkstra cost is `distance * weight`. Costs must be finite and nonnegative.

Omit `isAccessible` when unknown; omission is not true. Stair traversal is false. Mark true only for supported facts such as source-marked AO/wheelchair entrance edges, without claiming a complete accessible route. Do not infer elevator availability, service-elevator permission, unlocked doors, or ramp compliance. Metadata cannot enforce restrictions in a router that ignores them.

## Minimal, physically justified topology

- Room destinations are **doorway nodes**, not a room center plus a separate door node.
- Add only necessary junctions, bends, distinct entrances, and stair/elevator access points. Avoid grids, decorative/furniture nodes, and extra points along unobstructed straight paths.
- Keep a node if removing it would cross a wall, lose a branch or transfer, or substantially distort travel distance. Minimal does not mean arbitrary straight-line shortcuts.
- Follow visible openings. Interior-only rooms must be reached through their actual parent room. Retain multiple usable entrances and supported alternatives.
- Door edges may include approaches or travel between room doors. Corridor edges include lobby/open circulation. Use ramp, stairs, elevator, and outdoor kinds for the movement actually represented.
- Dashed equipment is not a walkway. Proximity is not connectivity. Do not invent doors for enclosed or ambiguous spaces; retain visible unnumbered entrances and document missing access evidence.
- Include only shown, relevant outdoor segments, such as an exterior stair exit's approach to a nearby entrance. A neighboring building outline does not establish its indoor graph or a campus path.

## Scale, building origin, and floor alignment

1. Read each PDF's printed scale, native page dimensions, units, and rotation. Never derive physical scale from an image's displayed size in chat. Standard PDF points are 1/72 inch; account for nonstandard units or source resizing.
2. Current local graphs use **feet**. At `1 inch = 30 feet`, `feetPerPdfPoint = 30 / 72`. Divide raster coordinates by the rendering scale in pixels per PDF point before applying this factor.
3. Choose a clearly identifiable exterior **door node** on the reference floor as the building's `(0, 0)`. Record its exact ID, description, and native PDF coordinate. Preserve that origin for subsequent floors instead of choosing a new door per floor.
4. Positive X is drawing-right; positive Y is drawing-up, not geographic east/north. For top-left PDF coordinates and origin `(ox, oy)`, `x = (pdfX - ox) * feetPerPdfPoint`, `y = (oy - pdfY) * feetPerPdfPoint`.
5. Align upper floors using corresponding fixed features such as elevator shafts and stair cores; compare multiple features where possible. Translation alone requires matching scale and orientation. Otherwise determine and record rotation/scale too. Different landings need not have identical coordinates.
6. Store the transform and projected origin on each floor. Upper-floor origin metadata references the reference-floor door, not an invented upper-floor exit. Negative coordinates and equal X/Y on different floors are legitimate.
7. Retain necessary bends to represent the walking route. Round coordinates to two decimals for reproducibility, not a claim of surveyed precision; the loader derives each runtime edge distance from those stored coordinates.
8. Ramp plan-view length omits unknown slope. Horizontal separation may produce a zero runtime distance for aligned transfer endpoints.

Metadata records source path/date, building/floor, units, scale/conversion factor, origin ID/description/PDF point, axes, alignment method/transform, undirected loading convention, weight assumptions, accessibility semantics, and uncertainties. Distinguish source observations from user-approved assumptions and note dated/manual geometry.

## Cross-floor connections

- Link corresponding stairs/elevators on **adjacent floors**, rather than every pair of floors. Do not extend a stair beyond the floors where it appears. Horizontal landing approaches stay in floor files; vertical travel goes in `connections.json`.
- Keep separate stair cores and passenger/service elevator chains.
- Store no transfer-distance override. The loader derives every transfer distance from its endpoint positions, as it does for within-floor edges. Ensure those positions express the routing geometry intended by the data.
- Current costs omit elevator waiting time and stair effort. Traversing multiple floors accumulates the loaded coordinate-derived edge distances.
- Future outdoor work should use a separate graph connected explicitly to entrance IDs after alignment. No outdoor naming scheme was finalized in the conversation; do not invent one as an established convention.

## Loading and validation

When app integration is in scope, update `src/graph/graphLoader.ts` to import the requested floors and connections. Initialize all nodes/empty adjacency lists before adding edges, use `connectBothWays`, preserve optional fields, and return fresh maps and nested positions. Repair imports after moves and preserve unrelated code.

Inspect the current routing API. Its nearest-start search originally used only X/Y; select the starting building/floor before snapping. With the existing API, supply only that floor's candidate `Nodes` while keeping the complete `Graph` and actual destination `Node`. Do not silently redesign Dijkstra or migrate coordinates to GPS during digitization.

Verify the following:

- Unique IDs, correct building/floor fields, finite coordinates, exact origin, allowed edge kinds, existing endpoints, no duplicate undirected pairs/self-links, no serialized `distance` property, and valid loaded distances/weights.
- Within-floor edges stay on their floor; only connections cross floors. Check reachability for each intended destination, and explain any genuinely disconnected region rather than forcing a route.
- Scale conversion and coordinate-derived edge distances are consistent. Compare routes to actual openings, walls, corners, ramps, and columns. Connectivity tests alone cannot establish physical correctness.
- Transfer endpoints correspond, supported floor ranges are correct, assumptions are labelled, and accessibility is not overstated.
- Loaded two-way links produce twice the serialized edge count. Test attribute preservation, independent loads, cross-floor routes, and floor-aware start candidates with real Dijkstra.
- Use test-first development for loader behavior changes. Run applicable AGENTS checks and a production build for integration changes. Distinguish no-test E2E runs and pre-existing formatting failures from successful checks. Do not repair unrelated files just to make checks green.

Validate using source inspection, data/tests, and temporary previews when helpful. For verification overlays or explicitly requested final previews, reverse the stored transform onto the source PDF, draw nodes/connections and the origin, inspect crossings, and regenerate after corrections. Keep self-verification images outside `src/data`; only deliver final previews there when asked. For requested deliverables, provide clickable project paths: `/tmp` is outside the project explorer and is unsuitable as the final user-facing preview location.

Hand off files, counts, actual check results, and remaining uncertainties. Do not claim GPS calibration, survey accuracy, current access permissions, or accessibility certification from these PDFs alone.
