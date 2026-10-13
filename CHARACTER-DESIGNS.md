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
