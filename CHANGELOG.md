# Changelog

Version lives in `project.godot` (`application/config/version`). Bump it there; CI stamps it
into the Android `version/name` and derives `version/code` from it (major*10000 + minor*100 + patch).

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
