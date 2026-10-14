# Saved first-three designs — implementation queue

Source: Supabase `isaac-loadout-*` records reviewed Oct 12, 2026. Drafts remain
user-owned; implementation evidence is stored separately under `isaac-build-*`.

## Isaac — shipped and tested

- Normal/default: D6 retained/restored.
- Optional mode: add Mom's Knife 114 + Soy Milk 330 without replacing D6.
- Applies to fresh runs and actual Twisted resets.
- Both reset modes, inventory stripping, persistent selection tested on Windows.
- No new item artwork required; game screenshot provided in planner.

## Magdalene — reviewed, not shipped

- Preserve Yum Heart and all normal unlocked starting items.
- Add Yuck Heart as a pocket active, not a replacement main active.
- Pocket item must not be removable.
- Forced-use timing requested from Alex; do not invent it.
- Implementation must test charge handling, floor transitions, active pickups,
  Exit/Continue, and Twisted resets without losing Yum Heart.

## Cain — art started, mechanics not shipped

- Preserve Lucky Foot and normal unlocked Paper Clip/starting kit.
- Custom locked item: Unlucky Foot, art draft in art/unlucky-foot-master.png.
- At each floor start: give a pill guaranteed to produce a negative effect.
- Must bypass Lucky Foot's positive-pill conversion for the cursed pill without
  silently removing Lucky Foot or globally changing other characters' pills.
- Prevent duplicate floor grants on Continue; decide/test card-slot overflow.
- Test floor 1, later floor, return via Twisted key, effect results, item-removal
  attempts and save/continue. No in-game-test badge until these actually pass.


## Oct 12 clarified character mechanics

- Magdalene: permanent pocket Yuck Heart; preserve Yum Heart. Every four unique cleared combat rooms, automatically convert one ordinary red heart, then soul/black health, into a rotten heart. Soul/black health is exchanged for a red container because vanilla rotten hearts require one. An isolated final half-heart rounds to a full rotten heart; this implementation detail needs in-game review. No free healing once all filled health is rotten.
- Cain: Unlucky Foot mechanic replaces slot-zero card/pill every floor with a mandatory negative pill. Pocket use/drop and card/pill pickups are locked until it is taken. Apply a negative effect directly, bypassing Lucky Foot, without granting False PHD. Negative effects currently use a safe explicit pool: speed/range/tears/luck/shot-speed down, amnesia, paralysis, retro vision.
- Judas: Purple Heart in a real trinket slot, non-droppable/non-swappable; Mom's Purse supplies a second slot. Book of Belial preserved. Cursed Bow and the other newer Judas design additions are NOT implemented by this mechanics module.

Status: code and mocked state-transition tests pass. No in-game testing claimed for these three mechanics. Current game remains untouched until reload/restart. All other starting-kit and reset behavior remains subject to the existing mod's limitations.

## Oct13 15:32 acceptance audit — current scope, not a completed-build claim

The earlier dated statuses above are historical. Native evidence now exists for
Magdalene's four-unique-room trigger/health conversion/Continue, Cain's raw-Q
negative-pill lock/pickup exclusion/reset/Continue, and Judas's actual protected
trinket slots/raw short-Ctrl switching/reset-kit/Continue. See checkpoints
0732/0802/0832/1032/1102 in PLAYTEST-20261012.md. Preserve the1102 FAIL:
Twisted reset retained an active card; consumable stripping is NOT certified.

New `tests/character-drafts.lua` exercises17 source-only contracts across the
legacy `character_setups.lua` inventory branches, including every Azazel/Lost
random choice. This is NOT full runtime acceptance: `CustomItems:Init` wraps
ApplySetup and overrides legacy dispatch for ready saved designs;
`saved_designs.lua`, restored starting kits and native character properties
can alter the final kit. No engine stats, visuals, floor generation, twins or
death behavior are simulated or certified by these17 checks.

| Legacy setup | Source observation / outstanding acceptance |
| --- | --- |
| Azazel | Rock Bottom plus one of four grants; native random boost/stat lock and reset remain unverified. |
| Lost | One of three flight grants; this module does not implement grounded movement. |
| Eden | Treatment/Blessing grants; no extra-boss hook here; current saved-design override must be assessed separately. |
| Jacob | Fetus/Reflection/No2 legacy grants; current override/twin Heart behavior requires native evidence. |
| Tainted Isaac | Three ordinary Sacred Orb grants, not an inverse quality-selection implementation here. |
| Tainted Lost | Baggy/CrystalBall legacy grants; GetLevel alone is not a planetarium-generation hook; saved-design override requires separate evidence. |
| Tainted Cain | Shovel grant; vanilla conversion is not a custom setup acceptance pass. |
| Tainted Keeper | Magneto/CursedPenny grants; no shop-door removal hook in this module. |
| Tainted Eden | TMTRAINER legacy grant; no inverse-key-on-death hook here; saved-design override requires separate evidence. |
| Tainted Jacob | Birthright grant only; native behavior/reset unverified. |

Next independent native acceptance priorities: Cursed Bow half-heart gain
limits (including HP-up healing); Eve hostile-bird damage/current+next-room
lifetime; Lazarus last-boss floor-death/extra-life behavior. Use isolated
backed-up fixtures; do not repeat already accepted Cain/Judas input work.
Native Beast/permanent badge/menu remain UNVERIFIED. Do not retry the identical
COMPLETE1402 TV fixture, change supported runtime, or ship QA helpers.


### Oct13 16:02 Cursed Bow acceptance extension

Native Hard Judas/REPENTOGON fixture:9 valid engine checks passed, including
red/soul/black half-heart gain caps, uncapped container gains/negative removals,
ordinary gains after removing Bow, incoming half-heart damage unchanged, and
Breakfast firstTime=true granting a full container but only half-heart healing.
One firstTime=false HP grant failed and is retained as an invalid pickup fixture;
only that test was corrected live, not the full suite replayed. See1602 evidence.
These are scripted native health/grant APIs, not organic pickups, Bow reset or
Bow cold Continue acceptance. Eve/Lazarus native priorities remain unfinished.

### Oct13 17:39 native Eve contact correction
Undead Bird pursuit/contact now repaired and verified in a fresh guarded HardEve slot3 native fixture: explicit effect movement; bird-source damage at frames40/80/120, health3→2→1→0. Initial stationary-effect failure retained. Friendly DeadBird actual count0 throughout bounded observations. Previous room-lifetime coverage stands; changed movement in next room, Continue and Twisted reset still unverified. Windows entering build restored; tested repair is local, release ZIP not rebuilt. See PLAYTEST-20261012.md and 1732 evidence.


### Oct13 20:02 saved-design composition audit
14 new MOCK contracts exercise actual saved-design/presets/mechanics/custom-item wrapper composition, not1532 legacy-only dispatch. Source final kits include BlueBaby725/358/378/675, Eden697/240, Bethany569, TaintedLost431/75/619, TaintedEden721, Jacob276 plus276 on returned twin, and revivedLazarus using original kit key. NOT native acceptance. Duplicate starting-kit copies currently collapse to one on restoration; characterized limitation, no repair or native reproduction. Forced Resurrection EID now accurately says final-boss clear rather than floor departure; gameplay unchanged. See2002 evidence and PLAYTEST checkpoint.


### Oct13 20:37 scripted native saved-design inventory extension
5/5 native required-grant cases passed on official REPENTOGON1.1.3/J273, isolated fresh HardIsaac slot3/KQS93PFZ: engine ChangePlayerType and real inventory cleared before calling production setup wrapper twice. BlueBaby725/358/378/675, Eden697/240, Bethany569, TaintedLost431/75/619 and TaintedEden721 each observed at count1 after both calls; player type matched/alive. NOT full inventory exclusion, fresh menu starts per character, organic gameplay, twins, character mechanics, Continue/keyreset or duplicate-baseline restoration acceptance. See2032 native evidence; limitations above retained. Production unchanged this lane.
