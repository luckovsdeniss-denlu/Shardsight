# Changelog

Version lives in `project.godot` (`application/config/version`). Bump it there; CI stamps it
into the Android `version/name` and derives `version/code` from it (major*10000 + minor*100 + patch).

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
