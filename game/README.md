# DriveBoss: prototype

Two slices of the game, picked from the title screen:

- **The counter:** one week of shifts at Covington Auto, Papers, Please style.
- **The lot:** free drive. One car (a 1991 Nissun Silvio: 2.0 turbo, rear-wheel drive), two blocks of Port Rumble around Covington Auto, four seasons, day and night. Everything you see is drawn by code; nothing is an image file.

These are steps 1 and 2 of the build order in [the concept](../DRIVEBOSS_CONCEPT.md): find out if the driving and the counter are fun before anything else gets built on them.

## Run it

- **Downloads:** each push builds Windows, Mac and Linux versions. On GitHub, open the **Actions** tab, then the latest **DriveBoss build** run; the downloads are under **Artifacts**.
- **From source:** open the `game` folder in Godot 4.5 and press Play.

## The counter

Monday to Friday, October 7 to 11, 2019. Each customer brings papers:
- a work order;
- a registration;
- a driver's licence;
- proof of insurance;
- Gus's sheet, read off the actual car.

The Ministry bulletin on the wall adds a rule every day. Thursday brings a stolen list from the police, and the Familia start sending cars with napkins. On Friday someone asks for "new numbers" who isn't who he says he is.

- **Inspect** (I, Y or right-click), then click two things to compare them:
  - a VIN against a VIN, or a name against a name;
  - an expiry date against the calendar;
  - the licence photo against the face at the counter;
  - the plate on the car against the stolen list;
  - a tread or brake-pad reading against the bulletin.
- **Stamp the work order:** APPROVE (1), DENY (2), REPORT to the police (3), or BAY 3 (4) for off-the-books work.
- **Mistakes:** each one is a $100 Ministry citation.
- **Friday night:** rent, Gus's pay, Aries's hockey and the Familia's cut all come due.

Drag the papers around with the mouse, or with the left stick and A on a controller. B cancels; Esc or Back returns to the menu.

## Controls (the lot)

| | Keyboard | Controller |
|---|---|---|
| Gas / brake | W / S (or arrows) | RT / LT |
| Steer | A / D | Left stick |
| Handbrake | Space | B |
| Shift up / down (manual) | E / Q | RB / LB (or A / X) |
| Automatic / manual | G | Y |
| Tow it home (reset) | R | Back |
| Night | N | D-pad up |
| Next season | M | D-pad right |
| Summer / winter tires | T | D-pad down |
| Sim / Street / Arcade assists | P | D-pad left |
| Hide the controls | F1 | Start |
| Back to the menu | Esc | |

**Burnout:** hold the gas and the brake together while stopped. The front brakes hold the car and the rear tires spin.

**Reverse (automatic):** hold the brake at a stop.

## What can go wrong (on purpose)

- **Money shift:** in manual, drop into a low gear at speed and the wheels drag the engine past the limiter. The valves bend. Street assists block the worst of it.
- **Cold engine:** every start is a cold start at the outside temperature. Rev it hard before the oil is warm and it wears.
- **Overheating:** hit something head-on and the radiator gets holed. The coolant leaks, the temperature climbs, and the head gasket goes.
- **Tires:** burnouts and slides eat tread (in millimetres, per tire) and heat the rubber. Run them to the cords and they blow out.
- **Brakes:** they fade when they're hot. On Sim the fronts lock up (no ABS), and locked wheels don't steer.
- **Seasons change the grip:**
  - Fall has wet roads and wet leaves.
  - Winter is -12 °C with packed snow and black ice at the corners. Summer tires are hopeless in it; switch to winter tires.
  - Spring has rain and potholes.

## Tests

```sh
godot --headless --path game -s tests/run_tests.gd
godot --headless --path game -s tests/counter_tests.gd
```

The counter tests (18 checks) prove that:
- every problem the game puts in the papers can be found again from the papers alone;
- every problem can be proven with the inspect tool;
- a clean customer never shows red;
- the stamps pay and fine the way they should.

The driving tests (16 checks) run headless on every push:
- 0–100 km/h and top speed;
- money shift, burnout tread, overheating and cold-engine wear;
- stopping on dry, snow and ice, and winter tires on snow;
- cornering, lift-off and handbrake turns;
- stop-and-go.

## Code

| Folder | What's in it |
|---|---|
| `sim/car_sim.gd` | The physics: tires, engine, clutch, gearbox, heat, damage. No drawing |
| `render/car_art.gd` | Draws the car pixel by pixel as 16 stacked slices |
| `render/car_view.gd` | Stacks and rotates the slices, with body roll, steering wheels and lights |
| `world/city.gd` | The streets, buildings, seasons and the grip of each surface |
| `world/player_car.gd` | Input, collisions, tire marks, smoke and steam |
| `ui/hud.gd` | The dashboard |
| `render/engine_audio.gd` | The engine and tire sounds, made live from the sim |
| `data/cars/silvio.json` | The car itself: weight, torque curve, gears, brakes, tires |
| `counter/rules.gd` | The counter's rules: customers, papers, problems, the bulletin, stamps and pay. No drawing |
| `counter/counter_scene.gd` | The counter: desk, documents, inspect, stamps, the day and the week |
| `counter/face.gd` | Faces drawn pixel by pixel from a seed, for customers and licence photos |
| `title.gd`, `drive.gd` | The title screen and the free-drive scene |
| `controls.gd` | Every input action, for keyboard and controller |
