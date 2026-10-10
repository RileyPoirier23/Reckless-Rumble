# DriveBoss: prototype

Two slices of the game, picked from the title screen:

- **The counter:** eight weeks of shifts at Covington Auto, Papers, Please style.
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
  - The Large Stop, the Lutes Mountain towers, the Havelock airfield and the lime quarry.
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

## HOPP-IN rides

A gig on the phone, any time of day. A request comes in from a house nearby; pick them up, take them where they're going (a landmark or another address), and they pay $3.50 plus $1.25 a km. Then they rate you, and five stars tips a fifth:
- **Memere going to bingo** hates being thrown about; **someone late for a shift** only cares that you're quick; **the chatty ones** tell you about their snowblower; **the bar crowd** after ten gets sick in the back if you corner like you, and that's one star and a $50 cleaning fee; **the quiet ones** keep their headphones in and only mind if you hit something.
- Speeding costs stars with everybody but the ones who are late. A run of bad ratings and HOPP-IN takes you off for the rest of the day. Your average shows on the phone.

## Gas

Your car burns fuel by the work the engine does: about 45 minutes of steady highway driving on a tank, a lot less flat out. The FUEL light comes on under a seventh of a tank, and the dash gauges show what's left. Fill up at the pumps at the Gas Bars, the Ultramarge in Dieppe or the Large Stop (they're on the GPS): regular at $1.62 a litre, premium at $1.89, or twenty bucks' worth. Premium keeps a hot tune from knocking (it goes by how much of what's in the tank is premium). Run dry and the car coughs and stops; Toby brings a jerry can for $60. Each car's fuel is saved with it, and nobody else's car ever runs out.

## Moose and deer

Only on the wildlife stretches, marked with yellow crossing signs at each end: moose country up Lutes Mountain, Irishtown, the Canaan woods, Route 112 north and the Trans-Canada through the woods, and deer country along Berry Mills, Boundary Creek, Scotch Settlement, Parkindale and Route 106 south. Never in town, in a village or on the city end of the highway. There they come out at dusk and dawn, and all night, more in the fall when the moose are in rut. A deer at the roadside bolts across when you come up on it; a moose walks out and stands in the road looking at you. The horn moves them along. Their eyes shine in your headlights: a deer's at bumper height, a moose's too high for low beams to catch, so use your high beams. Hit a deer and it's a bent bumper (it gets up and limps off); hit a moose at more than about 55 km/h and it comes through the windshield, with its own death-screen captions.

## Street races and the police

- **Street races** (GIGS, 10 p.m. to 4 a.m.): Marco runs one route a night: the Main Street Mile, the Downtown Box, the Riverside Loop or the North End Sprint. Pay the buy-in and line up with three locals in cars about as quick as yours (matched on horsepower per tonne). Hit the checkpoints in order; the GPS shows the next one. The winner takes the pot, less Marco's tenth.
- **Street rep:** a win is worth one, a pink-slip win two, a loss nothing, and not finishing costs one. Marco only lets you into the bigger routes once people know your name (the Riverside Loop at 1, the Downtown Box at 3, the North End Sprint at 5); until then you get the best one you've earned. The phone shows tonight's race and your rep.
- **Pink slips:** at rep 6, Friday and Saturday nights are one on one down the Main Street Mile against a ladder of five rivals, each in a quicker car than the last, up to the King of Main Street. Win and their car is in your garage. Lose and they drive home in yours, and Marco's cousin drops you at Gus's in whatever you've got left. You can't bet Toby's wrecker or your only car.
- **The other racers** drive the same physics as your car. They follow the route, brake for the corners they can see coming, go round slower traffic when the road is wide enough, follow it when it isn't, and back out when they get stuck. The leaders lift a little and the stragglers try harder, so it stays close.
- **The police** (Port Rumble Police, white Dodgy Charjers with a light bar) patrol at the limit. Go 20 km/h over, or race, where one can see you and they light you up. Pull over and Constable Tremblay writes the ticket. Keep going and it's a chase: the heat climbs and more cars join. Stay out of their sight for 14 seconds and they lose you. High heat, racing or a long chase gets the car impounded.
- **Heat** shows above the GPS and cools off slowly. Tickets are $100 plus $8 for every km/h past 15 over, doubled at 50 over (stunt driving). Racing adds $1,500, running $1,000, and hitting a police car $800. The impound is $450 more.
- Cruisers show on the GPS (flashing when they're after you), and so do the other racers.

## Crashes

Damage is tracked per side (front, back, left, right):
- **Dents** crumple the side you hit.
- **Scrapes** along a wall take the paint down to primer.
- **A hard hit** takes the bumper right off, and it skids down the road with a shower of glass.
- **Lamps** break on the corner that hit, so a headlight or tail light goes out.

Hit a traffic car and the impact is shared by mass. It slides and spins, then puts its hazards on and either gets back in its lane or waits for the tow truck.

## The garage

Pull up to Covington Auto's bay doors and stop: the garage opens. Pick which car to take out, or have Gus fix one up. Your cars, their paint and their damage are saved (`user://driveboss_save.json`).

## The meet

Friday and Saturday nights from 10 (it's on the GIGS app), the back row of the Champagne Place lot fills up: six locals and a spot with your name on it ($20 to get in, for the organizer's tire fund). Park in it, nose in or backed in (backing in earns a nod). For forty seconds the crowd looks it over: the gas revs it (the car's out of gear with the handbrake on), and a louder exhaust gets them going faster, but rev it too long and they've heard enough. Pop the hood with the use key, or they'll only half-believe what's under it. Then the votes: how it looks (paint finish, wheels, the drop, tint, stripes, wing, kit, tips), the build (the stages of everything bolted on), dents, what the car's worth, the night's theme (JDM, muscle, euro, classics, stance night where the drop and wheels count double, sleeper night where looking fast counts against you), and the hype. $250 for best in show and a bump in street rep, $100 and $40 for second and third, $50 for the loudest. Leave with a burnout and the crowd loves it; the patrol car on Melanson Rd might not.

## The impound auction

Saturdays from 10 to 2, the Northside impound lot (on the GPS; it's also where the police tow you) sells what nobody came back for: four lots, as is, where is, no test drives and no looking under them. Pull up to the booth. Lyle opens each lot at about a fifth of what it's worth and takes bids in steps ($50, then $100 over $1,000, $250 over $5,000); Darrell, a dealer from Shediac and a guy in a trucker hat bid against you, each up to his own limit. Three calls with no new bid and it's sold. A street racer's seized car still has his parts on it, some lots have no keys ($250 for the locksmith), and whatever the car's hiding (a head gasket, a slipping clutch, a rolled-back odometer) comes with it. Walk away and the lot on the block goes to whoever wanted it most.

## Northside Salvage

Lloyd's yard in Northside Industrial (on the GPS) is open 8 to 6: pull up to the trailer and stop. Every day there's a new pile: six used parts, graded A to D at 55% down to 16% of new, and three worn bits (a clutch, a turbo, a motor, a set of tires, brake pads) his nephew swaps on the car you came in, right there, for $40 and an hour or two. The panel says whether a part fits your car, and how much life a worn bit has left next to yours. Used parts go to Covington's on the yard truck an hour later, and that's when Gus opens the box: an A is always good, but the worse the grade, the better the odds it's cracked, seized or for a boat (a D is about a coin flip). No refunds. Lloyd also buys whatever's sitting on Gus's bench, for a fifth of new.

## MarketThing

The used-car app on Leo's phone (GIGS, then the shoulder buttons):
- **BUY:** a new batch of listings every morning off the catalogue. Sellers lie (or don't), you haggle in the chat, and then you meet them in a parking lot. Touch the hood, pull the dipstick, put the creeper light under it and take it for a test drive before you hand over cash. Every hidden fault shows up in at least one check.
- **SELL:** put one of your own cars up at a price you pick. Gus tells you what it's worth (age, kilometres, what's worn out, dents, plus a bit for the parts you put on). Answers come in by the hour: Brandon lowballs, the dealer offers fast and low, Nathalie is fair, Trevor needs his dad to see it, Gerald only asks questions, and Jay-P wants to trade a sled. A fair price gets bites; a dreamer's price gets Gerald, and nobody writes at four in the morning. Take an offer and the buyer picks the car up at Gus's. If someone offers over asking by certified cheque, the car leaves and the cheque bounces. You can't sell the car you're driving, your last car, or Toby's wrecker.

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

October 7 to November 29, 2019: eight weeks of shifts (closed weekends, Thanksgiving Monday and Remembrance Day), and then overtime. On the first brief, LB/RB (Q/E) picks the week to start in, or OVERTIME after week 8, and next to it R (Menu/Options on a controller) puts the wall clock on the relaxed pace. Each customer brings papers:
- a work order;
- a registration (in week eight it says what the car's for: private, taxi, rideshare or commercial);
- a driver's licence;
- proof of insurance;
- Gus's sheet, read off the actual car (the door-jamb VIN joins it in week three, the light meter for window tint in week five, the sound meter for the exhaust in week six, the serial off a part that went on somewhere else from week six, and the tires in week eight);
- and, as the rules arrive, a service history, last province's ownership, a structural certificate, a parts invoice.

**The shift.** The wall clock runs 8:00 to 6:00 in ten real minutes (fifteen on the relaxed clock). Customers line up in the lot (you can see them through the bay door). Spend more than an hour and a half with one and the next one leans on the horn. At six, whoever's still waiting drives off, and the day-end screen shows the money that went with them.

**The rules grow.** Week one adds a rule a day, a stolen list on Thursday (Constable Tremblay brings a new one every week after that, and the corkboard says which week it's for), the Familia's napkins and, on Friday, somebody asking for "new numbers" who isn't who he says he is. From week two the bulletin is a binder with tabs (Inspection, Documents, Police, Ministry, Seasonal): odometers only go up, a dated bill of sale covers a name mismatch, door-jamb VINs, temporary permits, out-of-province cars need the full inspection, salvage brands need a structural certificate (and a brand that vanished between provinces gets reported), and on Halloween the masks come off.

**Weeks five to seven.** Front side windows must let 70% of the light through (a Ministry medical exemption covers it, for that driver and that car). Gus opens an account with Fundy Parts Supply, and **the courier** comes to the window with the bay's parts: sign for a box only if the packing slip matches our order printout (part number and ship-to; a supplier's supersession notice covers a new number), and a box from the States carries a customs form that must declare what we paid. Gus's rules for it are on a PARTS tab he taped into the binder. Sign for a wrong box and it costs the shop a restocking fee or the broker's penalty, not a citation; refuse a right one and the job waiting on it waits. After Remembrance Day the exhaust rule arrives (no holes, 95 dB at 3,000 rpm), and some Thursdays the Familia's visit is a box for Bay 3. On the Thursday of week six Constable Tremblay adds **stolen part serials** to the police list: a catalytic converter, an airbag, a set of rims. A car with a part put on somewhere else comes with that part's invoice, and Gus reads the serial off the part itself (the invoice is sometimes one digit off, and clean against the list); Fundy's used shelf ships parts with serials too. A serial on the list, on a car or in a box, is a police matter: REPORT it. Approve it, sign for it or send it away and it's a police fine, never a free warning. Week seven is **the audit**: Inspector Hachey pulls two of your old files a day (at 9:30 and 2:00, ahead of the line), covers the stamp with his thumb, and you stamp the file again, read against the date on it. He pulls walk-ins, the regulars' visits, people who came back and the courier's boxes, each rebuilt exactly from the cabinet. Every file keeps the stolen list it was read against, so a stolen car or part is judged against that week's list, not this week's: while the file's on the desk the Ministry's copy of it is pinned over the corkboard ("STOLEN AS OF NOV 7 - FILE COPY"). The one thing he can't re-check is a licence photo, because the face at the window is long gone. Disagree with your own stamp and it's a citation, even when you're putting it right. Stamp the same wrong call twice and that's consistent: no new citation, but it's on the day-end sheet and in his report.

**Week eight: winter.** The snow sticks on Monday, November 25. Taxis, rideshares and commercial vehicles need winter tires from December 1 to April 30, and the Ministry won't have them stickered on anything else from the 25th; the ownership says what the car's for and Gus's sheet says what's on it. A cab here to get its winters on is the job, not a problem. On Wednesday the stud rule arrives: studded tires October 15 to April 30 only. Read the dates, then the calendar: every day of the run is in stud season, so studs this week are fine (failing them is the wrong call); out of season (from May, which overtime gets to) they fail an inspection. The run ends on Friday the 29th, with Hachey's report; RB (E) there keeps you working, into overtime.

**The regulars, and people who remember you.** Jayden from the Mountain Tim Burtons drive-thru, hockey dad Rob, Mrs. Doiron and her cursed Cava-lame, and Darrell with his trade-ins come in on their own days across the eight weeks (in week eight Rob's van is the hockey team's, and needs its winters on), and what you stamped on them last time changes what they say and bring (fail Jayden's bald tire and he's back with four used tires and Burton Bits for Gus; pass it and he's back off the causeway for a brake job; leave him in the lot at six and he tells you about it). Anybody else you turn away comes back one to four open days later, in the same car with whatever was on it (a part put on somewhere else, with its invoice; a salvage brand, with its certificate; a car from another province is still on the same old ownership, and still needs the full inspection): fixed, with a paper from a pocket (good or not), or hoping for a different clerk. Fundy's driver remembers the last box you sent back. Every stamp goes in the filing cabinet (`DeskBook.files`), which rides along in the story's save; that's also what Hachey pulls from.

**Overtime: the job after week 8.** Pick OVERTIME on the week picker (after week 8), or keep working from the end of the run, and the counter carries on from Monday, December 2, one day after another: through Christmas (the shop shuts for New Brunswick's holidays: Christmas, Boxing Day, New Year's, Family Day, Good Friday, Victoria Day and the rest), the winter and into spring, and on. Every rule from the eight weeks stays up, and the dated ones bite on their dates: winter tires on taxis, rideshares and commercial vehicles through April 30, and from May 1 studs are out of season, so a car on studs doesn't get a sticker (the stud problem the run can never reach). In the spring the tire job is SUMMER TIRES ON, and somebody on studs in for their summers is the job, not a problem. The line is the full pool: walk-ins, the courier, stolen cars and parts off a new list every week, the Familia's Thursdays, the people you turned away, and on about one open day in three a regular (Jayden's HOPP-IN Civic on all-seasons in January, Rob's team van, Mrs. Doiron still on her studs in May, Darrell's trade-ins). Hachey drops in now and then to pull a file (his car's in the lot on the brief when he's coming), and Friday's bills come on the last open day of the week. The record runs along the bottom of the booth, on the result card, the day-end sheet and the brief: days kept, the streak of right calls (any wrong call ends it) and the best streak. Overtime saves at every clock-out, in the same book the desk saves into the story (`DeskBook`, here in `user://driveboss_overtime.json`); quit mid-day and that day's gone. Lose the licence and that overtime's over; the next one starts again from December 2, and your best streak stays on the books. Everybody gets older as it goes: faces (and the kilometres on the cars) count from the date on the papers, birthdays and all. There's no story in it: it's just the job.

**Gus's tool drawer.** Under the day-end sheet is the front of the drawer under the desk: RB (E), or a click on it, pulls it open. Gus knows the guy with the tool truck: pay tonight, and it's in the drawer in the morning, for good. A tool turns up in the drawer the night before the check it's for, and each one makes that check quicker (or surer), never automatic: pick the thing it reads twice (INSPECT, then the same thing again) and the tool reads it, with the question it raises on the ASK list, like any red verdict. The stamp is still yours.
- **Tread gauge** ($750): the tread or the pads on Gus's sheet, against the safety limits, without flipping to the binder's INSPECTION tab.
- **Date wheel** ($900): any date on any paper, against today (or a pulled file's date), without a trip to the calendar.
- **Loupe** ($1,150): a plate, a VIN or a serial, against the stolen list on the wall (on a pulled file, that week's list).
- **UV lamp** ($1,500): the seal on a paper. A real one glows; one somebody made up (or wrote over, like an invoice with its serial changed) stays dark, and a fake never covers anything. A real one that's out of date still glows, so read the dates.

The gauge, the wheel and the loupe say exactly what the two-pick comparison would; the lamp only says whether a paper is real. In free play they're paid out of the till (the one Friday's bills come out of, so buy before the rent at your own risk); in the story, out of Leo's own money. What's in the drawer is kept in the book (`DeskBook.tools`), so it saves with the story and with overtime; a fresh book starts with an empty drawer.

**The relaxed clock.** For more time with each customer: on the morning brief (next to the week picker, or on its own on any other morning), R (Menu/Options) puts the wall clock on the relaxed pace, fifteen real minutes a day instead of ten. Only the pace changes: the line, the honking after an hour and a half on the clock, six o'clock and every rule and verdict are the same. It's kept in the book too (`DeskBook.relaxed`).

**Sounds.** No audio files: the horn from the lot, the stamp, paper on the desk, the wall clock and the till (for fines and fees) are made in code (`counter/desk_audio.gd`), and kept quiet.

- **Inspect** (I, Y or right-click), then pick two things to compare them: a VIN against a VIN, a name against a name, a date against the calendar, the licence photo against the face, a plate against the stolen list, a reading or a paper against a rule in the binder, a service reading against the odometer, a part number against a part number, a serial against the stolen list, the tires against the calendar. Pick the same thing twice and a tool from Gus's drawer reads it, if you've got the one for it.
- **ASK** (A or X, or click the question). A red verdict puts a question under the customer's speech bubble. Most answers are lies. Some customers pull a paper out of a pocket (a bill of sale, a permit, the pink card from the glovebox, a body shop invoice, a structural certificate, a tint exemption, a supersession notice in the box) that makes the discrepancy fine, if that paper checks out too. Small talk is always on the list; people from here know which Tim Burtons they go to.
- **Stamp the work order:** APPROVE (1), DENY (2), REPORT to the police (3), or BAY 3 (4) for off-the-books work. For the courier the stamp goes on the packing slip: APPROVE signs for the box, DENY sends it back.
- **Mistakes:** the first two a shift are Ministry warnings. After that each one is a $100 citation (police matters cost more and are never warnings). Twelve citations, or a third Ministry meeting, and the station loses its licence.
- **Leo's notebook** (N or D-pad up): inspect what somebody said, then the notebook, and Leo writes it down. **The sticker log** (L or D-pad down) lists every sticker you've issued; from week four, last fall's pages turn up, and they're worth reading closely.
- **Scripted customers** come from `data/story_customers.json`: Dale Hatch the Wednesday after Thanksgiving, Darrell's trade-in a week later, the Familia's cars on Thursdays. A story step can bring its own (`"customers": [...]` on a counter step); stamps set story flags (`desk_<id>_<stamp>` plus the outcome's own), and so do notes (`desk_note_<id>`). The regulars live in the same file (`"regulars"`: who they are, their visits, an `after` branch for each stamp you might have given them last time, and their `"overtime"` visits, each with a season instead of a day); `DeskBook.last_file(id)` tells a story step what you stamped on anybody.
- **Friday night** (or Thursday, before a holiday Friday): rent, Gus's pay, Aries's hockey and the Familia's cut all come due.

Drag the papers around with the mouse; with the arrow keys and Space; or with the left stick and A on a controller (D-pad left/right jumps the cursor to the next thing). B or Backspace cancels; Esc or Back returns to the menu.

## Controls (the lot)

The camera sits behind the car and turns with it, so up is always ahead. Time, weather and seasons run on their own (a day is 24 minutes, a season about 4 days), and you change cars in the garage.

| | Keyboard | Controller |
|---|---|---|
| Gas / brake | W / S (or arrows) | RT / LT |
| Steer | A / D | Left stick |
| Handbrake | Space | B |
| Shift up / down (manual) | E / Q | RB / LB |
| Automatic / manual | G | L3 |
| Blinkers | Z / C | D-pad left / right |
| Hazards | V | D-pad down |
| High beams (tap) / flash (hold) | B | D-pad up |
| Horn | H | X |
| Garage (at Covington Auto's bay doors) | F | Y |
| Map and GPS route | Tab / M | Back |
| Gigs | J | R3 |
| Tow it home | R | |
| Hydraulics (hop; hold to keep hopping) | X | A |
| Controls card | F1 | (in the pause menu) |
| Pause: resume, settings, controls, quit to title | Esc | Start |

Every one of these can be changed in **Settings > Controls** (from the title or the pause menu): pick a row, Left/Right for the keyboard or controller column, Enter and press the new key or button (Delete clears it). The prompts on screen follow whatever you bind. The same tab has the stick's dead zone and response curve, how much the stick and keys steer less at speed, the trigger dead zone, easing for the keyboard (keys are on or off, so the gas, brake and steering ease in and come back out quicker), vibration, and the gearbox.

On the controller the stick has a response curve (small movements, small corrections), and the default STREET assists add traction control and a little stability control. Blinkers cancel themselves after the turn.

**A steering wheel.** Plug it in, then **Settings > Wheel**: pick it, run CALIBRATE (hands off, full left, full right, the gas, the brake; it works out which axis is which and which way they run, and handles both pedals on one axis), set the wheel's rotation to match its own software, and turn on DRIVE WITH THE WHEEL. The rim turns the road wheels one for one (AUTO range gears it like a real car, about 14 to 1; or pick how many degrees give full lock), with no steering help in the way. Paddles, and an H-shifter's gears, bind on the same tab. There's no force feedback in the game: turn on your wheel's centring spring in its own software.

**The rest of Settings:** Display (window or full screen, size, vsync, frame cap, pixel scaling), UI (how much chatter, first-time tips, the scan tool, camera distance, button prompts), Difficulty (easy, normal, hard, or set the driving aids, the police and the moose and deer one by one), Graphics (streetlights, rain and snow, cloud shadows, tire smoke, skid marks, lightning flashes, the drunk blur) and Audio (volume, the engine, effects, mute in the background). It's all kept in `user://settings.cfg`, apart from the save, so a new game keeps your wheel set up.

**1ton and the Luchadooros.** The Luchadooros are a lowrider and donk club with a lot in the industrial park, off the road from Northside Salvage (it's on the map). They have three leaders: La Calavera runs the streets, El Pulpo runs his mouth, and 1ton runs the bays. Pull up at their gate and 1ton will talk. Show him a car that's on his laminated list (the big rear-drive sedans and coupes: Impalers, Caprees, a Maliboo, Cutless Supremos, a Grand Nashunal, Broughamms, Town Carrs, Bonnevillains, Crown Victoriouses, a Charjer) and he joins your crew. From then on his bay is a tab in the garage. **Hydraulics** come as two, three or four pumps, hopping 35, 60 or 90 cm, and they weigh what they weigh. **Donk kits** put a car on 24, 26, 28 or 30-inch rims with the lift to clear them: taller gearing, slower off the line, less grip, and a lot more attention. You pay for the parts; he doesn't take money for the labour. On the road, X (A on a controller) dumps the pumps while you're stopped or creeping, and if you hold it the car keeps hopping. A donk sits up off its shadow and its front wheels draw bigger. Three Employee of the Month photos go with it.

**Signals, signs and streetlights.** Signal junctions (where two big roads cross in town, and the full crossings on an arterial) have a signal head over every lane coming in, on a mast arm from a pole at the corner, with the stop line painted across the approach. The heads show what that approach's traffic is obeying: the main road gets the long green, there's an amber, and both ways are red for two seconds between greens. Traffic stops for a red however long it's waited. The side road at a priority junction has a stop sign (4-WAY under it at an all-way stop). Out on the roads: speed limits after every junction where the limit changes and every kilometre and a half on the long roads (the same limits the police go by), curve and sharp-turn warnings with the speed to take them at and chevrons round the sharp ones, MERGE and RIGHT LANE ENDS, SIGNAL AHEAD and STOP AHEAD on the fast roads, railway crossings, the moose and deer crossings, and EXIT before every interchange. Signs are one-sided: you read the ones for your direction and see the backs of the others. The streetlights stand over the street on arms, each on its own photocell at dusk (the odd sodium one flickers, the odd one's dead), and the poles near you are solid. Go through a red that had been red a second, or roll a stop sign, in sight of a patrol car, and they light you up ($250 for the red, $110 for the stop sign). Stopping first and then going (a right on red, your turn at the stop) is fine.

**Employee of the Month.** Thirty-five awards, each a framed photo of Leo on the wall of the break room at Covington Auto (from the title, or the pause menu). The wall fills a month at a time: the first photo you earn is October 2019, the next November, and so on. They're for the things you do on the road: kilometres, the cars and parts you collect, the gigs (pizzas, rides, tows, night drives), races, the meet and Drag Night, tickets and getting away, moose and deer, money, the auction, Northside Salvage, selling a car, running dry and writing one off. A new one goes up on the HUD straight away, and its card comes up the next time you've stopped with nothing else going on. What you've won is kept in `user://driveboss_awards.json`, apart from any save.

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
godot --headless --path game -s tests/jobs_tests.gd
godot --headless --path game -- --traffic-test
godot --headless --path game -- --race-test
```

The race test (`--race-test`) runs inside the drive scene: three AI racers round the Downtown Box through traffic (they have to finish, stay on the route and not get stuck), a race you win and get paid for, a pull-over and a ticket, a chase you get away from, an impound, a deer and a moose, a pink-slip race, a HOPP-IN ride, a trip to the salvage yard, a night at the meet, and the impound auction. The jobs tests check the routes follow real roads, the field is matched to your car, and the ticket and impound rules.

The map, sky and car tests check that:
- the map builds quickly;
- the GPS can reach every destination;
- no building sits on a road;
- the day/night cycle and lights work in every season;
- rain, sun, snow and freezing rain change the road;
- all four cars draw and drive sensibly.

The counter tests (`counter_tests.gd`, eight weeks of rules) prove that:
- every problem the game puts in the papers can be found again from the papers alone (couriers' boxes too);
- a stolen part is on the list, on Gus's sheet and findable from the desk, on a car or in a box, even when its invoice says otherwise; winter tires on working cars are checked in week eight and studs are legal all of it (and fail, under their own name, on a day in May);
- every problem type can be proven from the desk with the inspect tool, under its own ASK question, and from a file Hachey pulls, on the file's own date;
- a clean customer never shows red, and a covered one only shows the red its proof explains;
- an exception holds only while its proof checks out (spoil the proof and the problem's back);
- tint, exhaust, the courier and the audit are judged by their rules, and a walk-in's, a box's, a regular's (down every branch) and a returning customer's papers all rebuild exactly from the file;
- every regular's visit, down every branch, is honest about its papers; the people you turn away come back as the same person in the same car, once, with what was on it (a part and its invoice, and a car from another province still on its old ownership, booked for the full inspection);
- a new stolen list comes every week, and a pulled file is read against the list from its own week, not this one's;
- overtime's calendar holds (New Brunswick's holidays, Good Friday's bills on Thursday), the dated rules bite on their dates (winters on working cars through April 30, studs out of season from May 1), overtime's line is honest from December to June, Hachey drops in about one day in four, and every regular's overtime visit is honest, in its season, and rebuilds;
- Gus's tool drawer: four tools at one to four good days' takings, each turning up the night before its check; the gauge, the wheel and the loupe say exactly what the two-pick check says, and the UV lamp lights a good proof, leaves a fake dark (a fake never covers anything) and lights a real one that's out of date (which still doesn't cover it);
- ages count from the date on the papers (people, the cast and their cars), and nobody at the desk uses a real brand or calls Leo son, sir, ma'am or man;
- warnings, fines, the binder, the shift's arrivals and the scripted customers behave.

The desk tests (`desk_tests.gd`) run the counter scene itself: the shift clock ends the day at six, a line builds and honks, whoever's left drives off, ASK hands over proofs and takes off masks, the notebook and the sticker log (and its gap) work, the regulars come back changed by what you stamped, the filing cabinet survives the save, the courier's stamp lands on the slip, Hachey jumps the line and re-stamping differs or doesn't (and pulls a box and a regular, and writes down the same wrong call twice), a stolen part is caught from the desk, Rob's team van remembers whether you put its winters on, studs in November pass, the room's sounds play when they should and stay quiet, the day-end rows line up, every tab of the binder fits, every desk action has a key and a pad button, and every prompt comes from `Hints`. The stolen list is the same all week and new the next, and Hachey reads a stolen car's file against its own week's list, pinned over this week's. Overtime: the picker, the first morning's fax, the streak and the best streak, the save at clock-out and picking it up again, Friday's bills and no end of the month, Christmas week, studs in May, Hachey dropping in, KEEP WORKING from the end of the run, and losing the licence. Gus's drawer: it's under the day-end sheet with what's offered that night, buying comes off the till (in the story, Leo's own money), once, never short, and a click straight through from the stamps goes home; each tool at the desk (pick it twice: the date wheel, the UV lamp on a made-up permit, the tread gauge, the loupe), nothing without it, and the stamp is still yours. The relaxed clock: on the brief only, the same day with the same line, calls and walk-outs, half as long again in real time, the horn still at ninety minutes on the clock; the tools and the clock survive JSON, the story's save and overtime's file. Faces age with the calendar, Hachey's too.

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
| `ui/hud_layout.gd` | Where every driving HUD panel goes (the test checks nothing overlaps or covers the car) |
| `world/player_car.gd` | Input, collisions, tire marks, smoke and steam |
| `world/ai_car.gd` | A car with somebody else driving it: the same sim, steered down a line of points at the speed the corners allow |
| `world/path_track.gd` | A line to drive and how far along it a car is (laps included) |
| `world/police.gd` | Patrols, spotting, pull-overs, chases, tickets, the impound, and the heat meter |
| `world/road_furniture.gd` | Signals, stop signs, streetlight poles, speed limits, warnings, chevrons and exits: where they go, how they're drawn, the solid poles near you, and the red lights and stop signs you can run |
| `game_settings.gd` | Settings, saved to user://settings.cfg: controls, wheel, display, UI, difficulty, graphics, audio |
| `awards.gd` | Employee of the Month: the 35 awards, what each takes, and the file they're kept in |
| `crew/oneton.gd` | 1ton: his face, his list, what he says, the hydraulics and donk kits and what they do to a car, the hop |
| `world/luchadooros.gd` | The Luchadooros' lot: their cars out front, and 1ton's panel |
| `jobs/street_race.gd` | Marco's street races: the routes, the field, the grid, checkpoints, the running order and the pot |
| `ui/hud.gd` | The dashboard |
| `render/engine_audio.gd` | The engine and tire sounds, made live from the sim |
| `data/cars/silvio.json` | The car itself: weight, torque curve, gears, brakes, tires |
| `counter/rules.gd` | The counter's rules: customers, papers, problems, comparisons, ASK answers and proofs, the binder, the shift's arrivals, stamps, warnings and pay. No drawing |
| `counter/desk_tools.gd` | Gus's tool drawer: the tools, their prices, and what each one reads when you pick a fact twice |
| `counter/counter_scene.gd` | The counter: the shift clock, the line in the lot, desk, documents, inspect, ASK, stamps, the binder, the books, the day and the week |
| `counter/desk_book.gd` | Leo's notebook, the sticker log, the filing cabinet (every stamp) and the Ministry's tally; rides along in the story save |
| `counter/regulars.gd` | The regulars' visits and the people you turned away coming back, from what's in the filing cabinet |
| `counter/desk_audio.gd` | The counter's sounds, made in code: the horn from the lot, the stamp, paper, the wall clock, the till |
| `data/story_customers.json` | Scripted customers (Dale Hatch, Darrell, the Familia's cars) and the days they come in, and the regulars (Jayden, Rob, Mrs. Doiron, Darrell) with their visits |
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
