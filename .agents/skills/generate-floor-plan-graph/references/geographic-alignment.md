# Outdoor and GPS design direction

The user intends to connect indoor graphs to a separate outdoor graph at entrance nodes, anchor a node geographically, and derive GPS coordinates for the rest. This discussion did not authorize GPS conversion during ordinary floor generation. This design is also not confirmed.

## Anchor limitations

One GPS point fixes translation/location, not rotation or scale. It suffices mathematically only when orientation and scale are independently known. Otherwise, two well-separated matched reference points establish translation, rotation, and uniform scale; three or more help detect errors. Each independently drawn building needs alignment. Outdoor connectivity alone does not determine placement.

Check a known real-world measurement where available. Anchoring cannot remove errors in printed scale, north arrows, manual digitization, dated drawings, or reference measurements. Do not relabel arbitrary X/Y as latitude/longitude or call provisional vertical distances surveyed.

## Coordinate representations

The recommendation was to retain local drawing coordinates for PDF comparison, establish shared campus coordinates in meters for future geometry and routing, and derive latitude/longitude for GPS input and map display. **Current local graphs remain in feet.** Campus meters are a future recommendation, not an implemented migration; any future migration must convert coordinates/distances consistently and retain source transforms.

Latitude/longitude are angular units. The current Euclidean X/Y nearest-node calculation must not treat them as feet/meters. Transform incoming GPS through an appropriate geographic/projected coordinate system. Preserve building/floor identity because vertically stacked rooms share horizontal coordinates and GPS generally cannot reliably determine indoor floors.

Connect outdoor paths to explicit entrance IDs through verified walkable segments, not proximity across walls. Stair, ramp, winding-path, and elevator distances/costs remain distinct from horizontal endpoint distance. Waiting time and effort are cost-model choices, not physical measurements.

When only digitizing floors, retain the existing building frame and enough provenance for later calibration. Do not silently introduce a campus origin, switch coordinates to GPS, or redesign the routing API.
