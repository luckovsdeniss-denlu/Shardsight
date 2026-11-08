# Changelog

Version lives in `project.godot` (`application/config/version`). Bump it there; CI stamps it
into the Android `version/name` and derives `version/code` from it (major*10000 + minor*100 + patch).

## 0.47.1
A prettier map.
- The minimap is painted at three times the detail, like a drawn map: grass with soft meadows,
  round tree crowns lit from the top-left, water deep in the middle and pale in the shallows with
  glints, sandy shores, shaded rocks, cobbled towns, the dark dungeon, glowing forges and ridged
  house roofs, with dark outlines where open ground meets anything solid.
- Town names (Town, The Outpost, Southmoor) and "Dungeon" are written on it; ankh shrines are
  little glowing ankhs; untouched treasure chests show as gold dots; everyone's dot has a dark
  outline; your hero is a white arrow pointing where it faces (pale blue as a ghost).
- A dark frame with a thin gold line, and a gold "N" for north.

## 0.47.0
Magic in numbers, and your statistics.
- The Spells panel starts with "Your magic": Magery, Evaluating Intellect, Meditation and
  Resisting Spells; mana and how fast it comes back at rest and on the move (and whether metal
  is stopping Meditation); spell damage and healing multipliers; how much faster you cast; the
  chance a blow breaks your spell (and whether Protection is on); how often you shrug off hostile
  spells; your reagents; and each circle's required Magery with your success chance.
- Under every spell, its numbers: circle, mana, reagents, required Magery, your success chance,
  cast time, and exactly what it does with your current power (damage or healing range, poison
  strength, paralysis seconds, stat changes and duration, mana drained...). "Details: On/Off"
  shortens the list.
- Menu > Statistics: what you've done, counted as you play and saved: combat (kills, deaths, hit
  rate, damage dealt and taken, who killed you most), magic (spells cast, favourite spells,
  blessings, confessions), gathering and crafting, gold earned and spent, animals and music,
  thievery, quests and the world, and time played.
- Your magic over your hero's head, under the level and HP: Magery, mana, spell power, reagents,
  and the spell being cast with a countdown (or "[Protection]" when it's on). Menu > Hide magic /
  Show magic turns it off and on; on by default, saved.
- The buttons in the corner Menu are a little shorter, so all of them fit with the minimap.

## 0.46.1
Towns really are safe.
- Several kinds of harm slipped past the towns' protection, which only stopped the damage of
  blows and spells. Now nobody in a town can be harmed, and nobody can harm anyone from inside
  one, by any means:
  - a poisoned blow stopped at a town's edge no longer poisons you, and poison you brought in
    doesn't hurt you inside a town (it still wears off);
  - Poison, Paralyze, curses (Clumsy, Weaken, Feeblemind, Curse, Mass Curse) and Mana Drain
    can't be cast at anyone in a town (a spell that lands as its target steps in fizzles out:
    "protected");
  - poison, paralyze and fire fields don't touch anyone in a town;
  - no blow is swung across a town's edge at all, so Reactive Armor can't reflect one either.
- Your log says "Nobody can be hurt in town." (at most every 5 seconds) when you try.

## 0.46.0
Find your way back.
- Eight ankh shrines stand around the map, one near the middle of each region: a stone plinth
  and a glowing gold ankh with a pale blue light and motes rising, marked on the minimap with
  pale blue crosses.
- Dying makes you a ghost in a grey world, and you must find a resurrection spot: an ankh shrine
  (anyone, free; murderers lose 20% of stats and skills) or a healer or priest (innocents, free).
  Tap the ground to walk your ghost there (you couldn't move it before), or leave Auto on and it
  walks to the nearest. The top of the screen shows the nearest spot, how far and which way.
  You're raised where you stand, at half health, with a sparkle.
- No more being raised at home after a minute with -10% skills: that only happens to a ghost
  still lost after ten minutes.
- Computer players' ghosts walk to the nearest shrine, healer or priest too; criminals and
  murderers, whom healers turn away, now head for a shrine instead of waiting.
- Ghosts look like ghosts: instead of a see-through copy of the living body, a pale blue hooded
  shroud with a dark hollow for a face and two glowing eyes, sleeves reaching out and no legs;
  the robe narrows to a wisp that fades into nothing. The cloth ripples, the edges glow, it floats
  and sways, leans into its glide, and sheds pale wisps. Invisibility still looks as before.

## 0.45.2
- Menu > Hide corpse names / Show corpse names turns the labels over corpses and treasure
  chests (whose they are and what's inside) off and on. On by default; the choice is saved.

## 0.45.1
Use your bow.
- Menu > Bow draws the best bow or crossbow in your bag in one tap; a bow needs both hands, so
  your shield goes into the bag. The button turns into Melee, which brings back your best hand
  weapon and the shield. Before, the Bag refused a bow while you held a shield. You're told how
  many arrows you have, or to buy some from a merchant if you have none.
- Heroes from older saves who have no bow or crossbow find a bow and 40 arrows in their pack.

## 0.45.0
Pick a player, attack in one tap.
- Tapping a player no longer pauses the game and opens a panel: it picks them, with a blue ring
  under them and buttons at the bottom of the screen: "Attack <name>" (it says why not when
  you can't: in town, Trammel, an ally; "(crime!)" when they're an innocent), "Info" (the old
  panel with their gear) and "X" to let go. The pick drops when you tap elsewhere, or when they
  die, vanish or are over 30 m away.

## 0.44.2
- Treasure chests no longer fall from the sky: a slain monster (10%) leaves one on the ground
  beside its body, appearing in a burst of gold sparkles, with the golden beam and light as before.

## 0.44.1
Artifacts that look the part.
- Artifact weapons glow in their colour: runes down the blade and a gem at the guard on swords
  and daggers, a glowing head on maces and hammers, the blade of a halberd, the string and limb
  tips of bows, the prod of crossbows.
- Artifact armor adds a cape in the artifact's colour and glowing rune bands across the chest
  and round the waist; a plate helm's eye slit glows, a mail coif wears a glowing circlet.
- An artifact shield has a glowing rim and boss.
- Anyone carrying an artifact has motes of its colour swirling round their feet.
- On Medium and High graphics the glowing parts bloom softly.

## 0.44.0
Treasure from the sky.
- Every slain monster (not summons) has a 10% chance to drop a treasure chest from the sky: it
  falls, bounces as it lands with a burst of gold sparkles, and a golden beam rises from it to the
  sky with a warm light round it. Inside: an artifact, gold (more from dangerous monsters) and
  some reagents. Anyone may take it, so be quick; an untouched chest lasts 3 minutes, an emptied
  one vanishes. Your log tells you when one falls nearby and what's in it.
- Ten artifacts, legendary named gear 50-65% stronger than the ordinary kind and worth six
  times as much, each showing in its own colour on the model: Blade of Vengeance (longsword),
  Dawnbreaker (broadsword), Frostbite (kryss), Thunderfist (war hammer), Whisperwind (composite
  bow), Doombolt (heavy crossbow), Starforged Plate, Moonweave Mail, Shadowhide (studded armor)
  and the Aegis of the Dawn (heater shield).

## 0.43.0
First person.
- Menu > First person puts the camera at your hero's eyes, looking where it faces and a little
  down so the ground shows; the view turns smoothly as the hero does, and sits higher in the
  saddle. A wider lens; your own body, health bar, label and ring are hidden. Tap the ground to
  walk and a monster to attack, as before; twist two fingers to look round. Menu > Top view
  goes back. The choice is saved.

## 0.42.5
- Level counts combat skills only: Swordsmanship, Fencing, Mace Fighting, Archery, Wrestling,
  Tactics, Anatomy, Parrying, Healing, Magery, Evaluating Intellect, Meditation and Resisting
  Spells. Crafting, gathering, taming, music, thieving and the rest no longer raise it. All 13
  at 100 is level 1000 (about 0.77 levels a point); Menu > Skills shows the combat total.

## 0.42.4
- The skill cap is raised to the maximum: every one of the 37 skills can reach 100 (3700
  points; it was 700, "seven skills at 100"). Level 1000 now means every skill mastered, so
  each skill point is about 0.27 of a level: 100 points is level 28, 370 is 100, 1850 is
  500.

## 0.42.3
- Level runs from 1 to 1000 again, from the total of all the hero's skills: no skills is level
  1, the full 700-point skill cap is level 1000 (about 1.43 levels a skill point). It was the
  plain skill total, 1 to 700.

## 0.42.2
- The other sounds vary too, each with several takes picked at random and a slightly random
  pitch: mining rings like a pick on stone and chopping thocks like an axe in wood (they were
  one sound); spells shimmer in four different sweeps, deeper for higher circles; deaths fall
  in three ways, lower for big creatures; loot chimes and skill-gain arpeggios have three tunes
  each; bows twang and crossbows snap and thunk; thunder rolls three different ways.
- All the takes are built on a worker thread, so the game doesn't start any slower; for the
  first moment the original sounds play.

## 0.42.1
Blows that sound different.
- Each blow sounds like what hit what: a blade slashes with a ring of steel, a mace, club or
  hammer lands with a heavy thud, steel on plate or mail clangs, a skeleton clacks, an arrow or
  bolt thunks, and fists, claws and bites slap. A shield parry rings out.
- Every kind has three or four takes, picked at random and played at a slightly random pitch,
  so no two blows in a row sound alike; misses whoosh in a few different ways.
- A blow worth a quarter of the victim's health sounds heavier: lower and louder.

## 0.42.0
An opening fly-by.
- The start screen is see-through now, and behind the title the camera flies over the world:
  the south-west forest, the main town, the dungeon, the eastern wilds, the graveyard and
  Southmoor, then eases down into the usual view of your hero (about 14 seconds). The world
  carries on as it flies. Tap to skip: the camera glides straight down to the hero.

## 0.41.3
- The zone sound effects are heard from grows to 75% of the screen's width and height (was 35%).

## 0.41.2
- Sound effects are heard only from the middle of the screen: a centred box 35% of the
  screen's width and height, round the hero (it was the whole camera view). Music, rain and
  thunder stay global.

## 0.41.1
- Sound effects play only for what's on screen: swings, hits, spells, bows and the rest are
  heard when the camera can see where they happen (it was anything within 12 tiles of the hero,
  on screen or not). Music, rain and thunder stay global.

## 0.41.0
The priesthood.
- Two more priests: Mother Isolde, the abbess of Southmoor, and Brother Anselm at the outpost,
  alongside Father Corwin in the main town.
- Priests look the part: white and coloured robes with a gold ankh, stole and hood trim, a pale
  staff crowned with a gold sunburst, a glowing halo, a soft golden light round them and motes
  drifting up (only animated on screen).
- More they do for free while you stand near: lift curses (Clumsy, Weaken, Feeblemind, Curse...),
  restore mana by prayer (5 a second), and raise the dead: ghosts now walk to the nearest healer
  or priest. Poison is cured as before. Every service sparkles gold.
- Tap a priest for a panel: what they offer, your state (gold, mana, poison, curses, blessing
  time, murder counts), buttons to buy a blessing or confess, or to walk over if you're too far.
  Murderers can now confess by hand (the priest still won't serve them automatically).

## 0.40.0
Better magic.
- Spells grow with skill: damage rises with Magery (up to +50% at 100) on top of Evaluating
  Intellect (+50%), so a grandmaster hits 2.25x as hard as a beginner; healing spells rise with
  Magery (up to +67%). Area spells use the same power.
- Faster casting with skill: up to 25% quicker at Magery 100.
- Disruption by chance: a blow taken while casting used to break every spell. Now the chance
  is 90% for a novice, falling to 10% for a grandmaster; the Protection spell still stops it
  entirely. Your log says when your spell is disrupted.
- You can see magic happen: motes of the spell's colour swirl round a caster while it speaks
  the words, your hero gets a blue casting bar under its health bar, Lightning and Chain
  Lightning strike from the sky as jagged bolts with a flash, other attack spells fly as glowing
  orbs in their colour (Energy Bolt and Mind Blast bigger), and heals, buffs and area spells
  sparkle on whoever they touch.
- The Spells panel explains how Magery, Evaluating Intellect and Protection work.

## 0.39.0
Bows and crossbows.
- Every player now starts with a bow and 40 arrows in the bag (equip it from Bag). Anyone with
  no bow buys one from a merchant when they can afford it, so saved heroes get one too, and
  arrows are restocked 10 at a time as before. Archery trains with every shot.
- Two new ranged weapons: the Composite Bow (a recurve: faster and longer-ranged than the bow)
  and the Heavy Crossbow (slow, but hits hardest), each with its own model. All four are made
  with Carpentry: bow from the start (was 30), crossbow 25 (was 55), composite bow 45, heavy
  crossbow 65.
- Bows and crossbows drop from monsters: orcs and skeletons carry bows, ogres heavy crossbows.
- Monsters that shoot: Orc Archers with crossbows guard the orc fort, and Skeleton Archers
  haunt the graveyard and the dungeon. They keep their distance and fire from range.
- A new player, Fenn, fights with a crossbow.
- The crossbow model now has a string.

## 0.38.0
Gear you can see.
- Each kind of armor has its own look on the model, not just a torso colour:
  - Platemail: a closed helm with an eye slit and a plume in the wearer's colour, pauldrons
    (the right one moves with the sword arm), gorget, chest ridge, tassets, plate gauntlets,
    knee cops, greaves and sabatons.
  - Chainmail: a mail coif round the face, a hauberk skirt and mail leggings.
  - Studded armor: rows of studs on the chest, a shoulder guard, leather leggings, tall boots.
  - Leather armor: a cross strap, bracers, leather leggings and tall boots.
- Each shield has its own shape: the wooden one round with planks and a rim, the bronze one
  round with a boss, the heater shield a pointed knight's shield with a cross in the wearer's
  colour.
- Archers carry a quiver of arrows on the back.
- Gear made from coloured ingots shows its metal (copper, bronze, golden, agapite, verite,
  valorite...) on plate, mail, blades, mace heads and heater shields; exceptional
  (master-made) armor has gold trim and the belt turns gold.

## 0.37.0
A clearer picture.
- Health bars: a small bar over anyone hurt or fighting (and always over your hero), green to
  yellow to red as health drops. Townsfolk don't get one. Names, when shown, sit just above it.
- Rings on the ground: gold under your hero, and a pulsing red ring under whatever it's fighting.
- A light haze in the distance on clear days, tinted like the sky at that time of day (rain,
  storms and fog thicken it as before).
- Filmic tone mapping, so bright fire and sunlit grass don't wash out; on Medium and High
  graphics a soft glow round fire, coals and glowing eyes.

## 0.36.1
- Menus really are solid now. 0.35.1 set the solid look on the window, but a theme there doesn't
  reach controls on a CanvasLayer, so buttons and panels stayed see-through. It now changes
  Godot's default theme, which every button and panel uses.

## 0.36.0
Spread out.
- The map is split into 8 equal regions (4 across, 2 down) and the other players are spread
  over them evenly, 1-2 each: every one starts in its own home region, hunts there, and heads
  back after trips to a town's healer, merchant or bank. Before, 5 of the 13 started round the
  main town and the north-east and south-east had no players at all. The two player killers and
  the two thieves start in different regions.
- Thinner regions get extra monsters so each has as many as the busiest one (rats near the
  start, wolves, orcs, zombies and skeletons further out). Spawn spots are always reachable.
- Player level is now simply the total of all skills, rounded down (at least 1): one skill point
  is one level, so the 700-point skill cap is the top level, 700 (it was the total scaled up to
  1..1000, about 1.4 levels a point).

## 0.35.2
- The label over heads reads "Lvl" instead of "Lv" ("Lvl 12  HP 34/40").

## 0.35.1
Your level and HP, always; solid menus.
- Your hero's level and HP always show over its head ("Lv 12  HP 34/40"), even with names
  hidden; Show names adds the full label as before.
- A Hide stats / Show stats button sits in the upper left, above the stats text (it moved out
  of the corner Menu).
- Buttons and panels are solid now (Godot's default ones are see-through): the corner Menu and
  everything it opens, with a thin gold edge.

## 0.35.0
A cleaner screen.
- One Menu button in the upper right opens all the others, in two columns: Auto, Main Menu
  (what was Menu), Bag, Spells, Retreat, Ride, and new switches: Mute / Unmute (music and sound
  effects together), Show / Hide names, Show / Hide stats (the text in the upper left) and Show /
  Hide map. The minimap stays under the Menu button unless hidden. The switches are saved.
- Names (and health) over heads are hidden by default; Menu > Show names brings them back.
- "Level N!" now shows every 5 levels (5, 10, 15...), not every level, for everyone.
- The idle hologram is gone, and with it its setting.
- Players miss much less at the start: they land at least 85% of melee swings, rising with
  weapon skill to 95% (it was 60%).

## 0.34.2
No thumb stick.
- The on-screen thumb stick is gone; tap or hold on the ground to walk, as before.

## 0.34.1
Harder hitting, faster learning.
- Players hit more often and harder in melee. A new character with no weapon skill landed
  about a quarter of its swings against a seasoned monster (and zero Tactics halved every
  blow). Now players land at least 60% of swings (rising with skill: 85% at 100, or more
  where the classic formula gives more), deal 1.5x melee damage, and bare hands do 2-6
  instead of 1-4. Weapon skill and Tactics now train on every swing, hit or miss.
- Skills rise ten times faster: +1 point (1% of the 100 maximum) on every use, instead of +0.1.
  A skill reaches 100 after 100 uses, and the level follows. The log announces a skill every
  5 points rather than on every use. At the 700-point cap, a skill marked "down" still pays for
  the gain.

## 0.34.0
No more glitch; cast spells yourself.
- The screen glitch effect is gone: no distortion on heavy hits, death, gates, level-ups,
  lightning or the title. The idle hologram stays; its switch is now Settings > Idle hologram.
- Cast spells yourself: a Spells button (under Bag) opens your spellbook, circle by circle,
  with each spell's mana and where it goes (at your foe, on you, all foes around you...).
  Tap one to cast it; harmful spells go at your target or the nearest foe. Spells you can't
  afford right now are greyed out, and the last one you cast is offered first ("Again").
- Cast from the very beginning: circles 1 and 2 now have the classic negative minimum skill
  (-20 and -6), so a new character with no Magery can cast them (half of first-circle casts
  work at first, a sixth of second-circle ones) and Magery grows with every success. Before,
  every spell needed some Magery, which a new character could never get. Your hero also
  restocks reagents from the start.

## 0.33.0
Performance.
- Faster: creatures decide 7-10 times a second instead of every frame (the hero 20 times, so
  taps still feel immediate), with movement, swings and animation still every frame; name labels refresh 5
  times a second and only nearby; town services (healer, merchant, priest) run 4 times a
  second; the minimap's terrain is drawn once into a picture instead of 4,600 squares four
  times a second; the HUD text refreshes 5 times a second.
- Only what the camera sees is rendered: the walls, trees, rocks, water and grass are split
  into 12x12-tile chunks so off-screen chunks aren't drawn (one map-wide batch was always drawn
  whole); creatures outside the camera's view (with a small margin, checked 5 times a second)
  aren't drawn, animated or labelled, and their flames pause; forge, brazier and campfire
  flames only simulate while on screen.
- Your own log now sits in the lower-left corner itself; the thumb stick moved up above it.

## 0.32.0
Mounts.
- Fix: monsters noticed and spellcasters hit targets through walls (the dungeon's Bone King
  and Lich were killing players walking past outside). Now aggro, every spell and area spells
  need line of sight: walls and house walls block it.
- Idle holograms: a player standing idle for 3 seconds turns into a flickering hologram (cyan
  glowing edges, scanlines scrolling up the body, slices jumping sideways like a bad signal),
  and snaps back the moment they move, fight, cast, play or gather. Settings > Glitch effects
  turns it off too. It's an extra layer drawn only while idle.
- Four new mounts, each with its own strength (horses 1.8x and llamas 1.6x stay):
  - Forest Ostard, a big running bird: 2.0x speed. Southern forest (Animal Taming 45), or
    500 gold at the stable.
  - Giant Beetle, armoured and slow (1.4x) but its rider carries twice as many materials.
    South-east hills (Taming 40), or 450 gold at the stable.
  - Swamp Dragon, scaly and low with a spiked back: 1.6x and +3 armour while you ride it.
    The swamp; it bites back (Taming 60).
  - Nightmare, a black horse with red eyes and a burning mane: 2.2x, the fastest. Deep in
    the dungeon, and dangerous (Taming 90).
- A Ride button on screen (under Retreat): gets you on your nearest mount, or off it; it says
  if you have none or it's too far away. Menu > Animals shows your mount's speed, armour and
  carrying bonus, and where to find each kind.

## 0.31.0
Loot, glitch and fire.
- Loot you can see: a corpse's label now lists what's in it ("23 gold, Orc Ear, Longsword +2
  more"). When anyone loots near you, each thing rises out of the corpse as a little 3D icon
  (coin, sword, armour, shield, scroll, potion, ingot, log, pelt, pouch...) with a coloured
  "+..." label, then drifts over to whoever took it. Other players' looting also goes to the
  world log on the right.
- A glitch effect: a short burst of digital distortion over the whole screen (bands of the
  picture jumping sideways, colours pulled apart, a rolling tear line, scanlines and static).
  It plays on a heavy blow (a fifth of your HP or more), when you die, when you teleport,
  recall or step through a moongate, on lightning, at every tenth level, and on the title card.
  Settings > Glitch effects turns it off. It costs nothing while it isn't playing.
- Fire: real flames (glowing particles that brighten where they overlap) instead of plain
  shapes. Fireball flies as a burning ball with a flame trail and bursts on impact;
  Flamestrike is a pillar of fire out of the ground; Explosion is a fiery blast; Meteor Swarm
  rains a meteor onto every foe. Fire Field burns on the ground, campfires and the forge have
  flickering flames, fire elementals throw sparks, and stone braziers burn in all three towns,
  lighting them at night with a gentle flicker. Effects are only drawn near you.

## 0.30.0
Platform.
- Every use of a skill teaches it: +0.1 each time, no more dice (still up to 100 per skill and
  the 700-point total; locks still apply). The level follows, so a hero levels up about every
  seven uses: "Level N!" pops above the head, with a log line every 10 levels.
- Players can attack each other by hand: tap a player (or Menu > Players) and Attack. Outside
  town in Felucca anyone is fair game except your guild and allies; attacking an innocent makes
  you a criminal (and a murderer if they die). Not in town, and not in Trammel except guild wars.
- Players on Auto (and the computer players) no longer trade blows with a monster far stronger
  than they are: they retreat to a healer in a safe town instead. This matters now that
  everyone starts from zero.
- A Retreat button (under Bag): breaks off the fight and heals as you go (potions, bandages,
  Cure and Heal spells, Invisibility / Teleport / a wall if something is right on you), walking
  to the nearest healer in a safe town. Stops by itself once you're healed and cured; press it
  again ("Retreating...") to stop sooner. Nothing pulls you back into a fight on the way.
- See what other players wear: tap a player in the world, or open Menu > Players (everyone,
  nearest first). It shows title, guild, level, HP, standing (innocent, criminal, murderer,
  ghost), how they stand with your guild, distance, and their weapon (damage, speed, skill),
  armour, shield and mount. Bags stay private (that's what Snooping is for). From a tapped
  player you can walk over to them, or attack them if they're fair game.
- No more guards. Instead the towns (main town, the outpost, Southmoor) are safe zones: nobody
  inside a town can be hurt, nobody can attack out of a town, and nobody starts a fight there.
  Monsters still keep out of towns; criminals and murderers may now come in (they are as safe
  as anyone, but healers still turn them away and merchants won't trade with them).
- A Bag button (under Menu): what the hero has equipped (weapon with damage, speed and skill;
  armour; shield; mount), supplies (gold, bank, reagents, bandages, arrows) and every item in
  the bag with its value and tool wear. Equip gear from the bag or take it off; choosing by
  hand turns off auto-equip (a toggle there turns it back on). Saved.
- Every player starts from zero: the hero and all computer players begin a new game with no
  skills (level 1) and no fame or karma, and earn everything by use. Stats, gear, gold and
  the starter kit stay. Under 200 skill points everyone counts as "young", so the player
  killers leave them alone until they grow. (Saved games keep their progress; Settings >
  Reset progress starts a hero over.)
- A new game icon: a blue crystal shard behind a gold-hilted sword in a gold ring.
- An opening title card drawn in code (the name in gold, a subtitle and the version) that fades
  after a few seconds or at a tap; the engine's boot splash is now plain dark to match.
- Menu > Settings > Graphics: Low (no shadows or grass details, 70% render scale, half the
  rain; smoothest on older phones), Medium (the default: shadows, 85%) or High (full resolution
  with smoothed edges). Saved.
- CI: with the signing secrets set, every build also exports a signed release APK. SIGNING.md
  explains it, and what Google Play additionally needs (an App Bundle via a Gradle build).
- (Mesh batching, also on the old roadmap, already came with 0.22-0.24: scenery is one batch per
  kind and figures are a few merged meshes.)

## 0.29.0
Quests and a dungeon boss.
- Captain Marcus's quests are now a chain of 13 of four kinds:
  - kill quests as before;
  - fetch quests: bring 3 wolf pelts, 5 iron ingots or 3 orc ears (they're kept out of sales
    while the quest is on, and handed over at the end);
  - escort quests: Tobin the Trader to Southmoor and Sister Ada to the outpost. The traveller
    appears beside you and follows you; get them within 3 m of the goal;
  - and the last: slay The Bone King.
  Rewards now also give fame and karma. On Auto the hero leads escorts by itself and walks back
  to the captain once a quest is done.
- The Bone King, the dungeon's master, waits in its deepest hall: a towering lich (400 HP,
  armour, every combat spell) who raises two skeletons out of the ground every 25 s while
  he fights; they crumble after a minute. His health shows as a bar in the HUD while you fight
  him. He carries 400-700 gold, the Crown of Bones, and may drop the Bonecleaver (a unique
  sword, 12-24 damage), platemail and high-circle scrolls. He returns after 30 minutes.

## 0.28.0
Weather and music.
- Weather that changes every 3-7 minutes: clear, rain, fog or a storm. Rain falls round you
  (not underground), darkens the day, hisses softly and puts campfires out four times faster;
  fog closes in the view; storms bring heavy rain, lightning flashes and thunder.
- Music, generated in code like the sound effects (no audio files): a gentle tune in town, a
  soft pad with a sparse melody in the wilds, and a low drone with far-off bells in the dungeon.
  It cross-fades as you move between them; each loop is built in the background the first time.
- New sound effects: a sword whooshing past on a miss, a bow twang, thunder and rain.
- Menu > Settings: Music on/off and Weather on/off (off keeps the sky clear). Saved.

## 0.27.0
Controls and mounts.
- An on-screen thumb stick in the lower-left corner: drag to walk in any direction (it follows
  the camera's turn). Like a tap it takes over from Auto for a few seconds, and walking away
  breaks off a fight. The player log moved right to make room. Tapping still works too.
- Mounts: horses (1.8x speed) and llamas (1.6x). Tame a wild one (horses roam the eastern plains,
  a llama the south-east hills; Animal Taming 30 / 35), or buy one from Hal the Stablemaster in
  town (300 / 200 gold from the bank). Ride or get off from Menu > Animals; the rider sits in
  the saddle and the mount's legs do the walking. On Auto, players get back on their mount by
  themselves. You are thrown off if you die. Riding is saved with the game.
- (Quick-cast spell buttons were left out on purpose: spells stay in the menu, with no spell
  buttons on screen.)

## 0.26.0
Thieves (roadmap item 0.17).
- New skills: Hiding, Stealth, Snooping, Stealing, Detecting Hidden.
  - Hiding: vanish while standing still; nobody can target you. Stealth lets you walk a little
    hidden (Stealth / 6 metres); attacking or casting reveals you.
  - Snooping: see what a player next to you carries. Failing gets you caught.
  - Stealing: lift one item from their bag, or some gold (equipped gear can't be stolen).
    A failed theft, or a noticed one, makes you a criminal and the victim turns on you.
  - Detecting Hidden: reveal anyone hiding within 6 m.
  - Not allowed in Trammel, and never against your own guild or allies.
- Two computer thieves, Sly and Pip, hide and sneak up on players outside town, snoop, steal and
  slip away; the guards strike them down if they come into town as criminals.
- Menu > Thievery: Hide, Detect hidden, and Snoop / Steal on the player next to you.

## 0.25.0
Society (roadmap item 0.20; numbered 0.25 so phones see it as an update to 0.24).
- Fame and karma, with the classic title table: "Hero the Notable", "Aldric the Honorable",
  "Vex the Notorious", up to "the Glorious Lord" or "the Dread Lord" at 10000 fame. Monsters
  give fame (and karma, unless just an animal); killing criminals and murderers gives karma; an
  innocent costs 700 karma; guild-war kills give fame only; dying costs a tenth of your fame;
  confessing to the priest and raising ghosts give karma, begging costs a little. Gains slow
  down near the top. The HUD and every name label show the title; Menu > Guild & Fame explains
  it. Computer players start with some fame and karma of their own (the player killers bad).
- Guilds: the Order of the Silver Serpent [OSS] (Aldric, Mira, Gareth), the Wardens of
  Southmoor [WOS] (Dorian, Lyra) and Shadowclan [SHD] (Vex, Morg). OSS and WOS are allies and
  both at war with Shadowclan. Guild tags show on name labels; guildmates and allies show green,
  enemies at war orange. Guilds at war fight anywhere outside town with no criminal flag or
  murder counts; guildmates and allies never fight each other.
- Join a guild (honest guilds want karma 0 or more, Shadowclan -1000 or less), or found your own
  ("Hero's Company" [HER], 1000 gold from the bank), invite guildless players (fame and karma
  make them more likely to say yes), and declare war, make peace, or propose alliances.
- Rulesets (Menu > Settings): Felucca, open player-vs-player as before, or Trammel, where players
  can't hurt each other at all except guilds at war. Saved with the game.

## 0.24.0
Art: procedural low-poly models and textures, all built in code (no downloaded assets).
- Characters: real figures instead of capsules. Players and townsfolk have legs, arms, a head
  with hair and eyes (skin and hair picked per name), and show what they wear and wield: plate,
  chain, studded or leather armour (with a tabard in their colour), the actual weapon (dagger,
  kryss, swords, mace, war hammer, halberd, bow, crossbow) and shield. Guards wear helmets,
  merchants and bankers caps, the priest a hood, healers and mages robes (mages a pointed hat).
- Monsters by kind: rats with long tails, wolves with pointed ears and bushy tails, bears, deer,
  an eight-legged spider with red eyes, orcs with tusks, zombies reaching forward, skeletons
  with ribs, a pot-bellied ogre with a club, an evil mage in red robes, a hooded lich with
  glowing eyes, a horned, winged daemon; earth (rock), air and water (see-through), and fire
  (glowing) elementals, a spinning energy vortex and whirling blade spirits.
- Animation: legs stride when walking (four-legged gait for animals), the weapon arm swings on
  each blow, rises while casting and works while gathering; vortexes and blades spin.
- The world: noise-textured grass, cobbled towns, flagstone dungeon floor, animated water with
  sparkles, two kinds of tree (pines and oaks) each turned, sized and tinted a little
  differently, faceted rocks, banded stone walls (darker in the dungeon), grass tufts and
  flowers, timber-framed houses with a banded chest, and corpses as a sack with bones.
- Built for phones: every figure is 3-5 merged, flat-shaded meshes shared by everything that
  looks the same, and the scenery is one batch per kind.

## 0.23.0
Magic, travel and housing depth.
- New spells:
  - Paralyze (circle 5): the target can't move, swing or cast for 4 s + Magery/25, until a
    blow lands. The AI freezes a melee foe when it is losing, then heals or walks away.
  - Resurrection (circle 8): raises a ghost player close by (not murderers). Casters raise the
    ghosts they come across.
  - Summon Earth Elemental (circle 8): an elemental fights beside you for 90 s, then crumbles.
    Casters call one against tough monsters.
- The full spell list: all 64 classic Magery spells, 8 in each of the 8 circles. New ones:
  - Buffs (on you): Agility, Cunning, Strength, Bless (+10 stats), Polymorph (+20 Str, bigger),
    Protection and Arch Protection (taking damage can't break your spells), Reactive Armor
    (a quarter of each blow comes back), Magic Reflection (the next harmful spell bounces back),
    Invisibility (foes lose you until you attack or cast), Incognito (player killers don't
    recognise you), Night Sight (the night lifts for you).
  - Curses: Clumsy, Weaken, Feeblemind (-10 Dex, Str or Int), Curse, Mass Curse (-10 to all).
  - Mana: Mana Drain and Mana Vampire (keeps what it takes).
  - Damage: Chain Lightning, Meteor Swarm (everything hostile around you).
  - Fields on the ground: Fire Field, Poison Field, Paralyze Field, Magic Trap (bursts on the
    first foe to step on it), Wall of Stone and Energy Field (paths must go round them).
  - Dispels: Magic Untrap, Dispel Field, Dispel (a summoned creature), Mass Dispel.
  - Summons: Blade Spirits, Summon Creature (a wolf or a bear), Energy Vortex, Summon Air,
    Fire and Water Elementals and Summon Daemon (Earth Elemental was added earlier).
  - Utility: Create Food (a loaf of bread heals 10 out of combat), Telekinesis (loot a corpse
    you can't reach), Teleport (blink up to 8 tiles), Magic Lock (seal a corpse so only you
    can loot it), Unlock, Arch Cure (cures you and players around you), Reveal.
  - The AI uses them: buffs before a fight while mana is high, curses on dangerous foes,
    drains on casters, fields under groups, dispels on summoned foes, Invisibility,
    Teleport or a wall to escape, Telekinesis for unreachable corpses, bread when idle.
    Monsters stick to plain combat magic (plus curses and drains).
  - Any known spell can be cast from Menu > Travel & Spellbook; the HUD shows active effects.
- Spellbooks and scrolls: a spell must be in your spellbook to be cast. New characters know
  all of circles 1-4 (mages know everything). Scrolls drop from monsters (12% of gold-carrying
  monsters; tougher ones carry higher circles) and merchants sell circles 1-6 (12 gold per
  circle); a new scroll is copied into the book when picked up or bought, spare ones are
  sold. Menu > Travel & Spellbook lists what you know, circle by circle. Old saves keep
  circles 1-4 plus Mark and Gate Travel.
- Runebook: up to 8 runes. Mark adds a rune where you stand (replacing the selected one when
  the book is full); Recall and Gate Travel use the selected rune; runes can be forgotten.
  Each rune shows where it is (town, the outpost, Southmoor, the dungeon, the wilds).
- Houses in three sizes: small house 3x3 (1500 gold), house 5x5 (3500), large tower 7x7
  (7000). Deeds can be exchanged for another size at the bank (pay or get back the
  difference), and a house can be re-deeded: packed back into a deed with everything inside
  going to the bank.
- Lock-downs: 3, 8 or 15 item kinds locked down in the house. Unlike the chest, they are kept
  when a neglected house collapses (they go to the bank).
- Co-owners: 1, 2 or 3 trusted players (not player killers). Each one adds 3 days before the
  house collapses, and one passing nearby keeps it standing like the owner does.

## 0.22.0
- Weapon skills: Fencing (dagger, kryss), Mace Fighting (mace, war hammer), Archery (bow,
  crossbow) join Swordsmanship. Hit chance and gains use the skill of the weapon in hand, and
  the AI values a weapon by how well it can use it.
- New weapons: short sword, mace, war hammer, bow and crossbow (ranged, 7 m). Bows use one arrow
  a shot; merchants sell arrows (10 for 10 gold). Out of arrows means bare hands.
- Tools: mining needs a pickaxe, lumberjacking a hatchet, smithing and carpentry a tool kit.
  Each lasts about 40 uses, then breaks; merchants sell new ones for 12 gold. Tools are never sold.
- Coloured ore: enough ingots of one metal make a piece of that metal (+4% per tier on damage,
  armor and value). Grandmaster-level crafters sometimes make Exceptional pieces (+20%), which
  carry your maker's mark.
- Arms Lore and Item Identification: selling gear or goods trains them and adds up to 50% to the
  price.
- Tracking: an idle hunter finds monsters beyond sight and heads for them.
- Camping: hurt in the wild with a log, light a campfire and rest (triple regeneration nearby).
- Begging: with under 15 gold, ask townsfolk for coins (each once every 5 minutes).
- Spirit Speak: out of bandages, channel to mend your wounds for 10 mana.
- Arrows and tool wear are saved.
- Balance: natural healing pauses for 6 s after a blow, so monsters no longer heal
  mid-fight (it ate a third of the hero's damage; fights took about 45 s per kill).
- Player level shown above every player's head ("Hero (Lv 157)") and at the start of the HUD's
  HP line ("Level 157").
- Player level 1 to 1000: shown in the HUD (Lv) and the Skills menu. It is derived from your
  total skill (700 = level 1000), so a new hero starts at level 1 and nothing extra is saved.
- Priest: Father Corwin stands by the healer in town. Innocent players near him get poison
  cured for free, can buy a blessing (25 gold: +10% damage dealt, -10% damage taken for
  5 minutes, shown in the HUD) and can confess one murder count away for 50 gold.
- Fix: a crafter whose tool kit broke kept walking back to the forge with nothing it could make
  and stood there for the rest of the game. Forge trips now need something craftable (ore, or
  materials plus a tool kit), a fruitless visit waits 2 minutes, and missing tools are bought
  with only an 8-gold reserve.
- All players now play like the hero: Aldric, Mira, Selene and Vex start with the hero's kit
  (lute, pickaxe, hatchet, tool kit), gather and craft when idle, play bard songs (peace,
  provoke, entice), tame animals, track, buy a lute, and bank their gold in their own account.
  Tracking now works for crafters too (the hero never tracked before).
- A world four times bigger (96x48 tiles, was 52x24). The old map is unchanged in the north-west,
  with new land east and south:
  - Southmoor, a third town (healer Sister Maeve, merchant Hollis, banker Pell, two guards).
  - The eastern wilds with wolf packs, deer, a bear wood, a lake, and a walled orc fort with an ogre.
  - A dense southern forest (spiders, wolves), a swamp with zombies, ore-rich hills.
  - An old walled graveyard in the south-east: skeletons, a zombie and a lich.
  - About 40 more monsters, so roughly twice as many in all.
- Six more players (eleven in all): Gareth and Dorian (warriors), Lyra (mage), Thorne
  (fencer), Brina (a new archer with a bow and arrows) and Morg (a second player killer).
- Players resupply and bank at the nearest merchant and banker, not always the first one.
- The minimap shrinks its tiles to stay 240 px wide, and trees, rocks, walls and water are drawn
  in batches (one draw call per kind) so the bigger map stays fast on phones.
- Fix: a creature raised or respawned at its home kept walking its old route in a straight
  line (through trees and walls) toward where it had been heading.
- Two logs: your own events lower left, everyone else's (deaths, crimes, resurrections) lower right.

## 0.21.0
(0.20, society, comes later.)
- Shops with supply and demand (`scripts/shop.gd`, from the reference): each merchant has a purse
  and shelves. It pays less for what it already holds, refuses an item once it has 15, runs out
  of gold, and every two minutes restocks (purse refilled, shelves sold down).
- Prices differ by town: a new merchant, Mara, in the outpost pays 30% more for goods and
  charges 25% more for supplies, so hauling loot to the outpost pays.
- Menu > Prices: what each merchant pays for everything in your bag right now, their purses and
  supply prices.
- Player vendors: with a house, hire a vendor (100 gold from the bank). Give it your bag; it sells
  at full value (merchants pay half for used gear), keeps 10%, and sells even while you are away
  (about 3 items an hour, up to two days). Collect earnings at the house. A collapsing house
  spills the vendor's goods and earnings into the ruins too. Saved with the game.

## 0.19.0
- Bards: Musicianship, Peacemaking, Provocation and Enticement (new skills), played on a lute.
  The hero starts with one; Bran sells another for 20 gold if it is lost (lutes are never sold).
  - Peacemaking calms every monster around you for 15 s (a blow wakes them).
  - Provocation turns the nearest monster on another one; they fight each other.
  - Enticement lures a monster to walk over to you alone, away from its friends, for 8 s.
  - Each needs a good Musicianship roll first, then a skill roll against the creature's
    toughness; a failed provocation or enticement makes it angry with you.
- Menu > Bard: the three performances with your chances. In Auto the hero provokes when two
  monsters gang up on it, calms them when badly hurt, and lures lone monsters away first.
- Fix from the animals play-tests: taming attempts kept being broken off (the animal wandered
  more than 3.5 m away during the 3 s of coaxing) and the hero went straight back to chasing
  another hind, all hour, instead of gathering and crafting. Animals now hold still while being
  tamed, the leeway is 5 m, and the Auto hero waits 60 s after any attempt (finished, broken off
  or unreachable) before trying again. The report counts
  taming attempts and every bard performance.

## 0.18.0
(0.17, thieves, was skipped for now.)
- Animal Taming, Animal Lore and Veterinary (new skills).
- Wildlife: two hinds (peaceful: players leave them alone unless told to attack), a brown bear
  in the south-east and the wolves are tameable (Animal Taming 10 / 55 / 35 to try; no chance
  more than 10 points below). Taming takes 3 s next to the animal, damage interrupts it, and
  every attempt teaches; a failed attempt angers an aggressive animal.
- Pets (up to 2) follow you, attack what you attack, defend themselves, are healed by healers
  and bandaged with Veterinary; a pet's kills count for its owner's quests. A dead pet is gone
  for good; a tamed animal's lair gets a new wild one after 90 s. Pets are saved with the game.
- Menu > Animals: your pets (release them), Animal Lore on the nearest animal, a Tame button.
  In Auto the hero tames animals by itself and bandages hurt pets.
- HUD and minimap show pets (green dots).

## 0.16.1
- Economy, from the one-hour play-test (24 gold after an hour, never banked, 2 items crafted,
  all 3 deaths to the Evil Mage):
  - Monsters drop more gold (rats 3-8, spiders 5-14, wolves 6-14, orcs 15-35, the evil mage
    25-50, dungeon dwellers more).
  - Restocking keeps a 30-gold reserve and buys only what is short: one heal potion (a cure
    potion only while poisoned), bandages up to 6, reagents up to 20.
  - Crafting trips start with 5 ore, 3 ingots, 3 pelts or 5 logs; banking starts at 120 gold.
  - Spellcasting monsters count as more dangerous, so players stop picking fights with the
    evil mage too early.
- Fixes found by the hour-long play-test: a mage low on reagents walked to the merchant and
  waited there forever when it couldn't afford them (it now only goes if he will sell); and a
  character re-planning a route between two tiles could clip a wall corner (paths now step back
  onto the grid first).
- Poison toned down (40 poisonings in the hour-long play-test): the giant spider moved from
  beside the start to the south-west woods, its poison chance dropped from 35% to 15% a hit,
  players get 10 s of immunity after any cure, and casters use Poison once as an opener per
  target instead of repeatedly.
- Play-test fails if the hero does nothing for 5 game-minutes, and says what it was doing.
- Play-test report adds gold earned and spent, quests handed in, bounties and time in the
  dungeon, and fails if the hero spends at least as much gold as it earns.

## 0.16.0
- Poison: lesser, regular and greater, each draining HP every 2 s until cured or worn off (it can
  kill). A new giant spider (in the woods north of the start) and zombies poison on hit; casters
  gain the Poison spell (circle 3), stronger with more Magery.
- Cures: the Cure spell (circle 2; harder against stronger poison); bandages cure poison once
  Healing and Anatomy are both 60 (from the reference); cure potions.
- Alchemy (new skill): brew Refresh, Cure, Heal and Greater Heal potions from reagents (Menu >
  Craft, no forge needed). Players drink potions when it matters (cure when poisoned, heal below
  40% HP, refresh when worn out), one every 8 s. The merchant sells heal and cure potions;
  potions are never sold off. Auto crafters brew when low and rich in reagents.
- Stamina is now a pool: each swing costs a little and it regenerates, so a tired fighter swings
  slower (the reference's stamina-based swing speed). HUD shows stamina and poison.

## 0.15.1
- Balance, from the play-test reports (the hero died 7 times against 5 kills in one run, mostly
  to the Evil Mage and to Vex):
  - Players in Auto only start fights they can win: monsters have a danger rating (rat 1 ...
    lich 8), compared with the player's power (best weapon or magic skill / 20 + armor / 4).
    They still fight back when attacked.
  - Young players (under 200 skill points) are spared by player killers. The HUD says "young".
  - Players fall back to a healer at 45% HP (was 35%).
- Play-test: seeded so runs are repeatable, reports who killed the hero and what it killed, and
  fails if the hero dies more often than it kills.

## 0.15.0
- Automated play-test in CI: a fresh game plays itself in Auto mode for 15 game-minutes (headless,
  fixed 20 fps). It fails the build if the hero never kills, loots or gains skill, if anyone
  ends up inside a wall or with an invalid position, more HP than its maximum or negative gold,
  or on any script error, and prints a report (kills, loot, crafting, banking, deaths ...).
- Menu > Help explains the controls and rules; a new game shows a few tips in the log.
- ROADMAP.md has a second roadmap for everything else (still no multiplayer).

## 0.14.0
- Sound (`scripts/sfx.gd`): small effects synthesized in code (no audio files) for hits, spells,
  deaths, loot, skill gains and gathering, played near the hero. Toggle in Menu > Settings.
- Day and night: an 8-minute cycle; the sun moves and the sky dims, nights stay readable. The
  HUD shows the time.
- Minimap (`scripts/minimap.gd`) under the Auto and Menu buttons: terrain, towns, dungeon,
  houses, and everyone as coloured dots.
- Camera: pinch with two fingers to zoom, twist them to turn the view (mouse wheel zooms on a
  computer). Menu > Settings > Reset camera. Zoom, angle and sound are saved.
- Animation: characters bob when walking, lunge on each swing, float while casting, tilt while
  chopping or mining, breathe when idle; ghosts drift.

## 0.13.1
- Fix: guards killed the same criminal over and over, flooding the log. A criminal ghost walked
  to the healer in town, was resurrected still flagged (the flag didn't count down while dead),
  was struck down at once and resurrected again, every frame or two. Healers now turn criminal
  ghosts away until the flag wears off (or the shrine raises them outside town), flags keep
  fading while dead, and a guard kill logs one line instead of two.

## 0.13.0
- Bigger world: the map now runs 52 tiles east. An outpost town (guarded, with healer Brother
  Aldo) sits by a walled dungeon of dark halls. Ghosts walk to the nearest healer.
- Dungeon monsters: skeletons, a zombie, an ogre and a lich (a spellcaster with Earthquake),
  with better gold and gear (broadswords, halberds, heater shields, platemail).
- Magery circles 5-8: Mind Blast, Energy Bolt, Explosion, Flamestrike and Earthquake (hits every
  hostile creature around the caster, never innocents). Casters pick them up as Magery grows.
- Travel magic (Menu > Travel): Recall to your rune, Mark it where you stand (not in the
  dungeon), Gate Travel opens a two-way moongate for 20 s that anyone, monsters included, can
  walk through. You start with a rune marked in the town square.
- Quests: Captain Marcus in town gives kill quests (rats up to the lich) with gold rewards;
  stand near him to take one and to hand it in. Progress shows in the HUD and is saved, as is
  your rune.

## 0.12.0
- Bank (`scripts/property.gd`): Oswin the banker in town keeps your gold and items safe from
  death and theft. Menu > Bank & House: deposit or withdraw gold, deposit your bag, take items
  out. Criminals and murderers are refused. In Auto the hero banks gold above 50 on its own.
- Houses: buy a deed for 1500 gold (paid from the bank, like the classic large purchases), then
  place it on open ground outside town. A 3x3 house with a door and a private chest; placement
  never cuts off part of the map or covers anyone.
- Decay: coming within 6 tiles keeps a house standing. Stay away 7 real days and it collapses:
  its chest spills into ruins anyone can loot (Like new ... In danger of collapsing).
- Bank, deed and house (with chest) are saved.

## 0.11.0
- Gathering: rocks (Mining) and trees (Lumberjacking). Tap a rock or tree to work it; each
  gives a few tries, then recovers after a minute. Rarer ore (Dull Copper ... Valorite, the
  classic tiers) turns up only with enough Mining.
- Forge in the smith's house (next to the merchant): smelt ore into ingots (a failed smelt loses
  the ore). Blacksmithy makes weapons, shields and metal armor from ingots; Tailoring makes
  leather and studded armor from wolf pelts; Carpentry makes wooden shields from logs. A failed
  craft wastes half the materials. All five skills rise with use.
- Menu > Craft lists every recipe with materials, required skill and chance, and a Make button.
- In Auto the hero gathers when idle, carries materials to the forge, smelts, crafts upgrades
  (or practises on cheap items) and sells the spares to the merchant. Crafters keep materials.
- Skills and Craft screens scroll so they fit the screen; the HUD bag line is shortened.

## 0.10.1
- Fix: the wolf's lair sat one tile from the guarded town, so it kept wandering in, being struck
  down, respawning and walking back: endless "A guard strikes down Wolf" and wolf corpses piling
  up in town. The lair moved away, and monsters, criminals and murderers now never path into
  town (a second pathfinding grid walls it off for them) and stop chasing prey that reaches it.

## 0.10.0
- Reputation: names are blue (innocent), grey (criminal) or red (murderer; monsters are always
  red) and the label colour follows. Hitting an innocent player makes you a criminal for a
  minute; if they die within 30 s of your hit you are guilty of murder, even without the killing
  blow. Five murder counts make you a murderer; counts fade over time.
- Guarded town (the tan area with the house): no player-versus-player, and guards instantly kill
  monsters, criminals and murderers that enter. Murderers and criminals cannot trade or be
  healed by the healer.
- Outside town is open wilderness. A player killer, Vex, hunts innocents there; ordinary
  players fight criminals and murderers on sight and collect a bounty (25 gold per count) from
  a murderer they kill. Corpses of criminals and murderers can be looted by anyone.
- Death: players become ghosts and walk to the healer for a free resurrection. A murderer is
  refused and raised at a shrine after 30 s with -20% to stats and skills; anyone the healer
  has not reached within 60 s is raised at a shrine with -10% skills.
- HUD shows your reputation. Murder counts are saved.

## 0.9.0
- Stats rise with use: each skill is tied to Strength, Dexterity or Intelligence and slowly raises
  it (max 100 each, 225 total). At the stat cap, raising one lowers another.
- Skills screen (Menu > Skills): all skills with values and Up / Down / Locked arrows. At the
  700-point cap a gain is paid for by a skill marked Down; with none, the gain is refused.
- Healing and Anatomy: players bandage themselves when hurt and nothing is close. Bandages take
  a few seconds, are interrupted by damage and are sold by the merchant. Healing and Anatomy
  rise with use.
- Parrying and shields (wooden, bronze, heater): a chance to block most of a melee hit. Two-handed
  weapons (halberd) cannot be used with a shield; metal shields also spoil Meditation.
- Log messages when a skill or stat rises. HUD shows stats and bandages.
- Save files remember skill locks, bandages and shield.

## 0.8.0
- Save and load (`scripts/save_game.gd`): skills, stats, gold, reagents, bag and equipment persist
  between sessions. Autosaves every 20 s, when you open the menu, and when the app is closed or
  sent to the background. The world and other characters start fresh.
- Menu button: pauses the game; Resume, Save now, Reset progress (asks twice).
- CI can sign with a fixed key from repository secrets (see `SIGNING.md`), so builds update in
  place. Without the secrets it falls back to a throwaway key as before.
- `ROADMAP.md` lists the planned versions.

## 0.7.0
- Equipment (`scripts/gear.gd`): five weapons (dagger, kryss, longsword, broadsword, halberd)
  and four armors (leather, studded, chainmail, platemail) with speed/damage/rating and Strength
  requirements. Weapon speed feeds the swing timer; armor rating soaks damage.
- Gear drops from monsters; characters equip whatever beats what they wear, if Strength allows.
  Mages avoid metal armor, which also removes Meditation's benefit.
- The merchant buys spare gear at half price and sells upgrades.
- HUD shows weapon and armor. Everyone starts with their own kit.

## 0.6.3
- Event log is pinned to the lower-left corner with container layout (more reliable than anchors).

## 0.6.2
- Event log has no background panel; text uses a thick black outline instead.

## 0.6.1
- Event log moved into a dark translucent panel with larger text.

## 0.6.0
- Looting: dead monsters and players leave a corpse (`scripts/corpse.gd`) with gold, reagents and
  trophy items (`scripts/items.gd`); monster loot tables live in `scripts/bestiary.gd`.
- Players loot monster corpses (and their own) automatically when nothing hostile is near; tap a
  corpse to loot it yourself. Other players' corpses are off limits.
- Dying drops all your gold and trophies and half your reagents into your corpse (it lasts
  120 s, monsters' 60 s), so you can go back for it.
- The merchant now buys trophies and sells reagents for gold; mages restock only if they can pay.
- HUD shows gold and your bag. Version bumped to 0.6.0.
- Removed the on-screen spell buttons (spells are cast automatically).

## 0.5.0
- Magery: six spells (Magic Arrow, Heal, Harm, Fireball, Lightning, Greater Heal) with mana,
  minimum skill and reagent costs from the reference (`scripts/spells.gd`). Spoken words of power,
  cast time, fizzle on taking damage, cast chance rising with Magery.
- Evaluating Intellect raises spell damage; Resisting Spells can halve it; Meditation speeds up
  mana regeneration (resting doubles it). All rise with use.
- Casters (AI mage Selene, the Evil Mage) keep their distance, heal when
  hurt and fall back to melee when out of mana. Merchant Bran restocks reagents.
- The hero now starts as a battle mage: Swordsmanship 50, Tactics 30, Magery 30.

## 0.4.0
- Population: the hero, two computer-played players, two NPCs (healer, merchant) and
  monsters (rats, wolf, orcs), all built on one `Entity` class (`scripts/entity.gd`).
- Combat uses the reference formulas: hit chance, swing speed, Tactics/Strength/Anatomy damage,
  armor soak. Tap a monster to attack it.
- Skills rise by use; dying resurrects at spawn with -10% skills (never below starting values).
- Monsters aggro on players, chase, give up past their leash and respawn. Hurt players retreat to
  the healer, who heals everyone nearby. Stat blocks live in `scripts/bestiary.gd`.
- HUD shows skills; on-screen event log; floating damage numbers.

## 0.3.0
- Character acts on its own: idles, then wanders to random reachable tiles nearby.
  Tapping takes over for a few seconds; an on-screen button toggles Auto mode.

## 0.2.0
- Now 3D: tile map built from 3D meshes (ground, walls, water, trees), third-person camera,
  tap/drag on the ground picks a tile, A* routes around obstacles.

## 0.1.0
- Godot 4.3 project, Android debug export via GitHub Actions.
- Stats/skills model and classic UO combat formulas (`Rules`, `Hero`).
- ASCII tile map with collisions and A* tap-to-move.
