# DEV ADDITIONS — Vehicle Art Expansion

> **Status:** Production specification and AI-artist work order. This file defines the required 300 vehicles and 8,000+ modular sprite assets. A vehicle is not considered delivered until its art, data, validation report, and in-game preview exist in the repository.

## Goal

Build a deep vehicle catalog for Reckless Rumble with **300 fictional vehicles inspired by recognizable real-world cars from 1950–2019**. The visual language must match the supplied reference: readable side-profile pixel art, restrained shading, dark outlines, transparent backgrounds, and distinct silhouettes.

Every in-game make, model, badge, logo, grille treatment, lamp signature, and trim name must be fictional. Real vehicles may be used as proportion and era references, but the result must read as an original parody rather than a traced or rebadged copy.

The current runtime does not use ordinary flat car PNGs. `game/render/car_art.gd` builds each car as **16 stacked horizontal slices**, with the front facing `+x`, at **12 pixels per metre**. New art must preserve that runtime system, steering wheels, lights, directional damage, detached bumpers, body roll, and 360-degree rotation.

## Deliverables

- 300 base vehicle definitions, all with a maximum model year of 2019.
- 300 side-profile showroom sprites matching the attached visual reference.
- 300 runtime body recipes, each producing 16 compatible slices: **4,800 base slice sprites**.
- A modular visual-parts library producing at least **3,100 additional overlay sprites**.
- At least **8,200 authored/exported sprite layers** in total, not 8,200 wastefully flattened full-car combinations.
- Body customization, wheel/tire customization, paint, decals, stance, lighting, exhaust, and visible performance hardware.
- Performance upgrades that change simulation values and show suitable visual cues where applicable.
- Automated validation for naming, dimensions, transparent padding, palette, slice count, attachment points, and missing files.
- Contact sheets organized by era and vehicle class for fast human review.

## Asset Math

| Asset group | Source designs | Exported sprites |
|---|---:|---:|
| Runtime base bodies | 300 × 16 slices | 4,800 |
| Side showroom previews | 300 | 300 |
| Front/rear bumper kits | 48 × 16 | 768 |
| Side-skirt families | 24 × 16 | 384 |
| Hood families | 32 × 16 | 512 |
| Spoiler/wing families | 36 × 16 | 576 |
| Exhaust families | 20 × 16 | 320 |
| Lamp/grille families | 24 × 16 | 384 |
| Wheel-face/tire families | 48 × 2 states | 96 |
| Decal/livery masks | 80 | 80 |
| **Minimum total** |  | **8,220** |

Do **not** pre-render every possible full-car combination. Modular composition keeps the repository reviewable and permits millions of combinations from a controlled set of compatible layers.

## Catalog Allocation

The final manifest must contain exactly 300 vehicles. Use this class distribution so traffic, missions, garage inventory, and eras remain varied.

| Class | Count | Typical forms |
|---|---:|---|
| Compact/economy | 28 | City car, subcompact, economy notchback |
| Sedan | 32 | Family sedan, sport sedan, fleet car |
| Hatchback | 24 | Three-door, five-door, hot hatch |
| Wagon | 20 | Estate, shooting brake, long-roof |
| Coupe | 26 | Personal luxury, tuner coupe, GT |
| Muscle | 18 | Pony car, full-size muscle, homologation special |
| Sports | 28 | Roadster, lightweight coupe, rally special |
| Super/exotic | 14 | Wedge, mid-engine exotic, halo car |
| Pickup | 26 | Compact pickup, half-ton, heavy-duty, sport truck |
| Van/minivan | 16 | Cargo van, conversion van, minivan |
| SUV/crossover | 28 | Compact crossover, full-size SUV, luxury 4×4 |
| Utility/service | 12 | Tow, taxi, police-style fleet, delivery, municipal |
| Off-road | 14 | Trail 4×4, dune truck, rally raid |
| Luxury | 14 | Executive sedan, limousine, grand tourer |
| **Total** | **300** | |

Use this era distribution:

| Era | Count |
|---|---:|
| 1950–1969 | 24 |
| 1970–1979 | 30 |
| 1980–1989 | 50 |
| 1990–1999 | 66 |
| 2000–2009 | 70 |
| 2010–2019 | 60 |
| **Total** | **300** |

At least 35% of the catalog should look normal enough for everyday Port Rumble traffic. Do not make the catalog only famous sports cars.

## Fictional Identity Rules

Each vehicle needs a unique fictional make, model, trim, model year, and short description. Existing names such as **Nissun Silvio**, **Toyoda Supreem**, **Dodgy Charjer**, and **Fjord F-One-Fiddy** establish the tone.

For each parody, alter at least five identity cues:

- Fictional make and model names.
- Grille shape and internal pattern.
- Headlamp and taillamp signatures.
- Side-window/DLO outline.
- Bumper openings and lower valance.
- Hood creases or vents.
- Fender and wheel-arch treatment.
- Spoiler, mirrors, handles, and trim placement.
- Proportions within plausible limits.
- Badging and wheel design.

Never include real manufacturer logos, exact badges, trademarks, sponsor marks, license-plate text, or copied racing liveries. Reference images are for general proportion, era, and category cues only; do not trace them pixel-for-pixel.

## Visual Standard

### Showroom Sprite

- Canvas: `256 × 96 px`, transparent RGBA.
- Vehicle faces right; all previews use the same ground baseline at `y = 78`.
- Target maximum footprint: `224 × 76 px`, leaving transparent padding.
- Pixel-perfect hard edges; no antialiasing, blur, gradients, JPEG noise, or subpixel transforms.
- One-pixel near-black outer contour, selective two-pixel shadow at the underbody only.
- Three body-paint values: shadow, base, and highlight; glass may use three additional blue-grey values.
- Neutral factory paint in the source sprite. Paintable areas must also have a separate indexed mask.
- Doors, shut lines, pillars, lights, wheels, and body style must remain legible at 1× scale.
- Do not bake labels, floor shadows, UI frames, or category text into the vehicle file.

### Runtime Stack

- `16` slices exactly, indexed `00` through `15`.
- Front is `+x`; every slice shares an identical canvas and origin.
- Scale is `12 px/m`, matching `CarArt.PX`.
- Slice `00` begins at the undercarriage; slice `15` is the highest roof/wing detail.
- Transparent pixels must be fully transparent black to prevent edge halos.
- Lights export as separate masks: head, brake, reverse, left signal, right signal.
- Removable front and rear bumpers export separately so current crash debris still works.
- Front wheels remain steerable and must not be permanently baked into upper body slices.
- Part overlays must use the exact base canvas, origin, and slice index of their compatible archetype.

## Vehicle Archetypes

Do not hand-fit every universal part to all 300 cars. Assign every vehicle to one geometry archetype and author parts against that archetype.

Required archetypes:

- micro_fwd
- compact_fwd
- hatch_fwd
- sedan_compact
- sedan_midsize
- sedan_fullsize
- coupe_compact
- coupe_gt
- muscle_longhood
- sports_frontengine
- sports_midengine
- exotic_wedge
- wagon_compact
- wagon_fullsize
- crossover_compact
- suv_midsize
- suv_fullsize
- offroad_short
- pickup_compact
- pickup_half_ton
- pickup_heavy
- van_cargo
- van_passenger
- minivan
- utility_tow

Each vehicle manifest must declare an archetype plus approved exceptions. Never stretch a part with filtered scaling; create or adapt a pixel-correct part for that archetype.

## Customization System

### Body Parts

Each eligible vehicle must expose slots rather than flattened variants:

- `front_bumper`: stock, clean, street, sport, drift, rally, offroad, bash_bar.
- `rear_bumper`: stock, clean, street, sport, diffuser, drift, offroad, step.
- `hood`: stock, smooth, cowl, vented, scoop, carbon_style, cutout.
- `side_skirt`: stock, delete, street, sport, wide, rally_guard.
- `spoiler`: none, lip, ducktail, pedestal, touring, drag, rally, roof.
- `fenders`: stock, rolled, flared, bolt_on_wide, boxed, cut.
- `grille`: stock, mesh, billet_style, slatted, delete, rally_lamps.
- `lights`: stock, clear, smoked, projector_style, retro_round, taped_race.
- `mirrors`: stock, classic, compact, aero, tow.
- `exhaust`: hidden, single, dual, side_exit, dump, vertical_stack.
- `roof`: stock, rack, cargo_box, light_bar, visor, chop where supported.
- `bed`: stock, cap, tonneau, toolbox, flatbed, utility, tow_rig for pickups.

Unsupported combinations must be blocked in data, not allowed to clip.

### Wheels and Tires

- 48 fictional rim designs grouped into steel, classic, mesh, five-spoke, multi-spoke, deep-dish, rally, truck, off-road, and aero families.
- Sizes must respect the vehicle: 12–16 inch classics/economy, 15–20 inch street/performance, and suitable truck diameters.
- Tire types: economy, touring, sport, semi_slick, drag_radial, all_terrain, mud_terrain, winter, studded.
- Visual states: fresh, worn, corded, flat/blown, and snow-packed where applicable.
- Width, sidewall, offset, and track changes must be visible without breaking wheel-arch clearance.

### Paint and Trim

- Body paint is mask-driven and selectable at runtime.
- Separate masks for body, secondary accent, trim, wheel face, caliper, and decal.
- Finish modes: gloss, matte-style palette, metallic-style highlight, primer, patina, and fleet.
- Window tint levels: none, light, medium, dark; windshield remains legally lighter in the default preset.
- At least 80 original livery/decal masks. No real brands or copied motorsport schemes.

### Stance

- Ride height: offroad, raised, stock, street, low, race.
- Track: stock, mild_wide, wide.
- Camber: stock, sport, drift/show; values must remain sane in normal traffic builds.
- Wheel offsets must have compatibility bounds per archetype.

## Performance Upgrades

Performance customization belongs in vehicle data and simulation. Art only visualizes upgrades that would actually be visible.

Required upgrade families:

- Intake: stock, panel, cold_air, velocity_stack where suitable.
- Exhaust: stock, street, performance, race, side_exit.
- ECU/ignition: stock, tune_1, tune_2, race.
- Aspiration: naturally aspirated, supercharger, single turbo, twin turbo; only where compatible.
- Fuel: stock, upgraded pump/injectors, race fuel map.
- Cooling: stock, upgraded radiator, oil cooler, intercooler.
- Internals: stock, street forged, race forged.
- Transmission: stock ratios, close ratio, dogbox, automatic build, final-drive choices.
- Differential: open, limited slip, welded, selectable locker.
- Brakes: stock, street, sport, race; update torque, fade, and visual rotor/caliper size.
- Suspension: comfort, street, sport, drift, rally, offroad, drag.
- Weight reduction: none, street, interior strip, race; preserve mission-required seats/cargo rules.
- Tires: connect directly to compound, temperature, tread wear, snow, wet, ice, and blowout behavior.

Every performance part must declare cost, mass delta, durability, unlock condition, compatible IDs/archetypes, simulation modifiers, and visible-part references. Do not use arbitrary “+10 speed” stats; modify physical values such as torque curve, inertia, shift time, final drive, brake torque, mass, drag, grip, and cooling.

## Directory Layout

```text
game/
  art/
    vehicles/
      showroom/
        <vehicle_id>.png
      runtime/
        <vehicle_id>/
          body_00.png ... body_15.png
          masks/
          detachable/
      parts/
        <archetype>/
          bumpers/
          hoods/
          skirts/
          spoilers/
          lights/
          exhausts/
      wheels/
      tires/
      liveries/
      contact_sheets/
  data/
    cars/
      <vehicle_id>.json
    vehicle_art/
      <vehicle_id>.json
    customization/
      parts.json
      performance.json
      compatibility.json
  tools/
    validate_vehicle_art.gd
    build_contact_sheets.gd
```

Do not overwrite the four existing vehicle JSON files or silently change their handling. Migrate them only through a tested compatibility layer.

## Naming Convention

Use lowercase snake case everywhere.

```text
vehicle:        <fictional_make>_<fictional_model>_<year>
showroom:       <vehicle_id>.png
runtime slice:  body_<00-15>.png
part:           <slot>_<family>_<variant>_<00-15>.png
mask:           mask_<paint|accent|trim|glass|decal>.png
wheel:          wheel_<family>_<variant>.png
tire:           tire_<type>_<state>.png
```

IDs never change after merge because save files will reference them.

## Vehicle Art Manifest

Create `game/data/vehicle_art/<vehicle_id>.json` for every vehicle.

```json
{
  "schema_version": 1,
  "vehicle_id": "nissun_silvio_1991",
  "display": {
    "make": "Nissun",
    "model": "Silvio",
    "trim": "2.0T",
    "year": 1991
  },
  "classification": {
    "class": "sports",
    "body": "coupe",
    "era": "1990s",
    "archetype": "sports_frontengine"
  },
  "dimensions_m": {
    "length": 4.47,
    "width": 1.69,
    "wheelbase": 2.47
  },
  "art": {
    "showroom": "res://art/vehicles/showroom/nissun_silvio_1991.png",
    "runtime_dir": "res://art/vehicles/runtime/nissun_silvio_1991",
    "slice_count": 16,
    "front_axis": "+x",
    "pixels_per_metre": 12
  },
  "anchors": {
    "front_axle_m": 1.235,
    "rear_axle_m": -1.235,
    "front_bumper_m": 2.235,
    "rear_bumper_m": -2.235,
    "roof_z_slice": 15,
    "exhaust_side": "rear_right"
  },
  "slots": {
    "front_bumper": ["stock", "street", "drift"],
    "rear_bumper": ["stock", "street", "drift"],
    "hood": ["stock", "vented", "carbon_style"],
    "spoiler": ["none", "lip", "pedestal"],
    "wheel_family": ["mesh", "five_spoke", "deep_dish"]
  },
  "masks": ["body", "accent", "trim", "glass", "decal"],
  "review": {
    "reference_notes": "Generic early-1990s Japanese FR tuner coupe; do not reproduce badges or lamp geometry.",
    "artist": "",
    "reviewer": "",
    "approved": false
  }
}
```

## AI Vehicle Artist Work Order

Use the following as the standing task for an AI dedicated to vehicle assets:

> You are the Reckless Rumble vehicle-art specialist. Work only on vehicle manifests, vehicle sprites, modular customization parts, contact sheets, validators, and directly related tests. Preserve the Godot 4.5 architecture and never rewrite driving physics or unrelated game systems. Produce original fictional parodies, never trademarks or traced copies. Match the established hard-edged pixel-art look. Every runtime car needs 16 aligned slices, separate light masks, removable bumpers, steerable front wheels, damage compatibility, and a 256×96 side showroom preview. Work in small reviewable batches of five vehicles. Run validation and generate a contact sheet before each commit. Do not mark a vehicle complete when only its JSON, prompt, or placeholder exists.

For each batch:

1. Select five unclaimed catalog slots while maintaining class and era totals.
2. Write fictional identities and short reference notes.
3. Add or update physical vehicle data without fabricating impossible dimensions.
4. Create showroom art and 16-slice runtime art.
5. Add supported modular slots and compatibility rules.
6. Verify lights, wheels, damage, detached bumpers, steering, and paint masks in Godot.
7. Generate a labeled contact sheet for review only; keep labels out of source sprites.
8. Run all existing headless tests plus vehicle-art validation.
9. Commit one batch with a clear asset count and no unrelated code changes.

## Production Phases

### Phase A — Pipeline

- Add directories, schema, loader, modular composer, and validators.
- Convert the four current cars without changing their appearance or physics.
- Prove one bumper, hood, spoiler, wheel, tire, tint, paint, and visible performance part.
- Prove damage and lights still function on customized cars.

### Phase B — First 25

- Produce one vehicle for each archetype.
- Review silhouette readability, scaling, part alignment, and traffic performance.
- Lock palette, canvas, origins, anchors, and export procedure only after this review.

### Phase C — First 100

- Prioritize ordinary traffic cars, local work vehicles, weather-capable cars, and the main story cars.
- Add enough shared parts to prove the modular system reduces duplicated art.
- Profile memory, import time, load time, and draw cost.

### Phase D — Full 300

- Fill remaining class and era quotas.
- Add exotics and unusual vehicles only after everyday traffic has enough variety.
- Complete contact sheets and compatibility coverage.

### Phase E — Customization Depth

- Reach or exceed 8,220 exported base/overlay sprites.
- Eliminate visible clipping and unsupported combinations.
- Balance cost, unlock, durability, and physical effects.

## Validation Gates

A batch cannot merge unless all checks pass:

- Exactly 16 runtime body slices per vehicle.
- Identical canvas size and origin across all slices and overlays.
- PNGs are RGBA, nearest-neighbor safe, and contain no partial-alpha edge pixels unless explicitly whitelisted.
- Showroom sprite is 256×96 and uses the common baseline.
- Declared vehicle ID matches folder and manifest names.
- Dimensions match the simulation JSON within defined tolerance.
- Wheelbase and axle anchors align with visible wheels.
- No real logos, badges, sponsor text, or copied liveries.
- No placeholder, prompt image, label, or checkerboard background shipped as art.
- Paint masks do not recolor lights, tires, glass, trim, or transparent pixels.
- Headlights, brake lights, reverse lights, and turn signals work independently.
- Front wheels steer; tire wear/blowout states remain visible.
- Front/rear bumpers can detach and leave sensible underlying geometry.
- Directional dents, scrapes, primer, broken lamps, and cracked glass still work.
- Parts do not clip at supported ride heights, tracks, and steering angles.
- Existing simulation, counter, world, and traffic tests still pass.

## Review Checklist

- Does the silhouette communicate class and era at 1× size?
- Is it recognizable as a playful category parody without copying protected identity cues?
- Is it distinct from every existing vehicle in the same class?
- Does it fit the Port Rumble setting and traffic mix?
- Are body lines intentional rather than AI noise?
- Are wheels circular and aligned on a common baseline?
- Are glass, pillars, lights, and panel gaps readable?
- Do all 16 runtime slices rotate without shimmer or origin drift?
- Are customization parts genuinely interchangeable within the declared archetype?
- Do performance changes affect physical parameters and remain balanced?

## Repository Safety

- Work on a feature branch and open a pull request; never dump thousands of unreviewed files directly onto `main`.
- Commit in batches of five vehicles or one shared part family.
- Keep generated contact sheets separate from source art.
- Do not commit AI prompts, source reference photos, scraped images, or files without clear usage rights.
- Do not replace working procedural rendering until the modular pipeline matches its lights, damage, steering, and performance.
- Git LFS may be considered only after measuring repository growth; optimize indexed-color PNGs first.
- Never claim “300 cars complete” based on manifests or recolors. A recolor is not a new vehicle.

## Definition of Done

The expansion is complete only when the manifest reports exactly 300 approved vehicles, the asset validator reports at least 8,220 valid base/overlay sprites, every class and era quota is satisfied, all vehicles render in showroom and runtime views, customization combinations pass clipping tests, performance upgrades modify simulation data correctly, and all existing game tests pass.
