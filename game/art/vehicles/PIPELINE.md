# Vehicle art pipeline

Phase A of `DEV ADDITIONS.md` ("Pipeline"): one manifest per car saying what has to be drawn
for it and where it goes, a table that puts every car on one of the spec's 25 geometry
archetypes, a validator for the spec's gates, and tests. No art is drawn here: the manifests are
the work order for the showroom sprites (`art/vehicles/showroom/`) and the 16-slice runtime
stacks (`art/vehicles/runtime/`), and the validator checks those as they land.

## Running it

From the repository root:

```sh
# write data/vehicle_art/<vehicle_id>.json for every car, then print the spread
godot --headless --path game -s tools/build_vehicle_manifests.gd

# write nothing: exit 1 if any manifest on disk isn't what the cars say now
godot --headless --path game -s tools/build_vehicle_manifests.gd -- --check

# the validation gates over every manifest and whatever art has been delivered
godot --headless --path game -s tools/validate_vehicle_art.gd
godot --headless --path game -s tools/validate_vehicle_art.gd -- --verbose

# the tests
godot --headless --path game -s tests/vehicle_art_tests.gd
```

The build takes about five minutes: it draws every car, and every body-shop option on every
car, to see what shows (`-- --only <text>` does just the cars whose id has `<text>` in it). The
validator takes about twenty seconds, the tests about a minute and a half. All three end with
an `N failed` line like the other suites and exit non-zero on failure.

Rebuild the manifests whenever a car's table line, its JSON, CarGen or CarArt changes; the tests
fail when a manifest is stale. A manifest is never edited by hand except for the fields a
person fills in (`review.artist`, `review.reviewer`, `review.approved`, `art.alpha_whitelist`),
which a rebuild carries over (see "Review" below).

## Which cars

Every car the game can draw gets a manifest: the 499 you can own (`CarCatalog.ids()`, the four
hand-made cars first), the eight fleet vehicles (`CarCatalog.fleet_ids()`), and the other
hand-made JSONs in `data/cars` (the ambulance and the fire engine the incidents send). 509 in all.

The vehicle id is `PixCars.art_id(spec)`: make, model and year in snake case
(`nissun_silvio_1991`, `dodgy_charjer_r_t_2015`). It is the file name of the manifest, the
showroom sprite and the runtime folder, and it never changes once merged (saves and art folders
hang off it). `car_id` is the id the game uses for the car (`silvio`, `fjord_mustank_1966`).

## The manifest

`tools/vehicle_manifest.gd` (class `VehicleManifest`) builds them; the schema is the spec's,
with a few measured extras. Every number comes off the car, nothing is typed in.

| Field | What it is | Where it comes from |
|---|---|---|
| `schema_version` | 1 | |
| `vehicle_id`, `car_id` | see above | `PixCars.art_id`, the catalogue |
| `display.make/model/year` | the car's name | the spec |
| `display.trim` | empty: the catalogue has no trims (a trim word is part of the model, "Charjer R/T") | the spec's `trim`, if it ever has one |
| `classification.class` | the catalogue class (`jdm`, `pony`, `hd_pickup`...) | table line / `CarCatalog.HANDMADE` |
| `classification.body` | the body CarArt draws (`coupe`, `wedge`, `boxtruck`...) | the spec |
| `classification.era` | the decade, `"1990s"` | the year |
| `classification.era_band` | the spec's era quota it counts toward, `"1990-1999"` (`"1950-1969"` is one band) | the year |
| `classification.archetype` | one of the 25 | `VehicleArchetypes.of(spec)` |
| `classification.archetype_exceptions` | why the car sits a little off its archetype: `bus_on_van_skeleton`, `tractor_on_pickup_skeleton`, `box_body`, `length_outside_range` | `VehicleArchetypes.exceptions` |
| `classification.quota_class` | which of the spec's 14 class quotas it counts toward | `VehicleArchetypes.quota_class` |
| `dimensions_m.length/width/wheelbase/track` | metres | the spec (the sim's numbers) |
| `art.showroom` | `res://art/vehicles/showroom/<id>.png` | |
| `art.runtime_dir` | `res://art/vehicles/runtime/<id>` | |
| `art.slice_count`, `front_axis`, `pixels_per_metre` | 16, `"+x"`, 12 | the spec, `CarArt.PX` |
| `art.showroom_size`, `showroom_baseline_y` | 256x96, ground at y = 78 | `PixCars.SHOWROOM_BASELINE` |
| `art.alpha_whitelist` | files allowed partly transparent pixels (`"showroom"`, `"body_07.png"`); empty until a reviewer adds one | by hand |
| `anchors.front_axle_m`, `rear_axle_m` | the axles, metres from the car's centre, +x forward | CarArt's `wheel_spots` / `wheel_rears` at 12 px/m |
| `anchors.rear_axles_m` | every rear axle (two for a semi tractor's tandem; `rear_axle_m` is their middle) | `wheel_rears` |
| `anchors.front_bumper_m`, `rear_bumper_m` | the ends of the art: half its length either way | `CarArt.length_px` |
| `anchors.track_m`, `wheel_radius_m` | front track, tyre radius | the wheel spots, the back tyres' size |
| `anchors.roof_z_slice` | the top of the cabin, in slices (light bars stand on it) | `CarArt.roof_z` |
| `anchors.procedural_slices` | how many slices CarArt stacks this car in today (`n`, by height: 13 for the Silvio, more for a bus) | `CarArt.n` |
| `anchors.exhaust_side` | `rear_right`, `rear_left`, `rear_both`, `side_both` or `hidden` (box trucks) | the car drawn with and without its tips, and where the pixels went |
| `anchors.lamps` | every lamp: kind (`head`, `brake`, `reverse`, `signal_left`, `signal_right`, `beacon`, `roof_bar`), x, y (+y is the car's right) and slice | `CarArt.lamp_spots` |
| `slots` | see below | |
| `masks` | the paint masks to export: `masks/mask_<name>.png` (paint, accent, trim, glass, decal; the spec's naming) | |
| `light_masks` | the lamp masks: `masks/light_<name>.png` (head, brake, reverse, signal_left, signal_right) | |
| `review` | `reference_notes` (one line: era, class, body, archetype, the parody rule and the catalogue blurb), `artist`, `reviewer`, `approved` (false) | the blurb |

## Slots

A slot lists what the garage's LOOKS tab sells for that car (`ui/garage_screen.gd`) that the code
actually draws on it. The first value is always the car as it comes. The build tries every
other value on the car (from above with CarArt, then side on with CarGen) and keeps it only if
the picture changes, after the garage's own fitting rules (`GarageScreen._look_fits`: a bed only
on a pickup that isn't the wrecker, a spare only on a truck or a 4x4, no bull bar on a sports
car). So a roadster has no sunroof, a pickup no wing, a bus no hood scoop, popup headlamps no
halo rings.

| Slot (the spec's name) | Values | The looks it sets |
|---|---|---|
| `front_bumper` | stock, lip, bash_bar | BODY KIT's lip; BULL BAR (`bash`) |
| `rear_bumper` | stock, diffuser, spare | BODY KIT FULL's diffuser; SPARE |
| `side_skirt` | stock, skirts | BODY KIT LIP + SKIRTS |
| `spoiler` | none, ducktail, wing, gt | SPOILER |
| `hood` | stock, vented, scoop, carbon | HOOD |
| `fenders` | stock, flared | FENDERS |
| `lights` | stock, halo, smoked | HEADLIGHTS (halo), TAIL LIGHTS (smoked) |
| `exhaust` | single, dual, quad | EXHAUST TIPS (single is every car's stock) |
| `roof` | stock, sunroof, ttops, vinyl, rack, lightbar | ROOF |
| `bed` | stock, tonneau, rollbar, rollbar_lights | BED |
| `wheel_family` | stock, then every rim in `PixCars.RIMS` | RIMS |
| `tire` | `CarGen.TIRES` | TIRES |
| `fitment` | `CarGen.FITMENTS` | FITMENT |
| `stagger` | none, staggered | STAGGER |
| `finish` | gloss, metallic, pearl, matte, chrome | FINISH |
| `livery` | none, slash, split, sponsor, flames | LIVERY |
| `stripes` | none, racing, side, rally | STRIPES |

The garage sells the body kit as one row of steps (lip, lip + skirts, full); here it's split
over the three slots it bolts onto. The tyre and paint slots are tried like the rest:
whitewalls drop out on a car that has them from the factory, racing stripes on a car that came
striped, raised white letters where the tyre is too small to carry them. The rims are the one
shortcut (every car shows its wheels): every rim but the factory one, which is `stock`; the
tests try all of them on one car of every archetype. Each option is tried cheapest view first:
the top-down shape (CarArt's plan), then the top-down slices, wheels and lamps, then the side
view at the showroom's scale. Rows that are a colour or a number (paint, rim colour, rim size, lip depth,
calipers, ride height, tint, underglow, stripe colour, spacers) aren't slots. The spec's
`grille` and `mirrors` slots have nothing in the garage yet, so no manifest lists them.
`VehicleManifest.looks_of(slot, value)` gives the looks a value puts on the car, for the
modular composer to come.

## Archetypes

`data/vehicle_archetypes.gd` (class `VehicleArchetypes`). `of(spec)` reads the body first (a
pickup is a pickup whatever its class), then the class, the length and where the engine sits:

| Archetype | Cars (owned) | What goes on it |
|---|---:|---|
| micro_fwd | 18 | kei and city cars under 3.7 m, bubble cars, the three-wheeler |
| compact_fwd | 40 | economy sedans and hatches, boxy kei-shaped compacts, sedans under 4.25 m |
| hatch_fwd | 25 | other hatchbacks, hot hatches, rally hatches |
| sedan_compact | 38 | compact-class sedans, sedans under 4.6 m |
| sedan_midsize | 32 | sedans 4.6 to 5.0 m |
| sedan_fullsize | 38 | sedans 5.0 m and over (the Charjer, the limousine) |
| coupe_compact | 17 | ordinary coupes under 4.8 m, sporty liftbacks (the Supreem), front-engined economy wedges |
| coupe_gt | 23 | luxury coupes, coupes 4.8 m and over, front-engined exotics, luxury and classic convertibles |
| muscle_longhood | 23 | the muscle body, pony and muscle coupes |
| sports_frontengine | 50 | front-engined sports, JDM and rally coupes, roadsters (the Silvio) |
| sports_midengine | 15 | mid- and rear-engined sports cars and roadsters (engine behind the seats) |
| exotic_wedge | 15 | exotic-class wedges |
| wagon_compact | 5 | wagons under 4.65 m |
| wagon_fullsize | 15 | the rest |
| crossover_compact | 17 | crossovers under 4.75 m |
| suv_midsize | 31 | SUVs and long 4x4s 4.4 to 5.05 m, bigger crossovers |
| suv_fullsize | 9 | SUVs and 4x4s 5.05 m and over |
| offroad_short | 19 | 4x4s and SUVs under 4.4 m |
| pickup_compact | 13 | pickups under 5 m, kei trucks, utes |
| pickup_half_ton | 17 | pickups 5 m and over |
| pickup_heavy | 6 | HD and work pickups, duallies (and the semi tractors) |
| van_cargo | 5 | vans with the cargo cue, work vans |
| van_passenger | 6 | other vans (and the buses) |
| minivan | 16 | minivans |
| utility_tow | 6 | the wrecker, box trucks (and the fleet's box trucks, the ambulance, the fire engine) |

The counts are the 499 cars you can own; the fleet and the two incident trucks are counted
apart. Every archetype has cars on it, so Phase B ("one vehicle for each archetype") can start
from any of them. `TABLE` also holds the lengths each archetype's parts are authored for; a car
outside them is still on the archetype and its manifest says `length_outside_range`.

`quota_class()` and `era_band()` put each car in the spec's 14 class quotas and 6 era quotas.
The build prints the catalogue's spread against them, scaled to 300 cars. As of this commit the
catalogue runs heavy on sedans (54 per 300 against a quota of 32), sports cars (35 against 28)
and SUVs, and light on hatchbacks (15 against 24), wagons (12 against 20), coupes (13 against
26) and utility vehicles (5 against 12); by era it's close to the quotas except the 2000s and
2010s (60 and 49 against 70 and 60) and 1950-1969 (36 against 24). That's the shopping list
for picking the 300.

## The validator

`tools/validate_vehicle_art.gd` runs the gates in `tools/vehicle_art_checks.gd` (class
`VehicleArtChecks`):

- **Manifests**: schema and fields; the id is the file name, snake case and the car's art id;
  the name, year (no later than 2019) and body are the car's; the archetype is one of the 25 and
  the one the table gives; the sizes are the spec's (to 0.011 m) and the art is the spec's length
  (to a pixel); the paths, 16 slices, +x and 12 px/m; the anchors are in order, the axles a
  wheelbase apart (to a pixel and a half), and every anchor is where CarArt draws it today; the
  back tyres are there under the rear axle in the bottom slices, the front wheels' stack is
  centred on the front axle, and side on CarGen's wheels sit at the same spots; every slot value
  is one the code knows, starts with the stock look, and fits the car by the garage's rules; one
  manifest per car and no manifest without a car; nothing approved without an artist, a reviewer
  and passing art.
- **Showroom sprite**, when `art/vehicles/showroom/<id>.png` exists: 256x96 RGBA; no partly
  transparent pixels (unless whitelisted); the car within the 224x76 footprint with clear
  padding round it; its lowest pixels on the ground line, y = 78 (or one row up, where a round
  tyre stops short of it); two ground contacts spaced like the manifest's axles as a share of the
  car's length; a paint mask, if there is one, the same size.
- **Runtime stack**, when `art/vehicles/runtime/<id>/` exists: exactly `body_00.png` ..
  `body_15.png`, all on one canvas, RGBA, no partly transparent pixels (unless whitelisted),
  every clear pixel clear black, the canvas big enough for the car at 12 px/m;
  `masks/mask_<name>.png` for each of `masks` and `masks/light_<name>.png` for each of
  `light_masks` (one picture, or one per slice as `_00` ..); a front and a rear bumper in
  `detachable/`.

Art that isn't there is counted as not delivered, not failed. Today: 509 manifests pass, 0
showroom sprites and 0 runtime stacks delivered.

Known and listed rather than failed (`VehicleArtChecks.WHEELBASE_EXCEPTIONS`): the 1965 Minni
Cupper's hand-drawn side view puts its wheels at the corners, about 2.56 m apart against the
table's 2.04 m, and the Peeled Pee-Fifty's tyres can't sit closer to the ends of a 1.37 m car
than their own radius, so its art's axles are under a metre apart against 1.27 m. The manifests
record where the wheels are drawn; the fix belongs in CarGen or the table.

Found while calibrating the showroom gate against `tools/export_showroom.gd`'s own output (it
paints the preview the same way): open roadsters get a windshield painted at 55% alpha, which
the no-partial-alpha gate fails unless whitelisted, and the tall vans and trucks come out 77 rows
tall, one past the 76-row footprint (the exporter shrinks a car until 76 rows stand above the
ground line, then the tyres' own row makes 77).

## Review

`review.approved` stays false until a person has looked at the delivered art; the tool never sets
it. `artist`, `reviewer`, `approved` and `art.alpha_whitelist` are the hand-written fields
(`VehicleManifest.HAND_KEYS`): a rebuild reads them off the manifest on disk and keeps them, and
everything else it measures again. The validator fails a manifest that is approved without an
artist and a reviewer, or whose showroom sprite or runtime stack isn't delivered and passing.
