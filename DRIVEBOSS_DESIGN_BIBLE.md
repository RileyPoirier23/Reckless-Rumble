# DRIVEBOSS: design bible

> What the best games in our neighbourhood do, what we take from each, the story from the first drink to the last corner, the systems written down tightly enough to build, a bank of lines in the game's voice, and the order to build it all in.

Companion to [the concept](DRIVEBOSS_CONCEPT.md) and [the prototype README](game/README.md). Where this bible and the concept disagree, the disagreement is called out and argued. The fixed facts are not up for debate: Leo Covington, Aries (14), Dale Hatch killed Frank (brakes tampered, death staged as a drunk crash, Gus knows more), Toby Cormier (tow truck, male friend), Gus (old mechanic), Mikey (best friend), Dom and Mia Tortellini (the Familia), Darrell (sold Leo the '91 Nissun Silvio), no love interest, radio later, co-op after launch, the USB job as specified, parody car names only, no slurs, and parodies of real people never in crime, doping or abuse content.

**A note on sources.** The research was done with web search (2026-10). Page fetches were blocked in this environment, so facts come from search-result summaries of wikis, store pages, reviews and interviews; each section links the pages the facts came from. Anything marked *(play knowledge)* is from general familiarity with the game rather than a source, and should be checked before anyone quotes it.

---

## 0. The short version: twelve calls this bible makes

1. **The counter is the story's main stage.** Like VA-11 Hall-A and Papers, Please, the people at the desk carry the plot. Two or three scripted customers a day, the rest procedural. The final confrontation with Dale Hatch happens *at the counter*, with the inspect tool.
2. **Add a shift clock, two free warnings a day, and an ASK button.** These are the three Papers, Please mechanics the desk is missing, and they turn reading papers into pressure.
3. **Make every cutscene feel alive before writing more of them.** Expressions, blink and talk frames, per-character text blips, punctuation pauses, a few shot types and camera moves. It is cheap and every existing scene gets better.
4. **Ship the story.** Pixel Car Racer's most repeated complaint is a story mode that was promised and never arrived. Our story is the thing nobody else in this genre has.
5. **Stages 1 to 4 per category, plus a story-gated "Frank Spec" Stage 5.** CSR2's ladder is instantly legible. Its fusion parts become *tricks* earned from crew and Frank's tapes, never bought.
6. **Waiting for parts is a joy; paying to skip it is not.** Deliveries run on game days. You can shorten a wait by *doing* something (drive to the depot), never by paying. The courier arrives at the counter as a customer with a packing slip to check.
7. **Crew are people, not a lobby.** Gus, Toby and Mikey (and later Mia, Tej, Han) fill three slots: the bay, the passenger seat and the phone. Their perks are grounded and numeric. After Aries dies her slot stays empty.
8. **Relocate Frank's death from the Coast Road to Lutes Mountain Road.** The Coast Road is not on the map; the Mountain is, it's a downhill (where failed brakes kill), its red tower lights are visible from everywhere in town, and the Tim Burtons where Leo buys the Silvio sits on the road that leads up to it.
9. **Take the legal consequences of Aries's death seriously.** A Canadian court would jail Leo and take his licence for years. Chapter 5 becomes the custody year, Chapter 6 the year the crew drives for him (or he drives illegally, which is a path), and Chapter 7 the year he gets his licence back with an ignition interlock.
10. **Give the game an EZIC.** Hatch Motors' "fleet partnership" is easy, clean, well-paid desk work from Year 2. In Year 6 the player learns every fleet car they stamped fed the export pipeline.
11. **Hide the avatar twist better.** Create the avatar at first boot, never print the old manager's name in Years 1 and 2, and let initials on old paperwork and a coffee-stained staff photo do the work.
12. **Build order: presentation, phone and barks, desk 2.0, garage and dyno, evenings, then Chapter 1.** Section 5 has the full list.

---

## 1. What the reference games teach

Each entry: what the game does (sourced), then the concrete lesson for DriveBoss.

### 1.1 Pixel Car Racer (Studio Furukawa)

**What it does**
- A pixel-art drag and street racer whose store listing sells depth: "100+ cars", "1000+ car parts", "RPG style tuning", dyno tuning, a livery designer, a "realistic engine system" and manual shifting. Drag mode is one-on-one; street mode adds traffic to dodge.
- Parts and rims come from **crates**, sold in bundles from 4 to 60; some items are crate-only. Extra garage slots are sold separately.
- Fan tuning guides tell you to test your own gearing on the dyno; players say the pay-to-win factor is small because the existing parts go a long way.
- The **story mode** was locked and "coming in a future update" for years; reviewers and players list it as the main disappointment, alongside development slowing down.

Sources: [App Store listing](https://apps.apple.com/us/app/-/id1068808996), [Gamer Journalist tuning guide](https://gamerjournalist.com/what-is-the-best-tune-for-pixel-car-racer/), [TouchTapPlay on the locked story](https://www.touchtapplay.com/how-to-unlock-story-in-pixel-car-racer/), [PCR crates wiki](https://pixel-car-racer.fandom.com/wiki/Crates).

**Lessons for DriveBoss**
- **The parts list is the hook for car people.** Players stay for the next 4 kW. Our stage ladder (section 3.3) needs real numbers on screen and a dyno to prove them.
- **Keep the thrill of the crate, drop the crate.** Randomness comes from places and people: a pick-and-pull row, a barn find, Twinkee's van, Roll Up the Rim. Nothing random is ever sold for money (the concept's "never pay-to-win" rule).
- **The garage UI should show the part on the car.** The profile view (about 200×64 in the concept) on a lift, with the part's spot lit when you hover it, beats a list.
- **Ship the story.** It's our moat.

### 1.2 CSR Racing 2 (NaturalMotion / Zynga)

**What it does**
- **Seven upgrade categories with stages 1 to 5** bought with cash. Stages 1 to 3 install instantly; **stages 4 and 5 are imported parts with a delivery timer** that grows with the car's tier (fan wiki: about 20 minutes per part at Tier 1, 45, 90, 180, up to 360 minutes at Tier 5), skippable with gold.
- **Stage 6 and fusion parts can't be bought.** They come from events, key rolls and **stripping cars you own**. Fusion parts are **brand-specific**, come in green, blue and purple, slot into a stage's fusion slots and **stack** as you move up stages.
- **Tuning** (nitrous duration vs strength, final drive, tire pressure) unlocks at stages 2, 3 and 4; you read the result on the dyno and in "Evo points".
- **Crews:** members' RP pools into crew championship milestones with shared rewards, plus time-limited "wildcards" (double cash or RP). Activity matters more than skill.
- The campaign is **tiers of crews**: beat four crew members, then the leader, then a high-stakes race for the leader's car.

Sources: [CSR2 fan wiki, car upgrades](https://csrracing-2.fandom.com/wiki/Car_Upgrades), [Zynga help: fusion parts](https://zyngasupport.helpshift.com/hc/en/55-csr-2/faq/5925-what-are-fusion-parts-and-how-do-i-use-them/), [AllClash on stripping cars](https://www.allclash.com/csr2-stripping-cars-guide-for-fusion-parts/), [Pocket Gamer tuning guide](https://www.pocketgamer.co.uk/csr-racing-2/how-to-tune-your-car-in-csr-racing-2-tires-nitro-and-final-drive/), [Boostroom crew guide](https://boostroom.com/blog/csr-racing-2-crew-guide-how-crews-work-and-how-to-earn-more-crew-rp), [CSR Racing on Wikipedia](https://en.wikipedia.org/wiki/CSR_Racing).

**Lessons for DriveBoss**
- **Stages per category are the clearest progression UI in the genre.** Keep the shape: Stage 1 to 4 per category, and a Stage 5 that can't be bought.
- **Stage 5 is "Frank Spec"**, unlocked by a build sheet on one of Frank's 40 tapes plus Gus at level 4. That ties the collectibles to progression the way S6 ties events to it.
- **Fusion becomes "tricks":** small grounded bonuses (a port-matched gasket, a re-flashed map) from crew and tapes, specific to a make family (NISSUN tricks only fit Nissuns), stacked in slots on installed stages.
- **Delivery waits are good; real-time timers and paid skips are not.** Our timers are game days, and the way to speed up is a side mission.
- **The crew ladder and boss pink-slip stay** (the concept already has them). The crew *championship* becomes a seasonal league for our crew's combined results.

### 1.3 Papers, Please (Lucas Pope)

**What it does**
- A **discrepancy** is a mismatch between two in-game facts (a name spelled two ways, a photo that isn't the person). **Inspect mode** highlights two facts to prove it; the **rulebook** is a fact source too.
- **Rules escalate daily.** From day 18 a denial needs a reason stamp, so you must inspect and **interrogate** first. Protocol is judged at the moment the entrant leaves the booth.
- **Pay:** 5 credits per entrant processed without a citation. **The first two citations a day are warnings;** after that they cost money.
- **The end-of-day screen** is the family: rent is mandatory (20 credits, 25 from day 5), food is 5 a member, heat 10, medicine when someone is sick. Each relative tolerates hunger for a different number of days (the son for one). Skipping things is the strategy, and the cost.
- Pope: the day-to-day flow and **two or three entrants per day are scripted**; the rest are generated from the day's rules. The hard part was pacing 30 days without dry spots.
- Around 20 endings (guides count 20 to 24), many of them short failures, and you can **resume from any earlier day**. A secret faction (EZIC) asks for favours you can refuse.

Sources: [Papers, Please wiki: discrepancies](https://papersplease.fandom.com/wiki/Discrepancies), [wiki: heat and expenses](https://papersplease.fandom.com/wiki/Heat), [Ludo guide: family expenses](https://www.ludo.guide/guide/papers-please/family-expenses), [Game Developer: Road to the IGF interview](https://www.gamedeveloper.com/design/road-to-the-igf-lucas-pope-s-i-papers-please-i-), [TouchArcade endings guide](https://toucharcade.com/2014/12/24/how-to-get-all-the-different-endings-in-papers-please-tips-and-guide/).

**Lessons for DriveBoss**
- Our desk already has inspect-and-compare, a daily bulletin, napkins and a sting. It's missing four things, all specified in section 3.8:
  1. **A shift clock.** Speed is money. Without it, reading papers has no pressure.
  2. **Two free warnings a day.** Right now every mistake is $100 from the first customer, which punishes learning.
  3. **ASK.** After you prove a discrepancy, you can ask about it. Some answers are valid (a dated bill of sale covers a name mismatch), some are lies, and the exceptions are where the rules get interesting.
  4. **Scripted customers carry the story** (two or three a day), the rest are procedural.
- **The Kitchen Table screen** (section 3.9) is our family screen: checkboxes, mandatory rent, skippable things with consequences, and Aries's status in one line.
- **Short fail endings with a newspaper front page,** then "resume from day X".
- **A secret faction you serve without knowing.** Hatch Motors' fleet partnership is our EZIC in reverse.

### 1.4 My Summer Car (and My Winter Car), Amistech

**What it does**
- **Ordering parts is a ritual:** the parts catalogue sits on the garage table; you tick prices onto an order form, it becomes an envelope, you drop it in the yellow post box by Teimo's shop, and after a wait (the wiki says about 5,000 seconds) Teimo phones. You pay at his counter and collect the box at the loading dock. Postage is 60 mk; only one order can be pending.
- **Fleetari** repairs broken parts; a separate **inspection office** makes the car road-legal. Lindell, who runs inspection, feuds with Fleetari; Fleetari phones drunk at night asking you to dump sewage on Lindell's shop, for booze and a bigger discount.
- **Police checkpoints** breathalyse you; fines scale with your earnings; unpaid fines mean arrest. You get tickets for speeding, drunk driving and an uninspected car.
- **Side jobs:** firewood, septic tanks, home-brewed kilju, strawberry picking, driving a drunk neighbour home from the pub, delivering ads. Survival stats: hunger, thirst, fatigue, urine, stress, dirtiness.
- **My Winter Car** launched into Early Access on 29 December 2025 with cold-weather survival and body temperature, and became a breakout Steam hit.

Sources: [MSC wiki: parts catalog](https://my-summer-car.fandom.com/wiki/Parts_catalog), [wiki: police checkpoint](https://my-summer-car.fandom.com/wiki/Police_checkpoint), [wiki: vandalising the inspection shop](https://my-summer-car.fandom.com/wiki/Vandalising_the_inspection_shop), [My Summer Car on Wikipedia](https://en.wikipedia.org/wiki/My_Summer_Car), [The Drive on My Winter Car](https://www.thedrive.com/news/the-sequel-to-the-internets-favorite-finnish-car-building-life-simulator-is-now-available).

**Lessons for DriveBoss**
- **Keep the ritual, lose the friction.** Several orders at once, game-day waits, and a phone call from the PARTS shop next door to Covington Auto (it's already on the map) when your box is in.
- **A rival inspection station.** Leo can't inspect his own cars (conflict of interest), so once a year he takes them to **Lindsay's Lube & Inspect**. A feud, a petty vandalism job, and a station that "passes anything with a pulse" for your customers to threaten you with.
- **Checkpoints and tickets in the mail** (the concept's idea 17) with escalating fines, and court (idea 19).
- **Phone-call jobs.** Side jobs arrive as calls and texts, not menu items.
- **A Maritime winter is a selling point.** My Winter Car proves people want to fight the cold in a car game. We already simulate it.

### 1.5 Mon Bazou (SantaGoat)

**What it does**
- A solo Canadian developer's car-building life sim in **rural Quebec around 2005**. You turn a *bazou* (Quebec slang for a junker) into a street racer, bolting parts on by hand with no upgrade buttons.
- Money comes from **cutting firewood, making maple syrup, delivering pizza, night street races, fencing stolen radios and growing cannabis.**
- Steam reviews are around 97% positive; critics call it chill, sometimes grindy and very specific. Some players struggled with map text in Québécois French.

Sources: [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/MonBazou), [DLCompare feature](https://www.dlcompare.com/gaming-news/why-mon-bazou-is-more-than-just-a-my-summer-car-clone), [Steam page](https://store.steampowered.com/app/1520370/Mon_Bazou/), [Metacritic](https://www.metacritic.com/game/mon-bazou/).

**Lessons for DriveBoss**
- **Regional specificity sells.** A game full of Quebec in-jokes did not need to explain itself. Commit harder to the Maritimes: Chiac at the counter, dooryards, furnace oil, the tidal bore, lobster suppers, "going out West", "from away".
- **Local economies make side jobs:** Mon Bazou's maple syrup is our firewood run to Havelock, fiddlehead season, a lobster-supper delivery, plowing parking lots in January.
- **Bilingual flavour, never a barrier.** Chiac lines always come with English in the same line or a subtitle. Mon Bazou's French map confused players; ours won't.
- **A solo dev can win with depth over breadth.** Keep the city dense, not big.

### 1.6 Car Mechanic Simulator 2021 (Red Dot)

**What it does**
- **Diagnostic tools:** OBD scanner (which can't read older cars), compression tester, multimeter, fuel-pressure gauge, tread gauge, plus an examination mode that highlights parts.
- **Part condition in percent;** players treat about 80% as "green". **Story orders need the replaced parts at 100%.** Endless generated orders plus crafted story jobs.
- A common complaint: hunting for the one specific part that satisfies an order.

Sources: [Steam page](https://store.steampowered.com/app/1190000), [diagnostics guide (CMS 2026)](https://www.magicgameworld.com/car-mechanic-simulator-2026-diagnostic-tools-and-examination-guide/), [Steam discussion on part condition](https://steamcommunity.com/app/1190000/discussions/0/4331979507649051338).

**Lessons for DriveBoss**
- **Condition per part,** shown as a percentage and a colour, feeds the sim (section 3.2).
- **"The scanner can't read old cars" is a gift.** A 1991 Silvio or a 1986 Supreem predates on-board diagnostics, so you diagnose with Gus's ears (the concept's listen minigame), the creeper light and a gauge. Newer cars get the scanner. That's a real difference between eras that players will feel.
- **Bay 1's job board comes from the counter.** A stamped work order becomes a job. Gus does it, or Leo does the hands-on version.
- **Avoid the hunt.** Work orders state the symptom; the fix accepts any part above a threshold.

### 1.7 VA-11 Hall-A (Sukeban Games)

**What it does**
- A work-shift game with about four customers per shift; the world is built through what bar patrons say rather than exposition, and reviewers single out the natural, grounded dialogue.
- **Before work you set the jukebox,** and the music you picked plays under whatever happens.
- **After work, Jill's apartment:** a tabloid news site, a forum, a pop star's blog, decorating, and **paying bills**, with real tension between rent and wants.

Sources: [VA-11 Hall-A on Wikipedia](https://en.wikipedia.org/wiki/VA-11_Hall-A), [Pocket Gamer review](https://www.pocketgamer.co.uk/va-11-hall-a/va-11-hall-a-switch-review-a-gorgeous-enthralling-visual-novel/), [Tampere University Playlab review](https://www.tuni.fi/playlab/life-in-a-dystopian-future-va-11-hall-a-cyberpunk-bartender-action/).

**Lessons for DriveBoss**
- This is the **closest structural cousin of CLOCK IN / CLOCK OUT.** Regulars at the counter get arcs that run across weeks: the Tim Burtons drive-thru kid, the hockey dad, the woman with the cursed Cava-lame, Darrell's trade-ins.
- **A pre-shift choice** sets the mood of the day. Before radio exists it's Gus's coffee pot (the counter brief already has the mug); once radio exists, it's the shop radio's station.
- **The apartment upstairs is the wind-down screen:** phone, Bleeter, the Daily Clutch, MarketThing, bills, and the décor the concept wants to change over eight years.

### 1.8 Night in the Woods (Infinite Fall)

**What it does**
- Comic-style speech balloons in the world; an option for animated text; a GDC 2018 talk on how sound tells its story; a dying small town, broke friends and a mystery underneath.

Sources: [Night in the Woods on Wikipedia](https://en.wikipedia.org/wiki/Night_in_the_Woods), [GDC: how sound tells the story](https://gdconf.com/news/come-gdc-2018-hear-sounds-tell-stories-night-woods).

**Lessons for DriveBoss**
- **Tonal model.** Port Rumble is Possum Springs with a tidal bore: friends making jokes because the town's money left, and something rotten under it.
- **Speech balloons for passenger banter** in the drive scene, above the car, not a dialogue box over the road.
- **Word-level effects** (shake, wave) used rarely, for feeling, never for decoration.

### 1.9 Disco Elysium (ZA/UM)

**What it does**
- A tall, narrow scrolling dialogue column; **skills speak as voices** in the hero's head, with personalities, and **can give bad advice**; active checks show their odds before you commit.

Sources: [80.lv on the UI](https://80.lv/articles/disco-elysium-working-on-ui-design), [dialogue UI case study](https://tommartin.myblog.arts.ac.uk/?p=168), [Slant review](https://www.slantmagazine.com/games/disco-elysium-review/).

**Lessons for DriveBoss**
- **Leo's vices talk.** THE BOTTLE, THE BURNOUT and DAD'S VOICE interject one line at a time in cutscenes and at the counter ("THE BOTTLE: one won't hurt. One never has."). They get quieter as sober days pile up, and THE BOTTLE's line on the night of the crash is the last thing it says in the game.
- **Show the odds when Leo gambles.** A bribe offer or a bluff at the counter shows its chance, like an active check.

### 1.10 Hotline Miami (Dennaton)

**What it does**
- Story told in cutscenes drawn in the same 16-bit style as the play; an opening of masked men making cryptic comments; in the sequel, disembodied nodding heads delivering dialogue. *(Play knowledge:)* chapter title cards with a date, neon colour-cycling titles, and instant restart after death.

Sources: [GameSpot review](https://www.gamespot.com/reviews/hotline-miami-review/1900-6410681/), [Cliqist on Hotline Miami 2's aesthetics](https://cliqist.com/2015/03/30/aesthetic-excellence-hotline-miami-2/).

**Lessons for DriveBoss**
- **Title cards carry a date and a place,** with the title colour-cycling slowly. The current cards already have the slot (`small`).
- **Death to retry in under a second.** The meme screen is a reward; the restart must be instant (press A, you're back at the last checkpoint).
- **Interrogation framing for the darkest chapter:** after Aries's crash, the police interview room with Tremblay intercuts with the drive, in that same flat, unsettling stillness.

### 1.11 Undertale (Toby Fox)

**What it does**
- Unvoiced text with a **sound blip per speaker** (a few characters have their own unique sounds); different fonts by speaker and context; a **waving or shaking baseline** added for emotion.

Sources: [Fonts In Use: Undertale](https://fontsinuse.com/uses/51307/undertale-dialogue-and-interfaces), [Construct forum on recreating the blips](https://construct.net/en/forum/construct-2/how-do-i-18/undertale-based-text-155015).

**Lessons for DriveBoss**
- **Per-character blips** generated live (the engine audio is already generated live, so the same approach works). Gus low and slow, Mikey wobbly, Dom a soft organ chord, Aries quick and high.
- **Silence is punctuation.** In the gravest scenes there are no blips at all.

### 1.12 Gran Turismo 4 (Polyphony Digital)

**What it does**
- **Five licences of 16 tests each** (plus a coffee break); each test is graded gold, silver, bronze or fail against target times. Bronze on all 16 earns the licence and a prize car; silver and gold sweeps earn more cars. Some tests have a pace car you may not pass.
- **Used car dealerships** whose stock rotates on a cycle (every 10 in-game days in the early games, with the pattern repeating every 600 days); GT7's rotates roughly weekly or daily depending on the source.

Sources: [GT wiki: GT4 licences](https://gran-turismo.fandom.com/wiki/GT4_Licenses), [GT wiki: used car dealership](https://gran-turismo.fandom.com/wiki/Used_Car_Dealership), [Jalopnik on GT7's used lot](https://jalopnik.com/this-slick-fan-developed-web-tool-makes-gran-turismo-7-1848657019).

**Lessons for DriveBoss**
- **Mentor lessons are medal tests.** Dom's launch lessons at Airstrip 7 are timed tests (60-foot time, shift accuracy, reaction time) with gold, silver and bronze. Gold on all of a mentor's tests earns a trick or a car.
- **Aries's lessons are a licence test in reverse:** you're the instructor, the medal is her patience meter, and her road test (which you can't help with) is graded on how you taught her.
- **MarketThing refreshes each morning,** with rare listings on a long cycle the way GT's special cars came round (Frank's wreck is one).

### 1.13 Need for Speed: Underground 2 (EA Black Box)

**What it does**
- The story is told in **comic-book panels**; Rachel Teller guides you through **SMS messages** that also nudge you to the next event; high star ratings earn **magazine cover shoots** where you drive to a location before the photographer leaves, then frame the shot. Deep visual customisation, fine tuning and a **dyno run**.

Sources: [Need for Speed: Underground 2 on Wikipedia](https://en.wikipedia.org/wiki/Need_for_Speed:_Underground_2), [NFS wiki: Rachel Teller](https://nfs.fandom.com/wiki/Rachel_Teller).

**Lessons for DriveBoss**
- **The phone is the quest log.** Texts from Mikey, Toby, Mia and Aries give missions and nudge the day. It's already happening in `clock_out_1`; make it a real system (section 3.10).
- **Cover shoots:** The Daily Clutch's "Ride of the Week" and Instagrime: drive to a spot at golden hour before the light goes, frame it in photo mode. Good shots sell MarketThing cars faster (concept idea 2).
- **The reveal moment** after a big install (section 3.4).
- **Comic panels** are cheap and stylish for our code-drawn sets: split the 640×360 screen into two or three panels for fast beats.

### 1.14 Grand Theft Auto (Rockstar)

**What it does**
- **Chatterbox FM** in GTA III: an all-talk station hosted by Lazlow, co-written with Dan Houser, whose callers are deliberately odd and whose host has a stock reply for nonsense. **Parody ads** follow real marketing clichés so closely they feel real.
- **GTA IV:** more than 80,000 lines and 740 voices; the team **dropped random pedestrian self-talk** to make ambient dialogue more realistic.

Sources: [Grand Theft Wiki: Chatterbox FM](https://www.grandtheftwiki.com/Chatterbox_FM), [GTA Radio on Tropedia](https://tropedia.fandom.com/wiki/GTA_Radio), [GamesRadar: GTA IV audio Q&A](https://gamesradar.com/grand-theft-auto-iv-audio-qa/2).

**Lessons for DriveBoss**
- **Talk radio with recurring callers** who react to the player's flags (the safe on Main Street, the black Charjer outside Covington Auto). Our host gets his own stock line, not Lazlow's.
- **Parody ads of local ads**, the way Maritime furniture stores and car dealers sound on AM radio. Hatch Motors' ads change after the reveal.
- **Ambient lines must be situational, not random.** Every line has a trigger (section 3.10).
- **Scale honestly.** We will never have 80,000 lines. Our target for launch is about 6,500 written lines, tightly tagged.

### 1.15 Others worth stealing from

| Game | What it does | Take for DriveBoss |
|---|---|---|
| **Jalopy** ([TechRaptor review](https://techraptor.net/gaming/reviews/jalopy-review-communist-clunker)) | A 1990 road trip with your uncle in a Laika whose engine parts and tires wear out; scavenged crates; smuggling across borders. Reviewers found the late game empty | Passenger lines keyed to the car's condition ("that's the head gasket, that is"). And a warning: content density must hold up in the last third |
| **Motor Town: Behind the Wheel** ([guide](https://gamepretty.com/motor-town-behind-the-wheel-complete-guide/)) | Jobs gated by vehicle type: towing needs a tow truck, taxi work needs a registered taxi; renting job vehicles early | Tows need Toby's wrecker; Hoover rideshare needs a four-door with a valid inspection sticker (which is a counter tie-in) |
| **Retro Gadgets** ([TapTap review](https://www.taptap.io/post/3488976)) | Build working retro gadgets on a workbench and program them in Lua; "more of a tool than a game" | Diegetic devices with one consistent look: the counter PC for the USB job, the TomTum GPS, the scan tool, the phone. Each is a "gadget" drawn by code |
| **Slow Roads** ([Stuff](https://stuff.co.za/2022/10/25/stressed-go-play-slow-roads-this-free-browser-based-endless-driving-simulator/)) | Endless procedural driving with no way to fail; pick season and time; autodrive | **Night Drive,** the concept's healthy outlet: no objective, no cops, stress drains while you drive. Also the gentle way into Legacy mode |
| **Pacific Drive** ([TechRadar](https://www.techradar.com/gaming/pacific-drive-review), [Top Gear](https://www.topgear.com/car-news/gaming/pacific-drive-game-review-haunting-and-foreboding)) | One car you come to love; nearly every part damageable; **quirks** like the horn sounding when you close the boot | **Quirks** on MarketThing cars and customers' cars: the passenger window that drops in the rain, the gas gauge that lies by an eighth. Gus can fix one, or you can keep it and the car's bond goes up |

### 1.16 Steal and avoid, on one page

| Steal | Avoid |
|---|---|
| Stage ladders with numbers (CSR2, PCR) | Selling randomness or time skips |
| Two or three scripted visitors a day (Papers, Please) | Punishing the first mistake of the day |
| The family screen with skippable bills (Papers, Please) | Real-time timers that run while the game is closed |
| Customers as the story channel (VA-11 Hall-A) | Exposition dumps in cutscenes |
| Phone texts as the quest log (NFSU2) | Random chatter with no trigger (GTA IV dropped it) |
| Per-speaker blips and silence as punctuation (Undertale) | Text effects on every line |
| Vices as voices with odds shown (Disco Elysium) | Lecturing the player |
| Medal tests for lessons (GT4) | A late game with nothing to do (Jalopy) |
| Regional flavour without apology (Mon Bazou) | Leaving non-locals out (always subtitle) |
| Quirks that make a car yours (Pacific Drive) | A story mode that never ships (PCR) |

---

## 2. The story

### 2.1 A critical review of what's written

What exists today (`game/story/story_script.gd`, `story_missions.gd`, the counter briefs in `counter/counter_scene.gd`): the prologue (party, the drunk drive, the meet, Gus's morning, the avatar, the counter tutorial, clock-out texts, buying the Silvio from Darrell, driving it home, Aries at night) and the first day of Chapter 1 (Mia's Charjer job, Bay 3, Gus on the brakes). About 120 lines.

#### What's strong
- **The voice is already there.** Darrell ("Selling it for my wife's husband." / "Hence the price."), Dom's grace over the wreck, Mia's "The feelings are free," Mikey's "bro the jar is for emergencies. u are an emergency," Sal's "He was chasing himself." These are specific, dry and character-revealing. Keep this register.
- **Aries's line is the best line in the script:** "Dad used to say that. Right up until." It carries the whole theme in six words and it's set up by Leo's "I'm fine."
- **The drives match the beats.** You buy a lie (the Silvio), then drive the lie home with a blown head gasket and watch the temperature climb. That is the game's thesis done with mechanics, not words.
- **Debt as a number on screen** ($4,200, scratches cost money, Mia "almost smiles") gives every drive stakes.
- **The death memes** are funny, specific to car, place, weather and condition, and the specificity-weighted picker in `DeathMemes.pick()` is a pattern worth reusing for all ambient lines.

#### What's weak
- **Leo has the least distinctive voice in his own story.** Everyone else has a hook; Leo has "I'm fine," "Morning, Gus," and reasonable questions. He needs a signature: he deflects with car talk and self-roasts, and he's only sincere with Aries, late, when nobody else can hear. Rewrite a few of his lines in each scene to that rule.
- **Choices don't come back.** `cocky` / `quiet` / `joke`, `meet_agree` / `meet_defiant` and `checked_silvio` / `blind_buy` are set and never read. Rule: **every flag gets a callback within two scenes,** and at least one in three gets a mechanical consequence. Examples are in the fix list below.
- **The brakes clue is told twice in two days** (clock-out on day 0, Bay 3 on day 1), the second time with nothing new. Overexposed clues stop being clues. The second telling should add an object: Frank's green brake log.
- **Dale Hatch isn't on screen.** The killer needs to be the friendliest man in the first chapter. Right now he doesn't exist yet.
- **Toby and Tremblay are names, not people.** Toby has one text; Tremblay one brief. Both need a scene in Chapter 1, and Toby needs his clue.
- **The prologue drive cheats.** `last_call` ends on a crash, a 34-second timer, *or* doing 120 km/h after 8 seconds. A careful player who crawls home still "crashes" when a timer runs out, which reads as the game lying. Make it honest: impairment gets worse with time, and at the Airstrip 7 approach Leo has a **microsleep** (screen fades to black for 0.8 s, the engine note drops away, then the fence). Impaired drivers do this. It's his fault, not a timer's.

#### Pacing
- The prologue runs about 40 minutes: four scenes, three drives, the avatar screen and a full tutorial shift. That's right for a prologue, but **the avatar screen lands in the middle of the hangover** and stops the story cold. Move it to first boot (section 2.7).
- Target rhythm once the day loop is merged: **a day is a counter shift (8 to 12 minutes), a clock-out beat (1 to 2 minutes) and an evening (5 to 15 minutes).** At most one major story scene per day, and **every third day has no scripted scene at all** so the systems can breathe. A chapter is 3 to 4 hours.
- Each chapter has four seasons. Use the season changes as act breaks (fall setup, winter crisis, spring turn, summer payoff), with a "SIX MONTHS LATER" card only where nothing happens that the player would want to play.

#### Character voices (the rule for each, to write to)

| Character | Voice rule | Already good | Needs |
|---|---|---|---|
| **Leo** | Deflects with car talk and self-roasts; sincere only with Aries, late at night | "It's singing." | Signature lines, fewer straight questions |
| **Gus** | Five-word sentences. Never says what he feels; says what the car needs | "You look like something I'd drain out of a transmission." | Restraint: he should talk less, not more |
| **Mikey** | Earnest stoner, loyal to a fault, misuses one big word per scene | "u are an emergency" | A serious moment per chapter |
| **Aries** | Lowercase texts, sharp, fourteen going on forty | "thats the mafia leo" | Scenes where she's a kid, not just a wise one |
| **Toby** | Blunt, practical, tow-truck jargon; tells the truth to your face | (one text) | A scene. "I towed you. I didn't tow your excuses." |
| **Dom** | Grace, family, food; never raises his voice | The grace | Moments where the menace shows |
| **Mia** | Numbers, precise, deadpan threats; grief she won't name | "My dad built it." | The books as her love language |
| **Sal** | Understatement; the only one who says what everyone sees | "He was chasing himself." | Small kindnesses, so Chapter 6 hurts |
| **Darrell** | Lies and contradicts himself in the same sentence | Every line | Keep him exactly like this, and pay him off |
| **Tremblay** | Tired, decent; counts Leo's chances out loud | (one brief) | A scene; her own guilt about Frank's report |
| **Dale Hatch** | Warm salesman; calls Leo "kid"; calls Frank **"Frankie"** (nobody else does, and Gus flinches every time; when a kid named Frankie starts hanging around the shop in November 2019, Gus says so out loud) | (absent) | An introduction in Chapter 1 |
| **The old manager** | Absent, then nervous, then brave | (one mention) | A presence through paperwork |

#### Foreshadowing
- **Good:** Gus's Sunday brakes; "twenty years sober" at the party; "Dad used to say that"; Dom knew Frank.
- **Missing:** the killer on screen, a chain of physical objects (a log book, a carbon copy, a tool), the place (Frank's road), and **the corner.** The concept has Leo crash with Aries "on a corner he's taken a thousand times." Establish that corner in the prologue drive and use it in every chapter: the S-bend on Mountain Road below the Tim Burtons. It needs to be the most familiar corner in the game by the time it matters.
- **Aries in the passenger seat** should be a normal, nagging thing from Chapter 1 ("Seatbelt.") so that her absence in it is unbearable later.

#### Continuity bugs and house-rule risks (fix list)

| # | Where | Problem | Fix |
|---|---|---|---|
| 1 | `STEPS`, card after `the_meet` | The meet is "FRIDAY NIGHT"; the card says "THE NEXT MORNING"; the counter tutorial is Monday 7 October 2019 | Card: `"MONDAY"`, small `"7:58 A.M. COVINGTON AUTO"`. Gus: "Toby towed what's left of your father's car in Saturday at six." |
| 2 | Counter tutorial brief | `{MANAGER}` prints the avatar's name minutes after the player typed it, so the twist is spent on day 0 | Use "THE OLD MANAGER'S MUG" in Years 1 to 2. Never print the name until the USB chase |
| 3 | `BRIEFS[0]` | "YOUR DAD RAN IT TWENTY YEARS" contradicts Gus saying the old manager ran the counter | "YOUR DAD RAN THIS SHOP TWENTY YEARS. THE COUNTER WAS SOMEBODY ELSE'S. NOW IT'S YOURS." |
| 4 | `clock_out_1` and `bay_three` | The brakes clue twice, nothing new the second time | `bay_three` adds the green brake log: "He wrote it down. Every Sunday. Little green book. Nobody knew about that book but me and you kids. It wasn't in the car when Toby towed it." (That second sentence is the line Hatch trips over in Chapter 8; Leo's notebook records it.) |
| 5 | `party` | "the Coast Road" isn't on the map | "goes off Lutes Mountain Road with a forty in him?" (section 2.2) |
| 6 | `data/cars/silvio.json` | "31 years old" in a game set in 2019 | "28 years old" |
| 7 | `runs_great` | `checked_silvio` changes nothing | Checking the hood reveals the milkshake; Leo gets it for $790 and the drive home warns about the gasket. `blind_buy` pays $840 and finds out on the road |
| 8 | `home_night` | `cocky` / `quiet` / `joke` unused | Aries: "mikey says you told him you're a professional." (or "...said 'yeah.' that's it. just 'yeah.'") |
| 9 | `the_meet` | Nobody explains why Leo isn't charged | Dom: "Nobody called the police. You're welcome. That's the first thing family did for you." (That's also the leverage.) |
| 10 | `last_call` | Hidden timer ends the drive | Microsleep beat at a fixed spot near Airstrip 7 |
| 11 | `story/avatar_scene.gd` placement | Interrupts the story; telegraphs the twist | Move to first boot (section 2.7) |
| 12 | Concept, Chapter 3 | Nate Boudreau, an undercover cop infiltrating street racing, is the Brian O'Conner role the house rules exclude | Make Nate clearly original: a 48-year-old Ministry of Transport fraud investigator from Edmundston, Acadian, hates driving fast, carries a binder |
| 13 | Concept, cast | "Jake Tortellini: 'You can't see me'" parodies a real wrestler's catchphrase, and Jake is in the Familia, which is crime content | Drop the catchphrase. Jake's gag: he's always "just leaving" and nobody ever sees him arrive |
| 14 | Concept, cast | Parodies of movie characters (Huge Hobbs, Han Lunchbox...) must not look or talk like the actors | Portrait seeds chosen to avoid any likeness; no catchphrases from the actors' own careers |
| 15 | Calendar | Eight years from October 2019 cross 2020 to 2022 | Decide once. Recommendation: Port Rumble's calendar never mentions the pandemic, but MarketThing prices rise about 30% in Year 3 and fall in Year 5, mirroring the real used-car squeeze of 2021 and 2022. Nobody explains it; the old-timers just complain |
| 16 | `counter/rules.gd`, `CARS` | `KIA SOLE` uses a real make unchanged, and `GOLF` and `GRAND CARAVAN` are real model names | `KEEYA SOUL-LESS`, `VOLKSWAGON GULF`, `DODGY GRAND CRAVIN'`. (`world/player_car.gd` checks for `"CARAVAN"` in the name to pick the van body; update that test too) |

### 2.2 The backstory (the timeline the whole game hangs on)

| Year | What happened |
|---|---|
| **1971** | Walt Covington (Leo's grandfather) opens Covington Auto on the corner. The coffee maker arrives in 1974 and has not been cleaned since |
| **1981** | Gus Arsenault, 32, starts working Saturdays for Walt. He never stops |
| **1985 to 1987** | Frank Covington (born 1969) and his best friend **Dale Hatch** are the two fastest kids in Port Rumble. Frank drives, Dale navigates and talks. They run a stolen-car pipeline to the port for an older crew; **Gus welds the hidden compartments in Bay 3 and takes the money.** Frank's car is a 1987 **Fjord Mustank GT**, "the Fox" |
| **1989** | Dom Tortellini, 16, brings his first car to Covington Auto. Frank fixes it on credit and never asks for the money |
| **1995** | Dale Hatch opens Hatch Motors with money nobody asks about. The pipeline is now his, run through his used lot and the Docks |
| **1998** | Frank gets sober |
| **2000** | Leo is born. Frank takes over Covington Auto from Walt and goes straight for good. Frank hires a manager for the front counter: **the old manager** (the player's avatar) |
| **2005** | Aries is born. Their mother leaves when Aries is three; she's in Alberta and sends cards on the wrong birthdays |
| **Nov 2018** | A car off Hatch Motors' used lot comes through the counter for inspection with a ground-off VIN and a hidden compartment welded the way Gus welded them in 1987. Frank sees it in Bay 1. He starts keeping a ledger. On Sunday 2 December he replaces all four brake lines on the Fox and writes it in his green brake log. He tells a Ministry fraud line he has something (that tip becomes "cooperating witness" in a file Nate shows Leo in Year 3) |
| **Thu 6 Dec 2018** | First snow. Frank drives the Fox up **Lutes Mountain Road** to the lookout to meet "D." and bring the ledger. Dale cut the rear lines on the Fox in Covington Auto's lot that afternoon (he still has a key from 1987) while Frank was inside with a customer. Coming down the mountain, the pedal goes to the floor. The Fox goes through the guardrail at the hairpin above the towers |
| **7 Dec 2018** | Constable Tremblay is first on scene: no skid marks in fresh snow. Toby tows the Fox. Sgt. **Roy Pelletier** (Hatch's friend since high school) writes the report: driver impaired, BAC 0.14, brakes "worn and neglected". The blood sample was never Frank's. The ledger and the green log are gone |
| **Dec 2018** | The day after the funeral, a man visits the old manager's house and tells them they've had a long career and it's over. The manager quits the next morning and leaves the mug. **Pelletier retires in January 2019** to a nice house in the Heights, paid by "consulting fees" from a numbered company |
| **Jan 2019** | The Fox goes from the police impound to a "salvage auction" and disappears into Hatch Motors' back lot |
| **Oct 2019** | The game starts. Leo, 19, is ten months into thinking his dad drank himself off a mountain |

**Why Lutes Mountain Road and not the Coast Road.** The map in `world/map_data.gd` runs from Port Rumble to Salisbury and Havelock; it has no coast. It does have Lutes Mountain Road, a rural road climbing to the towers whose red beacons are drawn "so you can see them from everywhere." A brake failure kills on a descent, and a hairpin under a blinking red light is a place the player will never stop seeing. And the Tim Burtons on Mountain Road, where Leo buys the Silvio in the prologue, sits on the road that leads up there. The concept's coast (the Flats, the lighthouse, Shediac-style lobster country) becomes a later map expansion east along Shediac Rd; nothing in the main story needs it.

### 2.3 The expanded outline

Eight chapters, one per year, as in the concept, each a fall-to-summer year that starts in October. Every chapter lists its goal, the desk, the drives, the cutscene beats, the Frank clue and the choice that matters.

#### PROLOGUE: "LAST CALL" (Friday 4 to Monday 7 October 2019, Leo 19, Aries 14)

**Goal:** wreck everything, owe the Familia $4,200, buy a terrible car.

| Step | Type | Beat |
|---|---|---|
| Party (warehouse, Industrial Dr) | Scene | Mikey, the breathing speaker, "Ten months tomorrow." Keys in Mikey's hat. Choice: cocky / quiet / joke |
| LAST CALL | Drive | Dad's 1986 Toyoda Supreem, drunk and high, drizzle, fall. **Pass the S-bend below the Tim Burtons on Mountain Road** (the corner, first time). Billboard on the way: HATCH MOTORS: WE'LL TREAT YOU LIKE FAMILY. Microsleep at the Airstrip 7 fence |
| The meet (Airstrip 7) | Scene | As written, plus Dom: "Nobody called the police. You're welcome." Choice: agree / defiant |
| MONDAY | Card | 7:58 A.M. COVINGTON AUTO |
| Gus's morning | Scene | As written, plus **Toby** walks in with the Supreem's bumper: "Brought you this. It's the only part of your dad's car that's still a part." To Leo: "You were hammered. I towed you. I didn't tow your excuses." |
| Counter tutorial | Desk | As written, minus the name on the mug |
| Clock-out | Scene | Gus's first brakes line, Aries's texts, Mikey's MarketThing find, Toby lends the wrecker |
| RUNS GREAT | Drive | Toby's wrecker to the Tim Burtons on Mountain Road |
| Darrell | Scene | As written, with the `checked_silvio` fix |
| IT RUNS. GREAT. | Drive | Home with a blown head gasket, past the Hatch billboard again, lit now |
| Home | Scene | Aries, with the flag callback. "Dad used to say that. Right up until." |

#### CHAPTER 1: "WRONG TURF" (Year 1: October 2019 to September 2020, Leo 19)

**Goal:** pay off the $4,200, keep the inspection licence through the first Ministry audit, learn to launch from Dom, beat Johnny Tram's crew (Tier 1, Downtown back streets), survive the first winter and the first anniversary.

- **The desk:** weeks 1 to 8 of the rule escalation (section 3.8). Scripted customers: **Dale Hatch** (week 2, the Wednesday after Thanksgiving) brings a Hatch Motors used car himself because "my guys are swamped," calls Leo "kid", calls Frank "Frankie", offers to buy Covington Auto "at a fair price, for Frank's kids." Constable Tremblay drops the BOLO list. The Familia's napkins from Thursday. Darrell's trade-in with a rolled-back odometer (week 3). The Ministry Inspector's first audit (week 7). A Christmas card for Frank from the old manager (week 11).
- **The drives:** DETAILING (exists). LAUNCH CONTROL: Dom's three medal tests at Airstrip 7 (reaction, 60-foot time, shift light). PIZZA DELIRIUM: Year-1 money. TOBY'S NIGHT SHIFT: a sleet-storm ride-along in the wrecker, hooking up wrecked traffic cars. FIRST SNOW: winter tires or suffer; drive to Lutes Mountain on 6 December. HATCH DYNO DAY at Airstrip 7. JOHNNY TRAM: four crew members, then Johnny, then the pink slip for his Hondo S2-Thousand.
- **Cutscene beats:**
  - Mia's books: "I don't do feelings. I do columns." She shows Leo the ledger of what he owes, in pencil, so it can go down.
  - Aries's hockey game. Leo comes, cheers too loud. "never do that again. (do it again)"
  - **Toby on the night shift,** parked on Coverdale Road in the sleet: "I towed your dad off the Mountain. First snow. You know what I didn't see? Skid marks. Fresh snow, and not one. Man checks his brakes every Sunday for twenty years and doesn't even touch them on the way down?"
  - **The anniversary (6 December).** Leo drives up the Mountain to the hairpin. No objective but to stop. Gus's truck is already there. They stand at the guardrail. Gus: "He'd have hated the flowers." Leo: "I know." They don't say anything else. The towers blink.
  - **Hatch's dyno day.** Hatch Motors sponsors it. Leo pulls numbers in the Silvio; Hatch claps him on the back: "Frankie would've loved this." Gus, behind them, puts his coffee down.
  - Spring: the debt hits zero. Dom at the barbecue: "Now you work for family because you want to." **Choice:** keep Bay 3 open for the Familia, or close it (sets the Familia path).
- **The Frank clues:** the missing green brake log (Gus); no skid marks (Toby); **sticker 0448 is missing from the inspection sticker log** (a desk discovery: the sticker log is a document from week 5; the player can inspect the gap between 0447 and 0449 and Gus says, very quietly, "Forty-eight was your father's.").
- **End card:** CHAPTER 1 COMPLETE, the family barbecue, who sits where.

#### CHAPTER 2: "SIDEWAYS" (Year 2: October 2020 to September 2021, Leo 20)

**Goal:** learn to drift from Han Lunchbox in the Heights parkade, beat the Drift Kingpin down Magnet Hill in fall leaves, open Bay 2 and hire a mechanic, show up for Aries when it counts, and find Frank's tapes.

- **The desk:** salvage brands, the second and third VIN locations, tint, exhaust noise, studded tires. **Hiring:** applicants' résumés and references are documents with lies to catch. Twinkee's parts with serials on the BOLO. **Hatch Motors' fleet partnership** starts: a Hatch car a day, papers always perfect, $150 bonus per stamp. (This is the hidden faction. Count every one.)
- **The drives:** Han's parkade lessons (medal tests). LEAF PEEPERS: a tandem in wet leaves. PRINCIPAL'S OFFICE: the school calls during the shift; Aries is suspended for fighting. **Leaving the counter mid-shift costs the rest of the day's customers,** and the drive is across town at 2:30 p.m. (the first time the two modes collide on purpose). MOOSE RUN: the highway at night in hunting season. BARN FIND: Mikey's tip, out past Havelock. THE KINGPIN: tandem battles down Magnet Hill.
- **Cutscene beats:**
  - Aries suspended: she hit a kid who said Frank was a drunk. Leo can't tell her she's wrong, because he believes it too. That's the scene.
  - **The attic.** A shoebox of Frank's cassette tapes (the 40 collectibles). Leo plays the first one in the Silvio's tape deck, parked in the bay. Frank's voice about a carburettor and a seven-year-old Leo in the background asking what a carburettor is. Aries listens to one and says, "He sounds like you when you're tired."
  - Gus won't listen to the tapes. He leaves the room when one plays.
  - Mikey moves onto the apartment couch "for a week" and is still there in Chapter 4.
- **The Frank clues:** **Tape 7, "Sunday Brakes":** Frank, December 2018: "New lines on the Fox, double-flared, they'll outlive me." **Tape 12:** "D. says it's just paperwork. It's never just paperwork." Leo decides D. is Dom. (He's wrong; it's the red herring that drives Chapters 3 to 6.)
- **Choice:** confront Dom about "D." now (Familia trust drops, Dom is hurt, not angry) or keep it to himself.

#### CHAPTER 3: "TOO FAST, TOO SERIOUS" (Year 3: October 2021 to September 2022, Leo 21)

**Goal:** the USB job, the old manager, a stranger with paperwork that's too clean, teaching Aries to drive, beating Roman Purse (Tier 3, Downtown).

- **The USB job opens the chapter** (section 2.7). It ends with the old manager's carbon copy of inspection 0448 and a fried work computer.
- **The desk:** a new computer arrives, bought cheap on MarketThing from a guy named Nate. **Nate Boudreau** (Ministry of Transport fraud investigator, 48, Edmundston, hates speed) starts appearing at the counter with paperwork that's too clean: folds too crisp, a font that matches across three "different" documents, an Edmundston accent he forgets to hide. Over two weeks the player collects his tells with the inspect tool. Then the choice: **burn him** (tell Dom), **protect him** (say nothing), or **recruit him** (trade information).
- **The drives:** AT 10 AND 2: Aries's parking-lot lessons in the Silvio at Champagne Place (you sit in the passenger seat; her driving is AI, your inputs are coaching prompts; a patience meter). THE ROAD TEST: you sit on the bench outside the Ministry office and watch through the window; her result depends on your lessons. ROMAN PURSE: he talks for twenty minutes and loses in eleven seconds (an eighth-mile drag at Airstrip 7).
- **Cutscene beats:**
  - Aries passes (or fails the first time and passes on the retake, two weeks later). Her texts in all caps for the only time in the game. The photo on the fridge.
  - Mia starts driving Aries to practice when Leo forgets. They become friends. This is quiet and it's important.
  - Nate, cornered, shows Leo the file.
- **The Frank clues:** the carbon copy (brakes new in November 2018, passed, signed by Frank and the old manager); **Nate's file:** "COVINGTON, F. Contacted fraud line 2018-11-29. Pending interview. DECEASED 2018-12-06." Frank was going to the police. Leo is now sure it was the Familia.

#### CHAPTER 4: "FIVE-OH" (Year 4: October 2022 to September 2023, Leo 22, Aries 17)

**Goal:** survive Agent Huge Hobbs's task force, pull the vault job, survive the audit. The chapter's real subject is Leo's drinking, and it ends with Aries.

- **The desk:** checkpoints mean more cops at the counter; Hobbs's people "just looking"; the audit minigame (the books, with Mia). Customers offer bottles as tips. THE BOTTLE starts talking at the counter.
- **The drives:** checkpoint runs, Han's "death" (a staged crash; #JusticeForHan trends), THE VAULT (two cars, one safe, Downtown at night), the Hobbs pursuit and his cheating truck.
- **The systemic slide:** stress stays high, cravings show up as THE BOTTLE's lines, and the evening menu keeps offering a drink. The player can refuse every time. Leo, in cutscenes, doesn't. (The concept: the game never lectures, but it never pretends.)
- **The night (end of September 2023, rain, late summer).**
  - The vault job pays. The celebration at the warehouse from the prologue. Mikey hides Leo's keys in his hat again. Leo: "Give me my keys, Mikey." Mikey: "They're in my hat because I love you, you dumb fuck." Leo takes them.
  - Mia calls Leo fourteen times. Aries comes to bring him home. She says "Seatbelt." He drives anyway.
  - A Hobbs patrol lights him up on Main. He runs. **You are driving.** It's raining. The S-bend below the Tim Burtons on Mountain Road. The corner he's taken a thousand times.
  - The game doesn't let you save her and doesn't pretend it was anyone else's fault. No meme screen. No music. No blips. White text on black.
  - Tremblay is first on scene. Toby gets the call and recognises the car before he's out of the truck. **Tremblay writes the report straight:** driver impaired, driver at fault. It's the opposite of the report on Frank, and nobody says so.
- **No Frank clue this chapter.** Bleeter goes quiet. The radio plays one song.

#### CHAPTER 5: "NINETY DAYS" (Year 5: October 2023 to September 2024, Leo 23)

**Recommended change from the concept:** a Canadian court would jail Leo and take his licence for years. Players will notice if he's back behind the wheel by spring. So Chapter 5 is the custody year.

**Goal:** the funeral, the plea, the first ninety days sober inside, and keeping Covington Auto alive from a phone in a visiting room.

- **The funeral** opens the chapter. Played straight. Everyone is there; Dom doesn't say grace.
- **Leo pleads guilty.** The sentence (fiction, but plausible): custody, then a long driving prohibition, then an ignition interlock.
- **The desk without Leo:** **Mikey runs the counter.** It's the tutorial again, with Mikey: "I read every paper. Like you said." He's good at it. It's the saddest funny thing in the game. Mia keeps the books. Gus does everything else.
- **The drives:** you drive **as the crew** (section 3.1): Gus's slow, careful truck with the radio off; Toby's wrecker on tow calls; Mikey's errands. Mechanically it's the same game; emotionally it's the shop holding together without its owner.
- **Visiting room scenes** (VA-11 Hall-A style conversations on a fixed set, once a week): Gus brings the soup Leo hates; Mikey brings news from the counter; Tremblay comes once, leaves a double-double, says nothing; Hatch comes once: "Frankie would've wanted me to look out for you. I've got a lawyer for you. No charge, kid."
- **Days sober** count up on the end-of-week screen from day 1. The vices menu is locked behind cravings that spike on the anniversary and on Aries's birthday.
- **The Frank clue (the big one):** Darrell lists a parts car on MarketThing: "PARTS CAR. RAN WHEN PARKED. FJORD MUSTANK 87. SELLING FOR MY WIFE'S HUSBAND." It's the Fox. Leo, from the visiting-room phone, tells Mikey to buy it. On the lift, Gus finds the rear brake line **cut clean with a tubing cutter** (a spiral score, not a tear), and in the glovebox, Frank's **green brake log.** Last entry: "Sun Dec 2. All good. New lines holding. Thurs: meeting D. at the lookout. Bringing the book."
- **Release (June 2024).** Dom picks Leo up at the gate in the black Charjer. They sit on the hood at Airstrip 7 at 3 a.m. Dom: "I'm not going to say grace tonight. I don't think He's listening to me right now. Let's just sit." End card: DAYS SOBER: 271.

#### CHAPTER 6: "FAMILY BUSINESS" (Year 6: October 2024 to September 2025, Leo 24)

**Goal:** expose the export pipeline at the Docks, find the leak inside the Familia, beat Wreckard Shaw (Tier 4) in the container yard, and do it all without a licence.

- **Leo can't legally drive.** Missions are driven by the crew (Toby will only drive legal jobs; Mikey will drive anything, badly; Gus won't race). Or **Leo drives anyway**: faster, more options, the street path, and if he's stopped it's the STUNG fail ending. This is the Papers, Please pressure in the driving half.
- **The desk:** shipping manifests arrive at the counter. **They list VINs from the player's own counter history** (the save keeps every VIN the player stamped). The cars you DENIED in Year 1 went to the port anyway. And every **Hatch Motors fleet car** you stamped in Year 2 is on a manifest. The game tells you the count.
- **Leo confronts Dom about "D."** Dom: "D. is not me. I don't sign with one letter. I sign in full, on the cake." He's telling the truth.
- **The leak is Sal.** He's been feeding the Familia's routes to Hatch Motors, because he owes Hatch Motors' lending arm more than his house is worth. The barbecue is very quiet. **Choice:** tell Dom (Sal is "retired" to Alberta: Familia trust up), cover for Sal (he becomes Leo's informant inside Hatch Motors), or give him to Tremblay (law up, Familia trust down).
- **Gus's confession** in the bay, at night, with the Fox on the lift: 1987, the welds, the money, and Frank quitting when Leo was on the way. "Your father had a co-driver. I won't say his name in this shop." Then Gus has a heart attack. You drive him to the hospital (the crew drives if you're legal; Leo drives if he's not, and that's the one time the game doesn't count it against him).
- **Boss:** Wreckard Shaw in the container yard, cranes moving the course.
- **The Frank clue:** the pipeline started in the 80s, and Frank had a co-driver.

#### CHAPTER 7: "SIPHON" (Year 7: October 2025 to September 2026, Leo 25)

**Goal:** get the licence back, survive Siphon's hacked city, follow the money.

- **The ignition interlock.** Leo's licence comes back with a breath interlock. **Every time he starts a car, the player blows into it** (hold a button, a short meter). It's not a punishment screen; it's a ritual. In the first evening of the chapter Leo sits in the Silvio for a full minute before he starts it, and the game lets him.
- **Aries's driving notes** in the Silvio's glovebox: "LEO: CHECK MIRRORS. LEO: FULL STOP AT THE STOP. LEO: DON'T BE DAD." She believed what everybody believed.
- **Siphon** hacks every car with a modem. Old carbureted junk is the only thing that runs, so Leo's '91 Silvio, Gus's rebuilt '86 Supreem (returned to Leo on release day, Gus's slow project since the prologue) and the Fox's donor parts become a fleet. Han returns, snack in hand. The endless runway at Airstrip 7 against a cargo plane. **Boss:** Siphon, a highway run where the traffic is trying to kill you.
- **The callback:** Siphon, beaten: "Nice job with the USB in Year 3, by the way. Who do you think wrote that tip?"
- **The Frank clue:** Siphon was paid by **514207 N.B. Ltd.** Mia follows the money (her books are her love language): the same numbered company paid Sgt. Pelletier's "consulting fees" in January 2019, holds Sal's loans, and **bought Covington Auto's building from Landlord Bertrand in Year 2.** Leo's landlord. The director of record is Dale Hatch.
- **Choice (Mia's kitchen table):** take it to Tremblay (Clean), let the Familia handle it (The Street), or make him sign (Kingpin).
- **End card:** FIRST SNOW IS FORECAST FOR THURSDAY.

#### CHAPTER 8: "THE MOUNTAIN" (Year 8: October to December 2026, Leo 26)

**Goal:** prove it, and finish it where it started.

- **Hatch's showroom** has a "Frankie Covington" memorial display: photos from 1987, a trophy, and Frank's **tubing cutter** with an F scratched into the handle. Gus, on a cane, sees it from across the room: "That's Frank's. He scratched an F in everything he owned. Including me."
- **The desk is the climax.** Hatch brings his own Charjer in for its inspection (he always has; it's a show of trust). The papers are perfect. The player has to catch him in what he *says*. Hatch, small-talking: "Frankie and his little green book. Every Sunday." The player inspects that line against Leo's notebook, where Gus's Chapter 1 line is recorded ("Nobody knew about that book but me and you kids"), and the game highlights **DISCREPANCY: HOW DOES HE KNOW ABOUT THE BOOK?** It's Papers, Please's inspect tool turned on the killer. Hatch sees Leo's face and stops smiling.
- **The challenge:** Leo offers the green book as the pink slip. One run, the first snow of the eighth winter, at night, down Lutes Mountain Road, in the Fox (rebuilt from the MarketThing parts car, Frank Spec everything). Mikey reads pace notes ("Left three, don't cut, Dad's tree").
- **The endings** follow (section 2.6). **Credits:** the family barbecue, a memoriam card for Frank and one for Aries, the crew, and, last name in the cast list, the player's avatar as The Old Manager.

### 2.4 Character arcs

| Character | Starts | Turns | Ends (depends on path) |
|---|---|---|---|
| **Leo** | Drunk, grieving, sure his father was a drunk and afraid he's the same | Ch4: becomes exactly what he thought his father was, and it costs Aries. Ch5: sober inside. Ch7: the interlock ritual | Clean: sober, the shop legit, a plaque with two names. Street: Dom's chair. Kingpin: rich, alone, a speaker breathing in an empty house |
| **Aries** | 14, sharp, raising herself, lowercase texts | Ch2: suspended for defending Frank. Ch3: learns to drive, passes, ALL CAPS. Mia becomes her friend | Dies in Ch4. After: her room Leo can't enter, her empty crew slot, her notes in the glovebox, her name on the plaque |
| **Gus** | 70, knows more than he says, every Saturday since 1981 | Ch1: the brakes, the anniversary. Ch6: confesses 1987, heart attack | Clean: retires to fish, comes in Saturdays anyway. Kingpin: stops coming in on Saturdays. Street: keeps coming, never speaks of it |
| **Toby** | Pulls Leo out of ditches; the truth to his face | Ch1: the skid marks. Ch4: the call. Won't tow for Leo until Ch7: "I'm not doing it for you. I'm doing it for her." | Clean: tows Hatch's car to impound. Street: tows Hatch's car off the Mountain, and tells Leo exactly what he thinks of him |
| **Mikey** | Best friend, stoner, keys in his hat | Ch4: the hat again, and he can't stop Leo. Ch5: runs the counter, grows up | Opens Mikey's MarketThing Detailing. In every ending he still has the hat |
| **Dom** | Grace, debt, menace with manners | Ch2: suspected. Ch5: no grace at the gate. Ch6: cleared, betrayed by Sal | Clean: retires to Shediac to sell hot dogs. Street: hands Leo the meet. Kingpin: an uneasy partner who never says grace at Leo's table |
| **Mia** | Wants Leo dead over a car their father built | Ch1: columns. Ch3: Aries's friend. Ch5: keeps the shop afloat. Ch7: follows the money | Clean: Covington Auto's bookkeeper, legit. Kingpin: partner. Street: runs the Familia |
| **Sal** | Dry, kind in small ways, always there | Ch6: the leak, because he's drowning in Hatch Motors debt | Retired to Alberta, informant, or in custody, by the player's choice |
| **Darrell** | Sold Leo a lie for $840 | Recurring liar; Ch5: sells the Fox without knowing what it is | Clean: the surprise witness. He worked Hatch's back lot in 2019 and recognises the auction paperwork trick. His wife Brenda finally appears, and she's the one who kept the receipts |
| **Dale Hatch** | The friendliest man in Port Rumble: sponsor, mentor, "kid" | Ch2 to 6: the fleet partnership, the lawyer, the visit. Ch8: the slip at the counter | Arrested at the bottom of the Mountain (Clean), through the guardrail at the hairpin (Street), signs it all over on the hood and leaves the province (Kingpin) |
| **Const. Tremblay** | Counts Leo's chances out loud: "That's one." | First on scene for Frank (no skid marks, didn't push her sergeant) and for Aries (writes it straight) | Clean: reopens Frank's file and finally pushes. Street: knows and can't prove it. Kingpin: transfers to Fredericton |
| **The old manager** (the avatar) | Absent: a mug, initials on old paperwork, a coffee-stained staff photo | Ch3: the USB chase. Scared, not guilty; kept the carbon copy | Clean: testifies, then comes back to the counter for one day to train Leo's new hire. Credits: "{NAME} as The Old Manager" |

### 2.5 The Frank clue trail

| # | Chapter | How the player finds it | What it shows | What Leo concludes |
|---|---|---|---|---|
| 1 | Prologue | Party: "Twenty years sober" | Leo doesn't believe the report | Grief talking |
| 2 | 1 | Gus at clock-out | Frank checked his brakes every Sunday | Weird |
| 3 | 1 | Gus in Bay 3 | The green brake log wasn't in the wreck | Someone took it |
| 4 | 1 | Toby's night shift | No skid marks in fresh snow | The brakes were gone before the corner |
| 5 | 1 | **Desk:** sticker log gap, 0447 to 0449 | Frank's own inspection record is missing | Someone pulled it |
| 6 | 2 | Tape 7 | New lines in late November 2018 | The report's "worn brakes" is a lie |
| 7 | 2 | Tape 12 | "D. says it's just paperwork" | D. is Dom (wrong) |
| 8 | 3 | USB chase: the old manager's carbon copy | 0448: brakes new, passed, signed | Frank was sober and his car was safe |
| 9 | 3 | Nate's file | Frank called the fraud line a week before he died | The Familia killed him (wrong) |
| 10 | 5 | The Fox on the lift | Line cut with a tubing cutter; the log: "meeting D. at the lookout" | It was murder |
| 11 | 6 | Gus's confession; Dom's denial | The pipeline, 1987, Frank's co-driver | D. was the co-driver |
| 12 | 7 | Mia follows Siphon's money | 514207 N.B. Ltd paid Pelletier, holds Sal's loans, owns the building; director Dale Hatch | It's Hatch |
| 13 | 8 | Hatch's showroom | Frank's tubing cutter, scratched F | The weapon |
| 14 | 8 | **Desk:** Hatch mentions the green book | Only the killer could know | The confession |

The **evidence** meter is the set of clues 3, 5, 6, 8, 10, 12 and 13 the player actually *collected* (some can be missed; a missed carbon copy arrives in the mail a week after a lost chase, so nothing locks the story, but optional ones like the sticker log gap can be skipped).

### 2.6 Factions, meters and endings

**Meters** (all in `StoryState`): `family` (Familia trust, -100 to 100), `law` (police trust, 0 to 100), `heat` (attention, 0 to 100, decays 5 a week), `ministry` (citations in the last 30 shift days), `shop_rep` (Yowl stars, 1.0 to 5.0), `street_rep` (0 to 1000), `hatch` (hidden: Hatch fleet cars stamped), `evidence` (clue ids), `sober_days`, `stress`, `debt`, and each crew member's `loyalty`.

**The three endings and their variants** (decided at the Chapter 7 choice, gated at the Chapter 8 finish line):

| Ending | Gate | What happens | Variants |
|---|---|---|---|
| **CLEAN** | Chose Tremblay in Ch7; evidence includes 8, 10, 12 and 13; law ≥ 50 | Cruisers wait at the bottom of the Mountain with their lights off. They flip on as Hatch crosses the line. The trial is a Daily Clutch front page. Covington Auto goes fully legit; the new bay has a plaque: FRANK COVINGTON. ARIES COVINGTON | **Clean and Covington** (shop_rep ≥ 4.2, debt 0): the shop thrives. **Clean and broke** (debt > 0): the building's sold off with Hatch's assets; Leo works the counter at Lindsay's, sober, and it's still a happy ending |
| **THE STREET** | Chose the Familia in Ch7; family ≥ 40 | At the last hairpin, Hatch's brake pedal goes to the floor. Somebody in the Familia cut his lines that afternoon, the way he cut Frank's, and Leo knew. Hatch goes through the guardrail at the same spot. Leo stops, gets out, looks, and decides whether to call it in. "You become what Dom was" | **Grace:** at the next Friday meet, Leo bows his head and says grace. **The call:** Leo calls Toby. Toby: "I'll tow him. I won't tow your excuses." |
| **KINGPIN** | Chose Mia's plan in Ch7; evidence includes 12; street_rep ≥ 600 | At the bottom of the Mountain, Leo puts the papers on the Fox's hood. Hatch signs Hatch Motors over and leaves the province. Leo owns the city. Gus stops coming in on Saturdays | **Kingpin, sober:** rich and lonely, the plaque in a showroom nobody visits. **Kingpin, last call** (sober_days < 180): the final shot mirrors the party: Leo alone in a house in the Heights, staring at a speaker that breathes |

**Fail endings** (Papers, Please-style: a Daily Clutch front page, a short epilogue, then **RESUME FROM** any of the last 14 shift days or any chapter start):

| Ending | Trigger | Front page |
|---|---|---|
| **LICENCE REVOKED** | 12 citations in 30 shift days, or the third Ministry meeting | "COVINGTON AUTO LOSES INSPECTION LICENCE; 'WORLD'S OKAYEST BOSS' MUG SEIZED" |
| **STUNG** | Bay 3 work on a sting with heat ≥ 60, or caught driving under prohibition in Ch6 | "LOCAL GARAGE A CHOP SHOP, POLICE SAY" |
| **FAMILY BUSINESS** | family ≤ -80 | "YOUNG MECHANIC LEAVES TOWN ON THE 6 A.M. BUS. 'GO WITH GOD. GO FAR,' SAYS UNIDENTIFIED HOT DOG CUSTOMER" |
| **THE BANK TAKES THE LOT** | The till below -$5,000 on three Sundays running | "CONDOS PLANNED FOR COVINGTON CORNER" |
| **OUT WEST** | Choose to leave at the Ch5 or Ch7 crossroads, or broke with crew loyalty all below 20 | "ANOTHER ONE GONE TO ALBERTA" |
| **LAST CALL** | A fatal crash while impaired, any time after the prologue | No front page. White text on black: the date. Nothing else. No meme |

### 2.7 The USB job, placed and scripted

**Where it sits:** the opening of Chapter 3 (October 2021). Late enough that the player has forgotten making the avatar; early enough that the tone can still carry a fourth-wall joke (it must come before Chapter 4).

**Move the avatar to first boot.** On the very first launch, before the title screen: "SET UP YOUR PROFILE. THIS IS THE FACE AND NAME WE'LL USE IF DRIVEBOSS EVER GETS ONLINE PLAY." The joke survives, the story doesn't stop, and the player won't connect the avatar to a mug two scenes later. In Years 1 and 2 the old manager appears only as:
- the WORLD'S OKAYEST BOSS mug;
- **initials** in the "INSPECTED BY" box on old service-history entries at the counter (the avatar's initials);
- a staff photo above the filing cabinet with a coffee ring over one face (the avatar's portrait, half-hidden);
- the Christmas card in Year 1: "Thinking of you all. I'm sorry I left the way I did. Merry Christmas. -" and the initial.

**The beats:**
1. **The tip.** An unknown number texts Leo: "The old manager kept files on the shop PC. Check them. Tonight." Mikey's cousin **Kevin "Kernel" Gaudet** (17, wears a headset to the dépanneur) brings a USB stick and an earbud: "Plug it in and DON'T touch anything. Touching is how they get you."
2. **The plug-in** (after closing, the counter set at night). The consent screen from the concept, in plain words, then the file browser: the player's own folder names (or the pretend desktop).
3. **The file:** `Documents/SuperHiddenSecretFolder/EncryptedFile`. The decryptor is a progress-bar minigame (hold to keep the signal, release when it spikes).
4. **The punchline:** a Notepad parody opens: "Thank you for playing my game! - 506Clicks". In the earbud, Kernel: "Thank you for playing my game? what a fucking geek."
5. **The cleanup:** Kernel sends a script. Leo runs it. The work computer smokes, the fan dies, the room smells like a hair dryer.
6. **Headlights.** The old manager still had a remote-access app on that PC and saw someone in the files at 1 a.m. A car pulls into the lot. The driver gets out, sees Leo through the window, recognises him, and **runs**. The portrait on the driver's side window is the player's avatar. The game prints the name for the first time.
7. **The chase.** Two phases: the manager runs (night, Covington Corner to the Trans-Canada), Leo follows. At Magnet Hill the manager's car rolls "uphill" in neutral while they try to restart it, and Leo boxes them in at the Big Stop.
8. **The talk** (the Big Stop at 3 a.m., two coffees). The manager wasn't hiding anything from Leo; they were hiding from a man who visited the day after the funeral. "He said I'd had a long career and it was over. I believed him." They hand Leo the **pink carbon copy** of inspection 0448 they've carried for three years. If the player **loses the chase,** the carbon copy arrives in the counter mail a week later in an envelope with the initial on it.
9. **The morning after:** Gus finds the computer. "What did you do to it?" "I... updated it." "It's on fire, Leo." That's how Nate's MarketThing computer gets in the door.

**The payoff:** in Chapter 7, Siphon reveals he wrote the tip; Hatch wanted to know whether the manager had kept anything. The fourth-wall file is still just a joke; nobody in the world explains it.

---

## 3. Systems specs

Written to be built directly. Numbers are first-pass balance values; every one of them lives in a data file so it can be tuned without touching code.

### 3.0 Conventions

- **Pure logic, no drawing,** for every new system, the way `counter/rules.gd` and `sim/car_sim.gd` already work, so each can be tested headless. New folders: `game/shop/` (parts, orders, upgrades), `game/crew/`, `game/market/`, `game/jobs/`, `game/barks/`. New screens in `game/ui/`: `phone.gd`, `kitchen_table.gd`, `dyno_screen.gd`, `parts_screen.gd`, `loading_card.gd`.
- **Data** in `game/data/`: `parts.json`, `crew.json`, `rules.json` (the desk rules, moved out of `rules.gd` once there are more than about 20), `market_cars.json`, `jobs.json`, `barks/*.json`, `loading.json`.
- **Save:** extend `SaveGame` (each car's installed part instances, condition, quirks, tricks) and `StoryState` (calendar, meters, crew, orders, inventory, notebook). Bump `SaveGame.VERSION` and migrate.
- **Time:** the clock already runs one game minute per real second. A shift runs 8:00 to 18:00 (10 real minutes); the evening runs from clock-out until Leo parks at home or 02:00.
- **Tests:** each system gets a headless test file (`tests/shop_tests.gd`, `crew_tests.gd`, `market_tests.gd`, `barks_tests.gd`) in the style of `counter_tests.gd`: whatever the generator injects, the player can find again.

### 3.1 The crew

CSR2's crews pool strangers' points. Ours are the people in Leo's life, each with a job and perks earned by doing things together.

**Three slots per day:**

| Slot | When | What it affects |
|---|---|---|
| **BAY** | The shift | Install and repair speed and quality, Bay 1 throughput, tuning |
| **SEAT** | The evening | Driving missions, passenger banter, hints, stress |
| **PHONE** | The evening | One remote ability per evening (a tow, a price check, a delivery) |

**Progress:** each crew member has `xp` and `loyalty` (0 to 100). XP: +10 per job together, +25 per story mission, +5 per shift in the BAY. Levels at 0, 100, 300, 700 and 1,500 XP. Loyalty goes up with paid wages on time (+2 a week), remembered birthdays, and choices; it goes down with missed pay (-10), driving dangerously with them in the seat (-3 a near miss, -15 a crash) and driving impaired with them in the car (-30 and they won't ride with Leo for 14 days). Below 25 they refuse the SEAT; below 10 they stop answering (Gus never quits; in the Kingpin ending he just stops coming in on Saturdays).

```json
{ "id": "toby", "name": "TOBY CORMIER", "slots": ["seat", "phone"], "joins": "prologue",
  "hours": { "seat": [18, 2], "phone": [0, 24] }, "busy_in_weather": ["rain", "storm", "snow", "blizzard", "freezing"],
  "perks": [
    { "lv": 1, "id": "free_tow", "val": 1 },
    { "lv": 2, "id": "tow_jobs", "pay_mult": 1.15 },
    { "lv": 3, "id": "salvage", "chance": 0.25, "cond": [0.3, 0.7] },
    { "lv": 4, "id": "scanner", "radius_m": 600 },
    { "lv": 5, "id": "the_truth", "per_chapter": 1 } ] }
```

**The roster:**

| Who | Slots | Available | L1 | L2 | L3 | L4 | L5 |
|---|---|---|---|---|---|---|---|
| **Gus** | BAY (SEAT only in story) | Mon to Sat, 7:00 to 19:00 | Install time x0.8; +1 Bay 1 job a day | **Ears:** highlights the noise source in the listen minigame on pre-1996 cars | Repairs restore condition to 0.85 (default 0.70); repair cost -20% | **Frank's Way:** unlocks Frank Spec (Stage 5) installs with a build sheet; rebuilt engines need half the break-in | **Every Sunday:** all owned cars' brakes checked weekly (warns before pads or fluid drop below 30%); +1 trick slot on Engine and Brakes |
| **Toby** | SEAT, PHONE; drives in Ch5 to 6 | PHONE any time; SEAT on his nights off (Tue, Wed); busy on bad-weather nights half the time | One free tow home a day (otherwise the R tow costs $120) | Tow jobs appear on the map, +15% pay | **Salvage:** 25% of tows yield a junk part (condition 0.3 to 0.7) | **Scanner:** police within 600 m shown on the GPS | **The Truth:** once a chapter, stress to 0 and one craving cleared (Ch5 on) |
| **Mikey** | SEAT, PHONE; BAY on the counter in Ch5 | Any time after 11:00 | **Scout:** saved MarketThing searches alert a day early | **Haggle:** -5% on sellers' floors for listings he found | **Co-driver:** pace notes, 20% wrong (5% from Ch5) | **Barn Whisperer:** one barn-find tip per season | **The Hat:** once a chapter he hides your keys and blocks one impaired drive (it fails, by script, on the Chapter 4 night) |
| **Aries** (Ch1 to Ch4) | SEAT, Saturday BAY | Weekdays 15:30 to 21:00, weekends | **Seatbelt:** crash injuries to anyone in the car halved | **Reviews:** answers Yowl reviews; shop rep +0.1 a week she rode along | **Navigator:** GPS reroutes around jams and checkpoints | **Assertive** (Ch3, licensed): one delivery a night completes itself at 70% pay | **Make Leo Laugh:** stress -15 a day in any week she rode along |
| **Mia** (Ch1 spring, family ≥ 20) | PHONE | Any evening | **Columns:** the Kitchen Table shows a 4-week forecast; no late fees on the Familia's cut | **Padding:** dirty cash launders at 85% (60% without her); audit risk up | **Negotiator:** rent and supplier prices -5% | **Clean Books:** the audit is one tier easier; one citation a month forgiven on the legit path | **Follow the Money** (Ch7 story) |
| **Tej Sparker** (hire, Ch2, $600 a week) | BAY | Mon to Fri | ECU sliders at ECU Stage 2 (normally 3) | Free dyno pulls | Knock risk -30% on his tunes | +1 trick slot on Induction | **Map Wizard:** +3% torque on any car he tuned |
| **Han Lunchbox** (Ch2, back in Ch7) | SEAT | Evenings | Drift score +10% | Line hints (ghost arrows) in drift events | Tandem chase AI follows closer in crew drift battles | | |

**Contacts** (not slots; the phone's contact list): **Darrell** (parts at half price, lies about them), **Twinkee** (rare parts, Friday nights), **Kernel** (Ch3 on: opens a parking-garage gate or a traffic light once a night), **Sal** (napkin jobs), **Tremblay** (once a chapter, if law ≥ 40, a ticket becomes a warning: "That's two.").

**After Aries.** From Chapter 5 her card stays on the crew screen as a photo. It can't be selected. Her perks are simply gone, and the player will feel the stress number they no longer have help with.

**Crew Night and the Hubcap League** (CSR2's crew championship, grounded):
- **Every Friday, 21:00 to 02:00, Drag Night at Airstrip 7.** Leo plus up to two crew members run bracket races (their cars or yours). A win scores 10 crew points; a perfect light (reaction under 0.05 s) +3; breaking out under your dial-in scores 0.
- **The Hubcap League** is a season-long table (13 Fridays) against five AI crews (Johnny Tram's, Saki's, Roman Purse's, Wreckard Shaw's, the Drift Kingpin's), whose weekly points are drawn from a range set by their tier.
- **Milestones:** 50 points: $500 and a green trick. 150: a voucher toward a shop tool (tire machine). 300: a blue trick. 500: crew jackets (cosmetic) and street rep +50. League winner: a purple trick or a car from the last-placed crew.
- **Wildcards:** **Roll Up the Rim** (February to April): each Tim Burtons coffee has a 1 in 6 chance of a prize (a donut: stress -2; a free coffee; $20; double crew points next Friday; and once per game, a car: a beige Toyoda Corolly with 400,000 km). **Double-Double Weekend** (one random weekend a season): side jobs pay double.
- **Co-op later:** the slot model maps onto up to four players in the post-launch co-op (each player takes a slot's role in a mission).

### 3.2 Parts: sources, ordering, delivery, install, condition

**A part template** (`data/parts.json`):

```json
{ "id": "nissun_sr_s2_cams", "name": "STAGE 2 CAMS + PORT JOB", "cat": "engine", "stage": 2,
  "fits": ["family:nissun_sr"], "price": 1450, "install_h": 9.0, "equip": ["engine_stand"],
  "sources": ["fundy", "rockbottom", "twinkee"], "stack": true,
  "requires": { "engine": 1 }, "legal": { "noise_db": 2 },
  "fx": { "torque_lo": 1.02, "torque_hi": 1.10, "split_rpm": 4500, "redline": 300, "limiter": 300 },
  "wear": { "per_1000km": 0.006, "per_overrev_s": 0.02 } }
```

**A part instance** (in the save):

```json
{ "uid": 1042, "part": "nissun_sr_s2_cams", "cond": 0.94, "km": 1200, "on": "silvio#0",
  "tricks": ["green_port_match"], "source": "marketthing", "serial": "SR4471902", "hot": false }
```

**Where parts come from:**

| Source | Where | Lead time | Price | Condition | Risk |
|---|---|---|---|---|---|
| **Rumble Auto Parts** | The PARTS shop next to Covington Auto (on the map) | In stock 70% of the time: ready at clock-out if ordered before 15:00; otherwise next day | x1.00 | New | None |
| **Fundy Parts Supply** | Phone catalogue (apartment or counter phone) | 1 to 2 days, courier to the counter | x0.92 | New | 3% wrong part |
| **RockBottomAuto.com** | The counter PC | 4 to 7 days from the States | x0.72, plus $25 to $90 shipping, $35 brokerage and 15% HST on the value | New | 8% wrong part, 3% damaged |
| **The importer at the Docks** | Sal's guy (Ch1), Wreckard's people (Ch6) | 10 to 14 days | x0.60 | Used JDM, 0.65 to 0.90 | 20% hot |
| **MarketThing** | Meetups | At the meetup | x0.35 to 0.80 | 0.30 to 0.95, and the seller lies | Quirks; 5% hot |
| **Petitcodiac Pick-n-Pull** | Salisbury; you pull it yourself (30 to 90 game minutes) | At once | x0.25 | 0.20 to 0.80 | 10% hot |
| **Twinkee's green van** | Fridays 22:00 to 01:00, a random lot | At once | x0.60 (rare and race parts) | 0.70 to 1.00 | 35% hot |
| **Darrell** | Text him | 1 to 3 days, left in the lot overnight | x0.50 | Random, and he lies | 50% the description is wrong |

**Hot parts.** Every part has a serial. A hot part's serial is on that week's BOLO list on the counter wall, so the player can check before installing. A hot part on Leo's car: at any checkpoint or annual inspection with heat ≥ 30, a 40% chance it's seized, heat +20.

**Ordering.** The counter PC ("PartsWeb 98", a code-drawn retro OS consistent with the USB job's) and the phone catalogue both show a cart, the ETA in game days and the total. Several orders can be open at once. Online orders are paid when placed; local orders on pickup.

**Delivery.**
- ETA +1 day on blizzard or freezing-rain days; +2 days from 20 December to 2 January. Express shipping halves the wait (round up) for +40% shipping.
- **Will Call:** to get a box a day early, drive to the courier depot at the Big Stop and bring it back (reuses DETAILING's "careful" objective: the box is fragile).
- **The courier is a counter customer.** On the first shift after the ETA, a courier comes to the window with the box, a **packing slip** and, for RockBottom, a **customs form**. Compare the slip's part number with your order printout (a document on the desk) and the declared value with what you paid. APPROVE accepts, DENY refuses (no charge, reorder), and a wrong part you accept sits in your inventory and won't fit (return costs a 15% restocking fee). Once a chapter the box is a Familia package with the wrong name on it. Those are REPORT or BAY 3.

**Install.**
- **Who:** Gus in the BAY slot during the shift (8 working hours a day), or Leo himself in the evening (the install hours come out of the evening). Tej in the BAY for ECU and electrical parts.
- **Speed:** Gus x1.0 (x0.8 at L1), Leo x1.5 (x1.0 after 20 installs: "Leo's hands"), Tej x0.9 on electrical.
- **Bays:** Bay 1 is customers, Bay 2 is Leo's own cars (one at a time), Bay 3 is the Familia's.
- **Equipment** (shop upgrades): engine stand $900 (engine stage 2 on), hoist $1,400 (swaps and gearboxes), tire machine $2,200 (otherwise $20 a tire next door), alignment rack $6,500 (otherwise every suspension job leaves the car pulling), welder $1,100 (roll cage), dyno $18,000 (Chapter 3), paint booth $24,000 (respray clears heat, per the concept).
- **Hands-on (optional):** the first time Leo installs a part in each category he can do it by hand: a torque-sequence minigame (bolts in a star pattern, each to spec). A skipped or bad job loses 0.1 condition, and on wheels sets the `wheeloff` flag (the death memes already have a caption for it). Skipping the minigame is always allowed and gives 95% quality.
- **Break-in:** after an engine stage, the next 300 km above 5,000 rpm cause triple wear. The HUD shows "BREAK-IN: 212 KM LEFT". Gus at L4 halves it.
- **Do it while you're in there:** parts installed together that share access (clutch and flywheel; cams and head port; pads and lines) share install hours.

**Condition and wear,** mapped onto what `CarSim` already simulates:

| Category | Condition lives in | Wears from | Effect when worn | Failure |
|---|---|---|---|---|
| Engine | `engine_health` (exists) | Cold revs, over-revs, overheating (all exist); 0.004 per 1,000 km | `power_mult()` (exists) | Blown (exists) |
| Induction | `turbo_cond` (new) | 0.0005 per second above 90% boost; old oil | Boost x(0.7 + 0.3 x cond); blue smoke below 0.4 | Below 0.1: no boost, smoke, oil loss |
| Nitrous | `n2o_left` (new), solenoid condition | Each shot | | Below 0.2: backfire, intake damage |
| Drivetrain | `clutch_cond` (new) | Launch slip energy (-1 per 4 MJ); a missed shift -0.01 | `clutch_torque` x(0.6 + 0.4 x cond): slips under load below 0.5 | Below 0.08: no drive |
| Tires | `tires[i].tread`, temp (exist) | Exists | Exists | Blowout (exists) |
| Brakes | `pads_mm` (new, 10 new), `fluid` (new, 0 to 1, -0.15 a season) | Pad wear by brake energy; fluid takes on water | Fade threshold = `fade_c` x(0.7 + 0.3 x fluid); under 2 mm pads: torque x0.6 and grinding | Pads at 0: rotor damage; fluid under 0.2: fade at 300 °C |
| Suspension | `align` (new, rad), shock condition | Potholes (spring), curbs | Steering pulls (`align` added to steer) | Broken spring: ride drops, tire rubs |
| Body | `rust` (new, per panel group) | Winter salt: +0.015 a week unwashed (car wash $8); undercoating x0.4 | Rust over 0.6 fails inspection | Holes |

New `CarSim` fields: `pads_mm`, `fluid`, `clutch_cond`, `turbo_cond`, `n2o_left`, `align`, `lsd`, plus `spec.brakes.fade_c` (default 450, replacing the constant in `_substep`) and `spec.tires.grip` (default 1.0).

**Diagnosis.** Every car has a sheet that looks like Gus's sheet at the counter: each category with a condition bar. On a car you don't know (a MarketThing buy, a customer car) the bars are hidden until diagnosed: the **scan tool** on 1996-and-newer cars (codes in plain words), a **compression gauge**, **tread and pad gauges** on the lift, the **creeper light** (rust, frame welds), and on older cars **Gus's ears** (the listen minigame: rod knock, lifter tick, a bad bearing, a loose heat shield).

**Repair or replace.** Repair restores condition up to Gus's cap (0.70, or 0.85 at L3, 0.95 at L5) for 30% of a new part plus labour. Pads, tires, fluid and clutch discs can't be repaired.

**Legality** (the counter's rules apply to Leo too): each part's `legal` block lists what it does to noise, ride height, tint, lights and studs. In October each year Leo takes his cars to **Lindsay's Lube & Inspect** (he can't inspect his own). It's a short scene: the player watches someone else read *his* papers with *his* rules. A fail gives 30 days to fix it before tickets.

### 3.3 Performance stages

**How stages apply.** `Upgrades.apply(base_spec, installed) -> spec` is pure. It copies the car's JSON spec and applies each installed part's `fx` in a fixed category order, then condition. The sim never needs to know a part exists.

| `fx` key | Does |
|---|---|
| `torque_all`, `torque_lo`, `torque_hi`, `split_rpm` | Multiply `engine.torque_curve` points (below / above the split, blended over ±500 rpm) |
| `redline`, `limiter` | Add rpm |
| `inertia` | Multiply `engine.inertia` |
| `boost` | Turbo cars: multiply the curve and divide `turbo.no_boost` by the same factor, so off-boost torque is unchanged and full-boost torque rises |
| `spool`, `lag` | Add to `turbo.spool_rpm`; multiply `turbo.lag` |
| `add_turbo` | Non-turbo cars: create a `turbo` block and divide the curve by its `no_boost` (off boost it's the old engine) |
| `nitrous_kw`, `bottle_s` | Nitrous (new in the sim: extra torque = kW x 1000 / engine rad/s above 3,000 rpm at full throttle) |
| `clutch`, `shift`, `final`, `gears` | `engine.clutch_torque` x; `gearbox.shift_time` +; `gearbox.final` x; replace ratios |
| `compound`, `grip` | Tire compound; `tires.grip` x |
| `brake_torque`, `fade_c`, `bias` | `brakes.max_torque` x; `brakes.fade_c` +; set bias |
| `cg`, `steer_lock`, `mass`, `cda`, `lsd` | Add / add / add / add / set |
| `pothole_mult` | Damage taken from potholes and curbs x |

**Stacking rules:** Engine, Drivetrain, Brakes and Chassis parts **stack** (each stage is a different part). Induction, Fuel and ECU, Nitrous and Tires **replace** (one turbo, one ECU, one bottle, one set of tires), so their numbers are absolute.

Numbers below are the generic table, priced for the Year-1 Silvio. Per-car overrides go in `parts.json` through `fits`. For scale, the stock Silvio makes about 147 kW (197 hp) at the crank at full boost and runs the eighth-mile in about 9.5 s.

**ENGINE** (stack)

| Stage | Parts | Price | Hours | Effect | Notes |
|---|---|---|---|---|---|
| 1 | Cold-air intake, cat-back exhaust | $480 | 2 | `torque_all` 1.05 | +4 dB |
| 2 | Cams, head port | $1,450 | 9 | `torque_lo` 1.02, `torque_hi` 1.10 at 4,500; redline and limiter +300 | Engine stand |
| 3 | Forged pistons and rods | $3,900 | 16 | `torque_all` 1.03; limiter +500 more; over-rev wear x0.5 | Needed for Induction 3+ and Nitrous 3+ |
| 4 | Stroker (more displacement) | $8,500 | 20 | `torque_lo` 1.12, `torque_hi` 1.06; inertia x1.05 | Hoist |
| 5 | **Frank Spec: Blueprinted** | $2,200 | 12 | `torque_all` 1.04; all engine wear x0.5 | Build sheet (Tape 19) and Gus L4 |

**INDUCTION** (replace). Turbo cars:

| Stage | Parts | Price | Hours | Effect | Requires |
|---|---|---|---|---|---|
| 1 | Boost controller (+2 psi) | $350 | 1 | `boost` 1.08 | |
| 2 | Hybrid turbo and intercooler | $2,400 | 6 | `boost` 1.22, `spool` +300, `lag` x1.15 | Fuel 1 |
| 3 | Ball-bearing turbo | $3,600 | 6 | `boost` 1.25, `spool` -100, `lag` x0.80 | Engine 3, Fuel 2 |
| 4 | Big single | $7,800 | 10 | `boost` 1.50, `spool` +900, `lag` x1.35 | Engine 3, Fuel 3 |
| 5 | **Frank Spec: the wastegate trick** | $1,600 | 4 | `boost` 1.55, `spool` +600, `lag` x1.10 | Build sheet (Tape 26) |

Non-turbo cars (the Supreem's straight six, the Charjer's V8): S1 header and tune (`torque_all` 1.06); S2 centrifugal supercharger (`add_turbo` spool 2,500, lag 0.12, no_boost 0.78: about +28% at the top); S3 positive-displacement blower (spool 1,200, lag 0.05, no_boost 0.72, and `torque_all` 0.98 for the belt drive); S4 twin-turbo kit (spool 3,000, lag 0.45, no_boost 0.58: about +72%, all of it late).

**FUEL AND ECU** (replace)

| Stage | Parts | Price | Hours | Effect | Notes |
|---|---|---|---|---|---|
| 1 | Pump and injectors | $420 | 2 | Knock margin +1 | Needed for Induction 2 |
| 2 | Piggyback ECU | $650 | 1 | `torque_all` 1.03; rev limit adjustable ±400 | |
| 3 | Standalone ECU | $1,900 | 4 | `torque_all` 1.05; unlocks the dyno sliders (section 3.5); knock margin +2 | |
| 4 | Flex fuel (E85) | $1,200 | 3 | `torque_all` 1.10; knock margin +4; fuel use x1.3 | E85 at two stations only (the Big Stop, Dieppe); 30% chance of a no-start below -15 °C |

**Knock.** Margin = octane (87: 0, 91: +2, 94: +3, E85: +6) + fuel stage + tricks - (boost over the stage's target in %)/5 - timing advance in degrees - max(0, (AFR - 12.5) x 4). Below zero at full throttle above 3,500 rpm: a ping on the audio, a tick on the dyno, and `engine_health` -0.004 x |margin| per second. Simpler rule for the HUD: if Induction stage - Fuel stage ≥ 2, the knock light comes on.

**NITROUS** (replace; refills $45 next door)

| Stage | Shot | Bottle | Price | Requires |
|---|---|---|---|---|
| 1 | 50 hp (37 kW) | 14 s | $700 | |
| 2 | 75 hp (56 kW) | 12 s | $1,100 | Fuel 1 |
| 3 | 100 hp (75 kW), purge | 11 s | $1,600 | Engine 3, Fuel 2 |
| 4 | 150 hp wet (112 kW), progressive | 9 s | $2,900 | Engine 3, Fuel 3 |

Missing a requirement: -0.02 engine health per second of spray. A purge in sight of police: heat +5.

**DRIVETRAIN** (stack)

| Stage | Parts | Price | Hours | Effect |
|---|---|---|---|---|
| 1 | Stage 2 clutch | $520 | 5 | `clutch` x1.35; the auto-clutch launch rpm +300 |
| 2 | Lightweight flywheel | $480 | 5 (1 with the clutch) | `inertia` x0.80: revs faster, stalls easier |
| 3 | 1.5-way LSD, short shifter | $1,700 | 6 | `lsd` 0.5; `shift` -0.06 s |
| 4 | Close-ratio gears, final drive | $4,200 | 12 | Each ratio ±10%, final ±15% (dyno screen); `shift` -0.04 s |
| 5 | **Frank Spec: Mountain gearing** | $900 | 4 | Ratios fitted to the car's curve automatically; `shift` -0.03 s |

LSD in a bicycle model: soften the existing combined-slip penalty on the rear (`fy_r /= 1 + 5κ²` becomes `1 + (5 - 2.5 x lsd)κ²`), so slides are more controllable. (Optional: a small throttle-on yaw term.)

**TIRES** (replace; prices per set of four at 16 inches)

| Stage | Set | Price | Compound |
|---|---|---|---|
| 0 | All-season (most customers' cars) | | `allseason` |
| 1 | New summer or winter set | $480 / $620 | `summer` / `winter` (exist) |
| 2 | Sport | $760 | `sport` |
| 2W | Studded winter (legal 15 Oct to 30 Apr by the desk rule) | $780 | `studded` |
| 3 | Semi-slick | $1,150 | `semi` |
| 4 | Drag radials rear, skinnies front | $980 | `drag` (rear) |

Mounting $80 a set without the tire machine. One size wider: `grip` x1.03, `cda` +0.01, +15% price. New entries for `CarSim.COMPOUND` (same keys as the existing two, plus `wear`, a tread-wear multiplier):

| Compound | dry | wet | snow | ice | gravel | leaves | cold_below °C | opt °C | wear |
|---|---|---|---|---|---|---|---|---|---|
| allseason | 0.98 | 0.95 | 0.85 | 0.80 | 0.95 | 0.95 | -10 | 60 | 1.0 |
| sport | 1.12 | 0.97 | 0.45 | 0.45 | 0.85 | 0.92 | 10 | 90 | 1.3 |
| semi | 1.22 | 0.78 | 0.30 | 0.30 | 0.75 | 0.80 | 15 | 95 | 2.2 |
| studded | 0.82 | 0.92 | 1.35 | 2.20 | 1.00 | 1.00 | -35 | 40 | 1.4 |
| drag | 1.30 | 0.60 | 0.20 | 0.20 | 0.50 | 0.50 | 20 | 70 | 3.0 |

(Grass, mud and water: copy the nearest existing value. Drag radials should only multiply longitudinal grip; laterally use 0.95. That needs a separate `lat` value in `tire_mu`, which is a small sim change.)

**BRAKES** (stack)

| Stage | Parts | Price | Hours | Effect |
|---|---|---|---|---|
| 1 | Performance pads | $220 | 1.5 | `brake_torque` x1.10, `fade_c` +50; pad wear x1.2 |
| 2 | Braided lines, DOT 4 fluid | $260 | 2 | `fade_c` +80; fluid back to 1.0 |
| 3 | Big brake kit (4-piston front) | $2,300 | 4 | `brake_torque` x1.30, `fade_c` +70; +6 kg; needs 17-inch wheels |
| 4 | Adjustable bias valve, rear upgrade | $650 | 2 | `bias` slider 0.55 to 0.72; `brake_torque` x1.05 |
| 5 | **Frank Spec: Every Sunday** | $500 | 3 | `fade_c` +150; pad wear x0.5; fluid never ages. Build sheet: Tape 7 |

**CHASSIS AND WEIGHT** (stack)

| Stage | Parts | Price | Hours | Effect |
|---|---|---|---|---|
| 1 | Lowering springs (-30 mm) | $380 | 3 | `cg` -0.015; `pothole_mult` 1.3; needs an alignment |
| 2 | Coilovers | $1,600 | 5 | `cg` -0.03 (instead of S1's); ride height adjustable; `pothole_mult` 1.4 |
| 3 | Sway bars, angle kit | $1,300 | 4 | `steer_lock` +0.12; body roll drawn 40% smaller |
| 4a | Weight reduction (spare, carpets, rear seats, A/C) | $400 | 4 | `mass` -60 |
| 4b | Gutted (interior, sound deadening, the radio; carbon hood, lexan rear) | $1,900 | 6 | `mass` -120; stress +2 an hour in winter (it's loud and cold) |
| opt | Roll cage | $2,800 | 14 | `mass` +25; crash damage x0.7; required to race under 11.0 s on the quarter at the legal strip |

**The performance card ("Leo's Notebook").** After any install, run the car headless through the same procedures as `tests/run_tests.gd`: 0 to 100 km/h, eighth-mile ET and trap speed, quarter-mile ET, 100 to 0 km/h in metres, and lateral g on a 40 m circle. Cache the result per configuration. **Class** by eighth-mile ET (Airstrip 7's runway is 340 m, so its drag nights run the eighth, which is also what real street drag nights run): D ≥ 10.0 s, C 9.0 to 10.0, B 8.0 to 9.0, A 7.2 to 8.0, S under 7.2. Crew ladders and Drag Night brackets use these classes.

**Tricks** (CSR2's fusion parts, grounded):
- **Slots:** a Stage 1 or 2 part has 1 slot, Stage 3 or 4 has 2, Frank Spec has 3. Tricks stay when you move up a stage in the same category, as fusion parts do.
- **Make-family-specific:** NISSUN tricks fit Nissuns, FJORD tricks fit Fjords.
- **Rarity and sources:** green (junkyard pulls 10%, tow salvage, crew level-ups), blue (crew L3 and L5, league milestones, Darrell, who lies about the colour), purple (Frank's build sheets, gold medals on all of a mentor's tests).
- **Examples:** PORT-MATCHED GASKET (engine, green: `torque_hi` x1.01); TEJ'S MAP (ECU, blue: `torque_all` x1.02); GUS'S BLEED (brakes, blue: `fade_c` +25); FRANK'S SHIM (drivetrain, purple: `shift` -0.02); **WINTER WEIGHT** (chassis, green: 20 kg of sandbags in the trunk, `mass` +20 and rear snow grip x1.03, the oldest rear-wheel-drive trick in the Maritimes).
- Removing a trick costs an hour of labour.

### 3.4 Visual customization

| Area | Options | Notes and ties to other systems |
|---|---|---|
| **Paint** | Gloss, metallic, pearl, matte, candy, two-tone, wrap; **Maritime Primer** (free, patchy grey) | The shader-on-greys approach from the concept. A respray in the paint booth clears heat |
| **Body** | Front and rear bumpers (3 to 5 per car), skirts, flares, hoods (vented, scoop, carbon, primer), wings (duck-tail, lip, GT, "ridiculous") | GT wing: `cda` +0.02 and, if aero is added to the sim, downforce |
| **Wheels** | About 20 rim styles shared across cars, 14 to 19 inches, colour, offset; **winter steelies with hubcaps**; tire sidewall lettering | Port Rumble's nickname is the Hubcap City: hubcaps fly off in potholes and can be collected (a silly collectible set) |
| **Stance** | Ride height, camber (0 to -8° visual) | Camber over -3° wears the inner tread 1.5x faster. Ride below 100 mm fails inspection (desk rule) |
| **Lights** | Sleepy-eye on pop-ups, smoked tails, headlight colour, fog lights, light bars (trucks), underglow | Blue headlights and moving underglow are illegal: heat at checkpoints |
| **Glass** | Tint with a VLT number, windshield banners (COVINGTON AUTO, ROLL UP THE RIM) | Front side windows under 70% fail (desk rule, Chapter 1 week 5) |
| **Exhaust** | Tips, burnt tips, the oversized "fart can" | Noise dB shown; over the limit fails inspection and draws heat |
| **Plates** | Vanity plate (7 characters, filtered), frames ("MY OTHER CAR IS ALSO BROKEN") | |
| **Interior** (shown in the profile view) | Wheel, shift knob, seats, dice, air freshener (Black Ice tree), Dom's rosary (a gift in Chapter 1), a hula dancer | **Aries's hockey bag** sits in the Silvio's back seat from Chapter 1. After Chapter 4 the only option on it is LEAVE IT |
| **Winter** | Block-heater cord dangling from the grille, mud flaps, ski rack, snow brush on the dash | The block heater is also a real part: no dead battery below -20 °C if plugged in at home |
| **Wear** | Patina (clear-coated rust that stops spreading), dents kept or fixed | Rust and dirt are shader masks per the concept |
| **Horn** | Stock, air horn, a moose call, a public-domain melody | |
| **Later** | Livery editor (pixel decals, share codes) | After launch content is stable |

**The reveal moment** (after any stage install, or any visual job over $300): the car on the lift in profile, the lift lowers (0.8 s), the bay lights go off and on (0.2 s), the headlights flick on, the camera pans rear to front at 2x (1.5 s), the air wrench and the first rev play, one crew line ("...Yeah. Okay." from Gus is the highest praise in the game), and a stat card slides in: "+18 kW. 0-100: 7.1 → 6.6 s. CLASS C → B". Skippable after 0.5 s.

### 3.5 The dyno and tuning

**Access:** Chapter 1's Hatch Motors Dyno Day (free, once), then rental pulls at Hatch Motors Raceway ($40, the "friends and family rate"), then Covington Auto's own dyno in Bay 2 from Chapter 3 ($18,000).

**A pull:** the car in the gear nearest 1:1 at full throttle from 2,000 rpm to the limiter over about 8 s. Compute it steady-state rather than running the whole sim: at each rpm, torque = `curve_torque(rpm)` x boost multiplier (with the real spool curve and lag shown as the dip below spool) x `power_mult()` x `gearbox.efficiency`; wheel power = torque x engine rad/s. That is the same maths the sim uses, so the dyno can never disagree with the road.

**The screen** (640×360): a 400×200 pixel graph, rpm across, power (hp by default, kW as an option) and torque (N·m) up; the last pull ghosted behind the new one; the AFR line (ECU 2 and up); knock ticks; peak labels; a "COMPARE" toggle.

**Weather matters:** power x √(293.15 / (273.15 + outside °C)). A pull at -15 °C reads about 5% higher than at 20 °C. ("Dyno numbers are a winter sport.") **Heat soak:** each pull within 120 s of the last one raises intake temperature 8 °C and costs 1.5%, until you wait or run the fan.

**Tuning sliders** (ECU Stage 3, or Stage 2 with Tej):

| Slider | Range | Effect | Risk |
|---|---|---|---|
| Boost target | -20% to +15% of the stage's boost | Scales `boost` | Above 100%: knock margin down |
| Ignition timing | -4° to +4° | ±1.2% torque per degree | Each degree of advance: margin -1 |
| AFR at full throttle | 11.0 to 13.2 | +1.5% per 0.5 leaner, up to 12.8 | Above 12.5: margin down, more heat |
| Rev limiter | ±400 rpm | | Over-rev wear |
| Launch control | 2,500 to 6,000 rpm | Sets the auto-clutch's launch rpm | Clutch wear |
| Final drive (Drivetrain 4) | ±15% | Acceleration against top speed | |
| Tire pressure, front and rear | 24 to 40 psi | Grip x(1 + (32 - psi) x 0.004); lower means more launch grip and more heat | Below 26: tire heat x1.3 |
| Nitrous engage | 2,500 to 5,000 rpm | | Below 3,000: backfire risk |

Every slider shows the dyno delta and a **risk meter in plain words** (SAFE / SPICY / YOU'LL HEAR ABOUT IT), like Disco Elysium showing its odds. Results are kept in Leo's Notebook (last five pulls per car). **Dyno Day** events have a class leaderboard with AI entries and Hatch Motors banners everywhere.

### 3.6 MarketThing (the used-car market)

**A listing:**

```json
{ "id": 8812, "car": "silvio", "year": 1993, "km_claimed": 168000, "km_true": 241000,
  "cond": { "engine": 0.62, "induction": 0.50, "body_rust": 0.35, "tires": 0.40, "brakes": 0.30 },
  "hidden": ["head_gasket", "rolled_odo", "frame_rust"], "quirks": ["window_drops_in_rain"],
  "ask": 3469, "value": 2600, "seller": "flipper", "photos": 3, "photo_quality": 0.3,
  "title": "silvio turbo runs great needs nothing", "posted": 112, "expires": 115,
  "where": "TIM BURTONS - MOUNTAIN RD", "hot": false }
```

**Value** = base[car] x age x km x condition x season x trend x rarity:
- km factor = clamp(1.25 - km/400,000, 0.35, 1.2).
- condition factor = 0.4 + 0.6 x weighted condition (engine 0.35, body 0.25, drivetrain 0.15, tires 0.10, brakes 0.10, interior 0.05).
- **Season:** convertibles x0.75 December to February, x1.15 April to June; trucks and 4x4s x1.2 for three weeks after the first snow; rear-drive sports cars x0.85 November to February; winter tire sets x1.3 in November, x0.8 in March.
- **Trend:** 90s JDM +10% a year; everything +30% in Year 3 and -15% in Year 5; V8s -10% in Year 7 (gas prices); EVs from Year 6.
- Asking prices end in 00, 99 or 69.

**Sellers** (each listing has one):

| Seller | Ask | Floor (lowest yes, as share of ask) | Honesty | Replies | Tell |
|---|---|---|---|---|---|
| **The honest grandma** | x0.95 to 1.05 | 0.92 | True | Slow (hours) | "It was my husband's. He'd want it to go to a nice boy." |
| **Flipper Kyle** | x1.25 to 1.45 | 0.80 | Fresh paint over rust; codes cleared that morning | Instant | "no lowballs i know what i have" |
| **Darrell** | x1.10 to 1.30 | 0.75 | Lies about everything | Medium | "selling for my wife's husband" |
| **The ghost** | x1.0 to 1.2 | | | 40% never answer after "is this still available?" | |
| **The scammer** | x0.5 to 0.7 (too good) | | The car doesn't exist | Instant | Wants an e-transfer deposit "to hold it" |
| **The trader** | x1.0 to 1.3 | 0.85 | Mostly true | Medium | Wants a jet ski, a sled, a four-wheeler, or "ur silvio plus cash" |
| **Estate sale** | x0.7 to 0.9 | 0.85 | True | Slow | Sad and cheap; sometimes the way to a barn |
| **The curbsider** (Ch2 on) | x1.15 to 1.30 | 0.88 | A dealer posing as a private seller: Hatch Motors' back lot. Rolled odometers, washed titles | Fast | The registration is less than 30 days old and from out of province, every time |

**Chat.** Each seller has patience (grandma 90, Kyle 40, Darrell 60). With r = offer / ask: r ≥ 1 is a yes; below the floor, patience -25 and a lowball reply; otherwise P(yes) = ((r - floor) / (1 - floor))^1.5, or a counteroffer halfway, rounded to 50 (Darrell rounds to 69). Patience 0: ghosted. Mikey's Haggle perk lowers floors on listings he found. Paying a scammer's deposit loses it and puts SCAM ALERT on Bleeter.

**The meetup** is the counter in a parking lot. Drive to the listing's place (a Tim Burtons lot, a dooryard in Salisbury), then inspect with the same click-two-things tool:
- Ownership name vs the seller's licence; VIN on the dash vs the door jamb vs the ownership.
- Odometer vs the oil-change sticker on the windshield (rollback).
- **Touch the hood.** If it's warm before you asked to start it, the seller warmed it up to hide a cold-start problem.
- Dipstick (milkshake: head gasket), coolant cap (oil film: head gasket), smoke at start (blue: rings or turbo; sweet white: coolant; black: rich).
- Creeper light underneath (rust, frame welds, leaks), tread gauge.
- **Test drive:** the sim with the hidden faults injected (a misfire is a torque dip, a pull is `align`, a slipping clutch is `clutch_cond` 0.3, a clunk is a sound).
- The same promise as `counter_tests.gd`: **every hidden fault has at least one check that proves it,** and a test makes sure.

**Buying:** cash (the coffee can works, which is its own kind of laundering), signed ownership, and Leo has 10 days to register it (the desk's own bill-of-sale rule).

**Selling** your car: photos (photo mode, or an auto-shot whose quality depends on light: golden hour x1.3, night flash x0.6, a washed car x1.1), a title and description from phrase pickers, an **honesty toggle** (disclose faults: fewer offers, no blowback; hide them: faster sale, a chance of a Bleeter call-out and street rep -20), and a price. Buyers: 60% lowballers ("would u take 500"), 25% "is this still available?" ghosts, 15% real, offering value x 0.80 to 1.05 adjusted by street rep.

**Refresh:** 6 to 10 new listings every morning (x1.5 in April, "just took it out of storage"; x0.6 in January), each lasting 1 to 5 days; a watched listing has a 15% chance a day of selling to someone else. **Legend listings** come round on a long cycle like GT's special used cars; the Fox appears by script in Chapter 5. **Barn finds** (Mikey L4): a back-roads farm, a short scene with an old-timer, a car under a tarp at 0.1 to 0.4 condition.

**UI:** an app on Leo's phone: the listing photo (the car generator with the concept's bad-phone-photo effects: dark driveway, flash glare, a thumb, a dog), title, price, seller, distance; the chat; saved searches.

### 3.7 Side jobs

| Job | Unlocks | When | Vehicle | Pay | How it plays |
|---|---|---|---|---|---|
| **Tow calls** | Ch1 (Toby's Night Shift) | Any time; twice as many in snow and freezing rain | Toby's wrecker | $90 + $2.50/km towed, +$40 at night, +$60 in bad weather | Wrecked traffic cars already sit with their hazards on; drive to one (or a ditch), line up within 3 m, stop, work the boom, tow it to Covington Auto or the Northside impound with the extra weight. A towed car can show up at the counter next morning as a repair job |
| **Repo** | Ch2 | Night | Wrecker | $250 to $600 | The owner may come out and chase you (a traffic car turned pursuer) |
| **Pizza Delirium** | Prologue | 17:00 to 23:00 | Any | $6 a delivery + tip = $2 + $8 x max(0, 1 - minutes late / 10) x pizza condition | Pizza condition drops with lateral g over 0.7. Thirty minutes or it's free |
| **Parts runs** | Ch1 | Evenings | Any | $25 to $60 | Rumble Auto Parts or the Fundy depot to another garage |
| **Hoover** rideshare | Ch2 | Evenings and nights | A four-door with a valid inspection sticker | $4 + $1.80/km | Rating from smoothness (jerk), speed and a banter choice. Some riders are story characters |
| **Napkin jobs** (the Familia) | Ch1, after the debt, if Bay 3 is open | Night | Any | $400 to $1,200 dirty | Heat +5 to +15. Don't open the trunk (you can: cash, parts with ground VINs, forty frozen lobsters) |
| **Street races** | Ch1 | Friday and Saturday nights, Downtown | Any | Buy-in $100 to $1,000; winner takes the pot less 10% | Heat +10 a race; police chance |
| **Drag Night** | Ch1 | Fridays 21:00 to 02:00, Airstrip 7 | Any | Purses, side bets, pink slips; crew points | Eighth-mile. **Bracket racing:** you set a dial-in; the slower car starts early by the difference; faster than your dial-in is a loss. Heads-up grudge races too |
| **Cars & Double-Doubles** | Ch1 spring | Sundays 9:00 to 12:00, Champagne Place lot | Your build | Rep, buyer offers, a trick | Judged on cleanliness, rarity, stance, period correctness and sleeper factor |
| **Firewood** | Ch1 fall | Days | A truck | $80 a cord | Out past Havelock; heavy-load handling |
| **Plowing** | Ch1 winter | After snowstorms | A plow truck (a used F-One-Fiddy off MarketThing) | $120 a lot | Scored on coverage and not hitting parked cars |
| **Hockey shuttle** | Ch1 to Ch3 | Saturdays | Any | None; Aries loyalty +5, stress -5 | Aries and her gear to the Salisbury rink |
| **Night Drive** | Ch1, after the anniversary | Night | Any | None | No objectives, no police, no banter. Stress -1 a minute. The healthy outlet |

**Mentor tests** (GT4's licences): each mentor has three or four timed tests graded gold, silver and bronze. **Dom (Chapter 1):** reaction to the tree (gold under 0.20 s, silver 0.30, bronze 0.45); 60-foot time in the stock Silvio (gold under 2.15 s, silver 2.30, bronze 2.50); shift on the light four times within ±150 rpm (gold 4 of 4, silver 3, bronze 2). **Han (Chapter 2):** parkade figure-eight angle and line; a tandem chase within 3 m. **Aries's lessons (Chapter 3)** run in reverse: you coach, and the medal is her patience. Bronze on all of a mentor's tests moves the story on; gold on all earns a purple trick.

**Money sanity for Year 1:** legal evening work earns about $80 to $250 a night; napkin jobs $400 to $1,200 with heat. Weekly costs are about $2,400 for the shop and $300 to $500 for Leo's own life.

### 3.8 The desk: what's new, and the rules by day

**New mechanics** (all in `counter/rules.gd` and `counter_scene.gd`):
- **The shift clock.** The shift runs 8:00 to 18:00 (ten real minutes). Customers queue at the window and the next one honks if you spend more than 90 game minutes on one. Customers still waiting at 18:00 leave, and the day-end screen shows the money that walked away. A careful Year-1 player should manage 6 to 10 customers a day. (Today `day_line()` builds a fixed 5 or 6.)
- **Two warnings a shift.** The first two mistakes are MINISTRY WARNINGs (logged, no fine). From the third, the existing $100 `FINE`. Twelve citations in 30 shift days, or a third Ministry meeting, is the LICENCE REVOKED ending.
- **ASK.** After the inspect tool shows a discrepancy, ASK appears. Each problem type has 3 to 5 explanations from the generator. Some are **valid with proof**: the customer produces a document (a dated bill of sale, a temporary permit, the pink insurance card from the glovebox), and that document must pass inspection too (it can be forged). Some are lies, and some are true but don't matter. Validity is decided by the generator (an `exception` field) so tests can prove the rule: an exception is valid only if its document passes `find_problems`.
- **The rulebook binder.** Once more than seven rules are active, the wall bulletin becomes a binder with tabs (Inspection, Documents, Police, Ministry, Seasonal). A rule line can be one side of an inspect comparison, as in Papers, Please.
- **Scripted customers,** two or three a day, from `data/story_customers.json` keyed by chapter and day, with fixed papers and lines and flag outcomes.
- **Regulars:** about 10% of slots are recurring procedural people (Jayden from the Mountain Road drive-thru, hockey dad Rob, Mrs. Doiron and her cursed Cava-lame, Darrell). They remember your past stamps.
- **Leo's notebook:** a desk document from Chapter 1 that collects clue statements and can be inspected against what customers say (the Chapter 8 climax).
- **The courier** brings orders (section 3.2).
- **Gus's sheet grows:** dash VIN; plus the door-jamb VIN (Year 1, week 3); plus the engine stamp (Chapter 2); plus tint, noise and rust readings as their rules arrive.
- **Familia frequency:** Thursdays in Chapter 1; twice a week from Chapter 2 spring if Bay 3 is open; none if it's closed, but family trust then drifts down 2 a week ("family calls").
- **Stings:** one every two weeks while heat ≥ 30. Undercover people don't know local things; ASK them and they stumble: "Which Tim's?" "...The Tim Burtons?" "Everybody calls it the Mountain Tim's, bud."

**Year 1, week by week** (week 1 is what the prototype already does):

| Week | Day | New on the bulletin | New problem ids |
|---|---|---|---|
| 1 (Oct 7) | Mon to Fri | Match, inspect, registration valid, insured, owner, stolen list (Thu, plus napkins), photo (Fri, plus the sting) | Existing ten |
| 2 (Oct 14) | Mon | Thanksgiving: closed. (A card: Gus, Leo, Aries and Mikey eating a store-bought turkey in the office. Nobody says Frank's name; there's a plate nobody uses) | |
| | Tue | "SERVICE HISTORY: ODOMETER READINGS ONLY GO UP." (new document: service history) | `odo_rollback` |
| | Wed | (Scripted: **Dale Hatch** brings a used car himself) | |
| | Thu | "A NEW OWNER HAS 10 DAYS TO REGISTER. A DATED BILL OF SALE COVERS A NAME MISMATCH." | `bos_expired`, `bos_forged` (ASK exception for `name_mismatch`) |
| 3 (Oct 21) | Mon | "THE VIN ON THE DOOR JAMB MUST MATCH THE DASH." | `vin_door_mismatch` (exception: a body shop's replacement-door invoice) |
| | Wed | (Scripted: **Darrell's** trade-in, rolled back) | |
| | Thu | "OUT-OF-PROVINCE CARS ON A NEW REGISTRATION NEED A FULL INSPECTION." | `out_of_province` |
| 4 (Oct 28) | Mon | "SALVAGE BRAND: NO STICKER WITHOUT A STRUCTURAL CERTIFICATE." | `salvage_no_cert`, `title_washed` (the brand is on the old out-of-province ownership but not the new one: REPORT) |
| | Thu | (Halloween: masks at the counter. ASK: "It's a costume." Valid. Take it off, compare the face) | |
| 5 (Nov 4) | Mon | "WINDOW TINT: FRONT SIDE WINDOWS MUST PASS 70% OF LIGHT." | `tint` |
| | Tue | The **sticker log** goes on the desk. (The 0448 gap) | |
| 6 (Nov 12) | Tue | (Monday is Remembrance Day: closed) "EXHAUST: NO HOLES. 95 dB MAX AT 3,000 RPM." | `noise` |
| | Thu | "POLICE: STOLEN PART SERIALS ARE ON THE LIST." (new document: parts invoice) | `hot_part` |
| 7 (Nov 18) | All week | **The Ministry Inspector** (Inspector Hachey) audits: each day he pulls two of your past work orders and you re-judge them; disagreeing with your own stamp is a citation | |
| 8 (Nov 25) | Mon | "WINTER TIRES REQUIRED ON TAXIS, RIDESHARES AND COMMERCIAL VEHICLES, DEC 1 TO APR 30." | `no_winter_tires` |
| | Wed | "STUDDED TIRES: OCT 15 TO APR 30 ONLY." | `studs_out_of_season` |
| 9 (Dec 2) | Fri Dec 6 | The anniversary. Gus closes at noon. The drive to the Mountain | |
| 11 (Dec 16) | | The old manager's Christmas card in the mail | |
| Jan to Feb | | Dead batteries (customers' cars won't start: a $40 jump at the window). Roll Up the Rim from February | `battery` (a CHECK ENGINE LIGHT job that's really a battery) |
| Mar to Apr | | "RUST-THROUGH NOW FAILS. IT WAS A WARNING; NOW IT'S A RULE." Pothole season brings alignment jobs. "Just took it out of storage" customers with everything expired | `rust_through` (stricter threshold) |
| May to Sep | | Tourists "from away" with out-of-province plates; convertibles; hail claims | `claim_old_damage` (Ch2 rule, previewed) |

**Rule packs by chapter:**

| Chapter | New at the desk |
|---|---|
| 2 | Engine-stamp VIN; insurance claims with parts invoices (rust inside "new" damage means it's old); **emissions:** OBD readiness on 1996-and-newer cars ("NOT READY" means somebody cleared the codes this morning: Flipper Kyle); airbag recall list (VINs in a range need the recall done first); **résumés** for hiring; **Hatch Motors fleet cars** (always perfect, +$150 each, hidden `hatch` +1) |
| 3 | Nate's tells: identical type across three "different" documents (inspect two: SAME PRINTER); a new PC that prints differently |
| 4 | Hobbs's task force: a fed in the waiting room, 25% bust chance on any Bay 3 stamp; the audit minigame with Mia; customers who tip in bottles (THE BOTTLE speaks) |
| 5 | Mikey's counter: the same rules, Mikey's tutorial; visiting-room days replace one shift a week |
| 6 | Shipping manifests listing VINs from **your own counter history**; container seals; export permits |
| 7 | Digital registrations with QR codes (Siphon spoofs them: the QR decodes to a different VIN than the one printed, a new compare type); EVs (no exhaust; battery health; range anxiety) |
| 8 | Hatch's own inspection; the notebook comparison |

### 3.9 The Kitchen Table (money, debt and family)

Every Sunday night, the apartment kitchen. It replaces the Friday bills screen in `counter_scene.gd` once the day loop merges, and it's Papers, Please's family screen in our clothes.

**Layout (640×360):** left, the bills with checkboxes and amounts; right, the status panel: **ARIES** (a small portrait and four status words), **LEO** (stress bar; days sober from Chapter 5), **GUS**, **THE TILL** (shop money), **LEO'S WALLET**, **THE COFFEE CAN** (dirty cash), **THE FAMILIA** (debt). Bottom: PAY, and one line of what happened this week.

| Bill | Weekly | Paid from | Must pay? | If you skip it |
|---|---|---|---|---|
| Rent on the garage | $1,100 (from Year 2, $1,250: "the new owner's a numbered company") | The till | Yes | A notice; two missed weeks: eviction notice; three Sundays below -$5,000: the BANK ending |
| Gus's pay | $800 | The till | No | Gus loyalty -10; he works anyway; third skip: he takes a week off (no BAY) |
| The Familia | $400 until the debt is gone; then $150 "family dues" if Bay 3 is open | Wallet or coffee can | No | Family -10; Saturday morning the windshield's gone; the debt grows 5% |
| Furnace oil | $0 June to September; $90 October and May; $160 November and April; $240 December to March | The till (one tank for the shop and the apartment) | No | Aries COLD; two cold weeks: she's sick (no SEAT); January: frozen pipes, a $600 plumber |
| Groceries | $140 | Wallet | No | Aries HUNGRY: she eats at Mia's (family +2) or a friend's; week 3: the school calls; week 4: Aunt Carol from Riverview offers to take her (a choice; yes means four weeks without her) |
| Aries's hockey | $120 (October to March) | Wallet | No | "she says she didn't want to play this season anyway. she's lying." Aries loyalty -8 |
| Aries's phone | $45 | Wallet | No | No texts from Aries that week |
| Insurance | $38 per car | Wallet | By law | An uninsured car can't be driven; stopped in one: $575 ticket |
| Tickets in the mail | Varies | Wallet | Within 30 days | Court |
| Parts on account | Monthly balance | The till | Monthly | Fundy stops shipping |

The coffee can pays anything except rent (the landlord wants cheques), or launders into the till through Mia (60%, or 85% with her perk). **Aries's status words:** FED or HUNGRY; WARM or COLD; PLAYING or BENCHED; and one of OKAY, WORRIED, PROUD, FURIOUS (from the week's flags).

**After Chapter 4** the Aries rows are gone, groceries drop to $90, and the screen says nothing about it.

### 3.10 Ambient conversation ("barks")

**One system for all incidental lines,** generalising the specificity-weighted picker already in `DeathMemes.pick()`.

```json
{ "id": "toby_leaves_01", "who": "TOBY", "ch": [1, 8], "channel": "seat",
  "when": { "season": ["fall"], "weather": ["rain", "drizzle"], "zone": ["*"], "speed_kmh_gt": 70 },
  "text": "Wet leaves on the Mountain. Like driving on wet newspapers. Ease off.",
  "prio": 2, "cooldown_h": 48, "once": false }
```

**Channels:** `text` (phone threads; up to three canned replies that set flags), `counter` (greeting, request, ask_reply per problem, stamp_reaction per stamp and correctness, smalltalk), `seat` (passenger banter), `vice` (THE BOTTLE and friends), `bleeter`, `clutch` (Daily Clutch headlines), `loading`, `death` (the existing memes), `radio` (later).

**Triggers (`when`):** season, weather, time of day, zone (the `ZONES` ids in `map_data.gd`), near a landmark (name and radius), speed above or below, events (near miss, minor crash, red light, wheelspin, drift seconds, airtime, pothole, police seen, Tim Burtons seen, low fuel, hot engine, knock, flat), flags (all / any / none), chapter range, meters (e.g. `family_gt`), weekday, date (6 December), crew loyalty.

**Choosing a line:** filter by trigger, then weight = 1 + score², where score = 3 if the speaker is specific + 2 per condition + 1 if the event is specific (the DeathMemes formula). Never repeat a line inside its cooldown.

**Pacing rules while driving:** a speaker talks at most once a minute (Gus every two); any speaker at most every 25 s; nothing within 4 s of a GPS turn instruction or within 5 s of a new objective; priority story > hazard warning > reaction > idle; idle lines only after 90 s of nothing.

**Showing them:** `seat` lines are speech balloons over the car (Night in the Woods) for 3.5 s plus 0.05 s a character, with the speaker's blip. Texts buzz and slide a bubble in at the bottom right without pausing the drive; reading the phone above 20 km/h counts as distracted (and Aries texts "dont text and drive. i can see the read receipt you idiot"). Full threads open when stopped. The phone is Leo's cracked phone (already the Supreem's GPS in the README): threads, MarketThing, Bleeter, Hoover, the Daily Clutch.

**How many lines to write:**

| Channel | Vertical slice (prologue + Chapter 1 fall) | Launch (all eight chapters) |
|---|---|---|
| Phone texts (incl. MarketThing chat templates) | 150 | 1,200 |
| Counter customer lines | 250 | 1,500 |
| Passenger banter | 120 | 900 (Gus 200, Toby 200, Mikey 250, Aries 150, Dom 40, Mia 30, Han 30) |
| Vice voices | 30 | 200 |
| Bleeter posts | 80 | 600 |
| Daily Clutch headlines | 40 | 300 |
| Loading cards | 60 | 300 |
| Death memes | 100 (65 exist) | 250 |
| Radio (call-ins, DJ links, ads, news) | 0 (radio comes later) | 450 |
| **Ambient total** | **about 830** | **about 5,700** |
| Story dialogue (cutscenes, for scale) | 600 | 5,000 |

**Writing rules:** every line has a trigger; a line that fits everywhere is cut. Jokes punch at situations and at the speaker, never at a group. **After Chapter 4, every line tagged `impaired` leaves every pool** (death memes included), and Aries's lines leave the pool, though her phone thread stays, and the player can scroll it.

### 3.11 Loading screens

(The research turned up nothing reliable on how GT4 or NFSU2 built their loading screens, so this spec is ours, built from the lessons above: the phone-as-quest-log, the parody ads, the local flavour.)

**When:** every scene change (story, counter, drive, apartment). The drive itself streams with no loading, so these are transition cards: show one while `ResourceLoader.load_threaded_request` loads the next scene and `world.warm()` finishes. **At least 1.2 s** (so it never flashes), otherwise as long as loading takes; a card over 120 characters waits for loading + 2.5 s or a button. Never pad past 3 s.

**Layout (640×360):** left 400 px, a code-drawn vignette (a `StorySets` set cropped and tinted, the player's current car from `PixCars`, or a `Face` portrait for a character's line) with dithered grain; right 240 px, the category tag in its colour (TIP, PORT RUMBLE, CAR TRIVIA, AD, MARITIME, GUS SAYS, THE DAILY CLUTCH), the text in `PixelFont` size 2 wrapped to 26 characters, and a spinning hubcap as the progress indicator.

**Choosing a card:** 40% tips (with priority for a system the player is about to meet for the first time: the dipstick tip before the first meetup), 20% lore, 15% car trivia (about the car being loaded if possible), 15% ads, 10% Maritime. Filtered by season, chapter and flags; no repeats in a session; seen ids kept in a local prefs file so they rotate across sessions.

**Special states:**
- **From the end of Chapter 4 to week 2 of Chapter 5:** plain tips, white on black, no art, no ads, no jokes. The first one in Chapter 5 says only DAY 1.
- **The first load of each in-game day** shows the Daily Clutch's front page, with a headline built from yesterday's flags.
- **After the Chapter 8 reveal,** every Hatch Motors ad card is the same ad with WE'LL TREAT YOU LIKE FAMILY spray-painted over: LIKE FRANK?

**Data:** `data/loading.json`, entries `{ id, cat, text, when, art }` with the same `when` schema as barks; `art` is `"set:tims"`, `"car:current"` or `"face:GUS"`.

### 3.12 Cutscene presentation rules

**The line format grows, backwards-compatible** with today's `[speaker, text]` in `StoryScript.SCENES`:

```gdscript
["DOM", "Lord. [p=0.6]Thank you for this meet.", { "e": "grace", "shot": "close" }]
["shot", "two", "DOM", "LEO"]
["cam", "pan", 0, 80, 3.0]        # move across the set from x 0 to x 80 over 3 s
["fx", "shake", 3, 0.4]           # 3 px for 0.4 s
["fade", "black", 0.8]
["letterbox", true]
["sfx", "door_slam"]
["wait", 1.2]
["vice", "THE BOTTLE", "One won't hurt. One never has."]
```

**Inline tags:** `[p=0.4]` pause; `[spd=0.5]` speed; `[s]...[/s]` shake; `[w]...[/w]` wave; `[b]...[/b]` big; `[c=red]...[/c]` colour; `[e=angry]` change expression mid-line; `[bleep]...[/bleep]` (drawn as #### with a bleep when the concept's bleep toggle is on). Effects are for feelings, at most one tagged phrase in five lines.

**Shot types:**

| Shot | On screen | For |
|---|---|---|
| **SET** | The set at 2x, small portrait in the box (today's look) | Establishing, groups |
| **TWO** | Set dimmed 40%; two 96 px portraits facing each other above the box | Two people talking |
| **CLOSE** | Set darkened and blurred; one 128 px portrait centre-left; big name plate | Feelings, reveals |
| **INSERT** | One object drawn big: the napkin, a VIN plate, a cassette, the green book, the tubing cutter | Clues |
| **PHONE** | The phone full-screen with bubbles | Texts (the clock-out texts today are lines in a box; they should be bubbles) |
| **PANELS** | Two or three comic panels | Montages, "SIX MONTHS LATER" |
| **POV** | A frozen frame of the drive behind a windshield frame | Coming out of a drive |
| **BLACK** | White text on black | The gravest moments |

**Camera:** paint sets 400×180 instead of 320×180 so a pan can travel 80 px; `push` zooms 1.0 to 1.1 over 2 s for tension; `shake`, `fade` (black or white) and `letterbox` (24 px bars) as above.

**Portraits:** extend `Face`'s `expr` (today flat, smirk, frown) to eight: neutral, happy, angry, sad, smug, shocked, tired (hungover), crying; plus specials: Dom *grace* (eyes closed, head bowed), Gus *squint*, Mikey *baked*, Darrell *lying* (eyes slide left), Hatch *salesman* (too many teeth), Aries *eye-roll*. **Blink** every 2.5 to 6 s (half, closed, half; 60 ms each). **Talk:** three mouth frames at 10 fps while typing, on vowels; closed on pauses. The concept asks for 96×96 portraits; `Face` draws 64×64 today, so the generator needs a 96 grid (shown at 96 in TWO, 128 in CLOSE, 64 in the box).

**Text speed:** 45 characters a second (55 today reads a little fast in pixel type), scaled per speaker: Dom 0.7, Gus 0.8, Toby 0.95, Mia 1.0, Hatch 1.05, Mikey 1.1, Darrell 1.15, Aries 1.2. **Pauses:** comma 0.12 s, full stop / ! / ? 0.3 s, ellipsis 0.45 s, dash 0.2 s; 0.25 s at the end of a line before the next-arrow shows.

**Blips** (generated live, like `render/engine_audio.gd`): 35 ms on every second character (not spaces or punctuation), 18 dB under the music.

| Speaker | Blip |
|---|---|
| Leo | 180 Hz square |
| Gus | 110 Hz square, low-passed |
| Mikey | 220 Hz triangle, ±12% wobble |
| Aries | 330 Hz square, short |
| Dom | 130 + 195 Hz together (a fifth: an organ) |
| Mia | 260 Hz, 25% pulse |
| Toby | 150 Hz saw |
| Darrell | 200 Hz with random ±20% pitch (he's lying) |
| Hatch | 170 Hz sine (smooth) |
| Tremblay | 240 Hz triangle |
| The old manager | Pitch from the avatar's seed |
| Narration | A soft typewriter tick every third character |
| THE BOTTLE | Nothing. Its text is slightly transparent |

**Choices:** never timed. When a choice changes someone's loyalty, a sticky note in Gus's handwriting appears for a second: "GUS NOTICED." **Back:** LB/Backspace steps back (exists); holding it opens a scrolling log of the scene. **Auto** is off by default (2.0 s + 0.04 s a character when on). **Skipping:** hold A for 1.5 s to skip a scene you've seen; a first viewing can be fast-forwarded line by line but not skipped whole.

**Title cards** (as now), plus the date and place in small ash type and the title colour cycling slowly between gold and bone. **Boss intros** (CAGE BOSS's tale of the tape): both cars in profile, class, ET and power, the boss's CLOSE portrait and one line, 3 s. **Chapter complete:** the barbecue table, with seats decided by family and crew loyalty.

**Serious scenes** (Aries's night, the funeral, Gus's heart attack, Frank's last tape): letterbox on, no blips, no music or one held note, text at 0.7 speed, no jokes in narration, no shake, fades instead of cuts. Back still works.

**Accessibility:** text speed, instant text, text size 1x or 1.5x, high-contrast box, the bleep toggle, screen shake off, flash reduction (lightning, the crash).

---

## 4. Lines in the game's voice

Dry Maritime humour, swearing allowed, no slurs, no real car makes. Chiac lines carry their English in brackets. Numbered straight through so the count is easy (212 lines). Each is tagged with where it goes.

### 4.1 Phone texts

1. **ARIES:** leo the furnace is making the noise again. the bad noise. not the normal bad noise
2. **ARIES:** coach says if i dont have new skates by friday i can be a cone at practice. like an actual cone
3. **ARIES:** there's a black charjer across the street. the guy waved. do we wave back or is that how it starts
4. **ARIES:** i made mac and cheese for 2. you have 40 min before it becomes mac and cheese for 1
5. **ARIES:** dont text and drive. i can see the read receipt you idiot
6. **ARIES:** gus says you passed a car with no wipers today. in october. here
7. **ARIES:** can you come to my game saturday. you dont have to cheer. just be there
8. **ARIES:** ok you came. you cheered. you were SO loud. never do that again (do it again)
9. **ARIES:** mia picked me up from practice. she drives like she's mad at the road. i love her
10. **ARIES** (Ch3): PASSED!!!!!! the examiner said i was "assertive." i think that means good
11. **ARIES** (Ch3): mia says im a better driver than you. i didnt argue because i have manners
12. **ARIES** (Ch4): are you coming home or do i need to come get you
13. **MIKEY:** bro theres a silvio on marketthing "needs nothing" and the only pic is a tarp
14. **MIKEY:** update the tarp is on fire
15. **MIKEY:** i found the meaning of life its a $40 timing light from a guy in salisbury
16. **MIKEY:** u need anything from the big stop i am here for reasons i cant explain
17. **MIKEY:** aries beat me at the kart game and then explained why. i feel attacked
18. **MIKEY:** is it weird i miss your dads car. like the car specifically
19. **MIKEY** (Ch5): read every paper today like u said. caught a fake licence. felt like a cop. hated it. loved it
20. **MIKEY** (Ch5): a lady asked where you were and i said "away" and she said "oh like out west?" and i said yeah. hope thats ok
21. **TOBY:** Ditch on 880 by the quarry. Car's fine. Driver's not. Not you this time, so that's growth.
22. **TOBY:** Freezing rain tonight. Stay home or call me. Those are your two options.
23. **TOBY:** Hooked a Cava-lame with a moose in the windshield. Moose walked away. MOOSE.
24. **TOBY** (Ch7): I'm not doing it for you. I'm doing it for her. Where are you.
25. **GUS:** LEO THE LIFT IS MAKING A NOISE DONT USE IT. ALSO DONT ASK ME WHAT NOISE
26. **GUS:** CALL ME
27. **GUS:** NEVER MIND I FIGURED OUT THE PHONE
28. **GUS** (Ch5): VISITING SUNDAY. BRINGING THE SOUP YOU HATE
29. **MIA:** Bay 3 this week: $1,200. You owe: $3,000. I've attached nothing because I don't attach things.
30. **MIA:** You owe me a car, a turbo and an apology for saying "my bad." Two of those are negotiable.
31. **MIA** (Ch4, 1:47 a.m.): Leo. Pick up.
32. **DOM:** [VOICE NOTE 1:12] "Lord, bless this hot dog. And bless Leo, who is late."
33. **DOM:** [VOICE NOTE 0:09] "...Sal says you're on your way. Sal lies. Hurry."
34. **DARRELL:** hey bud its darrell from the silvio. got rims if u want. dont ask whos car they were on
35. **DARRELL:** correction they were on my car. my wifes husbands car
36. **TREMBLAY:** Leo, it's Constable Tremblay. That's one. Don't make me count to two.
37. **TREMBLAY:** Thanks for the call on the Charjer. Double-double's on your counter. Don't tell anybody I'm nice.
38. **HATCH:** Leo! Dale Hatch. Saw your numbers at dyno day. Frankie would've been proud. Door's always open, kid.
39. **KERNEL:** ok plug it in and DONT touch anything. touching is how they get u
40. **UNKNOWN NUMBER:** The old manager kept files on the shop computer. Check them. Tonight.
41. **MARKETTHING (Kyle):** would u take 200 and a game controller (drift damaged)
42. **MARKETTHING (Brenda):** Hi is this still for sale. My husband Darrell says it's a good one, which is how I know it isn't.
43. **MARKETTHING (the trader):** no money but i have a four-wheeler that runs (it does not run)
44. **HOOVER:** Your rider gave you 2 stars. Comment: "he drifted the roundabout. on purpose. with my groceries."
45. **NB POWERLESS:** Your bill is ready. Your bill is also very sorry.

### 4.2 Radio: The Rumble Line, Talk 1340, with Ron Gaudet (for when radio arrives)

Ron's stock reply to nonsense: **"Well. You've said it out loud now, and that's something."**

46. **DOREEN, RIVERSIDE:** "There's a pothole on Coverdale Road that's older than my grandson, Ron, and I'd like to know who I vote for to get it filled or killed."
47. **WADE, SALISBURY:** "Some young fella drifted the roundabout at the Big Stop three times last night. I'm not calling to complain. I'm calling to say his line was beautiful."
48. **CALLER:** "The tide came up the river this morning at the exact minute the paper said it would, and I want to know why nobody else in this city can be on time."
49. **MARCEL, DIEPPE:** "Ron, j'ai pas de problème avec les signs bilingues. J'ai un problème avec les gens qui savent pas lire ni un bord ni l'autre." *(I've no problem with the bilingual signs. I've got a problem with people who can't read either side.)*
50. **CALLER:** "Is it true if you put it in neutral at Magnet Hill it rolls uphill? Because I tried it on the Causeway and I'm calling from the river."
51. **CALLER:** "First snow tonight. Reminder: summer tires are called that for a reason, and the reason is August."
52. **CALLER:** "The Mountain Tim's gave me a double-double with no double. Just a single. A lonely single, Ron."
53. **CALLER:** "There's a black Charjer idling outside Covington Auto all week. Either somebody's in love or somebody's in trouble."
54. **CALLER:** "My husband bought a car off MarketThing. Fella said it runs great. It does not run great. It runs like a man telling you it runs great."
55. **CALLER:** "There's a moose in my dooryard looking at my truck like he's thinking about it."
56. **RON:** "After the news: is it a pothole or a sinkhole, and does the city care which? Spoiler. No."
57. **CALLER:** "I'm calling about the young fella at Covington Auto who passed my car when maybe he shouldn't have. Thank you, sir. Please don't let anyone hear this."
58. **CALLER** (Ch4, after the vault job): "Somebody dragged a safe down Main Street last night and left a groove in the bricks. I'm not saying it was a crime. I'm saying it was a craft."
59. **CALLER:** "My son wants to go out West for the oil. I told him there's plenty of oil here. It's in my driveway. It came out of his car."
60. **CALLER:** "Is Hatch Motors really giving away a truck at the Raceway opening? I'll stand in a parking lot for a truck. I've stood in a parking lot for less."
61. **CALLER:** "The bore came up the river this morning with a surfer on it, past my kitchen window. I'm seventy-one. I never thought I'd see that and I'd like it to stop."
62. **CALLER:** "Can somebody explain why the kid at Covington Auto reads my insurance like it's a love letter."
63. **CALLER:** "The crossing on Main stopped me eleven minutes so a train could carry what I believe was one potato."
64. **CALLER:** "To whoever keeps putting googly eyes on the Lutes Mountain towers: we see you. At night. It's horrifying."
65. **RON** (ad read): "This hour's brought to you by Hatch Motors. We treat you like family. Terms and conditions apply to family."
66. **CALLER** (Ch5, the first week back on air after the crash; no joke): "I just wanted to say drive safe tonight, everybody. That's all. That's the call."
67. **CALLER** (Clean ending): "I bought my truck at Hatch Motors. I'd like to know if I give it back or if it's evidence."

### 4.3 At the counter

68. "Morning. Safety, please. And before you say anything, the rust was there when I bought it, so it's grandfathered."
69. "I need the sticker by noon. My mother-in-law's visiting and this car is my only escape."
70. "It makes a noise turning left. So I don't turn left anymore. I go right three times."
71. "Bonjour, hi. Mon char fait un drôle de noise quand je brake, là. Comme une outarde. Une outarde triste." *(My car makes a funny noise when I brake. Like a goose. A sad goose.)*
72. "C'est pas mon char, c'est le char à mon cousin. Mais c'est moi qui le drive, so c'est quasiment mon char." *(It's not my car, it's my cousin's. But I drive it, so it's basically my car.)*
73. "Asteure, c'est quoi le problème avec mes papiers? Je les ai printés moi-même. Sur du vrai papier." *(So what's wrong with my papers now? I printed them myself. On real paper.)*
74. "Y fait frette à matin, pis mon char a pas voulu starter. Je l'ai poussé jusqu'icitte." *(It's cold this morning and my car wouldn't start. I pushed it here.)*
75. "My check engine light's been on since 2014. We've made our peace."
76. "Is the insurance supposed to be expired? I thought that meant it was mature."
77. "The VIN's different because I had the dash replaced. With a different dash. From a different car. That's normal?"
78. "My licence photo's from before the beard. And the divorce. And the other beard."
79. "Can you put the winter tires on? I know it's July. I like to be ready."
80. "Your dad did my brakes in '06. Never had to do them again. I mean, I probably should've."
81. "I'm not saying I'll leave a bad review. I'm saying my cousin writes reviews professionally."
82. "Do you do oil changes or just judge people?"
83. "I don't have the registration, but I have a very detailed memory of it."
84. "It smells like maple syrup in there and I didn't spill any. That's the problem."
85. "If it fails, can you fail it gently? It's been through a lot."
86. "The rust isn't through. It's just very committed."
87. "I brought a dozen donuts. That's not a bribe. A bribe would be two dozen."
88. "This truck's got 600,000 on it. The odometer only goes to 299,999, so we're on lap three."
89. "Need it before the tournament in Sussex. We leave at five a.m., and the car's coming with us if it's the last thing it does."
90. "I'm from away. Toronto. Is it normal everybody here waves at me?"
91. **Jayden, the Mountain Road drive-thru kid:** "I've seen things, man. A guy ordered forty timbits for his dog. The dog was a cat."
92. **Familia:** "Dom says hi. Dom says the napkin explains itself. Dom says don't read the napkin out loud."
93. **Sting:** "Buddy of mine says you're the guy for, you know. Numbers. Not math numbers. The other numbers."
94. **Hatch fleet driver:** "Fleet car from Hatch Motors. Mr. Hatch says you're quick and you're Frankie's kid. That's the whole message."
95. **After a DENY:** "Fine. I'll go to Lindsay's. She passes anything with a pulse."
96. **After an APPROVE:** "Frank used to give out a sucker after. I'm not asking. I'm just saying there was a tradition."
97. **Inspector Hachey:** "Good morning. Don't mind me. I'm just going to stand here and be the Ministry."
98. **ASK, plate swap:** "Me and my cousin swapped plates for luck. His luck's been bad. Mine's about to be, I guess."
99. **ASK, valid exception:** "I bought it Thursday. Here's the bill of sale. Signed and dated. My handwriting's a crime, but it's a legal one."
100. **Ch5, at Mikey's counter:** "Where's Leo?" (a beat) "...Oh. Right. Sorry. Tell him... never mind. Sticker, please."

### 4.4 Loading cards

101. **TIP:** Every lie at the counter can be proven from the papers on the desk. If you can't prove it, it's not a lie. It's Tuesday.
102. **TIP:** Rev a cold engine and it remembers. Let it warm up. It's a car, not a fling.
103. **TIP:** Summer tires turn to hockey pucks below 7 °C. You'll learn it the cheap way or the expensive way.
104. **TIP:** Bridges freeze before roads. The Gunningsville Bridge has opinions about you.
105. **TIP:** Locked wheels don't steer. If you're sliding at something, let off the brake and point at something else.
106. **TIP:** Touch the hood before the seller starts it. A warm engine at a meetup is a seller hiding a cold start.
107. **TIP:** Parts from RockBottomAuto come from the States. So does the brokerage fee. Budget for heartbreak.
108. **TIP:** Two mistakes a shift are warnings. The third costs money. The twelfth costs the licence.
109. **TIP:** The plow does the highway first. The plow always does the highway first.
110. **TIP:** A burnout eats real tread, a millimetre at a time. Smoke is expensive.
111. **TIP:** Drag nights at Airstrip 7 run the eighth-mile. The runway's short. The ambition isn't.
112. **TIP:** Twenty kilos of sandbags in the trunk of a rear-drive car is the oldest winter trick in the Maritimes. It still works.
113. **PORT RUMBLE:** The Chocolate River is not chocolate. Please stop calling City Hall about it.
114. **PORT RUMBLE:** Twice a day the tidal bore pushes the river backwards. The river isn't thrilled either.
115. **PORT RUMBLE:** At Magnet Hill, cars roll uphill. Scientists say it's an optical illusion. Locals say it's Tuesday.
116. **PORT RUMBLE:** They call it the Hubcap City. Nobody remembers why. Everybody's lost one here.
117. **PORT RUMBLE:** Covington Auto opened in 1971. The coffee maker arrived in 1974 and has not been cleaned since.
118. **PORT RUMBLE:** The towers on Lutes Mountain blink red all night. You can see them from everywhere in town. Everywhere.
119. **CAR TRIVIA:** A turbo is a fan spun by your own exhaust. Free power, if you don't count the turbo.
120. **CAR TRIVIA:** A "money shift" is a downshift into a gear the engine can't spin. It's named after what it costs.
121. **CAR TRIVIA:** A VIN is 17 characters and never uses I, O or Q, so nobody mixes them up with 1 and 0. People still find a way.
122. **CAR TRIVIA:** Brake fluid soaks up water from the air. Wet fluid boils sooner, and the pedal goes soft when you need it most. Bleed it every fall.
123. **CAR TRIVIA:** Winter tires aren't just about tread. The rubber stays soft in the cold. That's the whole trick.
124. **CAR TRIVIA:** The 1991 Nissun Silvio's turbo four was built for getting groceries. No one has ever used one to get groceries.
125. **AD:** HATCH MOTORS. We'll treat you like family. (Family sold separately.)
126. **AD:** PIZZA DELIRIUM. Thirty minutes or it's free. Thirty-one and our driver's crying in your dooryard.
127. **AD:** CANADIAN TIRED. Everything you need, in an aisle you can't find.
128. **AD:** RUMBLE AUTO PARTS, next door to Covington Auto. We have it, we can get it, or we can tell you a story about it.
129. **AD:** LINDSAY'S LUBE & INSPECT. We look at your car! (Briefly.)
130. **AD:** MOOSE WHISTLES, $9.99. Do they work? The moose aren't saying.
131. **MARITIME:** "Some cold out" is a complete weather report.
132. **MARITIME:** Directions here are given by what used to be there. "Turn left where the bowling alley burned down."
133. **MARITIME:** A dooryard is a driveway. A two-four is a case of beer. A double-double is breakfast, lunch and a personality.
134. **MARITIME:** Everybody you meet is related to somebody you know. Assume nothing. Be nice.
135. **MARITIME:** "Going out West" is a career plan, a threat and a love language.
136. **MARITIME:** Mud season is the fifth season. It starts when the snow goes and ends when you lose a boot.

### 4.5 Gus-isms

137. "It's not broke. It's just not working."
138. "Read the paper. The paper doesn't care how you feel."
139. "Your father could hear a bad wheel bearing from the house. You can't hear me from the bay."
140. "Torque it to spec. Not to feel. Feel is how people die."
141. "Rust never sleeps. Neither do I, apparently."
142. "Every car tells you what's wrong with it. Most people don't let it finish."
143. "That's a Bay 3 car. I don't see Bay 3 cars. My eyes stop at Bay 2."
144. "I've worked every Saturday since 1981. I'm not stopping for a hangover. Especially not yours."
145. "Winter tires on the first of December. Not the second. The second is how you meet Toby."
146. "If it pulls left, it's the alignment. If it pulls right, also the alignment. If it pulls you into a ditch, that's you."
147. "Cheap parts are expensive twice."
148. "Never trust fresh undercoating in May."
149. "You want to go fast? Learn to stop. Your father learned. Eventually."
150. "Coffee's on. It was on yesterday too. Same coffee."
151. "Paperwork's the job. Wrenching is the fun part. Lying is the expensive part."
152. "Never buy a car at night, in the rain, from a man named Darrell."
153. "The Ministry doesn't care if you're grieving. Neither does a brake line. Read the sheet."
154. "Good mechanics fix what's broke. Great ones find out why it broke."
155. "Your sister's smarter than both of us. Don't tell her I said so. She'll charge me."
156. "I don't do hugs. I do oil changes. Same thing, takes longer."
157. "A milkshake on the dipstick isn't a car for sale. It's a car for sorry."
158. "That's not a noise. That's a warning with a voice."
159. "If the VIN's ground off, somebody had a reason, and it wasn't a nice one."
160. "Bleed them from the far wheel in. Your father's way. The right way. Same thing."
161. "Drive it like you're bringing it back to me. Because you are."
162. "A key on the hook is a key. A key in your pocket is a key in a ditch."
163. "I'm not mad. I'm seventy. It looks the same."
164. "Sunday. Brakes. Every Sunday. You don't skip it because it's snowing. That's why you do it."
165. (Passing the Hatch Motors billboard, every time:) "Hm."
166. (After the reveal moment, his highest praise:) "...Yeah. Okay."

### 4.6 In the car

167. **TOBY** (speeding): "You know what I call people who drive like this? Customers."
168. **TOBY** (passing a ditch): "Pulled a Charjer out of that one in '17. Same Charjer in '18. Same guy. Bought him a calendar."
169. **TOBY** (red light): "That was red. That was a red you could see from space."
170. **TOBY** (the Mountain, Ch1): "...I towed your dad off this hill. I'll tell you about it when we're stopped."
171. **TOBY** (black ice warning): "Bridge coming. Feet light. Hands quiet. Don't do anything you'd have to explain."
172. **MIKEY** (near miss): "Oh my god. Oh my god. Okay. I'm fine. My soul left but it's coming back."
173. **MIKEY** (any Tim Burtons in view): "Tims. Tims. Leo. Tims. TIMS."
174. **MIKEY** (drifting): "Bro you're sideways. Is this on purpose. Blink twice if it's on purpose."
175. **MIKEY** (co-driver): "Left... medium? Medium-left. A left with feelings. Okay that was a right."
176. **MIKEY** (moose sign): "If we hit a moose do we get to keep the moose."
177. **ARIES** (pulling away unbuckled): "Seatbelt." (two seconds later) "SEATBELT, Leo."
178. **ARIES:** "You drive like Dad. The good parts. And the part where he swore at seagulls."
179. **ARIES** (Ch3, in the passenger seat after her test): "I'm going to come to a full stop. Watch me. That's called a full stop. You should try one."
180. **ARIES** (speeding): "Can you not? I have a math test tomorrow and I'd like to die after it."
181. **GUS** (over the limit): "Speed limit's a number, not a dare."
182. **GUS** (snow): "Gentle. The car's not angry. Don't make it angry."
183. **DOM** (arriving at Airstrip 7): "Every time I come here I say a prayer. Mostly for the turbos."
184. **DOM** (bad launch): "Too much wheelspin. You're not burning rubber. You're burning money, and my patience, which is also money."
185. **DOM** (Ch5, the gate): "I'm not going to say grace tonight. I don't think He's listening to me right now. Let's just sit."
186. **THE BOTTLE** (Ch4, at the counter): "One won't hurt. One never has."
187. **THE BOTTLE** (Ch4, clock-out): "You earned it. Look at you, earning things."
188. **DAD'S VOICE** (Ch2, after a tape): "Check the brakes, bud. Every Sunday."

### 4.7 Bleeter and the Daily Clutch

189. **@RumbleScanner:** Tow truck on Coverdale. Again. Who keeps finding the same ditch
190. **@hubcapcityhotdogs:** Dom T bought 40 hot dogs and said grace over each one individually. we closed at 2. bless
191. **@PRumblePolice:** Reminder: winter tires save lives. Summer tires save money until they don't.
192. **@ariesc:** my brother parked in gus's spot again. gus started parking in his. this is how wars start
193. **@MarketThingFails:** "Runs great" (photo: the car is on fire)
194. **Yowl, ★★★★★:** "The kid read my insurance like it was scripture. Passed. Felt seen."
195. **Yowl, ★☆☆☆☆:** "Wouldn't pass my car just because it had no brakes. Very judgmental for a garage."
196. **@hatchmotors:** Proud sponsor of Dyno Day at Airstrip 7! Frankie Covington's kid pulled 211 at the wheels. FAMILY!
197. **DAILY CLUTCH:** POTHOLE ON MAIN NAMED A PERSON OF INTEREST
198. **DAILY CLUTCH:** TIDAL BORE ARRIVES ON TIME; COUNCIL "INSPIRED," PROMISES NOTHING
199. **DAILY CLUTCH:** MOOSE HOLDS UP TRANS-CANADA FOR AN HOUR, LEAVES WITHOUT EXPLAINING
200. **DAILY CLUTCH:** SAFE DRAGGED THROUGH DOWNTOWN; BRICKS "WILL NEED A MINUTE"
201. **DAILY CLUTCH:** MINISTRY AUDITS LOCAL INSPECTION STATIONS; ONE MANAGER "LOOKED NERVOUS," SAYS MANAGER
202. **DAILY CLUTCH** (Clean): DEALERSHIP OWNER CHARGED IN 2018 DEATH OF LOCAL MECHANIC

### 4.8 New death memes (free drive, and the story before Chapter 4)

203. YOU DIED BECAUSE A MOOSE IS 600 KG OF NOPE AT WINDSHIELD HEIGHT.
204. YOU DIED BECAUSE THE TIDAL BORE ARRIVED ON TIME AND YOU DIDN'T.
205. YOU DIED BECAUSE YOU TRIED THE MAGNET HILL TRICK ON A HILL THAT WAS JUST A HILL.
206. YOU DIED BECAUSE THE PLOW BANK WAS NOT, IN FACT, FLUFFY.
207. YOU DIED BECAUSE YOU RAN THE CROSSING. THE TRAIN WAS CARRYING POTATOES. THE POTATOES WON.
208. YOU DIED BECAUSE YOUR MARKETTHING BRAKES WERE "BARELY USED." BARELY. USED.
209. YOU DIED BECAUSE YOU DID A DONUT IN THE TIM BURTONS LOT AND THE LOT DID ONE BACK.
210. YOU DIED BECAUSE MUD SEASON ATE YOUR CAR, THEN YOU.
211. YOU DIED BECAUSE YOU FOLLOWED THE GPS INTO A FIELD. THE GPS IS FINE. THE GPS IS ALWAYS FINE.
212. YOU DIED BECAUSE YOUR HOOD WASN'T LATCHED AND YOU LEARNED WHAT A HOOD LOOKS LIKE FROM THE INSIDE.

(Rule from section 3.10: no meme ever plays for a crash that happens with Aries in the car, at the S-bend on Mountain Road after Chapter 4, or while impaired after Chapter 4.)

---

## 5. Roadmap: what to build first

Ordered by player-visible win per week of work, on top of what exists (the drive with its sim, traffic, weather and memes; the counter's first week; the prologue and Chapter 1's first day). Each milestone is a playable build, like the concept's build order, and each adds headless tests in the style of the existing ones.

| # | Milestone | Size | What the player sees | Main files | Tests |
|---|---|---|---|---|---|
| **0** | **Script and continuity fixes** | 2 to 3 days | The prologue reads right: Monday is Monday, the twist stays hidden, choices come back, Toby has a scene, Dom explains why there were no police, the drunk drive ends honestly | `story/story_script.gd`, `story_missions.gd` (microsleep), `counter/counter_scene.gd` (briefs), `counter/rules.gd` (car names, fix 16), `data/cars/silvio.json`, `title.gd` + `story/avatar_scene.gd` (first boot) | `story_tests.gd` already checks speakers and sets; add "every flag set is read somewhere" |
| **1** | **Cutscenes that feel alive** | 2 to 3 weeks | Expressions, blinks and talking mouths; per-character blips and pauses; TWO, CLOSE, INSERT, PHONE and BLACK shots; pans, shakes, fades, letterbox; a backlog; dated title cards | `counter/face.gd` (expressions, 96 px), `story/story_scene.gd`, `story/story_sets.gd` (400 px sets), new `story/story_voice.gd` (blips) | Every tag in every scene parses; every expression name exists |
| **2** | **The phone, barks and loading cards** | 2 weeks | Texts arrive during drives and clock-outs; passengers talk in balloons; scene changes show a card instead of a cut; the first 150 lines and 60 cards | New `ui/phone.gd`, `barks/barks.gd` (DeathMemes-style picking), `ui/loading_card.gd`, `data/barks/*.json`, `data/loading.json`; hooks in `drive.gd` for events | Every bark's trigger keys are known; cooldowns hold; no `impaired` line after Chapter 4 |
| **3** | **Desk 2.0** | 3 weeks | The shift clock and a queue at the window, two warnings a day, ASK with exceptions and proof documents, the binder, weeks 2 to 4 of rules, Hatch and Darrell at the counter, the sticker log, Leo's notebook | `counter/rules.gd`, `counter/counter_scene.gd`, new `data/story_customers.json` | Extend `counter_tests.gd`: an exception is valid only when its proof passes; every new problem is findable from the desk |
| **4** | **Garage 2.0 and the dyno** | 4 weeks | Buy Stage 1 to 4 parts for the Silvio, wait for the courier, check the packing slip, watch Gus install it, see the reveal, pull numbers on the dyno; parts wear and need fixing | New `shop/parts.gd`, `shop/upgrades.gd`, `shop/orders.gd`, `ui/parts_screen.gd`, `ui/dyno_screen.gd`, `data/parts.json`; new fields in `sim/car_sim.gd`; `ui/garage_screen.gd`; `save_game.gd` (version 2) | `shop_tests.gd`: `apply()` never changes the base spec; each stage improves eighth-mile ET or braking; the dyno's torque equals the sim's; knock rule |
| **5** | **Evenings worth having** | 3 weeks | Tow calls in Toby's wrecker on the cars traffic already wrecks, Pizza Delirium, Friday Drag Night at Airstrip 7 (top-down eighth-mile bracket racing; the side view comes later), Night Drive, and the Kitchen Table on Sundays. The day loop merges: clock in, clock out, evening, home, Sunday | New `jobs/jobs.gd`, `ui/kitchen_table.gd`; `world/traffic_car.gd` (towable wrecks); `story/story_state.gd` (calendar and meters) | `jobs_tests.gd`: pay formulas; every job's start and end are on roads |
| **6** | **Chapter 1: the vertical slice** | 4 to 5 weeks | The rest of Year 1: Dom's medal tests, Toby's night shift, first snow and the anniversary on the Mountain, Hatch's dyno day, the Ministry audit week, Johnny Tram's crew ladder and pink slip; crew v1 (Gus, Toby, Mikey; slots; levels 1 to 3) | `story/*`, new `crew/crew.gd`, `data/crew.json` | Story tests for the new steps; crew perks apply |
| **7** | **MarketThing** | 4 weeks | Listings every morning, chat and haggling, meetups with the inspect tool, test drives with hidden faults, quirks, buying and selling | New `market/market.gd`, `ui/phone.gd` app, `data/market_cars.json` | `market_tests.gd`: every hidden fault is provable at the meetup |
| **8** | **Chapter 2 and the first real winter in the story** | 6 weeks | Han's drift lessons, the Drift Kingpin, the tapes as collectibles with build sheets (Frank Spec), hiring, the Hatch fleet partnership, Aries's suspension | Story, desk rule pack 2, tricks | |
| **9** | **Chapter 3 and the USB job** | 4 weeks | The USB job, the chase, the carbon copy, Nate at the counter, Aries's lessons and road test | `story/usb_job.gd` (see note below) | Consent declined always gives the fake desktop |
| **10+** | Chapters 4 to 8, the endings, customization depth and the livery editor, the side-view drag, radio | | | | |

**Why this order.** The prologue is the first hour every player sees, so Milestones 0 and 1 make the existing story land before more is written. The phone and barks (2) make the world talk without writing a single new scene. The desk (3) is the game's most original mechanic and is already half built. The garage and dyno (4) are the hook for car people, and they give the money from the desk somewhere to go. Evenings (5) close the day loop. Only then does new story (6 onward) go in, into systems that can carry it.

**Not yet:** radio stations, the livery editor, the side-view drag camera, EVs and exotics, couch versus, ghost races, Legacy mode, and co-op (after launch, per the concept).

**Note for the USB job (Milestone 9).** In Godot 4.5, list names with `DirAccess` on the paths from `OS.get_system_dir()` (Documents, Desktop, Downloads, Pictures), with `include_hidden` off, and the static `FileAccess.get_size(path)` and `FileAccess.get_modified_time(path)` for sizes and dates ([Godot 4.5 FileAccess docs](https://docs.godotengine.org/en/4.5/classes/class_fileaccess.html)). Both are class methods that don't hand the game an open file, which keeps to the concept's rule that nobody else's files are ever opened; never use `get_md5`, `get_sha256` or anything else that reads contents. Never recurse more than two folders deep; time-box the listing to 200 ms and fall back to the fake desktop if it's slow. Create `Documents/SuperHiddenSecretFolder/EncryptedFile` at first boot as the concept says, and say so in one line on the first-boot profile screen so nobody is surprised to find it.

**One more rule to add now (Milestone 2):** while Aries is in the passenger seat (Chapters 1 to 3), a fatal crash shows no meme. It shows a plain card, ARIES WAS IN THE CAR., and reloads the checkpoint. Players will learn to drive carefully when she rides along, which is exactly the habit Chapter 4 needs them to have.

---

## Appendix A: names in Port Rumble

| Real thing it suggests | In the game |
|---|---|
| Moncton | Port Rumble, "the Hubcap City" |
| Petitcodiac River | The Petitcodiac, "the Chocolate River" (geography, kept) |
| Magnetic Hill | Magnet Hill on the map; "Magnetic Hell" to drifters |
| Tim Hortons | Tim Burtons; "the Mountain Tim's" is the one on Mountain Road |
| Canadian Tire | Canadian Tired |
| A big Maritime dealership group | Hatch Motors (and Hatch Motors Raceway from Year 6) |
| RockAuto | RockBottomAuto.com |
| Uber | Hoover |
| Facebook Marketplace / Twitter / Yelp / Instagram | MarketThing / Bleeter / Yowl / Instagrime |
| The power utility | NB Powerless |
| A pizza chain | Pizza Delirium |
| A beer | Moosebutt Lager (only ever in ads that end with "don't drive after") |
| The rival inspection station | Lindsay's Lube & Inspect |
| The parts store next door | Rumble Auto Parts (the PARTS building on the map) |
| The phone parts catalogue | Fundy Parts Supply |
| The junkyard | Petitcodiac Pick-n-Pull (Salisbury) |
| Talk radio | Talk 1340, The Rumble Line with Ron Gaudet |
| The morning paper | The Daily Clutch |
| Hatch's numbered company | 514207 N.B. Ltd. |

New cast introduced by this bible: **Walt Covington** (grandfather, founded the shop, 1971), **Sgt. Roy Pelletier** (retired; wrote Frank's report), **Kevin "Kernel" Gaudet** (Mikey's cousin; the earbud), **Inspector Hachey** (the Ministry), **Lindsay** (the rival station), **Brenda** (Darrell's wife, keeper of receipts), **Ron Gaudet** (radio host), **Aunt Carol** (Riverview), and regulars **Jayden**, **hockey dad Rob** and **Mrs. Doiron**.

## Appendix B: decisions for the team

1. **Chapter 5 as the custody year** (section 2.3). Recommended. The alternative is to keep the concept's Chapter 5 and say in one card that Leo is awaiting trial, with the trial as the chapter's end; it's cheaper but players will ask how he's driving.
2. **Lutes Mountain Road for Frank's death** (section 2.2). Recommended. The coast becomes a later map expansion.
3. **How dark THE STREET ending is.** As written, the Familia cuts Hatch's brakes and Leo lets it happen. If that's too far, Hatch's own worn brakes fail (he never checked them on Sundays) and Leo chooses not to call it in.
4. **Nate Boudreau** as a Ministry fraud investigator, to keep clear of the excluded Brian archetype.
5. **The pandemic years** (2020 to 2022): never mentioned, felt only in MarketThing prices. Recommended.
