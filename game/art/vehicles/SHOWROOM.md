# Showroom sprites: the contract

Every car in the game has a side-view showroom sprite here: `showroom/<art_id>.png` and its
paint mask `showroom/masks/<art_id>_paint.png`. They start out exported from the procedural
painter (`render/car_gen.gd`), so every catalogue car has a real file from day one. An artist
replaces a car by overwriting its two files; nothing else needs to change.

## Names

`<art_id>` is `<make>_<model>_<year>` in lower-case snake case, exactly what
`PixCars.art_id(spec)` makes from the car's spec: `nissun_silvio_1991`,
`fjord_f_one_fiddy_wrecker_2008`, `toyoda_supreem_1986`. For a catalogue car it is the same as
its catalogue id; for the hand-made cars in `data/cars` it is not (`silvio` is
`nissun_silvio_1991`). The export covers every `CarCatalog.ids()` and `fleet_ids()` car plus
any `data/cars` JSON the catalogue doesn't list (the ambulance and the fire engine): 509 cars.

## The sprite

| | |
|---|---|
| Canvas | 256 x 96 px, RGBA, 8-bit, IHDR/IDAT/IEND only (no text, gamma or colour-space chunks) |
| Facing | right: the nose at the larger x |
| Baseline | the lowest opaque row of the tyres is **y = 78**, for every car. Nothing is drawn below it. |
| Footprint | everything inside x 16..239, y 3..78 (224 x 76), centred on the canvas; the rest is transparent padding |
| Pixels | hard edges only: alpha is 0 or 255, and a transparent pixel is transparent black (0, 0, 0, 0) |
| Contour | a one-pixel near-black (`#15181f`) outline round the body |
| Paint | neutral factory grey (`#8a8e94`) in four values: deep (the underbody's two-pixel shadow and the darkest creases), shadow, base and highlight. Glass, trim, rubber, lamps and chrome keep their own colours. |
| Not in the file | labels, ids, floor shadows, UI frames, class text. Labels live only on the contact sheets. |

### Scale

One scale for every car, so a kei car is small next to a dually: **26 px per metre** of the
car's length (`PX_PER_M` in `tools/export_showroom.gd`). At that scale the 8.3 m stretch limo
fills the 224 px footprint and a 2.5 m high-roof van fits under the 76.

The big rigs (body `bus`, `semi`, `boxtruck`: the buses, the semis, the box trucks, the step
vans, the ambulances, the fire engine) can't share it and stay inside the footprint (a city
bus is 12.2 m, a sleeper cab 4 m tall), so they share a second scale of their own,
**18 px per metre** (`BIG_PX_PER_M`). Keep to these when drawing a replacement, so the car
stands the right size next to the rest of its group.

## The paint mask

`masks/<art_id>_paint.png` is the same 256 x 96 canvas. A pixel the player's paint should
colour is opaque grey; every other pixel (glass, tyres, lamps, trim, chrome, background) is
transparent. The grey picks which paint value that pixel takes, the way
`PixCars.authored()` reads it (by the red channel):

| Grey written | Read as (`r`) | Paint value |
|---|---|---|
| 31 (`#1f1f1f`) | below 0.25 | deep |
| 95 (`#5f5f5f`) | 0.25 to 0.5 | shadow |
| 159 (`#9f9f9f`) | 0.5 to 0.75 | base |
| 223 (`#dfdfdf`) | 0.75 and up | highlight |

The four values come from `PixCars._palette(paint, "gloss")`: base is the paint, highlight
30% lighter, shadow 30% darker, deep 55% darker. In the exported files the sprite's painted
pixels are exactly those four values of the factory grey, so a sprite recoloured through its
mask in factory grey gives back the file. Paint only body panels: a masked lamp, tyre or
window would be recoloured with the body.

## Who wins

`PixCars.showroom(spec, len, paint, mods, dmg)` uses the file when the car is stock and
undamaged (the only mods allowed are the cosmetic `year`, `shadow`, `lights_on`, `glow`):
it loads `showroom/<art_id>.png`, recolours the masked pixels in the car's paint, and crops the
canvas to 86 rows (the baseline plus 8, the framing `PixCars.image()` uses). The garage does
the same through `PixCars.authored()`. A modded or damaged car, or a car with no file, goes
back to the painter. So a file in this folder always wins over the painter for a stock car:
whether it came from the exporter or from an artist makes no difference to the game.

Re-running the export **overwrites** every file it writes. Once a car has hand-made art, leave
it out of the export (pass the ids you want instead, below) and keep the artist's file.

## Re-running

From the repository root, with Godot 4.5 (headless is fine):

```sh
# every car, into game/art/vehicles/showroom (+ masks/)
godot --headless --path game -s tools/export_showroom.gd

# just some cars (catalogue ids or art ids), or somewhere else
godot --headless --path game -s tools/export_showroom.gd -- silvio fjord_f_one_fiddy_2015
godot --headless --path game -s tools/export_showroom.gd -- /tmp/showroom_try nissun_silvio_1991

# the review sheets, from whatever is in showroom/ now
godot --headless --path game -s tools/build_contact_sheets.gd
godot --headless --path game -s tools/build_contact_sheets.gd -- <out_dir> <showroom_dir>
```

The export checks each sprite against the canvas, the baseline and the footprint, prints any
car that breaks them as `OFF CONTRACT` and exits non-zero. After adding or changing files, run
`godot --headless --path game --import` once so the game picks them up as textures.

## Contact sheets

`contact_sheets/era_<decade>_NN.png` (1950s to 2010s) and `contact_sheets/class_<class>_NN.png`
(the catalogue's classes): 24 cars a sheet on a dark field, oldest first, each on its own
canvas with the footprint marked a shade lighter and a faint line one row under the baseline
(a wheel that floats or sinks shows against it). Under each car: its art id, year, make and
model, and its class, body and the archetype it would most likely take (a review hint, not a
manifest). The sheets are drawn from the files in `showroom/`, not from the painter, so they
show what the game will show. They are for review only; nothing in the game reads them.

## Fixing a car that reads badly

The painter is the source: a rule in `render/car_gen.gd` (a family, an era, a detail) fixes
every car it covers, and an entry in its `ICONS` table fixes one well-known car. Fix there,
re-export, rebuild the sheets, and look again. Draw a car by hand only when the rules can't
get it right, and then keep it out of later exports.
