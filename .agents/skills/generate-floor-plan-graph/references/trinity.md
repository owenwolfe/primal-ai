# Trinity Hall (`trinity`)

Digitized 2026-10-27 from `csuc-floor-plans/Trinity/trnt-1.pdf` (printed 9/15/09) and `csuc-floor-plans/Trinity/trnt-2.pdf` (7/14/08). Source pages are 612 x 792 PDF points, rotation 0; labels are vector outlines. Both print 1 inch = 20 feet, so 20/72 feet per PDF point. Exact 2x PyMuPDF renders were inspected, including enlarged door/lobby details.

## Files and coordinates

`src/data/trinity/floor-1.json`, `floor-2.json`, `connections.json`; requested PNG previews beside both floor files. Loader glob discovers these automatically. Previews are review aids, not commit artifacts.

Origin: `trinity-1-exit-south-ao`, the south AO doorway beside the south stair, native PDF point (349.5, 655.5), top-left coordinates. X drawing-right, Y drawing-up, in feet. Formula x=(pdfX-349.5)*20/72, y=(655.5-pdfY)*20/72. Both floors use the same projected origin; identity scale/rotation/translation is supported by corresponding elevator shaft, north walls and south wing outline. Landings can differ horizontally within matching stair cores. No GPS or survey calibration.

## Topology

Three adjacent-floor stair transfers: northwest, northeast and south; one labelled passenger elevator chain at the south wing lobby. Floor-1 west-central stair is marked DN and has no floor-2 counterpart (roof). Floor-2 east stair is UP and is not connected to floor 1 or an invented third floor. Transfer distances are coordinate-derived, including near-zero elevator displacement; no vertical cost override or waiting time.

North rooms connect to their visible doors. Floor-1 121A/B are accessed through 121. Floor-2 223 and its A/B/C suite share the visible suite entrance. Room 239A is interior to 239 and routes through that room's doorway. Floor-1 100A/B and open room 100 provide circulation. East 122 links north circulation and the south wing; its southern doorway leads through the east approach to the south corridor. Both ends of the south wing's paired corridors are open. Floor-2 north/south circulation follows the narrow ramp beside the opening over floor 1. Ramp slope and compliance are unknown.

Small cross-hatched shafts are not assumed to be public elevators. Floor-1 west custodial room lacks a confirmed doorway and is omitted rather than assigned invented access. Unnumbered accessible restroom, women/men, and source-visible storage/custodial destinations with doors are named spatially. Source AO entrance edges alone are marked accessible; stair transfers false, other edges unknown. Dated plans do not establish present locks, permissions or elevator availability.

## Validation

Final data: floor 1 has 132 nodes / 135 local edges; floor 2 has 111 nodes / 112 local edges; 4 transfers. Structural validation checks unique IDs, fields, finite coordinates, weights, allowed kinds, exact origin, endpoint existence, no duplicate undirected pairs/self-links, no serialized distances, local floor containment and transfer separation. All 243 included nodes are reachable bidirectionally from the south entrance. JSON-derived overlays were inspected and corrected at restroom approaches, east south-wing access, elevator lobby, floor-2 ramp opening and interior 239A access. Coordinates are manual approximations rounded to two decimals, not measurements of survey accuracy.
