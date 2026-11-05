# Changelog

Version lives in `project.godot` (`application/config/version`). Bump it there; CI stamps it
into the Android `version/name` and derives `version/code` from it (major*10000 + minor*100 + patch).

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
