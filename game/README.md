# DriveBoss: prototype

Two slices of the game, picked from the title screen:

- **The counter:** the first month of shifts at Covington Auto, Papers, Please style.
- **The lot:** free drive from Covington Auto out to Salisbury and Havelock. Four cars (a 1991 Nissun Silvio: 2.0 turbo, rear-wheel drive), two blocks of Port Rumble around Covington Auto, four seasons, day and night. Everything you see is drawn by code; nothing is an image file.

These are steps 1 and 2 of the build order in [the concept](../DRIVEBOSS_CONCEPT.md): find out if the driving and the counter are fun before anything else gets built on them.

## Run it

- **Downloads:** each push builds Windows, Mac and Linux versions. On GitHub, open the **Actions** tab, then the latest **DriveBoss build** run; the downloads are under **Artifacts**.
- **From source:** open the `game` folder in Godot 4.5 and press Play.

## The map

Port Rumble (our Moncton) to Salisbury and Havelock, laid out from the real geography at about 1:8:
- **Rivers and roads:**
  - The Petitcodiac runs brown past downtown, crossed by the Causeway and the Gunningsville Bridge.
  - Route 106 (Main St, then Salisbury Rd) runs along the north bank, and Route 112 (Coverdale Rd) along the south bank.
  - The Trans-Canada passes Magnet Hill and comes down to Salisbury, and Route 880 winds out to Havelock.
  - The CN line has level crossings in town and in Salisbury.
- **Neighbourhoods:** downtown, Covington Corner, the North End, Riverside, Dieppe and Northside Industrial, each with its own street grid, buildings and lighting.
- **Landmarks:**
  - Covington Auto, the Rumble Centre, Tidal Bore Park, Champagne Place and Airstrip 7.
  - Magnet Hill, where the car rolls "uphill" if you let it, and the casino.
  - The Big Stop, the Lutes Mountain towers, the Havelock airfield and the lime quarry.
  - A Tim Burtons on every corner.
- **Country:** farms with barns and yard lights, spruce and maple woods, and fields that change colour with the seasons.

The world streams in 64 m chunks around the camera, so it's all one drive with no loading.

## Time, weather and light

- **Clock:** a day is 24 minutes (one game minute per second). Sunrise and sunset follow Moncton's for each season, from 4:35 p.m. sunsets in winter to 9 p.m. in summer.
- **Weather:**
  - The weather changes on its own: clear, overcast, drizzle, rain, thunderstorms, fog, snow, blizzards and freezing rain, with odds that depend on the season.
  - Rain soaks the road (puddles), sun dries it, snow piles up (the highway gets plowed first), and freezing rain and cold nights leave black ice.
  - The tires feel all of it.
  - Clouds cast moving shadows, fog closes in, and lightning flashes.
- **Lighting by area:**
  - **Streets:** orange sodium in the old neighbourhoods (some buzz, some are dead), cold LEDs downtown and in the new suburbs, high-mast lights at the highway exits, blue bridge lights.
  - **Businesses:** neon shop signs that flicker, gas-station canopies, the casino's colour sweep, blue runway lights.
  - **Farms:** blue-green mercury yard lights and porch lights.
  - **Traffic and towers:** traffic signals that cycle, railway crossing flashers, and red tower beacons.
  - **Windows** light up after dark.

## Traffic

The other drivers follow the lanes (right-hand traffic) and keep a safe gap to whatever is ahead of them, including you. They use the Intelligent Driver Model, which brakes harder the faster a gap closes. Through junctions they drive a curved path from their lane in to the right lane out. The rules:
- **Traffic signals:** where two big roads cross in town. The main road gets the long green, and the light you see is the light they obey.
- **Two-way stops:** the smaller street stops and waits for a gap in the main road.
- **All-way stops:** downtown and in the village centres. First to stop goes first.
- **Lanes and turns:** left turns wait for oncoming traffic, and on multi-lane roads right turns come from the right lane only.
- **Don't block the box:** nobody enters an intersection without room on the other side.

Cars spawn out of sight around you, and there are more downtown and at rush hour, fewer at 3 a.m. They signal before turns, show brake lights and use headlights at night.

## Crashes

Damage is tracked per side (front, back, left, right):
- **Dents** crumple the side you hit.
- **Scrapes** along a wall take the paint down to primer.
- **A hard hit** takes the bumper right off, and it skids down the road with a shower of glass.
- **Lamps** break on the corner that hit, so a headlight or tail light goes out.

Hit a traffic car and the impact is shared by mass. It slides and spins, then puts its hazards on and either gets back in its lane or waits for the tow truck.

## The garage

Pull up to Covington Auto's bay doors and stop: the garage opens. Pick which car to take out, or have Gus fix one up. Your cars, their paint and their damage are saved (`user://driveboss_save.json`).

## Cars, dashes and GPS

Each car has its own instrument cluster and its own GPS, with day and night looks:

| Car | Dash | GPS |
|---|---|---|
| 1991 Nissun Silvio (Leo's) | 90s analog needles, orange backlight at night | A cheap suction-cup TomTum |
| 1986 Toyoda Supreem | 80s digital VFD bar graphs | Leo's cracked phone (loses signal in the country) |
| 2015 Dodgy Charjer R/T | Modern screen with rings | Built-in dash screen, dark and red, tilted |
| 2008 Fjord F-One-Fiddy wrecker (Toby's) | Big chrome truck gauges, tow lights | A rugged orange trucker unit, north-up |

Open the map (Tab or Back on the controller), pick a place, and the GPS routes you there with turn arrows and the distance left.

## The counter

October 7 to November 1, 2019: four weeks of shifts (closed weekends and Thanksgiving Monday). On the first brief, LB/RB (Q/E) picks the week to start in. Each customer brings papers:
- a work order;
- a registration;
- a driver's licence;
- proof of insurance;
- Gus's sheet, read off the actual car (the door-jamb VIN joins it in week three);
- and, as the rules arrive, a service history, last province's ownership, a structural certificate.

**The shift.** The wall clock runs 8:00 to 6:00 in ten real minutes. Customers line up in the lot (you can see them through the bay door). Spend more than an hour and a half with one and the next one leans on the horn. At six, whoever's still waiting drives off, and the day-end screen shows the money that went with them.

**The rules grow.** Week one adds a rule a day, a stolen list on Thursday, the Familia's napkins and, on Friday, somebody asking for "new numbers" who isn't who he says he is. From week two the bulletin is a binder with tabs (Inspection, Documents, Police, Ministry, Seasonal): odometers only go up, a dated bill of sale covers a name mismatch, door-jamb VINs, temporary permits, out-of-province cars need the full inspection, salvage brands need a structural certificate (and a brand that vanished between provinces gets reported), and on Halloween the masks come off.

- **Inspect** (I, Y or right-click), then pick two things to compare them: a VIN against a VIN, a name against a name, a date against the calendar, the licence photo against the face, a plate against the stolen list, a reading or a paper against a rule in the binder, a service reading against the odometer.
- **ASK** (A or X, or click the question). A red verdict puts a question under the customer's speech bubble. Most answers are lies. Some customers pull a paper out of a pocket (a bill of sale, a permit, the pink card from the glovebox, a body shop invoice, a structural certificate) that makes the discrepancy fine, if that paper checks out too. Small talk is always on the list; people from here know which Tim's they go to.
- **Stamp the work order:** APPROVE (1), DENY (2), REPORT to the police (3), or BAY 3 (4) for off-the-books work.
- **Mistakes:** the first two a shift are Ministry warnings. After that each one is a $100 citation (police matters cost more and are never warnings). Twelve citations, or a third Ministry meeting, and the station loses its licence.
- **Leo's notebook** (N or D-pad up): inspect what somebody said, then the notebook, and Leo writes it down. **The sticker log** (L or D-pad down) lists every sticker you've issued; in the last week, last fall's pages turn up, and they're worth reading closely.
- **Scripted customers** come from `data/story_customers.json`: Dale Hatch the Wednesday after Thanksgiving, Darrell's trade-in a week later, the Familia's cars on Thursdays. A story step can bring its own (`"customers": [...]` on a counter step); stamps set story flags (`desk_<id>_<stamp>` plus the outcome's own), and so do notes (`desk_note_<id>`).
- **Friday night:** rent, Gus's pay, Aries's hockey and the Familia's cut all come due.

Drag the papers around with the mouse; with the arrow keys and Space; or with the left stick and A on a controller (D-pad left/right jumps the cursor to the next thing). B or Backspace cancels; Esc or Back returns to the menu.

## Controls (the lot)

The camera sits behind the car and turns with it, so up is always ahead. Time, weather and seasons run on their own (a day is 24 minutes, a season about 4 days), and you change cars in the garage.

| | Keyboard | Controller |
|---|---|---|
| Gas / brake | W / S (or arrows) | RT / LT |
| Steer | A / D | Left stick |
| Handbrake | Space | B |
| Shift up / down (manual) | E / Q | RB / LB |
| Automatic / manual | G | |
| Blinkers | Z / C | D-pad left / right |
| Hazards | V | D-pad down |
| High beams (tap) / flash (hold) | B | D-pad up |
| Horn | H | X |
| Garage (at Covington Auto's bay doors) | F | Y |
| Map and GPS route | Tab / M | Back |
| Tow it home | R | |
| Hide the controls | F1 | Start |
| Back to the menu | Esc | |

On the controller the stick has a response curve (small movements, small corrections), and the default STREET assists add traction control and a little stability control. Blinkers cancel themselves after the turn.

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
godot --headless --path game -s tests/desk_tests.gd
godot --headless --path game -s tests/world_tests.gd
godot --headless --path game -- --traffic-test
```

The map, sky and car tests check that:
- the map builds quickly;
- the GPS can reach every destination;
- no building sits on a road;
- the day/night cycle and lights work in every season;
- rain, sun, snow and freezing rain change the road;
- all four cars draw and drive sensibly.

The counter tests (`counter_tests.gd`, four weeks of rules) prove that:
- every problem the game puts in the papers can be found again from the papers alone;
- every problem type can be proven from the desk with the inspect tool, under its own ASK question;
- a clean customer never shows red, and a covered one only shows the red its proof explains;
- an exception holds only while its proof checks out (spoil the proof and the problem's back);
- warnings, fines, the binder, the shift's arrivals and the scripted customers behave.

The desk tests (`desk_tests.gd`) run the counter scene itself: the shift clock ends the day at six, a line builds and honks, whoever's left drives off, ASK hands over proofs and takes off masks, the notebook and the sticker log (and its gap) work, every desk action has a key and a pad button, and every prompt comes from `Hints`.

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
| `world/player_car.gd` | Input, collisions, tire marks, smoke and steam |
| `ui/hud.gd` | The dashboard |
| `render/engine_audio.gd` | The engine and tire sounds, made live from the sim |
| `data/cars/silvio.json` | The car itself: weight, torque curve, gears, brakes, tires |
| `counter/rules.gd` | The counter's rules: customers, papers, problems, comparisons, ASK answers and proofs, the binder, the shift's arrivals, stamps, warnings and pay. No drawing |
| `counter/counter_scene.gd` | The counter: the shift clock, the line in the lot, desk, documents, inspect, ASK, stamps, the binder, the books, the day and the week |
| `counter/desk_book.gd` | Leo's notebook, the sticker log and the Ministry's tally; rides along in the story save |
| `data/story_customers.json` | Scripted customers (Dale Hatch, Darrell, the Familia's cars) and the days they come in |
| `counter/face.gd` | Faces drawn pixel by pixel from a seed, for customers and licence photos |
| `title.gd`, `drive.gd` | The title screen and the free-drive scene |
| `world/map_data.gd` | The map as data: roads, river, rail, zones, buildings, lights, landmarks, GPS routing |
| `world/world.gd` | Streams the map in chunks and draws it in layers |
| `world/sky.gd` | The clock, the sun, the weather and what it leaves on the road |
| `world/light_pool.gd` | Hands real lights to the nearest of the map's 1,200 light sources, with each kind's behaviour |
| `ui/dash.gd`, `ui/gps.gd`, `ui/map_screen.gd` | The per-car dashes and GPS units, and the big map |
| `world/traffic.gd`, `world/traffic_car.gd` | Traffic: spawning, lanes, the rules at junctions, and each driver |
| `world/debris.gd` | Bumpers, glass and hubcaps that come off in a crash |
| `ui/garage_screen.gd`, `save_game.gd` | The garage and the save file |
| `controls.gd` | Every input action, for keyboard and controller |
