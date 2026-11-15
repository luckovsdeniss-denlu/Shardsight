# Changelog

Version lives in `project.godot` (`application/config/version`). Bump it there; CI stamps it
into the Android `version/name` and derives `version/code` from it (major*10000 + minor*100 + patch).

## 0.97.3
- Recording the trailer video now deletes the last video (its release and tag) before publishing
  the new one, so only the latest trailer is ever there.

## 0.97.2
- The hero never leaves the frame in the trailer: the camera follows the hero, looking between
  the scene's centre and the hero (its circling and crane moves go with it), and if the hero ever
  slips out of view it swings round to them at once.

## 0.97.1
- Smoother, more fluid movement in the trailer: characters cut the corners of their paths and go
  straight to the furthest point they can walk to directly (no zig-zag from tile to tile), ease
  off as they arrive instead of stopping dead, and the hero moves a quarter faster.

## 0.97.0
- A "Download trailer" button on the start screen opens the trailer's video (an MP4 with its
  music) in the browser, to save or share.
- A new GitHub workflow, "Record trailer video", records the trailer as that video: Godot's
  Movie Maker draws every frame at 30 a second with all the looks on and no frame counter, then
  it's cut to the trailer (its opening included) and published to the "trailer" release, always at
  the same link. Started by hand, like the APK build.

## 0.96.0
The trailer's hero fights with style:
- Sword combos: each blow is the next step of a four-step combo, each with its own move - a
  slash with a quick side-step round the foe (left and right in turn), a spin slash, a leaping
  strike, and a whirlwind finisher with a camera punch-in and a burst of sparks. The move's name
  bursts over the foe that takes it ("SLASH!", "SPIN SLASH!", "LEAP STRIKE!", "WHIRLWIND FINISH!").
- Casting flourishes: as each spell begins the hero moves with it, in turn - rising into the air
  and held there while the words are spoken, a twirl, or a hop - with a sparkle of light.

## 0.95.9
- Fix: the trailer's epic score never actually played. During the loading-screen opening the
  game's own music took over and kept playing through the whole trailer. Now the trailer's score
  (the heroic climb, choir, doubled brass, drums and bells) plays from the first frame to the end.

## 0.95.8
- No sentences over the hero's head in the trailer: the hero's lines are gone from every scene;
  the townsfolk and the foes still speak theirs.

## 0.95.7
- The trailer's hero fights with blade and magic in balance: a spell about every 2.8 seconds, and
  in between the hero closes in and strikes with the sword (before, the hero stood back and cast
  almost nonstop). The Magic scene keeps its quicker spells.

## 0.95.6
- In the trailer the hero's spells can't be broken: a blow no longer interrupts the hero's casting.

## 0.95.5
- Trailer church scene: the camera pulls back and up, so the whole church is in the shot.

## 0.95.4
- Trailer boat scene: the hero turns 180 degrees, smoothly, to face the way the boat is going.

## 0.95.3
- More epic trailer music: the brass theme is doubled by a second horn an octave below for a
  fuller, bigger sound, and the trailer's score sits 2 dB louder.

## 0.95.2
- In the trailer the hero no longer turns its back on the monsters while running from them: it
  keeps facing the foe as it backs away and casts.

## 0.95.1
- The trailer's foes no longer fall from the sky into each fight: they're already on the ground
  and step in with a small bounce.

## 0.95.0
- The trailer has an epic score throughout: a heroic minor climb of chords that swells upward and
  resolves, a choir under the chords, brass calling out the theme more often, drums driving every
  beat with a fill at each phrase's end, and bells ringing over the top.

## 0.94.4
- No sound for the trailer's 3D words appearing or fading: the swell as a word comes in, the hit
  as it lands and the fly-by as it leaves are all silent now (the music and the big brass cuts stay).

## 0.94.3
- No more strange flashes in the trailer: spells landing no longer flash the screen white (the
  slow-motion moment stays), no scene cuts in through white any more (every cut is a dip to
  black), and the frame-rate keeper leaves the picture alone during the trailer (no glow, shadows
  or resolution switching mid-scene).

## 0.94.2
- Night and day change smoothly: dawn and dusk glide in and out on an eased curve, every change
  of light is eased (no steps), the sky updates in small, frequent steps too small to see instead
  of a jump every few seconds, and rain or a storm darkens the land and greys the sky gradually as
  the clouds gather (and lifts as slowly when it clears). The trailer still cuts at once.

## 0.94.1
- No sound effects from the characters any more - the hero's, the other players', the
  townsfolk's or the monsters': no blows, swings, parries, bows, spells, deaths, roars and
  hisses, no footsteps or heartbeat, no chopping, mining, fishing, rowing, drinking or coins.
  The music, the ambience (wind, water, birds, crickets, the tavern), the button clicks, the
  church bell, thunder, the arena crowd, the jingles for a level, quest or achievement, and the
  trailer's own sounds all stay.

## 0.94.0
- Every trailer scene tells a little story in floating lines over the characters: Elara the healer
  ("Back again? Try not to die this time." - "No promises."), the orcs ("Fresh meat!" - "Not
  today." - "...ow."), the ogre ("ME SMASH TINY HUMAN!"), the yeti, the scorpions, a quiet day on
  the lake ("...said no adventurer, ever."), Rosa at the bar with a rumour, Valka in the arena,
  the zombies ("Braaaains..." - "You'll be disappointed."), the storm, Tharok the World-Eater, and
  the hero wondering where to begin. The hero's lines rise in blue, the foes' in red, the
  townsfolk's in gold.

## 0.93.0
The trailer tells more of the stories and quests:
- "Quests": the hero takes a job from Captain Marcus in town ("Orcs on the north road!" -
  "I'll see to it." - "Four of them. Bring me proof.").
- "Bounties": a fight with a named beast, Grimfang the Wolf, bigger and tougher than the rest.
- "Help the townsfolk": Warden Sela of Highmoor asks for help with the bears on the southern roads.
- "The Shattered Sight" (in the church): Father Corwin and the hero speak of the memory that was
  taken - the main story.
- The lines rise over the speakers' heads in turn, gold for them and blue for the hero, and each
  scene has its own flying 3D words. The trailer now has 18 scenes.

## 0.92.0
- The trailer opens with the loading screen's animation: the spinning Shard in its rings over the
  glowing hexagons, the bar filling as the lines type out ("Waking the shard", "Raising the land",
  "Calling the heroes", "Rolling the trailer"), its score already playing - then it fades into the
  first scene. Skip works during it too.

## 0.91.9
- New sounds for the trailer's words coming and going: as a word flies in, a reverse-cymbal
  swell with a tone sweeping up (and a shimmer of fifths) that rises right into its landing hit;
  as it leaves, a jet-like fly-by - a hum falling in pitch as it passes, air swelling and fading,
  and a trail of tinkling sparks.

## 0.91.8
- A new sound as each 3D word lands in the trailer, instead of the plain shimmer: the gold words
  hit with a deep boom under a ringing struck-steel "shing", a burst of air and a falling sparkle;
  the ice-blue words with a cracking crystal chime that shivers, over a soft low thud.

## 0.91.7
- No looting in the trailer: at the end (after the world boss falls) the hero no longer walks off
  to open the treasure chest, and nobody stops to loot bodies anywhere in the trailer.

## 0.91.6
- Trailer scene 13 (Seasons and storms) has no flashes: it no longer cuts in through white, and
  the storm's lightning doesn't flash the screen during the trailer (the thunder still rolls).

## 0.91.5
- Trailer scene 11 (Ravenhollow): the camera films from higher up, circling over the graveyard's
  walls, so the fighters are in plain view (it had been a low tracking shot behind the walls).

## 0.91.4
- Trailer scene 6 (the Frostmarch): the camera keeps away from the piers and their flag, filming
  the fight from the north over the open snow.

## 0.91.3
- No running in the boat: while the boat glides, the hero sits still in it instead of playing the
  running steps (in the game and the trailer), and in the trailer's boat scene the hero just rides.

## 0.91.2
- In the trailer the hero runs from the monsters before casting: when one is close enough to
  strike, the hero dashes out of reach (round walls and water), then turns and casts. If they
  keep catching up, after two dashes the hero stands and casts anyway.

## 0.91.1
- The trailer starts without a flash: from its first frame it's black, and the opening shot rises
  gently out of the dark (no blink, no light leak, no white flash at the start).

## 0.91.0
The trailer: more camera, more animation.
- Every scene has its own camera move, in turn: a slow orbit, a crane that starts low among the
  fighters and rises up and over, a low tracking shot following the hero, a spiral closing in,
  and a dolly zoom (pulling back as the lens closes in). A hand-held drift, a gentle dutch tilt,
  and the camera punches in for an instant on a heavy blow or a K.O.
- Foes drop into each fight from the sky and land with a squash; after a K.O. the hero twirls and
  hops with a sparkle; the cartoon hops on every blow now really show.

## 0.90.3
- The trailer follows the loading screen: its 3D name, at the start and on the closing card, sits
  high on the screen (about a third of the way down) with the words below it; the closing card's
  sparks rise from just under the name.

## 0.90.2
- Loading screen: the Shard, its rings and the name sit higher on the screen (the circle's middle
  at about a third of the height), with the loading bar below them; the glowing ring still lies
  right on the gold ring.

## 0.90.1
- Casters step back before they cast: when a foe close enough to land a blow is coming for them
  (a blow can break a spell), mages - your hero on Auto, the other players and the monsters that
  cast - first step out of reach, then cast. Archers keep stepping back as before. (Not under
  Protection, which keeps a spell from being broken.)

## 0.90.0
The trailer: every combat label, and a cartoon touch.
- Over heads in the trailer, the fight shows in full - the hero's too: damage numbers, spell
  words, health bars, and the hero's casting bar under the health bar. (In the game itself
  nothing shows over your hero, as before.)
- Cartoon action: a body squashes and springs back with a hop at every blow (more for a heavy
  one), comic words burst over the struck ("BONK!", "POW!", "WHAM!", "KAPOW!", "SPLAT!" ...),
  and a slain foe is sent tumbling up into the air and away with a "YEET!" or "K.O.!", a burst
  of sparkles and a twinkle as it goes.

## 0.89.1
- Fix: the trailer's flying words were cut off at the edges of their little frame as they swooped
  in and rushed past. Each word now flies in a frame as big as the whole screen, so its flight is
  never clipped; the letters keep the same size and still hang a little above the middle.

## 0.89.0
More music and sound.
- Six new pieces of music: the swamp (murky and low: the Blackwater Fen and the Reedmarsh), the
  ash (ominous brass and embers: the Ashlands and the Cinderfields), the tavern (a quick jig in
  the Drunken Shard), the arena (a fanfare over drums while a bout or duel is on), the caves
  (sparse, cold, distant bells) and the sea (a gentle rocking lute and flute out in a boat).
- New sounds for the big moments: a rising chime when your hero gains a level, a swelling brass
  chord for an achievement, two bright chords when a quest is done, a deep bronze bell from the
  church at morning, noon and evening, a ghostly wail when the dead rise at night, and a great
  brass blast when a world boss wakes.

## 0.88.5
- "Reset all graphics settings to default" now resets everything about how the game looks, not
  only the performance settings: Auto-optimize on, every look on, the starting resolution, the
  frame counter shown, the camera back above the hero (not first person), names over heads off,
  corpse names, the magic line, the minimap, the stats and the weather on.

## 0.88.4
- The hero no longer casts Night Sight by itself at night (in the game or the trailer); it's still
  in the spellbook to cast by hand.

## 0.88.3
- A tap on the free space round a menu goes back one level at a time: from a page to the page
  before it, from a panel opened in the Main Menu back to the Main Menu, and a tap there closes
  the menu. (Before, one tap could close everything at once.) The X button steps back the same way.

## 0.88.2
- The 3D name is bigger, on the title and in the trailer (about half as large again); while the
  title shows, the corner buttons and the minimap step aside so it has the screen to itself.
- The loading screen's circle sits in the exact centre of the screen, and its glowing ring now
  lies right on the gold ring round the Shard (before, the two were off from each other).

## 0.88.1
- The trailer's flying words have their own sounds, in step with each flight: a swoop as the
  word comes in from afar (rushing air and a falling whistle), a glittering bell-like shimmer as
  it hangs in the light, and a rush past the ear as it flies by (the ice-blue words a little higher).

## 0.88.0
- The trailer explains itself in big flying 3D words: one or two short lines a scene ("MASTER THE
  BLADE", "67 SPELLS", "SAIL THE LAKES", "CHALLENGE CHAMPIONS", "YOUR LEGEND BEGINS NOW" ...), in
  the same lit 3D letters as the title, gold and ice-blue in turn. Each swoops in from the distance
  spinning to face you, hangs a moment with the light sweeping over it, then rushes past the camera.

## 0.87.0
The trailer: music all the way, and more action.
- Its score is written while the game loads (no silent start), plays even with music switched
  off in the game, and sits a little louder; after the trailer your own music setting returns.
- Every fight has one more foe (a named champion still fights alone), and they rush in from all sides.
- The hero casts in every fight scene, and more often (a spell every 1.1 seconds).
- When the foes fall with time to spare, a new wave charges in with a burst of light.

## 0.86.1
- Characters no longer push each other: whoever is walking steps round whoever stands still
  (two walkers each give way half); someone standing - fighting, casting, talking - stays put.

## 0.86.0
Nobody sees through walls or through each other:
- Characters and monsters only notice someone they can actually see: no wall between, and no
  other body standing in the way.
- Archers and casters step round whoever blocks their line before they shoot or cast; a spell
  can't be aimed through someone else ("You can't see that from here.").
- The wall check is tighter: sight no longer slips through the gap where two wall corners meet
  on a diagonal.

## 0.85.2
- The hero no longer casts Night Sight during the trailer (its night scenes stay dark).

## 0.85.1
- The Movie button on the start screen is now called Trailer.

## 0.85.0
- A Fly-by button on the start screen (beside Play, Tutorial and Movie) plays the opening flight
  over the land again, with all its effects and the 3D title; the mode buttons come back when the
  camera is down.

## 0.84.3
- The Performance panel shows the current settings in a line (Auto-optimize, each look, the
  resolution, the frame counter), and "Keep current settings" keeps them for every later start.
  "Reset all graphics settings" forgets what was kept.

## 0.84.2
- "Reset all graphics settings" in the Performance panel: Auto-optimize back on, every look on,
  the starting resolution, the frame counter shown, and the frame-rate keeper starts learning afresh.

## 0.84.1
- The Performance button sits right beside the Menu button in the upper right (always shown, not
  inside the menu any more).

## 0.84.0
- A Performance button in the corner menu opens the game's optimisation settings:
  - Auto-optimize (on by default): the game holds 60 frames a second by itself, lowering the
    resolution and turning looks off when it must and bringing them back when it can.
  - With it off, you choose: glow, vignette and smooth edges; sun shadows; grass and flowers;
    butterflies and falling leaves; the far view; and the 3D resolution (50% to 100%).
  - Show or hide the frame counter.
  - A live line shows the frames a second, the resolution and how many looks Auto has turned off.

## 0.83.1
- The main town moves 8 tiles to the right (east), away from the corner: its keep and walls, the
  forge, Elara, Hal, Bran, Oswin, Captain Marcus, the bounty board, the braziers, the townsfolk's
  homes, the starting Recall rune and its roads all with it. The movie and the fly-by follow.

## 0.83.0
The dungeon and the outpost move apart, and away from the town:
- The dungeon now stands on the western shore of the great lake, about 64 tiles south of the
  town - its halls, its dead, the Bone King, the stairs to the depths and its road all with it.
- The outpost (Mara, Brother Aldo, Brother Anselm, its bounty board and braziers) moves far out
  east, between Dawnport and Midmark.
- The tips, the quest text, the fly-by and the movie follow them. (Reedwick's healer is now
  Brother Osk, so there's only one Brother Aldo.)

## 0.82.1
- The build no longer runs any tests: no smoke test, no movie test, no Auto play-test. It exports
  the APK and publishes it to Releases straight away (a quicker build).

## 0.82.0
The great buildings spread over the whole land (they were all in the north):
- Ravenhollow Cemetery moves to the far south, below Highmoor - walls, graves, the Tomb of the
  Old Kings, its dead and its skeleton bounty all with it.
- The church moves to the far south-west, below the Reedmarsh, with Father Corwin (the story,
  the church page and the tips point there).
- The arena moves to the middle of the land, just south of Midmark, with Kael the Arena Master
  and the horse-race course round it.
- Roads lead to all three; the movie films each in its new place. The dungeon, the tavern and the
  northern towns stay where they were.

## 0.81.1
- Fix: the "A" in the 3D title was missing its front (only a sliver showed); every letter is whole now.

## 0.81.0
- The church has moved out of town: it now stands east, past the dungeon, at the edge of the
  Frostmarch (about 34 tiles from the starting town), with a road to its door. Father Corwin went
  with it; the story, the church page, the movie and the tips all point there.
- Hunter Bram's camp and a few wolves moved over to make room.

## 0.80.3
- The wall in front of the church on the left (north-west of its door) is gone too.

## 0.80.2
- The movie's Skip button sits in the top-right corner, just inside the screen's safe area (clear
  of a rounded corner or a camera cut-out).

## 0.80.1
- The movie shows nothing to tap or point at: no ring under the hero, no red ring round the
  target, no walk-to marker, no selection ring and no loot labels over the bodies. (Skip stays.)

## 0.80.0
The name in 3D.
- SHARDSIGHT on the title screen, at the start of the movie and on its closing card is now real
  3D lettering: raised, polished gold with deep sides, lit warm from above with a cool rim behind,
  a bright light sweeping across it, a soft gold glow, sparks rising round it and a slow sway that
  shows the depth. It grows and fades in, and fades out at the cut.

## 0.79.0
- After the movie (or Skip) the game no longer reloads: everything the movie changed is put back
  as it was (the hero's skills, spells, gear, gold, bag and place, the time of day, the weather,
  the records), the interface returns and the title's mode buttons appear again at once.
- Skip goes straight back (a quick dip to black); the full ending keeps its logo.
- Fix: a script error when a blow's after-effects ended the fight mid-swing.

## 0.78.0
Nothing over your hero's head, and your hero keeps their own shape - in the game and the movie.
- No name, level or health bar over the hero, no casting bar, no damage numbers, spell words or
  "+gold" (the corner shows your health; the log says what happened). Over everyone else, names,
  bars and damage still show.
- The hero never takes a fighting form by itself (polymorph, beast, lich or wraith): Auto keeps
  them as they are. (You can still cast those spells yourself from the spellbook.)

## 0.77.5
- In the movie's church scene the hero stays inside the church, standing still (no wandering out
  after a monster or loot).

## 0.77.4
- The movie's Skip button moves further in from the right edge (170 px), so it reads in full.

## 0.77.3
- The graves beside the church are gone (Ravenhollow Cemetery keeps all of its own).

## 0.77.2
- The old walls beside the church are gone: the one along its east side and the one just south
  of it. The church stands in the open, reachable from every side.

## 0.77.1
The movie's speed-ups, in the game itself:
- Creatures more than 48 m from the camera aren't drawn or animated.
- Off screen and more than 50 m from you, creatures think every eighth frame (every fourth nearer).
- The camera sees 170 m (across the whole land), not 4 km; the sun's shadows reach 28 m.
- On phones the 3D starts at 80% resolution.
- The vignette overlay is the first thing to go (with the glow) when 60 can't be held.

## 0.77.0
Half the monsters, and a town in every part of the land.
- Monsters halved: of every kind the land has more than one of, half are gone (about 118 in all,
  was about 226). The one-of-a-kind ones (chiefs, bosses, the Lich) and the beasts you can ride
  all stay. 3 dead rise at night (were 6).
- Four new towns, each with a healer, a merchant, a banker and a bounty board: Westford in the
  west, Reedwick by the Reedmarsh, Midmark in the middle of the land and Stormhold in the east.
  There are nine towns now, spread over the whole map.
- Roads join the new towns to their neighbours, the towers and the caves.

## 0.76.3
The movie, calmer:
- No camera shake when a spell lands (the flash and the slow motion stay).
- No hit sounds: the cuts and the spells landing no longer thump (the low swell on the big cuts stays).
- No shape-changing at all: a transformation spell cast during the movie simply does nothing.
- Nothing over the hero's head: no name, no spell words, no damage numbers (those over the
  monsters still show).

## 0.76.2
- The music comes forward: every sound effect is 9 dB quieter (about a third as loud), and the
  ambience (wind, water, crickets, rain, the tavern) 5 dB quieter. The movie too.

## 0.76.1
- No polymorph in the movie: nobody changes shape (polymorph, beast, lich or wraith form) while it plays.

## 0.76.0
Only what the phone can draw at 60 frames a second.
- When 60 can't be held, the frame-rate keeper first lowers the 3D resolution to 75%, then turns
  the looks off one at a time: 1 the glow and edge smoothing, 2 the sun's shadows, 3 the grass and
  flowers, 4 the butterflies and leaves, 5 the far distance (the camera sees 70 m); only then does
  the resolution go lower, down to half.
- With frames to spare it brings them back in the reverse order, a step every eight smooth seconds;
  anything whose return brings the stutter back stays off.
- The frame counter shows how many steps are off (e.g. "58 FPS · 75% · -2").

## 0.75.1
- A frame counter at the top middle of the screen, over everything (the title and the movie too):
  frames a second and the 3D resolution in use; green at 55 and over, yellow from 40, red below.

## 0.75.0
The south and the east filled in: the whole map has places worth going to.
- Four new wild regions, each with its own look, name and creatures:
  the Whitepeaks (snow, far east: frost wolves, a yeti), the Dunes of Kesh (desert, south-east:
  scorpions, mummies), the Reedmarsh (swamp round the south-western lake: leeches, a bog troll) and
  the Cinderfields (ash, far south: ash hounds, a cinder imp).
- Three new caves, each with a chief: Icejaw Grotto in the Whitepeaks, the Tomb of Kesh in the
  Dunes (the Dune Pharaoh), and Bonedeep Hollow in the middle south (the Bone Warden).
- New roads to the southern and eastern towers, Reedmere, the new caves, and between Dawnport and Highmoor.
- New townsfolk: Bryn the Fisher (Mirrormere, home in Dawnport), Ada the Shepherd (by Highmoor),
  and Old Cole the Hermit out on the southern plain.
- The map's place names now include the caves and wild regions; Auto explores the new ones too.

## 0.74.0
- The movie opens on the land alone: no hero in the first shot.
- The movie's Skip button sits in the middle of the top bar, well in from the corner, and stays
  on top of everything (it no longer vanishes in the dips to black).
- Fewer monsters: the regions that had none get 3 each (were topped up to 6), about 140 in the
  whole land instead of about 220; 6 dead rise at night (were 8).

## 0.73.3
- Fix: the movie froze on its first scene. On a fresh game the story's first chapter opened
  half a second in and paused everything, and with the movie's interface hidden it couldn't be
  seen or closed. The story now waits for the real game, and nothing can pause the movie.
- Fix: a crash when the game reloaded or quit while a piece of music was still being written.
- Fix: a script error when a blow killed its target and the target was cleared mid-swing.
- The build now also plays the whole movie headless and fails if it stops early or errors.

## 0.73.2
- No health bars in the movie (names, damage numbers, spell words and loot still show).

## 0.73.1
- The movie keeps the words over heads: names, health bars, damage numbers, spell words and loot
  (the buttons, log, stats and menus stay hidden).

## 0.73.0
The movie at 60 frames a second.
- Off camera, the world holds still while the movie plays (only what's filmed lives and moves).
- Creatures more than 48 m from the camera aren't drawn or animated in the movie (in the low, wide
  shots they were specks, but each one cost as much as the hero).
- The camera sees out to 130 m, not 4 km; the sun's shadows reach 28 m.
- The three widest shots come in a little lower and closer.
- The game's own vignette overlay steps aside (the movie has its own), and the film grain is cheaper.
- On phones the movie starts at 80% resolution, and the frame-rate keeper takes it from there.
- Rain: the lighter amount of 0.72.0 now holds after the weather changes too.

## 0.72.1
- The movie plays clean: no buttons, menus, log or stats on screen, and no names, health bars,
  damage numbers or loot words over anyone's head.

## 0.72.0
Smooth at 60 frames a second.
- The colour grade no longer copies the whole screen every frame: the colour is graded by the
  scene itself, and the vignette is a light overlay.
- The sun's shadows take one pass instead of two (out to 32 m).
- The glow uses one small pass instead of two.
- On phones the 3D draws at 85% of the screen's resolution, and the frame-rate keeper reacts
  every second (not every two) and lowers it sooner when frames drop.
- Creatures off screen think a quarter as often, and bodies are only pushed apart where you can see them.
- Up to 6 monsters a region (was 7) and 8 night dead (was 12).
- Lighter particles: spell and hit effects, rain and snow use about a third fewer.

## 0.71.0
The whole land is alive, not just the north-west.
- Monsters in every one of the 36 regions, about the same number in each; the far east and the
  south get their own, tougher mix (bears, spiders, ogres, evil mages, orc archers and more).
- Ten more adventurers (Rowan, Isla, Brom, Kestrel, Hale, Nyx, Garrick, Elda, Torin, Faye), and all
  of them now spread out over the whole map instead of crowding the first regions; several join the guilds.
- Three new guild towers in the south and east: Southwatch, Eastmarch and Farhold.
- A pair of landings on Reedmere, the lake of the south-west.
- Bounties for the southern and eastern wilds.
- Warden Sela at Highmoor has a quest: The Southern Wilds.
- Twice as many dead rise at night, scattered across the land.

## 0.70.1
- Fix: the game wouldn't start in 0.68.1-0.70.0 (a type the movie's title animation left unclear).

## 0.70.0
One look, at 60 frames a second.
- The Graphics setting is gone: everything is always on, at its best - shadows in two cascades,
  grass and flowers, fine ground, the glow, the colour grade, smooth edges, full resolution.
- What High costs is kept down where it doesn't show: edges smoothed by FXAA instead of MSAA (a
  fraction of the cost on phones), the glow on two levels only, shadows to 40 m on a 2048 map
  that fade out at their edge.
- The frame-rate keeper no longer turns anything off. If a phone can't hold 60, it only lowers the
  3D resolution a little, a step at a time, and raises it again when it can; buttons and text
  always stay sharp.

## 0.69.1
The Movie gets a soundtrack.
- Its own score, written for it: driving drums and bass, brass and a choir (the game's other
  music waits while it plays; the ambience steps back).
- Trailer sound: every cut lands on a hit - a deep impact, or a huge brass "braam" on the big
  scenes - and a riser sweeps up into each cut.
- When a spell lands in slow motion, the sound slows too: the world goes dull and far away, the
  music drops in pitch, a heavy impact - then it all snaps back.
- At the end a last braam under the logo, and the score fades away.

## 0.69.0
Sound and music.
- The mix: music, sound effects and ambience each on their own bus - music in a wide hall with a
  touch of chorus, effects with a room's reverb - and a compressor holding it all together, so a
  big fight never clips.
- Where you stand changes how it sounds: a long echo in the dungeon and the caves, a hall in the
  church, a little room in town, open air in the wilds. As a ghost the world goes muffled; near
  death too, and your heart pounds.
- Sounds fade with distance from your hero.
- New effects: fire spells roar, lightning and energy crack, healing and blessings chime, the
  great blasts (explosion, meteors, earthquake, flamestrike) boom; a fanfare when you level up;
  coins when gold comes your way; a soft click under every button; a gulp when you drink or eat;
  a whoosh for a missed blow. Twelve voices at once (from eight).
- New music, with new instruments built from formulas: a warm detuned pad, a plucked lute, a
  breathy flute with vibrato, brass, a choir, bells, and drums (a deep drum, a hand drum, a
  shaker). Pieces are twice as long (sixteen bars, in two halves, with phrases that come home).
- Music for each place and moment: the town (lute and flute), the wilds, the night (bells), the
  dungeon, battle (drums, driving bass, brass), boss fights (darker, with choir), the Frostmarch
  (high bells), the desert and ash (oud and hand drums), the church (choir), the cemetery.
  Pieces cross-fade; a fight starts its music at once and the calm returns slowly.

## 0.68.3
- A new loading bar: a slim capsule with round ends. Its fill is a soft cyan-to-gold gradient
  drawn a pixel at a time (no blocks or steps), with a gentle glow beneath, a light gliding
  along it and a pulsing pearl of light at its head; the per cent sits above it on the right.

## 0.68.2
- A smoother loading bar. The land is now built in short slices (about a thirtieth of a second
  each) with the screen redrawn between them, so the bar moves steadily instead of freezing and
  jumping; painting the land and growing the forests report their progress as they go. The bar
  glides to each new point, creeps on a little while a step runs, and is one smooth fill from
  cyan to gold with a soft glow and a shimmer running along it.

## 0.68.1
The Movie, with more style.
- Film grain and a soft flicker, darkened corners, and a warm light leak drifting along the left
  edge in daylight scenes.
- The black bars close in at the start; a thin gold thread along the bottom shows how far the
  movie has run, and each scene is numbered ("03 / 15").
- Titles in spaced capitals slide in and fade up, with a gold rule drawing itself under them.
- Each scene starts wide and the camera slowly pushes in.
- When a spell lands: a flash, a camera shake and a moment of slow motion.
- Some scenes cut through white instead of black (magic, the storm, the world boss).
- The end: SHARDSIGHT in gold, a band of light sweeping across it and golden sparks rising,
  before it fades back to the title.

## 0.68.0
The Movie.
- A Movie button on the start screen (after the fly-by, beside Play, Tutorial and Experimental
  mode): a gameplay showcase about two minutes long, played by the game itself and filmed with
  moving cameras over letterbox bars, a title and a line for each scene: the land from above;
  the towns; a fight; magic (fireballs, lightning, flamestrikes, meteors); the dungeon's depths;
  the Frostmarch and a yeti; scorpions in the Sunscar Wastes; a boat across the lake; the Drunken
  Shard at dusk; a champion in the arena; Ravenhollow at night; the church at dawn; winter and a
  storm; a world boss; and the whole land again. The hero fights and casts for real (and can't
  die), with dips to black between scenes.
- Skip ends it at any time. Nothing of it is saved: afterwards the game starts afresh at the title.

## 0.67.3
Polymorph, changed.
- Variety: it now turns you into a creature picked at random from those your Magery reaches,
  never the same one twice running - a wolf, a goblin or a spider from the start; an orc (Magery
  70), a scorpion (72), a bear (75), a yeti (82), an ogre (88), a drake (95). Each has its own
  strengths, and each body comes out a little bigger or smaller than the last.
- Faster decay: it lasts 60 seconds (from 150), every blow you take wears 2 seconds off it, and
  you're warned five seconds before the shape fades.

## 0.67.2
More for the opening fly-by.
- The sun's glare: when the sun is in the picture it blooms, god rays stream from it, and lens
  ghosts are strung across the screen towards the middle (fainter under cloud).
- A fine film grain over the picture.
- A band of light sweeps slowly across the letters of SHARDSIGHT.
- The camera breathes a little as it flies, like a hand-held shot.
- When it lands by your hero, a ring of golden light runs out over the ground, sparks fly up
  and a chime sounds.

## 0.67.1
- The game begins only once the opening fly-by is over and a mode is chosen: until then the world
  holds still (nobody moves, fights, loots or travels; the clock and the weather wait); only the
  camera flies. After switching modes from the menu, it begins as the title fades.

## 0.67.0
Ravenhollow Cemetery.
- The old walled graveyard of the south-east is a cemetery now: rows of headstones, crosses,
  stone tombs and broken stones (old ones leaning) over earth mounds, an obelisk, bare dead
  trees, lanterns burning with a cold green light, and an iron gate standing ajar on the west.
  It is named on the map and the minimap, and in the opening fly-by.
- At night, pale wisps drift among the graves.
- The Tomb of the Old Kings, a marble tomb with columns, in the north of the cemetery. Once a
  night you may break its seal - and wake the Barrow King, a great armoured skeleton who keeps
  the old kings' gold (gems, a crown of bones, a heavy purse).
- A few graves lie beside the church, under its east wall.

## 0.66.2
- No fog at all: the foggy weather is gone (its share of the days is rain now), and so is the
  light haze on clear days and the mist in rain and storms. The land is seen clear to the horizon.

## 0.66.1
- Collision between bodies: people, monsters and animals no longer walk through or stand inside
  each other. Any two that overlap are eased apart (the smaller gives way more), never into a
  wall. Ghosts still pass through everything.

## 0.66.0
People who move like people.
- A human frame for every person (players, townsfolk, orcs, skeletons, zombies, liches and the
  rest): a chest that tapers to the waist, shoulders, a neck, a jaw, nose, ears and mouth; arms
  with elbows and legs with knees; a head that turns by itself; and a left arm that moves (the
  shield is carried on it).
- Walking: arms swing against the legs with loose elbows, the trailing knee bends. At ease, they
  breathe and look about.
- Fighting: an on-guard stance (knees bent, weapon up, shield or off hand forward, eyes on the
  foe), and a different blow for each kind of weapon - a slash across the body with the torso
  turning into it, a thrust drawn back and driven out, a two-handed overhead smash, a punch, and
  a bow drawn to the cheek and loosed. A blow that lands snaps the head back and throws the arms out.
- Casting: both hands raised and weaving while the words are spoken, head back, then thrust
  forward as the spell is loosed.
- Other work: kneeling to bandage, crouching with a hand out to tame, strumming a lute, swinging
  a pick or axe with both hands, holding a fishing rod, riding with hands on the reins.
- Fix: arms used to swing backwards (blows, aiming and the dead's reaching arms went behind the
  back); they go forward now.

## 0.65.1
A new look: from bright toy colours towards a painting.
- A colour grade over the whole picture (under the buttons and text): a little less saturated,
  more contrast, cool blue in the shadows and warm gold in the lights, darkened corners. On
  Medium and High graphics.
- Painted light: a stronger, warmer sun against dimmer, cooler shade; amber light when the sun
  is low; film-like tone mapping (deeper shadows, softer highlights); haze that glows towards
  the sun.
- An earthier land: olive and moss greens, worn earth, pale sand, more grain, and slopes that
  fall into shade so the hills have weight.
- Dark, deep water with soft ripples, the sky's pale light along its far edge and finer glints.

## 0.65.0
A square map.
- The long straight sea along the south is gone. The land now runs on south to make a square:
  144 by 144 tiles (from 144 by 66), more than twice the ground.
- The Isle of Tides sits in a round lake instead, the Tidewater, south of Southmoor; Tidewater
  Harbour on its north shore is where the ship leaves.
- The far south: forests, rocky hills, three more lakes, and Highmoor, a fifth town (healer,
  merchant, banker, bounty board, a road from Southmoor). It is wilder and emptier than the
  north: a handful of wolves, orcs, bears, spiders and the dead to each region.
- The land is split into 36 regions; ten ankh shrines (one region in four, and the isle's).
- To carry the bigger land: the ground is drawn with one quad a tile and painted a little
  coarser, and the minimap is drawn a little coarser too.

## 0.64.1
The menus, remade.
- Smoked glass: every menu, panel and button is see-through now - the game shows behind, dimmed a
  little - with a thin gold edge, rounded corners and a soft shadow. All menu text has a dark
  outline so it reads over anything. Buttons stand up a little and sink when pressed.
- A close button (X) at the top of every panel, always in reach: no scrolling to the bottom for
  Back. A tap outside a panel closes it too.
- Every list still scrolls under your finger (drag anywhere, flick to glide), with a slim gold
  scroll bar.
- The main menu has three columns (less scrolling), a gold title, and little icons on its buttons.

## 0.64.0
The Church of the Shard.
- A stone church just south of the main town: walls with doors on the north side under an arch,
  a paved floor with a red runner, pews, an altar with a gold ankh and two candles, four windows
  of coloured glass glowing in the south wall, and a bell tower on the corner with a pointed roof.
- Father Corwin has moved in (the story's first and last chapters now lead to the church).
- The bell tolls at six in the morning, at noon and at eight in the evening.
- Inside, the Church button (or Adventures > The church): pray at the altar once a day (half
  your health back, mana restored, poison drawn out, a little karma and a clear mind for ten
  minutes), give 50 gold to the poor (karma), or speak with Father Corwin for a blessing or
  confession.
- The wolf, deer, bear and orc that lived on that ground have moved south of the wall; the race
  course goes round the church.

## 0.63.6
- Half as many ankh shrines: seven instead of fifteen (one in every other region, chequer-wise,
  and the one on the Isle of Tides). Ghosts have further to walk; healers and priests in the four
  towns still raise the dead.

## 0.63.5
- The texts over heads are spaced out: floating texts that come close together (the spell's
  words, the damage, "critical!", loot) no longer land on top of each other - each starts a step
  higher and a little to the side, above the name; and the lines of the name label have a little
  more room between them.

## 0.63.4
- Spell names are plain again everywhere (Fireball, Recall, Night Sight...). Only the words
  spoken when casting keep their new old-tongue spelling (Vaas Flaem, Khal Orth Pohr, Yn Lhor).

## 0.63.3
- Spell scrolls keep the plain names ("Scroll of Fireball"); the spells themselves keep their new
  ones.

## 0.63.2
- Every spell has its own name now, in an old spelling close to the plain one: Fyrebal, Hele,
  Greter Hele, Lyghtning, Nyght Syght, Recalle, Marke, Gate Travail, Flamestryke, Chayn Lyghtning,
  Summoun Demoun, Lych Forme and the rest (all 67, and the transformations: Wolf Forme, Bear Forme,
  Ogre Forme). Scrolls, the spellbook, the logs and the help text use the new names.

## 0.63.1
- The words of power are the game's own now: every spell's incantation is respelled in an older
  tongue, close to how it sounded before (In Lor is Yn Lhor, Vas Flam is Vaas Flaem, Kal Ort Por
  is Khal Orth Pohr...). Each syllable keeps one spelling across all the spells, so the language
  still reads as a language: Yn, Ahn, Vaas, Khal, Rhel, Uhs, Dess, Eks, Pohr, Orth, Flaem, Graav,
  Mahni, Nokh, Korph, Wys, Zhen, Juks, Lhor, Sankt, Hyr, Kwas, Bhal, Uhm, Ylaem.

## 0.63.0
A bigger map: the eastern lands.
- The land is half as wide again (144 by 66 tiles, from 96 by 66): the old eastern wall is gone
  and open country runs on beyond the orc fort and the graveyard.
- Dawnport, a fourth town, with a healer, a priest, a merchant (remote, so dear), a banker, a
  bounty board and a road from the east.
- The Ashlands in the far north-east: grey ash veined with embers, charred trees, ash hounds,
  fire-throwing cinder imps and the Ember Lord. Smith Orla of Dawnport has a task about him.
- Mirrormere, a fourth lake, with two landings; two more ankh shrines; wolves, bears, orcs, deer
  and wild horses on the eastern plains.
- The land is split into twelve regions (from eight) for spreading players and monsters; the
  minimap is a little larger to fit it.

## 0.62.0
A big one: thirteen additions.
- Sounds for the wider world: oars on the water, beasts' roars, hisses and rattles as they turn
  on you, wind in the snow and in winter, the tavern's hum and lute, the arena's crowd and cheers.
- Their own bodies for the new creatures: the yeti (a white horned ape), scorpions (pincers and a
  curled tail), mummies (wrapped, reaching), goblins (small, big-eared), bog leeches (fat worms).
- A Journal (Main Menu > Adventures): the story, the captain's quest, side quests, the bounty and
  the rest in one list, with a walk-there button for each. On the minimap: a gold ! over
  townsfolk with work, a green ? when you can hand it in, rings on the creatures a task wants.
- Balance: the skill cap covers all 40 skills; furniture and the boat cost about double; a
  guild tower pays 150 gold a day.
- Icons: little pixel pictures in front of every log line (instead of text marks), beside each
  thing in the bag, and on the menu's buttons.
- Pets level up (to 10) from the kills they share in: stronger, tougher, and they carry part of
  your load. Levels are saved with the pet (Animals shows them).
- Enchanting and gems at the forge: cave crystals and gold enchant a weapon, armour or shield
  to +1..+3 (8% a level; it can fail); rubies, sapphires, emeralds and diamonds (from cave
  chiefs, mummies, the depths and bosses) set into gear lend strength, intelligence or dexterity.
- Seasons: spring, summer, autumn and winter, three days each. The land and the trees change
  colour, snow lies and falls in winter, and the weather leans with the season (the clock shows
  the season and day).
- Farming (a new skill): four fields by your house for wheat, carrots and pumpkins; they grow
  with the seasons (fast in summer, not in winter). New recipes: bread, vegetable stew, pumpkin pie.
- From the saddle, blows land 15% harder (more on a high-level mount). Horse races at the arena:
  a lap of the course on your own mount against three riders, with a stake.
- The sea: Southmoor Harbour on the south coast, and a voyage to the Isle of Tides - giant
  crabs, drowned sailors, and the Drowned King in his ruin (pearls, sapphires, a diamond). An ankh
  stands on the isle.
- World bosses: now and then a giant wakes in the wilds (Tharok the World-Eater, the Frost Wyrm,
  the Queen of Ashes, Grandfather Yeti). The strong players come from every side; it leaves two
  treasure chests, and gold, fame and a diamond for a hero who fought.
- Auto's errands can each be switched on or off (Adventures > What Auto does), and Auto also
  farms, enchants, races and joins world-boss fights.
- A Tutorial button on the start screen: the ordinary game with six guided first steps.

## 0.61.2
Fix: the hero (on Auto) left treasure chests and corpses lying.
- Auto's errands kept re-issuing the walk to their destination, which dropped whatever the hero
  was about to loot; they now wait while it loots (or fights).
- On any long walk (an errand, or off to another region) the hero now stops for spoils lying
  near its way, then carries on; before, it walked straight past them.
- Deer, horses and other peaceful beasts nearby no longer stop it looting (only a monster that
  might fight does).
- Treasure chests are noticed from 22 m (their beam is seen from afar) and come first.
- On hills, the reach to a corpse is measured along the ground, and one on the same tile is just
  stepped over to; a corpse that truly can't be reached is no longer tried again and again.

## 0.61.1
- Treasure chests rise out of the ground: they push up through the earth with a shake and a
  spray of dirt, then glint with gold sparkles.
- Fix: chests dropped by monsters on a hillside could sit buried in the slope or float above it
  (they took the monster's height, not the ground's under them); corpses and chests now always
  lie on the ground where they fall.

## 0.61.0
A loading screen.
- From the moment the game opens: a dark field of glowing hexagons with a pulse rolling out from
  the middle and a scan line sweeping down; at the centre the Shard spins inside turning rings of
  light, with a gold progress arc and tick marks round it; the name spaced out in gold; a
  segmented progress bar with a bright leading edge and the per cent; the step being loaded,
  typed out with a blinking cursor; system lines lower left; viewfinder corners and the version.
- The world is built a step at a time behind it (the land, the sky, the creatures, the towns,
  your saved hero, the wider world), so the screen keeps moving instead of freezing; then it
  fades into the title and the fly-by.
- The game is never saved while it is still loading (going to the background then could have
  saved a fresh hero over yours).

## 0.60.1
- Fix: the game wouldn't start in 0.59.7 and 0.60.0 (a name used twice in the fly-by's camera
  code).

## 0.60.0
Auto plays the whole game.
- On Auto your hero no longer only fights, loots, gathers and crafts: every minute or so, when
  nothing presses, it runs an errand - whichever kind it has gone longest without (side quests
  weigh most, then bounties, then the rest): takes side quests from the townsfolk, hunts or
  fetches for them and hands them in; takes bounties at a board and hunts them down; cooks (lighting
  a fire with a log); brews strength and agility potions and blade poisons; visits the tavern (a
  meal, a bed at night, rumours, an ale for the minstrel); buys a boat and a fishing pole when
  gold allows and fishes the lakes (or rides the ferry); fights the arena champion it can beat;
  goes down the dungeon's stairs as deep as it safely can; stands on rival guilds' towers to take
  them; goes home to sleep, gather the garden, study and furnish the house; and now and then goes
  to look at a cave or a biome.
- It only takes on fights it can win, and only spends gold it can spare.
- In a fight with a tough foe it drinks a strength or agility potion and poisons its blade; when
  fleeing badly hurt it drinks invisibility. Out of a fight it eats its best cooked meal to stay
  Well fed, or when hurt.
- A tap still takes over: errands wait while you're steering.
- Landings sell fishing poles (15 gold).

## 0.59.7
The opening fly-by as a film.
- It fades in from black; black bars frame the picture and the corners are darkened, and the
  bars slide away when the camera reaches your hero.
- Each place it passes is named in the corner: the Southern Woods, the Town, the Dungeon, the
  Eastern Wilds, the Old Graveyard, Southmoor.
- The camera leans into its turns and looks through a wider lens up high, levelling out and
  narrowing to the usual view as it comes down.
- Golden motes drift in the air ahead of it.
- The title's lines fade in one after another, and the name shimmers gold.

## 0.59.6
- The start screen: the title shows over the opening fly-by (tap to skip it); once the camera
  has come down to your hero, the mode buttons fade in - Play (the ordinary game) or
  Experimental mode - and the game waits for your choice. After switching modes from the menu
  the choice is already made, so the title simply fades once the fly-by is over.

## 0.59.5
Aiming at 60 frames a second.
- The world off screen costs a third of what it did: creatures you can't see live every third
  frame (a third of them at a time, catching up on the time they missed). The hero, everyone on
  screen and whoever is after the hero still live every frame.
- The frame-rate keeper now holds 60 rather than 28: under 54 it lowers the 3D resolution (to
  half at most, faster when far below); if that isn't enough it turns off the sun's shadows, then
  the grass, flowers and fine ground. Those stay off until you change Settings > Graphics, so
  nothing flickers. After ten smooth seconds the resolution climbs back a step, and it learns
  where to stop. The first seconds after starting aren't counted.
- Never more than 60 frames a second, even on a 120 Hz screen: steadier, cooler, kinder to the
  battery.
- A smaller shadow map on Low and Medium graphics.

## 0.59.4
- The logs are in colour, each line with a mark in front, by what it's about: deaths red (†),
  danger orange (!), gold yellow ($), spoils and things you make pale gold (+), skills and levels
  cyan (*), quests and bounties violet (»), magic blue (*), healing, food and rest green (+),
  travel and towers teal (»), tips grey; everything else white (•). Both logs: yours (lower left)
  and the world's (lower right).

## 0.59.3
- Builds: the APK is published to the repository's Releases (tag `v<version>`), so there is a
  permanent download link for every version and a full Actions artifact storage no longer
  matters. It is published once the smoke test has shown the game starts.

## 0.59.2
- Fix: the game wouldn't start in 0.59.0/0.59.1 (the bounty boards' building code was missing).
  The boards now stand in each town: two posts and a board pinned with notices.

## 0.59.1
- Builds: the APK is kept for 3 days (so old builds no longer fill GitHub's artifact storage),
  and a full storage no longer stops the build before the smoke test checks the game.

## 0.59.0
The wider world: twelve new things to do, all in the main game (Main Menu > Adventures; an
action button appears at the bottom of the screen when you stand by something you can use).
- Dungeon depths: stairs in the Bone King's hall lead down through four deeper levels (the Bone
  Galleries, the Weeping Crypts, the Ember Deep, the Abyss). Each level's dead are stronger and
  pay extra gold; each has its own master to slay before the way goes deeper. Slay the Bone King
  to open the stairs. Leave the dungeon and you're back on the first level.
- Biomes: the Frostmarch (snow, with falling snow) in the north, the Sunscar Wastes (desert) in
  the south-east and the Blackwater Fen (swamp) round the southern lake. The ground, the trees
  and the minimap take their colours, and each has its own creatures and spoils: frost wolves
  and a yeti (frost pelts), sand scorpions and mummies (venom, ancient wrappings), bog leeches and
  a bog troll (swamp herbs). Deer, bears and wolves now give raw meat.
- Caves: Frostfang Cavern (north), Scorpion Hollow (desert) and the Goblin Warren (south-west):
  walled hollows with one way in, dark floors, cave spiders, goblins and a chief in each (the
  Frost Giant, the Scorpion Queen, the Goblin Chief). Their rocks hold richer ore and crystals.
- Boats: landings on all three lakes. Ride the ferry across for a few coins, or buy a boat
  (150 gold) to cross free and to fish from out on the deep water (big fish and pearls).
- The tavern: the Drunken Shard in Southmoor. Ale, a hot meal, a room for the night (sleep till
  morning), rumours, dice, and its hearth to cook at.
- Townsfolk with a daily round: a farmer, a fisherwoman and a minstrel work by day, go to the
  tavern in the evening and home at night; a barkeep, the arena master and four folk out in the
  wilds keep their posts.
- Side quests told in dialogue, with choices that change the reward, your karma and your fame:
  wolves at Tobin's fold, Nell's pearl, Bram's yeti, Wren's herbs, Zahir's venom, Garret's goblin
  warren, a song from Tam, Rosa's rats.
- Bounty boards in every town: an elite beast of uncommon size (marked red on the map), a cull of
  some monster, or a murderer among the players. One at a time, paid on the spot.
- Cooking (a new skill): cook fish, steaks, fish pie, hearty stew and Frostmarch chowder at a
  campfire (light one with a log), the tavern's hearth or your own. Meals heal and make you
  Well fed: stronger, quicker or sharper for ten to twenty minutes.
- Alchemy: Strength and Agility potions, an Invisibility potion, and Lesser and Deadly blade
  poisons that coat your weapon (each blow may poison the foe), brewed from reagents and what the
  wilds give.
- House decoration: rugs, tables, chairs, plants, lanterns, a weapon rack, a bed (sleep and wake
  Rested; the more comfortable the house the longer it lasts), a bookshelf (study once a day), a
  hearth (cook at home), an herb garden (herbs every day) and trophies from the great foes you've
  slain.
- The arena south of the main town: fight Kael's four champions for a purse, betting on yourself
  to win double your stake, or bet on a bout between two gladiators.
- Guild towers: three watchtowers in the wilds, each held by a guild (its flag on the tower and
  the minimap). Hold the ground round one for twenty seconds, with no defenders, to take it; the
  computer guilds raid each other's. A tower pays its guild 75 gold a day (into your bank if
  it's yours).

## 0.58.2
- Fix: white streaks across the screen in the rain. The rain started at the overhead camera's
  height, so drops were born right by the lens and smeared across the view (worse zoomed in); it
  now starts a little below the camera. The drops are finer and grey-blue rather than white.
- The fog is thinner and grey rather than milky white, so a foggy day no longer whites out the
  screen. (Settings > Weather: Off still keeps the sky always clear.)

## 0.58.1
Story scenes.
- At the story's key moments the camera glides down from the overhead view to your hero's eyes
  and looks at what matters: the priest or abbess you speak with, the ankh you pray at, the fallen
  ogre, lich or Bone King whose fragment you take, and Malgrath himself. The chapter's story
  panel opens once the camera is down, and when you continue it rises smoothly back to the usual
  view (or your first-person view).
- The first time you come near the Broken Circle in the last chapter, the camera comes down to
  look the Shardbreaker in the eye for a few seconds as he speaks.
- Taps are ignored while a scene plays.

## 0.58.0
The main story: The Shattered Sight.
- Long ago the Shard of Sight watched over the land; Malgrath the Shardbreaker broke it, gave its
  fragments to his servants, and the world went half blind. Eight chapters take your hero from
  waking on the road with no memory, through Father Corwin and an ankh's vision, to the three
  fragments (held by the Ogre of the orc fort, the Lich of the graveyard and the Bone King),
  Mother Isolde's old writings, and the last stand against Malgrath at the Broken Circle, a ring
  of standing stones in the heart of the land; then the Shard is whole and you're the Shardbearer.
- Each chapter is told in a story panel when it begins (after the opening fly-by for the first),
  with your task; the task and its distance and direction show at the top of the screen, and a
  violet diamond marks the place on the minimap. Main Menu > Story shows the current chapter and
  the ones behind you, or the epilogue.
- Rewards: gold and fame for every chapter, the three Shard Fragments (kept, never sold), the
  Shard of Sight, and the title "the Shardbearer" at the end.
- Malgrath the Shardbreaker, a lich lord far stronger than any other foe, waits at the Broken
  Circle (lit with a violet glow while he's there) once the fragments are gathered.
- The Broken Circle stands in the heart of the land from the start.

## 0.57.0
Experimental mode.
- The start screen offers a choice: Play (the ordinary game) or Experimental mode, a separate
  game with its own save where new ideas are tried out first. In experimental mode the title
  says so, and Main Menu > Experiments switches each experiment on and off (the choices are
  kept); Main Menu > Ordinary game goes back (and Experimental mode goes the other way), saving
  first. The ordinary game is never touched by experiments.
- The first experiments: Fast days (day and night four times as fast), Crowded wilds (half as many
  monsters again, from the next start), Quick learning (skills rise twice as fast) and Glass cannon
  (everyone deals and takes double damage).
- The main menu is laid out in two columns that scroll, so every button fits on the screen.

## 0.56.0
A deeper fight.
- Twelve new hand weapons, each with its own model: Scimitar, Katana and Viking Sword; Axe,
  Battle Axe and Double Axe (Swordsmanship); Short Spear, Spear and War Fork (Fencing);
  Quarterstaff, War Axe and Maul (Mace Fighting). Merchants sell most of them, smiths make them
  (Blacksmithy; the quarterstaff with Carpentry), and orcs, skeletons and ogres drop some.
- Damage types: slashing (swords, axes) bites 15% deeper into the unarmoured, piercing (daggers,
  kryss, spears, bows) goes halfway through armour, bashing (maces, hammers, staves, mauls) hits
  metal armour and bone 25% harder.
- Critical hits: 5% of blows (up to 15% with Anatomy) do half as much again.
- Weapon specials: with 25+ in your weapon skill, 12-22% of your hits (costing 10 stamina) land
  your weapon's special: Bleeding Wound (swords and axes: hurts every second for 4 s), Armor
  Ignore (spears and fencing: straight through armour), Crushing Blow (maces and hammers: +50%
  and stuns for a moment), Double Strike (daggers, kryss, scimitar, katana, double axe: a second
  blow at once) or Concussion (quarterstaff, war fork: knocks 15 mana out and breaks a spell).
  The Bag and the merchant show each weapon's damage type and special.
- Swings match the weapon type: spears and fencing weapons thrust, staves, war axes and mauls
  smash down from overhead.
- Spells come to you as your Magery grows: every spell whose minimum Magery you reach is added to
  your spellbook by itself (attack and defence, curses, fields, summons, transformations), and your
  log says which. Scrolls still teach a spell early.
- Transformations: Polymorph now really changes your body: a wolf (Dex +15, faster, quicker
  bites), a bear from Magery 75 (Str +20, armour) or an ogre from 90 (Str +30, heavy blows).
  New: Horrific Beast (circle 5: a daemon's body, Str +10, harder blows, health back each second),
  Wraith Form (circle 6: a shroud that takes a quarter less damage, mana back faster) and Lich
  Form (circle 8: Int +20, mana back three times as fast, a little more fragile). Beasts can't
  cast until they change back. Computer players (and your hero on Auto) take a fighting form
  against tough foes: fighters a beast, mages a wraith or a lich.
- Summons: casters call up an ally not only against a tough foe but whenever they're outnumbered.

## 0.55.1
Faster.
- Sun shadows only as far as the camera sees (30 m, 45 m on High) in one cascade (two on High),
  instead of the default four cascades out to 100 m: the costliest single thing on a phone.
- The soft glow round fire and magic is now High graphics only.
- The sky re-lights the world at most every 3 seconds, and only when it has visibly changed
  (lightning at once), instead of every second.
- The 3D resolution adapts: if the game runs under 28 frames a second it is lowered a step at a
  time (to 55% at most), and raised back to the graphics setting's once it runs smoothly again.
  Buttons and text stay sharp.
- Creatures far off screen make their decisions a third as often (they still move and fight
  every frame).
- On Low graphics the land is built with one quad a tile instead of two (a quarter of the
  triangles).
- First person looks for whoever's in the sights ten times a second, not every frame; the minimap
  redraws twice a second.

## 0.55.0
Hills and hollows.
- The land rises and falls: gentle hills up to about three metres out in the wilds, higher in
  the rocky country, while the towns, the dungeon, the shores and the ground beside walls stay
  flat and the slopes run down to them smoothly. The ground is finer-meshed to carry the hills and
  lit as slopes, so hillsides catch the sun and fall into shade.
- Everything stands on the land: trees, bushes, rocks, pebbles, grass, the ankh shrines,
  players, monsters, corpses and chests; walkers go up and down the slopes.
- Taps find the spot on the hillside you touched (not the flat ground under it).
- A house levels the ground it's built on.

## 0.54.2
- Scrolling the menus with a finger works properly: drag anywhere in a list, even starting on a
  button, and it scrolls without pressing the button (before, a drag that began on a button didn't
  scroll and pressed the button on release); flick it and it glides on and slows to a stop; a
  short tap still presses buttons; the scroll bar is wider so you can see where you are.

## 0.54.1
- Your hero's name and title show over its head above the level and HP, even with names hidden
  ("Hero the Slayer" with an achievement title, or the fame and karma title such as "Hero the
  Notable").

## 0.54.0
Players shoot.
- Computer players use their bows and crossbows: they draw the bow while a foe is still coming
  (more than a few steps off) and switch to the hand weapon and shield once it closes in, with a
  moment to change weapons ("draws a bow" / "draws steel"). Archers and crossbowmen by trade
  (Brina, Fenn) and about a quarter of the others prefer the bow and keep shooting even close in.
- Archers pressed by something that only fights up close step back a few paces to shoot again.
- They buy arrows from merchants as they need them, and every shot trains Archery.
- Your hero on Auto does the same, unless you chose its gear by hand (Bow button or the Bag).

## 0.53.2
- Fix: the Statistics panel declared a variable twice, which stopped the game's main script from
  loading (the 0.53.1 build failed its smoke test).

## 0.53.1
- Treasure chests from slain monsters are rarer: 3% (was 10%). Champions still always leave one.

## 0.53.0
On the move across the whole map.
- Computer players no longer stay in one region for good: after four to eight minutes in one they
  set off for another, preferring the emptiest, and walk there across the map (fighting off
  anyone who attacks on the way, then carrying on). Everyone stays spread out, but on the move.
- Your hero on Auto travels the land the same way.
- Tap anywhere on the minimap and your hero walks there, right across the map if need be: a gold
  flag marks the destination, your log says where and how far, and on Auto the hero fights off
  attackers on the way and carries on. Tap the ground to stop.

## 0.52.0
A world in motion.
- Cloud shadows drift slowly across the land on clear days (none under an overcast sky).
- Water swells gently in slow crossing waves, glints where the light catches it and brightens
  towards the horizon.
- Smoke rises from the forge, the braziers and campfires, spreading and drifting with the wind
  (only animated on screen).
- Banners in each town's colours (red for the main town, blue for the outpost, green for
  Southmoor) fly from poles at its four corners, flapping in the wind.
- A flock of birds wheels over the land by day, wings beating.
- Butterflies flutter over the meadows by day, and leaves drift down in the woods (clear weather,
  Medium and High graphics).
- The ankh shrines turn slowly and their light breathes.
- Corpses sink into the ground as they rot away, and a treasure chest's beam pulses.

## 0.51.0
Livelier movement.
- Walkers take straight lines and cut corners where it's clear, instead of zig-zagging from tile
  centre to tile centre (for anyone near the camera), and ease into their pace from a standstill.
- Bodies turn smoothly to face where they're going or what they fight, instead of snapping round.
- The walk follows the actual pace: faster walkers and mounts step quicker; legs and arms ease
  in and out of the stride; hips sway and the body leans into the walk. Standing idle, people
  glance about.
- Each weapon has its own attack: swords slash diagonally, daggers and kryss thrust with a long
  lunge, maces, clubs and war hammers come down from high overhead, and bows and crossbows are
  held out aiming (and kept raised between shots).
- A flinch when struck: a quick jolt back from the blow.
- Slain monsters topple backwards to the ground before they vanish, leaving their corpse.

## 0.50.0
A better first person.
- Look round with one finger: drag left and right to turn, up and down to look higher or lower;
  a short tap still walks or attacks. Leave it for four seconds and the view eases back round to
  where the hero is heading (it used to be stuck to the hero's facing, with no way to look round).
- A crosshair in the middle of the screen, red over a monster, with the name and health of
  whoever is in your sights.
- Taps pick whoever is drawn nearest your finger (their chest, not their feet), so you can
  target monsters, players, merchants and priests by tapping them; this helps in the overhead
  view too.
- Your health, mana and stamina as bars at the bottom of the screen (your own bar and label over
  your head are hidden in first person).
- Your weapon in your hand at the lower right: it swings when you strike, lifts as you cast, and
  bobs as you walk; the view bobs gently as you walk too.

## 0.49.0
A living world: trade, treasure, fishing, jewelry, wear, events, sounds, sky and achievements.
- Trade: tap a merchant for a shop window. Buy supplies (arrows, bandages, reagents, potions,
  pickaxe, hatchet, tool kit, shovel, fishing pole, lute), weapons, armour, shields, jewelry and
  spell scrolls you don't know (circles 1-6); sell anything in your bag at the merchant's offer
  (it pays less for what it already holds, and only what its purse allows); have worn gear
  repaired. Your artifacts, jewelry and maps are no longer sold automatically when you stand by
  a merchant.
- Treasure maps drop from monsters (and come up when fishing). Bag > Read marks the spot with a
  red X on the minimap; walk there and Dig with a shovel: a rich chest (gold, reagents, high-
  circle scrolls, often an artifact and jewelry), and two or three of its dead guardians rise.
- Fishing, a new skill: carry a fishing pole and tap the water. Fish and big fish can be eaten
  (+10 and +20 health) or sold; now and then a pearl, an old boot, or a treasure map in a bottle.
- Jewelry: a ring and an amulet slot (Bag > Wear). Rings of Strength, Agility, Wits, Power (spell
  damage), Swift Casting and Life (health back each second); amulets of Guarding (armour),
  Warding (resist spells), the Mind and the Titan. Merchants sell the plainer ones; the rest come
  from chests and, rarely, monsters. An amulet shows as a gold chain with a glowing gem.
- Durability: weapons wear with your blows, armour with the blows you take, shields when they
  parry; a piece breaks at 0 (you're warned at 10). The Bag shows it; a merchant repairs it for
  gold, or do it yourself at the forge with a tool kit (Blacksmithy). Computer players repair too.
  Exceptional work lasts longer, artifacts twice as long.
- World events: the restless dead rise in the wilds at night and crumble at dawn; every ten
  minutes or so an orc warband with a Warlord marches on a town and camps at its gates (help
  destroy it for gold and fame); champions (Gorgath the Ravager, Ulmara the Bone Witch, Kruul
  Ironhide) rise in the wilds, show as big orange dots on the minimap, have a health bar, and
  always leave a treasure chest.
- Sounds of the world: footsteps on grass and on stone, birdsong among the trees by day,
  crickets at night, running water near rivers and lakes, and the crackle of fires near braziers,
  campfires and the forge, each fading with distance.
- The sky: blue by day with the sun, glowing orange towards the sun at dawn and dusk, dark with
  stars and a moon at night, greyer in bad weather; fireflies drift round you on clear nights in
  the wilds.
- Achievements (Statistics): 19 deeds, from First Blood and Monster Slayer to Archmage and Hero of
  the Realm, each paying gold and earning a title you can wear after your name.
- A new skill (Fishing) raises the skill cap to 3800.

## 0.48.0
A prettier world.
- The ground is painted once at the start instead of one flat noise: grass with soft meadows,
  sandy shores round the water, a dark forest floor under and beside the trees, and dirt roads
  from the main town to the outpost, Southmoor, the dungeon's gate and the western woods, and on
  to the graveyard and the orc fort, all blending softly, with a fine grain on top.
- Trees, bushes, grass and flowers sway in the wind, each on its own beat; trunks barely move,
  crowns and tips swing.
- Bushes with red berries at the forest edges, and pebbles scattered across the fields (hidden on
  Low graphics, like the grass and flowers).
- Town and dungeon walls have battlements.
- Light from the sky all round (bluish from above, a green bounce from the ground) instead of
  one flat ambient colour, so everything looks rounder.

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
