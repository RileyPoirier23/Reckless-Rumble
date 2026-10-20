# Runtime stacks: the top-down car art

Every car in the world is drawn top-down as a **stack of horizontal slices**, one pixel apart,
rotated to the car's heading and lifted one screen pixel per slice (`render/car_view.gd`). Until
now the slices were always painted by code (`render/car_art.gd`, "the painter"). This folder
lets an artist replace them: drop PNGs into `runtime/<vehicle_id>/` and the game draws them, no
code change needed.

`tools/export_runtime.gd` has already written every car's folder from the painter, so each one
starts as an exact copy of what the game draws today. Paint over those files; don't start from
nothing.

## When the game uses the files

CarArt reads `runtime/<vehicle_id>/` instead of painting when **all** of these are true:

- the car is **stock**: no mods except the cosmetic keys `PixCars.showroom()` allows (`year`
  only when it's the car's own year, `shadow`, `lights_on`, `glow`). Any garage part, tint,
  finish, livery, stance, wear, dirt or decal sends the car to the painter;
- it is **undamaged**: every side's damage is 0. A dent, a knocked-off bumper or a broken lamp
  is the painter's job (it reads the plan, not your pixels);
- it is drawn at the game's scale (`CarArt.CAR_SCALE`). The garage's big preview draws at
  other scales and still uses the painter;
- it isn't a semi's trailer;
- if the folder has `masks/mask_lightness.png`, the paint is about as light as factory grey
  (luminance between 0.55 and 0.7, `CarArt.AUTHORED_LUM`); see the lightness mask below;
- the car's plan is the one in `plan.txt` (the car's catalogue shape, sizes and art cues: a
  spec with the same name but another shape is still the painter's). A folder without
  `plan.txt` is used for any car with that name;
- `body_00.png` exists, every `body_NN.png` is the same size, that size is the car's plan
  canvas (see below), and `wheel_00.png` exists. If any of this is wrong the painter draws the
  car and a warning names the file.

The folder is read once per car the first time it's drawn (on the worker thread that draws
cars), then kept. Restart the game, or call `CarArt.clear_stacks()`, to pick up new files.

## The folder

```text
runtime/<vehicle_id>/
  body_00.png .. body_NN.png        one per slice, bottom (00) to top
  wheel_00.png .. wheel_NN.png      the steerable front wheel's own stack
  plan.txt                          the plan the exporter drew the slices for (leave it)
  masks/
    mask_paint.png                  which pixels take the body paint (a strip, see below)
    mask_lightness.png              pixels the painter colours by how light the paint is (some cars)
    mask_head.png                   headlamps, lit
    mask_brake.png                  brake/tail lamps, lit
    mask_reverse.png                reversing lamps, lit
    mask_signal_left.png            left turn signals, lit
    mask_signal_right.png           right turn signals, lit
    mask_beacon.png                 emergency beacons, lit (only cars that have them)
    mask_lightbar.png               an LED roof bar, lit (only cars that have one)
  detachable/
    front_bumper_NN.png             the pixels that go when the front bumper is knocked off
    rear_bumper_NN.png              and the rear
```

`<vehicle_id>` is `PixCars.art_id(spec)`: make, model and year in lower snake case, e.g.
`nissun_silvio_1991`, `dodgy_charjer_r_t_2015`.

## Canvas, origin, axes

- **Every body slice has the same canvas**: the car's plan size, `CarArt.size`. That is the
  car's length plus 4 px each end (`CarArt.MX`) by its width plus 3 px each side
  (`CarArt.MY`), at **15 px per metre** (`CarArt.PX` = 12, times `CarArt.CAR_SCALE` = 1.25:
  the world draws cars a quarter bigger than life). A Silvio is 76 x 32.
- **Origin**: the canvas centre is the car's centre. Slices are drawn centred, so nothing
  can be moved by padding; keep the canvas exactly the size the exporter wrote.
- **Front is +x** (the right edge of the image) in every slice. **+y is the car's right side.**
- **Slice order**: `body_00` is the ground (the undercarriage, the bottom of the tyres), each
  next slice one step up, the last one the top of the roof, wing or rack.
- **How many slices**: as many as the car stands tall. A metre of car is 0.8 px of stack per
  pixel of length (`CarArt.RISE`), so it's height x 15 x 0.8: a coupe is 16, a family
  sedan 18 to 20, a pickup about 24, a box truck or a bus 37 to 46. The production spec's
  "16 slices" is the Silvio's count, not every car's; the game draws whatever number of
  `body_NN.png` files is there, counting up from 00 until one is missing.
- **Transparent pixels are transparent black** (0, 0, 0, 0), so nothing halos at the edges.
  Opaque pixels are fully opaque.
- The **back wheels** are part of the body slices. The **front wheels are not**: they're in
  `wheel_NN.png` so they can steer. Leave the front wheel wells empty in the body slices.
- 8-bit RGBA PNG, no colour profile or text needed.

## The paint mask

`masks/mask_paint.png` is **one strip** as long as all the slices side by side: slice `z` is at
x = z x canvas width (the same layout as `CarArt.atlas`). A pixel takes the car's paint where
the mask's alpha is 255; elsewhere the body slice's own colour is used as it is (glass, trim,
chrome, lamps, tyres, stripes).

- **Red** picks the paint value, 0 deep shadow to 6 specular, written as `round(value x 255 / 6)`:
  0, 43, 85, 128, 170, 213, 255 (base paint is 128). These are `CarGen.ramp()`'s seven values
  for whatever colour the car is sprayed.
- **Green** picks how the painter darkens that value (`CarArt.paint_ops()`): 0 is the value as
  it is. The exporter writes the exact op the painter used (rim lines, shut lines, risers, the
  sill toward the trim, the bottom row toward the ink) so the copy is pixel-identical. When you
  paint by hand, leave green at 0 and pick the shade with red.
- Blue is unused (0).

The body slices themselves are in factory grey (`#8a8e94`) so you can see the shading; the
mask, not the grey, decides what the paint does.

## The lightness mask

Some cars carry colours the painter picks by how light the body paint is: a racing stripe
(dark on light paint, light on dark), a 50s two-tone's second colour, a vinyl roof (cream on
dark paint), the black floating roof of some late cars (off on very dark paint). The files can
only hold the factory-grey choice, so the exporter marks those pixels in
`masks/mask_lightness.png` (a strip like the paint mask, opaque white where it applies). While
that file is there, the game uses the stack only for paints in factory grey's band and lets the
painter draw the car in the others, so nothing changes colour. 53 of the 509 cars have one.

If you've painted the stripes or the roof the way you want them in every colour, delete
`mask_lightness.png` and your stack is used whatever the paint.

## The lamp masks

Each `mask_<lamp>.png` is a strip laid out like the paint mask. Its opaque pixels are what
lights up, **in the colour they light**: they're drawn over the car, unshaded, when that lamp
is on (headlamps with the lights, brake lamps when braking and dimmer with the lights, the
signals as they blink). The unlit lens belongs in the body slices. The glow round each lamp
at night comes from where these pixels are, left and right, front and back kept apart.

## The wheel

`wheel_NN.png`: one slice per file, bottom to top, all the same canvas: the wheel's length
along the car by its width, rim face toward **+y** (the game mirrors it for the left wheel).
The game places it at the plan's front axle and turns it with the steering.

## The detachable bumpers

`detachable/front_bumper_NN.png` and `rear_bumper_NN.png` are on the body's canvas and slice
numbers; only slices with bumper pixels have a file. They hold what goes when the bumper is
knocked off: the bumper that juts past the body, and the face below the bumper line that the
game shows as a dark hole. The game doesn't read them yet (a damaged car is the painter's);
they're the reference for the crash debris and for the parts library.

## Exporting and checking

```sh
# every car (writes game/art/vehicles/runtime/, replacing what's there)
godot --headless --path game -s tools/export_runtime.gd
# some cars, somewhere else (catalogue ids or vehicle ids)
godot --headless --path game -s tools/export_runtime.gd -- /tmp/stacks silvio charjer
# the loader against the painter
godot --headless --path game -s tests/runtime_art_tests.gd
```

The exporter overwrites the folders it writes, hand-painted files included: export somewhere
else and copy over what you need if you've already painted a car.

Run the vehicle-art validator (`tools/validate_vehicle_art.gd`) before committing; it checks
names, canvas sizes, slice counts, transparent padding and missing files against this layout.
Then drive the car in the game: a stock one, in a few paints, with its lights on and off.

## What a stack can't carry yet

The painter still does these, so a hand-painted stack gives way to it:

- garage mods (spoilers, kits, wheels, tint, finish, liveries, stance, lights) and the traffic's
  dirt, salt and rust;
- crash damage: dents, crumple, broken lamps, cracked glass and the knocked-off bumpers;
- the paint's finish: the stack is shaded for gloss;
- the colours the painter picks by how light the paint is (see the lightness mask): in paints
  outside factory grey's band those cars are still the painter's;
- a second paint colour: only the body paint is mask-driven (no accent, trim, glass or decal
  masks yet).
